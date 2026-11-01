module PlayerSpec (spec) where

import Types (Position(..), Trail(..))
import Test.Hspec
import Player

spec :: Spec
spec = do
  it "newPlayer: đúng mã, vị trí, chưa có vệt, chưa bị phạt" $ do
    let p = newPlayer P1 (Position 1 1)
    playerId p `shouldBe` P1
    playerPos p `shouldBe` (Position 1 1)
    playerTrail p `shouldBe` Trail []
    playerPenalty p `shouldBe` 0
  it "opponent đổi P1 <-> P2" $ do
    opponent P1 `shouldBe` P2
    opponent P2 `shouldBe` P1
  it "setPlayerPos đổi vị trí" $
    playerPos (setPlayerPos (Position 4 7) (newPlayer P2 (Position 0 0))) `shouldBe` (Position 4 7)
  it "addPenalty cộng dồn" $
    playerPenalty (addPenalty 5 (addPenalty 5 (newPlayer P1 (Position 0 0)))) `shouldBe` 10
  it "extendTrail thêm ô mới vào đầu vệt, resetTrail xóa sạch" $ do
    let p = extendTrail (Position 2 1) (extendTrail (Position 1 1) (newPlayer P1 (Position 0 0)))
    playerTrail p `shouldBe` Trail[Position 2 1, Position 1 1]
    playerTrail (resetTrail p) `shouldBe` Trail []
