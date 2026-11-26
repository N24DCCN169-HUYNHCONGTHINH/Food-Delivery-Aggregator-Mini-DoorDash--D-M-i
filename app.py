"""Flask web demo for the Mini-DoorDash Phase 3 MySQL database."""

from __future__ import annotations

import hashlib
import hmac
import os
import re
from decimal import Decimal
from functools import wraps
from typing import Any
from urllib.parse import urlsplit

import mysql.connector
from flask import Flask, flash, jsonify, redirect, render_template, request, session, url_for
from mysql.connector import Error
from werkzeug.security import check_password_hash, generate_password_hash

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "local-demo-secret-change-before-deployment")
app.config.update(SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax")


def get_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "food_delivery_phase3_workbench"),
        charset="utf8mb4",
    )


def query_all(sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    connection = get_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(sql, params)
        return cursor.fetchall()
    finally:
        connection.close()


def safe_next_url(target: str | None) -> str:
    if not target:
        return url_for("index")
    parsed = urlsplit(target)
    if parsed.scheme or parsed.netloc or not target.startswith("/") or target.startswith("//"):
        return url_for("index")
    return target


def role_home(role: str | None = None) -> str:
    role = role or session.get("role")
    return url_for({
        "customer": "customer_portal",
        "restaurant": "restaurant_portal",
        "driver": "driver_portal",
        "admin": "admin_portal",
    }.get(role, "index"))


def role_required(*roles: str):
    def decorate(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            if session.get("role") not in roles:
                flash("Vui lòng đăng nhập bằng đúng loại tài khoản để tiếp tục.", "info")
                return redirect(url_for("account_login", next=request.full_path))
            if session["role"] != "customer":
                accounts = query_all(
                    "SELECT is_active, restaurant_id, driver_id FROM PHASE4_ACCOUNT WHERE account_id=%s AND role=%s",
                    (session.get("account_id"), session["role"]),
                )
                if not accounts or not accounts[0]["is_active"]:
                    session.clear()
                    flash("Tài khoản đã bị khóa hoặc không còn tồn tại.", "error")
                    return redirect(url_for("account_login"))
                if session["role"] == "restaurant":
                    restaurant = query_all(
                        "SELECT is_active FROM RESTAURANT WHERE restaurant_id=%s",
                        (accounts[0]["restaurant_id"],),
                    )
                    if not restaurant or not restaurant[0]["is_active"]:
                        session.clear()
                        flash("Nhà hàng hiện đã tạm ngưng trên nền tảng.", "error")
                        return redirect(url_for("account_login"))
                if session["role"] == "driver" and accounts[0]["driver_id"] != session.get("driver_id"):
                    session.clear()
                    flash("Liên kết tài khoản tài xế không hợp lệ.", "error")
                    return redirect(url_for("account_login"))
            return view(*args, **kwargs)
        return wrapped
    return decorate


def customer_login_required(view):
    @wraps(view)
    @role_required("customer")
    def wrapped(*args, **kwargs):
        return view(*args, **kwargs)
    return wrapped


def restaurant_login_required(view):
    @wraps(view)
    @role_required("restaurant")
    def wrapped(*args, **kwargs):
        return view(*args, **kwargs)
    return wrapped


def driver_login_required(view):
    @wraps(view)
    @role_required("driver")
    def wrapped(*args, **kwargs):
        return view(*args, **kwargs)
    return wrapped


def admin_login_required(view):
    @wraps(view)
    @role_required("admin")
    def wrapped(*args, **kwargs):
        return view(*args, **kwargs)
    return wrapped


app.jinja_env.globals["role_home"] = role_home


def verify_password(stored_hash: str, supplied_password: str) -> tuple[bool, bool]:
    """Verify Werkzeug hashes and legacy SHA-256 hashes from the Phase 3 seed."""
    if re.fullmatch(r"[0-9a-fA-F]{64}", stored_hash or ""):
        expected = hashlib.sha256(supplied_password.encode("utf-8")).hexdigest()
        return hmac.compare_digest(stored_hash.lower(), expected), True
    try:
        return check_password_hash(stored_hash, supplied_password), False
    except (ValueError, TypeError):
        return False, False


@app.get("/account/register")
def account_register():
    if session.get("role"):
        return redirect(role_home())
    return render_template("account_register.html", next_url=safe_next_url(request.args.get("next")))


@app.post("/account/register")
def account_register_submit():
    first_name = request.form.get("first_name", "").strip()
    last_name = request.form.get("last_name", "").strip()
    email = request.form.get("email", "").strip().lower()
    phone = request.form.get("phone_number", "").strip()
    password = request.form.get("password", "")
    confirmation = request.form.get("password_confirmation", "")
    next_url = safe_next_url(request.form.get("next"))
    if not first_name or not last_name or not email or not phone:
        flash("Vui lòng điền đầy đủ họ tên, email và số điện thoại.", "error")
    elif len(first_name) > 50 or len(last_name) > 50 or len(email) > 100 or len(phone) > 20:
        flash("Một số thông tin vượt quá độ dài cho phép.", "error")
    elif "@" not in email or "." not in email.rsplit("@", 1)[-1]:
        flash("Email chưa đúng định dạng.", "error")
    elif len(password) < 8:
        flash("Mật khẩu cần có ít nhất 8 ký tự.", "error")
    elif password != confirmation:
        flash("Xác nhận mật khẩu chưa khớp.", "error")
    else:
        connection = get_connection()
        try:
            cursor = connection.cursor()
            cursor.execute("SELECT account_id FROM PHASE4_ACCOUNT WHERE email = %s", (email,))
            if cursor.fetchone():
                flash("Email này đã được dùng cho một tài khoản khác.", "error")
                return render_template("account_register.html", next_url=next_url)
            cursor.execute(
                """INSERT INTO CUSTOMER (first_name, last_name, email, phone_number, password_hash)
                   VALUES (%s, %s, %s, %s, %s)""",
                (first_name, last_name, email, phone, generate_password_hash(password)),
            )
            customer_id = cursor.lastrowid
            connection.commit()
            session.clear()
            session["role"] = "customer"
            session["customer_id"] = customer_id
            session["customer_name"] = f"{first_name} {last_name}"
            flash("Tài khoản đã được tạo. Chào mừng bạn đến Mini DoorDash!", "success")
            return redirect(next_url if next_url != url_for("index") else url_for("customer_portal"))
        except Error as exc:
            connection.rollback()
            if getattr(exc, "errno", None) == 1062:
                flash("Email hoặc số điện thoại này đã được đăng ký.", "error")
            else:
                flash("Không thể tạo tài khoản lúc này. Vui lòng thử lại.", "error")
        finally:
            connection.close()
    return render_template("account_register.html", next_url=next_url)


@app.get("/account/login")
def account_login():
    if session.get("role"):
        return redirect(role_home())
    return render_template("account_login.html", next_url=safe_next_url(request.args.get("next")))


@app.post("/account/login")
def account_login_submit():
    email = request.form.get("email", "").strip().lower()
    password = request.form.get("password", "")
    next_url = safe_next_url(request.form.get("next"))
    staff_accounts = query_all(
        """SELECT account_id, email, display_name, password_hash, role, restaurant_id, driver_id
           FROM PHASE4_ACCOUNT WHERE email = %s AND is_active = TRUE""",
        (email,),
    )
    if staff_accounts:
        account = staff_accounts[0]
        if not verify_password(account["password_hash"], password)[0]:
            flash("Email hoặc mật khẩu chưa chính xác.", "error")
            return render_template("account_login.html", next_url=next_url), 401
        session.clear()
        session["role"] = account["role"]
        session["account_id"] = account["account_id"]
        session["customer_name"] = account["display_name"]
        if account["restaurant_id"] is not None:
            session["restaurant_id"] = account["restaurant_id"]
        if account["driver_id"] is not None:
            session["driver_id"] = account["driver_id"]
        flash(f"Đăng nhập thành công · {account['display_name']}.", "success")
        return redirect(next_url if next_url != url_for("index") else role_home(account["role"]))

    customers = query_all(
        """SELECT customer_id, first_name, last_name, password_hash
           FROM CUSTOMER WHERE email = %s""",
        (email,),
    )
    valid_password, legacy_hash = verify_password(
        customers[0]["password_hash"], password
    ) if customers else (False, False)
    if not customers or not valid_password:
        flash("Email hoặc mật khẩu chưa chính xác.", "error")
        return render_template("account_login.html", next_url=next_url), 401
    customer = customers[0]
    if legacy_hash:
        connection = get_connection()
        try:
            cursor = connection.cursor()
            cursor.execute(
                "UPDATE CUSTOMER SET password_hash = %s WHERE customer_id = %s",
                (generate_password_hash(password), customer["customer_id"]),
            )
            connection.commit()
        except Error:
            connection.rollback()
        finally:
            connection.close()
    session.clear()
    session["role"] = "customer"
    session["customer_id"] = customer["customer_id"]
    session["customer_name"] = f"{customer['first_name']} {customer['last_name']}"
    flash(f"Chào mừng trở lại, {session['customer_name']}!", "success")
    return redirect(next_url if next_url != url_for("index") else url_for("customer_portal"))


@app.post("/account/logout")
def account_logout():
    session.clear()
    flash("Bạn đã đăng xuất.", "success")
    return redirect(url_for("index"))


@app.route("/account", methods=["GET", "POST"])
@customer_login_required
def account_profile():
    customer_id = session["customer_id"]
    if request.method == "POST":
        first_name = request.form.get("first_name", "").strip()
        last_name = request.form.get("last_name", "").strip()
        email = request.form.get("email", "").strip().lower()
        phone = request.form.get("phone_number", "").strip()
        if not first_name or not last_name or not email or not phone:
            flash("Vui lòng điền đầy đủ họ tên, email và số điện thoại.", "error")
        elif len(first_name) > 50 or len(last_name) > 50 or len(email) > 100 or len(phone) > 20:
            flash("Một số thông tin vượt quá độ dài cho phép.", "error")
        elif "@" not in email or "." not in email.rsplit("@", 1)[-1]:
            flash("Email chưa đúng định dạng.", "error")
        else:
            connection = get_connection()
            try:
                cursor = connection.cursor()
                cursor.execute(
                    """UPDATE CUSTOMER SET first_name = %s, last_name = %s,
                       email = %s, phone_number = %s WHERE customer_id = %s""",
                    (first_name, last_name, email, phone, customer_id),
                )
                connection.commit()
                session["customer_name"] = f"{first_name} {last_name}"
                flash("Thông tin tài khoản đã được cập nhật.", "success")
                return redirect(url_for("account_profile"))
            except Error as exc:
                connection.rollback()
                if getattr(exc, "errno", None) == 1062:
                    flash("Email hoặc số điện thoại đó đã được tài khoản khác sử dụng.", "error")
                else:
                    flash("Không thể cập nhật thông tin lúc này.", "error")
            finally:
                connection.close()
    customer = query_all(
        "SELECT customer_id, first_name, last_name, email, phone_number, created_at FROM CUSTOMER WHERE customer_id = %s",
        (customer_id,),
    )
    if not customer:
        session.clear()
        flash("Không tìm thấy tài khoản. Vui lòng đăng nhập lại.", "error")
        return redirect(url_for("account_login"))
    addresses = query_all(
        "SELECT address_id, address_text FROM CUSTOMER_ADDRESS WHERE customer_id = %s ORDER BY address_id DESC",
        (customer_id,),
    )
    return render_template("account.html", customer=customer[0], addresses=addresses)


@app.route("/account/password", methods=["GET", "POST"])
@role_required("customer", "restaurant", "driver", "admin")
def account_change_password():
    current_password = request.form.get("current_password", "")
    password = request.form.get("password", "")
    confirmation = request.form.get("password_confirmation", "")
    role = session["role"]
    if request.method == "POST":
        if role == "customer":
            rows = query_all("SELECT password_hash FROM CUSTOMER WHERE customer_id = %s", (session["customer_id"],))
            update_sql = "UPDATE CUSTOMER SET password_hash = %s WHERE customer_id = %s"
            update_key = session["customer_id"]
        else:
            rows = query_all("SELECT password_hash FROM PHASE4_ACCOUNT WHERE account_id = %s AND role = %s", (session["account_id"], role))
            update_sql = "UPDATE PHASE4_ACCOUNT SET password_hash = %s WHERE account_id = %s AND role = %s"
            update_key = session["account_id"]
        valid_password = verify_password(rows[0]["password_hash"], current_password)[0] if rows else False
        if not valid_password:
            flash("Mật khẩu hiện tại chưa chính xác.", "error")
        elif len(password) < 8:
            flash("Mật khẩu mới cần có ít nhất 8 ký tự.", "error")
        elif password != confirmation:
            flash("Xác nhận mật khẩu mới chưa khớp.", "error")
        else:
            connection = get_connection()
            try:
                cursor = connection.cursor()
                if role == "customer":
                    cursor.execute(update_sql, (generate_password_hash(password), update_key))
                else:
                    cursor.execute(update_sql, (generate_password_hash(password), update_key, role))
                connection.commit()
                flash("Mật khẩu đã được đổi.", "success")
                return redirect(url_for("account_change_password"))
            except Error:
                connection.rollback()
                flash("Không thể đổi mật khẩu lúc này.", "error")
            finally:
                connection.close()
    return render_template("account_password.html")


@app.post("/account/addresses")
@customer_login_required
def account_add_address():
    address = request.form.get("address_text", "").strip()
    if not address or len(address) > 255:
        flash("Địa chỉ cần có từ 1 đến 255 ký tự.", "error")
        return redirect(url_for("account_profile"))
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO CUSTOMER_ADDRESS (customer_id, address_text) VALUES (%s, %s)",
            (session["customer_id"], address),
        )
        connection.commit()
        flash("Đã lưu địa chỉ giao hàng.", "success")
    except Error as exc:
        connection.rollback()
        if getattr(exc, "errno", None) == 1062:
            flash("Địa chỉ này đã có trong sổ địa chỉ của bạn.", "error")
        else:
            flash("Không thể lưu địa chỉ lúc này.", "error")
    finally:
        connection.close()
    return redirect(url_for("account_profile"))


@app.post("/account/addresses/<int:address_id>/delete")
@customer_login_required
def account_delete_address(address_id: int):
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "DELETE FROM CUSTOMER_ADDRESS WHERE address_id = %s AND customer_id = %s",
            (address_id, session["customer_id"]),
        )
        connection.commit()
        flash("Đã xóa địa chỉ giao hàng." if cursor.rowcount else "Không tìm thấy địa chỉ.",
              "success" if cursor.rowcount else "error")
    except Error:
        connection.rollback()
        flash("Không thể xóa địa chỉ lúc này.", "error")
    finally:
        connection.close()
    return redirect(url_for("account_profile"))


@app.get("/")
def index():
    restaurants = query_all(
        """SELECT r.restaurant_id, r.name, r.phone_number,
                  COALESCE((SELECT ROUND(AVG(rv.rating), 1) FROM REVIEW rv
                            WHERE rv.restaurant_id = r.restaurant_id), 0) AS avg_rating,
                  (SELECT COUNT(*) FROM REVIEW rv WHERE rv.restaurant_id = r.restaurant_id) AS review_count,
                  (SELECT COUNT(*) FROM MENU_ITEM mi WHERE mi.restaurant_id = r.restaurant_id) AS menu_count,
                  COALESCE((SELECT SUM(oi.quantity) FROM ORDERS o
                            JOIN ORDER_ITEM oi ON oi.order_id = o.order_id
                            WHERE o.restaurant_id = r.restaurant_id), 0) AS sold_count,
                  COALESCE((SELECT GROUP_CONCAT(mi.name SEPARATOR ' ')
                            FROM MENU_ITEM mi WHERE mi.restaurant_id = r.restaurant_id), '') AS menu_search
           FROM RESTAURANT r
           WHERE r.is_active = TRUE
           ORDER BY r.name"""
    )
    return render_template(
        "index.html", restaurants=restaurants,
        customer_id=session.get("customer_id"),
    )


@app.get("/restaurants/<int:restaurant_id>")
def restaurant_menu(restaurant_id: int):
    restaurants = query_all(
        """SELECT r.restaurant_id, r.name, r.phone_number,
                  COALESCE((SELECT ROUND(AVG(rv.rating), 1) FROM REVIEW rv
                            WHERE rv.restaurant_id = r.restaurant_id), 0) AS avg_rating,
                  (SELECT COUNT(*) FROM REVIEW rv WHERE rv.restaurant_id = r.restaurant_id) AS review_count,
                  (SELECT COUNT(*) FROM MENU_ITEM mi WHERE mi.restaurant_id = r.restaurant_id
                   AND mi.is_available = TRUE) AS menu_count,
                  (SELECT MIN(v.price) FROM MENU_ITEM_VARIANT v
                   JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
                   WHERE mi.restaurant_id = r.restaurant_id AND v.is_available = TRUE) AS min_price,
                  (SELECT MAX(v.price) FROM MENU_ITEM_VARIANT v
                   JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
                   WHERE mi.restaurant_id = r.restaurant_id AND v.is_available = TRUE) AS max_price
           FROM RESTAURANT r WHERE r.restaurant_id = %s AND r.is_active = TRUE""",
        (restaurant_id,),
    )
    if not restaurants:
        flash("Không tìm thấy nhà hàng.", "error")
        return redirect(url_for("index"))
    menu = query_all(
        """SELECT mi.menu_item_id, mi.name AS item_name, mi.description,
                  v.variant_id, v.variant_name, v.price,
                  COALESCE((SELECT SUM(oi.quantity) FROM ORDER_ITEM oi
                            WHERE oi.variant_id = v.variant_id), 0) AS sold_count
           FROM MENU_ITEM mi
           JOIN MENU_ITEM_VARIANT v ON v.menu_item_id = mi.menu_item_id
           WHERE mi.restaurant_id = %s AND mi.is_available = TRUE
             AND v.is_available = TRUE
           ORDER BY mi.name, v.price""",
        (restaurant_id,),
    )
    customer_id = session.get("customer_id") if session.get("role") == "customer" else None
    customer = query_all(
        "SELECT customer_id, first_name, last_name, email, phone_number FROM CUSTOMER WHERE customer_id = %s",
        (customer_id,),
    ) if customer_id else []
    return render_template(
        "menu.html", restaurant=restaurants[0], menu=menu,
        selected_customer=customer[0] if customer else None,
    )


@app.get("/customer/<int:customer_id>/addresses")
@customer_login_required
def customer_addresses(customer_id: int):
    if customer_id != session.get("customer_id"):
        return jsonify({"error": "forbidden"}), 403
    rows = query_all(
        "SELECT address_text FROM CUSTOMER_ADDRESS WHERE customer_id = %s ORDER BY address_id DESC",
        (customer_id,),
    )
    return jsonify([row["address_text"] for row in rows])


@app.get("/customer")
@customer_login_required
def customer_portal():
    customer_id = session.get("customer_id")
    customer_rows = query_all(
        "SELECT customer_id, first_name, last_name, email FROM CUSTOMER WHERE customer_id = %s",
        (customer_id,),
    )
    selected = customer_rows[0] if customer_rows else None
    if not selected:
        session.clear()
        flash("Không tìm thấy tài khoản khách hàng. Vui lòng đăng nhập lại.", "error")
        return redirect(url_for("account_login"))
    orders = []
    transactions = []
    balance = 0
    if selected:
        balance_rows = query_all("SELECT GetLoyaltyBalance(%s) AS balance", (customer_id,))
        balance = balance_rows[0]["balance"] if balance_rows else 0
        orders = query_all(
            """SELECT o.order_id, o.order_time, o.total_amount,
                      r.name AS restaurant_name, s.status AS order_status,
                      s.changed_at AS status_changed_at,
                      rv.rating AS review_rating, rv.comment AS review_comment,
                      receipt.confirmed_at AS customer_confirmed_at
               FROM ORDERS o
               JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
               JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
               LEFT JOIN REVIEW rv ON rv.order_id = o.order_id
               LEFT JOIN CUSTOMER_ORDER_RECEIPT receipt
                 ON receipt.order_id = o.order_id AND receipt.customer_id = o.customer_id
               WHERE o.customer_id = %s
               ORDER BY o.order_time DESC, o.order_id DESC LIMIT 50""",
            (customer_id,),
        )
        order_ids = [order["order_id"] for order in orders]
        items_by_order: dict[int, list[dict[str, Any]]] = {order_id: [] for order_id in order_ids}
        if order_ids:
            placeholders = ",".join(["%s"] * len(order_ids))
            order_items = query_all(
                f"""SELECT oi.order_id, mi.name AS item_name, v.variant_name,
                           oi.unit_price, oi.quantity, oi.notes,
                           GROUP_CONCAT(oic.customization_name ORDER BY oic.customization_id SEPARATOR '||') AS customization_names
                    FROM ORDER_ITEM oi JOIN MENU_ITEM_VARIANT v ON v.variant_id = oi.variant_id
                    JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
                    LEFT JOIN ORDER_ITEM_CUSTOMIZATION oic ON oic.order_item_id = oi.order_item_id
                    WHERE oi.order_id IN ({placeholders})
                    GROUP BY oi.order_item_id, oi.order_id, mi.name, v.variant_name,
                             oi.unit_price, oi.quantity, oi.notes
                    ORDER BY oi.order_id, oi.order_item_id""",
                tuple(order_ids),
            )
            for item in order_items:
                items_by_order[item["order_id"]].append(item)
        for order in orders:
            order["items"] = items_by_order[order["order_id"]]
        transactions = query_all(
            """SELECT points, transaction_type, created_at, order_id
               FROM LOYALTY_TRANSACTION WHERE customer_id = %s
               ORDER BY created_at DESC, loyalty_transaction_id DESC LIMIT 12""",
            (customer_id,),
        )
    return render_template(
        "customer_portal.html", selected_customer=selected,
        orders=orders, transactions=transactions, balance=balance,
    )


@app.post("/orders")
@customer_login_required
def create_order():
    customer_id = session.get("customer_id")
    variant_ids = request.form.getlist("variant_id", type=int)
    quantities = request.form.getlist("quantity", type=int)
    address = request.form.get("delivery_address", "").strip()
    instructions = request.form.get("instructions", "").strip() or None
    item_notes = {
        int(key.removeprefix("item_note_")): value.strip()[:255]
        for key, value in request.form.items()
        if key.startswith("item_note_") and key.removeprefix("item_note_").isdigit() and value.strip()
    }
    lines = [(variant_id, qty) for variant_id, qty in zip(variant_ids, quantities) if qty > 0]
    if not customer_id:
        flash("Vui lòng đăng nhập bằng tài khoản khách hàng để đặt món.", "error")
        return redirect(url_for("account_login", next=request.referrer or url_for("index")))
    if not lines:
        flash("Hãy chọn ít nhất một món trước khi đặt đơn.", "error")
        return redirect(request.referrer or url_for("index"))
    if not address:
        flash("Hãy chọn địa chỉ đã lưu hoặc nhập địa chỉ giao hàng mới.", "error")
        return redirect(request.referrer or url_for("index"))

    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        placeholders = ",".join(["%s"] * len(lines))
        cursor.execute(
            f"""SELECT v.variant_id, v.restaurant_id, v.price
                FROM MENU_ITEM_VARIANT v JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
                JOIN RESTAURANT r ON r.restaurant_id = mi.restaurant_id
                WHERE v.variant_id IN ({placeholders})
                  AND v.is_available = TRUE AND mi.is_available = TRUE AND r.is_active = TRUE
                FOR UPDATE""",
            tuple(v for v, _ in lines),
        )
        variants = cursor.fetchall()
        if len(variants) != len(lines):
            raise ValueError("Một hoặc nhiều món đã hết hàng.")
        restaurant_ids = {v["restaurant_id"] for v in variants}
        if len(restaurant_ids) != 1:
            raise ValueError("Mỗi đơn hàng chỉ có thể gồm món từ cùng một nhà hàng.")
        cursor.execute("SELECT customer_id FROM CUSTOMER WHERE customer_id = %s", (customer_id,))
        if cursor.fetchone() is None:
            raise ValueError("Không tìm thấy khách hàng.")

        cursor.execute(
            "SELECT address_id FROM CUSTOMER_ADDRESS WHERE customer_id = %s AND address_text = %s",
            (customer_id, address),
        )
        if cursor.fetchone() is None:
            cursor.execute(
                "INSERT INTO CUSTOMER_ADDRESS (customer_id, address_text) VALUES (%s, %s)",
                (customer_id, address),
            )

        fee = Decimal("15000.00")
        price_map = {v["variant_id"]: v["price"] for v in variants}
        subtotal = sum(
            (price_map[variant_id] * qty for variant_id, qty in lines), Decimal("0.00")
        )
        tax = (subtotal * Decimal("0.08")).quantize(Decimal("0.01"))
        total = subtotal + fee + tax
        cursor.execute(
            """INSERT INTO ORDERS
               (customer_id, restaurant_id, order_time, subtotal, delivery_fee,
                tax, total_amount, delivery_address, special_instructions)
               VALUES (%s, %s, CURRENT_TIMESTAMP, %s, %s, %s, %s, %s, %s)""",
            (customer_id, next(iter(restaurant_ids)), subtotal, fee, tax,
             total, address, instructions),
        )
        order_id = cursor.lastrowid
        for variant_id, qty in lines:
            cursor.execute(
                """INSERT INTO ORDER_ITEM (order_id, variant_id, restaurant_id, unit_price, quantity, notes)
                   VALUES (%s, %s, %s, %s, %s, %s)""",
                (order_id, variant_id, next(iter(restaurant_ids)), price_map[variant_id], qty,
                 item_notes.get(variant_id) or None),
            )
        cursor.execute(
            """INSERT INTO ORDER_STATUS_HISTORY (order_id, status, status_note)
               VALUES (%s, 'Pending', 'Khách tạo đơn qua giao diện Phase 4')""",
            (order_id,),
        )
        cursor.callproc("FinalizeOrder", [order_id])
        connection.commit()
        flash(f"Đã tạo đơn #{order_id} thành công.", "success")
        return redirect(url_for("order_detail", order_id=order_id, source="customer", customer_id=customer_id))
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể tạo đơn: {exc}", "error")
        return redirect(request.referrer or url_for("index"))
    finally:
        connection.close()


@app.post("/customer/orders/<int:order_id>/review")
@customer_login_required
def submit_customer_review(order_id: int):
    customer_id = session.get("customer_id")
    rating = request.form.get("rating", type=int)
    comment = request.form.get("comment", "").strip() or None
    if not customer_id or rating not in {1, 2, 3, 4, 5}:
        flash("Hãy chọn số sao từ 1 đến 5.", "error")
        return redirect(url_for("customer_portal", customer_id=customer_id))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "SELECT restaurant_id FROM ORDERS WHERE order_id = %s AND customer_id = %s FOR UPDATE",
            (order_id, customer_id),
        )
        order = cursor.fetchone()
        if not order:
            raise ValueError("Không tìm thấy đơn thuộc tài khoản khách hàng này.")
        cursor.execute("SELECT status FROM ORDER_CURRENT_STATUS WHERE order_id = %s", (order_id,))
        status = cursor.fetchone()
        if not status or status["status"] != "Delivered":
            raise ValueError("Chỉ có thể đánh giá đơn đã giao thành công.")
        cursor.execute("SELECT review_id FROM REVIEW WHERE order_id = %s", (order_id,))
        if cursor.fetchone():
            raise ValueError("Đơn hàng này đã được đánh giá.")
        cursor.execute(
            """INSERT INTO REVIEW (order_id, customer_id, restaurant_id, rating, comment)
               VALUES (%s, %s, %s, %s, %s)""",
            (order_id, customer_id, order["restaurant_id"], rating, comment),
        )
        connection.commit()
        flash("Cảm ơn bạn đã đánh giá nhà hàng.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể gửi đánh giá: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("customer_portal", customer_id=customer_id))


@app.post("/customer/orders/<int:order_id>/confirm-received")
@customer_login_required
def confirm_order_received(order_id: int):
    customer_id = session["customer_id"]
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "SELECT order_id FROM ORDERS WHERE order_id = %s AND customer_id = %s FOR UPDATE",
            (order_id, customer_id),
        )
        if not cursor.fetchone():
            raise ValueError("Không tìm thấy đơn hàng thuộc tài khoản của bạn.")
        cursor.execute("SELECT status FROM ORDER_CURRENT_STATUS WHERE order_id = %s", (order_id,))
        current = cursor.fetchone()
        if not current or current["status"] != "Delivered":
            raise ValueError("Chỉ xác nhận nhận món sau khi tài xế báo giao thành công.")
        cursor.execute(
            """INSERT INTO CUSTOMER_ORDER_RECEIPT (order_id, customer_id)
               VALUES (%s, %s)""",
            (order_id, customer_id),
        )
        connection.commit()
        flash("Đã ghi nhận bạn nhận được món. Cảm ơn bạn!", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        if getattr(exc, "errno", None) == 1062:
            flash("Bạn đã xác nhận nhận đơn này trước đó.", "info")
        else:
            flash(str(exc), "error")
    finally:
        connection.close()
    return redirect(url_for("customer_portal"))


@app.get("/orders")
@admin_login_required
def orders():
    rows = query_all(
        """SELECT o.order_id, o.order_time, o.total_amount, c.first_name, c.last_name,
                  r.name AS restaurant_name, s.status, s.changed_at
           FROM ORDERS o JOIN CUSTOMER c ON c.customer_id = o.customer_id
           JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
           LEFT JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
           ORDER BY o.order_time DESC, o.order_id DESC LIMIT 100"""
    )
    return render_template("orders.html", orders=rows)


@app.get("/restaurant")
@restaurant_login_required
def restaurant_portal():
    restaurant_id = session["restaurant_id"]
    rows = query_all(
        """SELECT o.order_id, o.order_time, o.delivery_address,
                  o.special_instructions, c.first_name, c.last_name,
                  r.name AS restaurant_name, s.status AS order_status
           FROM ORDERS o
           JOIN CUSTOMER c ON c.customer_id = o.customer_id
           JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
           JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
           WHERE o.restaurant_id = %s AND s.status IN ('Pending', 'Preparing')
           ORDER BY o.order_time, o.order_id"""
        , (restaurant_id,)
    )
    restaurant = query_all(
        "SELECT restaurant_id, name, phone_number, email, is_active FROM RESTAURANT WHERE restaurant_id = %s",
        (restaurant_id,),
    )
    menu_rows = query_all(
        """SELECT mi.menu_item_id, mi.name, mi.description, mi.is_available AS item_available,
                  v.variant_id, v.variant_name, v.price, v.is_available AS variant_available
           FROM MENU_ITEM mi LEFT JOIN MENU_ITEM_VARIANT v ON v.menu_item_id = mi.menu_item_id
           WHERE mi.restaurant_id = %s
           ORDER BY mi.menu_item_id, v.variant_id""",
        (restaurant_id,),
    )
    menu_by_id: dict[int, dict[str, Any]] = {}
    for row in menu_rows:
        item = menu_by_id.setdefault(row["menu_item_id"], {
            "menu_item_id": row["menu_item_id"], "name": row["name"],
            "description": row["description"], "is_available": row["item_available"],
            "variants": [],
        })
        if row["variant_id"] is not None:
            item["variants"].append({
                "variant_id": row["variant_id"], "variant_name": row["variant_name"],
                "price": row["price"], "is_available": row["variant_available"],
            })
    return render_template(
        "restaurant_portal.html", orders=rows,
        restaurant=restaurant[0] if restaurant else None,
        menu_items=list(menu_by_id.values()),
    )


@app.post("/restaurant/orders/<int:order_id>/status")
@restaurant_login_required
def restaurant_update_status(order_id: int):
    target = request.form.get("status", "")
    if target not in {"Preparing", "Ready"}:
        flash("Góc nhà hàng chỉ được cập nhật Preparing hoặc Ready.", "error")
        return redirect(url_for("restaurant_portal"))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT restaurant_id FROM ORDERS WHERE order_id = %s FOR UPDATE", (order_id,))
        order = cursor.fetchone()
        if not order or order["restaurant_id"] != session["restaurant_id"]:
            raise ValueError("Đơn này không thuộc nhà hàng của bạn.")
        cursor.execute("SELECT status FROM ORDER_CURRENT_STATUS WHERE order_id = %s", (order_id,))
        current = cursor.fetchone()
        expected = {"Pending": "Preparing", "Preparing": "Ready"}
        if not current or expected.get(current["status"]) != target:
            raise ValueError("Nhà hàng chỉ được chuyển Pending → Preparing → Ready.")
        cursor.callproc("UpdateOrderStatus", [order_id, target, "Nhà hàng cập nhật trạng thái chuẩn bị"])
        connection.commit()
        flash(f"Nhà hàng đã chuyển đơn #{order_id} sang {target}.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể cập nhật đơn tại góc nhà hàng: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("restaurant_portal"))


@app.post("/restaurant/menu/add")
@restaurant_login_required
def restaurant_add_menu_item():
    name = request.form.get("name", "").strip()
    description = request.form.get("description", "").strip() or None
    variant_name = request.form.get("variant_name", "").strip()
    try:
        price = Decimal(request.form.get("price", "0").strip())
    except Exception:
        price = Decimal("0")
    if not name or len(name) > 100 or len(description or "") > 4000 or not variant_name or len(variant_name) > 50 or price <= 0:
        flash("Nhập tên món, tên phân loại và giá lớn hơn 0 (đúng giới hạn ký tự).", "error")
        return redirect(url_for("restaurant_portal"))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO MENU_ITEM (restaurant_id, name, description, is_available) VALUES (%s, %s, %s, TRUE)",
            (session["restaurant_id"], name, description),
        )
        menu_item_id = cursor.lastrowid
        cursor.execute(
            """INSERT INTO MENU_ITEM_VARIANT
               (menu_item_id, restaurant_id, variant_name, price, is_available)
               VALUES (%s, %s, %s, %s, TRUE)""",
            (menu_item_id, session["restaurant_id"], variant_name, price),
        )
        connection.commit()
        flash("Đã thêm món và phân loại đầu tiên vào thực đơn.", "success")
    except Error as exc:
        connection.rollback()
        flash(f"Không thể thêm món: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("restaurant_portal"))


@app.post("/restaurant/menu/<int:menu_item_id>/edit")
@restaurant_login_required
def restaurant_edit_menu_item(menu_item_id: int):
    name = request.form.get("name", "").strip()
    description = request.form.get("description", "").strip() or None
    available = request.form.get("is_available") == "on"
    if not name or len(name) > 100 or len(description or "") > 4000:
        flash("Tên món hoặc mô tả không hợp lệ.", "error")
        return redirect(url_for("restaurant_portal"))
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE MENU_ITEM SET name = %s, description = %s, is_available = %s
               WHERE menu_item_id = %s AND restaurant_id = %s""",
            (name, description, available, menu_item_id, session["restaurant_id"]),
        )
        if cursor.rowcount:
            connection.commit()
            flash("Đã cập nhật món ăn.", "success")
        else:
            connection.rollback()
            flash("Không tìm thấy món thuộc nhà hàng của bạn.", "error")
    except Error as exc:
        connection.rollback()
        flash(f"Không thể cập nhật món: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("restaurant_portal"))


@app.post("/restaurant/menu/<int:menu_item_id>/hide")
@restaurant_login_required
def restaurant_hide_menu_item(menu_item_id: int):
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE MENU_ITEM SET is_available = FALSE WHERE menu_item_id = %s AND restaurant_id = %s",
            (menu_item_id, session["restaurant_id"]),
        )
        if cursor.rowcount:
            cursor.execute(
                "UPDATE MENU_ITEM_VARIANT SET is_available = FALSE WHERE menu_item_id = %s AND restaurant_id = %s",
                (menu_item_id, session["restaurant_id"]),
            )
            connection.commit()
            flash("Đã ẩn món khỏi thực đơn; lịch sử đơn cũ được giữ nguyên.", "success")
        else:
            connection.rollback()
            flash("Không tìm thấy món thuộc nhà hàng của bạn.", "error")
    except Error as exc:
        connection.rollback()
        flash(f"Không thể ẩn món: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("restaurant_portal"))


@app.post("/restaurant/menu/<int:menu_item_id>/variants/add")
@restaurant_login_required
def restaurant_add_variant(menu_item_id: int):
    variant_name = request.form.get("variant_name", "").strip()
    try:
        price = Decimal(request.form.get("price", "0").strip())
    except Exception:
        price = Decimal("0")
    if not variant_name or len(variant_name) > 50 or price <= 0:
        flash("Tên phân loại và giá phải hợp lệ; giá phải lớn hơn 0.", "error")
        return redirect(url_for("restaurant_portal"))
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "SELECT menu_item_id FROM MENU_ITEM WHERE menu_item_id=%s AND restaurant_id=%s",
            (menu_item_id, session["restaurant_id"]),
        )
        if not cursor.fetchone():
            raise ValueError("Món không thuộc nhà hàng của bạn.")
        cursor.execute(
            """INSERT INTO MENU_ITEM_VARIANT
               (menu_item_id, restaurant_id, variant_name, price, is_available)
               VALUES (%s, %s, %s, %s, TRUE)""",
            (menu_item_id, session["restaurant_id"], variant_name, price),
        )
        connection.commit()
        flash("Đã thêm phân loại món.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể thêm phân loại: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("restaurant_portal"))


@app.post("/restaurant/variants/<int:variant_id>/edit")
@restaurant_login_required
def restaurant_edit_variant(variant_id: int):
    variant_name = request.form.get("variant_name", "").strip()
    available = request.form.get("is_available") == "on"
    try:
        price = Decimal(request.form.get("price", "0").strip())
    except Exception:
        price = Decimal("0")
    if not variant_name or len(variant_name) > 50 or price <= 0:
        flash("Tên phân loại và giá phải hợp lệ; giá phải lớn hơn 0.", "error")
        return redirect(url_for("restaurant_portal"))
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE MENU_ITEM_VARIANT SET variant_name = %s, price = %s, is_available = %s
               WHERE variant_id = %s AND restaurant_id = %s""",
            (variant_name, price, available, variant_id, session["restaurant_id"]),
        )
        connection.commit()
        flash("Đã cập nhật phân loại và giá.", "success" if cursor.rowcount else "error")
    except Error as exc:
        connection.rollback()
        flash(f"Không thể cập nhật giá: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("restaurant_portal"))


@app.get("/driver")
@driver_login_required
def driver_portal():
    driver_id = session["driver_id"]
    drivers = query_all(
        "SELECT driver_id, first_name, last_name, phone_number, vehicle_type FROM DRIVER WHERE driver_id = %s",
        (driver_id,),
    )
    selected = drivers[0] if drivers else None
    if not selected:
        session.clear()
        flash("Hồ sơ tài xế không còn hoạt động. Vui lòng liên hệ quản trị viên.", "error")
        return redirect(url_for("account_login"))
    assignments = query_all(
            """SELECT da.assignment_id, da.order_id, da.status AS assignment_status,
                      da.assigned_at, da.accepted_at, o.delivery_address,
                      c.first_name AS customer_first_name, c.last_name AS customer_last_name,
                      r.name AS restaurant_name, s.status AS order_status,
                      s.changed_at AS status_changed_at, receipt.confirmed_at AS customer_confirmed_at
               FROM DELIVERY_ASSIGNMENT da
               JOIN ORDERS o ON o.order_id = da.order_id
               JOIN CUSTOMER c ON c.customer_id = o.customer_id
               JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
               JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
               LEFT JOIN CUSTOMER_ORDER_RECEIPT receipt ON receipt.order_id = o.order_id
               WHERE da.driver_id = %s
                 AND da.status IN ('Assigned', 'Accepted', 'Completed', 'Failed', 'Rejected', 'Cancelled')
               ORDER BY CASE WHEN da.status IN ('Assigned', 'Accepted') THEN 0 ELSE 1 END,
                        da.assigned_at DESC, da.assignment_id DESC
               LIMIT 20""",
            (driver_id,),
        )
    locations = query_all(
            """SELECT latitude, longitude, address_text, recorded_at
               FROM LOCATION WHERE driver_id = %s
               ORDER BY recorded_at DESC, location_id DESC LIMIT 5""",
            (driver_id,),
        )
    return render_template(
        "driver_portal.html", drivers=drivers, selected_driver=selected,
        assignments=assignments, locations=locations,
        source="driver",
    )


@app.get("/delivery")
@admin_login_required
def delivery_dispatch():
    delivery_orders = query_all(
        """SELECT o.order_id, o.order_time, o.delivery_address,
                  c.first_name, c.last_name, r.name AS restaurant_name,
                  s.status AS order_status, s.changed_at AS status_changed_at,
                  da.assignment_id, da.status AS assignment_status,
                  da.assigned_at, da.failure_reason,
                  d.driver_id, d.first_name AS driver_first_name,
                  d.last_name AS driver_last_name, d.phone_number AS driver_phone,
                  loc.latitude, loc.longitude, loc.address_text AS last_location,
                  loc.recorded_at AS location_time
           FROM ORDERS o
           JOIN CUSTOMER c ON c.customer_id = o.customer_id
           JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
           JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
           LEFT JOIN DELIVERY_ASSIGNMENT da ON da.assignment_id = (
               SELECT da2.assignment_id FROM DELIVERY_ASSIGNMENT da2
               WHERE da2.order_id = o.order_id
               ORDER BY da2.assigned_at DESC, da2.assignment_id DESC LIMIT 1
           )
           LEFT JOIN DRIVER d ON d.driver_id = da.driver_id
           LEFT JOIN LOCATION loc ON loc.location_id = (
               SELECT l.location_id FROM LOCATION l
               WHERE l.driver_id = da.driver_id
               ORDER BY l.recorded_at DESC, l.location_id DESC LIMIT 1
           )
           WHERE s.status IN ('Pending', 'Preparing', 'Ready', 'On The Way', 'Delivery Failed')
           ORDER BY CASE s.status WHEN 'Pending' THEN 1 WHEN 'Preparing' THEN 2
                                  WHEN 'Ready' THEN 3 WHEN 'On The Way' THEN 4 ELSE 5 END,
                    s.changed_at, o.order_id"""
    )
    drivers = query_all(
        """SELECT d.driver_id, d.first_name, d.last_name, d.phone_number, d.vehicle_type
           FROM DRIVER d JOIN PHASE4_ACCOUNT a ON a.driver_id=d.driver_id
           WHERE a.role='driver' AND a.is_active=TRUE
           ORDER BY d.last_name, d.first_name"""
    )
    order_ids = [row["order_id"] for row in delivery_orders]
    assignments_by_order: dict[int, list[dict[str, Any]]] = {order_id: [] for order_id in order_ids}
    if order_ids:
        placeholders = ",".join(["%s"] * len(order_ids))
        assignment_rows = query_all(
            f"""SELECT da.order_id, da.assignment_id, da.status, da.assigned_at,
                       da.accepted_at, da.completed_at, da.failure_reason,
                       d.first_name, d.last_name
                FROM DELIVERY_ASSIGNMENT da JOIN DRIVER d ON d.driver_id = da.driver_id
                WHERE da.order_id IN ({placeholders})
                ORDER BY da.order_id, da.assigned_at, da.assignment_id""",
            tuple(order_ids),
        )
        for assignment in assignment_rows:
            assignments_by_order[assignment["order_id"]].append(assignment)
    return render_template(
        "dispatch.html", orders=delivery_orders, drivers=drivers,
        assignments_by_order=assignments_by_order,
    )


@app.post("/orders/<int:order_id>/assign")
@admin_login_required
def assign_driver(order_id: int):
    driver_id = request.form.get("driver_id", type=int)
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT order_id FROM ORDERS WHERE order_id = %s FOR UPDATE", (order_id,))
        if not cursor.fetchone():
            raise ValueError("Không tìm thấy đơn hàng.")
        cursor.execute("SELECT status FROM ORDER_CURRENT_STATUS WHERE order_id = %s", (order_id,))
        current = cursor.fetchone()
        if not current or current["status"] not in {"Ready", "Delivery Failed"}:
            raise ValueError("Chỉ có thể phân công đơn đang Ready hoặc Delivery Failed.")
        cursor.execute(
            """SELECT d.driver_id FROM DRIVER d JOIN PHASE4_ACCOUNT a ON a.driver_id=d.driver_id
               WHERE d.driver_id=%s AND a.role='driver' AND a.is_active=TRUE""",
            (driver_id,),
        )
        if not driver_id or not cursor.fetchone():
            raise ValueError("Hãy chọn một tài xế có tài khoản đang hoạt động.")
        cursor.execute(
            """INSERT INTO DELIVERY_ASSIGNMENT (order_id, driver_id, status)
               VALUES (%s, %s, 'Assigned')""",
            (order_id, driver_id),
        )
        connection.commit()
        flash("Đã tạo lượt phân công mới; lịch sử các lượt trước được giữ nguyên.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể phân công tài xế: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("delivery_dispatch"))


@app.post("/assignments/<int:assignment_id>/action")
@role_required("driver", "admin")
def assignment_action(assignment_id: int):
    action = request.form.get("action", "")
    actor_role = "driver" if session["role"] == "driver" else "dispatcher"
    actor_driver_id = session.get("driver_id") if actor_role == "driver" else None
    reason = request.form.get("reason", "").strip()
    latitude = request.form.get("latitude", type=float)
    longitude = request.form.get("longitude", type=float)
    location_text = request.form.get("location_text", "").strip() or None
    driver_actions = {"accept", "reject", "cancel", "start", "complete", "fail"}
    if not ((actor_role == "driver" and action in driver_actions) or
            (actor_role == "dispatcher" and action == "cancel")):
        flash("Thao tác giao hàng không hợp lệ.", "error")
        return redirect(role_home())

    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """SELECT assignment_id, order_id, driver_id, status
               FROM DELIVERY_ASSIGNMENT WHERE assignment_id = %s FOR UPDATE""",
            (assignment_id,),
        )
        assignment = cursor.fetchone()
        if not assignment:
            raise ValueError("Không tìm thấy lượt phân công.")

        cursor.execute("SELECT order_id FROM ORDERS WHERE order_id = %s FOR UPDATE", (assignment["order_id"],))
        if not cursor.fetchone():
            raise ValueError("Không tìm thấy đơn hàng của lượt phân công.")

        current = assignment["status"]
        order_id = assignment["order_id"]
        driver_id = assignment["driver_id"]
        cursor.execute("SELECT status FROM ORDER_CURRENT_STATUS WHERE order_id = %s", (order_id,))
        order_state = cursor.fetchone()
        order_status = order_state["status"] if order_state else None
        if actor_role == "driver" and actor_driver_id != driver_id:
            raise ValueError("Tài xế đang chọn không sở hữu lượt phân công này.")
        if actor_role == "driver" and action == "accept" and current == "Assigned":
            if order_status not in {"Ready", "Delivery Failed"}:
                raise ValueError("Chỉ nhận chuyến khi đơn đã sẵn sàng hoặc đang chờ giao lại.")
            cursor.execute(
                """UPDATE DELIVERY_ASSIGNMENT
                   SET status = 'Accepted', accepted_at = CURRENT_TIMESTAMP
                   WHERE assignment_id = %s""",
                (assignment_id,),
            )
            if (latitude is None) != (longitude is None):
                raise ValueError("Cần nhập cả vĩ độ và kinh độ để ghi vị trí.")
            if latitude is not None:
                cursor.execute(
                    """INSERT INTO LOCATION (driver_id, latitude, longitude, address_text)
                       VALUES (%s, %s, %s, %s)""",
                    (driver_id, latitude, longitude, location_text),
                )
            message = "Tài xế đã nhận chuyến. Hãy cập nhật trạng thái khi bắt đầu giao."
        elif actor_role == "driver" and action == "reject" and current == "Assigned":
            if not reason:
                raise ValueError("Nhập lý do từ chối để lưu vào lịch sử điều phối.")
            cursor.execute(
                """UPDATE DELIVERY_ASSIGNMENT
                   SET status = 'Rejected', completed_at = CURRENT_TIMESTAMP,
                       failure_reason = %s
                   WHERE assignment_id = %s""",
                (reason[:255], assignment_id),
            )
            message = "Đã lưu lượt từ chối; có thể phân công tài xế khác."
        elif actor_role == "driver" and action == "cancel" and current in {"Assigned", "Accepted"}:
            if not reason:
                raise ValueError("Nhập lý do hủy chuyến để lưu vào lịch sử giao hàng.")
            cursor.execute(
                """UPDATE DELIVERY_ASSIGNMENT
                   SET status = 'Cancelled', completed_at = CURRENT_TIMESTAMP,
                       failure_reason = %s
                   WHERE assignment_id = %s""",
                (reason[:255], assignment_id),
            )
            if current == "Accepted" and order_status == "On The Way":
                cursor.callproc("UpdateOrderStatus", [order_id, "Delivery Failed", reason[:255]])
                message = "Đã lưu việc tài xế hủy chuyến; đơn chuyển sang Delivery Failed để điều phối lại."
            elif current == "Accepted":
                message = "Đã lưu việc tài xế hủy chuyến trước khi khởi hành."
            else:
                message = "Đã lưu việc tài xế hủy lượt chờ; có thể phân công lại."
        elif actor_role == "dispatcher" and action == "cancel" and current == "Assigned":
            cursor.execute(
                """UPDATE DELIVERY_ASSIGNMENT
                   SET status = 'Cancelled', completed_at = CURRENT_TIMESTAMP,
                       failure_reason = %s
                   WHERE assignment_id = %s""",
                (reason[:255] or None, assignment_id),
            )
            message = "Đã hủy lượt phân công; lịch sử được giữ lại."
        elif actor_role == "driver" and action == "start" and current == "Accepted" and order_status in {"Ready", "Delivery Failed"}:
            cursor.callproc("UpdateOrderStatus", [order_id, "On The Way", "Tài xế bắt đầu giao đơn"])
            message = "Đơn đã chuyển sang On The Way; khách hàng có thể theo dõi trạng thái này."
        elif actor_role == "driver" and action == "complete" and current == "Accepted" and order_status == "On The Way":
            cursor.execute(
                """UPDATE DELIVERY_ASSIGNMENT
                   SET status = 'Completed', completed_at = CURRENT_TIMESTAMP
                   WHERE assignment_id = %s""",
                (assignment_id,),
            )
            cursor.callproc("UpdateOrderStatus", [order_id, "Delivered", "Tài xế xác nhận giao thành công"])
            cursor.execute(
                """SELECT COUNT(*) AS earned FROM LOYALTY_TRANSACTION
                   WHERE order_id = %s AND transaction_type = 'EARN'""",
                (order_id,),
            )
            if cursor.fetchone()["earned"] == 0:
                cursor.callproc("ProcessLoyaltyPoints", [order_id])
            message = "Đã hoàn tất giao hàng; đơn chuyển sang Delivered."
        elif actor_role == "driver" and action == "fail" and current == "Accepted" and order_status == "On The Way":
            if not reason:
                raise ValueError("Nhập lý do giao thất bại.")
            cursor.execute(
                """UPDATE DELIVERY_ASSIGNMENT
                   SET status = 'Failed', completed_at = CURRENT_TIMESTAMP,
                       failure_reason = %s
                   WHERE assignment_id = %s""",
                (reason[:255], assignment_id),
            )
            cursor.callproc("UpdateOrderStatus", [order_id, "Delivery Failed", reason[:255]])
            message = "Đã lưu lần giao thất bại; có thể thử phân công tài xế khác."
        else:
            raise ValueError(f"Không thể thực hiện thao tác này khi lượt giao đang ở trạng thái {current}.")

        connection.commit()
        flash(message, "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể cập nhật giao hàng: {exc}", "error")
    finally:
        connection.close()
    if actor_role == "driver" and actor_driver_id:
        return redirect(url_for("driver_portal", driver_id=actor_driver_id))
    return redirect(role_home())


@app.post("/assignments/<int:assignment_id>/location")
@driver_login_required
def record_location(assignment_id: int):
    actor_driver_id = session["driver_id"]
    latitude = request.form.get("latitude", type=float)
    longitude = request.form.get("longitude", type=float)
    location_text = request.form.get("location_text", "").strip() or None
    if latitude is None or longitude is None:
        flash("Nhập cả vĩ độ và kinh độ.", "error")
        return redirect(url_for("driver_portal", driver_id=actor_driver_id))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """SELECT driver_id FROM DELIVERY_ASSIGNMENT
               WHERE assignment_id = %s AND status = 'Accepted' FOR UPDATE""",
            (assignment_id,),
        )
        active = cursor.fetchone()
        if not active:
            raise ValueError("Chỉ ghi vị trí cho lượt giao đã được tài xế nhận.")
        if actor_driver_id != active["driver_id"]:
            raise ValueError("Chỉ tài xế được phân công mới có thể cập nhật vị trí.")
        cursor.execute(
            """INSERT INTO LOCATION (driver_id, latitude, longitude, address_text)
               VALUES (%s, %s, %s, %s)""",
            (active["driver_id"], latitude, longitude, location_text),
        )
        connection.commit()
        flash("Đã ghi nhận vị trí tài xế.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể ghi nhận vị trí: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("driver_portal", driver_id=actor_driver_id))


@app.get("/orders/<int:order_id>")
@role_required("customer", "restaurant", "driver", "admin")
def order_detail(order_id: int):
    source = session.get("role", "")
    if source not in {"customer", "restaurant", "driver", "admin"}:
        flash("Đăng nhập để xem chi tiết đơn hàng.", "info")
        return redirect(url_for("account_login", next=request.full_path))
    order = query_all(
        """SELECT o.*, c.first_name, c.last_name, r.name AS restaurant_name,
                  s.status AS current_status, s.changed_at AS status_time,
                  receipt.confirmed_at AS customer_confirmed_at
           FROM ORDERS o JOIN CUSTOMER c ON c.customer_id = o.customer_id
           JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
           LEFT JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
           LEFT JOIN CUSTOMER_ORDER_RECEIPT receipt
             ON receipt.order_id = o.order_id AND receipt.customer_id = o.customer_id
           WHERE o.order_id = %s""",
        (order_id,),
    )
    if not order:
        flash("Không tìm thấy đơn hàng.", "error")
        return redirect(role_home())
    owns_order = (
        (source == "customer" and order[0]["customer_id"] == session.get("customer_id")) or
        (source == "restaurant" and order[0]["restaurant_id"] == session.get("restaurant_id"))
    )
    if source == "driver":
        owns_order = bool(query_all(
            "SELECT assignment_id FROM DELIVERY_ASSIGNMENT WHERE order_id = %s AND driver_id = %s LIMIT 1",
            (order_id, session.get("driver_id")),
        ))
    if source != "admin" and not owns_order:
        flash("Tài khoản của bạn không có quyền xem đơn hàng này.", "error")
        return redirect(role_home())
    items = query_all(
        """SELECT mi.name AS item_name, v.variant_name, oi.unit_price,
                  oi.quantity, oi.notes, oi.order_item_id,
                  GROUP_CONCAT(oic.customization_name ORDER BY oic.customization_id SEPARATOR '||') AS customization_names
           FROM ORDER_ITEM oi JOIN MENU_ITEM_VARIANT v ON v.variant_id = oi.variant_id
           JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
           LEFT JOIN ORDER_ITEM_CUSTOMIZATION oic ON oic.order_item_id = oi.order_item_id
           WHERE oi.order_id = %s
           GROUP BY oi.order_item_id, mi.name, v.variant_name, oi.unit_price, oi.quantity, oi.notes
           ORDER BY oi.order_item_id""",
        (order_id,),
    )
    history = query_all(
        "SELECT status, changed_at, status_note FROM ORDER_STATUS_HISTORY WHERE order_id = %s ORDER BY changed_at, order_status_history_id",
        (order_id,),
    )
    assignments = query_all(
        """SELECT da.assignment_id, da.status, da.assigned_at, da.accepted_at,
                  da.completed_at, da.failure_reason, d.first_name, d.last_name,
                  d.phone_number
           FROM DELIVERY_ASSIGNMENT da JOIN DRIVER d ON d.driver_id = da.driver_id
           WHERE da.order_id = %s ORDER BY da.assigned_at, da.assignment_id""",
        (order_id,),
    )
    locations = query_all(
        """SELECT l.latitude, l.longitude, l.address_text, l.recorded_at,
                  d.first_name, d.last_name
           FROM LOCATION l JOIN DRIVER d ON d.driver_id = l.driver_id
           WHERE EXISTS (SELECT 1 FROM DELIVERY_ASSIGNMENT da
                         WHERE da.order_id = %s AND da.driver_id = l.driver_id)
           ORDER BY l.recorded_at DESC, l.location_id DESC LIMIT 12""",
        (order_id,),
    )
    return render_template(
        "order_detail.html", order=order[0], items=items, history=history,
        assignments=assignments, locations=locations, source=source,
    )


@app.get("/admin")
@admin_login_required
def admin_portal():
    restaurants = query_all(
        """SELECT r.restaurant_id, r.name, r.phone_number, r.email, r.is_active,
                  a.account_id, a.display_name AS manager_name, a.email AS manager_email,
                  a.is_active AS manager_active
           FROM RESTAURANT r LEFT JOIN PHASE4_ACCOUNT a
             ON a.restaurant_id = r.restaurant_id AND a.role = 'restaurant'
           ORDER BY r.name"""
    )
    unlinked_drivers = query_all(
        """SELECT d.driver_id, d.first_name, d.last_name, d.email, d.phone_number, d.vehicle_type
           FROM DRIVER d LEFT JOIN PHASE4_ACCOUNT a
             ON a.driver_id = d.driver_id AND a.role = 'driver'
           WHERE a.account_id IS NULL ORDER BY d.last_name, d.first_name"""
    )
    driver_accounts = query_all(
        """SELECT a.account_id, a.display_name, a.email, a.is_active,
                  d.driver_id, d.phone_number, d.vehicle_type
           FROM PHASE4_ACCOUNT a JOIN DRIVER d ON d.driver_id = a.driver_id
           WHERE a.role = 'driver' ORDER BY d.last_name, d.first_name"""
    )
    counts = query_all(
        """SELECT COUNT(*) AS open_orders FROM ORDER_CURRENT_STATUS
           WHERE status IN ('Pending','Preparing','Ready','On The Way','Delivery Failed')"""
    )
    return render_template(
        "admin_portal.html", restaurants=restaurants,
        unlinked_drivers=unlinked_drivers, driver_accounts=driver_accounts,
        open_orders=counts[0]["open_orders"] if counts else 0,
    )


@app.post("/admin/restaurants")
@admin_login_required
def admin_create_restaurant():
    name = request.form.get("name", "").strip()
    phone = request.form.get("phone_number", "").strip()
    email = request.form.get("email", "").strip().lower()
    manager_password = request.form.get("manager_password", "")
    if not name or len(name) > 100 or not phone or len(phone) > 20 or not email or len(email) > 100 or "@" not in email:
        flash("Thông tin nhà hàng không hợp lệ.", "error")
        return redirect(url_for("admin_portal"))
    if len(manager_password) < 8:
        flash("Mật khẩu ban đầu của nhà hàng phải có ít nhất 8 ký tự.", "error")
        return redirect(url_for("admin_portal"))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor()
        cursor.execute("SELECT customer_id FROM CUSTOMER WHERE email = %s", (email,))
        if cursor.fetchone():
            raise ValueError("Email này đang được khách hàng sử dụng.")
        cursor.execute(
            "INSERT INTO RESTAURANT (name, phone_number, email) VALUES (%s, %s, %s)",
            (name, phone, email),
        )
        restaurant_id = cursor.lastrowid
        cursor.execute(
            """INSERT INTO PHASE4_ACCOUNT (role, email, display_name, password_hash, restaurant_id)
               VALUES ('restaurant', %s, %s, %s, %s)""",
            (email, name, generate_password_hash(manager_password), restaurant_id),
        )
        connection.commit()
        flash(f"Đã thêm nhà hàng #{restaurant_id} và tạo tài khoản quản lý.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể thêm nhà hàng: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("admin_portal"))


@app.post("/admin/restaurants/<int:restaurant_id>/edit")
@admin_login_required
def admin_edit_restaurant(restaurant_id: int):
    name = request.form.get("name", "").strip()
    phone = request.form.get("phone_number", "").strip()
    email = request.form.get("email", "").strip().lower()
    if not name or len(name) > 100 or not phone or len(phone) > 20 or not email or len(email) > 100 or "@" not in email:
        flash("Thông tin nhà hàng không hợp lệ.", "error")
        return redirect(url_for("admin_portal"))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE RESTAURANT SET name=%s, phone_number=%s, email=%s WHERE restaurant_id=%s",
            (name, phone, email, restaurant_id),
        )
        if not cursor.rowcount:
            raise ValueError("Không tìm thấy nhà hàng.")
        cursor.execute(
            "UPDATE PHASE4_ACCOUNT SET display_name=%s WHERE role='restaurant' AND restaurant_id=%s",
            (name, restaurant_id),
        )
        connection.commit()
        flash("Đã cập nhật thông tin nhà hàng. Email liên hệ không đổi email đăng nhập của đối tác.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể cập nhật nhà hàng: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("admin_portal"))


@app.post("/admin/restaurants/<int:restaurant_id>/toggle")
@admin_login_required
def admin_toggle_restaurant(restaurant_id: int):
    active = request.form.get("is_active") == "1"
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE RESTAURANT SET is_active=%s WHERE restaurant_id=%s",
            (active, restaurant_id),
        )
        if not cursor.rowcount:
            raise ValueError("Không tìm thấy nhà hàng.")
        cursor.execute(
            "UPDATE PHASE4_ACCOUNT SET is_active=%s WHERE restaurant_id=%s AND role='restaurant'",
            (active, restaurant_id),
        )
        connection.commit()
        flash("Đã cập nhật trạng thái nhà hàng.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể cập nhật trạng thái: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("admin_portal"))


@app.post("/admin/restaurants/<int:restaurant_id>/account")
@admin_login_required
def admin_create_restaurant_account(restaurant_id: int):
    email = request.form.get("email", "").strip().lower()
    password = request.form.get("password", "")
    rows = query_all("SELECT name FROM RESTAURANT WHERE restaurant_id=%s", (restaurant_id,))
    if not rows:
        flash("Không tìm thấy nhà hàng.", "error")
    elif not email or len(email) > 100 or "@" not in email or len(password) < 8:
        flash("Cần email hợp lệ và mật khẩu ít nhất 8 ký tự.", "error")
    else:
        connection = get_connection()
        try:
            cursor = connection.cursor()
            cursor.execute("SELECT customer_id FROM CUSTOMER WHERE email=%s", (email,))
            if cursor.fetchone():
                raise ValueError("Email này đang được khách hàng sử dụng.")
            cursor.execute(
                """INSERT INTO PHASE4_ACCOUNT (role,email,display_name,password_hash,restaurant_id)
                   VALUES ('restaurant',%s,%s,%s,%s)""",
                (email, rows[0]["name"], generate_password_hash(password), restaurant_id),
            )
            connection.commit()
            flash("Đã tạo tài khoản nhà hàng.", "success")
        except (Error, ValueError) as exc:
            connection.rollback()
            flash(f"Không thể tạo tài khoản nhà hàng: {exc}", "error")
        finally:
            connection.close()
    return redirect(url_for("admin_portal"))


@app.post("/admin/drivers/<int:driver_id>/account")
@admin_login_required
def admin_create_driver_account(driver_id: int):
    password = request.form.get("password", "")
    drivers = query_all(
        "SELECT first_name, last_name, email FROM DRIVER WHERE driver_id=%s",
        (driver_id,),
    )
    if not drivers or len(password) < 8:
        flash("Không tìm thấy tài xế hoặc mật khẩu chưa đủ 8 ký tự.", "error")
        return redirect(url_for("admin_portal"))
    driver = drivers[0]
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT customer_id FROM CUSTOMER WHERE email=%s", (driver["email"],))
        if cursor.fetchone():
            raise ValueError("Email tài xế đang được khách hàng sử dụng.")
        cursor.execute(
            """INSERT INTO PHASE4_ACCOUNT (role,email,display_name,password_hash,driver_id)
               VALUES ('driver',%s,%s,%s,%s)""",
            (driver["email"], f"{driver['first_name']} {driver['last_name']}",
             generate_password_hash(password), driver_id),
        )
        connection.commit()
        flash("Đã tạo tài khoản đăng nhập cho tài xế.", "success")
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể tạo tài khoản tài xế: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("admin_portal"))


@app.post("/admin/accounts/<int:account_id>/toggle")
@admin_login_required
def admin_toggle_account(account_id: int):
    active = request.form.get("is_active") == "1"
    connection = get_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE PHASE4_ACCOUNT SET is_active=%s WHERE account_id=%s AND role <> 'admin'",
            (active, account_id),
        )
        connection.commit()
        flash("Đã cập nhật quyền đăng nhập đối tác." if cursor.rowcount else "Không tìm thấy tài khoản đối tác.",
              "success" if cursor.rowcount else "error")
    except Error as exc:
        connection.rollback()
        flash(f"Không thể cập nhật tài khoản: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("admin_portal"))


@app.get("/health")
def health():
    try:
        query_all("SELECT 1 AS connected")
        return {"status": "ok", "database": "connected"}
    except Error as exc:
        return {"status": "error", "database": str(exc)}, 503


if __name__ == "__main__":
    app.run(host=os.getenv("APP_HOST", "127.0.0.1"), port=int(os.getenv("APP_PORT", "5000")), debug=False)
