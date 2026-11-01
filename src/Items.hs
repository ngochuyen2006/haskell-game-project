module Items
  ( ItemKind(..)
  , Item(..)
  , nextSeed
  , randomFreeCell
  , ageItems
  , countKind
  ) where

import Types (Position(..))

-- Bom: đạp vô là mất trail.  Expand: phình lãnh địa 3x3.
data ItemKind = Bomb | Expand
  deriving (Show, Eq)

data Item = Item
  { itemKind :: ItemKind
  , itemPos  :: Position
  , itemAge  :: Double      -- số giây đã tồn tại (bom tự biến mất khi quá cũ)
  } deriving (Show, Eq)

{- Bộ sinh số giả ngẫu nhiên (LCG) đơn giản, không cần thêm thư viện `random`.
   Cùng seed thì cho cùng kết quả, nên test được.
-}
nextSeed :: Int -> Int
nextSeed s = (s * 1103515245 + 12345) `mod` 2147483648

{- Chọn một ô ngẫu nhiên trong bản đồ w x h, không nằm trong danh sách `blocked`.
   Thử tối đa 20 lần; trả về (ô chọn được, seed mới).
-}
randomFreeCell :: Int -> Int -> [Position] -> Int -> (Maybe Position, Int)
randomFreeCell w h blocked = go (20 :: Int)
  where
    go 0 s = (Nothing, s)
    go n s =
      let s1 = nextSeed s
          s2 = nextSeed s1
          p  = Position ((s1 `div` 65536) `mod` max 1 w)
                        ((s2 `div` 65536) `mod` max 1 h)
      in if p `elem` blocked then go (n - 1) s2 else (Just p, s2)

-- Tăng tuổi của mọi vật phẩm thêm dt giây.
ageItems :: Double -> [Item] -> [Item]
ageItems dt = map (\i -> i { itemAge = itemAge i + dt })

-- Đếm số vật phẩm thuộc một loại.
countKind :: ItemKind -> [Item] -> Int
countKind k = length . filter ((== k) . itemKind)
