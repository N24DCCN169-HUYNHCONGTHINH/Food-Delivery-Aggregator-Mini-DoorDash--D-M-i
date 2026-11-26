# Phase 4: Thiết lập đăng nhập và phân quyền

Tài liệu này bổ sung tài khoản nhà hàng, tài xế, quản trị viên và xác nhận khách đã nhận món. Các bảng Phase 1/3 không bị thay đổi; `Phase 3.sql` được giữ nguyên. Chạy sau khi đã cài database Phase 3.

## 1. Chọn cách cài SQL

**Tạo database mới từ bộ Phase 3 đã sửa:** mở `Phase 3 + Phase 4 tích hợp.sql` trong MySQL Workbench và chạy toàn bộ file. File đã gồm các bảng Phase 3, dữ liệu mẫu mở rộng và bổ sung Phase 4 (`RESTAURANT.is_active`, `PHASE4_ACCOUNT`, `CUSTOMER_ORDER_RECEIPT`).

**Nâng cấp database Phase 3 đang có và giữ dữ liệu:** chỉ chạy `phase4_access.sql` trên schema `food_delivery_phase3_workbench`.

`Phase 3 + Phase 4 tích hợp.sql` bắt đầu bằng `DROP DATABASE IF EXISTS food_delivery_phase3_workbench`; chạy nó sẽ xóa rồi tạo lại database đó. Không dùng file tích hợp trên database đang cần giữ dữ liệu. `phase4_access.sql` là migration bổ sung, có thể chạy lại an toàn.

## 2. Cấu hình kết nối trong VS Code

Mở thư mục dự án trong VS Code và mở Terminal → New Terminal (PowerShell). Nếu chưa có môi trường Python, chạy:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Đặt biến môi trường theo thông tin MySQL cục bộ:

```powershell
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_NAME = "food_delivery_phase3_workbench"
$env:DB_USER = "root"
$env:DB_PASSWORD = "MẬT_KHẨU_MYSQL_CỦA_BẠN"
$env:FLASK_SECRET_KEY = "thay-bang-chuoi-ngau-nhien-dai"
```

## 3. Tạo admin đầu tiên và khởi động web

Chạy trong terminal VS Code:

```powershell
python scripts/create_admin.py
python app.py
```

Nhập email admin và mật khẩu ít nhất 12 ký tự khi được hỏi. Mở `http://127.0.0.1:5000/account/login` để đăng nhập. Không có mật khẩu admin mặc định được lưu trong source code.

## 4. Cấp tài khoản cho nhà hàng và tài xế

- Nhà hàng đã có trong database Phase 3: admin mở **Quản trị** → cấp tài khoản nhà hàng. Email đăng nhập và mật khẩu do admin nhập.
- Thêm đối tác nhà hàng mới: admin nhập tên, điện thoại, email và mật khẩu ban đầu ở cùng trang.
- Tài xế: tài xế cần có hồ sơ trong bảng `DRIVER`; admin cấp mật khẩu tại **Quản trị**. Email đăng nhập lấy từ email hồ sơ tài xế.
- Khách hàng tự tạo tài khoản ở **Tạo tài khoản khách**.

Sau đó mỗi người đăng nhập ở cùng một trang. Hệ thống chuyển tới giao diện phù hợp với vai trò.

## 5. Quyền thao tác

- Khách hàng: xem nhà hàng/món, đặt đơn, xem đơn của mình, theo dõi trạng thái, xác nhận đã nhận sau khi tài xế báo `Delivered`, quản lý hồ sơ/địa chỉ và xem điểm Phase 3.
- Nhà hàng: chỉ xem đơn của mình, chuyển `Pending → Preparing → Ready`, thêm/sửa/ẩn món, sửa giá và phân loại.
- Tài xế: chỉ xem và cập nhật các lượt phân công cho mình; nhận/từ chối chuyến, bắt đầu giao, lưu vị trí, báo giao thành công/thất bại.
- Admin: quản lý trạng thái nhà hàng, cấp/khóa tài khoản nhà hàng và tài xế, phân công tài xế và theo dõi luồng giao.

Khi tạm ngưng nhà hàng, trang khách không hiển thị nhà hàng đó và tài khoản nhà hàng bị khóa. Bật lại nhà hàng sẽ mở lại tài khoản quản lý liên kết.
