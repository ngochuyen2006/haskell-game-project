module Main (main) where

import Test.Hspec

import qualified CollisionSpec
import qualified ItemSpec
import qualified TerritorySpec
import qualified TrailSpec
import qualified MapSpec
import qualified MovementSpec
import qualified PlayerSpec
import qualified InputSpec
import qualified GameSpec
import qualified UISpec

-- Mỗi module có một file test riêng, xuất ra `spec :: Spec`.
-- Thêm file test mới: xem hướng dẫn trong README (mục "Kiểm thử").
main :: IO ()
main = hspec $ do
  describe "Collision" CollisionSpec.spec
  describe "Items" ItemSpec.spec
  describe "Territory" TerritorySpec.spec
  describe "Trail" TrailSpec.spec
  describe "Map"      MapSpec.spec
  describe "Movement" MovementSpec.spec
  describe "Player"   PlayerSpec.spec
  describe "Input"    InputSpec.spec
  describe "Game"     GameSpec.spec
  describe "UI"       UISpec.spec
