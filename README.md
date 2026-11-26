# Mini DoorDash — Food Delivery Aggregator

Ứng dụng web mô phỏng nền tảng đặt và giao đồ ăn. Dự án phát triển từ mô hình cơ sở dữ liệu Phase 1, dùng MySQL cho dữ liệu Phase 3 và Flask để cung cấp các luồng thao tác Phase 4. Phạm vi tập trung vào việc đặt món, bàn giao đơn giữa nhà hàng và tài xế, theo dõi trạng thái giao hàng và xử lý các lượt giao.

> Đây là ứng dụng học tập chạy cục bộ. Dự án chưa có cấu hình triển khai lên máy chủ công khai, cổng thanh toán thật hoặc thông báo trạng thái thời gian thực.

## Thông tin dự án

| Mục | Thông tin |
| --- | --- |
| Tên đội | Dì Mười |
| Tên dự án | Hệ thống nền tảng tổng hợp dịch vụ giao đồ ăn — Mini-DoorDash |
| Môn học | INT1313 — Cơ Sở Dữ Liệu |
| Lớp/Mã đề tài  | D24CQCN02-N / 7 |
| Repository | [GitHub — Food-Delivery-Aggregator-Mini-DoorDash--D-M-i](https://github.com/N24DCCN169-HUYNHCONGTHINH/Food-Delivery-Aggregator-Mini-DoorDash--D-M-i) |
| Cơ sở dữ liệu | MySQL 8.0.16 trở lên |
| Backend | Python, Flask |
| Giao diện | Jinja templates, HTML, CSS, JavaScript |

### Thành viên

| Mã sinh viên | Họ và tên | Email trường |
| --- | --- | --- |
| N24DCCN169 | Huỳnh Công Thịnh | [n24dccn169@student.ptithcm.edu.vn](mailto:n24dccn169@student.ptithcm.edu.vn) |
| N24DCCN140 | Hà Đình Mạnh | [n24dccn140@student.ptithcm.edu.vn](mailto:n24dccn140@student.ptithcm.edu.vn) |
| N24DCCN134 | Lý Trọng Khôi | [n24dccn134@student.ptithcm.edu.vn](mailto:n24dccn134@student.ptithcm.edu.vn) |

**Giảng viên phụ trách:** | Lê Hà Thanh | [lethanh@ptithcm.edu.vn](mailto:lethanh@ptithcm.edu.vn)|

## Chức năng hiện có

- **Khách hàng:** đăng ký, đăng nhập, quản lý hồ sơ và địa chỉ; tìm nhà hàng/món, xem thực đơn, đặt đơn, theo dõi trạng thái, xác nhận đã nhận hàng, đánh giá và xem điểm thành viên.
- **Nhà hàng:** xem đơn mới, cập nhật các trạng thái ở khâu chuẩn bị, thêm/sửa/ẩn món và cập nhật giá các phiên bản món.
- **Tài xế:** xem các lượt giao được phân công, nhận/từ chối lượt, cập nhật tiến trình giao, ghi nhận vị trí và xác nhận kết quả giao.
- **Quản trị viên/điều phối:** quản lý nhà hàng và tài khoản đối tác, tìm kiếm dữ liệu, phân công tài xế, theo dõi vị trí và lịch sử các lượt giao.
- **Tìm kiếm:** thanh tìm kiếm dùng chung cho nhà hàng, món ăn và dữ liệu đơn phù hợp với quyền của tài khoản; trang quản trị và điều phối có bộ lọc riêng.

Các vai trò được giới hạn theo tài khoản đăng nhập. Dữ liệu nhà hàng, tài xế và đơn mẫu được nạp từ SQL; một số thao tác như phân công tài xế, đổi trạng thái và cập nhật menu được thực hiện qua giao diện web.

## Công nghệ và cấu trúc thư mục

```text
├── app.py                         # Flask routes, phân quyền và truy vấn MySQL
├── requirements.txt               # Python dependencies
├── .env.example                   # Mẫu các biến cấu hình kết nối
├── Phase 3 v3.sql                 # Schema, dữ liệu mẫu, truy vấn kiểm tra và RBAC
├── docs/
│   ├── 01_Problem_Statement.md
│   ├── 02_Business_Rules.md
│   ├── 03_ERD.png
│   ├── Dì Mười_Phase1.pdf
│   └── Dì Mười_Phase 2_v9.pdf
├── scripts/
│   ├── create_admin.py             # Tạo tài khoản quản trị web
│   ├── set_all_demo_passwords.py   # Đặt mật khẩu dùng thử cục bộ
│   └── export_google_password_import.py # Xuất CSV cho trình quản lý mật khẩu
├── static/
│   ├── style.css                   # Kiểu dùng chung
│   ├── storefront.css              # Trang khám phá và thực đơn
│   └── delivery.css                # Các trang vận hành giao hàng
└── templates/                      # Giao diện Jinja cho từng vai trò
```

## Yêu cầu cài đặt

- Windows 10/11, PowerShell và VS Code (các lệnh dưới đây dành cho PowerShell).
- Python 3.10 trở lên và `pip`.
- MySQL Server 8.0.16 trở lên và MySQL Workbench.
- Git nếu cần clone repository hoặc cộng tác qua GitHub.

## Cài đặt và chạy trên máy cá nhân

### 1. Lấy mã nguồn

```powershell
git clone https://github.com/N24DCCN169-HUYNHCONGTHINH/Food-Delivery-Aggregator-Mini-DoorDash--D-M-i.git
cd Food-Delivery-Aggregator-Mini-DoorDash--D-M-i
```

Nếu đã clone repository trước đó, mở đúng thư mục dự án trong VS Code và dùng GitHub Desktop **Fetch origin → Pull origin** để lấy commit mới.

### 2. Cài dependencies

Mở Terminal PowerShell trong VS Code tại thư mục dự án:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Nếu PowerShell chặn kích hoạt môi trường ảo, có thể chạy trực tiếp bằng đường dẫn Python trong `.venv` hoặc điều chỉnh Execution Policy theo chính sách máy tính của bạn.

### 3. Tạo database và dữ liệu mẫu

1. Mở MySQL Workbench và kết nối MySQL bằng tài khoản có quyền DBA, bao gồm quyền tạo database, role và user.
2. Mở file `Phase 3 v3.sql` trong Workbench.
3. Chọn đúng encoding UTF-8 rồi chạy toàn bộ script.

> **Cảnh báo:** `Phase 3 v3.sql` có lệnh `DROP DATABASE` và tạo lại `food_delivery_phase3_workbench`. Chạy file sẽ xóa dữ liệu cũ trong schema này. Sao lưu trước nếu database đang có dữ liệu cần giữ. Phần tạo role/user ở cuối file cần tài khoản có quyền DBA.

### 4. Cấu hình kết nối MySQL

`app.py` đọc cấu hình từ biến môi trường; dự án hiện không tự đọc file `.env`. Trong cùng cửa sổ PowerShell sẽ chạy web, đặt các biến sau và thay mật khẩu MySQL bằng mật khẩu của bạn:

```powershell
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_NAME = "food_delivery_phase3_workbench"
$env:DB_USER = "root"
$env:DB_PASSWORD = "mat-khau-MySQL-cua-ban"
$env:FLASK_SECRET_KEY = "chuoi-bi-mat-ngau-nhien-danh-cho-may-local"
$env:APP_HOST = "127.0.0.1"
$env:APP_PORT = "5000"
```

Không commit mật khẩu database, khóa bí mật hoặc file chứa thông tin đăng nhập lên GitHub. `.env.example` chỉ là mẫu tham khảo, không được Flask nạp tự động.

### 5. Tạo tài khoản quản trị web

Sau khi chạy SQL và cấu hình kết nối, tạo tài khoản quản trị đầu tiên:

```powershell
python scripts/create_admin.py
```

Nhập email quản trị và mật khẩu dài ít nhất 12 ký tự theo lời nhắc của chương trình.

### 6. Khởi động ứng dụng

```powershell
python app.py
```

Mở các địa chỉ sau trong trình duyệt:

- Web: <http://127.0.0.1:5000/>
- Kiểm tra kết nối database: <http://127.0.0.1:5000/health>
- Đăng nhập: <http://127.0.0.1:5000/account/login>

Health check thành công trả về JSON có `"status":"ok"` và `"database":"connected"`. Nhấn `Ctrl+C` trong Terminal để dừng Flask.

## Tài khoản và dữ liệu demo

- Khách hàng có thể đăng ký qua giao diện web.
- Quản trị viên có thể cấp tài khoản đăng nhập cho nhà hàng và tài xế trong trang quản trị.
- Để đặt lại mật khẩu dùng thử cho tất cả khách hàng, nhà hàng và tài xế trong database local, chạy `python scripts/set_all_demo_passwords.py`. Script hỏi mật khẩu qua terminal, lưu hash vào MySQL và **thay mật khẩu của toàn bộ các tài khoản thuộc phạm vi script**. Chỉ dùng trên database thử nghiệm.
- `python scripts/export_google_password_import.py` tạo CSV có mật khẩu dạng văn bản thuần để nhập vào Google Password Manager. Không đưa CSV lên GitHub; xóa file CSV sau khi nhập.
- Tài khoản demo DB `md_demo_*` trong phần RBAC của SQL được tạo ở trạng thái khóa. Chúng phục vụ minh họa quyền MySQL và khác với tài khoản đăng nhập web trong `PHASE4_ACCOUNT`.

## Tài liệu và báo cáo

- [Problem Statement](docs/01_Problem_Statement.md)
- [Business Rules](docs/02_Business_Rules.md)
- [ERD Phase 1](docs/03_ERD.png)
- [Báo cáo Phase 1](docs/D%C3%AC%20M%C6%B0%E1%BB%9Di_Phase1.pdf)
- [Tài liệu Phase 2](docs/D%C3%AC%20M%C6%B0%E1%BB%9Di_Phase%202_v9.pdf)
- [SQL Phase 3 v3 và phần hỗ trợ Phase 4](Phase%203%20v3.sql)

Theo hướng dẫn môn học, báo cáo chi tiết PDF được nộp riêng cho giảng viên; repository hiện có tài liệu PDF Phase 1 và Phase 2 như liệt kê ở trên.

## Cộng tác qua GitHub

1. Mỗi thành viên clone repository và tạo nhánh riêng cho phần việc của mình.
2. Trước khi bắt đầu, cập nhật `main` bằng **Fetch origin → Pull origin**.
3. Commit phần việc trên nhánh cá nhân, sau đó tạo Pull Request để nhóm xem xét và gộp vào `main`.
4. Trao đổi trước nếu nhiều thành viên cùng sửa một file, đặc biệt là `app.py` hoặc `templates/base.html`.
5. Database MySQL local không được đồng bộ chỉ bằng Git. Mỗi thành viên cần chạy SQL trên máy mình và cấu hình biến môi trường riêng.

## Phạm vi triển khai

- Flask hiện chạy bằng development server tại máy local (`127.0.0.1:5000`). Chưa có cấu hình production, domain, HTTPS, Docker hoặc pipeline triển khai tự động.
- Thanh toán là luồng mô phỏng; chưa kết nối cổng thanh toán.
- Trạng thái được lưu trong MySQL và hiển thị khi tải lại trang; chưa có WebSocket/push realtime.
- Không dùng chung một database production với dữ liệu demo. Sao lưu trước khi chạy script SQL có thao tác xóa/tạo lại schema.
