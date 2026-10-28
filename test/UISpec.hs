module UISpec (spec) where

import Data.List (isInfixOf)
import Test.Hspec

import Game
import Items
import Player
import Types
import UI

g0 :: GameState
g0 = initGame defaultConfig

count :: Char -> [String] -> Int
count c = length . filter (== c) . concat

spec :: Spec
spec = do
  describe "bản đồ" $ do
    it "đủ số dòng và độ rộng mỗi dòng (khung + 30x16 ô, mỗi ô 2 ký tự)" $ do
      let b = renderBoard False g0
      length b `shouldBe` 18
      map length b `shouldBe` replicate 18 62
    it "mỗi người chơi đúng 1 ký hiệu, đất hiển thị đủ (9 ô trừ ô người đứng)" $ do
      let b = renderBoard False g0
      count '1' b `shouldBe` 1
      count '2' b `shouldBe` 1
      count 'O' b `shouldBe` 8
      count 'X' b `shouldBe` 8
    it "vệt đường hiển thị bằng o / x" $ do
      let g = foldl (\s (p, d) -> applyMove p d s) g0 [(P1, MRight), (P1, MRight), (P1, MDown), (P1, MDown)]
      count 'o' (renderBoard False g) `shouldBe` 2
    it "bom là @ và phình lãnh địa là +" $ do
      let g = g0 { gsItems = [Item Bomb (10, 3) 0, Item Expand (12, 3) 0] }
      count '@' (renderBoard False g) `shouldBe` 1
      count '+' (renderBoard False g) `shouldSatisfy` (>= 3)   -- 1 ô + và 2 góc khung "+"
    it "chỉ có mã màu khi bật màu" $ do
      concat (renderBoard False g0) `shouldSatisfy` (not . isInfixOf "\ESC[")
      concat (renderBoard True g0) `shouldSatisfy` isInfixOf "\ESC["

  describe "toàn màn hình" $ do
    it "hiện thời gian còn lại và điểm hai người" $ do
      let s = renderGame False g0
      s `shouldSatisfy` isInfixOf "Còn lại: 60 giây"
      s `shouldSatisfy` isInfixOf "P1   Đất: 9   Phạt: -0   Điểm: 9"
      s `shouldSatisfy` isInfixOf "P2   Đất: 9   Phạt: -0   Điểm: 9"
    it "hiện hướng dẫn điều khiển" $
      renderGame False g0 `shouldSatisfy` isInfixOf "W/S/A/D"
    it "hiện thông báo va chạm" $ do
      let g = applyMove P1 MLeft g0 { gsPlayer1 = (gsPlayer1 g0) { playerPos = (0, 0) } }
      renderGame False g `shouldSatisfy` isInfixOf "đi ra ngoài biên"
    it "hiện kết quả hòa / thắng khi hết giờ" $ do
      renderGame False (tick 61 g0) `shouldSatisfy` isInfixOf "HẾT GIỜ - HÒA"
      let win = foldl (\s (p, d) -> applyMove p d s) g0 [ (P1, d) | d <- [MDown, MRight, MDown, MRight, MRight, MUp, MUp, MLeft, MLeft] ]
      renderGame False (tick 61 win) `shouldSatisfy` isInfixOf "P1 THẮNG"
    it "màn hình giới thiệu có tên game và hướng dẫn bắt đầu" $ do
      let s = renderIntro defaultConfig
      s `shouldSatisfy` isInfixOf "CHIẾM ĐẤT"
      s `shouldSatisfy` isInfixOf "Bấm phím bất kỳ"
