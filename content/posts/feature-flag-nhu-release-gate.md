---
title: "Feature flag như cổng release liên team"
date: 2026-09-22T09:00:00+07:00
draft: false
description: "Biết trước một tính năng sẽ fail 100% nếu bật sớm, vẫn ship đúng lịch — bằng cách biến feature flag thành thứ tự deploy bắt buộc cho team khác."
tags: ["feature-flags", "release-engineering", "cross-team", "incident-prevention"]
categories: ["Vận hành phát hành"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/feature-flag-nhu-release-gate/cover.png"
    alt: "Sơ đồ feature flag làm cổng chặn giữa deploy của team A và team B"
---

Có một loại bug tôi chưa bao giờ thấy trong log, vì nó chưa từng chạy: tôi đọc ra nó
từ đúng hai dòng code, trước khi viết dòng code đầu tiên của mình. Câu hỏi không phải
"sửa thế nào" — mà là "ship một tính năng biết chắc sẽ fail 100% nếu bật sớm thì tính
là xong hay chưa xong?"

---

## Bối cảnh

Đầu tháng 9 năm nay, tôi phụ trách phần chức năng cho một chế độ khuyến mãi mới trong
một hệ thống bán hàng: mỗi sản phẩm trong chương trình được cấp một quota bán riêng, và
hệ thống phải từ chối đơn khi quota đó hết. Tính năng có lịch ship định sẵn, phần việc
của tôi nằm trong lịch đó.

Việc của tôi giới hạn trong service quản lý quota — nơi tôi có toàn quyền sửa. Nhưng đơn
hàng đi qua một service khác, do team khác giữ. Service đó phải đọc đúng giá trị quota
mới thì tính năng mới bán được hàng. Tôi không có quyền merge code vào repo của họ.

## Xung đột

Trước khi viết dòng code nào, tôi đọc code của service kia để xem nó đọc quota như thế
nào. Hai chỗ trong cùng một repo đọc giá trị rỗng (`NULL`) theo hai nghĩa trái nhau:

1. Chỗ kiểm tra đơn ép `NULL` thành số 0 — `Number(quota_total ?? 0)`. Rỗng nghĩa là
   "hết hàng", đơn bị từ chối.
2. Chỗ hiển thị coi `NULL` là "không giới hạn". Trang bán hàng vẫn hiện sản phẩm còn
   mua được.

Chế độ mới không mã hóa bằng `NULL`. Nó có một cột riêng ghi rõ nguồn hàng: quota riêng
hay kho chung. `NULL` ở cột quota chỉ là hệ quả — dòng bán theo kho chung thì không có
quota riêng để ghi. Nhưng service kia chưa đọc cột nguồn hàng đó. Nó chỉ thấy `NULL`,
và đọc `NULL` theo hai nghĩa trái nhau. Soát lại tài liệu thiết kế thì con số còn tệ
hơn hai: `NULL` được đọc là 0 ở ba chỗ và là vô hạn ở ba chỗ khác, rải trên hai hệ.

Hậu quả tôi đọc ra được từ hai dòng code: bật chế độ mới lên là mọi đơn bán theo kho
chung bị từ chối, trong khi màn hình vẫn bảo còn hàng.

Tôi không sửa được chỗ đó — không phải repo của tôi, không phải team của tôi. Vì sao hai
chỗ trong cùng một repo lệch nhau, tôi không biết và cũng không đi hỏi; bài này chỉ nói
được thứ tôi đọc thấy. Team kia không sai khi chưa sửa: hậu quả này chỉ xuất hiện khi
chế độ mới bật, mà chế độ đó lúc ấy chưa tồn tại.

Hai điều đều đúng, nhưng không thể cùng đúng. Thứ nhất: lịch ship đã định, và phần việc
của tôi không có lý do gì để trễ. Thứ hai: bật tính năng trước khi team kia sửa xong
nghĩa là 100% đơn bán theo kho chung bị từ chối ngay lần đầu khách dùng — một thất bại
công khai, ở đúng chỗ đáng lẽ phải gây ấn tượng.

## Quyết định của tôi

Tôi ship đủ code và migration đúng lịch, nhưng để feature flag mặc định **tắt** trên
production. Rồi tôi viết điều kiện được phép bật flag thành một thứ tự deploy bắt buộc
cho team kia, hai bước, không đổi chỗ:

1. **Rào phần kho đã giữ chỗ trước.** Phần kho đã cấp cho các chương trình khác phải
   được tách khỏi kho chung, để đơn "không giới hạn" không bán vào đó.
2. **Nới cách đọc `NULL` sau.** Khi kho đã rào, chỗ kiểm tra đơn mới được đổi: rỗng
   không còn bị coi là hết hàng, mà đọc theo cột nguồn hàng.

Làm ngược thứ tự thì ra lỗi ngược chiều. Bật sớm là từ chối hết. Nới trước rào sau là
bán vượt kho (oversell) 100%. Lý do: giữa hai bước, đơn theo kho chung không bị quota
riêng chặn, cũng không bị kho đã giữ chặn.

Một ví dụ bằng số giả định, để thấy vì sao thứ tự quan trọng. Giả sử kho chung còn 10
đơn vị, và cả 10 đã được giữ cho một chương trình khác. Nới `NULL` trước khi rào: đơn
theo kho chung đọc ra "không giới hạn" và bán được cả 10 đơn vị đó — hàng của chương
trình kia. Rào trước rồi mới nới: cùng đơn ấy thấy kho chung còn 0 và bị từ chối đúng.

Flag ở đây không dùng để thử nghiệm dần. Nó là cách viết một phụ thuộc liên team thành
thứ kiểm tra được: flag còn tắt nghĩa là điều kiện chưa đủ, và điều kiện nằm trong một
tài liệu ai cũng đọc được.

## Cái giá

Tới lúc viết bài này, flag vẫn tắt. Tính năng đã có trên production — nhưng với người
dùng thật thì chưa có gì thay đổi. Nhìn từ ngoài, việc đó giống
một tính năng chưa xong, dù phần việc của tôi đã hoàn tất đúng lịch. Cái "xong" của cả
tính năng giờ phụ thuộc vào lịch của một team tôi không điều khiển được.

Tôi cũng làm thêm một việc không có trong phạm vi ban đầu: viết tài liệu thứ tự deploy
cho một repo không phải của mình, đủ rõ để team kia làm theo mà không cần tôi ngồi cạnh.
Và giá trị kinh doanh của chế độ khuyến mãi mới bị hoãn đúng bằng khoảng thời gian chờ
team kia deploy. Bao lâu, bao nhiêu đơn — tôi chưa có con số, vì việc chưa kết thúc.

## Điều tôi làm khác đi

Nếu làm lại, tôi sẽ đọc code của service phụ thuộc **trong buổi thiết kế**, trước khi
viết bất kỳ dòng code nào của mình — không phải sau khi đã nhận việc rồi mới phát hiện
ra. Câu hỏi "service kia đọc giá trị rỗng như thế nào" lẽ ra phải là một mục bắt
buộc trong review thiết kế liên team, chứ không phải thứ một người đào ra vì thói quen
đọc code trước khi sửa.

Tôi cũng sẽ đề xuất coi flag như một hợp đồng có hai bên ký từ ngày đầu, thay vì một
mình tôi đặt điều kiện rồi chuyển sang cho team kia. Thứ tự deploy được thống nhất lúc
thiết kế thì nằm trong backlog của cả hai bên ngay từ đầu, không phải một tài liệu bên
này viết rồi chờ bên kia đọc.

---

Bạn có từng phải ship một tính năng biết chắc sẽ fail nếu bật sai thời điểm chưa? Cách
bạn thuyết phục bên phụ thuộc là gì?
