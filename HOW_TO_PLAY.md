# CHIẾM ĐẤT – Game 2 người chơi

## Cài đặt (1 lần)
Cài Haskell Stack: https://docs.haskellstack.org

## Chạy bản ĐỒ HỌA (khuyến nghị)
Mở terminal **trong thư mục dự án** (có file `stack.yaml`) rồi gõ:
```
stack run my-game-project-gui
```
Lần đầu sẽ tải và biên dịch vài phút. Một cửa sổ game sẽ hiện ra.
Tùy chọn: `stack run my-game-project-gui -- --time 30` (ván 30 giây, mặc định 60).

## Chạy bản terminal (chữ)
```
stack run my-game-project-exe
```
Windows nếu chữ tiếng Việt lỗi: chạy `chcp 65001` trước.

## Nếu bản đồ họa không biên dịch được
Bỏ qua phần đồ họa và chỉ build bản terminal:
```
stack run my-game-project-exe --flag my-game-project:-gui
```

## Cách chơi
- P1 (xanh): W / A / S / D       P2 (đỏ): I / J / K / L (hoặc phím mũi tên, bản đồ họa)
- Bản đồ họa: SPACE bắt đầu, R chơi lại khi hết ván, Q hoặc ESC thoát.
- Mỗi người có đất 3x3. Đi ra ngoài đất sẽ để lại **vệt đường**; quay về đất nhà để **khép vòng** và chiếm vùng bị bao.
- Hết giờ, ai nhiều điểm hơn (đất − phạt) thì thắng.

## Luật
- Đi ra ngoài biên, đụng vệt của mình hoặc của đối thủ: đứng yên, **-5 điểm**.
- Chủ đất chạm kẻ xâm nhập đang đứng trong đất mình: **thắng ngay**.
- Kẻ xâm nhập chạm chủ đất: chỉ bị chặn lại.
- Khép vòng bao trúng ô đối thủ đang đứng: **thắng ngay**.
- Bom (tròn đen viền đỏ): mất đất. Dấu + xanh lá: thêm đất.
