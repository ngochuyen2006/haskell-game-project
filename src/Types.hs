module Types where

--các kiểu di chuyển của player theo bốn hướng
data Direction = MUp | MDown | MLeft | MRight 
    deriving (Eq, Show)
--kiểu vị trí được định nghĩa gồm (hàng, cột)
-- vị trí hiện tại 
type Position = (Int, Int)

--một danh sách các vị trí (Position)
type Trail = [Position]