"""Capa de conexión: SQLite (local) o PostgreSQL/Supabase vía DATABASE_URL."""

from __future__ import annotations

import os
import re
import sqlite3
from typing import Any

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQLITE_CATALOG_PATH = os.path.join(BASE_DIR, "instance", "alworki.db")
SQLITE_AUTH_PATH = os.path.join(BASE_DIR, "instance", "auth.db")


def is_postgres() -> bool:
    return bool(os.getenv("DATABASE_URL", "").strip())


def _row_to_mapping(cursor, row: Any) -> Any:
    if row is None:
        return None
    if isinstance(row, dict):
        return row
    if cursor.description:
        cols = [d[0] for d in cursor.description]
        return {cols[i]: row[i] for i in range(len(cols))}
    return row


class _CompatCursor:
    def __init__(self, raw_cursor, connection: "_CompatConnection"):
        self._raw = raw_cursor
        self._conn = connection
        self.lastrowid: int | None = None
        self.rowcount: int = getattr(raw_cursor, "rowcount", -1)

    def fetchone(self) -> Any:
        return _row_to_mapping(self._raw, self._raw.fetchone())

    def fetchall(self) -> list[Any]:
        return [_row_to_mapping(self._raw, r) for r in self._raw.fetchall()]


class _CompatCursorWrapper:
    def __init__(self, connection: "_CompatConnection"):
        self._conn = connection
        self.lastrowid: int | None = None

    def execute(self, sql: str, params: tuple | list = ()) -> _CompatCursor:
        cur = self._conn.execute(sql, params)
        self.lastrowid = cur.lastrowid
        return cur


class _CompatConnection:
    """Emula sqlite3.Connection para catalog_db y auth."""

    def __init__(self, raw, *, postgres: bool):
        self._raw = raw
        self._postgres = postgres
        self._last_cursor: _CompatCursor | None = None

    def _adapt_sql(self, sql: str) -> str:
        if not self._postgres:
            return sql
        sql = sql.replace("?", "%s")
        sql = re.sub(
            r"\bINSERT OR REPLACE\b",
            "INSERT",
            sql,
            flags=re.IGNORECASE,
        )
        return sql

    def execute(self, sql: str, params: tuple | list = ()) -> _CompatCursor:
        sql_adapted = self._adapt_sql(sql)
        cur = self._raw.cursor()
        args = tuple(params) if params else ()
        is_insert = sql_adapted.strip().upper().startswith("INSERT INTO")
        if self._postgres and is_insert and "RETURNING" not in sql_adapted.upper():
            sql_adapted = sql_adapted.rstrip().rstrip(";") + " RETURNING id"
        if args:
            cur.execute(sql_adapted, args)
        else:
            cur.execute(sql_adapted)
        compat = _CompatCursor(cur, self)
        if self._postgres and is_insert and "RETURNING" in sql_adapted.upper():
            row = cur.fetchone()
            if row is not None:
                compat.lastrowid = row["id"] if isinstance(row, dict) else row[0]
        elif not self._postgres:
            compat.lastrowid = cur.lastrowid
        self._last_cursor = compat
        return compat

    def cursor(self) -> _CompatCursorWrapper:
        return _CompatCursorWrapper(self)

    def commit(self) -> None:
        self._raw.commit()

    def close(self) -> None:
        self._raw.close()

    def executescript(self, script: str) -> None:
        if self._postgres:
            # En Postgres el esquema se aplica con supabase/migrations.
            return
        self._raw.executescript(script)


def get_catalog_connection() -> _CompatConnection:
    if is_postgres():
        import psycopg2
        from psycopg2.extras import RealDictCursor

        raw = psycopg2.connect(os.environ["DATABASE_URL"], cursor_factory=RealDictCursor)
        raw.autocommit = False
        return _CompatConnection(raw, postgres=True)

    os.makedirs(os.path.dirname(SQLITE_CATALOG_PATH), exist_ok=True)
    raw = sqlite3.connect(SQLITE_CATALOG_PATH)
    raw.row_factory = sqlite3.Row
    return _CompatConnection(raw, postgres=False)


def get_auth_connection() -> _CompatConnection:
    if is_postgres():
        return get_catalog_connection()

    os.makedirs(os.path.dirname(SQLITE_AUTH_PATH), exist_ok=True)
    raw = sqlite3.connect(SQLITE_AUTH_PATH)
    raw.row_factory = sqlite3.Row
    return _CompatConnection(raw, postgres=False)


def table_exists(conn: _CompatConnection, table: str) -> bool:
    if conn._postgres:
        row = conn.execute(
            """
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = %s
            LIMIT 1
            """,
            (table,),
        ).fetchone()
        return row is not None
    row = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return row is not None


def column_names(conn: _CompatConnection, table: str) -> set[str]:
    if conn._postgres:
        rows = conn.execute(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
            """,
            (table,),
        ).fetchall()
        return {r["column_name"] for r in rows}
    rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    return {r["name"] if isinstance(r, dict) else r[1] for r in rows}
