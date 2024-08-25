#!/usr/bin/env python3
import argparse
import psycopg2
import sys
import time

def check_db_initialized(conn):
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM ir_model LIMIT 1;")
        return True
    except psycopg2.Error:
        return False

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_host', required=True)
    arg_parser.add_argument('--db_port', required=True)
    arg_parser.add_argument('--db_user', required=True)
    arg_parser.add_argument('--db_password', required=True)
    arg_parser.add_argument('--database', required=False)
    arg_parser.add_argument('--timeout', type=int, default=5)

    args = arg_parser.parse_args()

    start_time = time.time()
    while (time.time() - start_time) < args.timeout:
        try:
            conn = psycopg2.connect(user=args.db_user, host=args.db_host, port=args.db_port, password=args.db_password, dbname=args.database)
            error = ''
            db_initialized = check_db_initialized(conn)
            break
        except psycopg2.OperationalError as e:
            error = e
        else:
            conn.close()
        time.sleep(1)

    if error:
        print("Database connection failure: %s" % error, file=sys.stderr)
        sys.exit(1)

    if not db_initialized:
        sys.exit(2)  # Custom exit code to indicate uninitialized database

    sys.exit(0)
