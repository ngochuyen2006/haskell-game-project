# my-game-project
# Dự Án Game Haskell - Nhóm X

## 1. Môi trường & Cấu hình[cite: 1]
- **Resolver**: `lts-21.25`[cite: 1]
- **GHC Version**: Chốt phiên bản đang dùng trên máy[cite: 1]

## 2. Lệnh cơ bản[cite: 1]
- **Build dự án**: `stack build`[cite: 1]
- **Chạy game**: `stack run`[cite: 1]
- **Chạy unit test**: `stack test`[cite: 1]

## 3. Quy ước làm việc nhóm[cite: 1]
1. **Phân công file**: Mỗi người CHỈ sửa file module được phân công[cite: 1].
2. **File dùng chung**: `Types.hs` và file `.cabal` là file chung. Muốn sửa BẮT BUỘC phải báo cả nhóm[cite: 1].
3. **Quy định trước khi push**: Trước khi `git push` lên GitHub, BẮT BUỘC phải chạy `stack build` thành công trên máy cá nhân[cite: 1].
4. **Tham khảo & AI**: Nếu sử dụng code ngoài hoặc AI, ghi chú rõ ràng trong comment code hoặc file này[cite: 1].
5. **Thêm Module mới**: Phải khai báo tên module đó vào phần `exposed-modules` trong file `.cabal`[cite: 1].

## 4. Deadline[cite: 1]
- Người 2, 3, 4 hoàn thành nhiệm vụ và push code trước deadline **1 ngày** để Người 1 tiến hành ghép `Main.hs`[cite: 1].
