module InputSpec (spec) where

import Test.Hspec
import Input
import Player (PlayerId(..))
import Types

spec :: Spec
spec = do
  it "P1: W/S/A/D" $ do
    parseKey 'w' `shouldBe` Just (Move P1 MUp)
    parseKey 's' `shouldBe` Just (Move P1 MDown)
    parseKey 'a' `shouldBe` Just (Move P1 MLeft)
    parseKey 'd' `shouldBe` Just (Move P1 MRight)
  it "P2: I/K/J/L" $ do
    parseKey 'i' `shouldBe` Just (Move P2 MUp)
    parseKey 'k' `shouldBe` Just (Move P2 MDown)
    parseKey 'j' `shouldBe` Just (Move P2 MLeft)
    parseKey 'l' `shouldBe` Just (Move P2 MRight)
  it "chữ hoa cũng được (bật Caps Lock)" $ do
    parseKey 'W' `shouldBe` Just (Move P1 MUp)
    parseKey 'L' `shouldBe` Just (Move P2 MRight)
  it "Q thoát" $ do
    parseKey 'q' `shouldBe` Just Quit
    parseKey 'Q' `shouldBe` Just Quit
  it "phím không hợp lệ bị bỏ qua" $
    map parseKey "xz1 \n\ESC[;" `shouldBe` replicate 8 Nothing
  it "chỉ có đúng 9 phím chữ có tác dụng (4 của P1, 4 của P2, Q)" $
    length [ k | k <- ['a' .. 'z'], parseKey k /= Nothing ] `shouldBe` 9
