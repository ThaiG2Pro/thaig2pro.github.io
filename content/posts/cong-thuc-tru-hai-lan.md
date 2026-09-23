---
title: "Công thức trong ticket trừ hai lần, và chỉ hai ảnh chụp cùng một phút mới bác được nó"
date: 2026-09-23T14:00:00+07:00
draft: false
description: "Tiêu chí chấp nhận định nghĩa tồn khả dụng là tổng nhập trừ đã phân bổ trừ đã bán. Đọc theo nghĩa đen ra 80; màn hình production hiện 90. Sai số đúng bằng phần bị trừ hai lần."
tags: ["backend", "requirements", "data-integrity", "inventory", "testing"]
categories: ["Kỹ thuật"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/cong-thuc-tru-hai-lan/cover.png"
    alt: "Thanh 200 đơn vị chia thành 110 đã phân bổ và 90 kho tổng, 10 đơn vị đã bán từ quota tô đỏ bên trong khối 110, và hai phép trừ bên dưới: đọc nghĩa đen ra 80, màn hình production ra 90"
---

Một mã hàng. Tổng nhập kho 200 đơn vị. Ba chương trình khuyến mãi được cấp quota lần lượt 10, 88 và 12, và đã bán ra từ quota đó 1, 9 và 0. Còn bao nhiêu đơn vị khả dụng để bán?

Ticket viết: **tồn khả dụng = tổng nhập − tổng đã phân bổ − tổng đã bán.** Thay số vào thì ra 200 − 110 − 10 = 80. Màn hình production của đúng mã hàng đó, cùng thời điểm, hiện 90.

Mười đơn vị trên một mã hàng 200 không phải sai số làm tròn. Đó là khoảng cách giữa "chương trình còn bán được" và "hệ thống báo hết hàng". Mà câu này sắp trở thành tiêu chí chấp nhận (acceptance criterion) cho một tính năng mới: cho phép chương trình bán thẳng từ kho tổng dùng chung, không cần quota riêng. Mọi đơn theo chế độ mới sẽ bị kiểm tra bằng đúng công thức này. Công thức thiếu 10 thì chế độ mới từ chối 10 đơn lẽ ra bán được. Có ai "sửa" theo hướng ngược lại thì bán vượt kho.

Nếu câu đó được cài y nguyên, chương trình bị từ chối sẽ chịu thiệt trước, rồi đến người lập trình đứng nhìn màn hình hiện một con số khác spec.

---

## Mổ xẻ: cùng một lượng hàng nằm trong hai trong ba số hạng

Bộ số ở trên là bộ số thật của sự cố, chỉ bỏ tên mã hàng. Nó nằm sẵn trong tài liệu đề xuất; phép trừ chỉ cần có người ngồi xuống làm, thay vì tin câu chữ.

"Tổng đã phân bổ" là tổng quota của mọi chương trình: 10 + 88 + 12 = 110. "Tổng đã bán" là tổng những gì các chương trình đó đã bán: 1 + 9 + 0 = 10. Cách đọc nghĩa đen trừ cả hai.

Nhưng quota là một lời hứa về số hàng, và bán ra từ quota không tạo thêm một yêu cầu mới lên kho. 9 đơn vị chương trình hai đã bán vốn nằm trong 88 của nó rồi. Trừ 110 là đã lấy 9 đơn vị đó ra khỏi kho; trừ thêm 10 là lấy ra lần thứ hai. Số 80 sinh ra từ đó, và vì thế sai số đúng bằng 10: **cách đọc nghĩa đen luôn sai đúng bằng lượng đã bán ra từ các quota.** Trong bench dẫn ở dưới, đồng nhất thức này giữ trên 10.000 bộ số ngẫu nhiên, không có ngoại lệ nào.

![Thanh 200 đơn vị, 10 đơn vị đã bán nằm bên trong khối 110 đã phân bổ, và hai phép trừ](/images/posts/cong-thuc-tru-hai-lan/cover.png)
*Hình 1: 10 đơn vị đã bán từ quota vốn nằm trong 110 đã phân bổ. Cách đọc nghĩa đen trừ chúng thêm một lần nữa.*

Vậy người viết câu đó muốn nói cách đọc nào? Một câu chữ không trả lời được. Thứ chốt được là hai ảnh chụp hai màn hình khác nhau của cùng mã hàng, trong cùng một phút. Phải cùng một phút, vì chỉ cần một đơn bán lọt vào giữa hai lần chụp thì số nhảy, và bằng chứng thành trùng hợp. Chuyện này không phải giả định: một ảnh thứ ba của cùng mã hàng, chụp mười bốn phút sau, đã hiện 89 thay vì 90. Một đơn vị đã nhích trong khoảng đó. Ghép hai ảnh đầu lại thì có đủ đầu vào và con số 90 hệ thống tính ra. Màn hình trừ đi quota đã phân bổ, rồi chỉ trừ tiếp phần bán *ngoài* mọi quota, tức là bán thẳng từ kho tổng. Trong bộ số này phần đó bằng 0, nên 200 − 110 − 0 = 90.

Đọc theo cách ấy, "tổng đã bán" trong ticket nghĩa là "đã bán từ kho tổng dùng chung", một đại lượng mà quota theo chương trình không bao giờ chứa. Câu chữ đúng theo một cách đọc, và mơ hồ trên giấy.

Vì sao không ai bắt được sớm hơn? Hai lý do, nên tách riêng:

1. **Trên chương trình mới, hai cách đọc cho cùng một số.** Chưa chương trình nào bán được gì thì số hạng "đã bán" bằng 0 theo cả hai cách, và hai công thức trả về cùng kết quả. Kiểm tay trên dữ liệu vừa tạo không thể nhìn thấy lỗi. Bench xác nhận: mọi ca ngẫu nhiên có tổng bán từ quota bằng 0 thì hai cách đọc trùng nhau.
2. **Câu chữ có dáng của một công thức đúng.** "Tổng trừ đã giữ trừ đã bán" là cách mọi quy tắc tồn kho được viết ra. Tôi đoán, và chỉ là đoán, rằng một câu có dáng đó không làm ai dừng lại. Nó cũng không làm tôi dừng lại, cho đến khi màn hình bắt tôi dừng. Không chữ nào trong câu nói "một số hạng ở đây đã chứa sẵn số hạng kia".

---

## Đánh đổi (Trade-offs)

Chốt được nghĩa rồi, spec vẫn giữ hai dạng của công thức, và thiết kế phải chọn dạng nào để ship.

- **Dạng theo lô:** tổng trên các lô kho của (tổng lô − đã dùng của lô), trừ tổng trên các chương trình của (quota − đã bán từ quota). Dạng này đọc thẳng từ bảng kho ra. Nó chỉ đúng khi mọi đơn bán, ở cả hai chế độ, đều đã được ghi trừ vào một lô, để "đã dùng của lô" và "đã bán từ quota" luôn nhích cùng nhau. Dịch vụ đặt hàng có ghi cả hai bộ đếm trong cùng một transaction, và hoàn tác cả hai khi hủy đơn. Nhưng "bất biến được chỗ ghi dữ liệu giữ cho" là một bảo đảm yếu hơn "công thức không cần đến bất biến đó".
- **Dạng theo tổng nhập:** tổng nhập − quota đã phân bổ − đã bán từ kho tổng. Đây là dạng được chọn. Nó không có số hạng "đã dùng của lô" nào, nên một lần hủy đơn quên hoàn tác không làm nó trôi. Cái giá: câu SQL phải phân biệt được đơn nào bán từ kho tổng, đơn nào bán từ quota, tức là thêm một điều kiện lọc phải viết đúng và phải bảo vệ được khi review.

---

## Kết quả đo được

| Đại lượng | Đọc ticket theo nghĩa đen | Cách đọc màn hình đang chạy |
|---|---|---|
| Tồn khả dụng, bộ số thật | 80 | 90 |
| Sai số | 10, bằng đúng lượng đã bán từ quota | |
| Ca ngẫu nhiên vi phạm đồng nhất thức "sai số = đã bán từ quota" | 0 trên 10.000 | |
| Ca ngẫu nhiên hai cách đọc trùng nhau | mọi ca có đã bán từ quota bằng 0 | |

Số 80 và 90 đến từ một mã hàng trong hệ thống riêng tư và một ảnh chụp tôi không đưa ra được. Phần còn lại bạn chạy lại được. [`bench/cong-thuc-tru-hai-lan`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/cong-thuc-tru-hai-lan) là một script Python chỉ dùng thư viện chuẩn, không cần database: nó tính cả hai cách đọc và dạng theo lô trên bộ số của sự cố và trên 10.000 bộ số ngẫu nhiên, kiểm đồng nhất thức ở từng ca, và thoát với mã lỗi nếu có ca nào vỡ. Một lệnh, cùng một output trên máy cá nhân và trong container sạch.

Tôi không đo hiệu năng; bài này không bàn tốc độ. Thứ thay đổi là công thức giờ có một nghĩa duy nhất với bộ số thật đứng sau, và dạng được ship là dạng không phụ thuộc vào sổ sách lô kho phải hoàn hảo.

---

## Giới hạn, và điều tôi sẽ làm khác

**Bài này không nói được:** lúc đó trên production có bao nhiêu mã hàng đã bán từ quota nhiều hơn 0, mà đó là tập duy nhất khiến hai cách đọc lệch nhau. Tôi không đo, nên không nói được bao nhiêu màn hình sẽ hiện số sai nếu công thức nghĩa đen được ship. Hai ảnh chụp chứng minh màn hình trừ đại lượng nào, chứ không chứng minh màn hình đúng theo một chuẩn nào bên ngoài; bench nhận định nghĩa đó làm đầu vào và chỉ trình ra phép tính. Và tôi chưa kiểm xem mọi đơn hủy trong lịch sử có thật sự hoàn tác đủ cả hai bộ đếm hay không, đó chính là lý do dạng được ship tránh dựa vào nó.

**Quy tắc tôi rút ra:** với mọi quy tắc dạng "khả dụng = tổng − đã giữ − đã bán", hỏi hai câu trước khi nó thành tiêu chí chấp nhận. Có số hạng nào đã chứa sẵn số hạng khác không? Và màn hình production đang tính ra bao nhiêu cho một mã hàng thật, ngay lúc này? Một quy tắc chưa được đối chiếu với một bộ số thật thì mới là một câu văn, chưa phải spec.

**Điều tôi sẽ làm khác:** làm phép trừ ngay ngày câu đó được viết ra, không đợi đến khi màn hình phản bác. Bộ số nằm sẵn trong tài liệu đề xuất. Phép trừ thì tầm thường; phần khó duy nhất là quyết định rằng một câu trông giống mọi quy tắc tồn kho khác vẫn cần được kiểm.
