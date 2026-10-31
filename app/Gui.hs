module Main (main) where

{- Giao diện đồ họa (gloss) cho game CHIẾM ĐẤT.
   Chỉ ĐỌC GameState để vẽ và đổi phím thành applyMove; mọi luật vẫn nằm trong module Game.
   Lưu ý: chữ của gloss không có dấu tiếng Việt nên phần chữ trong cửa sổ viết không dấu.

   Chạy:  stack run my-game-project-gui
          stack run my-game-project-gui -- --time 30
-}

import Data.Char (toUpper)
import Graphics.Gloss
import Graphics.Gloss.Interface.IO.Game
import System.Environment (getArgs)
import System.Exit (exitSuccess)

import Game hiding (Event)
import qualified Game as G
import Input (Action(..), parseKey)
import Items
import Player
import Types

{- ===================== TRẠNG THÁI CỦA CỬA SỔ ===================== -}

data Phase = Intro | InPlay
  deriving (Eq)

data World = World
  { wPhase :: Phase
  , wCfg   :: Config
  , wGame  :: GameState
  }

{- ===================== KÍCH THƯỚC ===================== -}

cell :: Float
cell = 32

winW, winH :: Int
winW = 1000
winH = 780

-- Góc trên trái của bản đồ (gloss: gốc toạ độ ở giữa cửa sổ, trục y hướng lên).
boardLeft, boardTop :: Config -> Float
boardLeft cfg = negate (fromIntegral (cfgWidth cfg) * cell / 2)
boardTop _    = 190

cellCenter :: Config -> Position -> (Float, Float)
cellCenter cfg (x, y) =
  ( boardLeft cfg + (fromIntegral x + 0.5) * cell
  , boardTop cfg  - (fromIntegral y + 0.5) * cell )

{- ===================== MÀU ===================== -}

playerColor :: PlayerId -> Color
playerColor P1 = makeColor 0.25 0.55 1.0 1
playerColor P2 = makeColor 1.0 0.35 0.35 1

landColor :: PlayerId -> Color
landColor P1 = makeColor 0.25 0.55 1.0 0.45
landColor P2 = makeColor 1.0 0.35 0.35 0.45

bgColor, emptyColor, textColor, dimColor :: Color
bgColor    = makeColor 0.08 0.09 0.12 1
emptyColor = makeColor 0.16 0.17 0.21 1
textColor  = makeColor 0.95 0.95 0.95 1
dimColor   = makeColor 0.65 0.67 0.72 1

{- ===================== CHỮ ===================== -}

{- Tự vẽ chữ bằng các nét thẳng, KHÔNG dùng `text` của gloss: `text` gọi GLUT
   (glutStrokeCharacter) và sẽ báo "unknown GLUT entry" khi gloss chạy bằng backend GLFW.
   Mỗi ký tự nằm trong ô rộng 4, cao 6; chữ thường được vẽ thành chữ hoa.
-}
glyph :: Char -> [[(Float, Float)]]
glyph ch = case ch of
  'A' -> [[(0,0),(0,4),(2,6),(4,4),(4,0)], [(0,3),(4,3)]]
  'B' -> [[(0,0),(0,6),(3,6),(4,5),(4,4),(3,3),(0,3)], [(3,3),(4,2),(4,1),(3,0),(0,0)]]
  'C' -> [[(4,5),(3,6),(1,6),(0,5),(0,1),(1,0),(3,0),(4,1)]]
  'D' -> [[(0,0),(0,6),(2,6),(4,4),(4,2),(2,0),(0,0)]]
  'E' -> [[(4,6),(0,6),(0,0),(4,0)], [(0,3),(3,3)]]
  'F' -> [[(4,6),(0,6),(0,0)], [(0,3),(3,3)]]
  'G' -> [[(4,5),(3,6),(1,6),(0,5),(0,1),(1,0),(3,0),(4,1),(4,3),(2,3)]]
  'H' -> [[(0,0),(0,6)], [(4,0),(4,6)], [(0,3),(4,3)]]
  'I' -> [[(1,6),(3,6)], [(2,6),(2,0)], [(1,0),(3,0)]]
  'J' -> [[(4,6),(4,1),(3,0),(1,0),(0,1)]]
  'K' -> [[(0,0),(0,6)], [(4,6),(0,3),(4,0)]]
  'L' -> [[(0,6),(0,0),(4,0)]]
  'M' -> [[(0,0),(0,6),(2,3),(4,6),(4,0)]]
  'N' -> [[(0,0),(0,6),(4,0),(4,6)]]
  'O' -> [[(1,0),(0,1),(0,5),(1,6),(3,6),(4,5),(4,1),(3,0),(1,0)]]
  'P' -> [[(0,0),(0,6),(3,6),(4,5),(4,4),(3,3),(0,3)]]
  'Q' -> [[(1,0),(0,1),(0,5),(1,6),(3,6),(4,5),(4,1),(3,0),(1,0)], [(2,2),(4,0)]]
  'R' -> [[(0,0),(0,6),(3,6),(4,5),(4,4),(3,3),(0,3)], [(2,3),(4,0)]]
  'S' -> [[(4,5),(3,6),(1,6),(0,5),(0,4),(1,3),(3,3),(4,2),(4,1),(3,0),(1,0),(0,1)]]
  'T' -> [[(0,6),(4,6)], [(2,6),(2,0)]]
  'U' -> [[(0,6),(0,1),(1,0),(3,0),(4,1),(4,6)]]
  'V' -> [[(0,6),(2,0),(4,6)]]
  'W' -> [[(0,6),(1,0),(2,3),(3,0),(4,6)]]
  'X' -> [[(0,6),(4,0)], [(0,0),(4,6)]]
  'Y' -> [[(0,6),(2,3),(4,6)], [(2,3),(2,0)]]
  'Z' -> [[(0,6),(4,6),(0,0),(4,0)]]
  '0' -> [[(1,0),(0,1),(0,5),(1,6),(3,6),(4,5),(4,1),(3,0),(1,0)], [(0,1),(4,5)]]
  '1' -> [[(1,5),(2,6),(2,0)], [(1,0),(3,0)]]
  '2' -> [[(0,5),(1,6),(3,6),(4,5),(4,4),(0,0),(4,0)]]
  '3' -> [[(0,5),(1,6),(3,6),(4,5),(4,4),(3,3),(1,3)], [(3,3),(4,2),(4,1),(3,0),(1,0),(0,1)]]
  '4' -> [[(3,0),(3,6),(0,2),(4,2)]]
  '5' -> [[(4,6),(0,6),(0,3),(3,3),(4,2),(4,1),(3,0),(1,0),(0,1)]]
  '6' -> [[(4,5),(3,6),(1,6),(0,5),(0,1),(1,0),(3,0),(4,1),(4,2),(3,3),(0,3)]]
  '7' -> [[(0,6),(4,6),(1,0)]]
  '8' -> [[(1,3),(0,4),(0,5),(1,6),(3,6),(4,5),(4,4),(3,3),(1,3),(0,2),(0,1),(1,0),(3,0),(4,1),(4,2),(3,3)]]
  '9' -> [[(0,1),(1,0),(3,0),(4,1),(4,5),(3,6),(1,6),(0,5),(0,4),(1,3),(4,3)]]
  ':' -> [[(2,4),(2,4.6)], [(2,1),(2,1.6)]]
  ';' -> [[(2,4),(2,4.6)], [(2,1),(1.5,-0.5)]]
  '.' -> [[(2,0),(2,0.6)]]
  ',' -> [[(2,0.6),(1.5,-1)]]
  '-' -> [[(0,3),(4,3)]]
  '+' -> [[(0,3),(4,3)], [(2,1),(2,5)]]
  '(' -> [[(3,6),(1,4),(1,2),(3,0)]]
  ')' -> [[(1,6),(3,4),(3,2),(1,0)]]
  '/' -> [[(0,0),(4,6)]]
  '!' -> [[(2,6),(2,2)], [(2,0),(2,0.6)]]
  ' ' -> []
  _   -> [[(0,0),(4,0),(4,6),(0,6),(0,0)]]

-- Vẽ chuỗi với góc dưới trái tại (x, y); s = cỡ chữ (cao khoảng 70*s điểm ảnh).
label :: Float -> Float -> Float -> Color -> String -> Picture
label x y s c str = translate x y (color c (pictures (zipWith drawChar [0 ..] (map toUpper str))))
  where
    u = 70 * s / 6
    t = max 0.8 (u * 0.16)                      -- độ dày nét (vẽ lệch vài lần để nét đậm hơn)
    drawChar :: Int -> Char -> Picture
    drawChar i ch = translate (fromIntegral i * 6 * u) 0 $ pictures
      [ translate dx dy (pictures [ line [ (a * u, b * u) | (a, b) <- pts ] | pts <- glyph ch ])
      | (dx, dy) <- [(0, 0), (t, 0), (0, t), (t, t)] ]

labelCentered :: Float -> Float -> Float -> Color -> String -> Picture
labelCentered cx y s c str = label (cx - w / 2) y s c str
  where w = 70 * s * (fromIntegral (length str) - 1 / 3)

{- ===================== VẼ ===================== -}

render :: World -> IO Picture
render w = return $ case wPhase w of
  Intro   -> renderIntro (wCfg w)
  InPlay  -> renderGame (wGame w)

renderIntro :: Config -> Picture
renderIntro cfg = pictures
  [ labelCentered 0 200 0.5 textColor "CHIEM DAT"
  , labelCentered 0 150 0.2 dimColor "Tro choi 2 nguoi tren cung ban phim"
  , drawKeys
  , labelCentered 0 (-10) 0.17 textColor
      ("Muc tieu: chiem nhieu dat hon doi thu trong " ++ show (round (cfgDuration cfg) :: Int) ++ " giay")
  , labelCentered 0 (-50) 0.15 dimColor "Di ra khoi dat nha de lai vet; quay ve dat nha de khep vong chiem dat"
  , labelCentered 0 (-80) 0.15 dimColor "Dung bien hoac dung vet duong: -5 diem. Bom (tron den): mat dat. Dau + xanh: them dat"
  , labelCentered 0 (-110) 0.15 dimColor "Chu dat cham ke xam nhap: thang ngay.  Bao vay doi thu: thang ngay"
  , labelCentered 0 (-200) 0.25 (makeColor 1 0.85 0.3 1) "Nhan SPACE de bat dau"
  , labelCentered 0 (-240) 0.13 dimColor "Q / ESC: thoat"
  ]
  where
    drawKeys = pictures
      [ translate (-250) 90 (keyBox P1 "P1 xanh:  W A S D")
      , translate 250 90 (keyBox P2 "P2 do:  I J K L / mui ten")
      ]
    keyBox pid s = pictures
      [ color (landColor pid) (rectangleSolid 440 40)
      , color (playerColor pid) (rectangleWire 440 40)
      , labelCentered 0 (-6) 0.15 textColor s
      ]

renderGame :: GameState -> Picture
renderGame gs = pictures
  [ hud gs
  , board gs
  , footer gs
  , if isFinished gs then overlay gs else blank
  ]

hud :: GameState -> Picture
hud gs = pictures
  [ labelCentered 0 340 0.3 textColor "CHIEM DAT"
  , labelCentered 0 285 0.28 timeCol ("Con lai: " ++ show secs ++ " giay")
  , scoreCard P1 (-330)
  , scoreCard P2 330
  ]
  where
    secs    = max 0 (ceiling (gsTimeLeft gs)) :: Int
    timeCol = if secs <= 10 then makeColor 1 0.5 0.3 1 else textColor
    scoreCard pid cx = pictures
      [ translate cx 270 (color (landColor pid) (rectangleSolid 300 110))
      , translate cx 270 (color (playerColor pid) (rectangleWire 300 110))
      , labelCentered cx 300 0.17 (playerColor pid) (name pid)
      , labelCentered cx 255 0.26 textColor ("Diem: " ++ show (scoreOf pid gs))
      , labelCentered cx 227 0.13 dimColor
          ("Dat: " ++ show (territorySize pid gs) ++ "   Phat: -" ++ show (playerPenalty (getPlayer pid gs)))
      ]
    name P1 = "P1 (W/A/S/D)"
    name P2 = "P2 (I/J/K/L)"

board :: GameState -> Picture
board gs = pictures $
     [ translate cx cy (color (makeColor 0.3 0.32 0.38 1) (rectangleWire (bw + 6) (bh + 6))) ]
  ++ [ square (x, y) emptyColor (cell - 2) | x <- [0 .. w - 1], y <- [0 .. h - 1] ]
  ++ [ square (x, y) (landColor pid) cell
     | pid <- [P1, P2], x <- [0 .. w - 1], y <- [0 .. h - 1], landAt pid (x, y) gs ]
  ++ [ square pos (playerColor pid) (cell - 10)
     | pid <- [P1, P2], pos <- playerTrail (getPlayer pid gs) ]
  ++ map drawItem (gsItems gs)
  ++ [ drawPlayer pid | pid <- [P1, P2] ]
  where
    cfg = gsConfig gs
    w   = cfgWidth cfg
    h   = cfgHeight cfg
    bw  = fromIntegral w * cell
    bh  = fromIntegral h * cell
    cx  = boardLeft cfg + bw / 2
    cy  = boardTop cfg - bh / 2

    square pos c size =
      let (px, py) = cellCenter cfg pos
      in translate px py (color c (rectangleSolid size size))

    drawItem it =
      let (px, py) = cellCenter cfg (itemPos it)
      in translate px py $ case itemKind it of
           Bomb   -> pictures
             [ color (makeColor 0.1 0.1 0.1 1) (circleSolid 12)
             , color (makeColor 1 0.25 0.2 1) (thickCircle 12 3)
             , color (makeColor 1 0.8 0.2 1) (translate 8 11 (circleSolid 3))
             ]
           Expand -> pictures
             [ color (makeColor 0.2 0.85 0.4 1) (rectangleSolid 24 24)
             , color white (rectangleSolid 16 4)
             , color white (rectangleSolid 4 16)
             ]

    drawPlayer pid =
      let (px, py) = cellCenter cfg (playerPos (getPlayer pid gs))
      in translate px py $ pictures
           [ color white (circleSolid 14)
           , color (playerColor pid) (circleSolid 11)
           , label (-3.5) (-5) 0.14 white (case pid of P1 -> "1"; P2 -> "2")
           ]

footer :: GameState -> Picture
footer gs = pictures
  [ labelCentered 0 (-352) 0.17 (makeColor 1 0.85 0.3 1) msg
  , labelCentered 0 (-378) 0.11 dimColor "Q / ESC: thoat"
  ]
  where msg = maybe "" (describeEvent gs) (gsEvent gs)

-- Chữ không dấu vì font của gloss không có dấu tiếng Việt.
describeEvent :: GameState -> G.Event -> String
describeEvent gs ev = case ev of
  EvOutOfBounds p -> show p ++ " di ra ngoai bien: dung yen, -" ++ pen ++ " diem"
  EvHitTrail p    -> show p ++ " dung vet duong: dung yen, -" ++ pen ++ " diem"
  EvBlocked p     -> show p ++ " cham doi thu: bi chan lai"
  EvClaimed p n   -> show p ++ " khep vong, chiem them " ++ show n ++ " o"
  EvBomb p n      -> show p ++ " dap trung bom: mat " ++ show n ++ " o dat"
  EvExpand p n    -> show p ++ " nhat phinh lanh dia: them " ++ show n ++ " o dat"
  where pen = show (cfgPenalty (gsConfig gs))

overlay :: GameState -> Picture
overlay gs = pictures
  [ translate 0 (boardTop cfg - bh / 2) (color (makeColor 0 0 0 0.72) (rectangleSolid (bw + 6) (bh + 6)))
  , labelCentered 0 40 0.4 (makeColor 1 0.85 0.3 1) title
  , labelCentered 0 (-10) 0.17 textColor sub
  , labelCentered 0 (-70) 0.2 textColor ("P1: " ++ show (scoreOf P1 gs) ++ "   -   P2: " ++ show (scoreOf P2 gs))
  , labelCentered 0 (-130) 0.2 dimColor "R: choi lai     Q: thoat"
  ]
  where
    cfg = gsConfig gs
    bw  = fromIntegral (cfgWidth cfg) * cell
    bh  = fromIntegral (cfgHeight cfg) * cell
    (title, sub) = case gsStatus gs of
      Finished (Win p TimeUp)     -> (show p ++ " THANG!", "Het gio - nhieu diem hon")
      Finished (Win p Surrounded) -> (show p ++ " THANG SOM!", "Bao vay duoc doi thu")
      Finished (Win p Touched)    -> (show p ++ " THANG SOM!", "Doi thu bi cham khi dang o trong dat cua " ++ show p)
      Finished Draw               -> ("HOA!", "Het gio - bang diem")
      Playing                     -> ("", "")

{- ===================== PHÍM & THỜI GIAN ===================== -}

handle :: Event -> World -> IO World
handle (EventKey key Down _ _) w = case key of
  SpecialKey KeyEsc   -> exitSuccess
  SpecialKey KeySpace -> return (startIf Intro w)
  SpecialKey KeyEnter -> return (startIf Intro w)
  SpecialKey KeyUp    -> return (move P2 MUp w)
  SpecialKey KeyDown  -> return (move P2 MDown w)
  SpecialKey KeyLeft  -> return (move P2 MLeft w)
  SpecialKey KeyRight -> return (move P2 MRight w)
  Char c
    | c `elem` "rR", wPhase w == InPlay, isFinished (wGame w) -> return (restart w)
    | otherwise -> case parseKey c of
        Just Quit        -> exitSuccess
        Just (Move p d)  -> return (move p d w)
        Nothing          -> return w
  _ -> return w
handle _ w = return w

startIf :: Phase -> World -> World
startIf ph w | wPhase w == ph = restart w
             | otherwise      = w

restart :: World -> World
restart w = w { wPhase = InPlay, wGame = initGame (wCfg w) }

move :: PlayerId -> Direction -> World -> World
move p d w
  | wPhase w == InPlay = w { wGame = applyMove p d (wGame w) }
  | otherwise           = w

step :: Float -> World -> IO World
step dt w
  | wPhase w == InPlay = return w { wGame = tick (realToFrac dt) (wGame w) }
  | otherwise           = return w

{- ===================== MAIN ===================== -}

main :: IO ()
main = do
  args <- getArgs
  let cfg = case args of
        ("--time" : n : _) | [(s, "")] <- reads n, s > 0 -> defaultConfig { cfgDuration = s }
        _ -> defaultConfig
  playIO
    (InWindow "Chiem dat - 2 nguoi choi" (winW, winH) (40, 20))
    bgColor
    60
    (World Intro cfg (initGame cfg))
    render
    handle
    step
