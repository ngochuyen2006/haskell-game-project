module UI
  ( renderGame
  , renderBoard
  , renderIntro
  , describeEvent
  , describeOutcome
  , drawFrame
  , clearScreen
  , hideCursor
  , showCursor
  ) where

import qualified Data.Set as S
import System.IO (hFlush, stdout)

import Game
import Items
import Player
import Types (Position(..), Trail(..))
{- UI chỉ ĐỌC GameState và trả về String: không chứa luật chơi, không đọc phím.
   Muốn đổi giao diện chỉ cần sửa file này.

   Bố cục màn hình (từ trên xuống):
     1. Tiêu đề + thời gian còn lại
     2. Điểm của hai người chơi (đất, phạt, điểm)
     3. Bản đồ (khung + ô)
     4. Thông báo sự kiện gần nhất và trạng thái ván (đang chơi / kết quả thắng-thua-hòa)
     5. Hướng dẫn điều khiển và chú thích ký hiệu

   Ký hiệu trên bản đồ:
     1 / 2 : người chơi P1 / P2      O / X : đất của P1 / P2      o / x : vệt đường của P1 / P2
     @     : bom                     +     : phình lãnh địa         .     : ô trống
-}

{- ===================== MÀU (ANSI) ===================== -}

type Color = Maybe String

blue, red, yellow, green, plain :: Color
blue   = Just "1;34"
red    = Just "1;31"
yellow = Just "1;33"
green  = Just "1;32"
plain  = Nothing

paintText :: Bool -> Color -> String -> String
paintText True (Just code) s = "\ESC[" ++ code ++ "m" ++ s ++ "\ESC[0m"
paintText _    _           s = s

{- ===================== BẢN ĐỒ ===================== -}

-- Mỗi ô rộng 2 ký tự (ký tự + dấu cách) để bản đồ nhìn vuông hơn trong terminal.
renderBoard :: Bool -> GameState -> [String]
renderBoard color gs = [border] ++ map row [0 .. h - 1] ++ [border]
  where
    cfg    = gsConfig gs
    w      = cfgWidth cfg
    h      = cfgHeight cfg
    border = "+" ++ replicate (2 * w) '-' ++ "+"
    row y = "|" ++ concatMap (\x -> cell (Position x y)) [0 .. w - 1] ++ "|"

    p1 = gsPlayer1 gs
    p2 = gsPlayer2 gs
    trail1 = case playerTrail p1 of
              Trail positions -> S.fromList positions

    trail2 = case playerTrail p2 of
              Trail positions -> S.fromList positions
    itemMap = [ (itemPos i, itemKind i) | i <- gsItems gs ]

    cell pos = let (c, col) = glyph pos in paintText color col [c] ++ " "

    -- Thứ tự ưu tiên khi nhiều thứ nằm trên cùng một ô.
    glyph pos
      | pos == playerPos p1                = ('1', blue)
      | pos == playerPos p2                = ('2', red)
      | Just k <- lookup pos itemMap       = case k of
                                               Bomb   -> ('@', yellow)
                                               Expand -> ('+', green)
      | S.member pos trail1                = ('o', blue)
      | S.member pos trail2                = ('x', red)
      | landAt P1 pos gs                   = ('O', blue)
      | landAt P2 pos gs                   = ('X', red)
      | otherwise                          = ('.', plain)

{- ===================== TOÀN MÀN HÌNH ===================== -}

renderGame :: Bool -> GameState -> String
renderGame color gs = unlines $
  [ rule
  , "  CHIẾM ĐẤT - 2 NGƯỜI CHƠI          Còn lại: " ++ show secs ++ " giây"
  , rule
  , scoreLine P1
  , scoreLine P2
  , rule
  ]
  ++ renderBoard color gs ++
  [ rule
  , "  " ++ maybe "" (describeEvent gs) (gsEvent gs)
  , "  " ++ statusText
  , rule
  , "  Điều khiển  P1: W/S/A/D (lên/xuống/trái/phải)   P2: I/K/J/L (lên/xuống/trái/phải)   Q: thoát"
  , "  Ký hiệu     1,2: người chơi   O,X: đất P1,P2   o,x: vệt đường   @: bom   +: phình lãnh địa"
  ]
  where
    secs = ceiling (max 0 (gsTimeLeft gs)) :: Int
    rule = replicate 78 '='

    scoreLine pid =
      "  " ++ show pid
      ++ "   Đất: " ++ show (territorySize pid gs)
      ++ "   Phạt: -" ++ show (playerPenalty (getPlayer pid gs))
      ++ "   Điểm: " ++ show (scoreOf pid gs)

    statusText = case gsStatus gs of
      Playing        -> "Đang chơi..."
      Finished out   -> describeOutcome out

describeOutcome :: Outcome -> String
describeOutcome (Win p TimeUp)     = "HẾT GIỜ - " ++ show p ++ " THẮNG (nhiều điểm hơn)"
describeOutcome (Win p Surrounded) = show p ++ " THẮNG SỚM - bao vây được đối thủ!"
describeOutcome (Win p Touched)    = show p ++ " THẮNG SỚM - đối thủ bị chạm khi đang ở trong đất của " ++ show p ++ "!"
describeOutcome Draw               = "HẾT GIỜ - HÒA"

describeEvent :: GameState -> Event -> String
describeEvent gs ev = case ev of
  EvOutOfBounds p -> show p ++ " đi ra ngoài biên: đứng yên, -" ++ pen ++ " điểm"
  EvHitTrail p    -> show p ++ " đụng vệt đường: đứng yên, -" ++ pen ++ " điểm"
  EvBlocked p  n   -> show p ++ " chạm đối thủ: bị chặn lại"
  EvClaimed p n   -> show p ++ " khép vòng, chiếm thêm " ++ show n ++ " ô"
  EvBomb p n      -> show p ++ " đạp trúng bom: mất " ++ show n ++ " ô đất"
  EvExpand p n    -> show p ++ " nhặt phình lãnh địa: thêm " ++ show n ++ " ô đất"
  where pen = show (cfgPenalty (gsConfig gs))

-- Màn hình giới thiệu trước khi bắt đầu.
renderIntro :: Config -> String
renderIntro cfg = unlines
  [ replicate 78 '='
  , "  CHIẾM ĐẤT - 2 NGƯỜI CHƠI"
  , replicate 78 '='
  , "  Mục tiêu: chiếm nhiều đất hơn đối thủ trước khi hết " ++ show (round (cfgDuration cfg) :: Int) ++ " giây."
  , ""
  , "  - Đi ra khỏi đất nhà sẽ để lại vệt đường; vòng về lại đất nhà để chiếm vùng bị bao."
  , "  - Vòng bao luôn đất đối thủ thì chiếm cả phần đó. Bao vây được đối thủ là thắng ngay."
  , "  - Đứng trong đất đối thủ mà bị họ chạm vào thì bạn thua ngay."
  , "  - Đụng vệt đường hoặc ra ngoài biên: đứng yên và bị trừ " ++ show (cfgPenalty cfg) ++ " điểm."
  , "  - @ là bom (mất đất khi đạp trúng), + là phình lãnh địa (mở rộng đất 3x3)."
  , ""
  , "  Điều khiển   P1: W/S/A/D   P2: I/K/J/L   Q: thoát"
  , ""
  , "  Bấm phím bất kỳ để bắt đầu..."
  ]

{- ===================== TERMINAL ===================== -}

clearScreen :: IO ()
clearScreen = putStr "\ESC[2J\ESC[H" >> hFlush stdout

hideCursor :: IO ()
hideCursor = putStr "\ESC[?25l" >> hFlush stdout

showCursor :: IO ()
showCursor = putStr "\ESC[?25h" >> hFlush stdout

-- Vẽ lại từ góc trên-trái, xóa phần thừa cuối mỗi dòng và cuối màn hình (ít nhấp nháy hơn xóa cả màn hình).
drawFrame :: String -> IO ()
drawFrame s = do
  putStr ("\ESC[H" ++ concatMap (++ "\ESC[K\n") (lines s) ++ "\ESC[J")
  hFlush stdout
