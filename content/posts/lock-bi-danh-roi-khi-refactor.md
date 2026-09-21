---
title: "Cái lock tôi đánh rơi khi refactor, và 1184 test xanh không hề hay biết"
date: 2026-09-21T10:00:00+07:00
draft: false
description: "Một row lock biến mất trong lúc refactor. Suite vẫn xanh vì sqlite nuốt im lặng FOR UPDATE. Cách tôi làm cho cái lock hiện ra trước mắt test, và cái giá phải trả."
tags: ["concurrency", "testing", "laravel", "sqlite", "refactoring", "tdd"]
categories: ["Kỹ thuật"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/lock-bi-danh-roi-khi-refactor/cover.png"
    alt: "Câu lệnh SELECT FOR UPDATE tan thành chuỗi rỗng trên driver sqlite"
---

QA gửi đúng một dòng: *chưa có test chạy đồng thời trên kho tồn khuyến mãi*. Tôi mở file ra, định viết bốn cái test rồi đóng ticket trong buổi chiều. Nhưng cái khóa mà bốn test đó sinh ra để bảo vệ thì đã biến mất khỏi code từ lúc nào không hay.

## Chuyện gì có thể hỏng ở đây

Hệ thống là phần backend của mảng khuyến mãi. Giả sử một mã hàng có 200 sản phẩm trong kho: nhiều chương trình khuyến mãi cùng lấy hàng từ đúng 200 cái đó. Trước khi một chương trình giữ chỗ cho một đơn, service phải làm ba việc theo thứ tự: đọc xem kho còn bao nhiêu, trừ đi phần các chương trình khác đã giữ, rồi ghi phần của mình.

Ba việc đó chỉ an toàn khi không ai chen vào giữa. Giả sử kho còn 10 sản phẩm, rồi hai khách đặt hàng đúng cùng một khoảnh khắc ở hai chương trình khác nhau. Cả hai request cùng đọc thấy 10. Cả hai cùng kết luận mình lấy được 10. Cả hai cùng ghi. Hệ thống tưởng vừa bán 10 sản phẩm, thực tế nó đã hứa giao 20. Đó là **bán vượt tồn**, và không ai phát hiện ra cho tới lúc thủ kho không còn hàng để giao.

Để chặn chuyện này, database có sẵn một cơ chế gọi là **khóa dòng** (row lock). Khi một request đọc dòng tồn kho kèm câu lệnh `SELECT ... FOR UPDATE`, mọi request khác muốn đọc đúng dòng đó phải xếp hàng đợi, cho tới khi request đầu tiên ghi xong và giải phóng khóa. Tài liệu thiết kế đã ghi rõ điều kiện này: phải đọc tồn kho ở **bên trong** khóa. Code ban đầu làm đúng như vậy.

Rồi tôi sửa nó. Trong hệ thống có nhiều chỗ chỉ đọc tồn kho để hiển thị lên màn hình, không ghi gì cả — mà chúng vẫn phải chờ một cái khóa chúng không cần. Tôi tách ra một hàm đọc riêng, không khóa, để mấy chỗ đó gọi. Khi thay đoạn code cũ bằng lời gọi hàm mới, dòng `lockForUpdate()` nằm lẫn trong đoạn cũ bị xóa theo.

Bộ test vẫn xanh, và review vẫn duyệt. Nhìn vào diff thì đây là một cú tách hàm gọn gàng: xóa vài dòng cũ, thêm một lời gọi hàm mới. Cái khóa mất đi không hiện ra thành dòng nào sai — nó nằm trong đám dòng **bị xóa**, mà người review bao giờ cũng đọc dòng thêm vào kỹ hơn dòng xóa đi. Còn chuyện vì sao bộ test vẫn xanh thì dài hơn, và đó mới là phần đáng kể.

---

## Cái test không bao giờ đỏ được

Ban đầu tôi nghĩ đơn giản: khóa vẫn còn nguyên, QA chỉ thiếu test thôi. Nên tôi viết cái test mà tôi chắc chắn sẽ xanh — cho chạy một đơn hàng, rồi xem lúc nó đọc tồn kho thì câu truy vấn có kèm khóa không.

Nó xanh thật. Trong khi tôi chưa hề thêm lại dòng khóa nào.

Tới đây thì buổi chiều biến thành cả ngày. Một cái test xanh từ trước khi bạn viết code thì không phải test, nó là đồ trang trí. Tôi đem nó chạy trên bản tôi cố tình phá, trên bản cũ, rồi trên cả bản tôi xóa sạch đoạn đọc tồn kho. Xanh. Xanh. Xanh. Không có cách nào làm nó đỏ.

Thủ phạm nằm ở môi trường test. Bộ test chạy trên **sqlite** cho nhanh, còn production chạy MySQL. Mà sqlite thì không có `SELECT ... FOR UPDATE` — nó là database một file, không cần tới cơ chế xếp hàng đó. Vấn đề là Laravel không hề báo cho ai biết. Khi dịch câu truy vấn, Laravel gọi `compileLock()` để sinh ra phần `FOR UPDATE`, và bản dành cho sqlite trả về chuỗi rỗng. Không lỗi, không cảnh báo, không log. Câu SQL cuối cùng đơn giản là không có khóa:

```php
// Service viết thế này
$pool = StockPool::where('sku', $sku)->lockForUpdate()->first();

// sqlite chạy ra thế này
// select * from "stock_pools" where "sku" = ? limit 1
```

Nghĩa là trên môi trường test, việc có gọi `lockForUpdate()` hay không **không tạo ra một khác biệt nào quan sát được**. Mọi cách kiểm tra bằng hành vi đều mù trước đúng thứ tôi cần kiểm tra.

Nếu không quan sát được bằng hành vi, thì phải quan sát bằng thứ khác. Thứ còn lại là chính câu SQL mà Laravel sinh ra trước khi gửi xuống database. Tôi làm ba việc:

1. Thay bản `compileLock()` của sqlite bằng bản của tôi, cho nó sinh ra một comment đánh dấu `/* for update */` thay vì chuỗi rỗng. Comment thì sqlite vẫn chạy bình thường, còn tôi thì nhìn thấy.
2. Dùng `DB::listen()` ghi lại mọi câu SQL mà bộ test chạy qua.
3. Bắt buộc: mọi câu đọc bảng tồn kho, trên cả ba chỗ có ghi dữ liệu, đều phải mang cái dấu đó.

```php
protected function compileLock(Builder $query, $value): string
{
    return $value ? ' /* for update */' : '';
}
```

Lần này test đỏ. Và cái màu đỏ đó mới là phát hiện thật sự: vấn đề nằm ở cú refactor của tôi, chứ không phải ở chỗ QA thiếu test. Toàn bộ đoạn code làm việc này dài khoảng ba mươi dòng.

---

## Đánh đổi (Trade-offs)

Tôi có ba lựa chọn, và cái tôi chọn lại là cái yếu nhất nếu chỉ nhìn trên giấy.

**Một — mở hai kết nối thật vào MySQL.** Chạy hai transaction song song, để cái thứ hai bị chặn lại, rồi kiểm tra xem nó có thật sự phải chờ không. Cách này kiểm được cái khóa thật, kể cả thứ tự khóa lẫn thời gian chờ. Cái giá: bộ test phải có một MySQL thật đang chạy, nên CI phải dựng thêm một service MySQL, và mỗi lập trình viên cũng phải cài MySQL trên máy mình mới chạy được test. Thời gian dựng dữ liệu cho mỗi test nhảy từ vài mili-giây lên vài giây. Cho ba chỗ ghi thôi, tôi ước lượng bộ test sẽ ngốn nhiều thời gian hơn cả thời gian làm ra tính năng này.

**Hai — kiểm tra trên câu SQL sinh ra.** Nhanh, không cần hạ tầng gì thêm, chạy thẳng trên sqlite sẵn có. Cái giá: nó chỉ chứng minh cái khóa **được yêu cầu**, chứ không chứng minh cái khóa **đủ chặt**. Và nó bám vào một chi tiết bên trong Laravel: ngày nào Laravel đổi cách gọi tới `compileLock()`, đoạn code của tôi sẽ âm thầm thôi đánh dấu, rồi mọi test lại xanh vì một lý do sai.

**Ba — đặt quy ước: mọi chỗ ghi đều phải gọi qua một hàm bọc có sẵn khóa.** Rẻ nhất, khỏi cần test luôn. Tôi loại nó vì quy ước này chỉ bắt được những lỗi *trông giống* lỗi — kiểu ai đó viết thẳng câu truy vấn mà quên gọi hàm bọc. Còn lỗi của tôi thì vẫn lọt qua: tôi **có** gọi hàm bọc, chỉ là gọi nhầm sang phiên bản không khóa của chính nó.

Tôi chọn cách hai, vì sự cố tôi thật sự gặp là "dòng gọi khóa bị xóa mất", chứ không phải "khóa có nhưng chưa đủ chặt". Test nên nhắm vào cái lỗi đã thực sự xảy ra. Bộ test trên MySQL là khoản đầu tư đúng khi bản thân việc tranh chấp trở thành vấn đề — lúc đó thì chưa.

---

## Kết quả đo được

Ở đây có hai loại bằng chứng, và nên tách bạch ra.

Mấy con số dưới đây đo trong một **codebase riêng tư**, cùng một máy, cùng một lệnh `phpunit` chạy trước và sau khi sửa. Bạn không chạy lại được, nên cứ trừ hao khi đọc.

- **Test chạy đồng thời trên lượt đọc tồn kho:** 0 → 4
- **Số chỗ ghi có kiểm tra khóa:** 0/3 → 3/3
- **Toàn bộ test:** 1101 → 1184 xanh (phần tăng thêm là test của cả đợt làm; bốn cái trong đó là test khóa)

Có một cái giá tôi **chưa đo**: việc thay `compileLock()` buộc mỗi test phải mở kết nối mới, nên bộ test chậm đi. Tôi không ghi lại con số trước và sau, nên không đưa ra ở đây được. Nó nhỏ ở quy mô bốn test, nhưng sẽ lớn dần theo mỗi chỗ ghi thêm vào sau này.

Còn thứ bạn **chạy lại được** là cơ chế — chính chuyện cái khóa im lặng biến mất trên sqlite, và đây mới là phần áp dụng được ở nơi khác. Tôi dựng lại nó từ đầu, tách hẳn khỏi code công ty, ở [`bench/lock-bi-danh-roi-khi-refactor/`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/lock-bi-danh-roi-khi-refactor): một dự án Laravel trống, năm file, và một hằng số để bạn lật qua lại giữa bản hỏng và bản đã sửa. Trong đó có hai bài test. Cái test kiểu hành vi — đúng thứ một người bình thường sẽ viết khi QA đòi "test đồng thời" — xanh ở cả hai trường hợp. Đó chính là phát hiện của bài, và bạn dựng lại được trong khoảng năm phút.

Riêng chuyện bán vượt tồn thì chưa bao giờ đo được trên production, vì cái khóa đã quay lại trước ngày phát hành. Con số trung thực cho số đơn bị ảnh hưởng là: không biết, và nhiều khả năng bằng không.

---

## Giới hạn, và điều tôi sẽ làm khác

Cái test này đọc văn bản SQL, nên nó không nhìn thấy thứ tự khóa, không thấy deadlock, cũng không thấy trường hợp transaction đóng lại quá sớm — một lượt đọc có thể được khóa hoàn toàn đúng mà vẫn nằm trong một transaction kết thúc sai chỗ. Nhóm lỗi đó đến giờ vẫn chưa ai canh.

Nó cũng bám vào một chi tiết bên trong Laravel mà không có gì canh chừng. Nếu một bản Laravel sau này đổi cách gọi tới `compileLock()`, đoạn code của tôi sẽ lặng lẽ thôi đánh dấu, và mọi kiểm tra lại xanh hết — đúng y cái kiểu hỏng mà tôi đang cố diệt, chỉ là lùi lên một tầng.

Nhưng điều tôi sẽ làm khác thì sớm hơn và rẻ hơn mọi thứ ở trên. Tài liệu thiết kế có đúng một câu: *đọc tồn kho ở bên trong khóa*. Câu đó không gắn với bất kỳ cái test nào. Nó chỉ tồn tại trong một file tài liệu, và trong trí nhớ của những người đã đọc file đó.

Giờ tôi làm thế này: khi tài liệu thiết kế đặt ra một điều kiện phải luôn đúng, thì ngay trong chính commit tạo ra điều kiện ấy, tôi viết luôn một cái test sẽ đỏ nếu điều kiện bị phá. Không để lần sau, không đợi tới vòng QA. Lý do đơn giản: chỉ ở đúng thời điểm đó mọi người mới còn hiểu rõ câu chữ trong tài liệu nghĩa là gì. Sáu tháng sau, người đọc lại câu đó sẽ là một người mới — và người đó sẽ refactor y hệt cách tôi đã refactor.

Bộ test xanh là có lý do của nó. Chỉ là không phải cái lý do tôi tin.
