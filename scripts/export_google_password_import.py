"""Create a temporary Chrome/Google Password Manager CSV for local demo users."""
from __future__ import annotations

import csv
import getpass
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import get_connection


LOGIN_URL = "http://127.0.0.1:5000/account/login"


def main() -> None:
    password = getpass.getpass("Shared local-test password: ")
    confirmation = getpass.getpass("Confirm password: ")
    if password != confirmation:
        raise SystemExit("Passwords do not match.")
    if len(password) < 8:
        raise SystemExit("Password must have at least 8 characters.")

    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT DATABASE() AS database_name")
        database_name = cursor.fetchone()["database_name"]
        if database_name != "food_delivery_phase3_workbench":
            raise SystemExit(
                f"Refusing to export accounts from {database_name!r}; "
                "expected 'food_delivery_phase3_workbench'."
            )

        entries: dict[str, dict[str, str]] = {}

        def add_entry(email: str, note: str) -> None:
            email = (email or "").strip()
            if not email:
                return
            key = email.casefold()
            if key in entries:
                entries[key]["note"] += f" | Tài khoản cùng email: {note}"
            else:
                entries[key] = {"email": email, "note": note}

        cursor.execute(
            """SELECT customer_id, first_name, last_name, email, phone_number
               FROM CUSTOMER"""
        )
        for row in cursor.fetchall():
            name = f"{row['first_name']} {row['last_name']}".strip()
            add_entry(
                row["email"],
                f"Vai trò: Khách hàng | Mã: {row['customer_id']} | "
                f"Tên: {name} | SĐT: {row['phone_number']}",
            )

        cursor.execute(
            """SELECT r.restaurant_id, r.name, r.email, r.phone_number
               FROM PHASE4_ACCOUNT a
               JOIN RESTAURANT r ON r.restaurant_id = a.restaurant_id
               WHERE a.role = 'restaurant' AND a.is_active = TRUE AND r.is_active = TRUE"""
        )
        for row in cursor.fetchall():
            add_entry(
                row["email"],
                f"Vai trò: Nhà hàng | Mã: {row['restaurant_id']} | "
                f"Tên: {row['name']} | SĐT: {row['phone_number']}",
            )

        cursor.execute(
            """SELECT d.driver_id, d.first_name, d.last_name, a.email,
                      d.phone_number, d.vehicle_type
               FROM PHASE4_ACCOUNT a
               JOIN DRIVER d ON d.driver_id = a.driver_id
               WHERE a.role = 'driver' AND a.is_active = TRUE"""
        )
        for row in cursor.fetchall():
            name = f"{row['first_name']} {row['last_name']}".strip()
            add_entry(
                row["email"],
                f"Vai trò: Tài xế | Mã: {row['driver_id']} | Tên: {name} | "
                f"SĐT: {row['phone_number']} | Phương tiện: {row['vehicle_type']}",
            )

        account_entries = sorted(entries.values(), key=lambda item: item["email"].casefold())
    finally:
        connection.close()

    with tempfile.NamedTemporaryFile(
        mode="w",
        # Chrome's CSV parser expects the header to begin with plain "url";
        # a UTF-8 BOM can make it read the first column name as unknown.
        encoding="utf-8",
        newline="",
        prefix="MiniDoorDash_GooglePasswords_",
        suffix=".csv",
        delete=False,
    ) as csv_file:
        writer = csv.DictWriter(
            csv_file, fieldnames=["url", "username", "password", "note"]
        )
        writer.writeheader()
        for entry in account_entries:
            writer.writerow(
                {
                    "url": LOGIN_URL,
                    "username": entry["email"],
                    "password": password,
                    "note": entry["note"],
                }
            )
        output_path = Path(csv_file.name)

    print(f"Created {len(account_entries)} Google Password Manager entries.")
    print(f"Temporary CSV: {output_path}")
    print("The CSV contains plaintext passwords. Import it, then delete it immediately.")


if __name__ == "__main__":
    main()
