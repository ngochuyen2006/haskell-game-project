module Movement where
import Types
import System.IO
import Data.Char(toLower) --chữ thường
import Trail (isInTrail)
--các phép nhập tương ứng hướng di chuyển
--nhập vào thì phải đổi hết thành chữ thường
keyToDir :: Char -> Maybe Direction
keyToDir key =
    case toLower key of
        'w' -> Just MUp
        's' -> Just MDown
        'a' -> Just MLeft
        'd' -> Just MRight
        'i' -> Just MUp
        'j' -> Just MLeft
        'l' -> Just MRight
        'k' -> Just MDown
        _ -> Nothing


--nhận vào vị trí hiện tại trả về hàm nhận hướng đi làm đầu vào trả về hàm nhận kích thước bản đồ và trả về vị trí hiện tại
movePlayer :: Position -> Direction -> (Int, Int) -> Position
movePlayer (Position x y) dir (width, height) =
    let (nx, ny) = case dir of
                    MUp    -> (x, y - 1)
                    MDown  -> (x, y + 1)
                    MLeft  -> (x - 1, y)
                    MRight -> (x + 1, y)
    in
        if nx >= 0 && nx < width && ny >= 0 && ny < height
        then Position nx ny
        else Position x y

--mặc định người chơi mới vào game chưa bấm phím gì thì đi thăng lên luôn
defaultmove :: Direction
defaultmove = MUp
