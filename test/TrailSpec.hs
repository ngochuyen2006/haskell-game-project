module TrailSpec (spec) where
import Test.Hspec
import Trail
import Types (Position(..), Trail(..))


spec :: Spec
spec = do
    describe "Trail" $ do
        -- Kiểm thử initTrail
        describe "initTrail" $ do
            it "khởi tạo Trail rỗng" $ do
                initTrail `shouldBe` Trail []
        -- Kiểm thử addStep
        describe "addStep" $ do
            it "thêm vị trí mới vào đầu Trail" $ do
                let trail = Trail [Position 2 2, Position 1 2]
                addStep (Position 3 2) trail `shouldBe`
                    Trail
                        [ Position 3 2
                        , Position 2 2
                        , Position 1 2
                        ]
            it "thêm vị trí vào Trail đang rỗng" $ do
                addStep (Position 1 1) (Trail []) `shouldBe` Trail [Position 1 1]

            it "không làm thay đổi Trail ban đầu" $ do
                let original = Trail [Position 1 1]
                    result = addStep (Position 2 1) original
                original `shouldBe` Trail [Position 1 1]
                result `shouldBe` Trail [Position 2 1, Position 1 1]


        -- Kiểm thử isInTrail
        describe "isInTrail" $ do
            it "trả về True khi vị trí nằm trong Trail" $ do
                let trail =
                        Trail
                            [ Position 1 1
                            , Position 2 1
                            , Position 3 1
                            ]

                isInTrail (Position 2 1) trail `shouldBe` True

            it "trả về False khi vị trí không nằm trong Trail" $ do
                let trail =
                        Trail
                            [ Position 1 1
                            , Position 2 1
                            ]
                isInTrail (Position 3 1) trail `shouldBe` False
            it "trả về False khi Trail rỗng" $ do
                isInTrail (Position 1 1) (Trail []) `shouldBe` False


        -- Kiểm thử clearTrail
        describe "clearTrail" $ do
            it "trả về Trail rỗng" $ do
                clearTrail `shouldBe` Trail []
            it "xóa được Trail đang có nhiều vị trí khi gán kết quả clearTrail" $ do
                let trail =
                        Trail
                            [ Position 1 1
                            , Position 2 1
                            , Position 3 1
                            ]
                    clearedTrail = clearTrail
                clearedTrail `shouldBe` Trail []
                isInTrail (Position 2 1) clearedTrail `shouldBe` False
