# Blog cá nhân — Hugo + PaperMod

Blog song ngữ (vi/en), deploy tự động lên GitHub Pages qua GitHub Actions khi push `main`.
Mục đích: portfolio kỹ thuật phục vụ ứng tuyển big/mid tech.

## Bắt buộc khi viết hoặc sửa bài

Đọc `CONTENT_STYLE.md` **trước** khi tạo hoặc chỉnh bất kỳ file nào trong `content/posts/`.
Mọi bài mới tạo bằng `hugo new content posts/<slug>.md` (dùng `archetypes/posts.md`).

Tóm tắt không được vi phạm:
- Front matter YAML, đủ 10 trường, đường dẫn ảnh bắt đầu bằng `/`
- Khung theo thể loại A/B/C/D — xem `CONTENT_STYLE.md` mục 4 và 5
- Bản gốc 900-1200 từ + bản còn lại: cắt **ý** thừa, đừng cắt **chữ**
  (bản VI dài hơn bản EN là bình thường)
- Mọi con số phải truy được nguồn về `drafts/inbox.md` hoặc `bench/<slug>/`
- Không emoji trong thân bài; đừng dịch thẳng thành ngữ kỹ thuật tiếng Anh

## Lệnh

```bash
hugo server -D          # xem thử tại localhost:1313
hugo --gc --minify      # build kiểm tra trước khi push
```

## Lưu ý

- `themes/PaperMod` là git submodule — `git submodule update --init --recursive` sau khi clone.
- `drafts/` chứa bản nháp thô, đã gitignore.

## Dây chuyền content (nhiều tuần)

Spec đầy đủ: `CONTENT_STYLE.md` (luật). Kinh nghiệm: `lessons/` (lỗi đã xảy ra).
Trạng thái: `pipeline/state.json` (đừng sửa tay).

| Skill | Tầng | Khi nào |
|---|---|---|
| `/content-status` | — | **Cửa vào.** Mở phiên, hỏi "tuần này làm gì" |
| `/content-capture` | 0 | Vừa xảy ra chuyện gì đáng ghi |
| `/content-triage` | 1+2 | Inbox đã tích vài mục, cần biết viết được chưa |
| `/content-measure` | 1 | Mục ở stage `needs-measure` |
| `/content-write` | 3 | Mục ở stage `ready`/`drafting`/`needs-translation` |
| `/content-artwork` | 3 | Mục ở stage `needs-assets` — ảnh cover, sơ đồ |
| `/content-bench` | 3 | Mục ở stage `needs-bench` — code bằng chứng, phải chạy thật |
| `/content-audit` | 3 | **Soi độc lập trước publish** — không tin tự kiểm của write |
| `/content-derive` | 4 | Trong 24h sau publish |
| `/content-review` | 5 | Mỗi quý, hoặc trước khi nộp CV |
| `/content-lesson` | — | Ngay khi gặp lỗi — ghi vào `lessons/` |

`career/` và `drafts/` không commit. `bench/` thì có — script reproduce là bằng chứng.

## Quét định danh trước khi commit

Hook `pre-commit` chạy `scripts/scan-identifiers.sh` trên mọi file sắp commit. Sau khi
clone lại phải bật tay một lần:

```bash
git config core.hooksPath .githooks
```

Từ khóa riêng của công ty đặt ở `.git/identifiers.local` (không commit). Dương tính giả:
thêm `scan-ok` vào cuối dòng.
