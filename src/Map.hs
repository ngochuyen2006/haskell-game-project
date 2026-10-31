module Map where

import Types
import qualified Data.Vector as V

--Các loại ô trên bản đồ
data Tile
  = Empty --ô trống (.)
  | Wall --tường (#)
  | Territory --lãnh thổ đã chiếm (O)
  | TrailTile --đường đi đang vẽ (*)
  deriving (Show, Eq) 

{-đoạn dưới là kiểu dữ liệu định nghĩa dạng bản ghi,
lưu trữ ba trường dữ liệu kiểu số nguyên: chiều rộng,chiều cao và ma trận grid,
bản ghi sẽ tự động sinh ra sẵn hai hàm lấy giá trị (getter) tương ứng
để dễ dàng gọi ra dùng.
-}
data GameMap = GameMap 
  { mapWidth :: Int
  , mapHeight :: Int
  , grid :: V.Vector Tile
  } deriving (Show, Eq)

{-khởi tạo bản đồ với chiều rộng w, chiều cao h và khởi tạo vector,
w * h là tổng số ô,
initCell là thuật toán cho các dòngk ma trận thành 1 dòng
-}
newMap :: Int -> Int -> GameMap
newMap w h = GameMap w h (V.generate (w * h) initCell)
  where
    --để máy hiểu idx của 1 chiều ở tọa độ nào trên map 2 chiều
    initCell idx = 
      let x = idx `mod` w --cột mấy
          y = idx `div` w --hàng mấy
      in if x == 0 || x == w - 1 || y == 0 || y == h - 1 
         then Wall 
         else Empty

--check xem 1 tọa độ bất kỳ có nằm trong biên bản đồ hay k
inBounds :: Position -> GameMap -> Bool
inBounds (Position x y) (GameMap w h _) = 
  x >= 0 && x < w && y >= 0 && y < h

{-hàm này chỉ đọc thôi, như là biết trạng thái ô đang có gì,
hàm này giúp renderMap biết ô đó là # hay . để in ra màn hình,
dùng maybe trả về just để k bị crash nếu tọa độ lỗi
-}
getTile :: Position -> GameMap -> Maybe Tile
--gắn lại tên sau khi phân rã để ném vào inBounds, dùng @
getTile pos@(Position x y) gameMap@(GameMap w h g)
  --(y * w + x) là đang ở 2 chiều, truy về 1 chiều (đang ở idx mấy)
  | inBounds pos gameMap = Just (g V.! (y * w + x))
  | otherwise = Nothing

--cập nhật trạng thái một ô trên bản đồ (thay đổi từ hành động của người chơi)
setTile :: Position -> Tile -> GameMap -> GameMap
--newTile là ô mang gtri mới
setTile pos@(Position x y) newTile gameMap@(GameMap w h g)
  | not (inBounds pos gameMap) = gameMap
  --phải trả về gameMap vì nếu đã k có trong map rồi mà còn cố đi tìm trong vector nữa thì crash
  | otherwise = GameMap w h (g V.// [(y * w + x, newTile)])

--vẽ bản đồ
{-mục tiêu: Chuyển cấu trúc GameMap và vị trí hiện tại của người chơi (Position) 
thành một bức tranh dạng chữ (String) để in ra màn hình qua lệnh putStrLn
-}
renderMap :: GameMap -> Position -> String
--playerPos là vị trí người chơi
renderMap (GameMap w h g) playerPos = unlines [ renderRow y | y <- [0 .. h - 1] ]
{-danh sách trên có nghĩa là "hãy lần lượt gọi hàm renderRow để vẽ từng hàng y 
(chạy từ hàng số 0 ở trên cùng xuống đến hàng cuối cùng h - 1 ở đáy)".
Từ đó thu được một danh sách các dòng chữ mà mỗi dòng là 1 hàng ngang.
unlines dùng để ghép danh sách các dòng chữ đó lại
với nhau thành một chuỗi duy nhất, cách nhau bởi ký tự xuống dòng (\n)
-}
  where
    --vẽ từng hàng y
    --getCharForCell được gọi tại mỗi ô tọa độ để quyết định xem ô đó nên là ký tự gì
    renderRow y = [ getCharForCell (Position x y) | x <- [0 .. w - 1] ]
    
    --xác định ký tự tại mỗi ô tọa độ
    getCharForCell pos@(Position x y)
      | pos == playerPos = 'P' --vị trí người chơi
      | otherwise = case getTile pos (GameMap w h g) of
          Just Wall -> '#'
          Just Territory -> 'O'
          Just TrailTile -> '*'
          Just Empty -> '.'
          Nothing -> ' '

--vì sao lại là w - 1 và h - 1?
--vì index bắt đầu từ số 0. Nếu w = 10 thì đến mép nó là 9