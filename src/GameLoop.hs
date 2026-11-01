
module GameLoop (runGame) where

import Control.Concurrent (ThreadId, forkIO, killThread, threadDelay)
import Control.Concurrent.Chan (Chan, newChan, readChan, writeChan)
import Control.Exception (bracket, bracket_)
import Control.Monad (when)
import GHC.Clock (getMonotonicTime)
import System.IO

import Game
import Input
import UI
import Storage

data LoopEvent
  = InputEvent Action
  | TimerEvent Double

runGame :: Config -> Bool -> IO ()
runGame cfg color = do
  hSetEncoding stdout utf8
  withRawInput $ bracket_ hideCursor showCursor $ do
    clearScreen
    putStr (renderIntro cfg)
    hFlush stdout

    k <- waitAnyKey

    if k `elem` ['q', 'Q']
      then goodbye
      else do
        clearScreen
        channel <- newChan

        finished <- bracket
          (startWorkers channel)
          stopWorkers
          (\_ -> loop channel (initGame cfg) "")

        if finished
          then do
            putStrLn "  Bấm phím bất kỳ để thoát..."
            _ <- waitAnyKey
            return ()
          else goodbye

  where
    waitAnyKey = do
      mk <- readKeyTimeout 1000
      maybe waitAnyKey return mk

    goodbye = putStrLn "\n  Đã thoát game."

    startWorkers :: Chan LoopEvent -> IO [ThreadId]
    startWorkers channel = do
      inputThread <- forkIO (inputWorker channel)
      timerThread <- forkIO (timerWorker channel)
      return [inputThread, timerThread]

    stopWorkers :: [ThreadId] -> IO ()
    stopWorkers = mapM_ killThread

    inputWorker :: Chan LoopEvent -> IO ()
    inputWorker channel = do
      mk <- readKeyTimeout 50

      case mk >>= parseKey of
        Nothing ->
          inputWorker channel

        Just action -> do
          writeChan channel (InputEvent action)

          case action of
            Quit -> return ()
            _    -> inputWorker channel

    saveResult gs = do
      result <- saveGameResult gs

      case result of
        Left err ->
          putStrLn ("\n  Cảnh báo: " ++ err)

        Right _ ->
          putStrLn "\n  Đã lưu kết quả trận đấu."

    timerWorker :: Chan LoopEvent -> IO ()
    timerWorker channel = do
      lastT <- getMonotonicTime
      timerLoop channel lastT

    timerLoop :: Chan LoopEvent -> Double -> IO ()
    timerLoop channel lastT = do
      threadDelay 50000
      now <- getMonotonicTime

      let dt = now - lastT

      writeChan channel (TimerEvent dt)
      timerLoop channel now

    loop :: Chan LoopEvent -> GameState -> String -> IO Bool
    loop channel gs prevFrame = do
      event <- readChan channel
      case event of
        InputEvent Quit ->
          return False

        InputEvent (Move pid direction) ->
          updateAndContinue channel (applyMove pid direction gs) prevFrame

        TimerEvent dt ->
          updateAndContinue channel (tick dt gs) prevFrame

    updateAndContinue :: Chan LoopEvent -> GameState -> String -> IO Bool
    updateAndContinue channel gs prevFrame = do
      let frame = renderGame color gs
      when (frame /= prevFrame) $
        drawFrame frame

      if isFinished gs
        then do
          putStrLn "\n  Trận đấu đã kết thúc."
          saveResult gs
          printHistory
          return True
        else
          loop channel gs frame