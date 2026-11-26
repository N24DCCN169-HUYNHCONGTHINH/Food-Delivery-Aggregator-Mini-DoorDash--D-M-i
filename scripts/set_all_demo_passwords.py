"""Set one shared local-test password for all customer/restaurant/driver accounts.

This deliberately only operates on food_delivery_phase3_workbench. It never
stores or prints the plaintext password; only Werkzeug password hashes go to MySQL.
"""
from __future__ import annotations

import getpass
import sys
from pathlib import Path

from werkzeug.security import generate_password_hash

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import get_connection


EXPECTED_DATABASE = "food_delivery_phase3_workbench"


def main() -> None:
    password = getpass.getpass("Shared local-test password: ")
    confirmation = getpass.getpass("Confirm password: ")
    if password != confirmation:
        raise SystemExit("Passwords do not match.")
    if len(password) < 8:
        raise SystemExit("Password must have at least 8 characters.")

    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("SELECT DATABASE() AS database_name")
        database_name = cursor.fetchone()["database_name"]
        if database_name != EXPECTED_DATABASE:
            connection.rollback()
            raise SystemExit(
                f"Refusing to change passwords in {database_name!r}; "
                f"expected {EXPECTED_DATABASE!r}."
            )

        # The requested password is shared by all demo users, so one salted
        # Werkzeug hash is sufficient and avoids running scrypt thousands of times.
        print("Đang tạo mã băm mật khẩu...", flush=True)
        password_hash = generate_password_hash(password)

        cursor.execute("SELECT customer_id, email FROM CUSTOMER")
        customers = cursor.fetchall()
        print(f"Đang cập nhật mật khẩu cho {len(customers)} khách hàng...", flush=True)
        cursor.executemany(
            "UPDATE CUSTOMER SET password_hash=%s WHERE customer_id=%s",
            [(password_hash, customer["customer_id"]) for customer in customers],
        )
        print("Đã cập nhật khách hàng.", flush=True)

        cursor.execute(
            """SELECT account_id, role, restaurant_id, driver_id
               FROM PHASE4_ACCOUNT WHERE role IN ('restaurant', 'driver')"""
        )
        linked_accounts = cursor.fetchall()
        print(f"Đang đặt lại mật khẩu cho {len(linked_accounts)} tài khoản đối tác...", flush=True)
        cursor.executemany(
            "UPDATE PHASE4_ACCOUNT SET password_hash=%s WHERE account_id=%s",
            [(password_hash, account["account_id"]) for account in linked_accounts],
        )
        print("Đã xử lý tài khoản đối tác hiện có.", flush=True)

        linked_restaurants = {
            account["restaurant_id"]
            for account in linked_accounts
            if account["role"] == "restaurant"
        }
        linked_drivers = {
            account["driver_id"]
            for account in linked_accounts
            if account["role"] == "driver"
        }

        # Do not create an identity when its email is already used by a customer
        # or another partner account; PHASE4_ACCOUNT requires unique emails.
        cursor.execute("SELECT email FROM PHASE4_ACCOUNT")
        occupied_emails = {
            row["email"].strip().casefold() for row in cursor.fetchall() if row["email"]
        }
        occupied_emails.update(
            row["email"].strip().casefold() for row in customers if row["email"]
        )

        created_restaurants = 0
        skipped_restaurants = 0
        restaurant_inserts = []
        cursor.execute("SELECT restaurant_id, name, email FROM RESTAURANT ORDER BY restaurant_id")
        for restaurant in cursor.fetchall():
            if restaurant["restaurant_id"] in linked_restaurants:
                continue
            email = (restaurant["email"] or "").strip()
            key = email.casefold()
            if not email or key in occupied_emails:
                skipped_restaurants += 1
                continue
            restaurant_inserts.append(
                (email, restaurant["name"][:120], password_hash, restaurant["restaurant_id"])
            )
            occupied_emails.add(key)
        if restaurant_inserts:
            print(f"Đang tạo {len(restaurant_inserts)} tài khoản nhà hàng...", flush=True)
            cursor.executemany(
                """INSERT INTO PHASE4_ACCOUNT
                   (role, email, display_name, password_hash, restaurant_id)
                   VALUES ('restaurant', %s, %s, %s, %s)""",
                restaurant_inserts,
            )
            created_restaurants = len(restaurant_inserts)
        print("Đã xử lý hồ sơ nhà hàng.", flush=True)

        created_drivers = 0
        skipped_drivers = 0
        driver_inserts = []
        cursor.execute(
            "SELECT driver_id, first_name, last_name, email FROM DRIVER ORDER BY driver_id"
        )
        for driver in cursor.fetchall():
            if driver["driver_id"] in linked_drivers:
                continue
            email = (driver["email"] or "").strip()
            key = email.casefold()
            if not email or key in occupied_emails:
                skipped_drivers += 1
                continue
            driver_inserts.append(
                (
                    email,
                    f"{driver['first_name']} {driver['last_name']}"[:120],
                    password_hash,
                    driver["driver_id"],
                )
            )
            occupied_emails.add(key)
        if driver_inserts:
            print(f"Đang tạo {len(driver_inserts)} tài khoản tài xế...", flush=True)
            cursor.executemany(
                """INSERT INTO PHASE4_ACCOUNT
                   (role, email, display_name, password_hash, driver_id)
                   VALUES ('driver', %s, %s, %s, %s)""",
                driver_inserts,
            )
            created_drivers = len(driver_inserts)
        print("Đã xử lý hồ sơ tài xế.", flush=True)

        connection.commit()
        print(f"Customer passwords updated: {len(customers)}")
        print(f"Restaurant accounts created: {created_restaurants}")
        print(f"Existing restaurant/driver passwords reset: {len(linked_accounts)}")
        print(f"Driver accounts created: {created_drivers}")
        print(
            "Profiles skipped because email is blank or already used: "
            f"restaurants={skipped_restaurants}, drivers={skipped_drivers}"
        )
        print("Only salted password hashes were stored; plaintext was not written to files.")
    except SystemExit:
        raise
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()
