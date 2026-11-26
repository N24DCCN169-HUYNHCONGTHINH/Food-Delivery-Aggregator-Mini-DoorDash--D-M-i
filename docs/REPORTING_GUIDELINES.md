# Quy tắc tạo và chỉnh sửa báo cáo dự án

## Căn cứ

Các quy tắc này được ghi lại theo yêu cầu của người dùng sau khi đối chiếu:

- `docs/Dì Mười_Phase1.pdf`
- `docs/Dì Mười_Phase 2 .pdf`
- `C:/Users/Maxsys/Downloads/Project Report template (2).docx`

Khi các tài liệu nguồn có điểm khác nhau, áp dụng yêu cầu mới nhất của người dùng trước, cấu trúc của template tiếp theo, rồi dùng hai báo cáo gốc làm chuẩn về cách trình bày thực tế. Không coi văn bản hướng dẫn, ví dụ điền mẫu hoặc nội dung placeholder trong template là nội dung dự án.

## Trình bày

- Dùng Times New Roman cho toàn bộ nội dung, chữ màu đen.
- Giữ hệ phân cấp cỡ chữ và cách nhấn mạnh đơn giản như các báo cáo gốc: tiêu đề chính khoảng 18 pt, tiêu đề mục khoảng 13 pt, thân bài khoảng 12 pt. Chỉ dùng cỡ nhỏ hơn trong bảng khi cần để giữ bảng dễ đọc và phù hợp mật độ của tài liệu gốc.
- Giữ cách căn lề, giãn dòng, thụt dòng, dấu đầu dòng, định dạng bảng và khoảng cách theo báo cáo gốc phù hợp với phase đang thực hiện. Không tự thêm hoặc bỏ gạch đầu dòng, đường kẻ ngang, đường phân cách, màu trang trí, kiểu nhấn mạnh hoặc cấu trúc trang.
- Không in đậm tùy tiện. Chỉ giữ chữ đậm ở tiêu đề, nhãn hoặc vị trí mà template và báo cáo gốc dùng để phân cấp rõ ràng.
- Không tự đổi khổ giấy khi sửa một báo cáo hiện có. Báo cáo Phase 1 gốc là Letter, còn báo cáo Phase 2 gốc là A4; kiểm tra đúng bản đang làm trước khi lưu.
- Dùng tiêu đề báo cáo và phần nhận dạng dự án theo mẫu hiện có của nhóm. Giữ tiếng Việt bên ngoài và thuật ngữ tiếng Anh trong ngoặc khi cần chú giải.

## Cấu trúc và phạm vi theo phase

- Tuân thủ cấu trúc template theo thứ tự mục: 1. Introduction & Project Scope; 2. Database Design; 3. Data Dictionary; 4. Database Implementation; 5. Verification & Security, cùng các mục con tương ứng khi nội dung thuộc phạm vi báo cáo. Dùng tiêu đề tiếng Việt theo cách nhóm đã thể hiện trong báo cáo gốc và giữ số thứ tự theo template.
- Chỉ đưa vào báo cáo các phần thuộc phase được yêu cầu. Không thêm mục đánh số mới ngoài template nếu chưa được người dùng yêu cầu.
- Mỗi báo cáo phase là phần tiếp nối tiến độ dự án. Chỉ nhắc lại các thông tin nhận dạng ngắn gọn nếu mẫu yêu cầu; không sao chép lại phần thuyết minh, yêu cầu, quy tắc nghiệp vụ, mô hình, từ điển dữ liệu hoặc dữ liệu mẫu của phase trước nếu chúng không cần thiết để giải thích kết quả của phase hiện tại.
- Khi kết quả hiện tại phụ thuộc một quyết định từ phase trước, ghi chú ngắn hoặc dẫn chiếu rõ tới phase/tài liệu nguồn; không chép lại toàn bộ nội dung cũ.
- Giữ tên thực thể/bảng nhất quán với EER và SQL của dự án; tên thực thể/bảng viết hoa theo quy ước hiện có. Tên cột và câu lệnh dùng đúng chữ hoa/thường, dấu gạch dưới và tên trong SQL nguồn.
- Không tự tạo dữ kiện hoặc khẳng định kết quả kiểm thử chưa được xác nhận. Có thể chỉnh câu chữ cho rõ nghĩa nhưng không làm thay đổi nội dung kỹ thuật đã được nhóm xác nhận.

## Lưu file và kiểm tra

- Lưu báo cáo và tài liệu dự án trong thư mục dự án, ưu tiên `docs/`.
- Khi sửa một báo cáo đã có, giữ nguyên bản gốc và tạo tên phiên bản tiếp theo theo quy ước `v1`, `v2`, `v3` đã được người dùng yêu cầu; không ghi đè bản duy nhất.
- Trước khi bàn giao DOCX, kết xuất thành PDF hoặc ảnh để kiểm tra trực quan toàn bộ trang: font, màu chữ, cỡ chữ, thứ tự mục, bảng, gạch đầu dòng, khoảng trắng, lỗi tràn trang và tính nhất quán với bản gốc/template. Sửa lỗi trình bày quan sát được trước khi gửi.
