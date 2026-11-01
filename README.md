Territory Fight

Giới thiệu

Territory Fight là trò chơi chiếm đất dành cho hai người chơi trên cùng một máy tính. Mỗi người điều khiển nhân vật bằng bàn phím, di chuyển ra khỏi lãnh thổ ban đầu để tạo đường đi và quay trở lại lãnh thổ của mình nhằm khép kín vòng bao. Các khu vực được bao vây sẽ được chuyển thành lãnh thổ của người chơi. Dự án cung cấp hai chương trình thực thi: phiên bản giao diện terminal và phiên bản giao diện đồ họa sử dụng Gloss.

1. Môi trường phát triển

Dự án được xây dựng bằng ngôn ngữ Haskell và sử dụng Stack để quản lý môi trường, thư viện phụ thuộc, quá trình biên dịch và kiểm thử. Cấu hình Stack sử dụng Resolver lts-22.39 trong file stack.yaml. Phiên bản GHC được sử dụng trong lần build gần nhất là 9.6.6. Bộ kiểm thử tự động sử dụng Hspec. Phiên bản đồ họa sử dụng Gloss với backend GLFW. Có thể kiểm tra phiên bản Stack bằng lệnh stack --version và kiểm tra phiên bản GHC bằng lệnh stack exec -- ghc --version.

2. Cấu hình trò chơi

Cấu hình mặc định được định nghĩa trong Game.hs. Kích thước bản đồ là 34 x 18 ô, thời lượng mỗi ván là 60 giây, chu kỳ xuất hiện vật phẩm là 3 giây, số lượng tối đa của mỗi loại vật phẩm là 3 và thời gian tồn tại của bom là 10 giây. Điểm phạt mặc định cho mỗi lần vi phạm biên bản đồ là 5 điểm. Các thông số này được quản lý tập trung trong kiểu Config và giá trị mặc định defaultConfig, cho phép điều chỉnh cấu hình mà không cần thay đổi trực tiếp các luật chơi.

3. Chuẩn bị và biên dịch dự án

Mở Terminal hoặc PowerShell tại thư mục gốc của dự án, nơi chứa hai file stack.yaml và my-game-project.cabal. Trong lần đầu thiết lập môi trường, chạy stack setup để Stack chuẩn bị phiên bản GHC phù hợp với Resolver. Sau đó chạy stack build để tải thư viện phụ thuộc và biên dịch các thành phần của chương trình. Sử dụng stack test để thực thi toàn bộ bộ kiểm thử tự động. Trước khi chia sẻ hoặc push thay đổi lên Git, cần kiểm tra kết quả biên dịch và kiểm thử trên môi trường phát triển.

4. Chạy chương trình

Dự án khai báo hai chương trình thực thi riêng trong my-game-project.cabal. Phiên bản terminal được khởi chạy bằng lệnh stack run my-game-project-exe. Thời lượng ván đấu có thể thay đổi bằng tùy chọn --time. Ví dụ, để đặt thời lượng 30 giây, sử dụng lệnh stack run my-game-project-exe -- --time 30. Có thể tắt màu ANSI bằng tùy chọn --no-color và xem hướng dẫn sử dụng bằng tùy chọn --help. Hai tùy chọn --time và --no-color có thể được sử dụng đồng thời.
Phiên bản giao diện đồ họa Gloss được khởi chạy bằng lệnh stack run my-game-project-gui. Thời lượng ván đấu có thể thay đổi bằng tùy chọn --time. 

5. Điều khiển trò chơi

Trong phiên bản terminal, người chơi 1 sử dụng W, A, S, D để di chuyển lên, trái, xuống và phải. Người chơi 2 sử dụng I, J, K, L theo các hướng tương ứng. Nhấn Q để thoát trò chơi. Phím điều khiển không phân biệt chữ hoa và chữ thường. Chương trình sử dụng chế độ đọc phím trực tiếp nên không cần nhấn Enter sau mỗi lần di chuyển.
Trong phiên bản giao diện đồ họa, nhấn Space hoặc Enter tại màn hình giới thiệu để bắt đầu. Người chơi 1 sử dụng W, A, S, D; người chơi 2 sử dụng I, J, K, L. Sau khi ván đấu kết thúc, nhấn R để bắt đầu ván mới. Nhấn Q hoặc Esc để thoát chương trình.

6. Luật chơi cơ bản

Mỗi người chơi bắt đầu với một vùng lãnh thổ riêng có kích thước 3 x 3 ô. Khi di chuyển ra ngoài lãnh thổ của mình, nhân vật để lại một vệt đường. Nếu vệt đường kết nối trở lại lãnh thổ ban đầu, các ô trống nằm trong vùng được bao vây và các ô trên vệt đường sẽ được chuyển thành lãnh thổ của người chơi. Thuật toán Flood Fill được sử dụng để xác định vùng bên ngoài và vùng được bao kín. Khi một người chơi chiếm phần đất của đối thủ, các ô lãnh thổ bị chồng lấn sẽ được loại bỏ khỏi lớp bản đồ của đối thủ, bảo đảm một ô không đồng thời thuộc về cả hai người chơi.
Các tình huống va chạm được xử lý theo vị trí và trạng thái của người chơi. Khi đi ra ngoài biên bản đồ, nhân vật giữ nguyên vị trí và bị trừ điểm theo cấu hình. Khi chạm vào vệt đường của đối thủ, người sở hữu vệt đường bị mất một nửa số ô lãnh thổ; các ô bị xóa được lựa chọn theo khoảng cách Manhattan đến vị trí va chạm. Va chạm trực tiếp giữa hai nhân vật có thể dẫn đến việc người di chuyển bị mất một nửa lãnh thổ hoặc chủ đất giành chiến thắng sớm, tùy thuộc vào vị trí đất tại thời điểm va chạm.
Trò chơi có hai loại vật phẩm. Bomb khi được kích hoạt sẽ xóa vệt đường đang tạo và đưa người chơi trở về vị trí bắt đầu vẽ vệt; vật phẩm này không làm mất lãnh thổ đã sở hữu. Expand mở rộng lãnh thổ thành vùng 3 x 3 ô quanh vị trí nhặt vật phẩm và đồng thời xử lý phần đất bị chồng lấn với đối thủ. Theo cấu hình mặc định, hệ thống định kỳ tạo vật phẩm nếu số lượng hiện tại chưa đạt giới hạn; bom sẽ tự biến mất sau thời gian tồn tại được quy định, trong khi vật phẩm Expand không tự biến mất theo cơ chế này.
Điểm số của mỗi người chơi được tính bằng số ô lãnh thổ đang sở hữu trừ đi tổng điểm phạt. Trận đấu kết thúc khi hết thời gian hoặc khi xuất hiện điều kiện thắng sớm như bao vây được đối thủ hay chủ đất chạm được người xâm nhập đang ở trên lãnh thổ của mình. Khi hết thời gian, người có điểm số cao hơn giành chiến thắng; nếu hai người bằng điểm, kết quả là hòa.

7. Cấu trúc chương trình

Thư mục src chứa các module xử lý dữ liệu và logic chính của trò chơi. Types.hs định nghĩa các kiểu dữ liệu dùng chung gồm Direction, Position và Trail. Map.hs quản lý cấu trúc bản đồ, lưu lưới ô bằng Data.Vector và cung cấp các thao tác kiểm tra tọa độ, đọc và cập nhật ô. Movement.hs xử lý ánh xạ hướng di chuyển và tính vị trí tiếp theo. Player.hs quản lý mã người chơi, vị trí hiện tại, vệt đường, vị trí bắt đầu vẽ vệt và điểm phạt. Trail.hs cung cấp các thao tác khởi tạo, thêm vị trí, kiểm tra và xóa vệt đường.
Territory.hs thực hiện thuật toán Flood Fill theo phương pháp duyệt theo lớp để xác định các ô thuộc vùng bên ngoài, từ đó xác định và cập nhật lãnh thổ được bao vây. Module này cũng cung cấp chức năng tính số ô lãnh thổ. Collision.hs kiểm tra vị trí có nằm trong vệt đường của đối thủ hay không và lựa chọn các ô lãnh thổ bị xóa khi áp dụng hình phạt. Items.hs định nghĩa hai loại vật phẩm Bomb và Expand, quản lý tuổi vật phẩm, bộ sinh số giả ngẫu nhiên và việc chọn vị trí trống trên bản đồ.
Game.hs là module quản lý trạng thái và luật chơi trung tâm. Module định nghĩa Config, GameState, các trạng thái trận đấu, kết quả, sự kiện và các hàm khởi tạo, di chuyển, xử lý va chạm, chiếm lãnh thổ, kích hoạt vật phẩm, cập nhật thời gian và xác định điểm số. GameState lưu riêng hai lớp bản đồ lãnh thổ của hai người chơi, dữ liệu người chơi, danh sách vật phẩm, đồng hồ, trạng thái ván đấu và sự kiện gần nhất. Logic trong Game.hs chủ yếu được tổ chức dưới dạng các hàm xử lý trạng thái, tách biệt với thao tác nhập xuất của giao diện.
Input.hs chuyển phím thành hành động của người chơi và cung cấp chức năng đọc bàn phím cho phiên bản terminal. UI.hs chuyển GameState thành nội dung hiển thị trên terminal, bao gồm bản đồ, điểm số, thời gian, sự kiện và kết quả trận đấu. GameLoop.hs kết nối đầu vào, bộ đếm thời gian, logic game và giao diện terminal. Vòng lặp sử dụng các luồng xử lý riêng cho đầu vào và đồng hồ, truyền sự kiện qua Chan để cập nhật trạng thái game theo thứ tự.
Thư mục app chứa các điểm khởi chạy chương trình. Main.hs là điểm vào của phiên bản terminal, tiếp nhận các tham số chạy chương trình và khởi tạo vòng lặp terminal. Gui.hs là điểm vào của phiên bản đồ họa, tiếp nhận sự kiện bàn phím và thời gian, cập nhật trạng thái thông qua các hàm trong Game.hs và kết xuất hình ảnh bằng Gloss. Hai phiên bản sử dụng chung các module dữ liệu và luật chơi.
Storage.hs cung cấp chức năng lưu, đọc và hiển thị lịch sử trận đấu. Dữ liệu lịch sử được lưu dưới định dạng JSON trong file data/history.json. Mỗi bản ghi gồm thời điểm chơi, điểm của hai người chơi, người chiến thắng, lý do kết thúc và thời lượng trận đấu. Trong vòng lặp terminal hiện tại, kết quả được lưu sau khi trận đấu kết thúc và lịch sử được hiển thị trên terminal. Thư mục data được tạo tự động khi lưu kết quả nếu chưa tồn tại.

8. Kiểm thử

Bộ kiểm thử được xây dựng bằng Hspec và được thực thi bằng lệnh stack test. GameSpec.hs kiểm tra luật chơi và hành vi tích hợp của toàn trận đấu. InputSpec.hs kiểm tra việc phân tích phím và chuyển đổi hành động. MapSpec.hs kiểm tra cấu trúc bản đồ và thao tác trên các ô. MovementSpec.hs kiểm tra hướng và vị trí di chuyển. PlayerSpec.hs kiểm tra dữ liệu và thao tác của người chơi. UISpec.hs kiểm tra nội dung hiển thị. CollisionSpec.hs kiểm tra phát hiện va chạm và lựa chọn các ô bị xóa. ItemSpec.hs kiểm tra các thao tác quản lý vật phẩm. TerritorySpec.hs kiểm tra Flood Fill, chiếm lãnh thổ và tính diện tích. TrailSpec.hs kiểm tra các thao tác trên vệt đường. StorageSpec.hs kiểm tra việc đọc lịch sử khi file chưa tồn tại, đọc JSON hợp lệ, xử lý JSON không hợp lệ, từ chối lưu kết quả khi trận đấu chưa kết thúc, lưu kết quả trận đấu, bổ sung bản ghi mới và bảo toàn file lịch sử khi dữ liệu JSON cũ không hợp lệ.
Các Spec riêng tập trung kiểm tra chức năng của từng module. GameSpec kiểm tra hành vi ở cấp độ toàn trò chơi khi các thành phần phối hợp. Hai cấp độ kiểm thử bổ trợ cho nhau, giúp phát hiện lỗi ở cả chức năng độc lập và luồng xử lý tích hợp.

9. Quy ước làm việc nhóm

Types.hs và my-game-project.cabal là các file dùng chung của dự án. Mọi thay đổi đối với các file này cần được thông báo và thống nhất với cả nhóm trước khi thực hiện. Việc bổ sung module mới trong thư mục src cần được trao đổi trước, sau đó đăng ký tên module trong mục library, exposed-modules của my-game-project.cabal. Nếu module sử dụng thư viện bên ngoài, thư viện tương ứng phải được khai báo trong build-depends của component sử dụng.
Khi bổ sung Spec mới trong thư mục test, cần tạo module kiểm thử tương ứng, đăng ký trong mục other-modules của test suite, khai báo các thư viện được sử dụng trực tiếp trong build-depends và import, gọi hàm spec trong test/Spec.hs. Các thư mục và tệp build tự động như .stack-work không được đưa lên Git. Trước khi push thay đổi, cần kiểm tra trạng thái Git và xác nhận các file được đưa vào commit, đồng thời chạy stack build và stack test thành công.

10. Xử lý một số vấn đề thường gặp

Nếu GHC thông báo không tìm thấy package khi biên dịch, cần kiểm tra mục build-depends của đúng component trong my-game-project.cabal. Nếu lỗi xuất hiện trong test suite, package được import trực tiếp bởi các Spec cần được khai báo trong build-depends của test suite, không chỉ trong library. Nếu phiên bản đồ họa gặp vấn đề khi biên dịch hoặc khởi chạy do thư viện Gloss hoặc backend đồ họa, có thể tắt cờ GUI bằng lệnh stack build --flag my-game-project:-gui để tiếp tục biên dịch phiên bản terminal. Muốn bật lại GUI, sử dụng stack build --flag my-game-project:gui. Sau khi thay đổi cấu hình hoặc mã nguồn, cần chạy lại stack build và stack test để kiểm tra tính tương thích của phiên bản dự án.