module Trail where

import Types

{-khởi tạo đường đi rỗng
khi trò chơi vừa bắt đầu hoặc khi người chơi vừa xóa vết, 
danh sách đường đi sẽ rỗng, được biểu diễn bằng một danh sách trống
-}
initTrail :: Trail
initTrail = []

--thêm một bước di chuyển mới vào đầu danh sách vết
addStep :: Position -> Trail -> Trail
addStep pos trail = pos : trail

--kiểm tra xem một tọa độ có nằm trong đường đi hiện tại không
--elem để kiểm tra phần tử có trong danh sách k
isInTrail :: Position -> Trail -> Bool
isInTrail = elem

--xóa toàn bộ đường đi (khi hoàn thành chiếm đất hoặc chết)
clearTrail :: Trail
clearTrail = []