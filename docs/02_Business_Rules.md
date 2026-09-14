# Business Rules

These business rules define the constraints represented in the current
Phase 1 comprehensive ER/EER model.

## Customer and Order

1.  Every ORDER is placed by exactly one CUSTOMER.
2.  A CUSTOMER can place zero or many ORDERS.

## Restaurant and Order

3.  Every ORDER belongs to exactly one RESTAURANT.
4.  A RESTAURANT can receive zero or many ORDERS.

## Order and Delivery Assignment

5.  Every DELIVERY_ASSIGNMENT belongs to exactly one ORDER.
6.  An ORDER can have zero or many DELIVERY_ASSIGNMENTS.
7.  At a given time, an ORDER has at most one active
    DELIVERY_ASSIGNMENT.

## Order and Order Item

8.  Every ORDER must contain one or more ORDER_ITEMS.
9.  Every ORDER_ITEM belongs to exactly one ORDER.
10. Every ORDER_ITEM refers to exactly one MENU_ITEM_VARIANT.

## Delivery Assignment and Driver

11. Every DELIVERY_ASSIGNMENT is assigned to exactly one DRIVER.
12. A DRIVER can have zero or many DELIVERY_ASSIGNMENTS.
13. If a DELIVERY_ASSIGNMENT fails or is cancelled, the system creates a
    new DELIVERY_ASSIGNMENT for the next driver while retaining the
    previous assignment for delivery history.
14. If a DELIVERY_ASSIGNMENT has status Failed, failure_reason must be
    recorded.
15. The status of a DELIVERY_ASSIGNMENT must follow the valid
    delivery-assignment status transitions defined by the system.

## Menu Item and Variant

16. Every MENU_ITEM_VARIANT belongs to exactly one MENU_ITEM.
17. A MENU_ITEM can have zero or many MENU_ITEM_VARIANTS.
18. A MENU_ITEM_VARIANT can have its own price and availability status.

## Restaurant and Menu Item

19. A RESTAURANT offers zero or many MENU_ITEMS.
20. A MENU_ITEM is offered by zero or one RESTAURANT.

## Driver and Location

21. A DRIVER can have zero or many LOCATION records.
22. Every LOCATION record belongs to exactly one DRIVER.
23. LOCATION records represent the driver's recorded position over time
    for delivery tracking.

## Derived Attributes

24. RESTAURANT.avg_rating is derived from the related REVIEW records.
25. ORDER.current_status is derived from the most recent
    ORDER_STATUS_HISTORY record.
26. CUSTOMER.loyalty_points is derived from the sum of points recorded
    in LOYALTY_TRANSACTION.
27. ORDER.estimated_delivery_time is derived from order processing and
    delivery information.

## Customer and Review

28. Every REVIEW is written by exactly one CUSTOMER.
29. A CUSTOMER can write zero or many REVIEWS.

## Restaurant and Review

30. Every REVIEW is associated with exactly one RESTAURANT.
31. A RESTAURANT can receive zero or many REVIEWS.

## Order Status History

32. Every ORDER must have one or more ORDER_STATUS_HISTORY records.
33. Every ORDER_STATUS_HISTORY record belongs to exactly one ORDER.

## Order Delivery Information

34. Every ORDER has exactly one delivery_address.

## Customer Loyalty

35. A CUSTOMER can have zero or many LOYALTY_TRANSACTIONS.
36. Every LOYALTY_TRANSACTION belongs to exactly one CUSTOMER.

## Order Status Transitions

The order status follows the defined transition flow:

  -----------------------------------------------------------------------
  Current Status          Meaning                 Can transition to
  ----------------------- ----------------------- -----------------------
  Pending                 Order has been created  Preparing, Cancelled
                          and is waiting for      
                          processing.             

  Preparing               Restaurant is preparing Ready, Cancelled
                          the order.              

  Ready                   Order is ready for      On The Way, Cancelled
                          pickup/delivery.        

  On The Way              Driver is transporting  Delivered, Delivery
                          the order to the        Failed
                          customer.               

  Delivered               Order has been          No further transition
                          completed.              

  Cancelled               Order has been          No further transition
                          cancelled.              

  Delivery Failed         Delivery was            On The Way, Cancelled
                          unsuccessful and        
                          requires further        
                          handling.               
  -----------------------------------------------------------------------

## Multi-Valued Attributes

The ER/EER model represents the following multi-valued attributes:

-   CUSTOMER.address
-   ORDER.order_notes
-   ORDER_ITEM.customizations
