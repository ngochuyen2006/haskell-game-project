module MapSpec (spec) where

import Types (Position(..))
import Test.Hspec
import Map

spec :: Spec
spec = do
  it "newMap lưu đúng kích thước" $ do
    mapWidth (newMap 10 10) `shouldBe` 10
    mapHeight (newMap 10 10) `shouldBe` 10
  it "inBounds: góc (0,0) hợp lệ" $
    inBounds (Position 0 0) (newMap 10 10) `shouldBe` True
  it "inBounds: (9,9) hợp lệ" $
    inBounds (Position 9 9) (newMap 10 10) `shouldBe` True
  it "inBounds: x = 10 ngoài biên" $
    inBounds (Position 10 5) (newMap 10 10) `shouldBe` False
  it "inBounds: tọa độ âm ngoài biên" $
    inBounds (Position (-1) 5) (newMap 10 10) `shouldBe` False
  it "renderMap: có đúng 1 chữ P" $
    length (filter (== 'P') (renderMap (newMap 10 10) (Position 3 3))) `shouldBe` 1
  it "renderMap: hàng đầu toàn tường" $
    head (lines (renderMap (newMap 10 10) (Position 3 3))) `shouldBe` replicate 10 '#'
