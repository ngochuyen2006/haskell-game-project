# my-game-project
##  GHI CHÚ VỀ DỰ ÁN (PROJECT NOTES)

### 1. Phiên bản & Môi trường sử dụng
* **Stack Resolver**: `lts-22.39` (khai báo trong `stack.yaml`)
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

## 19/10/26 Xử lý Lãnh thổ & Tối ưu hóa Vector
1. Mục tiêu Tuần 2
* **Xây dựng module `Territory.hs`**: Hiện thực hóa thuật toán bao vây và chiếm đóng lãnh thổ.
* **Ứng dụng thuật toán Flood Fill (Layer-by-layer BFS)**: Tự động nhận diện không gian "bên ngoài" bản đồ bắt đầu từ các mép biên, từ đó cô lập và chuyển hóa các ô trống bên trong thành lãnh thổ của người chơi.
* **Tối ưu hóa hiệu năng với `Data.Vector`**: Dùng mảng `Vector` 1 chiều để đạt tốc độ truy xuất $O(1)$ và nhanh chóng tính toán điểm số.
2. Cấu trúc Module & Phân chia
* **`Types.hs`**: Định nghĩa kiểu dữ liệu cơ bản (`Position`, `Tile`, `GameMap`, `Trail`).
* **`Map.hs`**: Quản lý bản đồ dưới dạng mảng `Vector` 1 chiều với các thao tác truy xuất `getTile` và cập nhật `setTile` an toàn.
* **`Trail.hs`**: Theo dõi vết đường đi của người chơi trong thời gian thực.
* **`Territory.hs`** *(Trọng tâm tuần này)*:
  * `claimTerritory`: Hàm cốt lõi xử lý khi người chơi khép kín vòng vây.
  * `findOutsideCells`: Thuật toán BFS duyệt từng tầng (*layer-by-layer*) lan tỏa từ biên ngoài cùng để loại bỏ vùng bên ngoài.
  * `calculateTerritorySize`: Hàm đếm điểm số dựa trên bộ lọc vector (`V.filter` và `V.length`).
3. Điểm nhấn của `Data.Vector`
Trong phiên bản này, toàn bộ dữ liệu lưới bản đồ (`grid`) được lưu trữ dưới dạng **`V.Vector Tile`** thay vì danh sách thông thường. 
* **Truy xuất $O(1)$**: Giúp các hàm kiểm tra ô (`getTile`) và cập nhật ô (`setTile`) chạy với tốc độ tối đa, không bị giật lag khi bản đồ mở rộng kích thước.
* **Tính điểm số hiệu quả**: Hàm tính diện tích lãnh thổ (`calculateTerritorySize`) sử dụng trực tiếp các hàm tối ưu từ thư viện Vector:
  ```haskell
  calculateTerritorySize :: GameMap -> Int
  calculateTerritorySize (GameMap _ _ g) = 
      V.length (V.filter (== Territory) g)

## Người 4: Player, Input, UI, vòng chơi và kiểm thử

**Phụ trách:** `src/Player.hs`, `src/Input.hs`, `src/Items.hs`, `src/Game.hs`, `src/UI.hs`, `src/GameLoop.hs`, `app/Main.hs` và thư mục `test/`.

### 1. Chạy game

```bash
stack run                      # chơi (mặc định 60 giây/ván)
stack run -- --time 30         # đổi thời gian một ván (giây)
stack run -- --no-color        # tắt màu ANSI
stack run -- --help
```

| Người chơi | Lên | Xuống | Trái | Phải |
|:---:|:---:|:---:|:---:|:---:|
| **P1** | `W` | `S` | `A` | `D` |
| **P2** | `I` | `K` | `J` | `L` |

Bấm `Q` để thoát. Không phân biệt hoa/thường. Phím khác bị bỏ qua.

### 2. Kiến trúc: tách giao diện khỏi luật chơi

```
Input.parseKey  -->  Game.applyMove / Game.tick  -->  UI.renderGame
 (phím -> Action)     (luật chơi, hàm thuần)          (GameState -> String)

        GameLoop.runGame nối phím + đồng hồ + màn hình (phần IO duy nhất)
```

| Tầng | Module | Có IO? | Vai trò |
|---|---|:---:|---|
| Nhập | `Input` | Có | Đọc phím, đổi phím thành thao tác |
| Luật chơi | `Game`, `Items`, `Player` | Không | Cập nhật `GameState`, test tự động được |
| Hiển thị | `UI` | Không (trừ vài hàm vẽ) | Đổi `GameState` thành chuỗi để in |
| Nối | `GameLoop` | Có | Vòng lặp: phím, đồng hồ, màn hình |

Luật chơi (`Game.hs`) không có IO nên test tự động được. Muốn đổi giao diện chỉ cần sửa `UI.hs`, không đụng tới luật.

### 3. Các module

| File | Vai trò | Kiểu / hàm chính |
|---|---|---|
| `Player.hs` | Dữ liệu người chơi | `PlayerId = P1 \| P2`, `Player`, `newPlayer`, `opponent`, `setPlayerPos`, `addPenalty`, `extendTrail`, `resetTrail` |
| `Input.hs` | Nhận phím | `Action`, `parseKey`, `readKey`, `readKeyTimeout`, `withRawInput` |
| `Game.hs` | Toàn bộ luật chơi | `Config`, `defaultConfig`, `GameState`, `initGame`, `applyMove`, `tick`, `scoreOf`, `territorySize`, `landAt`, `isFinished` |
| `Items.hs` | Vật phẩm | `ItemKind = Bomb \| Expand`, `Item`, bộ sinh số ngẫu nhiên đơn giản (không cần thư viện `random`) |
| `UI.hs` | Giao diện | `renderGame`, `renderBoard`, `renderIntro`, `describeEvent`, `describeOutcome`, `drawFrame`, `clearScreen`, `hideCursor`, `showCursor` |
| `GameLoop.hs` | Vòng chơi | `runGame :: Config -> Bool -> IO ()` |
| `app/Main.hs` | Điểm vào chương trình | Đọc tham số `--time`, `--no-color`, `--help` rồi gọi `runGame` |

**Player.hs**

| Thành phần | Mô tả |
|---|---|
| `Player { playerId, playerPos, playerTrail, playerPenalty }` | Mã, vị trí, vệt đường, điểm bị phạt |
| `newPlayer :: PlayerId -> Position -> Player` | Tạo người chơi tại vị trí cho trước |
| `opponent`, `setPlayerPos`, `addPenalty`, `extendTrail`, `resetTrail` | Hàm cập nhật nhỏ |

Không lưu đất và điểm ở `Player` vì `GameState` đã quản lý. Điểm = số ô đất - điểm phạt (`scoreOf`).

**Input.hs**

| Hàm | Mô tả |
|---|---|
| `Action = Move PlayerId Direction \| Quit` | Thao tác game xử lý được |
| `parseKey :: Char -> Maybe Action` | Chuyển phím thành thao tác, dùng lại `keyToDir` của `Movement.hs` |
| `readKey :: IO Char` | Đọc 1 phím, không cần Enter, không hiện phím ra màn hình |
| `readKeyTimeout :: Int -> IO (Maybe Char)` | Chờ phím tối đa vài mili-giây để đồng hồ vẫn chạy; bỏ qua chuỗi phím mũi tên; hết dữ liệu nhập (EOF) coi như bấm `Q` |
| `withRawInput :: IO a -> IO a` | Bật chế độ đọc phím tức thời và luôn khôi phục terminal khi kết thúc |

**Game.hs**

| Thành phần | Mô tả |
|---|---|
| `Config` / `defaultConfig` | Mọi con số của luật gom về một chỗ (xem mục 5) |
| `GameState` | Cấu hình, hai người chơi, hai lớp đất, vật phẩm, thời gian còn lại, trạng thái, sự kiện gần nhất |
| `initGame :: Config -> GameState` | Tạo ván mới |
| `applyMove :: PlayerId -> Direction -> GameState -> GameState` | Một lần bấm phím = đi một ô |
| `tick :: Double -> GameState -> GameState` | Cho thời gian trôi, sinh/xóa vật phẩm, kết thúc ván khi hết giờ |
| `scoreOf`, `territorySize`, `landAt`, `isFinished` | Truy vấn trạng thái |

**UI.hs**

| Hàm | Mô tả |
|---|---|
| `renderGame :: Bool -> GameState -> String` | Vẽ cả màn hình (`Bool` = bật màu) |
| `renderBoard`, `renderIntro` | Vẽ bản đồ, màn hình giới thiệu |
| `describeEvent`, `describeOutcome` | Đổi sự kiện và kết quả thành chữ hiển thị |
| `drawFrame`, `clearScreen`, `hideCursor`, `showCursor` | Hàm điều khiển terminal |

### 4. Bố cục màn hình

| Thứ tự | Khu vực | Nội dung |
|:---:|---|---|
| 1 | Đầu | Tiêu đề và thời gian còn lại |
| 2 | Điểm số | Đất, phạt, điểm của hai người chơi |
| 3 | Bản đồ | Khung và các ô |
| 4 | Trạng thái | Thông báo sự kiện gần nhất; đang chơi hoặc kết quả thắng/thua/hòa |
| 5 | Chân trang | Hướng dẫn điều khiển và chú thích ký hiệu |

| Ký hiệu | Ý nghĩa |
|:---:|---|
| `1` / `2` | Người chơi P1 / P2 |
| `O` / `X` | Đất của P1 / P2 |
| `o` / `x` | Vệt đường của P1 / P2 |
| `@` | Bom |
| `+` | Phình lãnh địa |
| `.` | Ô trống |
