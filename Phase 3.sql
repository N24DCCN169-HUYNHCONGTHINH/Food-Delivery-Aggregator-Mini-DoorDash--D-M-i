-- PHASE 3 INTEGRATED WORKBENCH SCRIPT
-- Based on the teammate's phase3.sql; source file is kept unchanged.
-- Uses an isolated database named food_delivery_phase3_workbench.
-- Seed values use numeric IDs mapped from the Phase 1 sample identifiers.
-- See docs/Phase3_SQL_Review.md for source-data discrepancies and review notes.


DROP DATABASE IF EXISTS food_delivery_phase3_workbench;
CREATE DATABASE food_delivery_phase3_workbench CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE food_delivery_phase3_workbench;
-- Database : Mini-DoorDash (Food Delivery Aggregator)
-- DBMS     : MySQL 8.0.16+ (hỗ trợ ràng buộc CHECK)
-- ===================================================================

-- ===================================================================
-- 1. PHÂN HỆ NGƯỜI DÙNG & ĐỐI TÁC
-- ===================================================================

-- Table: CUSTOMER
CREATE TABLE CUSTOMER (
    customer_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi khách hàng.',
    first_name VARCHAR(50) NOT NULL COMMENT 'Tên của khách hàng.',
    last_name VARCHAR(50) NOT NULL COMMENT 'Họ của khách hàng.',
    email VARCHAR(100) NOT NULL COMMENT 'Địa chỉ email dùng để đăng nhập và liên lạc.',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Số điện thoại liên lạc của khách hàng.',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Mật khẩu đã được băm để bảo mật.',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm tài khoản được tạo.',

    -- Constraints
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT uq_customer_phone UNIQUE (phone_number)
);



-- Table: CUSTOMER_ADDRESS
CREATE TABLE CUSTOMER_ADDRESS (
    address_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi địa chỉ.',
    customer_id INT NOT NULL COMMENT 'Khách hàng sở hữu địa chỉ.',
    address_text VARCHAR(255) NOT NULL COMMENT 'Nội dung địa chỉ.',

    -- Constraints
    CONSTRAINT pk_customer_address PRIMARY KEY (address_id),
    CONSTRAINT uq_customer_address UNIQUE (customer_id, address_text),
    CONSTRAINT fk_address_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE
);

-- Table: DRIVER
CREATE TABLE DRIVER (
    driver_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi tài xế.',
    first_name VARCHAR(50) NOT NULL COMMENT 'Tên của tài xế.',
    last_name VARCHAR(50) NOT NULL COMMENT 'Họ của tài xế.',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Số điện thoại tài xế.',
    email VARCHAR(100) NOT NULL COMMENT 'Email tài khoản tài xế.',
    vehicle_type VARCHAR(50) NOT NULL COMMENT 'Loại xe giao hàng (Motorcycle, Car, Bicycle).',
    license_number VARCHAR(50) NOT NULL COMMENT 'Số bằng lái xe.',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Ngày đăng ký trở thành tài xế.',

    -- Constraints
    CONSTRAINT pk_driver PRIMARY KEY (driver_id),
    CONSTRAINT uq_driver_phone UNIQUE (phone_number),
    CONSTRAINT uq_driver_email UNIQUE (email),
    CONSTRAINT uq_driver_license UNIQUE (license_number),
    CONSTRAINT chk_driver_vehicle CHECK (vehicle_type IN ('Motorcycle', 'Car', 'Bicycle'))
);

-- Table: RESTAURANT
CREATE TABLE RESTAURANT (
    restaurant_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi nhà hàng.',
    name VARCHAR(100) NOT NULL COMMENT 'Tên hiển thị của nhà hàng.',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Số điện thoại liên hệ của nhà hàng.',
    email VARCHAR(100) NOT NULL COMMENT 'Địa chỉ email của nhà hàng.',

    -- Constraints
    CONSTRAINT pk_restaurant PRIMARY KEY (restaurant_id),
    CONSTRAINT uq_restaurant_email UNIQUE (email),
    CONSTRAINT uq_restaurant_phone_number UNIQUE (phone_number)
);

-- Index: idx_restaurant_name
CREATE INDEX idx_restaurant_name ON RESTAURANT(name);

-- ===================================================================
-- 2. PHÂN HỆ THỰC ĐƠN & BIẾN THỂ
-- ===================================================================

-- Table: MENU_ITEM
CREATE TABLE MENU_ITEM (
    menu_item_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi món ăn.',
    restaurant_id INT NOT NULL COMMENT 'Nhà hàng cung cấp món ăn.',
    name VARCHAR(100) NOT NULL COMMENT 'Tên của món ăn.',
    description TEXT NULL COMMENT 'Mô tả chi tiết về món ăn, nguyên liệu.',
    is_available BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Trạng thái món ăn còn phục vụ hay không.',

    -- Constraints
    CONSTRAINT pk_menu_item PRIMARY KEY (menu_item_id),
    CONSTRAINT fk_menu_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES RESTAURANT(restaurant_id) ON DELETE CASCADE
);

-- Table: MENU_ITEM_VARIANT
CREATE TABLE MENU_ITEM_VARIANT (
    variant_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho biến thể món.',
    menu_item_id INT NOT NULL COMMENT 'Món ăn gốc.',
    variant_name VARCHAR(50) NOT NULL COMMENT 'Tên biến thể (VD: Large, Spicy).',
    price DECIMAL(10,2) NOT NULL COMMENT 'Giá bán của biến thể này.',
    is_available BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Trạng thái biến thể còn hàng hay không.',

    -- Constraints
    CONSTRAINT pk_variant PRIMARY KEY (variant_id),
    CONSTRAINT chk_variant_price CHECK (price > 0),
    CONSTRAINT fk_variant_menu FOREIGN KEY (menu_item_id)
        REFERENCES MENU_ITEM(menu_item_id) ON DELETE CASCADE
);

-- ===================================================================
-- 3. PHÂN HỆ ĐƠN HÀNG
-- ===================================================================

-- Table: ORDERS
CREATE TABLE ORDERS (
    order_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi đơn đặt hàng.',
    customer_id INT NOT NULL COMMENT 'Khách hàng đặt đơn.',
    restaurant_id INT NOT NULL COMMENT 'Nhà hàng nhận đơn.',
    order_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm đặt hàng.',
    subtotal DECIMAL(10,2) NOT NULL COMMENT 'Tổng tiền đồ ăn trước phí và thuế.',
    delivery_fee DECIMAL(10,2) NOT NULL COMMENT 'Phí giao hàng.',
    tax DECIMAL(10,2) NOT NULL COMMENT 'Tiền thuế.',
    total_amount DECIMAL(10,2) NOT NULL COMMENT 'Tổng tiền thanh toán cuối cùng.',
    delivery_address TEXT NOT NULL COMMENT 'Địa chỉ giao hàng cụ thể cho đơn này.',
    special_instructions TEXT NULL COMMENT 'Ghi chú chung cho đơn hàng (VD: Gọi khi đến).',

    -- Constraints
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT chk_orders_amounts CHECK (subtotal >= 0 AND delivery_fee >= 0 AND tax >= 0),
    CONSTRAINT chk_orders_total CHECK (total_amount = subtotal + delivery_fee + tax),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES RESTAURANT(restaurant_id) ON DELETE RESTRICT
);

-- Indexes
CREATE INDEX idx_order_customer ON ORDERS(customer_id);
CREATE INDEX idx_order_restaurant ON ORDERS(restaurant_id);
CREATE INDEX idx_orders_order_time ON ORDERS(order_time);

-- Table: ORDER_NOTE
CREATE TABLE ORDER_NOTE (
    order_note_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi ghi chú.',
    order_id INT NOT NULL COMMENT 'Đơn hàng được ghi chú.',
    note_text VARCHAR(255) NOT NULL COMMENT 'Nội dung ghi chú.',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm tạo ghi chú.',

    -- Constraints
    CONSTRAINT pk_order_note PRIMARY KEY (order_note_id),
    CONSTRAINT fk_note_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE CASCADE
);

-- Table: ORDER_ITEM
CREATE TABLE ORDER_ITEM (
    order_item_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất của chi tiết đơn hàng.',
    order_id INT NOT NULL COMMENT 'Thuộc về đơn hàng nào.',
    variant_id INT NOT NULL COMMENT 'Món (biến thể) được đặt.',
    unit_price DECIMAL(10,2) NOT NULL COMMENT 'Giá tại thời điểm đặt (sao chép từ biến thể).',
    quantity INT NOT NULL DEFAULT 1 COMMENT 'Số lượng món đặt.',
    notes VARCHAR(255) NULL COMMENT 'Ghi chú riêng cho món này (VD: Không hành).',

    -- Constraints
    CONSTRAINT pk_order_item PRIMARY KEY (order_item_id),
    CONSTRAINT chk_order_item_quantity CHECK (quantity >= 1),
    CONSTRAINT chk_order_item_price CHECK (unit_price >= 0),
    CONSTRAINT fk_orderitem_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_orderitem_variant FOREIGN KEY (variant_id)
        REFERENCES MENU_ITEM_VARIANT(variant_id) ON DELETE RESTRICT
);

-- Ensure an order item can only use a variant offered by that order's restaurant.
-- Composite keys carry restaurant_id through the FK path.
ALTER TABLE MENU_ITEM
    ADD CONSTRAINT uq_menu_item_restaurant UNIQUE (menu_item_id, restaurant_id);

ALTER TABLE MENU_ITEM_VARIANT
    ADD COLUMN restaurant_id INT NOT NULL,
    ADD CONSTRAINT uq_variant_restaurant UNIQUE (variant_id, restaurant_id),
    ADD CONSTRAINT fk_variant_menu_restaurant
        FOREIGN KEY (menu_item_id, restaurant_id)
        REFERENCES MENU_ITEM(menu_item_id, restaurant_id) ON DELETE CASCADE;

ALTER TABLE ORDERS
    ADD CONSTRAINT uq_order_restaurant UNIQUE (order_id, restaurant_id);

ALTER TABLE ORDER_ITEM
    ADD COLUMN restaurant_id INT NOT NULL,
    ADD CONSTRAINT fk_order_item_order_restaurant
        FOREIGN KEY (order_id, restaurant_id)
        REFERENCES ORDERS(order_id, restaurant_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_order_item_variant_restaurant
        FOREIGN KEY (variant_id, restaurant_id)
        REFERENCES MENU_ITEM_VARIANT(variant_id, restaurant_id) ON DELETE RESTRICT;

CREATE INDEX idx_order_item_order ON ORDER_ITEM(order_id);
CREATE INDEX idx_order_item_variant ON ORDER_ITEM(variant_id);

-- Table: ORDER_ITEM_CUSTOMIZATION
CREATE TABLE ORDER_ITEM_CUSTOMIZATION (
    customization_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi tùy chọn.',
    order_item_id INT NOT NULL COMMENT 'Chi tiết đơn hàng chứa tùy chọn.',
    customization_name VARCHAR(100) NOT NULL COMMENT 'Tên tùy chọn (VD: Thêm phô mai, Ít đá).',

    -- Constraints
    CONSTRAINT pk_customization PRIMARY KEY (customization_id),
    CONSTRAINT fk_customization_item FOREIGN KEY (order_item_id)
        REFERENCES ORDER_ITEM(order_item_id) ON DELETE CASCADE
);

-- ===================================================================
-- 4. PHÂN HỆ VẬN CHUYỂN, VỊ TRÍ & LỊCH SỬ
-- ===================================================================

-- Table: DELIVERY_ASSIGNMENT
CREATE TABLE DELIVERY_ASSIGNMENT (
    assignment_id INT AUTO_INCREMENT COMMENT 'ID duy nhất cho giao dịch phân công.',
    order_id INT NOT NULL COMMENT 'Đơn hàng được phân công.',
    driver_id INT NOT NULL COMMENT 'Tài xế được phân công.',
    status VARCHAR(20) NOT NULL DEFAULT 'Assigned' COMMENT 'Trạng thái.',
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm hệ thống phân công.',
    accepted_at TIMESTAMP NULL COMMENT 'Thời điểm tài xế bấm xác nhận nhận đơn.',
    completed_at TIMESTAMP NULL COMMENT 'Thời điểm hoàn thành hoặc thất bại đơn.',
    failure_reason VARCHAR(255) NULL COMMENT 'Lý do nếu giao hàng thất bại.',

    -- Constraints
    CONSTRAINT pk_assignment PRIMARY KEY (assignment_id),
    CONSTRAINT chk_assignment_status CHECK (
        status IN ('Assigned', 'Accepted', 'Rejected', 'Completed', 'Failed', 'Cancelled')
    ),
    CONSTRAINT chk_assignment_failure CHECK (
        status <> 'Failed' OR NULLIF(TRIM(failure_reason), '') IS NOT NULL
    ),
    CONSTRAINT chk_assignment_accepted_time CHECK (
        status NOT IN ('Accepted', 'Completed', 'Failed') OR accepted_at IS NOT NULL
    ),
    CONSTRAINT chk_assignment_terminal_time CHECK (
        status NOT IN ('Rejected', 'Completed', 'Failed', 'Cancelled') OR completed_at IS NOT NULL
    ),
    CONSTRAINT fk_assignment_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_driver FOREIGN KEY (driver_id)
        REFERENCES DRIVER(driver_id) ON DELETE RESTRICT
);

-- Enforce at most one active assignment per order.
DELIMITER //
CREATE TRIGGER trg_assignment_one_active_insert
BEFORE INSERT ON DELIVERY_ASSIGNMENT
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Assigned', 'Accepted') AND EXISTS (
        SELECT 1 FROM DELIVERY_ASSIGNMENT
        WHERE order_id = NEW.order_id AND status IN ('Assigned', 'Accepted')
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order already has an active delivery assignment';
    END IF;
END //

CREATE TRIGGER trg_assignment_one_active_update
BEFORE UPDATE ON DELIVERY_ASSIGNMENT
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Assigned', 'Accepted') AND EXISTS (
        SELECT 1 FROM DELIVERY_ASSIGNMENT
        WHERE order_id = NEW.order_id
          AND assignment_id <> OLD.assignment_id
          AND status IN ('Assigned', 'Accepted')
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order already has an active delivery assignment';
    END IF;
END //
DELIMITER ;

CREATE INDEX idx_assignment_driver_status ON DELIVERY_ASSIGNMENT(driver_id, status);

-- Table: LOCATION
CREATE TABLE LOCATION (
    location_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi record vị trí.',
    driver_id INT NOT NULL COMMENT 'Tham chiếu tài xế.',
    latitude DECIMAL(9,6) NOT NULL COMMENT 'Tọa độ vĩ độ.',
    longitude DECIMAL(9,6) NOT NULL COMMENT 'Tọa độ kinh độ.',
    address_text VARCHAR(255) NULL COMMENT 'Địa chỉ đã được resolve.',
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm ghi nhận vị trí.',

    -- Constraints
    CONSTRAINT pk_location PRIMARY KEY (location_id),
    CONSTRAINT chk_location_lat CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_location_lng CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT fk_location_driver FOREIGN KEY (driver_id)
        REFERENCES DRIVER(driver_id) ON DELETE CASCADE
);

CREATE INDEX idx_driver_location ON LOCATION(driver_id, recorded_at);

-- Table: ORDER_STATUS_HISTORY
CREATE TABLE ORDER_STATUS_HISTORY (
    order_status_history_id INT AUTO_INCREMENT COMMENT 'ID duy nhất cho mỗi record lịch sử.',
    order_id INT NOT NULL COMMENT 'Tham chiếu đơn hàng.',
    status VARCHAR(50) NOT NULL COMMENT 'Trạng thái.',
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm trạng thái được cập nhật.',
    status_note VARCHAR(255) NULL COMMENT 'Ghi chú thêm cho trạng thái.',

    -- Constraints
    CONSTRAINT pk_status_history PRIMARY KEY (order_status_history_id),
    CONSTRAINT chk_status_history_status CHECK (
        status IN ('Pending', 'Preparing', 'Ready', 'On The Way', 'Delivered', 'Cancelled', 'Delivery Failed')
    ),
    CONSTRAINT fk_history_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE CASCADE
);


CREATE INDEX idx_status_history_order ON ORDER_STATUS_HISTORY(order_id, changed_at);
CREATE INDEX idx_status_history_latest ON ORDER_STATUS_HISTORY(order_id, changed_at DESC, order_status_history_id DESC);

-- ===================================================================
-- 5. PHÂN HỆ ĐÁNH GIÁ & TÍCH ĐIỂM
-- ===================================================================

-- Table: REVIEW
CREATE TABLE REVIEW (
    review_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho đánh giá.',
    order_id INT NOT NULL COMMENT 'Tham chiếu đơn hàng.',
    customer_id INT NOT NULL COMMENT 'Người đánh giá.',
    restaurant_id INT NOT NULL COMMENT 'Nhà hàng được đánh giá.',
    rating INT NOT NULL COMMENT 'Điểm đánh giá (từ 1 đến 5 sao).',
    comment TEXT NULL COMMENT 'Ý kiến nhận xét bằng chữ của khách hàng.',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời gian viết đánh giá.',

    -- Constraints
    CONSTRAINT pk_review PRIMARY KEY (review_id),
    CONSTRAINT uq_review_order UNIQUE (order_id),
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_review_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES RESTAURANT(restaurant_id) ON DELETE CASCADE
);

-- Review customer/restaurant must be the ones recorded on its order.
ALTER TABLE ORDERS
    ADD CONSTRAINT uq_order_review_identity UNIQUE (order_id, customer_id, restaurant_id);

ALTER TABLE REVIEW
    ADD CONSTRAINT fk_review_order_identity
        FOREIGN KEY (order_id, customer_id, restaurant_id)
        REFERENCES ORDERS(order_id, customer_id, restaurant_id) ON DELETE CASCADE;

DELIMITER //
CREATE TRIGGER trg_review_requires_delivered_order
BEFORE INSERT ON REVIEW
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ORDER_STATUS_HISTORY h
        WHERE h.order_id = NEW.order_id AND h.status = 'Delivered'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only delivered orders can be reviewed';
    END IF;
END //
DELIMITER ;

-- Table: LOYALTY_TRANSACTION
CREATE TABLE LOYALTY_TRANSACTION (
    loyalty_transaction_id INT AUTO_INCREMENT COMMENT 'Định danh duy nhất cho mỗi giao dịch điểm.',
    customer_id INT NOT NULL COMMENT 'Khách hàng thực hiện giao dịch.',
    order_id INT NULL COMMENT 'Đơn hàng phát sinh điểm (NULL nếu không gắn với đơn).',
    points INT NOT NULL COMMENT 'Số điểm thay đổi (dương khi EARN, âm khi REDEEM).',
    transaction_type VARCHAR(20) NOT NULL COMMENT 'Loại giao dịch: EARN hoặc REDEEM.',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời gian thực hiện giao dịch điểm.',

    -- Constraints
    CONSTRAINT pk_loyalty PRIMARY KEY (loyalty_transaction_id),
    CONSTRAINT uq_loyalty_order_type UNIQUE (order_id, transaction_type),
    CONSTRAINT chk_loyalty_type CHECK (transaction_type IN ('EARN', 'REDEEM')),
    CONSTRAINT chk_loyalty_points CHECK (
        (transaction_type = 'EARN' AND points > 0)
        OR (transaction_type = 'REDEEM' AND points < 0)
    ),
    CONSTRAINT chk_loyalty_nonzero CHECK (points <> 0),
    CONSTRAINT fk_loyalty_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_loyalty_order FOREIGN KEY (order_id)
        REFERENCES ORDERS(order_id) ON DELETE SET NULL
);

CREATE INDEX idx_loyalty_customer_created ON LOYALTY_TRANSACTION(customer_id, created_at);

-- Latest status is derived from the history table, as specified by the project.
CREATE OR REPLACE VIEW ORDER_CURRENT_STATUS AS
SELECT h.order_id, h.status, h.changed_at, h.status_note
FROM ORDER_STATUS_HISTORY AS h
WHERE NOT EXISTS (
    SELECT 1 FROM ORDER_STATUS_HISTORY AS newer
    WHERE newer.order_id = h.order_id
      AND (newer.changed_at > h.changed_at OR
           (newer.changed_at = h.changed_at AND newer.order_status_history_id > h.order_status_history_id))
);



-- tính tổng tiền đồ ăn
DROP PROCEDURE IF EXISTS CalculateOrderTotal;
DELIMITER //
CREATE PROCEDURE CalculateOrderTotal (
    IN p_order_id INT,
    OUT p_subtotal DECIMAL(10,2),
    OUT p_total_amount DECIMAL(10,2)
)
BEGIN
    SELECT COALESCE(SUM(unit_price * quantity), 0) INTO p_subtotal
    FROM ORDER_ITEM
    WHERE order_id = p_order_id;

    UPDATE ORDERS
    SET subtotal = p_subtotal,
        total_amount = p_subtotal + delivery_fee + tax
    WHERE order_id = p_order_id;

    SELECT total_amount INTO p_total_amount
    FROM ORDERS
    WHERE order_id = p_order_id;
END //
DELIMITER ;

-- cập nhật trạng thái của 1 đơn hàng
DROP PROCEDURE IF EXISTS UpdateOrderStatus;
DELIMITER //
CREATE PROCEDURE UpdateOrderStatus (
    IN p_order_id INT,
    IN p_new_status VARCHAR(50),
    IN p_note VARCHAR(255)
)
BEGIN
    DECLARE v_current_status VARCHAR(50) DEFAULT NULL;
    DECLARE v_locked_order_id INT DEFAULT NULL;

    SELECT order_id INTO v_locked_order_id
    FROM ORDERS
    WHERE order_id = p_order_id
    FOR UPDATE;

    IF v_locked_order_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order does not exist';
    END IF;

    SELECT status INTO v_current_status
    FROM ORDER_CURRENT_STATUS
    WHERE order_id = p_order_id;

    IF v_current_status IS NULL THEN
        IF p_new_status <> 'Pending' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A new order must start in Pending status';
        END IF;
    ELSEIF NOT (
        (v_current_status = 'Pending' AND p_new_status IN ('Preparing', 'Cancelled')) OR
        (v_current_status = 'Preparing' AND p_new_status IN ('Ready', 'Cancelled')) OR
        (v_current_status = 'Ready' AND p_new_status IN ('On The Way', 'Cancelled')) OR
        (v_current_status = 'On The Way' AND p_new_status IN ('Delivered', 'Delivery Failed')) OR
        (v_current_status = 'Delivery Failed' AND p_new_status IN ('On The Way', 'Cancelled'))
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid order status transition';
    END IF;

    INSERT INTO ORDER_STATUS_HISTORY (order_id, status, changed_at, status_note)
    VALUES (p_order_id, p_new_status, CURRENT_TIMESTAMP, p_note);
END //
DELIMITER ;

-- Call only after adding order items and initial status, in the same transaction.
DROP PROCEDURE IF EXISTS FinalizeOrder;
DELIMITER //
CREATE PROCEDURE FinalizeOrder(IN p_order_id INT)
BEGIN
    DECLARE v_item_count INT DEFAULT 0;
    DECLARE v_status_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_item_count FROM ORDER_ITEM WHERE order_id = p_order_id;
    SELECT COUNT(*) INTO v_status_count FROM ORDER_STATUS_HISTORY WHERE order_id = p_order_id;

    IF v_item_count < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An order requires at least one item';
    END IF;
    IF v_status_count < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An order requires an initial status history record';
    END IF;

    CALL CalculateOrderTotal(p_order_id, @order_subtotal, @order_total);
END //
DELIMITER ;

-- Tự động tính toán và cộng điểm thưởng
DROP PROCEDURE IF EXISTS ProcessLoyaltyPoints;
DELIMITER //
CREATE PROCEDURE ProcessLoyaltyPoints (
    IN p_order_id INT
)
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_total_amount DECIMAL(10,2);
    DECLARE v_points INT;

    SELECT customer_id, total_amount INTO v_customer_id, v_total_amount
    FROM ORDERS
    WHERE order_id = p_order_id;

    SET v_points = FLOOR(v_total_amount / 10000);

    IF v_points > 0 THEN
        INSERT INTO LOYALTY_TRANSACTION (customer_id, order_id, points, transaction_type, created_at)
        VALUES (v_customer_id, p_order_id, v_points, 'EARN', CURRENT_TIMESTAMP);
    END IF;
END //
DELIMITER ;

-- Trả về điểm đánh giá trung bình của một nhà hàng
DROP FUNCTION IF EXISTS GetAvgRating;
DELIMITER //
CREATE FUNCTION GetAvgRating (
    p_restaurant_id INT
)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_avg DECIMAL(3,2);

    SELECT ROUND(AVG(rating), 2)
    INTO   v_avg
    FROM   REVIEW
    WHERE  restaurant_id = p_restaurant_id;

    RETURN v_avg;  -- NULL nếu nhà hàng chưa có đánh giá nào
END //
DELIMITER ;

-- Trả về số điểm thưởng hiện có của một khách hàng
DROP FUNCTION IF EXISTS GetLoyaltyBalance;

DELIMITER //
CREATE FUNCTION GetLoyaltyBalance (
    p_customer_id INT
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_balance INT;

    SELECT COALESCE(SUM(points), 0)
    INTO   v_balance
    FROM   LOYALTY_TRANSACTION
    WHERE  customer_id = p_customer_id;

    -- Trả về 0 nếu khách hàng chưa có giao dịch điểm nào
    RETURN v_balance;
END //
DELIMITER ;


-- 1. CUSTOMER (12 khách hàng)
INSERT INTO CUSTOMER (customer_id, first_name, last_name, email, phone_number, password_hash, created_at) VALUES
    (1, 'An', 'Nguyễn', 'nguyenan.work@gmail.com', '0903214567', '01d021f0ba9b570b4184f95145d3941182276ff3e4bf856d68cd363766eef7a0', '2022-04-18 08:42:00'),
    (2, 'Bình', 'Trần', 'tranbinh.nguyen@gmail.com', '0917382641', '81f8d2bccd393b16f362ab46f24c2cd354b57409b34a05e3be62df66459cc97c', '2023-09-07 19:15:00'),
    (3, 'Chi', 'Lê', 'lechi.98@gmail.com', '0938451276', 'a7e5bee844f618ecc4b381a5acccc6ca9c8432a504de910def2d4749265e3445', '2021-12-22 11:36:00'),
    (4, 'Dũng', 'Phạm', 'pham.dung.hcm@gmail.com', '0987326514', '57adf123eaf9754bbf9bf506c27b16b912f935fabb345b9d204ff0cd6cde8df6', '2024-02-14 13:08:00'),
    (5, 'Giang', 'Hoàng', 'hoanggiang15@gmail.com', '0908573192', '2c1a2353346c47d68782c3b09d585366d43fc6ce8322c4daa07f3fada53d6f3f', '2025-06-03 20:27:00'),
    (6, 'Hà', 'Vũ', 'vuhai.minh@gmail.com', '0912648305', '9909fbcecca0c81037da794d139f52a70608b62d33ad785853d016d622853ea5', '2022-11-09 07:55:00'),
    (7, 'Khoa', 'Đặng', 'dangkhoa.sg@gmail.com', '0932715408', 'cefca135ee2863c31e3d5c49b4f7915c9ff36b918128ac51706ec6233960ad28', '2024-08-21 18:41:00'),
    (8, 'Linh', 'Bùi', 'builinh.22@gmail.com', '0974286531', 'a43e955c5773ef0a8feff99ae8cf42e88b58ac545e9e21a583258dfcf4f6745a', '2025-01-17 10:12:00'),
    (9, 'Minh', 'Đỗ', 'dominhquan10@gmail.com', '0906431725', '0400cb40e7e09deb7e51572fb8aeddd54c32ad4bba6aa9f8f08b61f30f64bef5', '2023-05-29 21:06:00'),
    (10, 'Nam', 'Ngô', 'nguyen.nam.hcm@gmail.com', '0918537264', '5e3a5d6bef15988a40f1bc1201d328ea1027b50b568ffdcc8b7e3b76caed87a9', '2026-03-11 09:33:00'),
    (11, 'Oanh', 'Phan', 'phanoanh.95@gmail.com', '0935802417', '320b33b9e19894297d207e325b2cffbd5da4aef46fe99d71f568320b32e9c6ef', '2021-10-04 16:24:00'),
    (12, 'Vy', 'Mai', 'maivy.nguyen@gmail.com', '0983614250', '66c0dedfa0f06d1e3972c48df7549d74479a7a2ad0a03474d43264a8f1353674', '2025-08-26 14:49:00');

-- 2. CUSTOMER_ADDRESS (12 địa chỉ khách hàng)
INSERT INTO CUSTOMER_ADDRESS (address_id, customer_id, address_text) VALUES
    (1, 1, '12 Nguyễn Trãi, phường Bến Thành, TP.HCM'),
    (2, 2, '45 Lê Văn Sỹ, phường Nhiêu Lộc, TP.HCM'),
    (3, 3, '88 Phan Văn Trị, phường Hạnh Thông, TP.HCM'),
    (4, 4, '21 Hoàng Diệu, phường Khánh Hội, TP.HCM'),
    (5, 5, '105 Cách Mạng Tháng Tám, phường Hòa Hưng, TP.HCM'),
    (6, 6, '37 Xô Viết Nghệ Tĩnh, phường Thạnh Mỹ Tây, TP.HCM'),
    (7, 7, '16 Nguyễn Oanh, phường Hạnh Thông, TP.HCM'),
    (8, 8, '72 Võ Văn Tần, phường Xuân Hòa, TP.HCM'),
    (9, 9, '54 Lý Thường Kiệt, phường Diên Hồng, TP.HCM'),
    (10, 10, '93 Nguyễn Hữu Cảnh, phường Thạnh Mỹ Tây, TP.HCM'),
    (11, 11, '28 Trần Hưng Đạo, phường Cầu Ông Lãnh, TP.HCM'),
    (12, 12, '61 Điện Biên Phủ, phường Thạnh Mỹ Tây, TP.HCM');

-- 3. DRIVER (6 tài xế)
INSERT INTO DRIVER (driver_id, first_name, last_name, phone_number, email, vehicle_type, license_number, created_at) VALUES
    (1, 'Hùng', 'Nguyễn', '0938124576', 'hung.nguyen.driver@gmail.com', 'Motorcycle', '59K1-483.72', '2021-07-16 09:18:00'),
    (2, 'Long', 'Trần', '0905842317', 'long.tran.driver@gmail.com', 'Motorcycle', '59M2-716.35', '2022-12-05 14:36:00'),
    (3, 'Phúc', 'Lê', '0973264185', 'phuc.le.driver@gmail.com', 'Motorcycle', '50N1-284.69', '2024-03-27 08:52:00'),
    (4, 'Tài', 'Phạm', '0917463528', 'tai.pham.driver@gmail.com', 'Motorcycle', '59L3-935.18', '2023-06-11 17:24:00'),
    (5, 'Sơn', 'Võ', '0985612734', 'son.vo.driver@gmail.com', 'Motorcycle', '51H2-407.63', '2025-02-19 10:07:00'),
    (6, 'Quân', 'Đặng', '0909361742', 'quan.dang.driver@gmail.com', 'Motorcycle', '59G1-852.46', '2026-01-08 15:43:00');

-- 4. RESTAURANT (4 nhà hàng)
INSERT INTO RESTAURANT (restaurant_id, name, phone_number, email) VALUES
    (1, 'Buffet sushi kunimoto', '02866500195', 'kunimotogroup@gmail.com'),
    (2, 'Mì cay SEOUL Đặng Văn Bi', '0833331185', 'contact@micayseoul.com'),
    (3, 'Lẩu gà lá é ớt xanh', '0984201620', 'otxanhquan@gmail.com'),
    (4, 'Quán chay thong dong', '0973195257', 'quanchaytd2804@gmail.com');

-- 5. MENU_ITEM (39 món ăn)
INSERT INTO MENU_ITEM (menu_item_id, restaurant_id, name, description, is_available) VALUES
    (1, 1, 'Udon cari gà', 'Mì udon sợi dày phục vụ cùng nước súp cà ri đậm đặc, ăn kèm thịt gà thái miếng, cà rốt, bông cải xanh và rong biển.', TRUE),
    (2, 1, 'Udon miso gà', 'Mì udon nước dùng miso thanh nhẹ, kèm thịt gà, nửa quả trứng luộc, chả cá Nhật (kamaboko), rong biển, hành lá và vụn tempura.', TRUE),
    (3, 1, 'Udon thịt heo cay', 'Mì udon nước với topping chính là thịt heo băm cay tơi xốp, kết hợp cùng trứng lòng đào (onsen tamago), chả cá Nhật, hành lá và rong biển.', TRUE),
    (4, 1, 'Udon trộn thịt heo cay', 'Mì udon khô trộn đều cùng thịt heo băm xào cay mặn, trứng lòng đào béo ngậy, dưa leo xắt sợi thanh mát, rong biển và hành lá.', TRUE),
    (5, 1, 'Udon trộn gà sốt mè', 'Mì udon khô thanh đạm với thịt gà xé thấm đẫm xốt mè rang, ăn kèm trứng lòng đào, dưa leo xắt sợi, hành lá và rong biển.', TRUE),
    (6, 1, 'Bánh xèo Nhật', 'Bánh xèo tròn kiểu Nhật với lớp vỏ ngoài áp chảo, phủ đẫm xốt mặn ngọt, sốt mayonnaise, rắc cá bào và gừng hồng xắt nhỏ.', TRUE),
    (7, 1, 'Bánh bạch tuộc', 'Phần gồm 4 viên bánh nướng hình cầu nhân bạch tuộc, rưới đẫm xốt takoyaki, mayonnaise và rắc vụn cá bào đặc trưng.', TRUE),
    (8, 1, 'Bạch tuộc baby chiên', 'Bạch tuộc nguyên con cỡ nhỏ được tẩm bột chiên giòn rụm, phục vụ kèm chanh tươi để tăng hương vị.', TRUE),
    (9, 1, 'Bánh xếp Nhật', 'Phần gồm 4 chiếc bánh xếp kiểu Nhật được áp chảo xém vàng một mặt, vỏ ngoài bóng bẩy, dùng kèm nước chấm xốt tương.', TRUE),
    (10, 2, 'Lẩu hải sản', 'Gồm tôm, bạch tuộc, mực, cá viên, và rau sống.', TRUE),
    (11, 2, 'Lẩu bò', 'Gồm thịt bò, xúc xích, chả cá, nấm kim châm, và rau sống.', TRUE),
    (12, 2, 'Lẩu thập cẩm', 'Sự kết hợp của hải sản (tôm, mực) và các loại thịt, chả cá, nấm kim châm, và rau sống.', TRUE),
    (13, 2, 'Rau lẩu thêm', NULL, TRUE),
    (14, 2, 'Mì lẩu thái bạch tuộc', 'Mì lẩu Thái chua cay ăn kèm với bạch tuộc.', TRUE),
    (15, 2, 'Mì lẩu thái bò Mỹ', 'Mì lẩu Thái chua cay ăn kèm với ba chỉ bò Mỹ.', TRUE),
    (16, 2, 'Mì lẩu thái hải sản', 'Mì lẩu Thái chua cay ăn kèm với tôm, mực, nghêu.', TRUE),
    (17, 2, 'Mì lẩu thái bò', 'Mì lẩu Thái chua cay ăn kèm với thịt bò.', TRUE),
    (18, 2, 'Mì lẩu thái bò Mỹ trứng', 'Mì lẩu Thái chua cay ăn kèm với ba chỉ bò Mỹ và trứng luộc.', TRUE),
    (19, 2, 'Mì kim chi bạch tuộc', 'Mì nấu cùng nước dùng kim chi cay nồng, ăn kèm bạch tuộc.', TRUE),
    (20, 2, 'Mì kim chi bò Mỹ', 'Mì nấu cùng nước dùng kim chi cay nồng, ăn kèm thịt bò.', TRUE),
    (21, 3, 'Chả ốc ống lam', 'Thịt ốc nhồi băm nhỏ trộn cùng giò sống, sả và gia vị, nhồi vào ống tre hoặc ống nứa (ống lam) rồi đem hấp hoặc nướng, giữ được độ ngọt và thơm mùi sả, tre tươi.', TRUE),
    (22, 3, 'Chân gà ủ thảo mộc', 'Chân gà luộc chín tới, ngâm ủ trong nước dùng pha chế từ các vị thuốc bắc và thảo mộc (hoa hồi, quế, kỷ tử...), thớ thịt dai giòn sần sật, ngấm gia vị đậm đà.', TRUE),
    (23, 3, 'Bánh tráng', 'Bánh tráng gạo rắc mè đen hoặc mè trắng, nướng than hoa giòn rụm, thường dùng để bẻ nhỏ ăn kèm với các món gỏi, nộm.', TRUE),
    (24, 3, 'Gỏi gà uyên ương', 'Gỏi thịt gà xé phay trộn mắm chua ngọt cùng hành tây, bắp cải, cà rốt và rau răm. Từ "uyên ương" thường ngụ ý cách bài trí đẹp mắt dành cho cặp đôi hoặc sự kết hợp song song của hai loại nguyên liệu, hai loại sốt.', TRUE),
    (25, 3, 'Gỏi gà sum họp', 'Khẩu phần gỏi gà xé phay trộn chua ngọt cỡ lớn, kết hợp đa dạng rau củ, hành phi, đậu phộng rang. Thiết kế đầy đặn dành cho các mâm tiệc nhiều người.', TRUE),
    (26, 3, 'Thịt trâu gác bếp', 'Đặc sản vùng Tây Bắc làm từ thăn hoặc bắp trâu tươi, ướp đẫm mắc khén, hạt dổi, tỏi, ớt rồi sấy khô bằng khói bếp. Thịt có màu nâu sậm, xé ra bên trong đỏ tươi, vị ngọt dai và cay nồng mùi khói.', TRUE),
    (27, 3, 'Thịt heo gác bếp', 'Thịt nạc heo nguyên tảng ướp gia vị núi rừng tương tự trâu gác bếp, sấy khô bằng nhiệt khói. Thớ thịt mềm hơn thịt trâu nhưng vẫn giữ được độ dai ngọt và hương khói đặc trưng.', TRUE),
    (28, 3, 'Lẩu gà lá é', 'Lẩu gà ta nấu cùng nấm, măng chua và lá é tươi. Nước lẩu có vị ngọt thanh của xương thịt, hòa quyện với hương vị the mát, cay nồng tinh dầu đặc trưng của lá é.', TRUE),
    (29, 3, 'Lẩu gà lá giang', 'Nước lẩu gà ta nấu cùng lá giang tươi vò nát, tạo ra vị chua thanh, dịu nhẹ tự nhiên không gắt, kết hợp hoàn hảo với vị cay của ớt và độ dai ngọt của thịt gà.', TRUE),
    (30, 4, 'Tàu hũ mật gừng', 'Tàu hũ (tào phớ) truyền thống mềm mịn, tan trong miệng, chan nước đường sệt nấu cùng gừng tươi xắt sợi mang vị ngọt thanh và ấm bụng.', TRUE),
    (31, 4, 'Tàu hũ trân châu đường đen', 'Tàu hũ non (pudding đậu nành) mát lạnh, béo ngậy ăn kèm trân châu dai dẻo được ướp đẫm trong xốt đường đen ngọt thơm.', TRUE),
    (32, 4, 'Bánh mì nấm', 'Ổ bánh mì nướng giòn rụm kẹp nhân nấm xào gia vị đậm đà, kết hợp cùng dưa leo, ngò rí, đồ chua và xốt tương đặc trưng.', TRUE),
    (33, 4, 'Mỳ quảng', 'Sợi mì Quảng bản to dẹt, dai mềm, dùng kèm nước lèo đậm đà chan xăm xắp, topping nấm, đậu hũ, rắc đậu phộng rang và bẻ bánh tráng nướng giòn.', TRUE),
    (34, 4, 'Hủ tiếu xào HongKong', 'Sợi hủ tiếu mềm xào áp chảo với nhiệt độ cao (dậy mùi wok hei), kết hợp nước tương xì dầu kiểu Hong Kong, nấm và rau cải ngọt.', TRUE),
    (35, 4, 'Pad Thái', 'Sợi hủ tiếu/phở xào chuẩn vị Thái Lan chua - ngọt - mặn hài hòa, xào cùng giá đỗ, hẹ, đậu hũ, rắc đậu phộng rang và dùng kèm chanh tươi.', TRUE),
    (36, 4, 'Đậu hũ chiên muối sả', 'Đậu hũ cắt miếng vuông chiên vàng giòn rụm bên ngoài, béo mềm bên trong, xóc đều cùng sả băm chiên giòn và muối ớt mặn cay.', TRUE),
    (37, 4, 'Trứng chiên nấm', 'Trứng đánh tan chiên vàng ươm, cuộn cùng các loại nấm tươi (nấm rơm, nấm đùi gà...) xào chín tới, mang lại vị béo ngậy và ngọt tự nhiên.', TRUE),
    (38, 4, 'Cơm chiên ngọc bích', 'Cơm chiên tơi xốp, hạt cơm áo màu xanh bắt mắt tự nhiên (từ lá dứa hoặc cải bó xôi), xào cùng nấm và các loại rau củ thái hạt lựu.', TRUE),
    (39, 4, 'Cơm chiên rong biển', 'Cơm chiên săn hạt tơi xốp, dậy mùi thơm xì dầu, trộn đều cùng rong biển sấy vụn giòn rụm, mang lại vị mặn mặn, umami đặc trưng.', TRUE);

-- 6. MENU_ITEM_VARIANT (55 biến thể món ăn)
INSERT INTO MENU_ITEM_VARIANT (variant_id, menu_item_id, restaurant_id, variant_name, price, is_available) VALUES
    (1, 1, 1, 'Tiêu chuẩn', 62000.00, TRUE),
    (2, 1, 1, 'Phần lớn', 76000.00, TRUE),
    (3, 2, 1, 'Tiêu chuẩn', 48000.00, TRUE),
    (4, 2, 1, 'Phần lớn', 62000.00, TRUE),
    (5, 3, 1, 'Tiêu chuẩn', 58000.00, TRUE),
    (6, 3, 1, 'Phần lớn', 72000.00, TRUE),
    (7, 4, 1, 'Tiêu chuẩn', 65000.00, TRUE),
    (8, 4, 1, 'Phần lớn', 79000.00, TRUE),
    (9, 5, 1, 'Tiêu chuẩn', 63000.00, TRUE),
    (10, 5, 1, 'Phần lớn', 77000.00, TRUE),
    (11, 6, 1, 'Tiêu chuẩn', 54000.00, TRUE),
    (12, 7, 1, 'Tiêu chuẩn', 33000.00, TRUE),
    (13, 8, 1, 'Tiêu chuẩn', 45000.00, TRUE),
    (14, 9, 1, 'Tiêu chuẩn', 290000.00, TRUE),
    (15, 9, 1, 'Phần lớn', 320000.00, TRUE),
    (16, 10, 2, 'Tiêu chuẩn', 270000.00, TRUE),
    (17, 10, 2, 'Phần lớn', 300000.00, TRUE),
    (18, 11, 2, 'Tiêu chuẩn', 350000.00, TRUE),
    (19, 11, 2, 'Phần lớn', 380000.00, TRUE),
    (20, 12, 2, 'Tiêu chuẩn', 40000.00, TRUE),
    (21, 13, 2, 'Tiêu chuẩn', 30000.00, TRUE),
    (22, 14, 2, 'Tiêu chuẩn', 35000.00, TRUE),
    (23, 15, 2, 'Tiêu chuẩn', 45000.00, TRUE),
    (24, 16, 2, 'Tiêu chuẩn', 22000.00, TRUE),
    (25, 17, 2, 'Tiêu chuẩn', 75000.00, TRUE),
    (26, 17, 2, 'Phần lớn', 89000.00, TRUE),
    (27, 18, 2, 'Tiêu chuẩn', 70000.00, TRUE),
    (28, 18, 2, 'Phần lớn', 84000.00, TRUE),
    (29, 19, 2, 'Tiêu chuẩn', 120000.00, TRUE),
    (30, 19, 2, 'Phần lớn', 150000.00, TRUE),
    (31, 20, 2, 'Tiêu chuẩn', 135000.00, TRUE),
    (32, 20, 2, 'Phần lớn', 165000.00, TRUE),
    (33, 21, 3, 'Tiêu chuẩn', 85000.00, TRUE),
    (34, 21, 3, 'Phần lớn', 99000.00, TRUE),
    (35, 22, 3, 'Tiêu chuẩn', 65000.00, TRUE),
    (36, 22, 3, 'Phần lớn', 79000.00, TRUE),
    (37, 23, 3, 'Tiêu chuẩn', 30000.00, TRUE),
    (38, 23, 3, 'Phần lớn', 44000.00, TRUE),
    (39, 24, 3, 'Tiêu chuẩn', 55000.00, TRUE),
    (40, 25, 3, 'Tiêu chuẩn', 115000.00, TRUE),
    (41, 25, 3, 'Phần lớn', 145000.00, TRUE),
    (42, 26, 3, 'Tiêu chuẩn', 80000.00, TRUE),
    (43, 26, 3, 'Phần lớn', 94000.00, TRUE),
    (44, 27, 3, 'Tiêu chuẩn', 110000.00, TRUE),
    (45, 27, 3, 'Phần lớn', 140000.00, TRUE),
    (46, 28, 3, 'Tiêu chuẩn', 95000.00, TRUE),
    (47, 28, 3, 'Phần lớn', 109000.00, TRUE),
    (48, 29, 3, 'Tiêu chuẩn', 90000.00, TRUE),
    (49, 29, 3, 'Phần lớn', 104000.00, TRUE),
    (50, 30, 4, 'Tiêu chuẩn', 88000.00, TRUE),
    (51, 30, 4, 'Phần lớn', 102000.00, TRUE),
    (52, 31, 4, 'Tiêu chuẩn', 45000.00, TRUE),
    (53, 31, 4, 'Phần lớn', 59000.00, TRUE),
    (54, 32, 4, 'Tiêu chuẩn', 42000.00, TRUE),
    (55, 32, 4, 'Phần lớn', 56000.00, TRUE);

-- 7. ORDERS (24 đơn hàng)
INSERT INTO ORDERS (order_id, customer_id, restaurant_id, order_time, subtotal, delivery_fee, tax, total_amount, delivery_address, special_instructions) VALUES
    (1, 1, 1, '2025-03-07 02:19:00', 698000.00, 12000.00, 55840.00, 765840.00, '12 Nguyễn Trãi, phường Bến Thành, TP.HCM', 'Giao tận tay'),
    (2, 1, 1, '2025-03-19 20:13:00', 209000.00, 15000.00, 16720.00, 240720.00, '12 Nguyễn Trãi, phường Bến Thành, TP.HCM', 'Gọi điện khi tới nơi'),
    (3, 2, 1, '2025-03-23 23:11:00', 243000.00, 18000.00, 19440.00, 280440.00, '45 Lê Văn Sỹ, phường Nhiêu Lộc, TP.HCM', NULL),
    (4, 2, 1, '2025-03-30 18:45:00', 54000.00, 0.00, 4320.00, 58320.00, '45 Lê Văn Sỹ, phường Nhiêu Lộc, TP.HCM', 'Để hàng ở quầy lễ tân'),
    (5, 3, 1, '2025-04-06 16:02:00', 66000.00, 10000.00, 5280.00, 81280.00, '88 Phan Văn Trị, phường Hạnh Thông, TP.HCM', 'Không gọi điện, nhắn tin khi đến'),
    (6, 3, 1, '2025-05-12 01:02:00', 197000.00, 15000.00, 15760.00, 227760.00, '88 Phan Văn Trị, phường Hạnh Thông, TP.HCM', NULL),
    (7, 4, 2, '2025-05-18 01:20:00', 380000.00, 12000.00, 30400.00, 422400.00, '21 Hoàng Diệu, phường Khánh Hội, TP.HCM', 'Giao tại sảnh chung cư'),
    (8, 4, 2, '2025-05-22 11:31:00', 700000.00, 18000.00, 56000.00, 774000.00, '21 Hoàng Diệu, phường Khánh Hội, TP.HCM', 'Giao cho bảo vệ'),
    (9, 5, 2, '2025-06-09 18:26:00', 80000.00, 15000.00, 6400.00, 101400.00, '105 Cách Mạng Tháng Tám, phường Hòa Hưng, TP.HCM', NULL),
    (10, 5, 2, '2025-07-16 17:12:00', 240000.00, 0.00, 19200.00, 259200.00, '105 Cách Mạng Tháng Tám, phường Hòa Hưng, TP.HCM', 'Kiểm tra đủ món trước khi rời đi'),
    (11, 6, 2, '2025-10-07 23:58:00', 330000.00, 10000.00, 26400.00, 366400.00, '37 Xô Viết Nghệ Tĩnh, phường Thạnh Mỹ Tây, TP.HCM', 'Gọi khách trước 5 phút'),
    (12, 6, 2, '2025-12-13 20:38:00', 334000.00, 12000.00, 26720.00, 372720.00, '37 Xô Viết Nghệ Tĩnh, phường Thạnh Mỹ Tây, TP.HCM', NULL),
    (13, 7, 3, '2026-01-22 20:48:00', 240000.00, 15000.00, 19200.00, 274200.00, '16 Nguyễn Oanh, phường Hạnh Thông, TP.HCM', 'Để tại bàn bảo vệ'),
    (14, 7, 2, '2026-02-24 13:22:00', 440000.00, 18000.00, 35200.00, 493200.00, '16 Nguyễn Oanh, phường Hạnh Thông, TP.HCM', 'Không cần liên hệ nếu khách không nghe máy'),
    (15, 8, 3, '2026-03-14 18:01:00', 285000.00, 15000.00, 22800.00, 322800.00, '72 Võ Văn Tần, phường Xuân Hòa, TP.HCM', NULL),
    (16, 8, 2, '2026-03-18 02:49:00', 765000.00, 12000.00, 61200.00, 838200.00, '72 Võ Văn Tần, phường Xuân Hòa, TP.HCM', 'Giao tận tay'),
    (17, 9, 3, '2026-03-19 10:44:00', 230000.00, 18000.00, 18400.00, 266400.00, '54 Lý Thường Kiệt, phường Diên Hồng, TP.HCM', 'Nhắn Zalo khi đến nơi'),
    (18, 9, 3, '2026-04-02 01:06:00', 220000.00, 10000.00, 17600.00, 247600.00, '54 Lý Thường Kiệt, phường Diên Hồng, TP.HCM', NULL),
    (19, 10, 4, '2026-04-11 21:31:00', 42000.00, 15000.00, 3360.00, 60360.00, '93 Nguyễn Hữu Cảnh, phường Thạnh Mỹ Tây, TP.HCM', 'Giao tại tầng trệt'),
    (20, 10, 4, '2026-04-30 13:17:00', 279000.00, 12000.00, 22320.00, 313320.00, '93 Nguyễn Hữu Cảnh, phường Thạnh Mỹ Tây, TP.HCM', 'Gọi trước khi giao'),
    (21, 11, 4, '2026-05-04 18:35:00', 206000.00, 18000.00, 16480.00, 240480.00, '28 Trần Hưng Đạo, phường Cầu Ông Lãnh, TP.HCM', NULL),
    (22, 11, 3, '2026-05-21 22:31:00', 347000.00, 10000.00, 27760.00, 384760.00, '28 Trần Hưng Đạo, phường Cầu Ông Lãnh, TP.HCM', 'Để tại lễ tân nếu khách vắng'),
    (23, 12, 4, '2026-08-11 19:20:00', 274000.00, 15000.00, 21920.00, 310920.00, '61 Điện Biên Phủ, phường Thạnh Mỹ Tây, TP.HCM', NULL),
    (24, 12, 4, '2026-08-27 14:22:00', 353000.00, 12000.00, 28240.00, 393240.00, '61 Điện Biên Phủ, phường Thạnh Mỹ Tây, TP.HCM', 'Giao tận tay');

-- 8. ORDER_NOTE (21 ghi chú đơn hàng)
INSERT INTO ORDER_NOTE (order_note_id, order_id, note_text, created_at) VALUES
    (1, 2, 'Ít đá', '2025-03-19 20:13:00'),
    (2, 3, 'Thêm nước mắm', '2025-03-23 23:11:00'),
    (3, 4, 'Không hành, ít cay', '2025-03-30 18:45:00'),
    (4, 5, 'Cho thêm rau', '2025-04-06 16:02:00'),
    (5, 6, 'Không lấy muỗng', '2025-05-12 01:02:00'),
    (6, 7, 'Ít ngọt', '2025-05-18 01:20:00'),
    (7, 8, 'Để riêng nước chấm', '2025-05-22 11:31:00'),
    (8, 9, 'Không lấy khăn giấy', '2025-06-09 18:26:00'),
    (9, 10, 'Cho sốt riêng', '2025-07-16 17:12:00'),
    (10, 11, 'Ít đá, ít ngọt', '2025-10-07 23:58:00'),
    (11, 12, 'Không hành lá', '2025-12-13 20:38:00'),
    (12, 13, 'Thêm tương ớt', '2026-01-22 20:48:00'),
    (13, 14, 'Không cần đũa', '2026-02-24 13:22:00'),
    (14, 15, 'Gọi trước khi giao', '2026-03-14 18:01:00'),
    (15, 16, 'Để phần ăn riêng', '2026-03-18 02:49:00'),
    (16, 18, 'Ít cay', '2026-04-02 01:06:00'),
    (17, 19, 'Cho thêm túi đựng', '2026-04-11 21:31:00'),
    (18, 20, 'Không lấy ống hút', '2026-04-30 13:17:00'),
    (19, 21, 'Thêm nước tương', '2026-05-04 18:35:00'),
    (20, 22, 'Ít sốt', '2026-05-21 22:31:00'),
    (21, 24, 'Để riêng topping', '2026-08-27 14:22:00');

-- 9. ORDER_ITEM (50 chi tiết đơn hàng)
INSERT INTO ORDER_ITEM (order_item_id, order_id, variant_id, restaurant_id, unit_price, quantity, notes) VALUES
    (1, 1, 5, 1, 58000.00, 1, 'Không hành'),
    (2, 1, 15, 1, 320000.00, 2, 'Gói riêng'),
    (3, 2, 7, 1, 65000.00, 2, NULL),
    (4, 2, 8, 1, 79000.00, 1, 'Ít cay'),
    (5, 3, 9, 1, 63000.00, 3, 'Để sốt riêng'),
    (6, 3, 11, 1, 54000.00, 1, NULL),
    (7, 4, 11, 1, 54000.00, 1, 'Ít cay'),
    (8, 5, 12, 1, 33000.00, 2, 'Không cần muỗng'),
    (9, 6, 13, 1, 45000.00, 3, 'Gói riêng'),
    (10, 6, 1, 1, 62000.00, 1, 'Không hành'),
    (11, 7, 16, 2, 270000.00, 1, 'Ít sốt'),
    (12, 7, 22, 2, 35000.00, 1, 'Để sốt riêng'),
    (13, 7, 25, 2, 75000.00, 1, 'Ít sốt'),
    (14, 8, 18, 2, 350000.00, 1, 'Để sốt riêng'),
    (15, 8, 16, 2, 270000.00, 1, NULL),
    (16, 8, 20, 2, 40000.00, 2, 'Ít cay'),
    (17, 9, 20, 2, 40000.00, 2, 'Ít cay'),
    (18, 10, 21, 2, 30000.00, 1, 'Để sốt riêng'),
    (19, 10, 23, 2, 45000.00, 2, 'Không cần muỗng'),
    (20, 10, 20, 2, 40000.00, 3, 'Để sốt riêng'),
    (21, 11, 22, 2, 35000.00, 3, 'Để sốt riêng'),
    (22, 11, 25, 2, 75000.00, 1, 'Thêm đũa'),
    (23, 11, 30, 2, 150000.00, 1, 'Không hành'),
    (24, 12, 23, 2, 45000.00, 2, 'Ít cay'),
    (25, 12, 24, 2, 22000.00, 3, NULL),
    (26, 12, 26, 2, 89000.00, 2, 'Ít sốt'),
    (27, 13, 35, 3, 65000.00, 2, 'Ít sốt'),
    (28, 13, 44, 3, 110000.00, 1, 'Để sốt riêng'),
    (29, 14, 27, 2, 70000.00, 2, 'Ít cay'),
    (30, 14, 30, 2, 150000.00, 2, 'Để sốt riêng'),
    (31, 15, 45, 3, 140000.00, 1, 'Thêm đũa'),
    (32, 15, 41, 3, 145000.00, 1, 'Không cần muỗng'),
    (33, 16, 31, 2, 135000.00, 2, NULL),
    (34, 16, 32, 2, 165000.00, 3, 'Ít sốt'),
    (35, 17, 33, 3, 85000.00, 1, 'Ít cay'),
    (36, 17, 41, 3, 145000.00, 1, 'Không hành'),
    (37, 18, 35, 3, 65000.00, 2, 'Không cần muỗng'),
    (38, 18, 37, 3, 30000.00, 3, 'Ít cay'),
    (39, 19, 54, 4, 42000.00, 1, 'Thêm đũa'),
    (40, 20, 51, 4, 102000.00, 1, 'Để sốt riêng'),
    (41, 20, 53, 4, 59000.00, 3, 'Ít cay'),
    (42, 21, 53, 4, 59000.00, 2, 'Không cần muỗng'),
    (43, 21, 50, 4, 88000.00, 1, 'Thêm đũa'),
    (44, 22, 44, 3, 110000.00, 1, 'Ít cay'),
    (45, 22, 36, 3, 79000.00, 3, 'Không cần muỗng'),
    (46, 23, 51, 4, 102000.00, 1, 'Không lấy khăn giấy'),
    (47, 23, 54, 4, 42000.00, 2, 'Không lấy khăn giấy'),
    (48, 23, 50, 4, 88000.00, 1, 'Ít sốt'),
    (49, 24, 53, 4, 59000.00, 3, 'Để sốt riêng'),
    (50, 24, 50, 4, 88000.00, 2, 'Ít sốt');

-- 10. ORDER_ITEM_CUSTOMIZATION (55 tùy chọn món ăn)
INSERT INTO ORDER_ITEM_CUSTOMIZATION (customization_id, order_item_id, customization_name) VALUES
    (1, 1, 'Thêm rau'),
    (2, 2, 'Ít cay'),
    (3, 3, 'Ít cay'),
    (4, 4, 'Không hành'),
    (5, 6, 'Thêm rau'),
    (6, 7, 'Thêm rau'),
    (7, 8, 'Sốt để riêng'),
    (8, 8, 'Không hành'),
    (9, 9, 'Ít cay'),
    (10, 10, 'Ít ngọt'),
    (11, 10, 'Thêm đá'),
    (12, 11, 'Ít đá'),
    (13, 13, 'Ít đá'),
    (14, 14, 'Thêm sốt'),
    (15, 16, 'Ít cay'),
    (16, 18, 'Thêm rau'),
    (17, 19, 'Thêm sốt'),
    (18, 20, 'Ít ngọt'),
    (19, 20, 'Thêm đá'),
    (20, 21, 'Thêm sốt'),
    (21, 22, 'Ít cay'),
    (22, 23, 'Thêm rau'),
    (23, 24, 'Ít ngọt'),
    (24, 24, 'Thêm đá'),
    (25, 25, 'Không hành'),
    (26, 26, 'Không hành'),
    (27, 27, 'Ít cay'),
    (28, 28, 'Thêm sốt'),
    (29, 29, 'Ít cay'),
    (30, 30, 'Thêm rau'),
    (31, 31, 'Ít cay'),
    (32, 32, 'Không hành'),
    (33, 33, 'Ít cay'),
    (34, 34, 'Thêm rau'),
    (35, 35, 'Không hành'),
    (36, 36, 'Sốt để riêng'),
    (37, 36, 'Không hành'),
    (38, 37, 'Không hành'),
    (39, 38, 'Ít cay'),
    (40, 39, 'Sốt để riêng'),
    (41, 39, 'Không hành'),
    (42, 40, 'Không hành'),
    (43, 41, 'Ít cay'),
    (44, 42, 'Ít ngọt'),
    (45, 42, 'Thêm đá'),
    (46, 43, 'Không hành'),
    (47, 44, 'Không hành'),
    (48, 45, 'Ít ngọt'),
    (49, 45, 'Thêm đá'),
    (50, 46, 'Không hành'),
    (51, 47, 'Ít cay'),
    (52, 48, 'Ít cay'),
    (53, 49, 'Sốt để riêng'),
    (54, 49, 'Không hành'),
    (55, 50, 'Thêm sốt');

-- 11. DELIVERY_ASSIGNMENT (22 lượt phân công giao hàng)
INSERT INTO DELIVERY_ASSIGNMENT (assignment_id, order_id, driver_id, status, assigned_at, accepted_at, completed_at, failure_reason) VALUES
    (1, 1, 1, 'Completed', '2025-03-07 02:28:00', '2025-03-07 02:33:00', '2025-03-07 03:09:00', NULL),
    (2, 2, 2, 'Completed', '2025-03-19 20:23:00', '2025-03-19 20:26:00', '2025-03-19 20:50:00', NULL),
    (3, 3, 3, 'Completed', '2025-03-23 23:19:00', '2025-03-23 23:23:00', '2025-03-23 23:46:00', NULL),
    (4, 5, 5, 'Completed', '2025-04-06 16:10:00', '2025-04-06 16:12:00', '2025-04-06 16:37:00', NULL),
    (5, 6, 6, 'Failed', '2025-05-12 01:12:00', '2025-05-12 01:16:00', '2025-05-12 01:51:00', 'Khách từ chối nhận đơn'),
    (6, 7, 1, 'Completed', '2025-05-18 01:24:00', '2025-05-18 01:27:00', '2025-05-18 01:57:00', NULL),
    (7, 8, 2, 'Completed', '2025-05-22 11:38:00', '2025-05-22 11:41:00', '2025-05-22 12:18:00', NULL),
    (8, 9, 3, 'Completed', '2025-06-09 18:30:00', '2025-06-09 18:34:00', '2025-06-09 18:54:00', NULL),
    (9, 11, 5, 'Completed', '2025-10-08 00:07:00', '2025-10-08 00:10:00', '2025-10-08 00:32:00', NULL),
    (10, 12, 6, 'Completed', '2025-12-13 20:46:00', '2025-12-13 20:51:00', '2025-12-13 21:12:00', NULL),
    (11, 13, 1, 'Completed', '2026-01-22 20:54:00', '2026-01-22 20:58:00', '2026-01-22 21:32:00', NULL),
    (12, 14, 2, 'Completed', '2026-02-24 13:30:00', '2026-02-24 13:33:00', '2026-02-24 13:59:00', NULL),
    (13, 15, 3, 'Failed', '2026-03-14 18:06:00', '2026-03-14 18:08:00', '2026-03-14 18:45:00', 'Khách báo món bị đổ trong quá trình vận chuyển'),
    (14, 16, 4, 'Completed', '2026-03-18 02:53:00', '2026-03-18 02:57:00', '2026-03-18 03:19:00', NULL),
    (15, 17, 5, 'Accepted', '2026-03-19 10:54:00', '2026-03-19 10:58:00', NULL, NULL),
    (16, 18, 6, 'Completed', '2026-04-02 01:12:00', '2026-04-02 01:17:00', '2026-04-02 01:48:00', NULL),
    (17, 19, 1, 'Failed', '2026-04-11 21:39:00', '2026-04-11 21:42:00', '2026-04-11 22:13:00', 'Tài xế không tìm thấy địa chỉ giao hàng'),
    (18, 20, 2, 'Completed', '2026-04-30 13:25:00', '2026-04-30 13:28:00', '2026-04-30 14:00:00', NULL),
    (19, 21, 3, 'Completed', '2026-05-04 18:42:00', '2026-05-04 18:44:00', '2026-05-04 19:08:00', NULL),
    (20, 22, 4, 'Assigned', '2026-05-21 22:36:00', NULL, NULL, NULL),
    (21, 23, 5, 'Completed', '2026-08-11 19:29:00', '2026-08-11 19:32:00', '2026-08-11 19:56:00', NULL),
    (22, 24, 6, 'Completed', '2026-08-27 14:27:00', '2026-08-27 14:32:00', '2026-08-27 14:55:00', NULL);

-- 12. LOCATION (6 bản ghi tọa độ GPS tài xế)
INSERT INTO LOCATION (location_id, driver_id, latitude, longitude, address_text, recorded_at) VALUES
    (1, 1, 10.773800, 106.701700, '86 Lê Thánh Tôn, phường Sài Gòn, TP.HCM', '2026-01-12 08:24:00'),
    (2, 2, 10.777000, 106.686000, '127 Trương Định, phường Xuân Hòa, TP.HCM', '2026-02-07 18:47:00'),
    (3, 3, 10.817200, 106.686600, '154 Phan Văn Trị, phường Hạnh Thông, TP.HCM', '2026-04-19 12:16:00'),
    (4, 4, 10.758900, 106.705400, '121 Nguyễn Du, phường Bến Thành, TP.HCM', '2026-06-02 21:35:00'),
    (5, 5, 10.776800, 106.703100, '68 Nguyễn Huệ, phường Sài Gòn, TP.HCM', '2026-08-14 16:09:00'),
    (6, 6, 10.776500, 106.705000, '48 Đồng Khởi, phường Sài Gòn, TP.HCM', '2026-09-09 10:52:00');

-- 13. ORDER_STATUS_HISTORY (112 bản ghi lịch sử trạng thái đơn hàng)
INSERT INTO ORDER_STATUS_HISTORY (order_status_history_id, order_id, status, changed_at, status_note) VALUES
    (1, 1, 'Pending', '2025-03-07 02:19:00', 'Khách tạo đơn'),
    (2, 1, 'Preparing', '2025-03-07 02:25:00', 'Nhà hàng xác nhận'),
    (3, 1, 'Ready', '2025-03-07 02:31:00', 'Nhà hàng đang chuẩn bị món'),
    (4, 1, 'On The Way', '2025-03-07 02:44:00', 'Tài xế đã nhận đơn'),
    (5, 1, 'Delivered', '2025-03-07 02:47:00', 'Giao thành công'),
    (6, 2, 'Pending', '2025-03-19 20:13:00', 'Khách tạo đơn'),
    (7, 2, 'Preparing', '2025-03-19 20:19:00', 'Nhà hàng xác nhận'),
    (8, 2, 'Ready', '2025-03-19 20:22:00', 'Nhà hàng đang chuẩn bị món'),
    (9, 2, 'On The Way', '2025-03-19 20:33:00', 'Tài xế đã nhận đơn'),
    (10, 2, 'Delivered', '2025-03-19 20:57:00', 'Giao thành công'),
    (11, 3, 'Pending', '2025-03-23 23:11:00', 'Khách tạo đơn'),
    (12, 3, 'Preparing', '2025-03-23 23:17:00', 'Nhà hàng xác nhận'),
    (13, 3, 'Ready', '2025-03-23 23:25:00', 'Nhà hàng đang chuẩn bị món'),
    (14, 3, 'On The Way', '2025-03-23 23:35:00', 'Tài xế đã nhận đơn'),
    (15, 3, 'Delivered', '2025-03-23 23:55:00', 'Giao thành công'),
    (16, 4, 'Pending', '2025-03-30 18:45:00', 'Khách tạo đơn'),
    (17, 4, 'Cancelled', '2025-03-30 18:50:00', 'Khách hủy do thời gian chờ lâu'),
    (18, 5, 'Pending', '2025-04-06 16:02:00', 'Khách tạo đơn'),
    (19, 5, 'Preparing', '2025-04-06 16:06:00', 'Nhà hàng xác nhận'),
    (20, 5, 'Ready', '2025-04-06 16:11:00', 'Nhà hàng đang chuẩn bị món'),
    (21, 5, 'On The Way', '2025-04-06 16:27:00', 'Tài xế đã nhận đơn'),
    (22, 5, 'Delivered', '2025-04-06 16:32:00', 'Giao thành công'),
    (23, 6, 'Pending', '2025-05-12 01:02:00', 'Khách tạo đơn'),
    (24, 6, 'Preparing', '2025-05-12 01:08:00', 'Nhà hàng xác nhận'),
    (25, 6, 'Ready', '2025-05-12 01:13:00', 'Nhà hàng đang chuẩn bị món'),
    (26, 6, 'On The Way', '2025-05-12 01:26:00', 'Tài xế đã nhận đơn'),
    (27, 6, 'Delivery Failed', '2025-05-12 01:35:00', 'Khách từ chối nhận đơn'),
    (28, 7, 'Pending', '2025-05-18 01:20:00', 'Khách tạo đơn'),
    (29, 7, 'Preparing', '2025-05-18 01:24:00', 'Nhà hàng xác nhận'),
    (30, 7, 'Ready', '2025-05-18 01:31:00', 'Nhà hàng đang chuẩn bị món'),
    (31, 7, 'On The Way', '2025-05-18 01:41:00', 'Tài xế đã nhận đơn'),
    (32, 7, 'Delivered', '2025-05-18 02:04:00', 'Đã bàn giao cho khách'),
    (33, 8, 'Pending', '2025-05-22 11:31:00', 'Khách tạo đơn'),
    (34, 8, 'Preparing', '2025-05-22 11:38:00', 'Nhà hàng xác nhận'),
    (35, 8, 'Ready', '2025-05-22 11:44:00', 'Nhà hàng đang chuẩn bị món'),
    (36, 8, 'On The Way', '2025-05-22 11:51:00', 'Tài xế đã nhận đơn'),
    (37, 8, 'Delivered', '2025-05-22 12:08:00', 'Khách đã nhận đơn'),
    (38, 9, 'Pending', '2025-06-09 18:26:00', 'Khách tạo đơn'),
    (39, 9, 'Preparing', '2025-06-09 18:32:00', 'Nhà hàng xác nhận'),
    (40, 9, 'Ready', '2025-06-09 18:35:00', 'Nhà hàng đang chuẩn bị món'),
    (41, 9, 'On The Way', '2025-06-09 18:47:00', 'Tài xế đã nhận đơn'),
    (42, 9, 'Delivered', '2025-06-09 19:02:00', 'Khách đã nhận đơn'),
    (43, 10, 'Pending', '2025-07-16 17:12:00', 'Khách tạo đơn'),
    (44, 10, 'Cancelled', '2025-07-16 17:21:00', 'Khách hủy vì thay đổi kế hoạch'),
    (45, 11, 'Pending', '2025-10-07 23:58:00', 'Khách tạo đơn'),
    (46, 11, 'Preparing', '2025-10-08 00:05:00', 'Nhà hàng xác nhận'),
    (47, 11, 'Ready', '2025-10-08 00:10:00', 'Nhà hàng đang chuẩn bị món'),
    (48, 11, 'On The Way', '2025-10-08 00:24:00', 'Tài xế đã nhận đơn'),
    (49, 11, 'Delivered', '2025-10-08 00:29:00', 'Giao thành công'),
    (50, 12, 'Pending', '2025-12-13 20:38:00', 'Khách tạo đơn'),
    (51, 12, 'Preparing', '2025-12-13 20:43:00', 'Nhà hàng xác nhận'),
    (52, 12, 'Ready', '2025-12-13 20:51:00', 'Nhà hàng đang chuẩn bị món'),
    (53, 12, 'On The Way', '2025-12-13 20:59:00', 'Tài xế đã nhận đơn'),
    (54, 12, 'Delivered', '2025-12-13 21:09:00', 'Khách đã nhận đơn'),
    (55, 13, 'Pending', '2026-01-22 20:48:00', 'Khách tạo đơn'),
    (56, 13, 'Preparing', '2026-01-22 20:52:00', 'Nhà hàng xác nhận'),
    (57, 13, 'Ready', '2026-01-22 21:02:00', 'Nhà hàng đang chuẩn bị món'),
    (58, 13, 'On The Way', '2026-01-22 21:11:00', 'Tài xế đã nhận đơn'),
    (59, 13, 'Delivered', '2026-01-22 21:28:00', 'Giao thành công'),
    (60, 14, 'Pending', '2026-02-24 13:22:00', 'Khách tạo đơn'),
    (61, 14, 'Preparing', '2026-02-24 13:27:00', 'Nhà hàng xác nhận'),
    (62, 14, 'Ready', '2026-02-24 13:33:00', 'Nhà hàng đang chuẩn bị món'),
    (63, 14, 'On The Way', '2026-02-24 13:45:00', 'Tài xế đã nhận đơn'),
    (64, 14, 'Delivered', '2026-02-24 13:57:00', 'Đã bàn giao cho khách'),
    (65, 15, 'Pending', '2026-03-14 18:01:00', 'Khách tạo đơn'),
    (66, 15, 'Preparing', '2026-03-14 18:06:00', 'Nhà hàng xác nhận'),
    (67, 15, 'Ready', '2026-03-14 18:11:00', 'Đang chuẩn bị món'),
    (68, 15, 'On The Way', '2026-03-14 18:21:00', 'Tài xế đang giao'),
    (69, 15, 'Delivered', '2026-03-14 18:35:00', 'Đã bàn giao cho khách'),
    (70, 15, 'Delivery Failed', '2026-03-14 18:43:00', 'Khách báo vấn đề và yêu cầu hoàn đơn'),
    (71, 16, 'Pending', '2026-03-18 02:49:00', 'Khách tạo đơn'),
    (72, 16, 'Preparing', '2026-03-18 02:53:00', 'Nhà hàng xác nhận'),
    (73, 16, 'Ready', '2026-03-18 03:02:00', 'Nhà hàng đang chuẩn bị món'),
    (74, 16, 'On The Way', '2026-03-18 03:15:00', 'Tài xế đã nhận đơn'),
    (75, 16, 'Delivered', '2026-03-18 03:20:00', 'Giao thành công'),
    (76, 17, 'Pending', '2026-03-19 10:44:00', 'Khách tạo đơn'),
    (77, 17, 'Preparing', '2026-03-19 10:49:00', 'Nhà hàng xác nhận'),
    (78, 17, 'Ready', '2026-03-19 10:55:00', 'Nhà hàng đang chuẩn bị món'),
    (79, 17, 'On The Way', '2026-03-19 11:05:00', 'Tài xế đang giao'),
    (80, 18, 'Pending', '2026-04-02 01:06:00', 'Khách tạo đơn'),
    (81, 18, 'Preparing', '2026-04-02 01:11:00', 'Nhà hàng xác nhận'),
    (82, 18, 'Ready', '2026-04-02 01:16:00', 'Nhà hàng đang chuẩn bị món'),
    (83, 18, 'On The Way', '2026-04-02 01:33:00', 'Tài xế đã nhận đơn'),
    (84, 18, 'Delivered', '2026-04-02 01:40:00', 'Giao thành công'),
    (85, 19, 'Pending', '2026-04-11 21:31:00', 'Khách tạo đơn'),
    (86, 19, 'Preparing', '2026-04-11 21:36:00', 'Nhà hàng xác nhận'),
    (87, 19, 'Ready', '2026-04-11 21:43:00', 'Nhà hàng đang chuẩn bị món'),
    (88, 19, 'On The Way', '2026-04-11 21:52:00', 'Tài xế đã nhận đơn'),
    (89, 19, 'Delivery Failed', '2026-04-11 22:15:00', 'Không liên lạc được với khách'),
    (90, 20, 'Pending', '2026-04-30 13:17:00', 'Khách tạo đơn'),
    (91, 20, 'Preparing', '2026-04-30 13:21:00', 'Nhà hàng xác nhận'),
    (92, 20, 'Ready', '2026-04-30 13:28:00', 'Nhà hàng đang chuẩn bị món'),
    (93, 20, 'On The Way', '2026-04-30 13:40:00', 'Tài xế đã nhận đơn'),
    (94, 20, 'Delivered', '2026-04-30 13:58:00', 'Đã bàn giao cho khách'),
    (95, 21, 'Pending', '2026-05-04 18:35:00', 'Khách tạo đơn'),
    (96, 21, 'Preparing', '2026-05-04 18:42:00', 'Nhà hàng xác nhận'),
    (97, 21, 'Ready', '2026-05-04 18:49:00', 'Nhà hàng đang chuẩn bị món'),
    (98, 21, 'On The Way', '2026-05-04 18:54:00', 'Tài xế đã nhận đơn'),
    (99, 21, 'Delivered', '2026-05-04 19:11:00', 'Khách đã nhận đơn'),
    (100, 22, 'Pending', '2026-05-21 22:31:00', 'Khách tạo đơn'),
    (101, 22, 'Preparing', '2026-05-21 22:35:00', 'Nhà hàng xác nhận'),
    (102, 22, 'Ready', '2026-05-21 22:41:00', 'Nhà hàng đang chuẩn bị món'),
    (103, 23, 'Pending', '2026-08-11 19:20:00', 'Khách tạo đơn'),
    (104, 23, 'Preparing', '2026-08-11 19:26:00', 'Nhà hàng xác nhận'),
    (105, 23, 'Ready', '2026-08-11 19:30:00', 'Nhà hàng đang chuẩn bị món'),
    (106, 23, 'On The Way', '2026-08-11 19:41:00', 'Tài xế đã nhận đơn'),
    (107, 23, 'Delivered', '2026-08-11 20:01:00', 'Đã bàn giao cho khách'),
    (108, 24, 'Pending', '2026-08-27 14:22:00', 'Khách tạo đơn'),
    (109, 24, 'Preparing', '2026-08-27 14:29:00', 'Nhà hàng xác nhận'),
    (110, 24, 'Ready', '2026-08-27 14:33:00', 'Nhà hàng đang chuẩn bị món'),
    (111, 24, 'On The Way', '2026-08-27 14:40:00', 'Tài xế đã nhận đơn'),
    (112, 24, 'Delivered', '2026-08-27 15:06:00', 'Đã bàn giao cho khách');

-- 14. REVIEW (12 đánh giá từ khách hàng)
INSERT INTO REVIEW (review_id, order_id, customer_id, restaurant_id, rating, comment, created_at) VALUES
    (1, 1, 1, 1, 5, 'Món ngon, giao nhanh.', '2026-09-06 18:01:00'),
    (2, 3, 2, 1, 5, 'Đóng gói cẩn thận.', '2026-09-06 18:02:00'),
    (3, 5, 3, 1, 5, 'Hương vị vừa miệng.', '2026-09-06 18:03:00'),
    (4, 7, 4, 2, 4, 'Sẽ đặt lại.', '2026-09-06 18:04:00'),
    (5, 9, 5, 2, 5, 'Món ngon, giao nhanh.', '2026-09-06 18:05:00'),
    (6, 11, 6, 2, 5, 'Đóng gói cẩn thận.', '2026-09-06 18:06:00'),
    (7, 13, 7, 3, 5, 'Hương vị vừa miệng.', '2026-09-06 18:07:00'),
    (8, 15, 8, 3, 4, 'Sẽ đặt lại.', '2026-09-06 18:08:00'),
    (9, 18, 9, 3, 5, 'Món ngon, giao nhanh.', '2026-09-06 18:09:00'),
    (10, 20, 10, 4, 5, 'Đóng gói cẩn thận.', '2026-09-06 18:10:00'),
    (11, 21, 11, 4, 5, 'Hương vị vừa miệng.', '2026-09-06 18:11:00'),
    (12, 23, 12, 4, 4, 'Sẽ đặt lại.', '2026-09-06 18:12:00');

-- 15. LOYALTY_TRANSACTION (24 giao dịch điểm thưởng)
INSERT INTO LOYALTY_TRANSACTION (loyalty_transaction_id, customer_id, order_id, points, transaction_type, created_at) VALUES
    (1, 1, 2, -30, 'REDEEM', '2025-04-03 23:13:00'),
    (2, 1, NULL, 30, 'EARN', '2025-04-09 00:13:00'),
    (3, 2, NULL, 20, 'EARN', '2025-03-30 21:08:00'),
    (4, 2, 3, 30, 'EARN', '2025-03-24 01:58:00'),
    (5, 3, 5, 10, 'EARN', '2025-04-06 18:34:00'),
    (6, 3, NULL, 20, 'EARN', '2025-05-14 03:02:00'),
    (7, 4, 8, 10, 'EARN', '2025-05-22 14:40:00'),
    (8, 4, 7, 10, 'EARN', '2025-05-18 01:55:00'),
    (9, 5, NULL, 20, 'EARN', '2025-07-04 21:26:00'),
    (10, 5, 9, -20, 'REDEEM', '2025-06-28 00:26:00'),
    (11, 6, 12, 10, 'EARN', '2025-12-13 23:37:00'),
    (12, 6, 11, 30, 'EARN', '2025-10-08 03:38:00'),
    (13, 7, NULL, 10, 'EARN', '2026-02-16 23:48:00'),
    (14, 7, 13, 10, 'EARN', '2026-02-24 16:58:00'),
    (15, 8, NULL, 30, 'EARN', '2026-03-28 21:01:00'),
    (16, 8, NULL, 10, 'EARN', '2026-03-27 21:01:00'),
    (17, 9, NULL, 20, 'EARN', '2026-03-29 15:44:00'),
    (18, 9, 18, 10, 'EARN', '2026-03-19 12:35:00'),
    (19, 10, 20, -20, 'REDEEM', '2026-04-16 03:31:00'),
    (20, 10, NULL, 20, 'EARN', '2026-05-01 22:31:00'),
    (21, 11, NULL, 50, 'EARN', '2021-10-04 18:52:00'),
    (22, 11, 21, 20, 'EARN', '2026-05-22 00:52:00'),
    (23, 12, NULL, 50, 'EARN', '2025-08-26 15:21:00'),
    (24, 12, 24, -30, 'REDEEM', '2026-08-28 21:22:00');

-- Query 1: Tìm khách hàng VIP có tổng chi tiêu (đơn đã giao) cao hơn mức trung bình toàn hệ thống
-- Kỹ thuật: INNER JOIN, Aggregation, HAVING kết hợp Subquery không tương quan
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(o.order_id) AS delivered_order_count,
    SUM(o.total_amount) AS total_spent
FROM CUSTOMER AS c
INNER JOIN ORDERS AS o
    ON o.customer_id = c.customer_id
INNER JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = o.order_id
WHERE ocs.status = 'Delivered'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email
HAVING SUM(o.total_amount) > (
    SELECT AVG(customer_spending.total_paid)
    FROM (
        SELECT
            o2.customer_id,
            SUM(o2.total_amount) AS total_paid
        FROM ORDERS AS o2
        INNER JOIN ORDER_CURRENT_STATUS AS ocs2
            ON ocs2.order_id = o2.order_id
        WHERE ocs2.status = 'Delivered'
        GROUP BY o2.customer_id
    ) AS customer_spending
)
ORDER BY
    total_spent DESC;

-- Query 2: Top 5 biến thể món ăn bán chạy nhất và tỷ trọng (%) trên tổng số lượng món đã bán
-- Kỹ thuật: Multi-table INNER JOIN, Aggregation, Scalar Subquery trong SELECT
SELECT
    r.name AS restaurant_name,
    mi.name AS menu_item_name,
    v.variant_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) AS gross_item_revenue,
    ROUND(
        SUM(oi.quantity) * 100.0 / (
            SELECT SUM(oi2.quantity)
            FROM ORDER_ITEM AS oi2
            INNER JOIN ORDER_CURRENT_STATUS AS ocs2
                ON ocs2.order_id = oi2.order_id
            WHERE ocs2.status = 'Delivered'
        ),
        2
    ) AS quantity_share_pct
FROM ORDER_ITEM AS oi
INNER JOIN ORDERS AS o
    ON o.order_id = oi.order_id
INNER JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = o.order_id
INNER JOIN MENU_ITEM_VARIANT AS v
    ON v.variant_id = oi.variant_id
INNER JOIN MENU_ITEM AS mi
    ON mi.menu_item_id = v.menu_item_id
INNER JOIN RESTAURANT AS r
    ON r.restaurant_id = mi.restaurant_id
WHERE ocs.status = 'Delivered'
GROUP BY
    r.restaurant_id,
    r.name,
    mi.menu_item_id,
    mi.name,
    v.variant_id,
    v.variant_name
ORDER BY
    total_quantity_sold DESC,
    gross_item_revenue DESC
LIMIT 5;

-- Query 3: Đánh giá hiệu suất giao hàng và thời gian hoàn thành trung bình của từng tài xế
-- Kỹ thuật: LEFT JOIN, Conditional Aggregation (CASE WHEN), TIMESTAMPDIFF
SELECT
    d.driver_id,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    d.vehicle_type,
    COUNT(da.assignment_id) AS total_assignments,
    SUM(CASE WHEN da.status = 'Completed' THEN 1 ELSE 0 END) AS completed_deliveries,
    SUM(CASE WHEN da.status = 'Failed' THEN 1 ELSE 0 END) AS failed_deliveries,
    SUM(CASE WHEN da.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_assignments,
    ROUND(
        SUM(CASE WHEN da.status = 'Completed' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(da.assignment_id), 0),
        2
    ) AS completion_rate_pct,
    ROUND(
        AVG(
            CASE
                WHEN da.status = 'Completed'
                    THEN TIMESTAMPDIFF(MINUTE, da.accepted_at, da.completed_at)
                ELSE NULL
            END
        ),
        1
    ) AS avg_delivery_minutes
FROM DRIVER AS d
LEFT JOIN DELIVERY_ASSIGNMENT AS da
    ON da.driver_id = d.driver_id
GROUP BY
    d.driver_id,
    d.first_name,
    d.last_name,
    d.vehicle_type
ORDER BY
    completed_deliveries DESC,
    completion_rate_pct DESC;

-- Query 4: Tìm khách có ít nhất 2 đơn giao thành công, trong đó có đơn chưa được đánh giá
-- Kỹ thuật: LEFT JOIN, Conditional Aggregation, GROUP BY, HAVING
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.phone_number,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    COUNT(DISTINCT CASE WHEN rv.review_id IS NULL THEN o.order_id END) AS delivered_orders_without_review,
    SUM(o.total_amount) AS total_spent
FROM CUSTOMER AS c
INNER JOIN ORDERS AS o
    ON o.customer_id = c.customer_id
INNER JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = o.order_id
LEFT JOIN REVIEW AS rv
    ON rv.order_id = o.order_id
WHERE ocs.status = 'Delivered'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone_number
HAVING COUNT(DISTINCT o.order_id) >= 2
   AND COUNT(DISTINCT CASE WHEN rv.review_id IS NULL THEN o.order_id END) > 0
ORDER BY
    completed_orders DESC,
    c.customer_id;

-- Query 5: Tìm món ăn (biến thể) có mức giá cao nhất trong thực đơn của từng nhà hàng
-- Kỹ thuật: INNER JOIN kết hợp Correlated Subquery (truy vấn con tương quan)
SELECT
    r.restaurant_id,
    r.name AS restaurant_name,
    mi.name AS menu_item_name,
    v.variant_name,
    v.price AS highest_price
FROM RESTAURANT AS r
INNER JOIN MENU_ITEM AS mi
    ON mi.restaurant_id = r.restaurant_id
INNER JOIN MENU_ITEM_VARIANT AS v
    ON v.menu_item_id = mi.menu_item_id
WHERE v.price = (
    SELECT MAX(v2.price)
    FROM MENU_ITEM_VARIANT AS v2
    INNER JOIN MENU_ITEM AS mi2
        ON mi2.menu_item_id = v2.menu_item_id
    WHERE mi2.restaurant_id = r.restaurant_id
)
ORDER BY
    v.price DESC,
    r.name ASC;

-- Query 6: Xếp hạng Top 3 món ăn bán chạy nhất trong nội bộ từng nhà hàng
-- Kỹ thuật: Common Table Expression (CTE), Window Function (DENSE_RANK), JOIN
WITH restaurant_item_sales AS (
    SELECT
        r.restaurant_id,
        r.name AS restaurant_name,
        mi.menu_item_id,
        mi.name AS menu_item_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.unit_price) AS item_revenue,
        DENSE_RANK() OVER (
            PARTITION BY r.restaurant_id
            ORDER BY SUM(oi.quantity) DESC, SUM(oi.quantity * oi.unit_price) DESC
        ) AS rank_in_restaurant
    FROM RESTAURANT AS r
    INNER JOIN ORDERS AS o
        ON o.restaurant_id = r.restaurant_id
    INNER JOIN ORDER_CURRENT_STATUS AS ocs
        ON ocs.order_id = o.order_id
    INNER JOIN ORDER_ITEM AS oi
        ON oi.order_id = o.order_id
    INNER JOIN MENU_ITEM_VARIANT AS v
        ON v.variant_id = oi.variant_id
    INNER JOIN MENU_ITEM AS mi
        ON mi.menu_item_id = v.menu_item_id
    WHERE ocs.status = 'Delivered'
    GROUP BY
        r.restaurant_id,
        r.name,
        mi.menu_item_id,
        mi.name
)
SELECT
    restaurant_name,
    rank_in_restaurant,
    menu_item_name,
    total_units_sold,
    item_revenue
FROM restaurant_item_sales
WHERE rank_in_restaurant <= 3
ORDER BY
    restaurant_name ASC,
    rank_in_restaurant ASC;

-- Query 7: Đối soát lịch sử tích điểm (EARN), đổi điểm (REDEEM) và số dư điểm của khách hàng
-- Kỹ thuật: INNER JOIN, Conditional Aggregation, gọi Stored Function GetLoyaltyBalance
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(lt.loyalty_transaction_id) AS total_transactions,
    SUM(CASE WHEN lt.transaction_type = 'EARN' THEN lt.points ELSE 0 END) AS total_earned_points,
    SUM(CASE WHEN lt.transaction_type = 'REDEEM' THEN ABS(lt.points) ELSE 0 END) AS total_redeemed_points,
    GetLoyaltyBalance(c.customer_id) AS current_point_balance
FROM CUSTOMER AS c
INNER JOIN LOYALTY_TRANSACTION AS lt
    ON lt.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    current_point_balance DESC;

-- Query 8: Phân tích khung giờ cao điểm đặt hàng trong ngày và tỷ trọng doanh thu
-- Kỹ thuật: Date/Time Extraction (HOUR), Aggregation, Scalar Subquery
SELECT
    HOUR(o.order_time) AS order_hour,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS hourly_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_hourly_order_value,
    ROUND(
        COUNT(o.order_id) * 100.0 / (SELECT COUNT(*) FROM ORDERS),
        2
    ) AS order_volume_pct
FROM ORDERS AS o
GROUP BY
    HOUR(o.order_time)
ORDER BY
    total_orders DESC,
    order_hour ASC;

-- Query 9: Liệt kê biến thể có giá cao hơn giá trung bình và số lượng đã giao thành công
-- Kỹ thuật: Multi-table JOIN, Subquery đơn giản, Aggregation (SUM + GROUP BY)
SELECT
    r.name AS restaurant_name,
    mi.name AS menu_item_name,
    v.variant_name,
    v.price,
    COALESCE(SUM(CASE WHEN ocs.status = 'Delivered' THEN oi.quantity ELSE 0 END), 0) AS delivered_quantity
FROM MENU_ITEM_VARIANT AS v
INNER JOIN MENU_ITEM AS mi
    ON mi.menu_item_id = v.menu_item_id
INNER JOIN RESTAURANT AS r
    ON r.restaurant_id = mi.restaurant_id
LEFT JOIN ORDER_ITEM AS oi
    ON oi.variant_id = v.variant_id
LEFT JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = oi.order_id
WHERE v.price > (
    SELECT AVG(price)
    FROM MENU_ITEM_VARIANT
)
GROUP BY
    r.name,
    mi.name,
    v.variant_id,
    v.variant_name,
    v.price
ORDER BY
    v.price DESC,
    delivered_quantity DESC;



-- Query 10: Thống kê doanh thu giao thành công theo nhà hàng
-- Kỹ thuật: INNER JOIN, Conditional Aggregation, GROUP BY
SELECT
    r.restaurant_id,
    r.name AS restaurant_name,
    COUNT(DISTINCT CASE WHEN ocs.status = 'Delivered' THEN o.order_id END) AS delivered_order_count,
    COALESCE(SUM(CASE WHEN ocs.status = 'Delivered' THEN o.total_amount ELSE 0 END), 0) AS delivered_revenue,
    ROUND(AVG(CASE WHEN ocs.status = 'Delivered' THEN o.total_amount END), 2) AS average_delivered_order_value
FROM RESTAURANT AS r
LEFT JOIN ORDERS AS o
    ON o.restaurant_id = r.restaurant_id
LEFT JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = o.order_id
GROUP BY
    r.restaurant_id,
    r.name
ORDER BY
    delivered_revenue DESC;

-- Query 11: Rà soát các đơn hiện giao thất bại và lượt phân công thất bại đã ghi nhận
-- Kỹ thuật: JOIN, Aggregation, Conditional Aggregation
-- Bộ dữ liệu hiện có ba đơn giao thất bại; chưa có lịch sử điều phối lại.
SELECT
    o.order_id,
    o.order_time,
    ocs.status AS current_order_status,
    COUNT(da.assignment_id) AS assignment_attempts,
    SUM(CASE WHEN da.status IN ('Failed', 'Rejected') THEN 1 ELSE 0 END) AS failed_or_rejected_attempts,
    GROUP_CONCAT(
        CONCAT('DA', LPAD(da.assignment_id, 3, '0'), ': ', da.status,
               CASE WHEN da.failure_reason IS NOT NULL THEN CONCAT(' (', da.failure_reason, ')') ELSE '' END)
        ORDER BY da.assigned_at SEPARATOR '; '
    ) AS assignment_history
FROM ORDERS AS o
INNER JOIN DELIVERY_ASSIGNMENT AS da
    ON da.order_id = o.order_id
INNER JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = o.order_id
WHERE ocs.status = 'Delivery Failed'
GROUP BY
    o.order_id,
    o.order_time,
    ocs.status
HAVING SUM(CASE WHEN da.status IN ('Failed', 'Rejected') THEN 1 ELSE 0 END) > 0
ORDER BY
    o.order_time,
    o.order_id;

-- Query 12: Đối soát tổng phụ của đơn với tổng tiền chi tiết món
-- Kỹ thuật: LEFT JOIN, Aggregation, HAVING
-- Kết quả rỗng nghĩa là các subtotal đang khớp với ORDER_ITEM.
SELECT
    o.order_id,
    o.subtotal AS recorded_subtotal,
    COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS calculated_subtotal,
    o.subtotal - COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS difference
FROM ORDERS AS o
LEFT JOIN ORDER_ITEM AS oi
    ON oi.order_id = o.order_id
GROUP BY
    o.order_id,
    o.subtotal
HAVING o.subtotal <> COALESCE(SUM(oi.unit_price * oi.quantity), 0)
ORDER BY o.order_id;

-- Query 13: Xem tiến trình trạng thái mới nhất của từng đơn
-- Kỹ thuật: View, JOIN, ORDER BY
SELECT
    o.order_id,
    o.order_time,
    ocs.status AS current_status,
    ocs.changed_at AS status_changed_at,
    ocs.status_note
FROM ORDERS AS o
LEFT JOIN ORDER_CURRENT_STATUS AS ocs
    ON ocs.order_id = o.order_id
ORDER BY
    o.order_time DESC,
    o.order_id DESC;
