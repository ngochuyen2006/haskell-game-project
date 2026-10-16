module Input (readKey) where

import System.IO

-- Đọc đúng 1 phím, không cần Enter và không hiện phím ra màn hình
readKey :: IO Char
readKey = do
  hSetBuffering stdin NoBuffering
  hSetEcho stdin False
  getChar
