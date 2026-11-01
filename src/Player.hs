--cần ghi nhận điểm bắt đầu trail
module Player
  ( PlayerId(..)
  , Player(..)
  , newPlayer
  , opponent
  , setPlayerPos
  , addPenalty
  , extendTrail
  , resetTrail
  ) where


import Types (Position, Trail)
import qualified Trail as T


-- Mã người chơi: P1 ở bên trái, P2 ở bên phải.
data PlayerId = P1 | P2
  deriving (Show, Eq, Ord, Enum, Bounded)


{- Thông tin riêng của từng người chơi.
   KHÔNG lưu đất và điểm ở đây: đất nằm trong GameState (mỗi người một lớp bản đồ),
   điểm = số ô đất - playerPenalty được tính trong module Game (scoreOf).
-}
data Player = Player
  { playerId      :: PlayerId
  , playerPos     :: Position   -- vị trí hiện tại (x, y)
  , playerTrail   :: Trail      -- vệt đường đang vẽ (rỗng khi đang đứng trên đất nhà)
  , playerTrailStart :: Maybe Position
  , playerPenalty :: Int        -- tổng điểm bị phạt (số dương, sẽ bị trừ vào điểm)
  } deriving (Show, Eq)


-- Tạo người chơi tại vị trí cho trước: chưa có vệt, chưa bị phạt.
newPlayer :: PlayerId -> Position -> Player
newPlayer pid pos = Player
  { playerId      = pid
  , playerPos     = pos
  , playerTrail   = T.initTrail
  , playerPenalty = 0
  , playerTrailStart = Nothing
  }


-- Đối thủ của một người chơi.
opponent :: PlayerId -> PlayerId
opponent P1 = P2
opponent P2 = P1


setPlayerPos :: Position -> Player -> Player
setPlayerPos pos p = p { playerPos = pos }


-- Cộng thêm điểm phạt.
addPenalty :: Int -> Player -> Player
addPenalty n p = p { playerPenalty = playerPenalty p + n }


-- Thêm một ô vào vệt đường.
extendTrail :: Position -> Player -> Player
extendTrail pos p = p { playerTrail = T.addStep pos (playerTrail p) }


-- Xóa vệt đường (khi khép vòng hoặc bị mất đất).
resetTrail :: Player -> Player
resetTrail p = p
  {
  playerTrail = T.clearTrail
    , playerTrailStart = Nothing
  }



