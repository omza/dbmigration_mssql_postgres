"""Verbindung zu MS SQL Server.

Bevorzugt `mssql-python` (Microsoft, pip-installierbar, kein System-ODBC nötig),
Fallback `pyodbc` (braucht unixODBC + ODBC Driver 18).

Connection-String im ODBC-Stil, z.B.:
  SERVER=sqlhost,1433;DATABASE=EnergyDWH;UID=migration;PWD=...;Encrypt=yes;TrustServerCertificate=yes
"""

from __future__ import annotations


def connect(conn_str: str):
    try:
        import mssql_python  # type: ignore

        return mssql_python.connect(conn_str)
    except ImportError:
        pass
    try:
        import pyodbc  # type: ignore
    except ImportError as e:  # pragma: no cover
        raise RuntimeError(
            "Kein MSSQL-Treiber installiert: `uv sync --extra mssql` (mssql-python) "
            "oder pyodbc + ODBC Driver 18 installieren"
        ) from e
    if "driver=" not in conn_str.lower():
        conn_str = "DRIVER={ODBC Driver 18 for SQL Server};" + conn_str
    return pyodbc.connect(conn_str)
