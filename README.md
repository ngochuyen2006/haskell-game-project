# my-game-project
##  GHI CHÚ VỀ DỰ ÁN (PROJECT NOTES)

### 1. Phiên bản & Môi trường sử dụng
* **Stack Resolver**: `lts-24.62` (khai báo trong `stack.yaml`)
* **GHC / GHCI Version**: `9.6.x` (xem chi tiết bằng lệnh `stack ghci --version`)[cite: 1]

---

### 2. Cú pháp các Lệnh cơ bản (Build / Run / Test)
* **Biên dịch dự án**:
  ```bash
  stack build
  ```[cite: 1]
* **Chạy ứng dụng game**:
  ```bash
  stack run
  ```[cite: 1]
* **Chạy bộ kiểm thử (Unit Tests)**:
  ```bash
  stack test
  ```[cite: 1]

---

### 3. Quy ước Chỉnh sửa File & Làm việc Nhóm
* **Quy định file dùng chung**: **`Types.hs`** và **`my-game-project.cabal`** là hai file chung[cite: 1]. **CHỈ ĐƯỢC CHỈNH SỬA KHI ĐÃ THÔNG BÁO VÀ THỐNG NHẤT VỚI CẢ NHÓM**[cite: 1].
* **Quy định file riêng**: Mỗi thành viên chỉ sửa các file module do mình đảm nhận[cite: 1].
* **Điều kiện Push code**: Bắt buộc chạy `stack build` (và `stack test`) thành công trên máy cá nhân trước khi `git push` lên nhánh `main`[cite: 1].

---

### 4. Hướng dẫn Thêm Module mới vào File `.cabal`
Khi cần khởi tạo thêm một file module mới trong thư mục `src/` (ví dụ: `src/NewModule.hs`):
1. Thông báo cho cả nhóm trước khi thao tác[cite: 1].
2. Mở file `my-game-project.cabal`[cite: 1].
3. Tìm đến mục `library` -> `exposed-modules` và thêm tên Module (không có đuôi `.hs`) vào danh sách[cite: 1]:
   ```cabal
   library
     hs-source-dirs:      src
     exposed-modules:     Types
                        , Map
                        , Movement
                        , Player
                        , Input
                        , NewModule  -- Thêm tên module mới tại đây
