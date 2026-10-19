module Territory where

import Types
import Map
import Trail
import qualified Data.Set as S
import qualified Data.Vector as V
import Data.List (foldl')

--hàm xử lý khi người chơi đóng đường đi
claimTerritory :: Trail -> GameMap -> GameMap
claimTerritory trail gameMap@(GameMap w h _) =
    let 
        --tìm các ô thuộc vùng ngoài (ở đây dùng fload fill để xác định)
        outsideCells = findOutsideCells gameMap trail
        
        --ô trống nằm bên trong vùng bao vây sẽ bị đổi thành Territory
        enclosedPositions = [ (x, y) 
                            | y <- [0 .. h - 1]
                            , x <- [0 .. w - 1]
                            , let pos = (x, y) --gán tọa độ vào biến pos
                            , getTile pos gameMap == Just Empty
                            , not (pos `S.member` outsideCells)
                            , not (pos `elem` trail)
                            ]
                            
        --cập nhật bản đồ bằng cách đưa các ô trong vùng kín và vết đi thành Territory
        --dùng foldl' để gom nhóm thêm hàng loạt các ô mới vào tập hợp đã ghé thăm (tính liền chứ k lazy)
        mapWithTerritory = foldl' (\m pos -> setTile pos Territory m) gameMap enclosedPositions
        --gọi settile để cập nhập
        mapFinal = foldl' (\m pos -> setTile pos Territory m) mapWithTerritory trail
    in mapFinal

--thuật toán BFS flood fill theo layer-by-layer
--có thể hiểu đơn giản là nước loang
findOutsideCells :: GameMap -> Trail -> S.Set Position
findOutsideCells gameMap@(GameMap w h _) trail = expandLayers queue initialVisited
{-lệnh cho expandLayers bắt đầu chạy vòng lặp loang vùng
queue: các ô ở mép biên ngoài cùng borderNodes
initialVisited: tập hợp các ô đã được đánh dấu là đã đặt chân tới
-}
  where
    --xuất phát từ tất cả các ô ở mép biên ngoài cùng (các ô đầu tiên nước loang tới)
    borderNodes = [ (x, y) | x <- [0, w-1], y <- [0 .. h-1] ] ++ 
                  [ (x, y) | x <- [0 .. w-1], y <- [0, h-1] ]
    
    initialVisited = S.fromList borderNodes
    queue = borderNodes

    --kiểm tra vật cản như tường, lãnh thổ cũ hoặc vết đi của người chơi
    --có thể hiểu là cái gì chặn nước loang
    isBarrier pos = case getTile pos gameMap of 
                      Just Wall -> True
                      Just Territory -> True
                      _ -> pos `elem` trail

    --hàm duyệt từng tầng (expandLayers)
    --nếu sóng đã lan đi hết cỡ, không còn ô nào để đi nữa thì dừng lại, trả về kết quả
    expandLayers [] visited = visited
    --nếu vẫn còn tầng hiện tại (currentLayer) đang lan
    expandLayers currentLayer visited =
        let 
            --lấy tất cả ô lân cận hợp lệ từ tầng hiện tại, loại bỏ ô đã thăm và vật cản
            nextLayer = [ neighbor
                        | p <- currentLayer
                        , neighbor <- getNeighbors p w h
                        --chưa từng bị nước chảy qua trước đó
                        , not (neighbor `S.member` visited)
                        --hông phải tường hay vệt đi chặn lại
                        , not (isBarrier neighbor)
                        ]
            
            --đánh dấu toàn bộ các ô ở tầng mới (đợt sóng mới) này là đã thăm
            newVisited = foldl' (flip S.insert) visited nextLayer
            
        --đệ quy sang tầng tiếp theo với danh sách nextLayer
        in expandLayers nextLayer newVisited

--lấy danh sách 4 ô lân cận trong biên hợp lệ
getNeighbors :: Position -> Int -> Int -> [Position]
getNeighbors (x, y) w h = 
    {-dùng filter để khi nhân vật đang đứng ở x = 0 (đi lùi ra gtri âm khiến crash),
    giữ lại những ô nằm bên trong biên bản đồ, bỏ những ô nào ngoài biên-}
    filter (\(nx, ny) -> nx >= 0 && nx < w && ny >= 0 && ny < h)
           [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]

--tính tổng số ô lãnh thổ hiện tại để tính điểm số
calculateTerritorySize :: GameMap -> Int
calculateTerritorySize (GameMap _ _ g) = 
    V.length (V.filter (== Territory) g)