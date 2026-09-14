# Food Delivery Aggregator (Mini-DoorDash)

## Phase 1 - Conceptual Design

This repository contains the Phase 1 conceptual database design for a
Food Delivery Aggregator (Mini-DoorDash).

### Phase 1 Timeline

  -----------------------------------------------------------------------
  Phase             Timeline          Deliverables      Assessment Weight
  ----------------- ----------------- ----------------- -----------------
  Phase 1:          Weeks 3--4        Problem           20% (Design)
  Conceptual Design                   Statement,        
                                      Business Rules,   
                                      Comprehensive     
                                      ER/EER Diagram    

  -----------------------------------------------------------------------

### Phase 1 Deliverables

-   01_Problem_Statement.md
-   02_Business_Rules.md
-   03_ERD.png
-   04_BAO_CAO_NHOM_DI_MUOI_TUAN_3_4.pdf

### Documentation

1.  [Problem Statement](docs/01_Problem_Statement.md)
2.  [Business Rules](docs/02_Business_Rules.md)
3.  [ER/EER Diagram](docs/03_ERD.png)
4.  [Project Report - BÁO CÁO NHÓM DÌ MƯỜI TUẦN
    3-4](BAO_CAO_NHOM_DI_MUOI_TUAN_3_4.pdf)

### Conceptual Model Summary

The current Phase 1 ER/EER model contains 12 entities:

-   CUSTOMER
-   RESTAURANT
-   ORDER
-   ORDER_ITEM
-   MENU_ITEM
-   MENU_ITEM_VARIANT
-   DRIVER
-   DELIVERY_ASSIGNMENT
-   LOCATION
-   REVIEW
-   ORDER_STATUS_HISTORY
-   LOYALTY_TRANSACTION

The model represents 13 main relationships:

-   CUSTOMER PLACES ORDER
-   RESTAURANT RECEIVES ORDER
-   ORDER CONTAINS ORDER_ITEM
-   ORDER_ITEM SELECT_IN MENU_ITEM_VARIANT
-   MENU_ITEM HAS_VARIANT MENU_ITEM_VARIANT
-   RESTAURANT OFFERS MENU_ITEM
-   ORDER HAS_ASSIGNMENT DELIVERY_ASSIGNMENT
-   DELIVERY_ASSIGNMENT ASSIGNED_TO DRIVER
-   DRIVER LOCATED_AT LOCATION
-   CUSTOMER WRITES REVIEW
-   RESTAURANT RECEIVES_REVIEW REVIEW
-   ORDER HAS_STATUS_HISTORY ORDER_STATUS_HISTORY
-   CUSTOMER HAS LOYALTY_TRANSACTION

### Important Model Updates

The current ER/EER model improves the previous version by adding:

-   `MENU_ITEM_VARIANT` to represent size/type variants and
    variant-specific prices.
-   `DELIVERY_ASSIGNMENT` to represent delivery assignment history and
    driver reassignment.
-   Multiple `LOCATION` records per driver for location tracking
    history.
-   Zero-or-many restaurant menu offerings and driver/order
    relationships where appropriate.
-   Derived attributes for loyalty points, restaurant average rating,
    current order status, and estimated delivery time.
-   Multi-valued attributes for customer addresses, order notes, and
    item customizations.
-   Order status history and delivery exception scenarios.

### Project Report

The Phase 1 project report documents the Problem Statement, Business
Rules & Constraints, entity definitions, sample data, and the
comprehensive ER/EER conceptual model.

The report has been updated to match the current ER/EER model, including
the 12 entities, delivery assignments, menu item variants,
cardinalities, derived attributes, multi-valued attributes, and
delivery/order status scenarios.

### Project Status

**Current Phase:** Phase 1 - Conceptual Design

**Status:** Conceptual design completed with Problem Statement, Business
Rules, Comprehensive ER/EER Diagram, and Phase 1 project report.
