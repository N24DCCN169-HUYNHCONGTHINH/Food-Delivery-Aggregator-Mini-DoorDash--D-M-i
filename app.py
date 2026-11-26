"""Flask web demo for the Mini-DoorDash Phase 3 MySQL database."""

from __future__ import annotations

import os
from decimal import Decimal
from typing import Any

import mysql.connector
from flask import Flask, flash, redirect, render_template, request, url_for
from mysql.connector import Error

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "local-demo-secret-change-before-deployment")


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


@app.get("/")
def index():
    restaurants = query_all(
        """SELECT r.restaurant_id, r.name, r.phone_number,
                  COALESCE(ROUND(AVG(rv.rating), 1), 0) AS avg_rating,
                  COUNT(DISTINCT mi.menu_item_id) AS menu_count
           FROM RESTAURANT r
           LEFT JOIN REVIEW rv ON rv.restaurant_id = r.restaurant_id
           LEFT JOIN MENU_ITEM mi ON mi.restaurant_id = r.restaurant_id
           GROUP BY r.restaurant_id, r.name, r.phone_number
           ORDER BY r.name"""
    )
    return render_template("index.html", restaurants=restaurants)


@app.get("/restaurants/<int:restaurant_id>")
def restaurant_menu(restaurant_id: int):
    restaurants = query_all(
        "SELECT restaurant_id, name FROM RESTAURANT WHERE restaurant_id = %s",
        (restaurant_id,),
    )
    if not restaurants:
        flash("Không tìm thấy nhà hàng.", "error")
        return redirect(url_for("index"))
    menu = query_all(
        """SELECT mi.menu_item_id, mi.name AS item_name, mi.description,
                  v.variant_id, v.variant_name, v.price
           FROM MENU_ITEM mi
           JOIN MENU_ITEM_VARIANT v ON v.menu_item_id = mi.menu_item_id
           WHERE mi.restaurant_id = %s AND mi.is_available = TRUE
             AND v.is_available = TRUE
           ORDER BY mi.name, v.price""",
        (restaurant_id,),
    )
    customers = query_all(
        "SELECT customer_id, first_name, last_name FROM CUSTOMER ORDER BY customer_id"
    )
    return render_template(
        "menu.html", restaurant=restaurants[0], menu=menu, customers=customers
    )


@app.post("/orders")
def create_order():
    customer_id = request.form.get("customer_id", type=int)
    variant_ids = request.form.getlist("variant_id", type=int)
    quantities = request.form.getlist("quantity", type=int)
    address = request.form.get("delivery_address", "").strip()
    instructions = request.form.get("instructions", "").strip() or None
    lines = [(variant_id, qty) for variant_id, qty in zip(variant_ids, quantities) if qty > 0]
    if not customer_id or not lines or not address:
        flash("Hãy chọn khách hàng, ít nhất một món và nhập địa chỉ giao hàng.", "error")
        return redirect(request.referrer or url_for("index"))

    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)
        placeholders = ",".join(["%s"] * len(lines))
        cursor.execute(
            f"""SELECT v.variant_id, v.restaurant_id, v.price
                FROM MENU_ITEM_VARIANT v JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
                WHERE v.variant_id IN ({placeholders})
                  AND v.is_available = TRUE AND mi.is_available = TRUE
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

        fee = Decimal("15000.00")
        subtotal = sum(
            (price_map[variant_id] * qty for variant_id, qty in lines), Decimal("0.00")
        )
        tax = (subtotal * Decimal("0.08")).quantize(Decimal("0.01"))
        cursor.execute(
            """INSERT INTO ORDERS
               (customer_id, restaurant_id, order_time, subtotal, delivery_fee,
                tax, total_amount, delivery_address, special_instructions)
               VALUES (%s, %s, CURRENT_TIMESTAMP, %s, %s, %s, %s, %s, %s)""",
            (customer_id, next(iter(restaurant_ids)), subtotal, fee, tax,
             subtotal + fee + tax, address, instructions),
        )
        order_id = cursor.lastrowid
        price_map = {v["variant_id"]: v["price"] for v in variants}
        for variant_id, qty in lines:
            cursor.execute(
                """INSERT INTO ORDER_ITEM (order_id, variant_id, restaurant_id, unit_price, quantity)
                   VALUES (%s, %s, %s, %s, %s)""",
                (order_id, variant_id, next(iter(restaurant_ids)), price_map[variant_id], qty),
            )
        cursor.execute(
            """INSERT INTO ORDER_STATUS_HISTORY (order_id, status, status_note)
               VALUES (%s, 'Pending', 'Khách tạo đơn qua giao diện Phase 4')""",
            (order_id,),
        )
        cursor.callproc("FinalizeOrder", [order_id])
        connection.commit()
        flash(f"Đã tạo đơn #{order_id} thành công.", "success")
        return redirect(url_for("order_detail", order_id=order_id))
    except (Error, ValueError) as exc:
        connection.rollback()
        flash(f"Không thể tạo đơn: {exc}", "error")
        return redirect(request.referrer or url_for("index"))
    finally:
        connection.close()


@app.get("/orders")
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


@app.get("/orders/<int:order_id>")
def order_detail(order_id: int):
    order = query_all(
        """SELECT o.*, c.first_name, c.last_name, r.name AS restaurant_name,
                  s.status AS current_status, s.changed_at AS status_time
           FROM ORDERS o JOIN CUSTOMER c ON c.customer_id = o.customer_id
           JOIN RESTAURANT r ON r.restaurant_id = o.restaurant_id
           LEFT JOIN ORDER_CURRENT_STATUS s ON s.order_id = o.order_id
           WHERE o.order_id = %s""",
        (order_id,),
    )
    if not order:
        flash("Không tìm thấy đơn hàng.", "error")
        return redirect(url_for("orders"))
    items = query_all(
        """SELECT mi.name AS item_name, v.variant_name, oi.unit_price,
                  oi.quantity, oi.notes, oi.order_item_id
           FROM ORDER_ITEM oi JOIN MENU_ITEM_VARIANT v ON v.variant_id = oi.variant_id
           JOIN MENU_ITEM mi ON mi.menu_item_id = v.menu_item_id
           WHERE oi.order_id = %s ORDER BY oi.order_item_id""",
        (order_id,),
    )
    history = query_all(
        "SELECT status, changed_at, status_note FROM ORDER_STATUS_HISTORY WHERE order_id = %s ORDER BY changed_at, order_status_history_id",
        (order_id,),
    )
    return render_template("order_detail.html", order=order[0], items=items, history=history)


@app.post("/orders/<int:order_id>/status")
def update_status(order_id: int):
    status = request.form.get("status", "")
    note = request.form.get("note", "").strip() or None
    allowed = {"Preparing", "Ready", "On The Way", "Delivered", "Cancelled", "Delivery Failed"}
    if status not in allowed:
        flash("Trạng thái không hợp lệ.", "error")
        return redirect(url_for("order_detail", order_id=order_id))
    connection = get_connection()
    try:
        connection.start_transaction()
        cursor = connection.cursor()
        cursor.callproc("UpdateOrderStatus", [order_id, status, note])
        connection.commit()
        flash("Đã cập nhật trạng thái đơn hàng.", "success")
    except Error as exc:
        connection.rollback()
        flash(f"Không thể cập nhật trạng thái: {exc}", "error")
    finally:
        connection.close()
    return redirect(url_for("order_detail", order_id=order_id))


@app.get("/health")
def health():
    try:
        query_all("SELECT 1 AS connected")
        return {"status": "ok", "database": "connected"}
    except Error as exc:
        return {"status": "error", "database": str(exc)}, 503


if __name__ == "__main__":
    app.run(host=os.getenv("APP_HOST", "127.0.0.1"), port=int(os.getenv("APP_PORT", "5000")), debug=False)
