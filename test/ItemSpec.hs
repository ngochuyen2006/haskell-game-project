module ItemSpec (spec) where
import Test.Hspec
import Items
import Types (Position(..))

spec :: Spec
spec = do
    describe "Items" $ do
        -- Kiểm thử nextSeed
        describe "nextSeed" $ do
            it "tạo seed tiếp theo theo công thức LCG" $ do
                nextSeed 1 `shouldBe` 1103527590
            it "trả về 12345 khi seed ban đầu bằng 0" $ do
                nextSeed 0 `shouldBe` 12345
            it "cho kết quả giống nhau khi đầu vào giống nhau" $ do
                nextSeed 2026 `shouldBe` nextSeed 2026

        -- Kiểm thử randomFreeCell
        describe "randomFreeCell" $ do
            it "chọn một ô nằm trong phạm vi bản đồ" $ do
                let w = 10
                    h = 8
                    seed = 1
                    (result, newSeed) = randomFreeCell w h [] seed
                case result of
                    Nothing ->expectationFailure "Không chọn được ô trống"
                    Just  (Position x y) -> do
                        x `shouldSatisfy` (>= 0)
                        x `shouldSatisfy` (< w)
                        y `shouldSatisfy` (>= 0)
                        y `shouldSatisfy` (< h)
                newSeed `shouldBe` nextSeed (nextSeed seed)

            it "không chọn ô đã nằm trong danh sách blocked" $ do
                let w = 10
                    h = 8
                    seed = 1
                    s1 = nextSeed seed
                    s2 = nextSeed s1
                    blockedPos = Position
                            ((s1 `div` 65536) `mod` w)
                            ((s2 `div` 65536) `mod` h)
                    (result, _) = randomFreeCell w h [blockedPos] seed

                case result of
                    Nothing -> expectationFailure "Không chọn được ô trống sau khi thử lại"
                    Just pos -> pos `shouldNotBe` blockedPos

            it "trả về Nothing khi tất cả ô trên bản đồ đều bị chặn" $ do
                let w = 2
                    h = 2
                    seed = 1
                    blocked =
                        [ Position 0 0
                        , Position 0 1
                        , Position 1 0
                        , Position 1 1
                        ]

                    (result, finalSeed) = randomFreeCell w h blocked seed
                result `shouldBe` Nothing
                finalSeed `shouldBe` iterate nextSeed seed !! 40


        -- Kiểm thử ageItems
        describe "ageItems" $ do
            it "tăng tuổi của tất cả vật phẩm theo dt" $ do
                let items =
                        [ Item Bomb (Position 1 2) 2.5
                        , Item Expand (Position 3 4) 0.0
                        ]
                    expected =
                        [ Item Bomb (Position 1 2) 4.0
                        , Item Expand (Position 3 4) 1.5
                        ]
                ageItems 1.5 items `shouldBe` expected
            it "giữ nguyên tuổi vật phẩm khi dt bằng 0" $ do
                let items =
                        [ Item Bomb (Position 1 2) 3.0
                        , Item Expand (Position 3 4) 5.0
                        ]
                ageItems 0 items `shouldBe` items

            it "trả về danh sách rỗng khi không có vật phẩm" $ do
                ageItems 1.5 [] `shouldBe` []

        -- Kiểm thử countKind
        describe "countKind" $ do
            let items =
                    [ Item Bomb (Position 1 2) 1.0
                    , Item Expand (Position 3 4) 2.0
                    , Item Bomb (Position 5 6) 3.0
                    ]
            it "đếm chính xác số lượng Bomb" $ do
                countKind Bomb items `shouldBe` 2
            it "đếm chính xác số lượng Expand" $ do
                countKind Expand items `shouldBe` 1
            it "trả về 0 khi danh sách không có vật phẩm thuộc loại cần đếm" $ do
                countKind Bomb [] `shouldBe` 0
