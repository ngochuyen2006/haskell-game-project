module GameLoop (runGame) where

import Control.Exception (bracket_)
import Control.Monad (when)
import GHC.Clock (getMonotonicTime)
import System.IO

import Game
import Input
import UI

{- Vòng lặp chơi (phần IO duy nhất của game):
     nhận phím -> tick thời gian -> di chuyển / kiểm tra va chạm / chiếm đất / nhặt vật phẩm
     -> vẽ lại màn hình -> lặp lại cho tới khi hết giờ, có người thắng sớm, hoặc bấm Q.
   Toàn bộ luật nằm trong module Game (thuần, test được); file này chỉ nối phím, đồng hồ và màn hình.

   runGame cfg color
     cfg   : cấu hình ván chơi (xem defaultConfig trong Game.hs)
     color : True = dùng màu ANSI
   Có thể gọi từ ghci:  runGame defaultConfig True
-}
runGame :: Config -> Bool -> IO ()
runGame cfg color = do
  hSetEncoding stdout utf8
  withRawInput $ bracket_ hideCursor showCursor $ do
    clearScreen
    putStr (renderIntro cfg)
    hFlush stdout
    k <- waitAnyKey
    if k `elem` ['q', 'Q'] then goodbye else do
      clearScreen
      t0 <- getMonotonicTime
      loop (initGame cfg) t0 ""
  where
    loop gs lastT prevFrame = do
      mk  <- readKeyTimeout 50                   -- chờ phím tối đa 50ms để đồng hồ vẫn chạy
      now <- getMonotonicTime
      let gs1 = tick (now - lastT) gs
      case mk >>= parseKey of
        Just Quit -> goodbye
        act -> do
          let gs2 = case act of
                      Just (Move p d) -> applyMove p d gs1
                      _               -> gs1       -- không có phím / phím không hợp lệ: bỏ qua
              frame = renderGame color gs2
          when (frame /= prevFrame) (drawFrame frame)
          if isFinished gs2
            then do putStrLn "  Bấm phím bất kỳ để thoát..."
                    _ <- waitAnyKey
                    return ()
            else loop gs2 now frame

    waitAnyKey = do
      mk <- readKeyTimeout 1000
      maybe waitAnyKey return mk

    goodbye = putStrLn "\n  Đã thoát game."
