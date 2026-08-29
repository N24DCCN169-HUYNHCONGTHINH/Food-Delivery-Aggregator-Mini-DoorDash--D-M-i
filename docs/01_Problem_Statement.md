# Problem Statement

## 1. Background

Food delivery platforms connect customers, restaurants, and delivery
drivers through a centralized system.

Customers need to discover restaurants, place orders, select menu
items, and provide delivery information. Restaurants need to manage
their menu items and receive customer orders. Delivery drivers are
responsible for delivering orders and maintaining their current
location information.

The system must also track the lifecycle of each order, including
order status changes, delivery information, customer reviews, and
loyalty transactions.

---

## 2. Problem

A food delivery platform involves multiple entities and relationships
that must be represented consistently.

The system needs to manage:

- Customer information and delivery addresses
- Restaurant information and menu items
- Orders and order items
- Delivery drivers and their locations
- Customer reviews and restaurant ratings
- Order status history
- Customer loyalty transactions

The system must maintain the relationships between these entities
while enforcing appropriate cardinalities and business rules.

Several values are derived from system data. For example, restaurant
average rating is derived from reviews, the current order status is
derived from order status history, and customer loyalty points are
derived from loyalty transactions.

---

## 3. Objective

The objective of this project is to design a comprehensive conceptual
database model for a Food Delivery Aggregator (Mini-DoorDash).

The conceptual model should:

- Identify the major entities of the system.
- Define important attributes for each entity.
- Identify relationships between entities.
- Define appropriate cardinalities.
- Represent multi-valued attributes.
- Represent derived attributes.
- Capture order status history.
- Support restaurant reviews and ratings.
- Support customer loyalty transactions.
- Clearly represent the business rules of the system.

---

## 4. Scope

The conceptual model covers the following areas:

### Customer Management

The system stores customer identity, contact information,
authentication data, delivery addresses, and loyalty information.

### Restaurant Management

The system stores restaurant information, menu items, and customer
reviews.

### Order Management

The system records orders placed by customers, the restaurant
receiving each order, delivery information, order items, and order
status history.

### Delivery Management

The system associates orders with delivery drivers and records
driver locations for delivery tracking.

### Review Management

Customers can write reviews for restaurants. Restaurant average
ratings are derived from review data.

### Loyalty Management

Customers can have multiple loyalty transactions. Customer loyalty
points are derived from the accumulated points recorded in these
transactions.

---

## 5. Conceptual Model Entities

The conceptual model contains the following entities:

1. CUSTOMER
2. RESTAURANT
3. ORDER
4. ORDER_ITEM
5. MENU_ITEM
6. DRIVER
7. LOCATION
8. REVIEW
9. ORDER_STATUS_HISTORY
10. LOYALTY_TRANSACTION

---

## 6. Derived Data

The following attributes are derived from related system data:

- CUSTOMER.loyalty_points
- RESTAURANT.avg_rating
- ORDER.current_status
- ORDER.estimated_delivery_time

These attributes represent calculated or system-derived information
rather than independent source records.