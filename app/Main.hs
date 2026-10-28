module Main (main) where

import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import Game (Config(..), defaultConfig)
import GameLoop (runGame)

{- Chạy:   stack run
   Tùy chọn (đặt sau dấu --):
     stack run -- --time 30     đổi thời gian một ván (giây)
     stack run -- --no-color    tắt màu
     stack run -- --help
-}
main :: IO ()
main = do
  args <- getArgs
  case parseArgs args (defaultConfig, True) of
    Left "help" -> putStrLn usage
    Left err    -> hPutStrLn stderr (err ++ "\n" ++ usage) >> exitFailure
    Right (cfg, color) -> runGame cfg color

usage :: String
usage = unlines
  [ "Cách dùng: stack run -- [--time GIÂY] [--no-color]"
  , "  --time N     thời gian một ván, tính bằng giây (mặc định " ++ show (round (cfgDuration defaultConfig) :: Int) ++ ")"
  , "  --no-color   không dùng màu ANSI"
  ]

parseArgs :: [String] -> (Config, Bool) -> Either String (Config, Bool)
parseArgs [] acc = Right acc
parseArgs ("--help" : _) _ = Left "help"
parseArgs ("--no-color" : rest) (cfg, _) = parseArgs rest (cfg, False)
parseArgs ("--time" : n : rest) (cfg, color) =
  case reads n :: [(Double, String)] of
    [(secs, "")] | secs > 0 -> parseArgs rest (cfg { cfgDuration = secs }, color)
    _ -> Left ("Giá trị --time không hợp lệ: " ++ n)
parseArgs (a : _) _ = Left ("Tham số không hợp lệ: " ++ a)
