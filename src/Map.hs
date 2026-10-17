module Map where
--này tự định nghĩa để code độc lập trước

import types

{-đoạn dưới là kiểu dữ liệu định nghĩa dạng bản ghi,
lưu trữ hai trường dữ liệu kiểu số nguyên: chiều rộng và chiều cao,
bản ghi sẽ tự động sinh ra sẵn hai hàm lấy giá trị (getter) tương ứng
để dễ dàng gọi ra dùng
-}
data GameMap = GameMap 
  { mapWidth  :: Int
  , mapHeight :: Int
  } deriving (Show, Eq)

--khởi tạo bản đồ với chiều rộng w và chiều cao h
newMap :: Int -> Int -> GameMap
newMap w h = GameMap w h

--check xem 1 tọa độ bất kỳ có nằm trong biên bản đồ hay k
inBounds :: Position -> GameMap -> Bool
inBounds (x, y) (GameMap w h) = 
  x >= 0 && x < w && y >= 0 && y < h
{-dòng trên kiểm tra cùng lúc 4 đkien:
x >= 0: Hoành độ x phải lớn hơn hoặc bằng mép trái (không bị âm)
x < w: Hoành độ x phải nhỏ hơn chiều rộng w (không vượt quá mép phải)
y >= 0: Tung độ y phải lớn hơn hoặc bằng mép trên (không bị âm)
y < h: Tung độ y phải nhỏ hơn chiều cao h (không rơi xuống dưới đáy)
-}

--vẽ bản đồ
{-mục tiêu: Chuyển cấu trúc GameMap và vị trí hiện tại của người chơi (Position) 
thành một bức tranh dạng chữ (String) để in ra màn hình qua lệnh putStrLn
-}
renderMap :: GameMap -> Position -> String
--playerPos là vị trí người chơi
renderMap (GameMap w h) playerPos = unlines [ renderRow y | y <- [0 .. h - 1] ]
{-danh sách trên có nghĩa là "hãy lần lượt gọi hàm renderRow để vẽ từng hàng y 
(chạy từ hàng số 0 ở trên cùng xuống đến hàng cuối cùng h - 1 ở đáy)".
Từ đó thu được một danh sách các dòng chữ mà mỗi dòng là 1 hàng ngang.
unlines dùng để ghép danh sách các dòng chữ đó lại
với nhau thành một chuỗi duy nhất, cách nhau bởi ký tự xuống dòng (\n)
-}
  where
    --vẽ từng hàng y
    --getCharForCell được gọi tại mỗi ô tọa độ để quyết định xem ô đó nên là ký tự gì
    renderRow y = [ getCharForCell (x, y) | x <- [0 .. w - 1] ]
    
    --xác định ký tự tại mỗi ô tọa độ
    getCharForCell pos
      | pos == playerPos = 'P'          --vị trí người chơi
      | isWall pos       = '#'          --tường biên xung quanh
      | otherwise        = '.'          --ô trống bên trong

    --kiểm tra xem một tọa độ có phải là tường biên hay không
    isWall (x, y) = x == 0 || x == w - 1 || y == 0 || y == h - 1
--vì sao lại là w - 1 và h - 1?
--vì index bắt đầu từ số 0. Nếu w = 10 thì đến mép nó là 9