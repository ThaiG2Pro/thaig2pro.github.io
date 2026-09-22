---
title: "Mọi lần bấm Tăng đều bị 422, và người dùng không thấy gì hết"
date: 2026-09-22T10:00:00+07:00
draft: false
description: "Một selector jQuery trỏ nhầm vùng tab nên khớp 0 phần tử, mọi thao tác Tăng bị gửi đi thành Giảm 0. Phần tệ hơn: lỗi 422 của server rơi vào tab đang ẩn, nên thông báo được vẽ ra đúng chỗ không ai nhìn thấy."
tags: ["jquery", "frontend", "validation", "error-handling", "debugging", "staging"]
categories: ["Kỹ thuật"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/selector-jquery-lot-len-staging/cover.png"
    alt: "Thông báo lỗi validation được vẽ vào một tab đang ẩn, người dùng không nhìn thấy"
---

Báo lỗi của QC chỉ có hai câu. Bấm **Tăng** trong modal điều chỉnh số lượng thì không có gì xảy ra. Bấm lần nữa cũng không có gì xảy ra.

"Không có gì" là triệu chứng khó nhận nhất. Sập thì còn stack trace, sai kết quả thì còn con số sai; màn hình không đổi gì thì không để lại chỗ nào để bắt đầu.

## Chuyện thật sự hỏng ở đâu

Màn hình này là trang quản trị nội bộ của một hệ thống bán hàng có chương trình khuyến mãi. Người vận hành mở modal để điều chỉnh số lượng đã phân bổ cho một SKU. Modal có hai tab — Tăng và Giảm — dùng chung một nút gửi, tab nào đang mở thì quyết định gửi đi thao tác nào.

Trên môi trường staging, **100% lần bấm Tăng bị server từ chối bằng HTTP 422**, và **không lần nào hiện ra thông báo trên màn hình**. Cả hai con số đều đến từ một lượt QC thủ công trên staging, không phải từ đo đạc tự động — tôi nói rõ hơn ở phần dưới.

Chỗ lạ là phía server không có gì sai. Luật validation đúng như thứ chúng tôi muốn, mã 422 là phản hồi đúng cho cái request đã gửi tới, và nội dung phản hồi cũng đúng chuẩn. Không có dòng nào ở server để sửa, mà thao tác vẫn hỏng mọi lần bấm.

---

## Mổ xẻ: hai con bug khoác chung một cái áo

Dù vậy tôi vẫn mất đoạn đầu đi soi server, vì cứ 422 hàng loạt thì trông rất giống luật validation đã lệch khỏi form. Đọc body của request trong tab network là hết chuyện đó: luật không sai, body mới sai. `adjustment_type` là `decrease`, còn `decrease_quantity` là `0`. Trong khi tôi vừa gõ một số dương vào tab Tăng. Hóa ra trình duyệt vẫn luôn xin giảm đi 0 đơn vị, và server từ chối là đúng.

Vậy là chỗ ráp dữ liệu gửi đi có vấn đề. Đoạn đó đọc xem tab nào đang mở:

```js
// ý định: người dùng đang ở tab nào?
const type = $('#adjustmentTabContent .nav-link.active').data('type');
```

`#adjustmentTabContent` chỉ chứa phần **nội dung** của tab. Còn `.nav-link`, tức là chỗ mang `data-type`, lại nằm ở cụm điều hướng phía trên. Selector vì thế không khớp phần tử nào.

jQuery không coi "khớp 0 phần tử" là lỗi. Gọi `.data('type')` trên một tập rỗng thì trả về `undefined`. Đoạn ráp dữ liệu vì thế rơi vào nhánh mặc định. Kết quả: mọi request đều được gửi đi dưới dạng giảm, số lượng 0.

Nguyên nhân gốc thì xong khá nhanh: một selector sai, sửa mất một dòng. Thứ làm con bug này đáng kể lại là cách nó sống sót qua từng lớp kiểm tra, rồi hỏng trước mắt người dùng mà không để lại dấu vết nào.

**Vì sao không có test nào bắt được nó?** Mọi test phía server cho endpoint này đều POST thẳng `adjustment_type` như một field của form. Đó là cách viết test đúng cho một controller, và cũng đúng là cách không chạy lấy một dòng JavaScript nào của modal.

Lời giải thích dễ chịu sẽ là: dự án không có test trình duyệt. Lời giải thích đó sai, và tôi có đi kiểm trước khi viết nó ra. Playwright được khai trong `package.json` của dự án, và tám thay đổi khác trong cùng repo đều kèm thư mục spec và file cấu hình riêng. Công cụ vẫn ở đó. Đồng nghiệp vẫn đang dùng nó ngay trong tháng đó. Phần việc này chỉ đơn giản là không có thư mục spec nào của riêng nó — nên khoảng trống chưa bao giờ nằm ở bộ công cụ. Nó nằm ở chỗ phần việc này coi thế nào là xong.

**Rồi vì sao không ai nhìn thấy lỗi?** Phản hồi 422 của server hoàn toàn đúng chuẩn: một bảng ánh xạ tên field sang thông báo. Phía giao diện cũng làm đúng thứ bình thường phải làm — với mỗi field trong bảng đó, tìm ô nhập có tên tương ứng rồi vẽ thông báo ngay cạnh.

Nhưng mỗi tab có ô nhập riêng của nó — `increase_quantity` và `decrease_quantity` — nên tên field trong lỗi quyết định thông báo được vẽ cạnh ô nào. Nó gọi tên đúng cái ô đang nằm trong tab không được mở. Tab của Bootstrap ẩn phần nội dung không hoạt động bằng `display: none`. Thông báo đã được viết vào DOM đúng, gắn vào đúng phần tử, và vẽ ra đúng 0 pixel. Một thông báo lỗi đúng chuẩn, giao vào một chỗ không ai nhìn thấy, thì không khác gì im lặng.

---

## Đánh đổi (Trade-offs)

Lúc đầu trên bàn chỉ có mỗi phương án sửa selector. Cuối cùng có bốn.

- **Sửa selector rồi ship.** Một dòng, đóng ticket. Không đủ, vì nó để nguyên cái tật nuốt lỗi: ô mà lỗi này trỏ vào vẫn nằm cách một tab, và bất kỳ thông báo nào sau này rơi vào một pane đang đóng cũng biến mất y hệt.
- **Bỏ hẳn selector: mỗi tab một hàm gửi riêng, loại thao tác viết cứng.** Diệt tận gốc loại bug này, vì không còn chỗ nào phải tra cứu để mà tra sai. Bị loại vì modal này đang dùng chung ba thứ: chỗ gửi dữ liệu, đoạn ráp dữ liệu, đoạn vẽ lỗi. Tách hai tab ra là nhân đôi cả ba.
- **Sửa selector, và cho đoạn vẽ lỗi biết ô nào đang hiển thị** — phương án tôi chọn. Thông báo nào không hiện được tại chỗ thì rơi xuống một khung cảnh báo chung ở đầu modal. Cái giá phải trả có ba phần: nuôi thêm một nhánh vẽ lỗi nữa; một luật bắt buộc rằng mỗi thông báo chỉ được hiện ở đúng một trong hai chỗ; và chữ trong khung chung thì kém chính xác hơn, vì nó gọi tên field chứ không chỉ thẳng vào ô.

Còn một phương án nữa, phương án duy nhất bắt được lỗi này *trước* khi nó lên staging: viết một spec chạy trên trình duyệt cho modal. Một file spec là đủ: mở modal, bấm Tăng, kiểm xem cái gì được gửi đi. Nó đã không xảy ra, và không phải vì thiếu bộ khung — bộ khung có sẵn, đang được dùng ở chỗ khác ngay trong cùng repo. Lý do thật là phần việc này được đóng khung như một ca sửa bug giao diện, và không có bước nào trong quy trình hỏi đến test trước khi nó được coi là xong.

---

## Kết quả đo được

Có hai loại bằng chứng ở đây, và nên để riêng chúng ra.

Các con số dưới đây đến từ **một lượt QC thủ công trên staging riêng tư**, chạy trước khi sửa. Chúng mô tả đúng phiên kiểm thử đó, không phải số liệu thống kê dài hạn.

- **Lần bấm Tăng bị từ chối 422:** 100%
- **Lỗi hiện ra cho người vận hành thấy:** 0

Cột "sau khi sửa" bỏ trống là có chủ ý, vì không có gì trung thực để điền vào đó. Không ai chạy lại lượt QC. Tôi không có con số đo nào cho phần đã sửa, chỉ có bản thân thay đổi đó.

Thứ bạn *chạy lại được* là cơ chế, tôi dựng lại từ đầu thành một trang HTML tĩnh trong [`bench/selector-jquery-lot-len-staging/`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/selector-jquery-lot-len-staging): vẫn cấu trúc tab đó, selector sai đặt cạnh selector đúng, và một phản hồi 422 giả mà bạn tự chọn cho nó rơi vào ô đang ẩn hay rơi xuống khung cảnh báo chung. Mở trong trình duyệt là thấy thông báo biến mất ngay trước mắt.

Cùng thư mục đó còn có cái spec mà phần việc này chưa bao giờ có: một file Playwright mở modal, bấm Tăng, rồi kiểm xem cái gì được gửi đi. `./run.sh` chạy nó trong container. Bài kiểm đáng nói nhất hỏi hai câu về cùng một lượt chạy — thông báo có nằm trong DOM không, và `boundingBox()` trả về `null`.

Có một thứ tệ đi. Khung cảnh báo chung chiếm một vùng ở đầu modal, và lúc nó hiện ra thì cả form bị đẩy tụt xuống. Còn với một ô đang hiển thị, thông báo bây giờ có hai chỗ trong code cùng có thể vẽ nó ra — nên cái luật "chỉ một trong hai chỗ" mà hỏng thì người vận hành đọc cùng một lời phàn nàn hai lần.

Và có một con số đứng yên tại chỗ: số spec trình duyệt phủ modal này, từ 0 lên đúng **0**.

Con số đó thì tôi kiểm lại được chứ không phải nhớ lại. Bản sửa là một commit duy nhất, đụng vào đúng một file view, và không thêm file test nào. Năm ngày sau nó vẫn là commit cuối cùng của nhánh.

Thành ra cái vòng tự khép lại: bộ khung thì có sẵn, phần việc này không dùng, một lỗi JavaScript lên tới staging, bản sửa đi ra mà không kèm test, rồi không ai chạy lại lượt QC. Từng bước một đều có lý do nghe được. Gộp lại thì chúng bảo đảm rằng lần sau cũng sẽ y như vậy.

---

## Giới hạn, và điều tôi sẽ làm khác

Phép kiểm tra tôi viết chỉ hỏi xem phần tử có đang được vẽ ra hay không. Nó bắt được trường hợp tab đang ẩn, tức là đúng con bug của tôi. Nó không bắt được ba trường hợp khác:

- ô đã cuộn ra ngoài tầm nhìn
- ô bị một lớp phủ che mất
- ô nằm trong một khối đang gập lại, nhưng về mặt bố cục thì vẫn tồn tại

Cả ba đều vẫn vẽ thông báo vào một chỗ không ai nhìn.

Khung cảnh báo chung cũng chỉ tốt ngang cái hợp đồng dữ liệu lỗi: nó xử lý được thông báo có gắn tên field. Còn lỗi server trả về không kèm tên field, hoặc kèm tên một field form này không có, thì vẫn chưa có chỗ nào để hiện — tôi chưa xử lý, và cũng chưa biết nó xảy ra thường xuyên đến đâu.

Điều tôi sẽ làm khác thì không liên quan gì đến selector. Tôi đi theo con 422 về phía server vì một mã lỗi là tín hiệu kêu to, trong khi tín hiệu mạnh nhất tôi thật sự đang cầm là **người dùng không thấy gì cả** — mà "không có phản hồi" thì bao giờ cũng là chuyện của phía giao diện. Giờ tôi coi sự im lặng là một con bug riêng, ghi thành một mục riêng, tách khỏi nguyên nhân sinh ra nó. Cái selector chỉ tốn một dòng để sửa; chính sự im lặng mới làm nó đắt đến thế lúc đi tìm — và nếu không đụng tới, sự im lặng đó vẫn còn nguyên sau khi bản sửa đã đi ra.

Một hệ thống hỏng mà kêu to thì có người đến sửa. Một hệ thống hỏng mà im lặng lịch sự thì chỉ nhận về một dòng báo lỗi: "bấm vào không thấy gì".
