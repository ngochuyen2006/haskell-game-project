{-# LANGUAGE OverloadedStrings #-}

module Storage
  ( HistoryEntry(..)
  , saveGameResult
  , loadHistory
  , printHistory
  ) where

import Control.Exception (IOException, try)
import Data.Aeson
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString as BS
import Data.Time.Clock (getCurrentTime)
import System.Directory (createDirectoryIfMissing, doesFileExist)

import Game
import Player (PlayerId(..))

historyFile :: FilePath
historyFile = "data/history.json"

data HistoryEntry = HistoryEntry
  { historyPlayedAt  :: String
  , historyPlayer1   :: Int
  , historyPlayer2   :: Int
  , historyWinner    :: String
  , historyEndReason :: String
  , historyDuration  :: Double
  } deriving (Show, Eq)

instance ToJSON HistoryEntry where
  toJSON entry = object
    [ "played_at"  .= historyPlayedAt entry
    , "player1"    .= historyPlayer1 entry
    , "player2"    .= historyPlayer2 entry
    , "winner"     .= historyWinner entry
    , "end_reason" .= historyEndReason entry
    , "duration"   .= historyDuration entry
    ]

instance FromJSON HistoryEntry where
  parseJSON = withObject "HistoryEntry" $ \v ->
    HistoryEntry
      <$> v .: "played_at"
      <*> v .: "player1"
      <*> v .: "player2"
      <*> v .: "winner"
      <*> v .: "end_reason"
      <*> v .: "duration"

loadHistory :: IO (Either String [HistoryEntry])
loadHistory = do
  exists <- doesFileExist historyFile

  if not exists
    then return (Right [])
    else do
      result <- try (BS.readFile historyFile)
          :: IO (Either IOException BS.ByteString)

      case result of
        Left err ->
          return (Left ("Không thể đọc file lịch sử: " ++ show err))

        Right contents ->
          case eitherDecodeStrict' contents of
            Left err ->
              return (Left ("Dữ liệu JSON không hợp lệ: " ++ err))

            Right entries ->
              return (Right entries)

saveGameResult :: GameState -> IO (Either String HistoryEntry)
saveGameResult gs =
  case gsStatus gs of
    Playing ->
      return (Left "Trận đấu chưa kết thúc, không thể lưu kết quả.")

    Finished outcome -> do
      oldHistory <- loadHistory

      case oldHistory of
        Left err ->
          return (Left err)

        Right entries -> do
          currentTime <- getCurrentTime

          let entry = HistoryEntry
                { historyPlayedAt = show currentTime
                , historyPlayer1 = scoreOf P1 gs
                , historyPlayer2 = scoreOf P2 gs
                , historyWinner = winnerName outcome
                , historyEndReason = endReasonName outcome
                , historyDuration =
                    max 0 (cfgDuration (gsConfig gs) - gsTimeLeft gs)
                }

              newHistory = entry : entries

          result <- try $ do
            createDirectoryIfMissing True "data"
            BL.writeFile historyFile (encode newHistory)
            :: IO (Either IOException ())

          case result of
            Left err ->
              return (Left ("Không thể lưu lịch sử: " ++ show (err :: IOException)))

            Right () ->
              return (Right entry)

winnerName :: Outcome -> String
winnerName (Win P1 _) = "Player 1"
winnerName (Win P2 _) = "Player 2"
winnerName Draw       = "Draw"

endReasonName :: Outcome -> String
endReasonName (Win _ TimeUp)     = "Time limit"
endReasonName (Win _ Surrounded) = "Surrounded"
endReasonName (Win _ Touched)    = "Touched"
endReasonName Draw               = "Draw"

printHistory :: IO ()
printHistory = do
  result <- loadHistory

  putStrLn "\nLỊCH SỬ TRẬN ĐẤU"

  case result of
    Left err ->
      putStrLn err

    Right [] ->
      putStrLn "Chưa có trận đấu nào được lưu."

    Right entries ->
      mapM_ printEntry (zip [1 :: Int ..] entries)

printEntry :: (Int, HistoryEntry) -> IO ()
printEntry (index, entry) = do
  putStrLn $ "\nTrận đấu #" ++ show index
  putStrLn $ "  Thời gian: " ++ historyPlayedAt entry
  putStrLn $ "  Player 1: " ++ show (historyPlayer1 entry) ++ " điểm"
  putStrLn $ "  Player 2: " ++ show (historyPlayer2 entry) ++ " điểm"
  putStrLn $ "  Người thắng: " ++ historyWinner entry
  putStrLn $ "  Kết thúc: " ++ historyEndReason entry
  putStrLn $ "  Thời lượng: " ++ show (historyDuration entry) ++ " giây"