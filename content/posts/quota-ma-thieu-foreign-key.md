---
title: "Quota ma: thiếu một foreign key âm thầm hạ trần bán"
date: 2026-09-22T15:00:00+07:00
draft: false
description: "Một dòng mồ côi trong bảng không có foreign key trước đây chỉ làm báo cáo lệch một chút. Sau khi bảng kho dùng chung ra đời, chính dòng đó bắt đầu khóa cứng đơn vị bán thật."
tags: ["database", "data-integrity", "foreign-key", "backend", "migrations"]
categories: ["Kỹ thuật"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/quota-ma-thieu-foreign-key/cover.png"
    alt: "Một dòng mồ côi vẫn bị tính vào kho dùng chung, mà không có màn hình nào giải phóng được"
---

Bảng `campaign_product_variants` không có foreign key (khóa ngoại), không `ON DELETE CASCADE`, cũng không có `deleted_at`. Trước khi có kho dùng chung, đó chỉ là vấn đề thẩm mỹ: vài dòng trỏ tới một SKU đã không còn tồn tại làm báo cáo hiện ra con số nhỏ hơn thực tế một chút. Tôi không thấy ai coi đó là bug, và tôi cũng không lật lại ticket cũ để kiểm cho chắc.

Rồi chúng tôi ship tính năng kho dùng chung (shared stock pool) — nhiều chương trình khuyến mãi cùng rút quota từ một kho chung cho mỗi SKU — và những dòng mồ côi đó thôi là chuyện thẩm mỹ. Trên một DB dev tôi còn đụng vào được, 14 dòng mồ côi đang khóa cứng 294 đơn vị không bán được, vĩnh viễn, mà không có màn hình quản trị nào chọn được dòng đó để giải phóng. Thiếu một foreign key đã biến nợ kỹ thuật cũ thành một cái trần bán bị hạ thấp thật.

## Mổ xẻ: một dòng mồ côi thật ra tốn bao nhiêu

Cơ chế đơn giản một khi đã nhìn ra, và chính vì đơn giản nên không có gì buộc ai phải nhìn vào nó. Mỗi dòng trong `campaign_product_variants` gán một quota cho một chương trình, ứng với một SKU. Tính năng kho dùng chung tính phần còn bán được của một SKU bằng cách lấy tổng kho trừ đi tổng đã phân bổ trên **mọi** chương trình có tham chiếu tới SKU đó — một câu truy vấn gộp (aggregate), không lọc theo từng chương trình, vì lọc theo chương trình chính là điều một kho *dùng chung* phải tránh.

Câu truy vấn gộp đó không kiểm tra SKU mà một dòng trỏ tới còn tồn tại hay không. Nó cộng dồn cột `quota` của mọi dòng có tham chiếu tới id của SKU, hết. Trước khi có kho dùng chung, một variant bị xóa hoặc thay thế ở chỗ khác trong hệ thống chỉ để lại một dòng lơ lửng mà báo cáo lặng lẽ bỏ qua. Sau khi có kho dùng chung, chính dòng lơ lửng đó tiếp tục cộng quota của nó vào vế "đã phân bổ" của phép trừ. SKU mà nó từng thuộc về vẫn đang bán thật, vẫn còn thật, và vẫn đang nhận đơn từ những chương trình chẳng liên quan gì tới dòng mồ côi kia.

Và không có cách nào tìm ra nó trên giao diện sản phẩm. Dòng mồ côi không thuộc về chương trình nào mà người vận hành mở lên được — chương trình cha của nó có thể đã kết thúc, SKU nó trỏ tới có thể đã bị thay — nên không có màn hình sửa, không có nút "giải phóng quota", không có gì để bấm. Nó nằm trong database, tính vào trần bán của một SKU thật mãi mãi, cho tới khi ai đó tự tay chạy query trên production.

Tôi xác nhận hình dạng của vấn đề bằng một câu pre-check hai tầng `LEFT JOIN` (gọi là V7). Đây là bản dựng lại với tên bảng và tên cột chung, không phải nguyên văn câu truy vấn của production: nối `campaign_product_variants` sang `product_variants`, rồi sang chương trình cha, đếm những dòng mà một trong hai phía là `NULL` hoặc đã xóa mềm.

```sql
SELECT cpv.id, cpv.product_variant_id, cpv.quota
FROM campaign_product_variants cpv
LEFT JOIN product_variants pv
       ON pv.id = cpv.product_variant_id
      AND pv.deleted_at IS NULL
LEFT JOIN campaigns c
       ON c.id = cpv.campaign_id
      AND c.deleted_at IS NULL
WHERE pv.id IS NULL OR c.id IS NULL;
```

Trên DB dev, câu này trả về 14 dòng, tổng 294 đơn vị. Tôi chưa đo con số đó thay đổi thế nào nếu đếm thêm cả những SKU mà phép trừ gộp bị âm rồi bị kẹp (clamp) về 0 — đó là một triệu chứng liên quan của cùng một ràng buộc còn thiếu, nhưng tôi chưa chạy phép đếm đó nên không đưa ra con số ở đây.

## Đánh đổi (Trade-offs)

Cách sửa hiển nhiên nhất là thêm hẳn foreign key, kèm `ON DELETE CASCADE` để dòng mồ côi không bao giờ sinh ra được nữa. Tôi đề xuất đúng như vậy và bị bác, vì hai lý do:

- **`ALTER TABLE ... ADD CONSTRAINT` fail ngay nếu đã có dòng mồ côi từ trước.** Migration sẽ phải dọn dữ liệu trước, mà release lần này có tiêu chí nghiệm thu (acceptance criterion) là migration phải chạy tức thời — không có bước backfill, không có cửa sổ bảo trì. Thêm ràng buộc ngay lập tức là điều không thể mà không phá tiêu chí đó.
- **`ON DELETE CASCADE` xóa luôn những dòng mà bảng audit còn đang trỏ tới.** Bảng audit ghi lại quota đã phân bổ khi nào, khóa theo `campaign_product_variants.id`. Một lượt xóa theo tầng (cascade) sẽ âm thầm xóa mất đúng dòng mà người audit cần để giải trình một lần phân bổ trong quá khứ — đổi lấy một ràng buộc chỉ ngăn được dòng mồ côi *tương lai*.

Cái đã ship thay vào đó: câu pre-check V7 làm cổng chặn ở bước release — flag bật kho dùng chung không được mở cho tới khi câu đó trả về 0 dòng trên môi trường mục tiêu — cộng một test hồi quy tự seed đúng một dòng mồ côi và kiểm phép tính kho phải lộ nó ra, thay vì âm thầm nuốt vào phép trừ. Việc thêm foreign key thật được tách sang một ticket riêng, có chủ sở hữu cụ thể, tách khỏi release này.

## Cái tôi đã đo, và cái tôi chưa đo

14 dòng và 294 đơn vị đều là số từ database dev, trong một codebase riêng tư mà bạn không chạy lại được. Coi đây là bằng chứng cơ chế có thật, đừng coi là tuyên bố về quy mô — tôi chưa chạy câu V7 trên production, và bản chất của cổng chặn là tôi chỉ có con số đó đúng một lần, ngay trước khi bật flag, không phải một con số để công bố trước ở đây.

Cổng chặn cũng không sửa nguyên nhân gốc: không có gì trong schema ngăn một dòng mồ côi mới sinh ra vào ngày mai — tôi chưa truy ra đoạn code nào đã tạo ra những dòng cũ, nên cũng không nói được nó còn hoạt động hay không. Cổng chặn chỉ ngăn *release* lần này ship trên nền dữ liệu bẩn. Và cách sửa triệt để — foreign key thật — đang nằm ở một ticket riêng có chủ sở hữu cụ thể; tính đến lúc viết bài, tôi không biết nó đã có ngày hay chưa. Một pre-check chỉ bắt được lỗi ở đúng chỗ nó đứng gác, không sửa được cái schema đã để lỗi lọt vào từ đầu.

Nếu làm lại, tôi sẽ đẩy mạnh hơn để xếp lịch migration dọn dữ liệu và thêm ràng buộc trong cùng quý với tính năng khiến món nợ đó trở nên đắt đỏ, thay vì chấp nhận "tách ticket riêng" như một cách giải quyết đứng một mình.
