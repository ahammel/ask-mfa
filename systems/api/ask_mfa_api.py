from abc import ABC, abstractmethod
from dataclasses import asdict, dataclass
import os
from typing import List

import psycopg2

HOST = os.environ.get("ASK_MFA_POSTGRES_HOST")
PORT = os.environ.get("ASK_MFA_POSTGRES_PORT")
DB = os.environ.get("ASK_MFA_POSTGRESS_DB")
USER = os.environ.get("ASK_MFA_POSTGRES_USER")
PASSWORD = os.environ.get("ASK_MFA_POSTGRES_PASSWORD")

## Core


@dataclass(eq=True, frozen=True)
class QueryResult:
    """Single row of a query result"""

    question_id: str
    answer_id: str
    answer_parent_id: str
    question_text: str
    answer_text: str
    question_author: str
    answer_author: str
    question_score: int
    answer_score: int
    question_permalink: str
    answer_permalink: str
    thread_id: str
    thread_created_utc: int
    relevance: float


class QueryProvider(ABC):
    """Interface to text search queries."""

    @abstractmethod
    def text_search(self, query: str) -> List[QueryResult]:
        """Returns the top threads matching the query string, sorted by
        relevance.
        """


### DB


class DbQueryPovider(QueryProvider):
    """QueryProvider using Postgres as the storage medium."""

    def __init__(self, conn):
        self.conn = conn

    def text_search(self, query: str) -> List[QueryResult]:
        with self.conn.cursor() as curs:
            curs.execute("SELECT * FROM text_search(%s);", [query])
            return [QueryResult(*row) for row in curs.fetchall()]


if __name__ == "__main__":
    from pprint import pprint

    conn = psycopg2.connect(
        host=HOST, port=PORT, dbname=DB, user=USER, password=PASSWORD
    )
    try:
        query_provider = DbQueryPovider(conn)
        pprint(
            [asdict(res) for res in query_provider.text_search("margiela gat sizing")]
        )
    finally:
        conn.close()
