# my-game-project
##  GHI CHÚ VỀ DỰ ÁN (PROJECT NOTES)

### 1. Phiên bản & Môi trường sử dụng
* **Stack Resolver**: `lts-24.62` (khai báo trong `stack.yaml`)
* **GHC / GHCI Version**: `9.6.x` (xem chi tiết bằng lệnh `stack ghci --version`)

---

### 2. Cú pháp các Lệnh cơ bản (Build / Run / Test)
* **Biên dịch dự án**:
  ```bash
  stack build
 
* **Chạy ứng dụng game**:
  ```bash
  stack run
 
* **Chạy bộ kiểm thử (Unit Tests)**:
  ```bash
  stack test


---

### 3. Quy ước Chỉnh sửa File & Làm việc Nhóm
* **Quy định file dùng chung**: **`Types.hs`** và **`my-game-project.cabal`** là hai file chung. **CHỈ ĐƯỢC CHỈNH SỬA KHI ĐÃ THÔNG BÁO VÀ THỐNG NHẤT VỚI CẢ NHÓM**.
* **Quy định file riêng**: Mỗi thành viên chỉ sửa các file module do mình đảm nhận.
* **Điều kiện Push code**: Bắt buộc chạy `stack build` (và `stack test`) thành công trên máy cá nhân trước khi `git push` lên nhánh `main`

---

### 4. Hướng dẫn Thêm Module mới vào File `.cabal`
Khi cần khởi tạo thêm một file module mới trong thư mục `src/` (ví dụ: `src/NewModule.hs`):
1. Thông báo cho cả nhóm trước khi thao tác.
2. Mở file `my-game-project.cabal`.
3. Tìm đến mục `library` -> `exposed-modules` và thêm tên Module (không có đuôi `.hs`) vào danh sách:
   ```cabal
   library
     hs-source-dirs:      src
     exposed-modules:     Types
                        , Map
                        , Movement
                        , Player
                        , Input
                        , NewModule  -- Thêm tên module mới tại đây

## 16/10/26 Module Bản đồ (`Map.hs`)

Phụ trách xây dựng khung lưới, hệ thống tọa độ và hiển thị không gian trò chơi.

Các hàm cốt lõi đã hoàn thành:
- **`newMap`**: Khởi tạo kích thước bản đồ lưới dựa trên chiều rộng và chiều cao (`GameMap w h`).
- **`inBounds`**: Kiểm tra tọa độ `(x, y)` có nằm hợp lệ trong biên giới bản đồ hay không (tuân thủ hệ tọa độ máy tính: gốc `(0,0)` ở góc trên bên trái, $x$ tăng sang phải, $y$ tăng xuống dưới).
- **`renderMap`**: Kết xuất bản đồ thành chuỗi ký tự (`String`) để hiển thị trực quan trực tiếp trên terminal với các quy ước:
  - `#`: Tường biên xung quanh.
  - `P`: Vị trí hiện tại của người chơi.
  - `.`: Ô trống bên trong.

Chạy thử nghiệm khởi tạo và hiển thị:
let m = newMap 10 10
inBounds (5, 5) m
putStrLn (renderMap m (3, 3))

## Người 4: Người chơi, nhập phím và kiểm thử (`Player.hs`, `Input.hs`, `test/Spec.hs`)

Phụ trách kiểu dữ liệu người chơi, đọc phím từ bàn phím và bộ test tự động cho `Map` và `Movement`.

### Player (`src/Player.hs`)
- **`Player`**: bản ghi lưu trạng thái người chơi, hiện chỉ có `playerPos :: Position` (vị trí `(x, y)`).
- **`newPlayer :: Position -> Player`**: tạo người chơi tại vị trí cho trước.
- Export: `Player(..)`, `newPlayer`.
- Khi cần thêm thuộc tính (điểm, đường đi...) thì thêm trường vào `Player`.

```haskell
let p = newPlayer (1, 1)
playerPos p   -- (1,1)
```

### Input (`src/Input.hs`)
- **`readKey :: IO Char`**: đọc đúng một phím, không cần nhấn Enter và không hiện phím vừa gõ lên màn hình (dùng `NoBuffering` và tắt echo cho `stdin`).
- Export: `readKey`.

```haskell
c <- readKey
print (keyToDir c)
```

### Kiểm thử (`test/Spec.hs`)
Dùng thư viện **Hspec**, đã khai báo sẵn trong `test-suite` của file `.cabal`.

**Chạy test:**
```bash
stack test
```

**Các test hiện có:**
- `Map`: `newMap` lưu đúng kích thước. `inBounds` đúng ở các biên (`(0,0)`, `(9,9)` trong map 10x10, `x = 10`, tọa độ âm). `renderMap` có đúng một chữ `P`, và hàng đầu toàn tường `#`.
- `Movement`: `keyToDir` đúng với w/a/s/d, phím khác trả về `Nothing`. `movePlayer` đi đúng 4 hướng (đi lên thì `y` giảm 1, đi xuống thì `y` tăng 1, đi trái thì `x` giảm 1, đi phải thì `x` tăng 1). Chạm biên thì đứng yên ở cả 4 phía.

**Cách thêm test mới:** thêm một khối `it` vào `describe` tương ứng trong `test/Spec.hs`:
```haskell
it "mô tả test" $
  movePlayer (5, 5) MUp (10, 10) `shouldBe` (5, 4)
```
