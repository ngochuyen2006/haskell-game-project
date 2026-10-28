module PlayerSpec (spec) where

import Test.Hspec
import Player

spec :: Spec
spec = do
  it "newPlayer: đúng mã, vị trí, chưa có vệt, chưa bị phạt" $ do
    let p = newPlayer P1 (1, 1)
    playerId p `shouldBe` P1
    playerPos p `shouldBe` (1, 1)
    playerTrail p `shouldBe` []
    playerPenalty p `shouldBe` 0
  it "opponent đổi P1 <-> P2" $ do
    opponent P1 `shouldBe` P2
    opponent P2 `shouldBe` P1
  it "setPlayerPos đổi vị trí" $
    playerPos (setPlayerPos (4, 7) (newPlayer P2 (0, 0))) `shouldBe` (4, 7)
  it "addPenalty cộng dồn" $
    playerPenalty (addPenalty 5 (addPenalty 5 (newPlayer P1 (0, 0)))) `shouldBe` 10
  it "extendTrail thêm ô mới vào đầu vệt, resetTrail xóa sạch" $ do
    let p = extendTrail (2, 1) (extendTrail (1, 1) (newPlayer P1 (0, 0)))
    playerTrail p `shouldBe` [(2, 1), (1, 1)]
    playerTrail (resetTrail p) `shouldBe` []
