# Business Rules

## Customer and Order

1. Every ORDER is placed by exactly one CUSTOMER.

2. A CUSTOMER can place one or many ORDERS.

## Restaurant and Order

3. Every ORDER belongs to exactly one RESTAURANT.

4. A RESTAURANT can receive one or many ORDERS.

## Driver and Order

5. An ORDER may be delivered by zero or one DRIVER.

6. A DRIVER can deliver zero or many ORDERS.

## Order and Order Item

7. Every ORDER must contain one or more ORDER_ITEMS.

8. Every ORDER_ITEM belongs to exactly one ORDER.

## Order Item and Menu Item

9. Every ORDER_ITEM refers to exactly one MENU_ITEM.

10. A MENU_ITEM can be referenced by zero or many ORDER_ITEMS.

## Restaurant and Menu Item

11. A RESTAURANT offers one or many MENU_ITEMS.

12. A MENU_ITEM may be offered by zero or one RESTAURANT.

## Driver and Location

13. Every DRIVER has one current LOCATION.

14. A LOCATION can represent the current position of zero or many
DRIVERS.

## Customer and Review

15. Every REVIEW is written by exactly one CUSTOMER.

16. A CUSTOMER can write zero or many REVIEWS.

## Restaurant and Review

17. Every REVIEW is associated with exactly one RESTAURANT.

18. A RESTAURANT can receive zero or many REVIEWS.

19. A RESTAURANT's avg_rating is derived from its REVIEWS.

## Order Status History

20. Every ORDER must have one or more ORDER_STATUS_HISTORY records.

21. Every ORDER_STATUS_HISTORY record belongs to exactly one ORDER.

22. An ORDER's current_status is derived from its most recent
ORDER_STATUS_HISTORY record.

## Customer Loyalty

23. A CUSTOMER can have zero or many LOYALTY_TRANSACTIONS.

24. Every LOYALTY_TRANSACTION belongs to exactly one CUSTOMER.

25. A CUSTOMER's loyalty_points is derived from the sum of points
recorded in LOYALTY_TRANSACTION.

## Order Delivery Information

26. Every ORDER has exactly one delivery_address.

27. An ORDER's estimated_delivery_time is derived from order processing
and delivery information.