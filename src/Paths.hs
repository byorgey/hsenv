module Paths ( hseDirStructure
             , cabalConfigLocation
             , dotDirName
             , insidePathVar
             ) where

import Data.List (intercalate)
import System.FilePath ((</>))
import System.Directory (getCurrentDirectory)

import Util.IO (getEnvVar)
import Types
import MyMonad

-- returns record containing paths to all important directories
-- inside virtual environment dir structure
hseDirStructure :: MyMonad DirStructure
hseDirStructure = do
  cwd <- liftIO getCurrentDirectory
  dirName <- dotDirName
  let hsEnvLocation    = cwd
      hsEnvDirLocation = hsEnvLocation </> dirName
      cabalDirLocation = hsEnvDirLocation </> "cabal"
      ghcDirLocation   = hsEnvDirLocation </> "ghc"
  return DirStructure { hsEnv          = hsEnvLocation
                      , hsEnvDir       = hsEnvDirLocation
                      , ghcPackagePath = hsEnvDirLocation </> "ghc_pkg_db"
                      , cabalDir       = cabalDirLocation
                      , cabalBinDir    = cabalDirLocation </> "bin"
                      , hsEnvBinDir    = hsEnvDirLocation </> "bin"
                      , ghcDir         = ghcDirLocation
                      , ghcBinDir      = ghcDirLocation </> "bin"
                      }

-- directory name of hsEnvDir
dotDirName :: MyMonad String
dotDirName = do
  name <- asks hsEnvName
  return $ ".hsenv_" ++ name

-- returns location of cabal's config file inside virtual environment dir structure
cabalConfigLocation :: MyMonad FilePath
cabalConfigLocation = do
  dirStructure <- hseDirStructure
  return $ cabalDir dirStructure </> "config"

-- returns value of $PATH env variable to be used inside virtual environment
insidePathVar :: MyMonad String
insidePathVar = do
  oldPathVar <- liftIO $ getEnvVar "PATH"
  let oldPathVarSuffix = case oldPathVar of
                           Nothing -> ""
                           Just x  -> ':' : x
  dirStructure <- hseDirStructure
  ghc          <- asks ghcSource
  let extraPathElems = case ghc of
                         System    -> [cabalBinDir dirStructure]
                         Tarball _ -> [cabalBinDir dirStructure, ghcBinDir dirStructure]
  return $ intercalate ":" extraPathElems ++ oldPathVarSuffix
