-- Phase 4 additive access-control support.
-- Run after Phase 3.sql against food_delivery_phase3_workbench.
-- The Phase 3 SQL file and its existing business tables remain unchanged.

DELIMITER //
DROP PROCEDURE IF EXISTS AddRestaurantActiveFlagForPhase4//
CREATE PROCEDURE AddRestaurantActiveFlagForPhase4()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'RESTAURANT'
          AND COLUMN_NAME = 'is_active'
    ) THEN
        ALTER TABLE RESTAURANT
            ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE
            COMMENT 'Nhà hàng đang được hiển thị và nhận đơn.';
    END IF;
END//
CALL AddRestaurantActiveFlagForPhase4()//
DROP PROCEDURE AddRestaurantActiveFlagForPhase4//
DELIMITER ;

CREATE TABLE IF NOT EXISTS PHASE4_ACCOUNT (
    account_id INT AUTO_INCREMENT,
    role ENUM('restaurant', 'driver', 'admin') NOT NULL,
    email VARCHAR(100) NOT NULL,
    display_name VARCHAR(120) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    restaurant_id INT NULL,
    driver_id INT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_phase4_account PRIMARY KEY (account_id),
    CONSTRAINT uq_phase4_account_email UNIQUE (email),
    CONSTRAINT uq_phase4_account_restaurant UNIQUE (restaurant_id),
    CONSTRAINT uq_phase4_account_driver UNIQUE (driver_id),
    CONSTRAINT chk_phase4_account_role_link CHECK (
        (role = 'restaurant' AND restaurant_id IS NOT NULL AND driver_id IS NULL) OR
        (role = 'driver' AND restaurant_id IS NULL AND driver_id IS NOT NULL) OR
        (role = 'admin' AND restaurant_id IS NULL AND driver_id IS NULL)
    ),
    CONSTRAINT fk_phase4_account_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES RESTAURANT(restaurant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_phase4_account_driver FOREIGN KEY (driver_id)
        REFERENCES DRIVER(driver_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS CUSTOMER_ORDER_RECEIPT (
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    confirmed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customer_order_receipt PRIMARY KEY (order_id),
    CONSTRAINT fk_receipt_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_receipt_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER(customer_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
