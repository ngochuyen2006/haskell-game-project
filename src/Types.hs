module Types where

--các kiểu di chuyển của player theo bốn hướng
data Direction = MUp | MDown | MLeft | MRight 
    deriving (Eq, Show)
--kiểu vị trí được định nghĩa gồm (hàng, cột)
-- vị trí hiện tại như vậy dễ truy cập vào tọa độ
data Position = Position
    { posX :: Int, posY :: Int} deriving (Eq, Ord, Show)

--một danh sách các vị trí (Position)
data Trail = Trail [Position] deriving (Eq, Show)