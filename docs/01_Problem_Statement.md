# Problem Statement

## Phase 1 - Conceptual Design

This document defines the problem statement for the conceptual database
design of the Food Delivery Aggregator (Mini-DoorDash).

## 1. Background

Food delivery platforms connect customers, restaurants, and delivery
drivers through a centralized system.

Customers need to discover restaurants, select menu items and their
variants, place orders, provide a delivery address, and track the
delivery process. Restaurants need to manage the menu items they offer,
including different variants and prices, and receive customer orders.
Delivery drivers are responsible for accepting delivery assignments and
providing location information for delivery tracking.

The system must also track the lifecycle of each order, including order
status changes, delivery information, customer reviews, restaurant
ratings, and customer loyalty transactions.

The model is designed to reflect realistic delivery operations rather
than assuming that one order always has exactly one driver. A delivery
order may have multiple delivery assignments over time when a driver
rejects, cancels, or fails a delivery assignment, while the history of
previous assignments is retained.

------------------------------------------------------------------------

## 2. Problem

A food delivery platform involves multiple entities and relationships
that must be represented consistently in a comprehensive conceptual
model.

The system needs to manage:

-   Customer information and multiple saved delivery addresses
-   Restaurant information and the menu items offered by restaurants
-   Menu item variants such as size/type and variant-specific prices
-   Orders and order items
-   Delivery assignments between orders and drivers
-   Delivery drivers and their recorded locations
-   Customer reviews and restaurant ratings
-   Order status history
-   Customer loyalty transactions
-   Delivery information and estimated delivery time

The system must maintain the relationships between these entities while
enforcing appropriate cardinalities and business rules.

The model must also support realistic operational situations, including:

-   A normal order containing one or more order items
-   A very large order that may require multiple delivery assignments or
    delivery rounds
-   A menu item becoming unavailable
-   A customer or restaurant cancelling an order
-   A driver rejecting or cancelling a delivery assignment
-   A delivery attempt failing and requiring another assignment
-   Multiple delivery assignments being retained as historical records
    while at most one assignment is active for an order at a time

Several values are derived from system data. For example, restaurant
average rating is derived from reviews, the current order status is
derived from the most recent order status history record, customer
loyalty points are derived from loyalty transactions, and estimated
delivery time is derived from order processing and delivery information.

------------------------------------------------------------------------

## 3. Objective

The objective of this project is to design a comprehensive conceptual
ER/EER database model for a Food Delivery Aggregator (Mini-DoorDash).

The conceptual model should:

-   Identify the major entities of the system.
-   Define important attributes for each entity.
-   Identify relationships between entities.
-   Define appropriate cardinalities using UML-style multiplicity
    notation.
-   Represent multi-valued attributes.
-   Represent derived attributes.
-   Represent menu item variants and variant-specific prices.
-   Represent delivery assignments between orders and drivers.
-   Capture the history of delivery assignments when reassignment is
    required.
-   Capture order status history.
-   Support restaurant reviews and ratings.
-   Support customer loyalty transactions.
-   Support driver location tracking through multiple LOCATION records.
-   Clearly represent the business rules of the system.

------------------------------------------------------------------------

## 4. Scope

The conceptual model covers the following areas:

### Customer Management

The system stores customer identity, contact information, authentication
data, multiple saved delivery addresses, and loyalty information.

### Restaurant Management

The system stores restaurant information, the menu items offered by
restaurants, and customer reviews.

### Menu and Variant Management

The system stores MENU_ITEM records and their optional MENU_ITEM_VARIANT
records. A menu item may have zero or many variants, and each variant
belongs to exactly one menu item and may have its own price and
availability status.

### Order Management

The system records orders placed by customers, the restaurant receiving
each order, delivery information, order items, selected menu item
variants, and order status history.

### Delivery Management

The system records DELIVERY_ASSIGNMENT entries that connect orders with
drivers. An order may have zero or many assignments over its delivery
lifecycle, while each assignment belongs to exactly one order and
exactly one driver. If an assignment fails or is cancelled, a new
assignment can be created while the previous assignment remains in the
history.

The system also records multiple LOCATION entries for drivers so that
driver location history can be tracked.

### Review Management

Customers can write reviews for restaurants. A restaurant can receive
zero or many reviews, and its average rating is derived from related
review records.

### Loyalty Management

Customers can have zero or many loyalty transactions. Customer loyalty
points are derived from the sum of points recorded in these
transactions.

### Order Status Management

The system records every order status change in ORDER_STATUS_HISTORY.
The current order status is derived from the most recent history record.

------------------------------------------------------------------------

## 5. Conceptual Model Entities

The conceptual model contains the following 12 entities:

1.  CUSTOMER
2.  RESTAURANT
3.  ORDER
4.  ORDER_ITEM
5.  MENU_ITEM
6.  MENU_ITEM_VARIANT
7.  DRIVER
8.  DELIVERY_ASSIGNMENT
9.  LOCATION
10. REVIEW
11. ORDER_STATUS_HISTORY
12. LOYALTY_TRANSACTION

------------------------------------------------------------------------

## 6. Main Relationships

The comprehensive ER/EER model represents the following main
relationships:

1.  CUSTOMER PLACES ORDER
2.  RESTAURANT RECEIVES ORDER
3.  ORDER CONTAINS ORDER_ITEM
4.  ORDER_ITEM SELECT_IN MENU_ITEM_VARIANT
5.  MENU_ITEM HAS_VARIANT MENU_ITEM_VARIANT
6.  RESTAURANT OFFERS MENU_ITEM
7.  ORDER HAS_ASSIGNMENT DELIVERY_ASSIGNMENT
8.  DELIVERY_ASSIGNMENT ASSIGNED_TO DRIVER
9.  DRIVER LOCATED_AT LOCATION
10. CUSTOMER WRITES REVIEW
11. RESTAURANT RECEIVES_REVIEW REVIEW
12. ORDER HAS_STATUS_HISTORY ORDER_STATUS_HISTORY
13. CUSTOMER HAS LOYALTY_TRANSACTION

------------------------------------------------------------------------

## 7. Derived Data

The following attributes are derived from related system data:

-   CUSTOMER.loyalty_points
-   RESTAURANT.avg_rating
-   ORDER.current_status
-   ORDER.estimated_delivery_time

These attributes represent calculated or system-derived information
rather than independent source records.

------------------------------------------------------------------------

## 8. Multi-Valued Attributes

The ER/EER model represents the following multi-valued attributes:

-   CUSTOMER.address
-   ORDER.order_notes
-   ORDER_ITEM.customizations

These attributes may contain multiple values associated with the
corresponding entity.

------------------------------------------------------------------------

## 9. Order and Delivery Scenarios

The conceptual model is designed to support the following scenarios:

### Normal Order

An ORDER is created by a CUSTOMER, belongs to one RESTAURANT, contains
one or more ORDER_ITEMS, and each ORDER_ITEM selects exactly one
MENU_ITEM_VARIANT.

### Large Order

A very large order, such as an order for 100 pizzas, may require
multiple delivery assignments or delivery rounds. The model therefore
allows one ORDER to have zero or many DELIVERY_ASSIGNMENT records.

### Driver Reassignment

If a driver rejects, cancels, or fails a delivery assignment, the
previous DELIVERY_ASSIGNMENT is retained and the system can create a new
assignment for another DRIVER.

### Delivery Failure

When a DELIVERY_ASSIGNMENT has a Failed status, the system records a
failure_reason. The order can then be reassigned or cancelled according
to the business process.

### Order Status Tracking

Every change in an order's status is recorded in ORDER_STATUS_HISTORY.
ORDER.current_status is derived from the most recent status history
record.
