"""Abhängigkeiten zwischen Objekten + topologische Sortierung.

Referenzen werden auf Token-Ebene gesucht (funktioniert auch für Prozeduren, die sqlglot
nicht vollständig parsen kann): jede Folge `name.name` (bzw. 3-/4-teilig) und jeder
einteilige Name, der einem bekannten Objekt entspricht (einteilig -> Schema dbo).
"""

from __future__ import annotations

import heapq
from collections import defaultdict

from sqlglot.dialects.postgres import Postgres
from sqlglot.tokens import TokenType

from .naming import unbracket

_PG = Postgres()


def _names(sql: str, dialect: str) -> list[list[str]]:
    """Alle (ggf. mehrteiligen) Bezeichnerketten im SQL, lowercase."""
    try:
        if dialect == "tsql":
            from .convert.routines import tokenize
            tokens = tokenize(sql)
        else:
            tokens = _PG.tokenize(sql)
    except Exception:  # noqa: BLE001 – Tokenizerfehler: keine Abhängigkeiten statt Abbruch
        return []
    chains: list[list[str]] = []
    cur: list[str] = []
    expect_name = True
    for tok in tokens:
        is_name = tok.token_type == TokenType.IDENTIFIER or (
            tok.token_type != TokenType.STRING and (tok.text[:1].isalpha() or tok.text[:1] == "_"))
        if tok.token_type == TokenType.DOT and cur:
            expect_name = True
            continue
        if is_name and expect_name:
            cur.append(unbracket(tok.text).lower())
            expect_name = False
            continue
        if cur:
            chains.append(cur)
        cur = [unbracket(tok.text).lower()] if is_name else []
        expect_name = not is_name
    if cur:
        chains.append(cur)
    return chains


def find_references(sql: str, known: dict[str, str], self_key: str, dialect: str = "tsql",
                    default_schema: str = "dbo") -> tuple[set[str], set[str]]:
    """-> (Schlüssel bekannter Objekte, referenzierte Schemas aller mehrteiligen Namen).

    known: Lookup 'schema.name' (MSSQL- oder PG-Schreibweise, lowercase) -> Objektschlüssel.
    """
    refs: set[str] = set()
    schemas: set[str] = set()
    for chain in _names(sql, dialect):
        if len(chain) >= 2:
            schema, name = chain[-2], chain[-1]
            schemas.add(schema)
            k = known.get(f"{schema}.{name}")
            if k is None and len(chain) >= 3:
                # schema.tabelle.spalte
                k = known.get(f"{chain[-3]}.{chain[-2]}")
            if k:
                refs.add(k)
        else:
            k = known.get(f"{default_schema}.{chain[0]}")
            if k:
                refs.add(k)
    refs.discard(self_key)
    return refs, schemas


def topo_order(nodes: list[str], deps: dict[str, list[str]], tiebreak) -> tuple[list[str], list[str]]:
    """Kahn-Algorithmus, deterministisch über tiebreak(key). -> (Reihenfolge, Knoten in Zyklen)."""
    node_set = set(nodes)
    indeg = {n: 0 for n in nodes}
    rev: dict[str, list[str]] = defaultdict(list)
    for n in nodes:
        for d in set(deps.get(n, [])):
            if d in node_set:
                indeg[n] += 1
                rev[d].append(n)
    order: list[str] = []
    heap = [(tiebreak(n), n) for n in nodes if indeg[n] == 0]
    heapq.heapify(heap)
    while heap:
        _, n = heapq.heappop(heap)
        order.append(n)
        for m in rev[n]:
            indeg[m] -= 1
            if indeg[m] == 0:
                heapq.heappush(heap, (tiebreak(m), m))
    cyclic = sorted(n for n in nodes if indeg[n] > 0)
    return order, cyclic
