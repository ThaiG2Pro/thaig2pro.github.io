Trong dự án cá nhân đang làm, mình đã chuyển từ cách truyền thống mà hầu hết sinh viên thường dùng (auto-increment integer 1234.. , hay UUIDv4 ngẫu nhiên ) sang UUIDv7 – một thay đổi nhỏ nhưng mang lại cải thiện rõ rệt về hiệu suất.
UUIDv7 là gì ? (Hiểu một cách đơn giản
Hãy tưởng tượng bạn đang xây dựng một ứng dụng giống Shopee. Mỗi khi có một đơn hàng mới, hệ thống cần cấp cho nó một IDđể không nhầm lẫn với hàng tỷ thứ khác.￼
1.Cách Integer : 1, 2, 3, 4...
- Ưu điểm: Rất nhanh, máy tính cực thích sắp xếp số.
- Nhược điểm: Dễ bị lộ bí mật. Nếu link đơn hàng của bạn là http://shopee.vn/order/100, mình chỉ cần sửa thành 101 là có thể xem trộm đơn hàng của người khác.

2. Cách UUIDv4. Giống như một chuỗi loằng ngoằng: f47ac10b-58cc-4372-a567..
Ưu điểm: Bảo mật cực tốt. Ko đoán đc.
Nhược điểm: lộn xộn. Khi lưu hàng triệu đơn, máy tính phải tốn rất nhiều sức để sắp xếp đống mã ngẫu nhiên này vào bộ nhớ, làm hệ thống bị chậm.￼
Cấu trúc của một mã UUIDv7 sẽ trông như thế này:
[Thời gian hiện tại] + [Một chút ngẫu nhiên]
- Tại sao nó nhanh như số? Vì phần đầu là "Thời gian", nên cái nào tạo sau sẽ luôn có số lớn hơn cái tạo trước. Máy tính chỉ việc xếp chúng nối đuôi nhau, cực kỳ mượt mà.
- Tại sao nó bảo mật? Vì phần đuôi vẫn là các ký tự ngẫu nhiên, người ngoài không thể nhìn ID này mà đoán được ID tiếp theo là gì.￼
Hầu hết các Database (như MySQL, PostgreSQL) lưu trữ dữ liệu theo cấu trúc hình cây gọi là B-Tree.
- Dữ liệu được sắp xếp theo thứ tự (từ nhỏ đến lớn).
- Khi bạn chèn một dòng mới, Database sẽ tìm đúng vị trí của nó để nhét vào.
=> UUIDv7 giúp giảm B-Tree fragmentation đáng kể so với uuidv4.
Tất nhiên , uuidv7 vẫn còn hạn chế, các bạn tìm hiểu thêm nhé.￼

Uuidv7 được chuẩn hóa chính thức trong RFC 9562 (tháng 5/2024).
-  PostgreSQL 18 hỗ trợ native hàm uuidv7(), cho phép generate trực tiếp trong database mà không cần extension.
-  Nhiều ngôn ngữ và framework (Java, Go, Python, Swift, Rust…) đã có thư viện ổn định, thậm chí một số dự án lớn (như Buildkite, Bindbee) mặc định dùng UUIDv7 cho bảng mới.
-  Adoption tiếp tục tăng mạnh trong distributed systems nhờ cân bằng giữa tính phân tán, hiệu suất database và sắp xếp thời gian.￼
