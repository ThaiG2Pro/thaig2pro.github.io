# Spec sản xuất content — Blog Hoang Nguyen Thai

Tài liệu gốc. Mọi skill trong `.claude/skills/content-*` đều trỏ về đây.
Mục tiêu: blog là portfolio kỹ thuật phục vụ ứng tuyển big/mid tech, đồng thời là
nguồn nguyên liệu cho content video/social.

---

## 1. Dây chuyền 5 tầng

```
Tầng 0 Bắt      → drafts/inbox.md           (ghi nguyên liệu trong ngày)
Tầng 1 Cổng đo  → bench/<slug>/             (số + phương pháp + script reproduce)
Tầng 2 Phân luồng→ chọn thể loại A/B/C/D theo bằng chứng đang có
Tầng 3 Bản gốc  → content/posts/<slug>.md   (+ bản dịch)
Tầng 4 Dẫn xuất → career/ , drafts/video-<slug>.md
Tầng 5 Rà soát  → mỗi quý, soi lỗ hổng behavioral
```

Trạng thái từng mục nằm ở `pipeline/state.json`. Không sửa tay — dùng skill.

---

## 2. Tầng 0 — Bắt nguyên liệu

Ghi vào `drafts/inbox.md` **trong ngày** khi gặp một trong 4 thứ:

1. Một thứ vỡ / chậm / sai → ghi triệu chứng + con số **trước khi sửa**
2. Một quyết định kỹ thuật có ≥2 lựa chọn → ghi các lựa chọn và lý do chốt
3. Một con số vô tình nhìn thấy (query 4.2s, ảnh 300MB, bill 12 USD)
4. Một lần hiểu sai rồi vỡ ra

**Lý do:** nút thắt không phải khả năng viết mà là quên mất chuyện gì đã xảy ra.
Con số "trước khi sửa" không dựng lại được sau 2 tuần — mà đó chính là con số làm
bài viết có giá trị.

---

## 3. Tầng 1 — Cổng đo (gate bắt buộc)

Một mục chỉ được lên lịch viết khi trả lời được **cả 3**:

| Câu hỏi | Không đạt thì |
|---|---|
| Con số là bao nhiêu (before/after)? | task = "đi đo", không phải "viết bài" |
| Đo bằng gì (công cụ, dataset, số lần chạy)? | bổ sung phương pháp rồi đo lại |
| Người khác chạy lại được không (script ở đâu)? | viết script vào `bench/<slug>/` |

**Lý do:** chặn số liệu bịa trên artifact công khai mà interviewer sẽ đào đúng vào đó.
Một bài kèm script reproduce mạnh hơn hẳn bài chỉ có kết luận.

Ngoại lệ duy nhất: thể loại D (storytelling) không có số — bù lại phải có
**mốc thời gian, vai trò cụ thể, và quyết định bạn đã ra**.

### Khẳng định về bối cảnh cũng phải truy nguồn

Cổng trên chỉ soi **con số**. Nhưng một bài kỹ thuật còn khẳng định rất nhiều thứ về
codebase và về quy trình mà không dùng đến chữ số nào — và những câu đó lọt sạch. Hai
dạng đã thực sự lọt lên blog này (L-014, L-015):

| Dạng | Ví dụ thật đã lọt |
|---|---|
| Phủ định về năng lực | *"dự án chưa có bộ khung test trình duyệt nào"* — sai, Playwright có sẵn |
| Lượng từ thay cho số đếm | *"modal này có **vài** ô như vậy"* — chưa ai đếm, inbox ghi đúng một |

Cả hai đều **có lợi cho tác giả**: câu thứ nhất giải thích vì sao không làm việc lẽ ra
phải làm, câu thứ hai phóng to vấn đề vừa đủ để phương án đã chọn nghe hợp lý. Đó là lý
do chính tác giả không muốn đi kiểm.

**Hành động kiểm được:** liệt kê mọi câu nói dự án **có** hay **không có** thứ gì, mọi
câu ước lượng công sức ("mất vài ngày"), và mọi lượng từ không đếm — **vài, nhiều, hầu
hết, thường xuyên, một số, hiếm khi**. Với mỗi câu, ghi **lệnh đã dùng để kiểm**: một
dòng `git log`, `package.json`, hay một lần `grep`. Không có lệnh thì chọn một trong ba:
đổi thành con số đã đếm · hạ xuống điều chứng minh được · viết thẳng *"tôi không kiểm
lại chỗ này"*.

Soi trước hai vị trí, vì lỗi này gần như luôn nằm ở đó: câu **loại một phương án** trong
mục Đánh đổi, và câu **giải thích vì sao bug lọt**.

**Định nghĩa hệ thống cũng là khẳng định** (L-018, L-019 — lặp hai lần trong một bài).
Câu dạng *"`X` nghĩa là …"*, *"chế độ mới là …"*, *"trước đây … / bây giờ …"* về dữ liệu
hay tính năng của hệ thống phải trỏ được về một dòng inbox ghi đúng điều đó — không suy ra
từ hướng sửa, không suy ra từ tên cột. Hành động kiểm được: liệt kê mọi câu định nghĩa
trong mục Bối cảnh và mục cơ chế, ghi số dòng inbox bên cạnh; không có dòng thì hỏi tác
giả và **ghi câu trả lời vào inbox trước**, rồi mới viết. Inbox thiếu thì bổ inbox, không
bổ bằng suy luận.

**Sự kiện kể cũng là khẳng định** (L-016 ở bài D, L-061 lặp ở bài A). Mọi câu kể một lần
quan sát hay một hành động cụ thể (một ảnh chụp, một lần chạy, một dòng log, một lần fix,
một người đồng ý hay hỏi lại) phải trỏ được về một dòng inbox kể đúng lần đó. Hành động
kiểm được: đếm số lần quan sát/hành động trong bài, đếm số lần trong mục inbox; bài nhiều
hơn inbox là có sự kiện tự sinh. Sự kiện mang theo con số (89, "mười bốn phút") **không**
được coi là đã qua cổng số chỉ vì các số chính của bài đã truy được nguồn.

---

## 3b. Cổng bảo mật nghề nghiệp (áp dụng từ Tầng 0)

Nguyên liệu tốt nhất đến từ công việc thật, nên rủi ro lớn nhất cũng đến từ đó. Tách
làm hai vùng và **không bao giờ để lẫn**:

| Vùng | Chứa gì | Git |
|---|---|---|
| `drafts/inbox.md`, `career/` | ticket ID, mã SKU thật, đường dẫn module, commit hash, tên sản phẩm nội bộ | **không commit** |
| `pipeline/state.json`, `content/posts/`, `bench/` | đã khử định danh | **công khai** |

Trước khi ghi bất cứ thứ gì sang vùng công khai, thay:

- ID nội bộ (mã dự án, số ticket, commit hash) → bỏ hẳn
- Mã hàng/mã khách thật → `SKU-A`, `CUST-1`
- Đường dẫn module nội bộ → mô tả vai trò: "service tính tồn khả dụng"
- Tên sản phẩm/khách hàng/đồng nghiệp → mô tả chung: "một hệ thống bán hàng có chương
  trình khuyến mãi"
- **Log và history** (`pipeline/state.json`, `lessons/`) cũng là vùng công khai. Khi ghi
  "đã khử định danh", **không liệt kê thứ đã khử** — viết "đã khử định danh" rồi dừng.
  Kiểm: `grep -nE "khử định danh \(|đã loại \(" pipeline/state.json lessons/*.md` phải
  trả về rỗng (L-055).
- **Code nguyên văn từ repo mình không sở hữu** là định danh (L-057). Trong bài chỉ được
  có hai loại code: bản mình dựng lại trong `bench/<slug>/`, hoặc mô tả cơ chế bằng lời
  ("chỗ kiểm tra đơn ép quota rỗng thành 0"). Tên cột, tên hàm, tên biến thật của hệ khác
  → bỏ. Kiểm: mỗi hit của `grep -nE '`[^`]*[a-z]_[a-z][^`]*`' content/posts/<slug>*.md`
  phải chỉ được về `bench/`.

**Giữ nguyên:** con số, tỷ lệ, cơ chế, quyết định, cái giá phải trả. Đó mới là thứ làm
bài có giá trị — và không có thứ nào trong đó cần định danh để hiểu được.

Phép thử trước khi publish: *người trong câu chuyện đọc được thì có ổn không, và người
ngoài có suy ra được đây là công ty nào không?* Một câu trả lời "không chắc" nghĩa là
chưa khử đủ.

**Quét tự động.** `scripts/scan-identifiers.sh` chạy qua git hook `pre-commit` trên
**mọi file sắp commit**, không riêng `content/`. Hai rò rỉ thật đều nằm ngoài thư mục
bài viết — một trong `pipeline/state.json`, một trong chính mục luật này — nên kiểm
bằng mắt ở tầng bài viết là không đủ.

- Mẫu chung nằm trong script (file công khai).
- Từ khóa riêng của công ty nằm ở `.git/identifiers.local` — **không bao giờ commit**.
  Gặp tên dự án/sản phẩm/đồng nghiệp mới thì thêm một dòng regex vào đó.
- Dương tính giả: thêm chuỗi `scan-ok` vào cuối dòng, hoặc `git commit --no-verify`.
- Sau khi clone lại: `git config core.hooksPath .githooks` (git config không theo repo).

Kiểm tra thêm hợp đồng lao động/NDA của bạn về việc viết công khai chi tiết kỹ thuật
công việc. Khử định danh làm giảm rủi ro nhưng không thay thế được việc đọc điều khoản.

---

## 4. Tầng 2 — Phân luồng theo bằng chứng

Nhìn vào bằng chứng đang cầm, **không** nhìn chủ đề.

| Bằng chứng | Thể loại | Ngôn ngữ bản gốc | Đích chính | Đích phụ |
|---|---|---|---|---|
| Hệ thống thật + số trước/sau + quyết định của bạn | **A. Case study** | EN đầy đủ | CV + behavioral | Video |
| Benchmark tự chạy + phương pháp đo | **B. Benchmark/deep-dive** | EN đầy đủ | CV + traffic | Video |
| Kiến thức + ví dụ đời thường, chưa đo | **C. Giới thiệu công nghệ** | VI đầy đủ | Video + traffic | Traffic EN |
| Trải nghiệm ngành/con người, không có số | **D. Storytelling** | VI đầy đủ | Video + behavioral | — |
| Có code nhưng chưa đo gì | **Chưa viết** | — | → quay lại Tầng 1 | — |

**Lý do chọn ngôn ngữ gốc theo thể loại:** viết đầy đủ 2 thứ tiếng cho mọi bài là gấp
đôi công và sẽ bỏ cuộc sau 3 bài. Bài recruiter big tech đọc thì EN là bản gốc chất
lượng cao; bài nuôi khán giả VN thì ngược lại. Bản còn lại là bản rút gọn 60-70%.

---

## 5. Tầng 3 — Xương sống bắt buộc (mọi thể loại)

- Mở bài bằng **nỗi đau hoặc câu hỏi + con số**, không bằng tên công cụ
- Mọi khẳng định định lượng truy được về phương pháp đo ở Tầng 1
- Có mục **Đánh đổi (Trade-offs)** — không bài nào khen một chiều
- Ngôi "tôi" gắn với **quyết định cụ thể** bạn đã ra
- Tự nêu **giới hạn / thứ chưa giải quyết được**

Điểm cuối là tín hiệu senior mạnh nhất và rẻ nhất để làm.

### Giải thích mắt xích trước khi dùng cách nói tắt

Bài A do người đã sống trong sự cố viết ra, nên rất dễ bỏ qua các mắt xích mà với tác
giả là hiển nhiên. Người đọc không có bối cảnh đó, và một mắt xích thiếu làm hỏng cả
đoạn sau. Ba chỗ hay thiếu nhất:

1. **Hậu quả, bằng một ví dụ có số.** Đừng chỉ nói "bán vượt tồn". Viết: "kho còn 10,
   hai request cùng đọc thấy 10, cả hai cùng ghi, hệ thống tưởng bán 10 nhưng đã hứa
   giao 20."
2. **Vì sao không ai phát hiện ra.** Test xanh và review duyệt là hai chuyện khác nhau,
   mỗi chuyện cần một câu giải thích riêng. Không giải thích thì người đọc nghi ngờ cả
   câu chuyện.
3. **Vì sao công cụ lại cư xử như vậy.** "sqlite nuốt `FOR UPDATE`" là kết luận, không
   phải lời giải thích. Phải nói sqlite là database một file nên không cần cơ chế đó,
   và Laravel trả về chuỗi rỗng thay vì báo lỗi.

Phép thử: đưa bài cho một kỹ sư không làm trong dự án. Chỗ nào họ hỏi "cái này là gì",
chỗ đó thiếu một mắt xích — kể cả khi từ ngữ đã đúng.

### Một câu, tối đa hai khái niệm mới

Giải thích đủ mắt xích rồi thì lỗi tiếp theo là nhồi hết chúng vào một câu. Tác giả đọc
trôi vì đã biết trước cả chuỗi; người đọc phải giữ đồng thời từng mảnh trong đầu.

**Hành động kiểm được:** với mỗi câu dài, đếm số **khái niệm kỹ thuật mới** nó bắt người
đọc giữ — tên biến, tên hàm, trạng thái, giá trị, hệ quả. Quá **2** thì tách câu hoặc
chuyển thành danh sách đánh số. Không cắt chữ, chỉ chẻ câu.

| Nén quá tay (5 khái niệm) | Tách ra |
|---|---|
| "Gọi `.data('type')` trên một tập rỗng thì nhận về `undefined`, đoạn ráp dữ liệu rơi vào nhánh mặc định, nên mọi lần gửi đều đi ra dưới dạng mặc định: giảm, số lượng 0." | "Gọi `.data('type')` trên một tập rỗng thì trả về `undefined`. Đoạn ráp dữ liệu vì thế rơi vào nhánh mặc định. Kết quả: mọi request đều được gửi đi dưới dạng giảm, số lượng 0." |

Một mệnh đề liệt kê từ ba chi phí / ba lý do trở lên cũng tính là nén quá tay — chẻ bằng
dấu chấm phẩy có dẫn nhập ("Cái giá phải trả có ba phần: ...") hoặc tách thành bullet.

### Bằng chứng của thể loại A: tách hai loại

Bài A đến từ hệ thống riêng tư của công ty, nên **không tái hiện công khai được**.
Đừng gộp hai thứ khác nhau vào một câu "nguồn: bench/":

| Loại | Là gì | Viết thế nào trong bài |
|---|---|---|
| **Số đo nội bộ** | con số từ codebase riêng tư | nói thẳng "đo trong codebase riêng tư, bạn không chạy lại được, cứ trừ hao khi đọc" |
| **Cơ chế tái hiện** | bản dựng lại từ đầu trong `bench/<slug>/`, không dùng code công ty | link GitHub bấm được + một lệnh chạy |

`bench/` nằm trong **repo blog công khai của bạn**, không phải repo công ty, và không
chứa dòng code nào của công ty — nó là bản dựng lại cơ chế bằng schema và tên bảng tự
đặt. Không cần tạo repo riêng.

Tự khai "số này bạn không kiểm chứng được" làm bài **đáng tin hơn**, không phải yếu đi:
nó cho thấy bạn phân biệt được cái mình chứng minh được và cái mình chỉ có thể kể lại.

### Khung riêng từng thể loại

| Thể loại | Khung |
|---|---|
| A | Nỗi đau kinh doanh → Mổ xẻ (đọc log, tìm bottleneck) → Đánh đổi → Kết quả đo được |
| B | Câu hỏi → Phương pháp đo → Số liệu thô → Diễn giải → Giới hạn phép đo |
| C | Hook → 4 mục H2 đánh số → sơ đồ → Trade-offs → Đúc kết → CTA |
| D | Bối cảnh → Xung đột → Quyết định của tôi → Cái giá → Điều tôi làm khác đi |

Chi tiết từng khung: `.claude/skills/content-write/references/genre-*.md`

### Giọng văn

| Quy tắc | Đúng | Sai |
|---|---|---|
| Ngôi xưng | "tôi" (trải nghiệm), "chúng ta" (hướng dẫn) | "mình", "các bạn ơi" |
| Thuật ngữ | Việt + Anh trong ngoặc: "Tính Đóng Gói (Encapsulation)" | chỉ một thứ tiếng |
| Ẩn dụ | trong ngoặc kép: "đầu độc" Context, "chiều lòng" phần cứng | ẩn dụ dài, không ngoặc |
| Khẳng định | số liệu + nguồn đo | "rất nhanh", "đáng kể" |
| Bullet | mở đầu bằng thuật ngữ in đậm: `- **Page split:** ...` | bullet trần |
| Emoji | không dùng trong thân bài | 🚀 rải rác |

### Quy ước kỹ thuật

- Front matter **YAML** (`---`), đủ 10 trường: title, date, draft, description, tags,
  categories, author, showToc, TocOpen, cover
- Đường dẫn ảnh **luôn có `/` đầu**: `/images/posts/<slug>/<tên>.png`
- Thư mục bench **trùng slug bài**: `bench/<slug>/` — để rà soát tự động khớp được
- Tham chiếu `bench/` trong bài phải là **link GitHub bấm được**, không phải đường dẫn
  trần: người đọc đang ở trên trang blog, không có repo trong tay. Dạng:
  `https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/<slug>`.
  Bằng chứng không bấm vào được thì không phải bằng chứng.
- Ảnh kèm caption in nghiêng ngay dưới: `*Hình 1: ...*`
- `---` ngăn cách mọi section H2; mỗi H2 có ít nhất 1 code block hoặc 1 bullet list
- `tags` giữ tiếng Anh ở cả hai bản; `categories` dịch theo ngôn ngữ

### Độ dài

Bản gốc **900-1200 từ** — đây là mốc định hướng, không phải trần cứng. Vượt mốc không
phải lý do để cắt; chỉ cắt khi tìm được **ý trùng** hoặc đoạn không phục vụ ai. Cắt chữ
cho vừa một con số là cách chắc chắn nhất để sinh ra văn cứng.

Bản còn lại: cắt **ý** thừa, đừng cắt **chữ**. Bỏ được cả một
đoạn ví dụ địa phương thì bỏ; nhưng đã giữ ý nào thì viết nó cho ra câu hoàn chỉnh.

Tiếng Việt cần nhiều chữ hơn tiếng Anh cho cùng một ý, nên bản VI dài hơn bản EN là
bình thường và không phải lỗi. Ép bản VI xuống bằng số từ của bản EN là nguyên nhân
trực tiếp sinh ra văn dịch cứng.

### Viết tiếng Việt cho ra tiếng Việt

Bản VI không phải bản dịch câu-đối-câu của bản EN. Dịch sát cú pháp tiếng Anh tạo ra
thứ văn đọc như ghép từ rời — đúng chữ nhưng không ai nói như vậy. Bốn lỗi hay gặp:

| Lỗi | Dịch cứng | Viết lại |
|---|---|---|
| Danh từ hóa | "khẳng định trên SQL sinh ra" | "kiểm tra câu SQL được sinh ra" |
| Bê cấu trúc Anh | "Điều service nói / Điều sqlite thực thi" | "Service viết thế này / sqlite chạy ra thế này" |
| Nuốt từ nối | "Nó pass, trong khi tôi chưa thêm lock nào." | "Nó xanh thật. Trong khi tôi chưa hề thêm dòng khóa nào." |
| Nhồi thuật ngữ Anh | "lượt đọc pool có lock trên driver" | "lúc đọc kho chung có khóa hay không" |

Nguyên tắc: **ưu tiên động từ hơn danh từ**, giữ các từ nối (thì, mà, nên, vì, chứ),
và mỗi thuật ngữ tiếng Anh chỉ giữ nguyên khi nó là **tên định danh** (`lockForUpdate()`,
`SQLiteGrammar`, sqlite, Laravel). Khái niệm thì dịch: lock → khóa, suite → bộ test.

**Chú giải trong ngoặc là quy ước của blog này, không phải lỗi.** Hai luật dưới đây
dễ bị hiểu là mâu thuẫn nhau, nên nói rõ ranh giới:

- **Tiêu đề mục và lần xuất hiện đầu tiên của một khái niệm** → ghi Việt kèm Anh trong
  ngoặc: `## Đánh đổi (Trade-offs)`, "khóa dòng (row lock)". Giữ nguyên, vì người đọc
  Việt tra cứu tiếp bằng từ tiếng Anh, và đây là giọng sẵn có của blog từ các bài đầu.
- **Trong thân câu, sau lần đầu** → dùng từ tiếng Việt, đừng rải tiếng Anh: viết "cái
  khóa" chứ không viết "cái lock".

**Đừng dịch thành ngữ kỹ thuật tiếng Anh.** Đây là lỗi tinh vi hơn dịch sát cú pháp:
"write path", "a live MySQL", "the trait rots", "the shape of the mistake" đều là cách
nói bình thường trong tiếng Anh kỹ thuật, nhưng dịch thẳng ra thì thành "đường ghi",
"MySQL sống", "cái trait mục ruỗng", "hình dạng của sai lầm" — không ai nói vậy và
người đọc phải dừng lại đoán. Diễn đạt lại bằng thứ tiếng Việt có thật:

| Thành ngữ Anh | Dịch cứng | Viết lại |
|---|---|---|
| write path / read path | đường ghi / đường đọc | chỗ ghi dữ liệu / lượt đọc |
| a live MySQL | một MySQL sống | một MySQL thật đang chạy |
| the trait rots | cái trait mục ruỗng | đoạn code âm thầm hỏng mà không ai biết |
| catches the shape of the mistake | bắt hình dạng của sai lầm | chỉ bắt được lỗi *trông giống* lỗi |
| the call disappeared | lời gọi biến mất | dòng gọi khóa bị xóa mất |

Phép thử: đọc to một đoạn. Nếu phải dừng lại giữa câu để ghép nghĩa, viết lại câu đó.

---

## 6. Tầng 4 — Dẫn xuất (trong 24h sau publish)

| Dẫn xuất | Từ thể loại | Nơi lưu |
|---|---|---|
| 1 gạch đầu dòng CV (hành động + số + tác động) | A, B | `career/<slug>.md` |
| Thẻ STAR + 3 lát cắt Meta/Google/Amazon | A, D | `career/<slug>.md` |
| Kịch bản video 60-90s (1 ý + hook 3 giây) | C, D | `drafts/video-<slug>.md` |
| Post LinkedIn/Facebook trỏ về bài | mọi | `drafts/social-<slug>.md` |

**Lý do làm ngay:** cắt lại rẻ khi còn nhớ; để 3 tháng sau phải đọc lại bài từ đầu.
"Một mũi tên trúng 4 đích" là cách **đóng gói lại** bài đã viết, không phải cách viết bài.

`career/` **bắt buộc gitignore** — repo này là GitHub Pages công khai.

---

## 7. Tầng 5 — Nhịp và rà soát

**Nhịp: 2 bài/tháng, bắt buộc ≥1 bài thuộc A hoặc B.**

Ước lượng: C ~3h · D ~3h · A ~4h · B ~7h (đo chiếm quá nửa).

**Lý do có ràng buộc A/B:** C và D dễ viết hơn nhiều; không ràng buộc thì sau 6 tháng
có 12 bài giới thiệu công nghệ và 0 tài sản CV.

**Rà soát mỗi quý:** đọc `career/`, hỏi "đủ đạn cho 5 câu behavioral kinh điển chưa?"
— thất bại, mâu thuẫn, deadline, tự học, quyết định khó. Thiếu câu nào → quý sau ưu
tiên sinh nguyên liệu cho câu đó.

---

## 7b. Kho kinh nghiệm

`CONTENT_STYLE.md` là **luật**: phải làm gì. `lessons/` là **sự cố**: đã sai như thế nào,
ai bắt được, vì sao lọt, dấu hiệu nhận ra ở bài khác.

Luật sinh ra từ lessons. Một lỗi lặp **lần thứ hai** phải được nâng thành luật ở đây hoặc
thành một bước trong skill chuyên môn — kho kinh nghiệm là nơi ghi nhận, không thay thế
được cổng chặn.

Ghi lỗi mới bằng `/content-lesson`. Soi bài theo kho này bằng `/content-audit`.

---

## 8. Checklist trước khi publish

1. `draft: false`, `date` **không lớn hơn giờ build** — Hugo bỏ qua bài tương lai mà không
   cảnh báo (L-058)
2. Có bản dịch
3. Mọi ảnh tồn tại trong `static/images/posts/<slug>/`
4. Có mục Trade-offs và mục giới hạn
5. Mọi con số truy được về `bench/<slug>/` hoặc nguồn ngoài có link. Kể cả thứ **không
   phải con số**: mỗi khẳng định về bối cảnh và mỗi lượng từ không đếm phải ghi được
   lệnh đã dùng để kiểm (mục "Khẳng định về bối cảnh cũng phải truy nguồn")
6. Đã qua `/content-audit` — vòng soi độc lập, không phải tự kiểm. Trong đó có bước
   đếm khái niệm mới trên mỗi câu dài (mục "Một câu, tối đa hai khái niệm mới")
7. **Tác giả đọc bản render** (`hugo server`) một lượt, tập trung mục Bối cảnh và mục
   cơ chế, **trước khi push**. Audit "đạt" không thay được bước này: audit chỉ đối chiếu
   được với inbox, còn tài liệu thiết kế nằm trong đầu tác giả (L-019 — bài lên site với
   mô tả ngược chế độ mới sau 4 lượt audit đạt)
8. `hugo --gc --minify` chạy sạch, **và** `find public -path '*<slug>*' -name index.html |
   wc -l` ra đúng 2. Build sạch không có nghĩa là trang được sinh ra (L-058)
