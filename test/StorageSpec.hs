module StorageSpec (spec) where

import Control.Exception (bracket)
import Control.Monad (forM_)
import System.Directory
    ( createDirectory
    , createDirectoryIfMissing
    , doesFileExist
    , getTemporaryDirectory
    , removeFile
    , removePathForcibly
    , withCurrentDirectory
    )
import System.IO (hClose, openTempFile)
import Test.Hspec

import Game
import Player (PlayerId(..))
import Storage

-- Mỗi test chạy trong một thư mục làm việc tạm riêng.
-- Không đọc hoặc ghi đè lịch sử thật của game.
withIsolatedWorkingDirectory :: IO a -> IO a
withIsolatedWorkingDirectory action = do
    tempRoot <- getTemporaryDirectory
    bracket (createTempDirectory tempRoot) removePathForcibly $ \dir ->
        withCurrentDirectory dir action

createTempDirectory :: FilePath -> IO FilePath
createTempDirectory root = do
    (path, handle) <- openTempFile root "storage-spec"
    hClose handle
    removeFile path
    createDirectory path
    return path

finishedGame :: Outcome -> Double -> GameState
finishedGame outcome timeLeft =
    (initGame defaultConfig)
        { gsStatus = Finished outcome
        , gsTimeLeft = timeLeft
        }

createHistoryDirectory :: IO ()
createHistoryDirectory =
    createDirectoryIfMissing True "data"

spec :: Spec
spec = describe "Storage" $ do
    describe "loadHistory" $ do
        it "trả về danh sách rỗng khi file lịch sử chưa tồn tại" $
            withIsolatedWorkingDirectory $ do
                result <- loadHistory
                result `shouldBe` Right []
        it "đọc được danh sách lịch sử từ JSON hợp lệ" $
            withIsolatedWorkingDirectory $ do
                createHistoryDirectory
                writeFile "data/history.json" "[{\"played_at\":\"2026-11-01T10:00:00Z\",\"player1\":12,\"player2\":8,\"winner\":\"Player 1\",\"end_reason\":\"Time limit\",\"duration\":45.0}]"

        it "trả về lỗi khi nội dung JSON không hợp lệ" $
            withIsolatedWorkingDirectory $ do
                createHistoryDirectory
                writeFile "data/history.json" "{ JSON khong hop le"

                result <- loadHistory
                case result of
                    Left message ->
                        message `shouldContain` "Dữ liệu JSON không hợp lệ:"

                    Right entries ->
                        expectationFailure
                        ("Đáng lẽ phải báo lỗi JSON, nhưng lại đọc được: "
                            ++ show entries)

    describe "saveGameResult" $ do
        it "không lưu khi trận đấu vẫn đang diễn ra" $
            withIsolatedWorkingDirectory $ do
                let game = initGame defaultConfig
                result <- saveGameResult game

                result `shouldBe`
                    Left "Trận đấu chưa kết thúc, không thể lưu kết quả."

                doesFileExist "data/history.json" `shouldReturn` False
        it "lưu kết quả trận đấu đã kết thúc với đúng điểm và thời lượng" $
            withIsolatedWorkingDirectory $ do
                let game = finishedGame (Win P1 TimeUp) 15

                result <- saveGameResult game

                case result of
                    Left message ->
                        expectationFailure message

                    Right entry -> do
                        historyPlayer1 entry `shouldBe` scoreOf P1 game
                        historyPlayer2 entry `shouldBe` scoreOf P2 game
                        historyWinner entry `shouldBe` "Player 1"
                        historyEndReason entry `shouldBe` "Time limit"
                        historyDuration entry `shouldBe` 45
                        historyPlayedAt entry `shouldNotBe` ""

                        loadHistory `shouldReturn` Right [entry]

        it "thêm trận mới vào đầu danh sách và giữ lại lịch sử cũ" $
            withIsolatedWorkingDirectory (do
                let firstGame  = finishedGame (Win P1 TimeUp) 30
                    secondGame = finishedGame (Win P2 Surrounded) 20

                firstResult <- saveGameResult firstGame
                secondResult <- saveGameResult secondGame
                historyResult <- loadHistory

                case (firstResult, secondResult, historyResult) of
                    (Right firstEntry, Right secondEntry, Right entries) -> do
                        entries `shouldBe` [secondEntry, firstEntry]
                        historyWinner secondEntry `shouldBe` "Player 2"
                        historyEndReason secondEntry `shouldBe` "Surrounded"

                    (Left message, _, _) ->
                        expectationFailure message

                    (_, Left message, _) ->
                        expectationFailure message

                    (_, _, Left message) ->
                        expectationFailure message
            )

        it "không ghi đè file nếu lịch sử cũ chứa JSON không hợp lệ" $
            withIsolatedWorkingDirectory $ do
                createHistoryDirectory

                writeFile "data/history.json" "{ JSON khong hop le"

                result <- saveGameResult (finishedGame Draw 30)

                result `shouldSatisfy` isLeftResult

                readFile "data/history.json"
                    `shouldReturn` "{ JSON khong hop le"


storageOutcomes :: [(Outcome, String, String)]
storageOutcomes =
    [ (Win P1 Touched, "Player 1", "Touched")
    , (Draw, "Draw", "Draw")
    ]

isLeftResult :: Either a b -> Bool
isLeftResult (Left _)  = True
isLeftResult (Right _) = False