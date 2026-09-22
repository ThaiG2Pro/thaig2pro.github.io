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

"Không có gì" mới là chỗ khó. Sập thì có stack trace, sai số thì có con số sai. Ở đây chỉ có một modal đứng im và một người dùng không biết hệ thống đã nghe thấy mình hay chưa.

## Chuyện thật sự hỏng ở đâu

Màn hình này là trang quản trị nội bộ của một hệ thống bán hàng có chương trình khuyến mãi. Người vận hành mở modal để điều chỉnh số lượng đã phân bổ cho một SKU. Modal có hai tab — Tăng và Giảm — dùng chung một nút gửi, tab nào đang mở thì quyết định gửi đi thao tác nào.

Trên môi trường staging, **100% lần bấm Tăng bị server từ chối bằng HTTP 422**, và **không lần nào hiện ra thông báo trên màn hình**. Cả hai con số đều đến từ một lượt QC thủ công trên staging, không phải từ đo đạc tự động — tôi nói rõ hơn ở phần dưới.

Bản thân việc từ chối là đúng. Server đang từ chối một yêu cầu đòi *giảm* số lượng đi *0* đơn vị — và đó đúng là thứ trình duyệt gửi lên, lần nào cũng vậy, bất kể người dùng đang mở tab nào.

---

## Mổ xẻ: hai con bug khoác chung một cái áo

Giả thuyết đầu tiên của tôi là server: cứ 422 hàng loạt thì thường là luật validation đã lệch khỏi form. Giả thuyết chết ngay khi tôi đọc body của request trong tab network — luật không sai, body mới sai. `adjustment_type` là `decrease` còn `quantity` là `0`, trong khi tôi vừa gõ một số dương vào tab Tăng.

Vậy là chỗ ráp dữ liệu gửi đi có vấn đề. Đoạn đó đọc xem tab nào đang mở:

```js
// ý định: người dùng đang ở tab nào?
const type = $('#adjustmentTabContent .nav-link.active').data('type');
```

`#adjustmentTabContent` là vùng chứa **nội dung** của hai tab. Còn hai cái nút bấm để chuyển tab, tức là chỗ mang `.nav-link` và `data-type`, lại nằm trong thẻ `<ul>` *ở phía trên* vùng đó. Selector khớp 0 phần tử.

jQuery không coi "khớp 0 phần tử" là lỗi. Gọi `.data('type')` trên một tập rỗng thì nhận về `undefined`, đoạn ráp dữ liệu rơi vào nhánh mặc định, nên mọi lần gửi đều đi ra dưới dạng mặc định: giảm, số lượng 0.

Một selector, một dòng. Nhưng phần đáng viết ra không phải chỗ đó, mà là vì sao không ai *nhìn thấy* lỗi.

**Vì sao không test nào bắt được.** Mọi test phía server cho endpoint này đều POST thẳng `adjustment_type` như một field của form. Đó là cách viết test đúng cho một controller, và cũng đúng là cách không chạy lấy một dòng JavaScript nào của modal. Con bug nằm gọn trong khoảng trống giữa "có test server" và "không có test trình duyệt" — khoảng trống đó không thuộc ticket của ai cả.

**Vì sao không ai thấy lỗi.** Phản hồi 422 của server hoàn toàn đúng chuẩn: một bảng ánh xạ tên field sang thông báo. Phía giao diện cũng làm đúng thứ bình thường phải làm — với mỗi field trong bảng đó, tìm ô nhập có tên tương ứng rồi vẽ thông báo ngay cạnh.

Nhưng trong modal này có tới hai ô nhập tên `quantity`, mỗi tab một cái, và cái mà lỗi trỏ tới đang nằm trong tab không được mở. Tab của Bootstrap ẩn phần nội dung không hoạt động bằng `display: none`. Thông báo đã được viết vào DOM đúng, gắn vào đúng phần tử, và vẽ ra đúng 0 pixel. Một thông báo lỗi đúng chuẩn, giao vào một chỗ không ai nhìn thấy, thì không khác gì im lặng.

---

## Đánh đổi (Trade-offs)

Bốn phương án, và lúc đầu trên bàn chỉ có mỗi phương án sửa selector.

- **Sửa selector rồi ship.** Một dòng, đóng ticket. Không đủ, vì nó để nguyên cái tật nuốt lỗi: thông báo tiếp theo trỏ vào một ô đang ẩn — mà modal này có vài ô như vậy — sẽ biến mất y hệt.
- **Bỏ hẳn selector: mỗi tab một hàm gửi riêng, loại thao tác viết cứng.** Diệt tận gốc loại bug này, vì không còn chỗ nào phải tra cứu để mà tra sai. Bị loại vì phải nhân đôi cả đường gửi dữ liệu, cả đoạn ráp dữ liệu, cả đoạn vẽ lỗi, trong khi modal này dùng chung cả ba.
- **Sửa selector, và cho đoạn vẽ lỗi biết ô nào đang hiển thị** — phương án đã chọn. Thông báo nào không hiện được tại chỗ thì rơi xuống một khung cảnh báo chung ở đầu modal. Cái giá: phải nuôi thêm một đường vẽ lỗi thứ hai, một luật bắt buộc là mỗi thông báo chỉ được hiện ở đúng một trong hai chỗ, và chữ trong khung chung thì kém chính xác hơn vì nó gọi tên field chứ không chỉ thẳng vào ô.
- **Dựng test chạy trên trình duyệt cho modal.** Phương án duy nhất bắt được lỗi trước khi lên staging. Bị loại trong phạm vi ticket này, chứ không phải loại vĩnh viễn: dự án chưa có bộ khung test trình duyệt nào, dựng lên là việc vài ngày, cần người sở hữu và cần chỗ trong CI. Nhét nó vào một ticket sửa bug là cách chắc chắn nhất để nó nằm đó dang dở rồi bị tắt đi.

---

## Kết quả đo được

Có hai loại bằng chứng ở đây, và nên để riêng chúng ra.

Các con số dưới đây đến từ **một lượt QC thủ công trên môi trường staging riêng tư**: một người vận hành chạy lại luồng đó trước và sau khi sửa, còn tôi đọc tab network. Không có đo đạc tự động, không có bộ đếm request. Bạn không chạy lại được, và 100% ở đây nghĩa là "mọi lần bấm trong phiên đó", không phải một tỷ lệ đo theo thời gian.

- **Lần bấm Tăng bị từ chối 422:** 100% → 0%
- **Lỗi hiện ra cho người vận hành thấy:** 0 → hiện hết
- **Số phần tử mà selector khớp:** 0 → 1

Thứ bạn *chạy lại được* là cơ chế, tôi dựng lại từ đầu thành một trang HTML tĩnh trong [`bench/selector-jquery-lot-len-staging/`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/selector-jquery-lot-len-staging): vẫn cấu trúc tab đó, selector sai đặt cạnh selector đúng, và một phản hồi 422 giả mà bạn tự chọn cho nó rơi vào ô đang ẩn hay rơi xuống khung cảnh báo chung. Mở trong trình duyệt là thấy thông báo biến mất ngay trước mắt.

Có một thứ tệ đi. Với một ô đang hiển thị thì thông báo bây giờ có hai đường để tới nơi, nên cái luật "chỉ một trong hai chỗ" là thứ chịu lực. Làm hỏng nó thì người vận hành đọc cùng một lời phàn nàn hai lần.

Và có một con số không nhúc nhích: **số test tự động phủ đường này: 0 → 0.** Trang repro là một bản trình diễn, không phải một bài test. Ngày mai selector hỏng lại thì CI vẫn xanh.

---

## Giới hạn, và điều tôi sẽ làm khác

Phép kiểm tra tôi viết chỉ hỏi xem phần tử có đang được vẽ ra hay không. Nó bắt được trường hợp tab đang ẩn, tức là đúng con bug của tôi. Nó không bắt được ô đã cuộn ra ngoài tầm nhìn, ô bị một lớp phủ che mất, hay ô nằm trong một khối đang gập lại nhưng về mặt bố cục vẫn tồn tại.

Khung cảnh báo chung cũng chỉ tốt ngang cái hợp đồng dữ liệu lỗi: nó xử lý được thông báo có gắn tên field. Còn lỗi server trả về không kèm tên field, hoặc kèm tên một field form này không có, thì vẫn chưa có chỗ nào để hiện — tôi chưa xử lý, và cũng chưa biết nó xảy ra thường xuyên đến đâu.

Điều tôi sẽ làm khác thì không liên quan gì đến selector. Tôi mất cả đoạn đầu đi soi server chỉ vì con 422 chỉ về hướng đó, trong khi tín hiệu mạnh nhất tôi đang cầm là **người dùng không thấy gì cả** — mà "không có phản hồi" thì bao giờ cũng là chuyện của phía giao diện. Giờ tôi coi sự im lặng là một con bug riêng, ghi thành một mục riêng, tách khỏi nguyên nhân sinh ra nó. Cái selector chỉ tốn một dòng để sửa; chính sự im lặng mới làm nó đắt đến thế lúc đi tìm.

Một hệ thống hỏng mà kêu to thì có người đến sửa. Một hệ thống hỏng mà im lặng lịch sự thì chỉ nhận về một dòng báo lỗi: "bấm vào không thấy gì".
