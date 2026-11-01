module MovementSpec (spec) where

import Test.Hspec
import Movement
import Types 

spec :: Spec
spec = do
  it "keyToDir w/a/s/d" $ do
    keyToDir 'w' `shouldBe` Just MUp
    keyToDir 's' `shouldBe` Just MDown
    keyToDir 'a' `shouldBe` Just MLeft
    keyToDir 'd' `shouldBe` Just MRight
  it "keyToDir: phím khác là Nothing" $
    keyToDir 'x' `shouldBe` Nothing
  it "đi lên thì y giảm 1" $
    movePlayer (Position 5 5) MUp (10, 10) `shouldBe` Position 5 4
  it "đi xuống thì y tăng 1" $
    movePlayer (Position 5 5) MDown (10, 10) `shouldBe` Position 5 6
  it "đi trái thì x giảm 1" $
    movePlayer (Position 5 5) MLeft (10, 10) `shouldBe` Position 4 5
  it "đi phải thì x tăng 1" $
    movePlayer (Position 5 5) MRight (10, 10) `shouldBe` Position 6 5
  it "chạm biên trên thì đứng yên" $
    movePlayer (Position 5 0) MUp (10, 10) `shouldBe` Position 5 0 
  it "chạm biên trái thì đứng yên" $
    movePlayer (Position 0 5) MLeft (10, 10) `shouldBe` Position 0 5
  it "chạm biên dưới thì đứng yên" $
    movePlayer (Position 5 9) MDown (10, 10) `shouldBe` Position 5 9
  it "chạm biên phải thì đứng yên" $
    movePlayer (Position 9 5) MRight (10, 10) `shouldBe` Position 9 5
