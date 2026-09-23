---
title: "Merge chỉ có đúng hai cha. Một dòng lấy từ nhánh thứ ba làm sập toàn bộ route API"
date: 2026-09-23T14:42:00+07:00
draft: false
description: "Conflict ở file đăng ký middleware được xử lý bằng cách copy nguyên file từ một nhánh thứ ba. Một dòng middleware đi theo, class của nó thì không, và /api/* trả 500 gần 18 tiếng."
tags: ["git", "merge-conflict", "laravel", "incident", "code-review"]
categories: ["Kỹ thuật"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/merge-conflict-copy-nhanh-thu-ba/cover.png"
    alt: "Một merge commit có hai cha, và một nhánh thứ ba đẩy thêm một dòng vào file đã resolve"
---

Trong 17 tiếng 55 phút, mọi route dưới `/api/*` trên staging đều trả về lỗi fatal. Lần merge gây ra chuyện đó lên nhánh lúc 17:18 chiều; bản fix chấm dứt nó lên lúc 11:13 sáng hôm sau. Con số này lấy từ repo riêng và log server, bạn không kiểm chứng được, nên cứ đọc nó như lời kể của tôi.

Bản thân lần merge rất bình thường: một nhánh feature vào staging, một conflict, ở file đăng ký HTTP middleware. Conflict là thật, hai bên cùng thêm một dòng ở đúng một vị trí. Thứ hỏng không phải là conflict. Thứ hỏng là cách conflict được "giải quyết", rồi cách kết quả được kiểm và được coi là xong.

---

## Mổ xẻ: một lần resolve cho nhanh, và một phép kiểm chỉ nhìn một phía

HTTP kernel của framework là một danh sách. Middleware nào chạy trên request thì có tên ở đó, theo thứ tự. Staging đã thêm một dòng vào nhóm API. Nhánh feature thêm một dòng khác, cùng vị trí. Git dừng lại và hỏi giữ bên nào.

Câu trả lời là không bên nào cả. Nhánh development, nhánh thứ ba không nằm trong hai bên đang merge, lúc đó đã có sẵn dòng của phía feature, vì feature đã được gộp vào đó từ trước. Thế nên nguyên file được copy từ development đè lên file đang conflict, rồi add, rồi commit. Nhanh hơn ngồi đọc từng dấu conflict, và trông thì như lần merge này đã có ai làm xong ở đâu đó rồi.

Chưa có ai làm cả. Development không có dòng của phía staging, nên lần copy làm rơi mất dòng đó. Đây là lớp hỏng thứ nhất: một lần resolve đáng ra phải giữ cả hai bên thì chỉ giữ được một.

Lớp thứ hai mới là lớp gây sập. Development còn có thêm một dòng nữa trong nhóm đó: một ticket khác đã đăng ký ở đây một middleware giới hạn tần suất (rate limit). Middleware này dựa trên một package được cài ở development và chưa bao giờ được cài ở staging. Lần copy mang theo dòng đăng ký, và chỉ dòng đăng ký. Trên staging, kernel giờ gọi tên một class không tồn tại trên đĩa. Trên staging, mỗi request đi qua nhóm API đều đụng vào class còn thiếu đó, nên mọi request API đều hỏng theo cùng một kiểu.

Vì sao phép kiểm sau lúc resolve không bắt được? Vì câu hỏi nó đặt ra. Phép kiểm là một lần diff file đã resolve với nhánh được merge vào, đọc với đúng một câu hỏi trong đầu: *có dòng nào bị mất không?* Mọi dòng trong diff đều là dấu `+`. Không có dấu `-`. Đạt. Câu hỏi chưa bao giờ được hỏi mới là câu quan trọng: *mỗi dòng `+` đó có thật sự thuộc về một trong hai bên đang merge không?* Có một dòng thì không. Bản fix đầu khôi phục dòng đã rơi, rồi được kiểm y theo cách một phía ấy: không dòng nào mất, đạt. Dòng lạ vẫn nằm trong file. Phải nhờ log server mới lòi ra.

Lần thứ hai tôi kiểm theo cách khác, và đó là cơ chế mà phần còn lại của bài xoay quanh. Một merge commit có đúng hai cha, và git nói cho bạn biết đó là hai commit nào:

```bash
git show -s --format='%P' <merge-commit>      # hai hash, p1 và p2
git merge-base p1 p2                          # chỗ hai nhánh tách ra
```

So với merge-base đó, cha thứ nhất thêm một số dòng, cha thứ hai thêm một số dòng. File đã resolve chỉ được phép thêm hợp của hai tập đó, không hơn. Dòng `+` nào trong `base..merge` mà không phải là dòng `+` trong `base..p1` hay `base..p2` thì đến từ chỗ khác. Dòng `-` cũng theo đúng luật ấy. Ba mốc so sánh thay cho một, và mốc nào cũng do chính lần merge định ra. Kiểm theo cách đó, bản fix thứ hai cho ra không dòng nào không giải thích được nguồn gốc.

---

## Đánh đổi (Trade-offs)

- **Merge lại từ đầu, resolve bằng tay từ dấu conflict.** Làm được, và sẽ ra đúng cái file cần có. Tôi không chọn, vì lần merge hỏng đã nằm trên nhánh rồi, và tôi muốn một phép kiểm chạy được trên bất kỳ merge commit nào *sau khi nó đã xảy ra*, không chỉ trên lần merge tôi sắp làm. Resolve lại thì sửa được lần này; kiểm nguồn gốc thì trỏ được vào mọi lần merge đã nằm sẵn trên nhánh.
- **Giữ cách diff một phía, đọc kỹ hơn.** Loại. Đọc kỹ hơn không phải là một cơ chế kiểm soát. Diff với một mốc duy nhất không phân biệt được "dòng cha bên kia thêm" với "dòng nhánh thứ ba thêm", vì cả hai đều hiện ra là `+`. Thông tin đó không nằm trong bản diff ấy; nhìn chăm chú đến đâu cũng không làm nó xuất hiện.
- **So với cả hai cha thật** (đã chọn). Cái giá: sáu lệnh `git diff` tại ba mốc so sánh, và 38 dòng shell. Kèm theo là một luật tôi giờ coi là tuyệt đối. Không bao giờ lấy nội dung từ một nhánh không phải là một trong hai cha để resolve conflict giữa hai cha đó, dù nhánh kia trông "đầy đủ" đến mức nào. Phép kiểm này so tập dòng, nên mù với thứ tự; tôi sẽ quay lại điểm này ở cuối.
- **Cài package còn thiếu lên staging.** Loại. Làm vậy thì dòng lạ hết gây sập nhưng vẫn là dòng lạ. Cái rate limit đó thuộc một ticket khác. Làm triệu chứng biến mất không giống với bỏ đi dòng không có quyền nằm ở đó.

---

## Kết quả đo được

Ở đây có hai loại bằng chứng, và tôi tách chúng ra.

Từ sự cố, thứ bạn không chạy lại được:

| Chỉ số | Trước | Sau |
|---|---|---|
| `/api/*` trên staging trả 500 | 17h55' | 0 lỗi sau bản fix thứ hai |
| Kiểm lần một (một mốc, "có dòng nào mất không?") | 0 dòng mất, lọt 1 dòng thừa | |
| Kiểm lần hai (cả hai cha thật) | | 0 dòng không giải thích được nguồn gốc |

Từ bench, thứ bạn chạy lại được. [`bench/merge-conflict-copy-nhanh-thu-ba`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/merge-conflict-copy-nhanh-thu-ba) dựng một repo git nhỏ từ đầu, không có dòng code công ty nào: một manifest middleware 12 dòng, bốn nhánh (base, staging, feature, development), một conflict thật, và cùng một lần merge được resolve theo ba cách. Một lệnh chạy hết và ghi kết quả ra.

| Cách resolve | Kiểm một phía: dòng `-` so với staging | Kiểm hai cha: dòng lạ | Kiểm boot |
|---|---|---|---|
| Đúng, giữ cả hai bên | 0, đạt | 0, đạt | đạt |
| Copy file từ development | 0, **đạt, mà sai** | 1 dòng thêm, `RateLimitByPlan`, không đạt | không đạt, thiếu class |
| Đúng nhưng rơi một dòng gốc | 1, không đạt | 1 dòng mất, `StartSession`, không đạt | đạt |

Dòng thứ ba là đối chứng: nó cho thấy phép kiểm một phía vẫn bắt được đúng thứ nó được thiết kế để bắt. Dòng thứ hai là sự cố sau bản fix đầu: đủ cả hai bên, thừa một dòng lạ. Phép kiểm một phía đạt ở đó là do cấu tạo của nó, không phải do xui. Lần copy ban đầu của sự cố còn làm rơi dòng của staging, tức là lỗi ở dòng thứ ba; bench tách hai lớp ra hai kịch bản riêng để điểm mù của từng phép kiểm hiện ra rõ. Kiểm boot đóng vai lỗi 500: mỗi tên trong manifest phải có file class trong cây của commit đó. Hash commit được ghim cố định, nên chạy hai lần trên hai máy cho ra kết quả giống nhau từng byte.

---

## Giới hạn, và điều tôi sẽ làm khác

**Thứ phép kiểm không thấy.** Nó so tập nội dung dòng, không so vị trí. Một dòng mà cả hai cha đều có hợp lệ, nhưng lần resolve xếp sai chỗ, thì vẫn qua. Trong danh sách middleware, thứ tự chính là hành vi, nên đây là một lớp bug thật mà phép kiểm bỏ sót. Nó cũng chạy theo từng file; một lần copy chạm nhiều file thì cần vòng lặp qua các đường dẫn đã đổi. Và nó coi khoảng trắng là nội dung, đúng với manifest nhưng sinh báo nhầm với file khác. Bench chỉ có 12 dòng và bốn nhánh; nó cho thấy âm tính giả có tồn tại, không nói gì về cách phép kiểm cư xử trên một file có hàng trăm hunk conflict.

**Thứ bench không cho thấy.** Không có framework, không có PHP, không có lỗi 500. Kiểm boot chỉ chứng minh điều kiện "đã đăng ký mà không tồn tại", không phải cú sập. Và không gì ở đây tái lập được 17h55'; con số đó nằm trong một file log bạn không đọc được.

**Điều tôi sẽ làm khác.** Lần resolve đó đi đường tắt vì nội dung đúng đang nằm sẵn, nhìn thấy được, ở một nhánh khác. Lần sau gặp lại cám dỗ ấy, tôi sẽ coi nó là dấu hiệu: nếu nhánh thứ ba có đáp án, thì hai cha cộng lại cũng có đúng đáp án đó, và thứ duy nhất nhánh thứ ba có thể thêm vào là thứ không thuộc về đây. Và tôi sẽ chạy diff hai cha trước khi push bất kỳ lần resolve conflict nào, không đợi log bảo mới chạy.
