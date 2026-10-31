module Input
  ( Action(..)
  , parseKey
  , readKey
  , readKeyTimeout
  , withRawInput
  ) where

import Control.Exception (IOException, bracket, try)
import Data.Char (toLower)
import System.IO
import System.IO.Error (isEOFError ,isIllegalOperation)

import Movement (keyToDir)
import Player (PlayerId(..))
import Types (Direction)

-- Thao tác của người chơi mà game xử lý được.
data Action
  = Move PlayerId Direction
  | Quit
  deriving (Show, Eq)

{- Chuyển một phím thành thao tác.
   P1: W/A/S/D     P2: I/J/K/L (I lên, K xuống, J trái, L phải)     Q: thoát.
   Không phân biệt hoa/thường. Phím không hợp lệ trả về Nothing (bị bỏ qua).
   Phần "phím -> hướng" dùng lại keyToDir của Movement (W/A/S/D);
   phím của P2 được đổi sang phím tương ứng của P1 rồi mới tra keyToDir.
-}
parseKey :: Char -> Maybe Action
parseKey c
  | k == 'q'                                    = Just Quit
  | Just k1 <- lookup k p2Keys, Just d <- keyToDir k1 = Just (Move P2 d)
  | k `elem` "wasd", Just d <- keyToDir k       = Just (Move P1 d)
  | otherwise                                   = Nothing
  where
    k = toLower c
    p2Keys = [('i', 'w'), ('k', 's'), ('j', 'a'), ('l', 'd')]

-- Bỏ qua lỗi IO (ví dụ hSetEcho khi stdin không phải terminal, như git-bash/mintty hoặc pipe).
ignoreIO :: IO () -> IO ()
ignoreIO act = do
  r <- try act :: IO (Either IOException ())
  case r of
    Right () -> return ()
    Left e
      | isIllegalOperation e -> return ()
      | otherwise            -> ioError e

-- Đọc đúng 1 phím, không cần Enter và không hiện phím ra màn hình.
readKey :: IO Char
readKey = do
  hSetBuffering stdin NoBuffering
  ignoreIO (hSetEcho stdin False)
  getChar

{- Chờ tối đa `ms` mili-giây để có phím.
   Just c = có phím; Nothing = hết thời gian mà không có phím.
   Hết dữ liệu nhập (EOF) coi như người dùng bấm 'q'.
   Phím đặc biệt (mũi tên, F1...) gửi chuỗi bắt đầu bằng ESC: đọc bỏ cả chuỗi
   và trả về '\ESC' (parseKey bỏ qua), tránh việc chữ 'A' trong "ESC [ A" bị hiểu thành phím A.
-}
readKeyTimeout :: Int -> IO (Maybe Char)
readKeyTimeout ms = do
  ready <- try (hWaitForInput stdin ms)
  case ready of
    Left e | isEOFError e -> return (Just 'q')
           | otherwise    -> ioError e
    Right False -> return Nothing
    Right True  -> do
      r <- try getChar
      case r of
        Left e | isEOFError e -> return (Just 'q')
               | otherwise    -> ioError e
        Right '\ESC' -> drainPending >> return (Just '\ESC')
        Right c      -> return (Just c)
  where
    drainPending = do
      more <- try (hWaitForInput stdin 10) :: IO (Either IOException Bool)
      case more of
        Left e
          | isEOFError e -> return ()
          | otherwise    -> ioError e
        Right False -> return ()
        Right True -> do
          r <- try getChar :: IO (Either IOException Char)
          case r of
            Left e
              | isEOFError e -> return ()
              | otherwise    -> ioError e
            Right _ -> drainPending

-- Bật chế độ đọc phím tức thời (không buffer, không echo) và luôn khôi phục khi kết thúc.
withRawInput :: IO a -> IO a
withRawInput action = bracket save restore (const (setRaw >> action))
  where
    save = do
      b <- hGetBuffering stdin
      e <- try (hGetEcho stdin) :: IO (Either IOException Bool)
      echo <- case e of
        Right value -> return value
        Left err
          | isIllegalOperation err -> return True
          | otherwise              -> ioError err
      return (b, echo)
    restore (b, e) = do
      hSetBuffering stdin b
      ignoreIO (hSetEcho stdin e)
    setRaw = do
      hSetBuffering stdin NoBuffering
      ignoreIO (hSetEcho stdin False)
