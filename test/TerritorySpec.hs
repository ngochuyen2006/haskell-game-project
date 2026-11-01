module TerritorySpec (spec) where
import Test.Hspec
import Territory
import Map
import Types (Position(..), Trail(..))
import qualified Data.Set as S
import qualified Data.Vector as V


-- Tạo bản đồ chỉ gồm các ô Empty.
blankMap :: Int -> Int -> GameMap
blankMap w h = GameMap w h (V.replicate (w * h) Empty)

spec :: Spec
spec = do
    describe "Territory" $ do
        -- Kiểm thử getNeighbors
        describe "getNeighbors" $ do
            it "trả về đúng 4 ô lân cận khi vị trí nằm giữa bản đồ" $ do
                getNeighbors (Position 2 2) 5 5
                    `shouldBe`
                    [ Position 3 2
                    , Position 1 2
                    , Position 2 3
                    , Position 2 1
                    ]
            it "loại bỏ các vị trí nằm ngoài biên khi ở góc bản đồ" $ do
                getNeighbors (Position 0 0) 5 5
                    `shouldBe`
                    [ Position 1 0
                    , Position 0 1
                    ]
            it "chỉ trả về các vị trí nằm trong biên khi ở cạnh bản đồ" $ do
                getNeighbors (Position 2 0) 5 5
                    `shouldBe`
                    [ Position 3 0
                    , Position 1 0
                    , Position 2 1
                    ]

        -- Kiểm thử findOutsideCells
        describe "findOutsideCells" $ do
            it "tìm được tất cả ô khi bản đồ không có vật cản" $ do
                let gameMap = blankMap 5 5
                    outside = findOutsideCells gameMap S.empty
                S.size outside `shouldBe` 25
                S.member (Position 2 2) outside `shouldBe` True
            it "không đi xuyên qua ô Wall" $ do
                let gameMap =
                        setTile (Position 2 2) Wall (blankMap 5 5)
                    outside = findOutsideCells gameMap S.empty
                S.member (Position 2 2) outside `shouldBe` False
                S.size outside `shouldBe` 24
            it "không đi xuyên qua ô Territory" $ do
                let gameMap =
                        setTile (Position 2 2) Territory (blankMap 5 5)
                    outside = findOutsideCells gameMap S.empty
                S.member (Position 2 2) outside `shouldBe` False
                S.size outside `shouldBe` 24

            it "không đi xuyên qua các ô nằm trên Trail" $ do
                let gameMap = blankMap 5 5
                    trailSet = S.singleton (Position 2 2)

                    outside = findOutsideCells gameMap trailSet
                S.member (Position 2 2) outside `shouldBe` False
                S.size outside `shouldBe` 24


        -- Kiểm thử claimTerritory
        describe "claimTerritory" $ do
            it "không chiếm thêm ô nào khi Trail rỗng" $ do
                let gameMap = blankMap 5 5
                    result = claimTerritory (Trail []) gameMap
                result `shouldBe` gameMap
            it "chỉ chuyển các ô trên Trail thành Territory khi đường chưa khép kín" $ do
                let gameMap = blankMap 7 7
                    trail = Trail
                        [ Position 2 2
                        , Position 3 2
                        ]

                    result = claimTerritory trail gameMap
                getTile (Position 2 2) result `shouldBe` Just Territory
                getTile (Position 3 2) result  `shouldBe` Just Territory
                getTile (Position 2 3) result `shouldBe` Just Empty

            it "chiếm cả vùng bên trong khi Trail khép kín" $ do
                let gameMap = blankMap 7 7
                    trail = Trail
                        [ Position 2 2
                        , Position 3 2
                        , Position 4 2
                        , Position 4 3
                        , Position 4 4
                        , Position 3 4
                        , Position 2 4
                        , Position 2 3
                        ]
                    result = claimTerritory trail gameMap
                    trailPositions =
                        [ Position 2 2
                        , Position 3 2
                        , Position 4 2
                        , Position 4 3
                        , Position 4 4
                        , Position 3 4
                        , Position 2 4
                        , Position 2 3
                        ]
                getTile (Position 3 3) result `shouldBe` Just Territory
                map (`getTile` result) trailPositions `shouldBe` replicate 8 (Just Territory)
                getTile (Position 0 0) result `shouldBe` Just Empty
                calculateTerritorySize result `shouldBe` 9


        -- Kiểm thử calculateTerritorySize
        describe "calculateTerritorySize" $ do
            it "trả về 0 khi bản đồ chưa có lãnh thổ" $ do
                calculateTerritorySize (blankMap 5 5) `shouldBe` 0

            it "đếm chính xác số ô Territory trên bản đồ" $ do
                let gameMap = blankMap 5 5
                    territoryMap =
                        foldr
                            (\pos m -> setTile pos Territory m)
                            gameMap
                            [ Position 1 1
                            , Position 2 2
                            , Position 3 3
                            ]
                calculateTerritorySize territoryMap
                    `shouldBe` 3

            it "không tính các ô Empty và Wall vào lãnh thổ" $ do
                let gameMap = blankMap 5 5
                    territoryMap =
                        setTile (Position 1 1) Territory $
                        setTile (Position 2 2) Wall gameMap
                calculateTerritorySize territoryMap `shouldBe` 1
