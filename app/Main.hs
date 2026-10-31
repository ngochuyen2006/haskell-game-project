module Main (main) where

import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr, hSetEncoding, stdout, utf8)

import GameLoop (runGame)

import Control.Applicative (empty, many)
import Data.Void (Void)

import Text.Megaparsec
  ( Parsec, choice, eof, errorBundlePretty, parse )
import Text.Megaparsec.Char (space1, string)
import qualified Text.Megaparsec.Char.Lexer as L
import Game (Config(..), defaultConfig, validateConfig)

{- Chạy:   stack run
   Tùy chọn (đặt sau dấu --):
     stack run -- --time 30     đổi thời gian một ván (giây)
     stack run -- --no-color    tắt màu
     stack run -- --help
-}
main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  case parseArgs args (defaultConfig, True) of
    Left "help" -> putStrLn usage
    Left err    -> hPutStrLn stderr (err ++ "\n" ++ usage) >> exitFailure
    Right (cfg, color) ->
      case validateConfig cfg of
        Left err ->
          hPutStrLn stderr ("Cấu hình không hợp lệ: " ++ err)
            >> exitFailure
        Right () -> runGame cfg color

usage :: String
usage = unlines
  [ "Cách dùng: stack run -- [--time GIÂY] [--no-color]"
  , "  --time N     thời gian một ván, tính bằng giây (mặc định " ++ show (round (cfgDuration defaultConfig) :: Int) ++ ")"
  , "  --no-color   không dùng màu ANSI"
  ]

-- Parser phân tích tham số khởi chạy game.
type Parser = Parsec Void String

data CLIOption
  = SetTime Double
  | DisableColor
  | ShowHelp
  deriving (Eq, Show)

-- Bỏ qua khoảng trắng.
sc :: Parser ()
sc = L.space space1 empty empty

-- Phân tích từng tùy chọn.
optionParser :: Parser CLIOption
optionParser = choice
  [ do
      _ <- string "--time"
      _ <- space1
      secs <- realToFrac <$> L.signed sc L.scientific
      return (SetTime secs)

  , DisableColor <$ string "--no-color"

  , ShowHelp <$ string "--help"
  ]

-- Phân tích toàn bộ danh sách tham số.
optionsParser :: Parser [CLIOption]
optionsParser = sc *> many (optionParser <* sc) <* eof

-- Chuyển kết quả parser thành cấu hình game.
parseArgs :: [String] -> (Config, Bool) -> Either String (Config, Bool)
parseArgs args initial =
  case parse optionsParser "command-line" (unwords args) of
    Left err -> Left (errorBundlePretty err)
    Right options
      | ShowHelp `elem` options -> Left "help"
      | otherwise -> Right (foldl applyOption initial options)

-- Áp dụng từng tùy chọn lên cấu hình.
applyOption :: (Config, Bool) -> CLIOption -> (Config, Bool)
applyOption (cfg, color) option =
  case option of
    SetTime secs -> (cfg { cfgDuration = secs }, color)
    DisableColor -> (cfg, False)
    ShowHelp     -> (cfg, color)
