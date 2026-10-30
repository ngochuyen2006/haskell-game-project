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
movePlayer :: Position -> Direction -> (Int,Int) -> Position
movePlayer (x,y) dir (width, height) = 
    let (nx,ny) = case dir of 
                    MUp -> (x,y -1)
                    MDown -> (x,y+1)
                    MLeft -> (x-1,y)
                    MRight -> (x+1,y)
    in 
        if nx >= 0 && nx < width && ny >=0 && ny < height -- kiểm tra vượt biên lần lượt là biên trái, phải, trên, dưới
        then (nx,ny) -- không vượt thì trả về (nx,ny)
        else (x,y) -- vượt thì đứng yên tại tọa độ vị trí cũ.

-- nhận vào vị trí hiện tại của người chơi, nhận vào danh sách đường đang đi của đối thủ và trả về xem có va chạm không
--trong main sẽ gọi ra để coi có phạt không
collisions :: Position -> [Position] -> Bool
collision target trail = chưa có
    case trail of  
        [] -> False-- nếu vị trí hiện tại chưa có ( bắt dàu game) thi trả false
        (x:xs) -> if target == x then True else collision target xs
-- trả về true false




main :: IO ()
main = do
    hSetBuffering stdin NoBuffering
    hSetEcho stdin False

    putStrLn "Nhan phim mui ten de kiem tra:"
    c1 <- getChar
    print (fromEnum c1)

    hSetEcho stdin True
    hSetBuffering stdin LineBuffering
