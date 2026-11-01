module CollisionSpec (spec) where
import Test.Hspec
import Collision
import Types (Position(..), Trail(..))


spec :: Spec
spec = do
    describe "Collision" $ do
        -- Kiểm thử collisions
        describe "collisions" $ do
            it "trả về True khi vị trí nằm trong Trail" $ do
                let trail = Trail
                        [ Position 1 2
                        , Position 2 2
                        , Position 3 2
                        ]
                collisions (Position 2 2) trail `shouldBe` True

            it "trả về False khi vị trí không nằm trong Trail" $ do
                let trail = Trail
                        [ Position 1 2
                        , Position 2 2
                        , Position 3 2
                        ]
                collisions (Position 4 2) trail `shouldBe` False

            it "trả về False khi Trail rỗng" $ do
                collisions (Position 1 2) (Trail []) `shouldBe` False
        -- Kiểm thử cellsToClose
        describe "cellsToClose" $ do
            it "chỉ chọn một nửa số ô khi số lượng ô là số chẵn" $ do
                let hitPos = Position 0 0
                    victimCells =
                        [ Position 3 0
                        , Position 0 2
                        , Position 1 0
                        , Position 0 1
                        ]
                cellsToClose hitPos victimCells
                    `shouldBe` [Position 1 0, Position 0 1]
            it "làm tròn xuống khi số lượng ô là số lẻ" $ do
                let hitPos = Position 0 0
                    victimCells =
                        [ Position 3 0
                        , Position 1 0
                        , Position 4 0
                        , Position 2 0
                        , Position 5 0
                        ]
                cellsToClose hitPos victimCells
                    `shouldBe` [Position 1 0, Position 2 0]
            it "ưu tiên các ô có khoảng cách Manhattan gần vị trí va chạm nhất" $ do
                let hitPos = Position 0 0
                    victimCells =
                        [ Position 4 0
                        , Position 2 0
                        , Position 1 0
                        , Position 3 0
                        ]
                cellsToClose hitPos victimCells
                    `shouldBe` [Position 1 0, Position 2 0]
            it "giữ thứ tự ban đầu khi các ô có cùng khoảng cách" $ do
                let hitPos = Position 0 0
                    victimCells =
                        [ Position 0 1
                        , Position 1 0
                        , Position 2 0
                        , Position 0 2
                        ]
                cellsToClose hitPos victimCells
                    `shouldBe` [Position 0 1, Position 1 0]
            it "trả về danh sách rỗng khi không có ô đất" $ do
                cellsToClose (Position 0 0) [] `shouldBe` []
            it "trả về danh sách rỗng khi chỉ có một ô đất" $ do
                cellsToClose (Position 0 0) [Position 1 0]
                    `shouldBe` []
