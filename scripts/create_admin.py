"""Create the first Phase 4 administrator account after running phase4_access.sql."""
from __future__ import annotations

import getpass
import re
import sys
from pathlib import Path

from mysql.connector import Error
from werkzeug.security import generate_password_hash

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import get_connection


def main() -> None:
    email = input("Admin email: ").strip().lower()
    password = getpass.getpass("Admin password (min. 12 characters): ")
    confirmation = getpass.getpass("Confirm password: ")
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
        raise SystemExit("Email is not valid.")
    if len(password) < 12 or password != confirmation:
        raise SystemExit("Passwords must match and have at least 12 characters.")

    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """INSERT INTO PHASE4_ACCOUNT (role, email, display_name, password_hash)
               VALUES ('admin', %s, 'Quản trị viên', %s)""",
            (email, generate_password_hash(password)),
        )
        connection.commit()
        print("Administrator account created. Sign in at /account/login.")
    except Error as exc:
        connection.rollback()
        if getattr(exc, "errno", None) == 1062:
            raise SystemExit("That email already has an account.") from exc
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()
