---
title: "Tôi viết ngưỡng thêm index thành con số, rồi tự đo lại và thấy nó lệch 15 đến 100 lần"
date: 2026-09-28T11:30:00+07:00
draft: false
description: "Ô lọc voucher merge lên staging không index trên bảng team khác sở hữu, kèm ngưỡng leo thang viết bằng số. Bench sau đó cho thấy hai vế của ngưỡng không khớp nhau tùy phiên bản DB."
tags: ["backend", "mariadb", "indexing", "performance", "technical-debt", "laravel"]
categories: ["Kỹ thuật"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/khong-them-index-viet-nguong-leo-thang-thanh-so/cover.png"
    alt: "Biểu đồ log-log: đường ngoại suy chấm chấm kết thúc gần 10 ms, hai đường đo thật không index bỏ xa nó (MariaDB 10.11 ở 968 ms và 13.0 ở 148 ms tại 1M dòng), vạch gạch 300 ms, và một đường phẳng dưới 1 ms cho trường hợp có index"
---

Cuối tháng trước tôi chốt một thiết kế cho phép tra cứu trên một cột không có index, ở một bảng team tôi không sở hữu, và viết điều kiện sửa nó thành một câu có hai con số: *"khi bảng vượt khoảng 1.000.000 dòng, hoặc p95 của truy vấn lọc theo voucher vượt 300 ms, thì gửi yêu cầu thêm index non-unique cho team sở hữu."* Câu đó có đúng một việc: đưa phương án "ship không index" qua vòng review thiết kế, với "sẽ thêm sau" được đổi thành thứ người review ký được. Nó làm xong việc đó.

Tuần này tôi dựng bench để kiểm mấy con số. Vế số dòng lệch 15 lần trên một phiên bản MariaDB, khoảng 100 lần trên phiên bản kia. Quyết định hoãn index vẫn đứng vững. Những con số tôi gắn vào nó thì không, và bài này kể những con số đó đã được viết ra như thế nào.

---

## Mổ xẻ: hai con số đến từ đâu

Tính năng rất nhỏ: một ô nhập trên danh sách đơn hàng, tìm đơn nào chứa mã voucher người dùng gõ vào. Voucher nằm ở một bảng thuộc hệ thống khác, do team khác bảo trì. Cổng quản trị của chúng tôi chỉ đọc bảng đó, không được migrate. Có hai loại mã voucher ở hai cột khác nhau, và cả hai cột đều không có index.

Ngưỡng có trước phép đo. Lúc thiết kế đến tay tôi, giai đoạn phân tích đã chốt sẵn hướng của quyết định: ship không thêm index, và ghi một ngưỡng leo thang khoảng 1 triệu dòng hoặc p95 300 ms. Việc của tôi là đưa phương án đó qua vòng review. Nghĩa là phải cho thấy hai phương án kia tệ hơn, và cho thấy ngưỡng không chỉ là một lời hứa.

Nên tôi chạy một lần `EXPLAIN` trên staging: 3.217 dòng, trung bình 2,14 voucher mỗi đơn, quét toàn bảng dưới 1 ms. Rồi tôi kẻ một đường thẳng qua đúng một điểm đó. Khoảng 1 ms ở 100.000 dòng, khoảng 10 ms ở 1.000.000. Tài liệu thiết kế gọi đường thẳng đó là "cơ sở" của ngưỡng. Thật ra là ngược lại. Con số 1 triệu đã nằm trong biên bản từ trước; đường thẳng được kẻ sau để nó có cái mà tựa vào. Tôi không chạy truy vấn ở 100 nghìn dòng. Tôi không chạy ở 1 triệu. Con số staging là thật; đường thẳng kẻ qua nó là một phỏng đoán khoác vẻ chính xác đến hai chữ số thập phân.

Vế 300 ms thì không có cả đường thẳng. Không chỗ nào trong biên bản nói vì sao là 300 mà không phải 200 hay 500. Nó nghe hợp lý, và trong biên bản không thấy ai, kể cả tôi, hỏi nó từ đâu ra.

Đó cũng là lý do sau này không ai đo lại. Qua được vòng review rồi thì con số hết việc, nên không ai quay lại với nó. Không ai lên lịch đo lại. Việc treo duy nhất có thể chốt chuyện này, đếm số dòng bảng đó trên production, đến giờ vẫn treo trong ghi chú bàn giao.

Cùng thiết kế đó còn hai quyết định nhỏ hơn, và một trong hai sẽ quay lại ở cuối bài.

- Mã 10 chữ số trông như một con số, và cách validate hiển nhiên là validate như số. Đếm trên staging thì 9,8% mã bắt đầu bằng số 0. Ép một mã như vậy sang số nguyên là mất số 0 đầu, truy vấn trả về rỗng, và không có lỗi nào được báo. Cứ khoảng mười lần tìm thì một lần "không thấy" mà không ai hay biết. Vậy nên mã voucher là chuỗi từ đầu đến cuối: validate bằng regex, không ép kiểu ở tầng nào, và cột trong file Excel xuất ra khai kiểu text để Excel không tự bỏ số 0.
- Không biết người dùng gõ loại mã nào, và truy vấn hiển nhiên là `OR` cả hai cột. Nhưng hai định dạng không bao giờ giao nhau: một loại đúng 10 chữ số, loại kia đúng 11 ký tự và luôn có chữ cái. Nên tôi gói việc đó vào một value object: nhận chuỗi thô, trả về đúng một cặp (cột, giá trị), hoặc không trả gì nếu chuỗi không khớp định dạng nào. Cả ba nơi cần lọc, gồm lưới đơn, lưới đơn phụ và luồng xuất file, đều gọi qua nó. Lý do được ghi lại để không dùng `OR` là: không index thì `OR` buộc quét toàn bảng. Trong đầu tôi còn một lý do thứ hai, chưa từng viết ra: `OR` trên hai cột thì sau này có index cũng khó dùng.

---

## Đánh đổi (Trade-offs)

Lúc đó có ba phương án được ghi lại, và biên bản giữ cả ba.

- **Ship không index, viết điều kiện đi xin index thành con số.** Chọn. Nó tôn trọng ranh giới sở hữu và không chặn ai. Cái giá là chi phí truy vấn tăng theo bảng, và nếu ngưỡng không được viết ra thì sẽ bị quên. Ngưỡng có hai vế nối bằng *hoặc* vì số dòng thì dễ kiểm, còn độ trễ là thứ người dùng nhận thấy.
- **Tự thêm index bằng migration trong repo của chúng tôi.** Loại. Nhanh, nhưng không phải việc của chúng tôi: chúng tôi không có quyền trên schema đó, và một migration nằm trong repo này sẽ lệch khỏi schema của hệ sở hữu.
- **Chặn ticket cho đến khi team kia thêm index.** Loại. Đích đến cuối cùng nên là như vậy, nhưng nó bắt một thay đổi rủi ro thấp phải chờ backlog của người khác, vì một lợi ích mà ở 3.217 dòng thì chưa đo được.

Hai lựa chọn nhỏ hơn nằm bên trong phương án đầu. Yêu cầu sẽ là index *non-unique*, vì một ràng buộc unique có thể làm hỏng chỗ hệ sở hữu ghi mới hoặc ghi lại (insert/retry), mà hệ đó tôi không đủ hiểu để phán. Và ngưỡng được ghi vào tài liệu thiết kế, chứ không ghi vào trí nhớ.

Tôi vẫn nghĩ phương án đầu là đúng. Thứ tôi muốn đổi là những con số tôi gắn vào nó, và thứ tự giữa con số với phép đo.

---

## Kết quả đo được

Bench nằm ở [bench/khong-them-index-viet-nguong-leo-thang-thanh-so](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/khong-them-index-viet-nguong-leo-thang-thanh-so). Một lệnh, chỉ cần Docker, khoảng hai phút mỗi phiên bản.

- **Dữ liệu:** hai bảng với tên tự đặt, sinh bằng sequence engine của MariaDB, khoảng 2,14 voucher mỗi đơn.
- **Truy vấn:** một truy vấn `EXISTS` tương quan, đúng dạng truy vấn mà lưới đơn hàng đang dùng.
- **Cách đo:** 5 lần cho mỗi biến thể, mỗi lần nhắm một voucher khác đang tồn tại, đo ngay trên server bằng `SYSDATE(6)`; bảng ghi trung vị.

Tính bằng mili giây, theo số dòng bảng voucher:

| Biến thể | 3.217 | 100.000 | 1.000.000 |
|---|---|---|---|
| MariaDB 13.0.2, không index | 0,589 | 24,797 | 147,656 |
| MariaDB 13.0.2, index non-unique | 0,125 | 0,093 | 0,204 |
| MariaDB 13.0.2, `OR` hai cột, cả hai có index | 0,167 | 0,330 | 0,565 |
| MariaDB 10.11.18, không index | 2,319 | 44,279 | 967,945 |
| MariaDB 10.11.18, index non-unique | 0,426 | 0,503 | 0,622 |
| MariaDB 10.11.18, `OR` hai cột, cả hai có index | 0,561 | 0,523 | 0,454 |

Con số đầu tiên tôi nghi không phải 148 ms. Bốn lượt chạy ở 1 triệu dòng trên 13.0, mỗi lượt lấy trung vị của 5 lần, ra 148, 485, 162 và 129 ms, và 485 mới là số trông sai. Ghi chú bên cạnh nó nói lúc đó một tiến trình khác đang chiếm CPU, ba lần còn lại nằm trong khoảng 129 đến 162, nên tôi giữ 148. Rồi tôi kiểm xem truy vấn trong bench có đúng dạng `EXISTS` mà lưới đơn hàng đang dùng không, hay là một dạng dễ hơn hoặc khó hơn. Đúng dạng. Rồi tôi tính lại: 148 so với 10, 968 so với 10, gấp 22 lần từ 100 nghìn lên 1 triệu. Chỉ sau đó tôi mới nghĩ tới production, và điều đầu tiên nghĩ ra là tôi không biết trên đó chạy MariaDB phiên bản nào.

Ba chỗ trong bảng này nói ngược lại những gì tôi đã viết.

1. **Ngoại suy sai trên cả hai phiên bản.** Con số "dưới 1 ms" ở staging tái lập được trên 13.0 (0,6 ms) và không tái lập trên 10.11 (2,3 ms). Mức tăng không phải 1 ms cho mỗi 100 nghìn dòng. 100 nghìn dòng đầu tốn khoảng 25 ms trên 13.0 và 44 ms trên 10.11. Qua mốc đó, 13.0 tăng chậm hơn tuyến tính, còn 10.11 tăng nhanh hơn cả tuyến tính: từ 100 nghìn lên 1 triệu, gấp 10 lần số dòng thì tốn gấp 22 lần thời gian. Cái "khoảng 10 ms ở 1 triệu" của tôi thực tế là 148 ms trên một bản và 968 ms trên bản kia.
2. **Hai vế của ngưỡng không đồng ý với nhau.** Trên 13.0 khi máy rảnh, 1 triệu dòng mất khoảng 130 đến 160 ms qua ba lượt chạy, nên vế số dòng chạm ngưỡng trước và vế 300 ms gần như thừa. Một trong bốn lượt chạy, lúc một tiến trình khác đang chiếm CPU, ra 485 ms: cùng bảng, cùng phiên bản, và giờ vế độ trễ chạm ngưỡng trước. Trên 10.11, mốc 300 ms bị vượt ở đâu đó giữa 100 nghìn và 1 triệu dòng. Kéo dài từ điểm 100 nghìn thì ra khoảng 680 nghìn; kéo từ điểm 1 triệu thì khoảng 310 nghìn. Bench chưa đo ở giữa. Dù thế nào thì trên bản đó vế số dòng kích hoạt quá muộn, chỉ còn vế độ trễ bảo vệ người dùng, và không ai được giao theo dõi vế đó.
3. **Lý do ghi trong biên bản để loại `OR` vẫn đúng; lý do không ghi thì sai.** Không index thì quét toàn bảng, bench không bác điều đó. Nhưng khi cả hai cột có index, optimizer của cả hai phiên bản đều chọn phương án index-merge union và giữ dưới 1 ms ở 1 triệu dòng. Value object nhìn định dạng chuỗi mà chọn cột vẫn là thiết kế hợp lý, vì một điều kiện trúng một index thì không phụ thuộc vào việc optimizer có gộp được gì hay không. Nhưng cái giả định "sau này khó index" là không đúng, và nó đã chi phối thiết kế mà chưa từng được viết ra ở chỗ ai đó có thể chất vấn.

Index non-unique xóa hẳn đà tăng: phẳng trong khoảng 0,1 đến 0,6 ms qua cả ba cỡ bảng, trên cả hai phiên bản. Trong bench không có chỉ số nào xấu đi, vì bench không đo ghi; chi phí của index lên chỗ hệ sở hữu ghi dữ liệu là thứ duy nhất về nó mà tôi vẫn chưa nhìn thấy được.

---

## Giới hạn, và điều tôi sẽ làm khác

- **Số dòng trên production vẫn chưa đo.** Từ môi trường của tôi không có đường truy vấn bảng đó trên production. Nếu nó đã gần 1 triệu dòng thì mọi đoạn phía trên vô nghĩa ngay ngày phát hành. Đó vẫn là việc treo y như một tháng trước, và lẽ ra nó phải là thứ tôi đẩy lên hỏi team kia đầu tiên chứ không phải cuối cùng.
- **Phiên bản MariaDB trên production tôi không biết.** Tôi không tìm thấy chỗ nào trong repo của cổng quản trị pin phiên bản MariaDB, và database không nằm trong Docker của ứng dụng. Bảng trên có hai phiên bản chính vì kết quả ở 1 triệu dòng lệch nhau 6,5 lần, và tôi không nói được dòng nào trong hai dòng đó là dòng của production.
- **Mọi con số trong bảng đều là quét trong bộ nhớ, trên một laptop đang rảnh.** Một triệu dòng của schema này vừa trong buffer pool mặc định. Bảng production không vừa thì chậm hơn mọi con số ở đây, và bench chạy từng truy vấn một, nên p95 của nó không phải p95 của hệ thống đang chịu tải. Lượt chạy 485 ms ở trên cho thấy một máy bận làm con số không index xê dịch tới đâu.
- **Luồng xuất file chưa được bench.** Nó áp cùng điều kiện lọc cho mỗi lô, nên chi phí là con số này nhân với số lô.
- **Các số staging (3.217 dòng, 9,8% số 0 đầu, 2,14 voucher mỗi đơn) đến từ codebase riêng tư.** Bạn không chạy lại được. Cứ trừ hao khi đọc; bench mới là phần bạn kiểm được.

Điều tôi sẽ làm khác thì nhỏ và cụ thể. Lần sau viết ngưỡng bằng số dòng, tôi sẽ sinh đủ chừng ấy dòng trước: bench làm việc đó chỉ là một file SQL và một script, hai phút mỗi phiên bản, và chỉ cần Docker. Con số nào thừa kế chứ không đo thì ghi rõ là thừa kế, thay vì kẻ sau một đường thẳng để hợp thức hóa nó. Con số nào không có xuất xứ, như 300 ms, thì đánh dấu là tạm cho đến khi có người đo. Tôi cũng sẽ viết vế độ trễ trước, vế số dòng sau, vì số dòng là vế tôi tự tin nhất, và hóa ra nó là vế phụ thuộc phiên bản. Và tôi sẽ viết ra mọi lý do mà thiết kế dựa vào, kể cả những lý do nghe hiển nhiên đến mức không ai buồn ghi, để sau này người không tham gia lúc đó vẫn kiểm được từng lý do.

Câu có hai con số vẫn tốt hơn "sẽ thêm index sau". Chỉ là nó chưa phải một câu đã được đo.
