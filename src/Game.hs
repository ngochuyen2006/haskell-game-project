--sửa lại hành vi cần làm gì khi va chạm
module Game
  ( Config(..)
  , defaultConfig
  ,validateConfig
  , Status(..)
  , Outcome(..)
  , EndReason(..)
  , Event(..)
  , GameState(..)
  , initGame
  , applyMove
  , tick
  , getPlayer
  , landAt
  , setLandCells
  , territorySize
  , scoreOf
  , isFinished
  ) where


import Data.List (find, foldl')
import qualified Data.Vector as V
import Items
import Map
import Movement (movePlayer)
import Collision (collisions, cellsToClose)
import Player
import Territory (calculateTerritorySize, claimTerritory)
import Trail (isInTrail)
import Types


--CẤU HÌNH


-- Mọi con số "dự kiến" của luật chơi gom về đây để chỉnh sau khi chơi thử.
data Config = Config
  { cfgWidth      :: Int      -- chiều rộng bản đồ (số ô)
  , cfgHeight     :: Int      -- chiều cao bản đồ (số ô)
  , cfgDuration   :: Double   -- thời gian một ván (giây)
  , cfgSpawnEvery :: Double   -- cứ mỗi bấy nhiêu giây xuất hiện 1 bom + 1 phình lãnh địa
  , cfgMaxBombs   :: Int      -- số bom tối đa cùng lúc trên bản đồ
  , cfgMaxExpand  :: Int      -- số vật phẩm phình lãnh địa tối đa cùng lúc
  , cfgBombLife   :: Double   -- bom không ai đạp sẽ tự biến mất sau bấy nhiêu giây
  , cfgPenalty    :: Int      -- điểm bị trừ mỗi lần va chạm (biên / vệt đường)
  , cfgSeed       :: Int      -- seed cho bộ sinh số ngẫu nhiên
  } deriving (Show, Eq)


defaultConfig :: Config
defaultConfig = Config
  { cfgWidth      = 30
  , cfgHeight     = 16
  , cfgDuration   = 60
  , cfgSpawnEvery = 3
  , cfgMaxBombs   = 3
  , cfgMaxExpand  = 3
  , cfgBombLife   = 10
  , cfgPenalty    = 5
  , cfgSeed       = 2026
  }

-- Kiểm tra cấu hình game trước khi khởi tạo.
validateConfig :: Config -> Either String ()
validateConfig cfg
    | cfgWidth cfg < 10 =
        Left "Chieu rong ban do phai tu 10 tro len."
    | cfgHeight cfg < 3 =
        Left "Chieu cao ban do phai tu 3 tro len."
    | not (positiveFinite (cfgDuration cfg)) =
        Left "Thoi gian game phai la so duong hop le."
    | not (positiveFinite (cfgSpawnEvery cfg)) =
        Left "Thoi gian sinh vat pham phai la so duong hop le."
    | not (positiveFinite (cfgBombLife cfg)) =
        Left "Thoi gian ton tai cua bom phai la so duong hop le."
    | cfgMaxBombs cfg < 0 =
        Left "So luong bom toi da khong duoc am."
    | cfgMaxExpand cfg < 0 =
        Left "So luong Expand toi da khong duoc am."
    | cfgPenalty cfg < 0 =
        Left "Diem phat khong duoc am."
    | otherwise = Right ()
    where
        positiveFinite n = n > 0 && not (isNaN n || isInfinite n)

--TRẠNG THÁI


data EndReason = TimeUp | Surrounded | Touched
  deriving (Show, Eq)


data Outcome = Win PlayerId EndReason | Draw
  deriving (Show, Eq)


data Status = Playing | Finished Outcome
  deriving (Show, Eq)


-- Sự kiện gần nhất, để UI hiển thị thông báo (logic không chứa chữ hiển thị).
data Event
  = EvOutOfBounds PlayerId     -- đi ra ngoài biên
  | EvHitTrail PlayerId        -- đụng vệt đường
  | EvBlocked PlayerId Int -- chạm đối thủ đang đứng trong đất của họ: bị chặn lại
  | EvClaimed PlayerId Int     -- khép vòng, chiếm thêm n ô
  | EvBomb PlayerId  -- đạp bom, mất trail
  | EvExpand PlayerId Int      -- nhặt phình lãnh địa, thêm n ô đất
  deriving (Show, Eq)


{- Mỗi người có MỘT LỚP bản đồ riêng (gsLand1/gsLand2) chỉ chứa Empty/Territory:
   ô Territory ở lớp nào thì thuộc về người đó. Cách này cho phép dùng nguyên
   claimTerritory / calculateTerritorySize của Territory.hs mà không cần Tile có chủ.
   Lớp này KHÔNG có viền Wall (xem ghi chú về claimTerritory trong README).
   Bất biến: một ô không bao giờ là Territory ở cả hai lớp.
-}
data GameState = GameState
  { gsConfig     :: Config
  , gsPlayer1    :: Player
  , gsPlayer2    :: Player
  , gsLand1      :: GameMap
  , gsLand2      :: GameMap
  , gsItems      :: [Item]
  , gsTimeLeft   :: Double
  , gsSpawnTimer :: Double
  , gsSeed       :: Int
  , gsStatus     :: Status
  , gsEvent      :: Maybe Event
  } deriving (Show, Eq)


--TRUY CẬP


getPlayer :: PlayerId -> GameState -> Player
getPlayer P1 = gsPlayer1
getPlayer P2 = gsPlayer2


putPlayer :: Player -> GameState -> GameState
putPlayer p gs = case playerId p of
  P1 -> gs { gsPlayer1 = p }
  P2 -> gs { gsPlayer2 = p }


landOf :: PlayerId -> GameState -> GameMap
landOf P1 = gsLand1
landOf P2 = gsLand2


putLand :: PlayerId -> GameMap -> GameState -> GameState
putLand P1 m gs = gs { gsLand1 = m }
putLand P2 m gs = gs { gsLand2 = m }


-- Ô này có phải đất của người chơi đó không?
landAt :: PlayerId -> Position -> GameState -> Bool
landAt pid pos gs = getTile pos (landOf pid gs) == Just Territory


-- Đặt một loại ô cho nhiều vị trí ở lớp đất của một người (vị trí ngoài biên tự bị bỏ qua).
setLandCells :: PlayerId -> Tile -> [Position] -> GameState -> GameState
setLandCells pid tile ps gs = putLand pid (paint tile ps (landOf pid gs)) gs


paint :: Tile -> [Position] -> GameMap -> GameMap
paint tile ps m = foldl' (\acc p -> setTile p tile acc) m ps


-- Vùng 3x3 quanh một ô.
square :: Position -> [Position]
square (Position x y) =
    [ Position (x + dx) (y + dy)
    | dy <- [-1 .. 1]
    , dx <- [-1 .. 1]
    ]


territorySize :: PlayerId -> GameState -> Int
territorySize pid gs = calculateTerritorySize (landOf pid gs)


-- Điểm = số ô đất - điểm bị phạt.
scoreOf :: PlayerId -> GameState -> Int
scoreOf pid gs = territorySize pid gs - playerPenalty (getPlayer pid gs)


isFinished :: GameState -> Bool
isFinished gs = gsStatus gs /= Playing


allCells :: Config -> [Position]
allCells cfg =
    [ Position x y
    | y <- [0 .. cfgHeight cfg - 1]
    , x <- [0 .. cfgWidth cfg - 1]
    ]


--KHỞI TẠO

-- P1 bắt đầu ở bên trái, P2 ở bên phải, mỗi người có mảnh đất 3x3.
initGame :: Config -> GameState
initGame cfg =
    case validateConfig cfg of
        Left err -> error ("Cau hinh game khong hop le: " ++ err)
        Right () -> GameState
            { gsConfig     = cfg
            , gsPlayer1    = newPlayer P1 s1
            , gsPlayer2    = newPlayer P2 s2
            , gsLand1      = paint Territory (square s1) blank
            , gsLand2      = paint Territory (square s2) blank
            , gsItems      = []
            , gsTimeLeft   = cfgDuration cfg
            , gsSpawnTimer = 0
            , gsSeed       = cfgSeed cfg
            , gsStatus     = Playing
            , gsEvent      = Nothing
            }
    where
        w = cfgWidth cfg
        h = cfgHeight cfg
        s1 = Position 3 (h `div` 2)
        s2 = Position (w - 4) (h `div` 2)
        blank = GameMap w h (V.replicate (w * h) Empty)



--DI CHUYỂN


{- Một lần bấm phím = người `pid` đi một ô theo hướng `dir`.
   Thứ tự kiểm tra:
   1. Ra ngoài biên            -> đứng yên, bị phạt.
   2. Đụng đối thủ             -> nếu đối thủ bị mình chạm trail nó thì nó bị mất nửa đất.
   3. Đụng vệt đường (của ai)  -> đứng yên, bị phạt.
   4. Ngược lại                -> bước đi; về lại đất nhà thì khép vòng và chiếm đất;
                                  đứng lên vật phẩm thì kích hoạt vật phẩm.
-}
--Nếu chạm vào trail thì bị phạt mất nửa đất
-- Nếu chạm vào trail thì người sở hữu trail bị mất một nửa đất.
halfterritorypunish :: PlayerId -> Position -> GameState -> GameState
halfterritorypunish victim hitPos gs =
    let
        -- Lấy toàn bộ ô đất hiện tại của người bị phạt.
        victimCells = filter (\pos -> landAt victim pos gs) (allCells (gsConfig gs))
        -- Chọn những ô cần xóa.
        cellsToRemove = cellsToClose hitPos victimCells
        -- Xóa đất.
        gs1 = setLandCells victim Empty cellsToRemove gs
        -- Xác định vị trí mới tại ô cuối cùng bị xóa.
        oldPlayer = getPlayer victim gs1
        resetPos = case reverse cellsToRemove of
                (pos : _) -> pos
                []        -> playerPos oldPlayer
        -- Đưa người chơi về vị trí mới và xóa trail cũ.
        resetPlayer = setPlayerPos resetPos (resetTrail oldPlayer)


        newPlayer =
          (extendTrail resetPos resetPlayer)
            { playerTrailStart = Just resetPos }
    in
        putPlayer newPlayer gs1


applyMove :: PlayerId -> Direction -> GameState -> GameState
applyMove pid dir gs
    | isFinished gs = gs
    | target == playerPos me  = penalize EvOutOfBounds    -- movePlayer trả về chỗ cũ <=> ra ngoài biên
    --mình đụng trail đối thủ thì đối thủ bị trừ nửa đất
    -- không phải thì game cứ tiếp tục
    | target == playerPos foe && landAt pid target gs =
        gs { gsStatus = Finished (Win pid Touched) }

    | target == playerPos foe =
        let before = territorySize pid gs
            gs1 = halfterritorypunish pid target gs
            lost = before - territorySize pid gs1
        in gs1 { gsEvent = Just (EvBlocked pid lost) }
    | collisions target (playerTrail foe) =
        let victim = opponent pid
            before = territorySize victim gs
            gs1 = halfterritorypunish victim target gs
            lost = before - territorySize victim gs1
        in gs1 {gsEvent = Just(EvBlocked victim lost)}
    | otherwise = settle (advance pid target gs)
  where
    cfg    = gsConfig gs
    me     = getPlayer pid gs
    foe    = getPlayer (opponent pid) gs
    target = movePlayer (playerPos me) dir (cfgWidth cfg, cfgHeight cfg)


    penalize ev = (putPlayer (addPenalty (cfgPenalty cfg) me) gs) { gsEvent = Just (ev pid) }
   
    -- Chỉ nhặt vật phẩm nếu ván chưa kết thúc.
    settle g | isFinished g = g
             | otherwise    = pickUp pid g


-- Người chơi bước tới ô `target`: cập nhật vị trí, vệt đường, và khép vòng nếu về lại đất nhà.
advance :: PlayerId -> Position -> GameState -> GameState
advance pid target gs
  | onHome && playerTrail me /= Trail [] = closeLoop pid moved
  | otherwise                             = moved
  where
    me     = getPlayer pid gs
    onHome = landAt pid target gs


    me'
      | onHome = setPlayerPos target me
      | otherwise =
          let
              start =
                  case playerTrailStart me of
                      Nothing -> Just (playerPos me)
                      old     -> old


              updated = extendTrail target me
          in
              (setPlayerPos target updated)
                  { playerTrailStart = start }


    moved = (putPlayer me' gs) { gsEvent = Nothing }


{- Khép vòng: các ô trống bị bao kín và các ô của vệt đường trở thành đất của `pid`;
   phần đất của đối thủ nằm trong vùng đó bị lấy đi. Nếu ô đối thủ đang đứng bị chiếm
   thì đối thủ bị bao vây -> `pid` thắng ngay.
-}
closeLoop :: PlayerId -> GameState -> GameState
closeLoop pid gs
  | trapped   = gs3 { gsStatus = Finished (Win pid Surrounded) }
  | otherwise = gs3 { gsEvent = Just (EvClaimed pid gained) }
  where
    foeId   = opponent pid
    trail   = playerTrail (getPlayer pid gs)
    oldLand = landOf pid gs
    newLand = claimTerritory trail oldLand
    gained  = calculateTerritorySize newLand - calculateTerritorySize oldLand
    gs1     = putLand pid newLand gs
    gs2     = takeLand foeId pid gs1
    gs3     = putPlayer (resetTrail (getPlayer pid gs2)) gs2
    foePos  = playerPos (getPlayer foeId gs3)
    trapped = landAt pid foePos gs3 && getTile foePos oldLand /= Just Territory


-- Lấy khỏi `victim` mọi ô mà `taker` vừa chiếm (giữ bất biến: một ô chỉ thuộc một người).
takeLand :: PlayerId -> PlayerId -> GameState -> GameState
takeLand victim taker gs = setLandCells victim Empty stolen gs
  where
    stolen = [ p | p <- allCells (gsConfig gs), landAt taker p gs, landAt victim p gs ]


--VẬT PHẨM


pickUp :: PlayerId -> GameState -> GameState
pickUp pid gs =
  case find ((== pos) . itemPos) (gsItems gs) of
    Nothing -> gs
    Just it ->
      let gs1 = gs { gsItems = filter (/= it) (gsItems gs) }
      in case itemKind it of
           Bomb   -> explode pid pos gs1
           Expand -> expand pid pos gs1
  where
    pos = playerPos (getPlayer pid gs)


-- Đạp bom: xóa Trail và đưa người chơi về vị trí bắt đầu vẽ Trail.
-- Không ảnh hưởng đến lãnh địa.
explode :: PlayerId -> Position -> GameState -> GameState
explode pid _pos gs =
    let
        me = getPlayer pid gs


        me' =
            case playerTrailStart me of
                Just start ->
                    (resetTrail me)
                        { playerPos = start }


                Nothing ->
                    resetTrail me


    in
        (putPlayer me' gs)
            { gsEvent = Just (EvBomb pid ) }
expand :: PlayerId -> Position -> GameState -> GameState
expand pid pos gs
  | playerTrail (getPlayer pid gs3) == Trail [] = gs3
  | isFinished closed                      = closed
  | otherwise = closed { gsEvent = Just (EvExpand pid (territorySize pid closed - before)) }
  where
    before = territorySize pid gs
    gs1    = setLandCells pid Territory (square pos) gs
    gs2    = takeLand (opponent pid) pid gs1
    gs3    = gs2 { gsEvent = Just (EvExpand pid (territorySize pid gs2 - before)) }
    -- Đang giữa vệt đường mà phình ra trúng đất nhà thì coi như khép vòng.
    closed = closeLoop pid gs3


--THỜI GIAN


{- Cho thời gian trôi dt giây: giảm đồng hồ, làm bom già đi (quá cfgBombLife thì biến mất),
   đến hạn thì sinh vật phẩm mới, hết giờ thì kết thúc ván và tính thắng/thua/hòa theo điểm.
-}
tick :: Double -> GameState -> GameState
tick dt0 gs
  | isFinished gs = gs
  | left <= 0     = finishByTime gs { gsTimeLeft = 0 }
  | otherwise     = spawnDue gs
      { gsTimeLeft   = left
      , gsSpawnTimer = gsSpawnTimer gs + dt
      , gsItems      = filter alive (ageItems dt (gsItems gs))
      }
  where
    cfg  = gsConfig gs
    dt   = max 0 dt0
    left = gsTimeLeft gs - dt
    alive it = itemKind it /= Bomb || itemAge it < cfgBombLife cfg


spawnDue :: GameState -> GameState
spawnDue gs
  | every > 0 && gsSpawnTimer gs >= every =
      spawnDue (spawnRound gs { gsSpawnTimer = gsSpawnTimer gs - every })
  | otherwise = gs
  where every = cfgSpawnEvery (gsConfig gs)


-- Mỗi lượt xuất hiện cùng lúc 1 bom và 1 phình lãnh địa; loại nào đã đủ số lượng tối đa thì bỏ qua.
spawnRound :: GameState -> GameState
spawnRound = spawnOne Expand . spawnOne Bomb


spawnOne :: ItemKind -> GameState -> GameState
spawnOne kind gs
  | countKind kind (gsItems gs) >= limit = gs
  | otherwise =
      case randomFreeCell (cfgWidth cfg) (cfgHeight cfg) blocked (gsSeed gs) of
        (Just p, s)  -> gs { gsItems = Item kind p 0 : gsItems gs, gsSeed = s }
        (Nothing, s) -> gs { gsSeed = s }
  where
    cfg   = gsConfig gs
    limit = case kind of
              Bomb   -> cfgMaxBombs cfg
              Expand -> cfgMaxExpand cfg
    blocked = playerPos (gsPlayer1 gs) : playerPos (gsPlayer2 gs) : map itemPos (gsItems gs)


finishByTime :: GameState -> GameState
finishByTime gs = gs { gsStatus = Finished outcome }
  where
    s1 = scoreOf P1 gs
    s2 = scoreOf P2 gs
    outcome | s1 > s2   = Win P1 TimeUp
            | s2 > s1   = Win P2 TimeUp
            | otherwise = Draw

