{-# LANGUAGE CPP #-}
{-# LANGUAGE NoRebindableSyntax #-}
#if __GLASGOW_HASKELL__ >= 810
{-# OPTIONS_GHC -Wno-prepositive-qualified-module #-}
#endif
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module Paths_my_game_project (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where


import qualified Control.Exception as Exception
import qualified Data.List as List
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude


#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir `joinFileName` name)

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath




bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath
bindir     = "/Users/phungthingochuyen/Desktop/my-game-project/.stack-work/install/aarch64-osx/34c3afc95f10d0720fbdc88f13fb53f56b78242a504cb10ad85284cf02db8b80/9.10.3/bin"
libdir     = "/Users/phungthingochuyen/Desktop/my-game-project/.stack-work/install/aarch64-osx/34c3afc95f10d0720fbdc88f13fb53f56b78242a504cb10ad85284cf02db8b80/9.10.3/lib/aarch64-osx-ghc-9.10.3-fe9c/my-game-project-0.1.0.0-4S9SMRhTj5eDUGHohV1iZM-my-game-project-test"
dynlibdir  = "/Users/phungthingochuyen/Desktop/my-game-project/.stack-work/install/aarch64-osx/34c3afc95f10d0720fbdc88f13fb53f56b78242a504cb10ad85284cf02db8b80/9.10.3/lib/aarch64-osx-ghc-9.10.3-fe9c"
datadir    = "/Users/phungthingochuyen/Desktop/my-game-project/.stack-work/install/aarch64-osx/34c3afc95f10d0720fbdc88f13fb53f56b78242a504cb10ad85284cf02db8b80/9.10.3/share/aarch64-osx-ghc-9.10.3-fe9c/my-game-project-0.1.0.0"
libexecdir = "/Users/phungthingochuyen/Desktop/my-game-project/.stack-work/install/aarch64-osx/34c3afc95f10d0720fbdc88f13fb53f56b78242a504cb10ad85284cf02db8b80/9.10.3/libexec/aarch64-osx-ghc-9.10.3-fe9c/my-game-project-0.1.0.0"
sysconfdir = "/Users/phungthingochuyen/Desktop/my-game-project/.stack-work/install/aarch64-osx/34c3afc95f10d0720fbdc88f13fb53f56b78242a504cb10ad85284cf02db8b80/9.10.3/etc"

getBinDir     = catchIO (getEnv "my_game_project_bindir")     (\_ -> return bindir)
getLibDir     = catchIO (getEnv "my_game_project_libdir")     (\_ -> return libdir)
getDynLibDir  = catchIO (getEnv "my_game_project_dynlibdir")  (\_ -> return dynlibdir)
getDataDir    = catchIO (getEnv "my_game_project_datadir")    (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "my_game_project_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "my_game_project_sysconfdir") (\_ -> return sysconfdir)



joinFileName :: String -> String -> FilePath
joinFileName ""  fname = fname
joinFileName "." fname = fname
joinFileName dir ""    = dir
joinFileName dir fname
  | isPathSeparator (List.last dir) = dir ++ fname
  | otherwise                       = dir ++ pathSeparator : fname

pathSeparator :: Char
pathSeparator = '/'

isPathSeparator :: Char -> Bool
isPathSeparator c = c == '/'
