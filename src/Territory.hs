module Territory where

import Types
import Map
import Trail
import qualified Data.Set as S
import qualified Data.Vector as V
import Data.List (foldl')

--hàm xử lý chiếm đất (khi người chơi đóng đường đi)
claimTerritory :: Trail -> GameMap -> GameMap
claimTerritory (Trail trail) gameMap@(GameMap w h _) =
    let -- Chuyển trail sang Set để kiểm tra (`member`) nhanh hơn O(log n)
        trailSet = S.fromList trail
        
        -- Tìm các ô thuộc vùng ngoài bằng Flood Fill
        outsideCells = findOutsideCells gameMap trailSet

        -- Ô trống nằm bên trong vùng bao vây (Không thuộc outside và không nằm trên trail)
        enclosedPositions = 
            [ Position x y 
            | y <- [0 .. h - 1]
            , x <- [0 .. w - 1]
            , let pos = Position x y
            , getTile pos gameMap == Just Empty
            , not (pos `S.member` outsideCells)
            , not (pos `S.member` trailSet) 
            ]

        -- Cập nhật các ô bên trong thành Territory
        mapWithTerritory = foldl' (\m pos -> setTile pos Territory m) gameMap enclosedPositions
        
        -- Cập nhật các ô trên trail thành Territory
        mapFinal = foldl' (\m pos -> setTile pos Territory m) mapWithTerritory trail
    in mapFinal

-- Thuật toán BFS flood fill theo layer-by-layer xuất phát từ biên bản đồ
findOutsideCells :: GameMap -> S.Set Position -> S.Set Position
findOutsideCells gameMap trailSet = expandLayers initialQueue initialVisited
  where
    -- Lấy tất cả các ô ở mép biên ngoài cùng
    allBorderNodes = [ Position x y | x <- [0, w-1], y <- [0 .. h-1] ] 
                  ++ [ Position x y | x <- [0 .. w-1], y <- [0, h-1] ]
    
    (GameMap w h _) = gameMap

    -- Kiểm tra vật cản chặn nước loang
    isBarrier pos = case getTile pos gameMap of
        Just Wall      -> True
        Just Territory -> True
        _              -> pos `S.member` trailSet

    -- SỬA LỖI: Chỉ xuất phát từ những ô biên KHÔNG BỊ CHẶN
    initialQueue   = filter (not . isBarrier) allBorderNodes
    initialVisited = S.fromList initialQueue

    -- Hàm duyệt từng tầng (expandLayers)
    expandLayers [] visited = visited
    expandLayers currentLayer visited =
        let nextLayer = 
                [ neighbor 
                | p <- currentLayer
                , neighbor <- getNeighbors p w h
                , not (neighbor `S.member` visited)
                , not (isBarrier neighbor)
                ]
            -- Dùng S.union hoặc foldl' để gộp tầng mới vào tập hợp đã thăm
            newVisited = foldl' (flip S.insert) visited nextLayer
        in expandLayers nextLayer newVisited

-- Lấy danh sách 4 ô lân cận nằm trong biên hợp lệ
getNeighbors :: Position -> Int -> Int -> [Position]
getNeighbors (Position x y) w h = 
    filter (\(Position nx ny )-> nx >= 0 && nx < w && ny >= 0 && ny < h)
           [Position(x+1)  y, Position(x-1) y, Position x (y+1), Position x (y-1)]

-- Tính tổng số ô lãnh thổ hiện tại để tính điểm số
calculateTerritorySize :: GameMap -> Int
calculateTerritorySize (GameMap _ _ g) = V.length (V.filter (== Territory) g)