module Collision
  ( collisions
  , cellsToClose
  ) where

import Data.List (sortOn)
import Types
import Trail (isInTrail)

-- Kiểm tra vị trí có nằm trong trail hay không.
collisions :: Position -> Trail -> Bool
collisions target trail = isInTrail target trail


-- Chọn các ô đất cần xóa khi người chơi bị phạt.
-- Ưu tiên những ô gần vị trí va chạm nhất.
cellsToClose :: Position -> [Position] -> [Position]
cellsToClose hitPos victimCells =
    take numberToClose (sortOn distanceToHit victimCells)
  where
    numberToClose = length victimCells `div` 2
    hx = posX hitPos
    hy = posY hitPos

    distanceToHit (Position x y) =
        abs (x - hx) + abs (y - hy)