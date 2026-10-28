module GameSpec (spec) where

import Test.Hspec

import Game
import Items
import Map (Tile(..))
import Player
import Types

g0 :: GameState
g0 = initGame defaultConfig

-- Thực hiện một dãy nước đi (người chơi, hướng).
play :: [(PlayerId, Direction)] -> GameState -> GameState
play ms gs = foldl (\g (p, d) -> applyMove p d g) gs ms

-- Đặt thẳng vị trí người chơi (chỉ dùng trong test).
withPos :: PlayerId -> Position -> GameState -> GameState
withPos P1 pos gs = gs { gsPlayer1 = (gsPlayer1 gs) { playerPos = pos } }
withPos P2 pos gs = gs { gsPlayer2 = (gsPlayer2 gs) { playerPos = pos } }

p1 :: GameState -> Player
p1 = getPlayer P1

p2 :: GameState -> Player
p2 = getPlayer P2

-- P1 bắt đầu ở (3,8), đất P1 là x 2..4, y 7..9.
-- Vòng này đi ra khỏi đất rồi về lại, bao kín đúng 1 ô trống (5,9):
-- vệt gồm 6 ô + 1 ô bị bao = chiếm thêm 7 ô.
loop1 :: [(PlayerId, Direction)]
loop1 = [ (P1, d) | d <- [MDown, MRight, MDown, MRight, MRight, MUp, MUp, MLeft, MLeft] ]

allCells :: [Position]
allCells = [ (x, y) | x <- [0 .. 29], y <- [0 .. 15] ]

spec :: Spec
spec = do
  describe "khởi tạo" $ do
    it "P1 bên trái, P2 bên phải, cùng hàng giữa" $ do
      playerPos (p1 g0) `shouldBe` (3, 8)
      playerPos (p2 g0) `shouldBe` (26, 8)
    it "mỗi người có đất 3x3 = 9 ô, điểm bằng nhau, đang chơi, đủ giờ" $ do
      territorySize P1 g0 `shouldBe` 9
      territorySize P2 g0 `shouldBe` 9
      scoreOf P1 g0 `shouldBe` scoreOf P2 g0
      gsStatus g0 `shouldBe` Playing
      gsTimeLeft g0 `shouldBe` 60
    it "hai mảnh đất không chồng lên nhau" $
      [ c | c <- allCells, landAt P1 c g0, landAt P2 c g0 ] `shouldBe` []

  describe "di chuyển" $ do
    it "P1 đi lên thì y giảm 1, P2 đi trái thì x giảm 1" $ do
      playerPos (p1 (play [(P1, MUp)] g0)) `shouldBe` (3, 7)
      playerPos (p2 (play [(P2, MLeft)] g0)) `shouldBe` (25, 8)
    it "ra khỏi đất nhà thì bắt đầu để lại vệt đường" $ do
      let g = play [(P1, MRight), (P1, MRight)] g0
      playerPos (p1 g) `shouldBe` (5, 8)
      playerTrail (p1 g) `shouldBe` [(5, 8)]
    it "đi trong đất nhà thì không có vệt" $
      playerTrail (p1 (play [(P1, MRight), (P1, MUp)] g0)) `shouldBe` []

  describe "va chạm bị phạt" $ do
    it "ra ngoài biên: đứng yên, -5 điểm" $ do
      let g = play [(P1, MLeft)] (withPos P1 (0, 0) g0)
      playerPos (p1 g) `shouldBe` (0, 0)
      playerPenalty (p1 g) `shouldBe` 5
      scoreOf P1 g `shouldBe` 4
      gsEvent g `shouldBe` Just (EvOutOfBounds P1)
    it "đụng vệt đường của chính mình: đứng yên, -5 điểm" $ do
      let g = play [(P1, MRight), (P1, MRight), (P1, MDown), (P1, MUp)] g0
      playerPos (p1 g) `shouldBe` (5, 9)
      playerPenalty (p1 g) `shouldBe` 5
      gsEvent g `shouldBe` Just (EvHitTrail P1)
    it "đụng vệt đường của đối thủ cũng bị phạt" $ do
      let g1 = play (replicate 5 (P2, MLeft)) g0          -- P2 ra khỏi đất, vệt ở (24..21, 8)
          g2 = play [(P1, MUp)] (withPos P1 (22, 9) g1)  -- P1 đi lên vào (22,8) là vệt của P2
      playerPenalty (p1 g2) `shouldBe` 5
      playerPos (p1 g2) `shouldBe` (22, 9)
      gsEvent g2 `shouldBe` Just (EvHitTrail P1)

  describe "khép vòng và chiếm đất" $ do
    it "khép vòng bao 1 ô trống: chiếm vệt + ô bị bao" $ do
      let g = play loop1 g0
      territorySize P1 g `shouldBe` 16
      playerTrail (p1 g) `shouldBe` []
      playerPos (p1 g) `shouldBe` (4, 8)
      gsEvent g `shouldBe` Just (EvClaimed P1 7)
      landAt P1 (5, 9) g `shouldBe` True
    it "vòng bao luôn đất đối thủ thì chiếm phần đó" $ do
      let g = play loop1 (setLandCells P2 Territory [(5, 9)] g0)
      landAt P1 (5, 9) g `shouldBe` True
      landAt P2 (5, 9) g `shouldBe` False
      territorySize P2 g `shouldBe` 9
      [ c | c <- allCells, landAt P1 c g, landAt P2 c g ] `shouldBe` []
    it "đi ra 1 ô rồi quay lại đất nhà cũng là khép vòng (chiếm đúng ô vệt)" $ do
      let g = play [(P1, MRight), (P1, MRight), (P1, MLeft)] g0
      territorySize P1 g `shouldBe` 10
      playerTrail (p1 g) `shouldBe` []
    it "quay đầu giữa chừng (đi ngược lên vệt của mình) thì bị phạt, không chiếm được gì" $ do
      let g = play [(P1, MRight), (P1, MRight), (P1, MRight), (P1, MLeft)] g0
      territorySize P1 g `shouldBe` 9
      playerPenalty (p1 g) `shouldBe` 5

  describe "chạm đối thủ và bao vây" $ do
    it "chủ đất chạm kẻ xâm nhập thì kẻ xâm nhập chết, chủ đất thắng ngay" $ do
      let g = play [(P1, MDown)] (withPos P2 (3, 9) g0)
      gsStatus g `shouldBe` Finished (Win P1 Touched)
    it "kẻ xâm nhập chạm chủ đất thì chỉ bị chặn lại, không sao" $ do
      let g = play [(P2, MUp)] (withPos P2 (3, 9) g0)
      gsStatus g `shouldBe` Playing
      playerPos (p2 g) `shouldBe` (3, 9)
      playerPenalty (p2 g) `shouldBe` 0
      gsEvent g `shouldBe` Just (EvBlocked P2)
    it "bao vây được ô đối thủ đang đứng thì thắng ngay" $ do
      let g = play loop1 (withPos P2 (5, 9) g0)
      gsStatus g `shouldBe` Finished (Win P1 Surrounded)
    it "sau khi ván kết thúc, phím bị bỏ qua" $ do
      let done = play [(P1, MDown)] (withPos P2 (3, 9) g0)
      play [(P1, MUp), (P2, MUp)] done `shouldBe` done

  describe "thời gian, thắng / thua / hòa" $ do
    it "hết giờ, điểm bằng nhau thì hòa" $
      gsStatus (tick 61 g0) `shouldBe` Finished Draw
    it "hết giờ, ai nhiều điểm hơn thì thắng" $
      gsStatus (tick 61 (play loop1 g0)) `shouldBe` Finished (Win P1 TimeUp)
    it "điểm phạt được trừ vào điểm khi phân thắng thua" $ do
      let g = play [(P1, MLeft), (P1, MLeft), (P1, MLeft)] (withPos P1 (0, 0) g0)   -- 3 lần ra biên = -15
      gsStatus (tick 61 g) `shouldBe` Finished (Win P2 TimeUp)
    it "đồng hồ giảm đúng và chưa hết giờ thì vẫn đang chơi" $ do
      let g = tick 10 g0
      gsTimeLeft g `shouldBe` 50
      gsStatus g `shouldBe` Playing

  describe "vật phẩm" $ do
    it "sau 3 giây xuất hiện 1 bom và 1 phình lãnh địa" $ do
      let g = tick 3 g0
      countKind Bomb (gsItems g) `shouldBe` 1
      countKind Expand (gsItems g) `shouldBe` 1
    it "chưa đủ 3 giây thì chưa xuất hiện" $
      gsItems (tick 2.9 g0) `shouldBe` []
    it "không bao giờ vượt quá 3 bom và 3 phình lãnh địa cùng lúc" $ do
      let states = scanl (\g _ -> tick 0.5 g) g0 [1 .. 100 :: Int]
      all (\g -> countKind Bomb (gsItems g) <= 3 && countKind Expand (gsItems g) <= 3) states `shouldBe` True
      countKind Expand (gsItems (last states)) `shouldBe` 3
    it "bom không ai đạp tự biến mất sau 10 giây, phình lãnh địa thì không" $ do
      let g = g0 { gsItems = [Item Bomb (10, 10) 9.9, Item Expand (12, 10) 99] }
      map itemKind (gsItems (tick 0.2 g)) `shouldBe` [Expand]
    it "vật phẩm không xuất hiện đè lên người chơi" $ do
      let states = scanl (\g _ -> tick 3 g) g0 [1 .. 15 :: Int]
          ps = [playerPos (p1 g0), playerPos (p2 g0)]
      any (\g -> any ((`elem` ps) . itemPos) (gsItems g)) states `shouldBe` False
    it "đạp bom: mất phần đất trong vùng 3x3 quanh bom" $ do
      let g = play [(P1, MRight)] g0 { gsItems = [Item Bomb (4, 8) 0] }
      territorySize P1 g `shouldBe` 3
      gsItems g `shouldBe` []
      gsEvent g `shouldBe` Just (EvBomb P1 6)
    it "nhặt phình lãnh địa: đất mở rộng ra vùng 3x3 quanh vị trí nhặt" $ do
      let g = play [(P1, MRight), (P1, MRight)] g0 { gsItems = [Item Expand (5, 8) 0] }
      territorySize P1 g `shouldBe` 15
      gsItems g `shouldBe` []
      playerTrail (p1 g) `shouldBe` []
      gsEvent g `shouldBe` Just (EvExpand P1 6)
