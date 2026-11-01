
module GameSpec (spec) where

import Test.Hspec

import Game
import Items
import Map (Tile(..))
import Player
import Types
import Collision (cellsToClose)

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

--bổ sung thêm để tránh mỗi lần đổi thông số của map (kích thước đất thời gian....) lại phải đổi thủ công
cfg0 :: Config
cfg0 = gsConfig g0

p1Start :: Position
p1Start = playerPos (p1 g0)

p2Start :: Position
p2Start = playerPos (p2 g0)

-- Tính tọa độ tương đối so với một vị trí.
offset :: Position -> Int -> Int -> Position
offset (Position x y) dx dy = Position (x + dx) (y + dy)

-- Vòng đi khép kín tương đối so với vị trí xuất phát P1.
loop1 :: [(PlayerId, Direction)]
loop1 = [ (P1, d) | d <- [MDown, MRight, MDown, MRight, MRight, MUp, MUp, MLeft, MLeft] ]

allCells :: [Position]
allCells = [ Position x y | y <- [0 ..cfgHeight cfg0 -1], x <- [0 .. cfgWidth cfg0 - 1] ]

spec :: Spec
spec = do
  describe "khởi tạo" $ do
    it "vị trí xuất phát và lãnh thổ ban đầu nằm trong bản đồ" $ do
      let inBounds (Position x y) =
            x >= 0 && x < cfgWidth cfg0
            && y >= 0 && y < cfgHeight cfg0

          homeCells (Position x y) =
            [ Position (x + dx) (y + dy)
            | dx <- [-1 .. 1]
            , dy <- [-1 .. 1]
            ]

          Position x1 _ = p1Start
          Position x2 _ = p2Start

      (x1 < x2) `shouldBe` True
      inBounds p1Start `shouldBe` True
      inBounds p2Start `shouldBe` True

      all inBounds (homeCells p1Start) `shouldBe` True
      all inBounds (homeCells p2Start) `shouldBe` True

      all (\pos -> landAt P1 pos g0) (homeCells p1Start)
        `shouldBe` True
      all (\pos -> landAt P2 pos g0) (homeCells p2Start)
        `shouldBe` True

    it "mỗi người có đất 3x3 = 9 ô, điểm bằng nhau, đang chơi, đủ giờ" $ do
      territorySize P1 g0 `shouldBe` 9
      territorySize P2 g0 `shouldBe` 9
      scoreOf P1 g0 `shouldBe` scoreOf P2 g0
      gsStatus g0 `shouldBe` Playing
      gsTimeLeft g0 `shouldBe` cfgDuration cfg0

    it "hai mảnh đất không chồng lên nhau" $
      [ c | c <- allCells, landAt P1 c g0, landAt P2 c g0 ] `shouldBe` []

    it "mỗi người có đất 3x3 = 9 ô, điểm bằng nhau, đang chơi, đủ giờ" $ do
      territorySize P1 g0 `shouldBe` 9
      territorySize P2 g0 `shouldBe` 9
      scoreOf P1 g0 `shouldBe` scoreOf P2 g0
      gsStatus g0 `shouldBe` Playing
      gsTimeLeft g0 `shouldBe` cfgDuration cfg0

    it "hai mảnh đất không chồng lên nhau" $
      [ c | c <- allCells, landAt P1 c g0, landAt P2 c g0 ] `shouldBe` []

  describe "di chuyển" $ do
    it "P1 đi lên thì y giảm 1, P2 đi trái thì x giảm 1" $ do
      playerPos (p1 (play [(P1, MUp)] g0))
        `shouldBe` offset p1Start 0 (-1)

      playerPos (p2 (play [(P2, MLeft)] g0))
        `shouldBe` offset p2Start (-1) 0

    it "ra khỏi đất nhà thì bắt đầu để lại vệt đường" $ do
      let trailPos = offset p1Start 2 0
          g = play [(P1, MRight), (P1, MRight)] g0

      playerPos (p1 g) `shouldBe` trailPos
      playerTrail (p1 g) `shouldBe` Trail [trailPos]

    it "đi trong đất nhà thì không có vệt" $
      playerTrail (p1 (play [(P1, MRight), (P1, MUp)] g0))
        `shouldBe` Trail []

  describe "va chạm bị phạt" $ do
    it "ra ngoài biên: đứng yên, -5 điểm" $ do
      let g = play [(P1, MLeft)] (withPos P1 (Position 0 0) g0)
      playerPos (p1 g) `shouldBe` Position 0 0
      playerPenalty (p1 g) `shouldBe` 5
      scoreOf P1 g `shouldBe` 4
      gsEvent g `shouldBe` Just (EvOutOfBounds P1)


    it "chạm Trail đối thủ: đối thủ mất 50% đất, mất Trail cũ và trở về ô đất cuối cùng bị xóa" $ do
      let extraLand = offset p2Start (-2) 0
          gStart = setLandCells P2 Territory [extraLand] g0

          -- P2 đi ra ngoài đất nhà và tạo Trail.
          g1 = play (replicate 5 (P2, MLeft)) gStart

          -- P1 đi vào Trail của P2.
          hitPos = offset p2Start (-4) 0
          attackerStart = offset hitPos 0 1
          g2 = play [(P1, MUp)] (withPos P1 attackerStart g1)

          victimCells =
            [ c
            | c <- allCells
            , landAt P2 c g1
            ]

          removedCells = cellsToClose hitPos victimCells
          expectedReset = last removedCells

      territorySize P2 g1 `shouldBe` 10
      length removedCells `shouldBe` 5
      territorySize P2 g2 `shouldBe` 5

      playerPos (p2 g2) `shouldBe` expectedReset
      playerTrail (p2 g2) `shouldBe` Trail [expectedReset]
      playerPenalty (p1 g2) `shouldBe` 0
  describe "khép vòng và chiếm đất" $ do
    it "khép vòng bao 1 ô trống: chiếm vệt + ô bị bao" $ do
      let g = play loop1 g0
      territorySize P1 g `shouldBe` 16
      playerTrail (p1 g) `shouldBe` Trail []
      playerPos (p1 g) `shouldBe` offset p1Start 1 0
      gsEvent g `shouldBe` Just (EvClaimed P1 7)
      landAt P1 (offset p1Start 2 1) g `shouldBe` True

    it "vòng bao luôn đất đối thủ thì chiếm phần đó" $ do
      let capturedPos = offset p1Start 2 1
          g = play loop1 (setLandCells P2 Territory [Position 5 9] g0)
      landAt P1 (Position 5 9) g `shouldBe` True
      landAt P2 (Position 5 9) g `shouldBe` False
      territorySize P2 g `shouldBe` 9
      [ c | c <- allCells, landAt P1 c g, landAt P2 c g ] `shouldBe` []

    it "đi ra 1 ô rồi quay lại đất nhà cũng là khép vòng (chiếm đúng ô vệt)" $ do
      let g = play [(P1, MRight), (P1, MRight), (P1, MLeft)] g0
      territorySize P1 g `shouldBe` 10
      playerTrail (p1 g) `shouldBe` Trail []

    it "đi ngược vào Trail của chính mình không bị phạt" $ do
        let g = play [(P1, MRight), (P1, MRight), (P1, MRight), (P1, MLeft)] g0
        playerPenalty (p1 g) `shouldBe` 0

  describe "chạm đối thủ và bao vây" $ do
    it "chủ đất chạm kẻ xâm nhập thì kẻ xâm nhập chết, chủ đất thắng ngay" $ do
      let g = play [(P1, MDown)] (withPos P2 (offset p1Start 0 1) g0)
      gsStatus g `shouldBe` Finished (Win P1 Touched)

    it "kẻ xâm nhập chạm chủ đất: mất 50% lãnh thổ" $ do
      let extraLand = offset p2Start (-2) 0
          invaderStart = offset p1Start 0 1
          gStart = setLandCells P2 Territory [extraLand] g0
          g = play [(P2, MUp)] (withPos P2 invaderStart gStart)

      territorySize P2 gStart `shouldBe` 10
      territorySize P2 g `shouldBe` 5
      playerPenalty (p2 g) `shouldBe` 0

      playerPos (p2 g) `shouldSatisfy` (\pos -> not (landAt P2 pos g))

      gsEvent g `shouldSatisfy` (\event ->
        case event of
          Just (EvBlocked P2 5) -> True
          _ -> False)

    it "bao vây được ô đối thủ đang đứng thì thắng ngay" $ do
      let g = play loop1 (withPos P2 (offset p1Start 2 1) g0)
      gsStatus g `shouldBe` Finished (Win P1 Surrounded)

    it "sau khi ván kết thúc, phím bị bỏ qua" $ do
      let done = play [(P1, MDown)] (withPos P2 (offset p1Start 0 1) g0)
      play [(P1, MUp), (P2, MUp)] done `shouldBe` done

  describe "thời gian, thắng / thua / hòa" $ do
    it "hết giờ, điểm bằng nhau thì hòa" $
      gsStatus (tick (cfgDuration cfg0 + 1) g0) `shouldBe` Finished Draw

    it "hết giờ, ai nhiều điểm hơn thì thắng" $
      gsStatus (tick (cfgDuration cfg0 + 1) (play loop1 g0)) `shouldBe` Finished (Win P1 TimeUp)

    it "điểm phạt được trừ vào điểm khi phân thắng thua" $ do
      let g = play [(P1, MLeft), (P1, MLeft), (P1, MLeft)] (withPos P1 (Position 0 0) g0)
      gsStatus (tick (cfgDuration cfg0 + 1) g) `shouldBe` Finished (Win P2 TimeUp)

    it "đồng hồ giảm đúng và chưa hết giờ thì vẫn đang chơi" $ do
      let dt = min 10 (cfgDuration cfg0 / 2)
          g = tick dt g0
      gsTimeLeft g `shouldBe` (cfgDuration cfg0 - dt)
      gsStatus g `shouldBe` Playing

  describe "vật phẩm" $ do
    it "đến thời gian spawn thì xuất hiện 1 bom và 1 phình lãnh địa" $ do
      let g = tick (cfgSpawnEvery cfg0) g0

      countKind Bomb (gsItems g) `shouldBe` 1
      countKind Expand (gsItems g) `shouldBe` 1

    it "chưa đủ thời gian spawn thì chưa xuất hiện" $
      gsItems (tick (cfgSpawnEvery cfg0 - 0.1) g0) `shouldBe` []

    it "không bao giờ vượt quá số lượng vật phẩm tối đa trong cấu hình" $ do
      let interval = cfgSpawnEvery cfg0
          states = scanl (\g _ -> tick interval g) g0 [1 .. 100 :: Int]

      all
        (\g ->
          countKind Bomb (gsItems g) <= cfgMaxBombs cfg0
          && countKind Expand (gsItems g) <= cfgMaxExpand cfg0
        )
        states `shouldBe` True

    it "bom không ai đạp tự biến mất theo thời gian cấu hình, phình lãnh địa thì không" $ do
      let bombAgeStep = cfgBombLife cfg0 / 10
          center = Position (cfgWidth cfg0 `div` 2) (cfgHeight cfg0 `div` 2)
          nextPos = offset center 1 0

          g = g0
            { gsItems =
                [ Item Bomb center (cfgBombLife cfg0 - bombAgeStep)
                , Item Expand nextPos 99
                ]
            }

      map itemKind (gsItems (tick (2 * bombAgeStep) g)) `shouldBe` [Expand]

    it "vật phẩm không xuất hiện đè lên người chơi" $ do
      let interval = cfgSpawnEvery cfg0
          n = ceiling (cfgDuration cfg0 / interval) :: Int
          states = scanl (\g _ -> tick interval g) g0 [1 .. n]
          ps = [p1Start, p2Start]

      any (\g -> any ((`elem` ps) . itemPos) (gsItems g)) states
        `shouldBe` False

    it "đạp bom khi đang tạo Trail: mất Trail và quay về điểm bắt đầu Trail" $ do
      let bombPos = offset p1Start 4 0
          firstTrailPos = offset p1Start 2 0
          returnPos = offset p1Start 1 0

          gStart = g0
            { gsItems = [Item Bomb bombPos 0] }

          -- P1 đi 3 bước sang phải để tạo Trail.
          gBeforeBomb = play (replicate 3 (P1, MRight)) gStart

          -- P1 bước thêm 1 ô và đạp bom.
          gAfterBomb = applyMove P1 MRight gBeforeBomb

      -- Trail trước khi đạp bom.
      playerTrail (p1 gBeforeBomb)
        `shouldBe` Trail
          [ offset p1Start 3 0
          , firstTrailPos
          ]

      -- Người chơi quay về vị trí bắt đầu Trail.
      playerPos (p1 gAfterBomb) `shouldBe` returnPos

      -- Trail bị xóa hoàn toàn.
      playerTrail (p1 gAfterBomb) `shouldBe` Trail []

      -- Bom biến mất.
      gsItems gAfterBomb `shouldBe` []

    it "nhặt phình lãnh địa: đất mở rộng ra vùng 3x3 quanh vị trí nhặt" $ do
      let expandPos = offset p1Start 2 0
          g = play [(P1, MRight), (P1, MRight)]
                g0 { gsItems = [Item Expand expandPos 0] }

      territorySize P1 g `shouldBe` 15
      gsItems g `shouldBe` []
      playerTrail (p1 g) `shouldBe` Trail []
      gsEvent g `shouldBe` Just (EvExpand P1 6)