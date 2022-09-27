import os

import psycopg2

HOST = os.environ.get("ASK_MFA_POSTGRES_HOST")
PORT = os.environ.get("ASK_MFA_POSTGRES_PORT")
DB = os.environ.get("ASK_MFA_POSTGRESS_DB")
USER = os.environ.get("ASK_MFA_POSTGRES_USER")
PASSWORD = os.environ.get("ASK_MFA_POSTGRES_PASSWORD")

if __name__ == "__main__":
    conn = psycopg2.connect(
        host=HOST, port=PORT, dbname=DB, user=USER, password=PASSWORD
    )
    try:
        with conn.cursor() as curs:
            curs.execute("SELECT * FROM answers LIMIT 1;")
            print(curs.fetchone())
    finally:
        conn.close()
