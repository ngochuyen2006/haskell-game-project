module Movement where
import Types
import Data.Char(toLower) --chữ thường

--các phép nhập tương ứng hướng di chuyển
--nhập vào thì phải đổi hết thành chữ thường
keyToDir :: Char -> Maybe Direction
keyToDir key =
    case key of
        'w' -> Just MUp
        's' -> Just MDown
        'a' -> Just MLeft
        'd' -> Just MRight
        _ -> Nothing

--nhận vào vị trí hiện tại trả về hàm nhận hướng đi làm đầu vào trả về hàm nhận kích thước bản đồ và trả về vị trí hiện tại
movePlayer :: Position -> Direction -> (Int,Int) -> Position
movePlayer (x,y) dir (width, weight) = 
    let (nx,ny) = case dir of 
                    MUp -> (x,y -1)
                    MDown -> (x,y+1)
                    MLeft -> (x-1,y)
                    MRight -> (x+1,y)
    in 
        if nx >= 0 && nx < width && ny >=0 && ny < weight -- kiểm tra vượt biên lần lượt là biên trái, phải, trên, dưới
        then (nx,ny) -- không vượt thì trả về (nx,ny)
        else (x,y) -- vượt thì đứng yên tại tọa độ vị trí cũ.

