from dataclasses import asdict, dataclass
import os
from pprint import pprint
from typing import List

import psycopg2

HOST = os.environ.get("ASK_MFA_POSTGRES_HOST")
PORT = os.environ.get("ASK_MFA_POSTGRES_PORT")
DB = os.environ.get("ASK_MFA_POSTGRESS_DB")
USER = os.environ.get("ASK_MFA_POSTGRES_USER")
PASSWORD = os.environ.get("ASK_MFA_POSTGRES_PASSWORD")


## Service


def connect():
    """Returns a psycopg2 connection given postgresql connection params from the
    environment.

    """
    return psycopg2.connect(
        host=HOST, port=PORT, dbname=DB, user=USER, password=PASSWORD
    )


class CLIService:
    """Service which executes queries from the stdin in a loop, printing the results to
    stdout.

    """

    def __init__(self, query_provider):
        self.query_provider = query_provider

    def run(self):
        while True:
            try:
                query = input()
            except EOFError:
                break
            result = self.query_provider.text_search(query)
            pprint([asdict(row) for row in reversed(result)])


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


### DB


class DbQueryPovider:
    """QueryProvider using Postgres as the storage medium."""

    def __init__(self, conn):
        self.conn = conn

    def text_search(self, query: str) -> List[QueryResult]:
        with self.conn.cursor() as curs:
            curs.execute("SELECT * FROM text_search(%s);", [query])
            return [QueryResult(*row) for row in curs.fetchall()]


if __name__ == "__main__":
    conn = connect()
    try:
        CLIService(query_provider=DbQueryPovider(conn)).run()
    finally:
        conn.close()
