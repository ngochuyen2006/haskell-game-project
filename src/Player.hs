module Player (Player(..), newPlayer) where

import Types (Position)

-- Người chơi hiện chỉ có vị trí. Tuần 2 cần thêm trường (điểm, trail...) thì thêm ở đây.
data Player = Player
  { playerPos :: Position
  } deriving (Show, Eq)

-- Tạo người chơi ở vị trí cho trước
newPlayer :: Position -> Player
newPlayer pos = Player { playerPos = pos }
