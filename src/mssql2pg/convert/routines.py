"""Stored Procedures / Functions: T-SQL -> PL/pgSQL.

Kontrollfluss (DECLARE, SET, IF/ELSE, WHILE, BEGIN/END, TRY/CATCH, RETURN, THROW, EXEC, PRINT)
wird hier auf Token-Ebene geparst; einzelne DML-Statements (SELECT/INSERT/UPDATE/DELETE/MERGE/...)
werden abgegrenzt und an sqlglot übergeben (common.normalize + to_pg).

Konventionen:
  * Prozeduren werden zu FUNCTION ... RETURNS void (Aufruf: SELECT schema.proc(...)).
  * Parameter @x -> p_x, lokale Variablen @x -> v_x.
  * Temp-Tabellen #x -> tmp_x (CREATE TEMP TABLE, vorher DROP IF EXISTS).
  * Nicht unterstützt (-> status failed, Override nötig): Cursor, Tabellenvariablen,
    Resultsets aus Prozeduren, Inline-Table-Valued-Functions, GOTO.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

import sqlglot
from sqlglot import exp
from sqlglot.dialects.tsql import TSQL
from sqlglot.tokens import Token, TokenType

from ..model import PgObject, SourceObject
from ..naming import pg_name, quote
from .common import Ctx, Unsupported, map_datatype, normalize, to_pg
from .types import TypeSchema, coerce



class _Tokenizer(TSQL.Tokenizer):
    # END/FETCH sind in sqlglot "Commands" (Rest bis ';' wird ein String) – hier normale Tokens
    COMMANDS = TSQL.Tokenizer.COMMANDS - {TokenType.END, TokenType.FETCH}


def tokenize(sql: str) -> list[Token]:
    return _Tokenizer(dialect="tsql").tokenize(sql)

STMT_START = {
    "SELECT", "INSERT", "UPDATE", "DELETE", "MERGE", "WITH", "TRUNCATE", "DECLARE", "SET", "IF",
    "ELSE", "WHILE", "BEGIN", "END", "RETURN", "THROW", "RAISERROR", "EXEC", "EXECUTE", "PRINT",
    "DROP", "CREATE", "ALTER", "BREAK", "CONTINUE", "COMMIT", "ROLLBACK", "GOTO", "OPEN", "FETCH",
    "CLOSE", "DEALLOCATE", "SAVE", "WAITFOR",
}
DML_START = {"SELECT", "INSERT", "UPDATE", "DELETE", "MERGE", "WITH", "TRUNCATE", "DROP", "CREATE", "ALTER"}
SET_OPTIONS = {
    "NOCOUNT", "XACT_ABORT", "ANSI_NULLS", "ANSI_WARNINGS", "ANSI_PADDING", "QUOTED_IDENTIFIER",
    "ARITHABORT", "CONCAT_NULL_YIELDS_NULL", "NUMERIC_ROUNDABORT", "DATEFIRST", "DATEFORMAT",
    "LANGUAGE", "DEADLOCK_PRIORITY", "LOCK_TIMEOUT", "ROWCOUNT", "STATISTICS", "FMTONLY", "IDENTITY_INSERT",
}


@dataclass
class Routine:
    kind: str                         # procedure | scalar | tvf
    params: list[str] = field(default_factory=list)       # fertige PG-Parameterdefinitionen
    returns: str = "void"
    has_out: bool = False
    decls: list[str] = field(default_factory=list)        # DECLARE-Abschnitt
    decl_names: set[str] = field(default_factory=set)
    return_table: str | None = None   # tvf: T-SQL-Name der Rückgabe-Tabellenvariable
    uses_rowcount: bool = False


class Parser:
    def __init__(self, sql: str, ctx: Ctx, routine: Routine, types: TypeSchema | None = None):
        self.sql = sql
        self.toks: list[Token] = tokenize(sql)
        self.i = 0
        self.ctx = ctx
        self.r = routine
        self._types = ctx.var_types        # PL/pgSQL-Variable -> PG-Typ
        self.types = types

    # ------------------------------------------------------------------ Token-Helfer

    @property
    def cur(self) -> Token | None:
        return self.toks[self.i] if self.i < len(self.toks) else None

    def peek(self, n: int = 1) -> Token | None:
        j = self.i + n
        return self.toks[j] if j < len(self.toks) else None

    @staticmethod
    def kw(tok: Token | None) -> str:
        """Schlüsselwort (upper) oder '' für Bezeichner/Strings/Zahlen."""
        if tok is None or tok.token_type in (TokenType.IDENTIFIER, TokenType.STRING,
                                             TokenType.NATIONAL_STRING, TokenType.NUMBER):
            return ""
        return tok.text.upper()

    def at(self, *words: str) -> bool:
        return self.kw(self.cur) in words

    def expect(self, *words: str) -> Token:
        if not self.at(*words):
            got = self.cur.text if self.cur else "<Ende>"
            raise Unsupported(f"Erwartet {'/'.join(words)}, gefunden {got!r} (Zeile {self.cur.line if self.cur else '?'})")
        t = self.cur
        self.i += 1
        return t

    def text(self, a: int, b: int) -> str:
        """Originaltext der Tokens [a, b)."""
        if a >= b:
            return ""
        return self.sql[self.toks[a].start: self.toks[b - 1].end + 1]

    def skip_semicolons(self) -> None:
        while self.cur is not None and self.cur.token_type == TokenType.SEMICOLON:
            self.i += 1

    def read_var(self) -> str:
        """@name -> 'name' (lowercase)."""
        if self.cur is None or self.cur.token_type != TokenType.PARAMETER:
            raise Unsupported(f"Variable erwartet, gefunden {self.cur.text if self.cur else '<Ende>'!r}")
        self.i += 1
        name = self.cur.text
        self.i += 1
        return name.lower()

    def read_qualified_name(self) -> list[str]:
        parts = [self.cur.text]
        self.i += 1
        while self.cur is not None and self.cur.token_type == TokenType.DOT:
            self.i += 1
            parts.append(self.cur.text)
            self.i += 1
        return parts

    # ------------------------------------------------------------------ Extent-Scanner

    def scan_expr(self, start: int, stop_comma: bool = False, stop_words: set[str] = frozenset()) -> int:
        """Ende (exklusiv) eines Ausdrucks ab start."""
        depth = case = 0
        j = start
        while j < len(self.toks):
            t = self.toks[j]
            k = self.kw(t)
            if t.token_type == TokenType.L_PAREN:
                depth += 1
            elif t.token_type == TokenType.R_PAREN:
                if depth == 0:
                    return j
                depth -= 1
            elif k == "CASE":
                case += 1
            elif k == "END" and case > 0:
                case -= 1
            elif depth == 0 and case == 0:
                if t.token_type == TokenType.SEMICOLON:
                    return j
                if stop_comma and t.token_type == TokenType.COMMA:
                    return j
                if k in STMT_START or k in stop_words:
                    return j
            j += 1
        return j

    def scan_dml(self, start: int) -> int:
        """Ende (exklusiv) eines DML-Statements ab start."""
        kind = self.kw(self.toks[start])
        depth = case = 0
        seen_source = False          # INSERT: SELECT/VALUES/EXEC bereits gesehen
        seen_set = False             # UPDATE: SET bereits gesehen
        prev = ""
        j = start + 1
        while j < len(self.toks):
            t = self.toks[j]
            k = self.kw(t)
            if t.token_type == TokenType.L_PAREN:
                depth += 1
            elif t.token_type == TokenType.R_PAREN:
                depth -= 1
                if depth < 0:
                    return j
            elif k == "CASE":
                case += 1
            elif k == "END" and case > 0:
                case -= 1
            elif depth == 0 and case == 0:
                if t.token_type == TokenType.SEMICOLON:
                    return j
                if k in STMT_START:
                    nxt = self.toks[j + 1] if j + 1 < len(self.toks) else None
                    cont = False
                    if k == "SELECT" and prev in ("UNION", "ALL", "EXCEPT", "INTERSECT"):
                        cont = True
                    elif k == "WITH" and nxt is not None and nxt.token_type == TokenType.L_PAREN:
                        cont = True                                   # Tabellenhinweis WITH (NOLOCK)
                    elif kind == "WITH" and k in ("SELECT", "INSERT", "UPDATE", "DELETE", "MERGE"):
                        kind, cont = k, True
                        seen_source = k != "INSERT"
                    elif kind == "INSERT" and not seen_source and k in ("SELECT", "WITH", "EXEC", "EXECUTE"):
                        cont = seen_source = True
                    elif kind == "UPDATE" and k == "SET" and not seen_set:
                        cont = seen_set = True
                    elif kind == "MERGE" and k in ("UPDATE", "INSERT", "DELETE", "SET", "SELECT", "WITH"):
                        cont = True
                    elif kind == "CREATE" and k in ("SELECT", "WITH") and prev == "AS":
                        cont = True
                    if not cont:
                        return j
                elif kind == "INSERT" and k in ("VALUES", "DEFAULT"):
                    seen_source = True
            prev = k
            j += 1
        return j

    # ------------------------------------------------------------------ Statements

    def block(self, until: tuple[str, ...]) -> list[str]:
        out: list[str] = []
        while True:
            self.skip_semicolons()
            if self.cur is None:
                if until:
                    raise Unsupported(f"Unerwartetes Ende, erwartet {until}")
                return out
            if self.at(*until) and until:
                return out
            out += self.statement()

    def statement(self) -> list[str]:
        self.skip_semicolons()
        k = self.kw(self.cur)
        nxt = self.kw(self.peek())
        if k == "BEGIN":
            if nxt == "TRY":
                return self.try_catch()
            if nxt in ("TRAN", "TRANSACTION", "DISTRIBUTED"):
                return self.skip_tx()
            self.i += 1
            body = self.block(("END",))
            self.expect("END")
            return body
        if k in ("COMMIT", "ROLLBACK", "SAVE"):
            return self.skip_tx()
        if k == "DECLARE":
            return self.declare()
        if k == "SET":
            return self.set_stmt()
        if k == "IF":
            return self.if_stmt()
        if k == "WHILE":
            return self.while_stmt()
        if k == "RETURN":
            return self.return_stmt()
        if k == "THROW":
            return self.throw_stmt()
        if k == "RAISERROR":
            return self.raiserror_stmt()
        if k == "PRINT":
            self.i += 1
            e = self.scan_expr(self.i)
            expr = self.expr(self.i, e)
            self.i = e
            return [f"RAISE NOTICE '%', {expr};"]
        if k in ("EXEC", "EXECUTE"):
            return self.exec_stmt()
        if k == "BREAK":
            self.i += 1
            return ["EXIT;"]
        if k == "CONTINUE":
            self.i += 1
            return ["CONTINUE;"]
        if k in ("OPEN", "FETCH", "CLOSE", "DEALLOCATE"):
            raise Unsupported("Cursor werden nicht unterstützt")
        if k in ("GOTO", "WAITFOR"):
            raise Unsupported(f"{k} wird nicht unterstützt")
        if k in DML_START:
            return self.dml()
        if self.cur is not None and self.cur.token_type == TokenType.VAR and self.peek() is not None \
                and self.peek().token_type == TokenType.COLON:
            raise Unsupported("Sprungmarken (GOTO) werden nicht unterstützt")
        raise Unsupported(f"Unbekanntes Statement {self.cur.text!r} (Zeile {self.cur.line})")

    def skip_tx(self) -> list[str]:
        self.ctx.warn("Transaktionssteuerung (BEGIN TRAN/COMMIT/ROLLBACK) entfernt – Funktion läuft in der Transaktion des Aufrufers")
        self.i += 1
        if self.at("TRAN", "TRANSACTION", "WORK", "DISTRIBUTED"):
            self.i += 1
            if self.at("TRAN", "TRANSACTION"):
                self.i += 1
            # optionaler Name
            if self.cur is not None and self.cur.token_type in (TokenType.VAR, TokenType.PARAMETER) \
                    and self.kw(self.cur) not in STMT_START:
                if self.cur.token_type == TokenType.PARAMETER:
                    self.i += 1
                self.i += 1
        return []

    def try_catch(self) -> list[str]:
        self.expect("BEGIN")
        self.expect("TRY")
        body = self.block(("END",))
        self.expect("END")
        self.expect("TRY")
        self.skip_semicolons()
        self.expect("BEGIN")
        self.expect("CATCH")
        handler = self.block(("END",))
        self.expect("END")
        self.expect("CATCH")
        return ["BEGIN", *_ind(body), "EXCEPTION WHEN OTHERS THEN", *_ind(handler or ["NULL;"]), "END;"]

    def declare(self) -> list[str]:
        self.expect("DECLARE")
        out: list[str] = []
        while True:
            if self.cur is not None and self.cur.token_type != TokenType.PARAMETER and self.kw(self.peek()) == "CURSOR":
                raise Unsupported("Cursor werden nicht unterstützt")
            var = self.read_var()
            if self.at("AS"):
                self.i += 1
            if self.at("CURSOR"):
                raise Unsupported("Cursor werden nicht unterstützt")
            if self.at("TABLE"):
                out += self.table_variable(var)
                if self.cur is not None and self.cur.token_type == TokenType.COMMA:
                    self.i += 1
                    continue
                return out
            e = self.scan_expr(self.i, stop_comma=True, stop_words={"="})
            typ = self.pg_type_text(self.text(self.i, e))
            self.i = e
            name = self.add_local(var, typ)
            if self.cur is not None and self.cur.token_type == TokenType.EQ:
                self.i += 1
                e = self.scan_expr(self.i, stop_comma=True)
                out.append(f"{name} := {self.expr(self.i, e)};")
                self.i = e
            if self.cur is not None and self.cur.token_type == TokenType.COMMA:
                self.i += 1
                continue
            return out

    def table_variable(self, var: str) -> list[str]:
        """DECLARE @t TABLE (...) -> Temp-Tabelle tmp_t."""
        self.expect("TABLE")
        start = self.i
        self.expect("(")
        end = self.scan_expr(self.i)
        self.i = end
        self.expect(")")
        tname = f"tmp_{pg_name(var)}"
        self.ctx.table_vars[var] = tname
        cols_sql = self.text(start, self.i)
        tree = sqlglot.parse_one(f"CREATE TABLE {tname} {cols_sql}", read="tsql", error_level=sqlglot.ErrorLevel.RAISE)
        self.ctx.temp_tables[tname] = tname
        body = to_pg(normalize(tree, self.ctx))
        body = re.sub(r"^CREATE\s+TABLE", "CREATE TEMP TABLE", body)
        self.ctx.warn("Tabellenvariable als Temp-Tabelle umgesetzt")
        return [f"DROP TABLE IF EXISTS {tname};", *_lines(body + ";")]

    def set_stmt(self) -> list[str]:
        self.expect("SET")
        if self.cur is not None and self.cur.token_type == TokenType.PARAMETER:
            var = self.read_var()
            target = self.ctx.variables.get(var)
            if target is None:
                raise Unsupported(f"Unbekannte Variable @{var}")
            op = ""
            if self.cur.token_type in (TokenType.PLUS, TokenType.DASH, TokenType.STAR, TokenType.SLASH):
                op = self.cur.text
                self.i += 1
            if self.cur is None or self.cur.token_type != TokenType.EQ:
                raise Unsupported(f"SET @{var}: '=' erwartet")
            self.i += 1
            e = self.scan_expr(self.i)
            value = self.expr(self.i, e)
            self.i = e
            if op == "+":
                # += auf Strings ist Verkettung, auf Zahlen Addition – Typ entscheidet
                op = "||" if self.is_text_var(target) else "+"
            return [f"{target} := {target} {op} ({value});" if op else f"{target} := {value};"]
        k = self.kw(self.cur)
        if k in SET_OPTIONS:
            self.i += 1
            while self.cur is not None and self.kw(self.cur) not in STMT_START \
                    and self.cur.token_type != TokenType.SEMICOLON:
                self.i += 1
                if self.kw(self.toks[self.i - 1]) in ("ON", "OFF") or self.toks[self.i - 1].token_type == TokenType.NUMBER:
                    break
            return []
        if k == "TRANSACTION":
            self.ctx.warn("SET TRANSACTION ISOLATION LEVEL entfernt")
            while self.cur is not None and self.kw(self.cur) not in ("UNCOMMITTED", "COMMITTED", "READ", "REPEATABLE",
                                                                      "SERIALIZABLE", "SNAPSHOT"):
                self.i += 1
            while self.at("READ", "UNCOMMITTED", "COMMITTED", "REPEATABLE", "SERIALIZABLE", "SNAPSHOT"):
                self.i += 1
            return []
        raise Unsupported(f"SET {self.cur.text if self.cur else ''} nicht unterstützt")

    def if_stmt(self) -> list[str]:
        self.expect("IF")
        e = self.scan_expr(self.i)
        cond = self.expr(self.i, e)
        self.i = e
        then = self.statement()
        self.skip_semicolons()
        out = [f"IF {cond} THEN", *_ind(then or ["NULL;"])]
        if self.at("ELSE"):
            self.i += 1
            if self.at("IF"):
                rest = self.if_stmt()
                # ELSE IF -> ELSIF
                out.append("ELSIF " + rest[0][3:])
                out += rest[1:-1]
            else:
                out += ["ELSE", *_ind(self.statement() or ["NULL;"])]
        out.append("END IF;")
        return out

    def while_stmt(self) -> list[str]:
        self.expect("WHILE")
        e = self.scan_expr(self.i)
        cond = self.expr(self.i, e)
        self.i = e
        body = self.statement()
        return [f"WHILE {cond} LOOP", *_ind(body or ["NULL;"]), "END LOOP;"]

    def return_stmt(self) -> list[str]:
        self.expect("RETURN")
        e = self.scan_expr(self.i)
        if e == self.i or self.r.kind == "tvf":
            self.i = e
            return ["RETURN;"]
        value = self.expr(self.i, e)
        self.i = e
        if self.r.kind == "scalar":
            return [f"RETURN {value};"]
        self.ctx.warn("RETURN-Wert einer Prozedur entfernt")
        return ["RETURN;"]

    def throw_stmt(self) -> list[str]:
        self.expect("THROW")
        if self.cur is None or self.at("END", "ELSE") or self.cur.token_type == TokenType.SEMICOLON:
            return ["RAISE;"]
        args = self.arg_list(self.scan_expr(self.i))
        if len(args) != 3:
            raise Unsupported("THROW mit unerwarteten Argumenten")
        return [f"RAISE EXCEPTION '%', {args[1]} USING DETAIL = 'THROW ' || ({args[0]})::text;"]

    def raiserror_stmt(self) -> list[str]:
        self.expect("RAISERROR")
        self.expect("(")
        end = self.scan_expr(self.i)
        args = self.arg_list(end)
        self.expect(")")
        if self.at("WITH"):
            self.i += 1
            while self.at("NOWAIT", "LOG", "SETERROR") or (self.cur and self.cur.token_type == TokenType.COMMA):
                self.i += 1
        if len(args) > 3:
            self.ctx.warn("RAISERROR-Formatargumente ignoriert")
        level = "EXCEPTION"
        try:
            if int(args[1]) <= 10:
                level = "NOTICE"
        except (ValueError, IndexError):
            pass
        return [f"RAISE {level} '%', {args[0]};"]

    def exec_stmt(self) -> list[str]:
        self.i += 1
        if self.cur is not None and self.cur.token_type == TokenType.L_PAREN:
            self.i += 1
            e = self.scan_expr(self.i)
            sql = self.expr(self.i, e)
            self.i = e
            self.expect(")")
            self.ctx.warn("Dynamisches SQL (EXEC) – Inhalt ist weiterhin T-SQL")
            return [f"EXECUTE {sql};"]
        if self.cur is not None and self.cur.token_type == TokenType.PARAMETER and self.peek(2) is not None \
                and self.peek(2).token_type == TokenType.EQ:
            raise Unsupported("EXEC @rc = proc (Rückgabewert) wird nicht unterstützt")
        name = self.read_qualified_name()
        end = self.scan_expr(self.i)
        if name[-1].lower() == "sp_executesql":
            args = self.arg_list(end)
            if len(args) > 1:
                raise Unsupported("sp_executesql mit Parametern wird nicht unterstützt")
            self.ctx.warn("Dynamisches SQL (sp_executesql) – Inhalt ist weiterhin T-SQL")
            return [f"EXECUTE {args[0]};"]
        args = self.arg_list(end, named=True)
        fn = ".".join(quote(pg_name(p)) for p in name[-2:])
        return [f"PERFORM {fn}({', '.join(args)});"]

    def arg_list(self, end: int, named: bool = False) -> list[str]:
        args = []
        while self.i < end:
            prefix = ""
            if named and self.cur.token_type == TokenType.PARAMETER and self.peek(2) is not None \
                    and self.peek(2).token_type == TokenType.EQ:
                pname = self.toks[self.i + 1].text
                prefix = f"p_{pg_name(pname)} => "
                self.i += 3
            e = self.scan_expr(self.i, stop_comma=True)
            if self.at("OUTPUT", "OUT") or "OUTPUT" in self.text(self.i, e).upper().split():
                raise Unsupported("EXEC mit OUTPUT-Parametern wird nicht unterstützt")
            args.append(prefix + self.expr(self.i, e))
            self.i = e
            if self.cur is not None and self.cur.token_type == TokenType.COMMA and self.i < end:
                self.i += 1
        self.i = end
        return args

    # ------------------------------------------------------------------ DML

    def dml(self) -> list[str]:
        start = self.i
        end = self.scan_dml(start)
        sql = self.text(start, end)
        self.i = end
        try:
            tree = sqlglot.parse_one(sql, read="tsql", error_level=sqlglot.ErrorLevel.RAISE)
        except sqlglot.errors.ParseError as e:
            raise Unsupported(f"DML nicht parsebar (Zeile {self.toks[start].line}): {str(e).splitlines()[0]}") from e
        if isinstance(tree, exp.Command):
            raise Unsupported(f"Nicht unterstütztes Statement (Zeile {self.toks[start].line}): {sql.strip()[:60]!r}")
        out = self.translate_dml(tree)
        if self.r.uses_rowcount and isinstance(tree, (exp.Insert, exp.Update, exp.Delete, exp.Merge, exp.Select)):
            out.append("GET DIAGNOSTICS v_rowcount = ROW_COUNT;")
        return out

    def norm(self, tree: exp.Expr) -> exp.Expr:
        """normalize + Typinferenz auf den äußersten SELECTs (DML-Ziele bleiben unqualifiziert)."""
        tree = normalize(tree, self.ctx)
        if self.types is None:
            return tree
        if isinstance(tree, (exp.Select, exp.SetOperation)):
            return coerce(tree, self.types, self.ctx)
        def nested(node: exp.Expr) -> bool:
            a = node.parent
            while a is not None and a is not tree:
                if isinstance(a, (exp.Select, exp.SetOperation)):
                    return True
                a = a.parent
            return False

        outer = [s for s in tree.find_all(exp.Select, exp.SetOperation) if not nested(s)]
        for s in outer:
            s.replace(coerce(s, self.types, self.ctx))
        return tree

    def translate_dml(self, tree: exp.Expr) -> list[str]:
        ctx = self.ctx
        # INSERT INTO @rueckgabe ... (Multi-Statement-TVF) -> RETURN QUERY
        if isinstance(tree, exp.Insert) and self.r.return_table:
            target = tree.this.this if isinstance(tree.this, exp.Schema) else tree.this
            if isinstance(target, exp.Table) and isinstance(target.this, exp.Parameter) \
                    and target.this.name.lower() == self.r.return_table:
                q = tree.expression
                if isinstance(q, exp.Values):
                    q = exp.select(*q.expressions[0].expressions) if len(q.expressions) == 1 else q
                return [*_lines(f"RETURN QUERY {to_pg(self.norm(q))};")]
        for t in tree.find_all(exp.Table):
            if isinstance(t.this, exp.Parameter) and t.this.name.lower() not in ctx.table_vars:
                raise Unsupported(f"Unbekannte Tabellenvariable @{t.this.name}")

        # SELECT @a = x, @b = y [FROM ...]  -> Zuweisung
        if isinstance(tree, exp.Select) and tree.expressions and all(
                isinstance(e, exp.EQ) and isinstance(e.this, exp.Parameter) for e in tree.expressions):
            targets = []
            for e in tree.expressions:
                var = e.this.name.lower()
                if var not in ctx.variables:
                    raise Unsupported(f"Unbekannte Variable @{var}")
                targets.append(ctx.variables[var])
            tree.set("expressions", [e.expression for e in tree.expressions])
            if not tree.args.get("from_") and len(targets) == 1 and not tree.args.get("where"):
                return [f"{targets[0]} := {to_pg(normalize(tree.expressions[0], ctx), pretty=False)};"]
            body = to_pg(self.norm(tree))
            # INTO direkt hinter die Select-Liste (vor FROM) setzen
            into = f"INTO {', '.join(targets)}"
            m = re.search(r"\nFROM\b", body)
            body = body[: m.start()] + f"\n{into}" + body[m.start():] if m else body + f"\n{into}"
            return _lines(body + ";")

        # SELECT ... INTO #tmp -> CREATE TEMP TABLE ... AS
        if isinstance(tree, exp.Select) and tree.args.get("into"):
            into = tree.args["into"]
            tree.set("into", None)
            tname = self.temp_name(into.this)
            body = to_pg(self.norm(tree))
            return [f"DROP TABLE IF EXISTS {tname};", *_lines(f"CREATE TEMP TABLE {tname} AS\n{body};")]

        if isinstance(tree, exp.Select):
            raise Unsupported("Resultset aus Prozedur (SELECT ohne Zuweisung) – Rückgabetyp manuell festlegen (Override)")

        if isinstance(tree, exp.Create) and tree.kind == "TABLE":
            t = tree.this.this if isinstance(tree.this, exp.Schema) else tree.this
            if isinstance(t, exp.Table) and t.this.args.get("temporary"):
                tname = self.temp_name(t)
                body = to_pg(normalize(tree, ctx))
                body = re.sub(r"^CREATE\s+(TEMPORARY\s+)?TABLE", "CREATE TEMP TABLE", body)
                return [f"DROP TABLE IF EXISTS {tname};", *_lines(body + ";")]
            ctx.warn("CREATE TABLE (permanent) in Routine übernommen")
            return _lines(to_pg(normalize(tree, ctx)) + ";")

        if isinstance(tree, exp.Drop):
            for t in tree.args.get("tables") or []:
                if t.this.args.get("temporary"):
                    self.temp_name(t)
            tree.set("exists", True)

        if isinstance(tree, exp.Update):
            _fix_update_from(tree)
        if isinstance(tree, exp.Delete):
            _fix_delete_from(tree)

        return _lines(to_pg(self.norm(tree)) + ";")

    def temp_name(self, table: exp.Expr) -> str:
        name = table.name.lstrip("#").lower()
        return self.ctx.temp_tables.setdefault(name, f"tmp_{pg_name(name)}")

    # ------------------------------------------------------------------ Ausdrücke / Typen

    def expr(self, a: int, b: int) -> str:
        sql = self.text(a, b).strip()
        if not sql:
            raise Unsupported(f"Leerer Ausdruck (Zeile {self.toks[a].line if a < len(self.toks) else '?'})")
        try:
            tree = sqlglot.parse_one(f"SELECT {sql}", read="tsql", error_level=sqlglot.ErrorLevel.RAISE)
        except sqlglot.errors.ParseError as e:
            raise Unsupported(f"Ausdruck nicht parsebar: {sql[:60]!r}") from e
        if not isinstance(tree, exp.Select) or len(tree.expressions) != 1 or tree.args.get("from_"):
            raise Unsupported(f"Ausdruck nicht eindeutig: {sql[:60]!r}")
        return to_pg(normalize(tree.expressions[0], self.ctx), pretty=False)

    def pg_type_text(self, tsql_type: str) -> str:
        t = re.sub(r"\[([^\]]+)\]", r"\1", tsql_type.strip())
        t = re.sub(r"\s+\(", "(", t)
        try:
            dt = exp.DataType.build(t, dialect="tsql")
        except Exception as e:  # noqa: BLE001
            raise Unsupported(f"Datentyp nicht erkannt: {t!r}") from e
        return map_datatype(dt).sql(dialect="postgres").lower()

    def add_local(self, var: str, typ: str) -> str:
        name = f"v_{pg_name(var)}"
        if var in self.ctx.variables and name in self.r.decl_names:
            return name   # Re-Deklaration (z.B. in getrennten Blöcken) – einmal reicht
        self.ctx.variables[var] = name
        self.r.decl_names.add(name)
        self.r.decls.append(f"{name} {typ};")
        self._types[name] = typ
        return name

    def is_text_var(self, name: str) -> bool:
        t = self._types.get(name, "")
        return t.startswith(("varchar", "text", "char"))


def _ind(lines: list[str]) -> list[str]:
    return ["    " + line if line else line for line in lines]


def _lines(text: str) -> list[str]:
    return text.splitlines()


# --------------------------------------------------------------------------- UPDATE/DELETE mit Alias


def _alias_target(target: exp.Table, frm: exp.Table) -> bool:
    if target.args.get("db"):
        return False
    return frm.alias_or_name.lower() == target.name.lower()


def _join_to_where(joins: list[exp.Join]) -> tuple[list[exp.Expr], exp.Expr | None]:
    """Erster INNER JOIN wird FROM/USING-Element, seine ON-Bedingung wandert ins WHERE."""
    if not joins:
        return [], None
    first = joins[0]
    if first.side or (first.kind and first.kind.upper() not in ("INNER", "")):
        raise Unsupported("UPDATE/DELETE ... FROM mit OUTER JOIN auf die Zieltabelle")
    item = first.this.copy()
    if joins[1:]:
        item.set("joins", [j.copy() for j in joins[1:]])
    return [item], first.args.get("on")


def _and(a: exp.Expr | None, b: exp.Expr | None) -> exp.Expr | None:
    if a is None:
        return b
    if b is None:
        return a
    return exp.and_(exp.Paren(this=a.copy()), exp.Paren(this=b.copy()))


def _fix_update_from(tree: exp.Update) -> None:
    """UPDATE a SET ... FROM schema.t a JOIN u ON ... -> UPDATE schema.t AS a SET ... FROM u WHERE ..."""
    frm = tree.args.get("from_")
    if frm is None:
        return
    first = frm.this
    if not isinstance(first, exp.Table) or not _alias_target(tree.this, first):
        return
    joins = first.args.get("joins") or []
    target = first.copy()
    target.set("joins", None)
    tree.set("this", target)
    items, on = _join_to_where(joins)
    where = tree.args.get("where")
    cond = _and(on, where.this if where else None)
    if items:
        tree.set("from_", exp.From(this=items[0]))
    else:
        tree.set("from_", None)
    tree.set("where", exp.Where(this=cond) if cond is not None else None)
    # SET-Spalten dürfen in PG kein Alias-Präfix haben
    for eq in tree.expressions:
        if isinstance(eq.this, exp.Column):
            eq.this.set("table", None)


def _fix_delete_from(tree: exp.Delete) -> None:
    """DELETE a FROM schema.t a JOIN u ON ... -> DELETE FROM schema.t AS a USING u WHERE ..."""
    tables = tree.args.get("tables")
    if not tables:
        return
    src = tree.this
    if not isinstance(src, exp.Table) or not _alias_target(tables[0], src):
        raise Unsupported("DELETE mit mehreren Tabellen")
    joins = src.args.get("joins") or []
    target = src.copy()
    target.set("joins", None)
    tree.set("this", target)
    tree.set("tables", None)
    items, on = _join_to_where(joins)
    where = tree.args.get("where")
    cond = _and(on, where.this if where else None)
    if items:
        tree.set("using", items)
    else:
        tree.set("using", None)
    tree.set("where", exp.Where(this=cond) if cond is not None else None)


# --------------------------------------------------------------------------- Kopf (CREATE PROC/FUNCTION)


def _header(p: Parser, r: Routine, obj_type: str) -> None:
    while p.cur is not None and not p.at("CREATE"):
        p.i += 1
    p.expect("CREATE")
    if p.at("OR"):
        p.i += 2   # OR ALTER
    k = p.kw(p.cur)
    if k not in ("PROC", "PROCEDURE", "FUNCTION"):
        raise Unsupported(f"CREATE {k} erwartet PROCEDURE/FUNCTION")
    p.i += 1
    p.read_qualified_name()
    in_parens = p.cur is not None and p.cur.token_type == TokenType.L_PAREN
    if in_parens:
        p.i += 1
    while p.cur is not None and p.cur.token_type == TokenType.PARAMETER:
        var = p.read_var()
        if p.at("AS"):
            p.i += 1
        e = p.scan_expr(p.i, stop_comma=True, stop_words={"=", "OUTPUT", "OUT", "READONLY", "AS"})
        # scan_expr stoppt bei '=' nicht (kein Keyword) -> manuell
        j = p.i
        depth = 0
        while j < e:
            tt = p.toks[j].token_type
            if tt == TokenType.L_PAREN:
                depth += 1
            elif tt == TokenType.R_PAREN:
                depth -= 1
            elif tt == TokenType.EQ and depth == 0:
                break
            j += 1
        e = j
        typ = p.pg_type_text(p.text(p.i, e))
        p.i = e
        default = None
        if p.cur is not None and p.cur.token_type == TokenType.EQ:
            p.i += 1
            de = p.scan_expr(p.i, stop_comma=True, stop_words={"OUTPUT", "OUT", "READONLY", "AS"})
            default = p.expr(p.i, de)
            p.i = de
        mode = ""
        if p.at("OUTPUT", "OUT"):
            p.i += 1
            mode = "INOUT "
            r.has_out = True
        if p.at("READONLY"):
            raise Unsupported("Tabellenwertparameter (READONLY) werden nicht unterstützt")
        name = f"p_{pg_name(var)}"
        p.ctx.variables[var] = name
        p._types[name] = typ
        r.params.append(f"{mode}{name} {typ}" + (f" DEFAULT {default}" if default is not None else ""))
        if p.cur is not None and p.cur.token_type == TokenType.COMMA:
            p.i += 1
    if in_parens:
        p.expect(")")

    if obj_type == "function":
        p.expect("RETURNS")
        if p.cur.token_type == TokenType.PARAMETER:
            r.kind = "tvf"
            r.return_table = p.read_var()
            p.expect("TABLE")
            p.expect("(")
            end = p.scan_expr(p.i)
            cols = []
            while p.i < end:
                ce = p.scan_expr(p.i, stop_comma=True)
                parts = p.text(p.i, ce).split(None, 1)
                if len(parts) != 2:
                    raise Unsupported("Rückgabetabelle nicht erkannt")
                cname = pg_name(parts[0])
                cols.append(f"{quote(cname)} {p.pg_type_text(parts[1])}")
                p.i = ce
                if p.cur.token_type == TokenType.COMMA:
                    p.i += 1
            p.expect(")")
            r.returns = f"TABLE ({', '.join(cols)})"
        elif p.at("TABLE"):
            raise Unsupported("Inline-Table-Valued-Function: Rückgabespalten manuell festlegen (Override)")
        else:
            r.kind = "scalar"
            e = p.i
            while e < len(p.toks) and p.kw(p.toks[e]) not in ("AS", "WITH", "BEGIN"):
                e += 1
            r.returns = p.pg_type_text(p.text(p.i, e))
            p.i = e
    if p.at("WITH"):
        p.i += 1
        while p.cur is not None and not p.at("AS"):
            p.i += 1
    p.expect("AS")


def convert_routine(src: SourceObject, getdate: str, types: TypeSchema | None = None) -> PgObject:
    obj = PgObject(src.key, src.type, pg_name(src.schema), pg_name(src.name), source=str(src.path))
    ctx = Ctx(getdate=getdate)
    r = Routine(kind="procedure")
    body_batches = [b for b in src.batches if re.search(r"\bCREATE\s+(OR\s+ALTER\s+)?(PROC|PROCEDURE|FUNCTION)\b", b, re.I)]
    try:
        if len(body_batches) != 1:
            raise Unsupported(f"{len(body_batches)} CREATE PROCEDURE/FUNCTION im Skript")
        sql = body_batches[0]
        # OBJECT_NAME(@@PROCID) -> eigener Name
        sql = re.sub(r"OBJECT_NAME\s*\(\s*@@PROCID\s*\)", f"'{src.schema}.{src.name}'", sql, flags=re.I)
        r.uses_rowcount = bool(re.search(r"@@ROWCOUNT", sql, re.I))
        if r.uses_rowcount:
            ctx.system_vars["rowcount"] = "v_rowcount"
            r.decls.append("v_rowcount bigint := 0;")
            ctx.var_types["v_rowcount"] = "bigint"
        ctx.system_vars.update({"trancount": "0", "error": "0", "servername": "inet_server_addr()::text",
                                "identity": "lastval()"})
        if re.search(r"@@IDENTITY|SCOPE_IDENTITY\s*\(", sql, re.I):
            ctx.warn("@@IDENTITY/SCOPE_IDENTITY() als lastval() übersetzt")
        p = Parser(sql, ctx, r, types)
        _header(p, r, src.type)
        body = p.block(())
    except Unsupported as e:
        obj.fail(str(e))
        return obj
    except Exception as e:  # noqa: BLE001
        obj.fail(f"Fehler: {type(e).__name__}: {str(e).splitlines()[0] if str(e) else ''}")
        return obj
    for w in ctx.warnings:
        obj.warn(w)
    if r.has_out:
        obj.warn("OUTPUT-Parameter als INOUT übersetzt – Aufrufer prüfen")
    returns = "" if (r.has_out and r.kind == "procedure") else f"RETURNS {r.returns}\n"
    decl = ""
    if r.kind == "tvf":
        decl += "#variable_conflict use_column\n"
    if r.decls:
        decl += "DECLARE\n" + "\n".join(_ind(r.decls)) + "\n"
    params = (",\n    ".join(r.params))
    params = f"\n    {params}\n" if params else ""
    obj.sql = (
        f"CREATE FUNCTION {quote(obj.pg_schema)}.{quote(obj.pg_name)}({params})\n"
        f"{returns}LANGUAGE plpgsql\nAS $fn$\n{decl}BEGIN\n" + "\n".join(_ind(body)) + "\nEND\n$fn$;\n"
    )
    return obj
