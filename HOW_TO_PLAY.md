CHIẾM ĐẤT – GAME 2 NGƯỜI CHƠI

CÀI ĐẶT

Cài đặt Haskell Stack theo hướng dẫn tại: https://docs.haskellstack.org

Mở Terminal hoặc PowerShell tại thư mục dự án, nơi chứa file stack.yaml. Trong lần chạy đầu tiên, Stack sẽ tải các thư viện cần thiết và biên dịch chương trình.

CHẠY PHIÊN BẢN ĐỒ HỌA

Chạy lệnh:
stack run my-game-project-gui

Một cửa sổ trò chơi sẽ xuất hiện. Thời lượng mặc định của mỗi ván là 60 giây. Có thể thay đổi thời lượng bằng tùy chọn --time. Ví dụ, để đặt thời lượng ván đấu là 30 giây:
stack run my-game-project-gui -- --time 30

CHẠY PHIÊN BẢN TERMINAL

Chạy lệnh:
stack run my-game-project-exe

Trên Windows, nếu ký tự tiếng Việt hiển thị không chính xác, thực hiện lệnh sau trước khi chạy chương trình:
chcp 65001

Có thể thay đổi thời lượng ván đấu bằng tùy chọn --time hoặc tắt màu ANSI bằng tùy chọn --no-color. Ví dụ:
stack run my-game-project-exe -- --time 30 --no-color

Nếu phiên bản đồ họa không thể biên dịch do vấn đề thư viện hoặc môi trường, có thể tắt cờ GUI và chỉ biên dịch phiên bản terminal:
stack build --flag my-game-project:-gui

Sau đó chạy:
stack run my-game-project-exe

CÁCH ĐIỀU KHIỂN

Người chơi 1 sử dụng W, A, S, D để di chuyển lên, trái, xuống và phải. Người chơi 2 sử dụng I, J, K, L theo các hướng tương ứng. Các phím điều khiển không phân biệt chữ hoa và chữ thường.

Đối với phiên bản terminal, nhấn Q để thoát trò chơi. Đối với phiên bản đồ họa, nhấn Space hoặc Enter tại màn hình giới thiệu để bắt đầu, nhấn R để chơi lại sau khi trận đấu kết thúc và nhấn Q hoặc Esc để thoát.

LUẬT CHƠI

Bản đồ có kích thước 34 x 18 ô. Mỗi người chơi bắt đầu với một vùng lãnh thổ riêng gồm 9 ô (3 x 3). Khi di chuyển ra ngoài lãnh thổ của mình, người chơi để lại vệt đường. Quay trở lại lãnh thổ ban đầu để khép kín vòng bao, các ô trống được bao vây và các ô trên vệt đường sẽ trở thành lãnh thổ của người chơi. Có thể di chuyển ngược vào vệt đường của chính mình mà không bị áp dụng hình phạt.

Ra khỏi biên bản đồ khiến nhân vật đứng yên và bị trừ 5 điểm. Khi chạm vào vệt đường của đối thủ, người sở hữu vệt đường bị mất 50% lãnh thổ. Các ô đất bị mất được lựa chọn dựa trên khoảng cách Manhattan đến vị trí va chạm.

Khi chủ đất chạm vào người xâm nhập đang đứng trong lãnh thổ của mình, chủ đất giành chiến thắng ngay lập tức. Khi người xâm nhập chạm vào chủ đất, người xâm nhập bị mất 50% lãnh thổ. Nếu khép vòng bao vây được vị trí của đối thủ, người thực hiện giành chiến thắng ngay lập tức.

VẬT PHẨM

Bom được hiển thị bằng ký hiệu @ trong giao diện terminal. Khi đạp trúng bom trong lúc đang tạo vệt đường, người chơi mất toàn bộ vệt đường hiện tại và được đưa trở về vị trí bắt đầu tạo vệt. Bom không làm mất lãnh thổ đã sở hữu.

Vật phẩm phình lãnh địa được hiển thị bằng ký hiệu +. Khi nhặt được, lãnh thổ được mở rộng thành vùng 3 x 3 ô quanh vị trí vật phẩm. Phần lãnh thổ bị chồng lấn sẽ được loại bỏ khỏi bản đồ của đối thủ.

Bom tự biến mất sau thời gian tồn tại được quy định trong cấu hình. Các vật phẩm được sinh theo chu kỳ và số lượng mỗi loại không vượt quá giới hạn cấu hình.

ĐIỂM SỐ VÀ KẾT THÚC TRẬN ĐẤU

Điểm số được tính bằng số ô lãnh thổ đang sở hữu trừ đi tổng điểm phạt. Khi hết thời gian, người chơi có điểm số cao hơn giành chiến thắng; nếu hai người có điểm bằng nhau, trận đấu kết thúc với kết quả hòa. Trận đấu cũng có thể kết thúc sớm khi một người chơi thỏa mãn điều kiện chiến thắng do bị bao vây hoặc chạm đối thủ trong lãnh thổ của mình.

LỊCH SỬ TRẬN ĐẤU

Phiên bản terminal hỗ trợ lưu kết quả các trận đấu đã kết thúc vào file data/history.json dưới định dạng JSON. Thông tin được lưu gồm thời điểm chơi, điểm số của hai người chơi, người chiến thắng, lý do kết thúc và thời lượng trận đấu. Dữ liệu lịch sử được bổ sung vào danh sách hiện có và có thể được đọc, hiển thị lại thông qua module Storage.

KIỂM THỬ

Chạy toàn bộ bộ kiểm thử tự động bằng lệnh:
stack test
Bộ kiểm thử sử dụng HSpec để kiểm tra các chức năng của từng module và hành vi phối hợp giữa các thành phần của trò chơi. Các nhóm kiểm thử bao gồm luật chơi, di chuyển, đầu vào, bản đồ, người chơi, vệt đường, lãnh thổ, va chạm, vật phẩm, giao diện và lưu trữ lịch sử trận đấu.