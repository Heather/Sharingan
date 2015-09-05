{-# LANGUAGE
    MultiWayIf
  , LambdaCase
  , CPP
  , UnicodeSyntax
  #-}

module Shell.Pull
  ( pull
  ) where

import Data.List.Split
import Data.Maybe
import Data.List

import System.Info (os)
import System.Directory
import System.FilePath((</>))

import System.Process

import Trim
import Exec
import Config

import Shell.Helper

pull :: String → String → [String]
      → Bool → Bool → Bool → Bool → Maybe String
      → Bool → MyEnv → IO (Bool, Bool)
pull path branch _ unsafe frs processClean _ rhash _ myEnv =
    doesDirectoryExist path ≫= \dirExists →
      if dirExists then execPull
                   else return (False, False)
  where
    gitX :: IO (Bool, Bool)
    gitX = vd ".git" path $ do
      let (myGit, msGit) = getMyMsGit myEnv
          whe c s = when c $ exec s
      currentbranch ← readProcess myGit ["rev-parse", "--abbrev-ref", "HEAD"] []
      let cbr = trim currentbranch
      whe (cbr ≢ branch) $ msGit ⧺ " checkout " ⧺ branch
      whe (not unsafe)   $ msGit ⧺ " reset --hard"
      whe processClean   $ msGit ⧺ " clean -xdf"
      loc ← case rhash of
              Just hsh → return hsh
              _ → readProcess myGit ["log", "-n", "1"
                                    , "--pretty=format:%H"
                                    ] []
      rlm ← readIfSucc myGit ["ls-remote", "origin", branch]
      case rlm of
       Just rlc → do
         lrc ← if isNothing rhash
           then readProcess myGit ["log", "-n", "1"
                                  , "--pretty=format:%H"
                                  ] []
           else return (trim loc)
         let remoteloc = head (splitOn "\t" rlc)
             localloc = trim lrc
         putStrLn $ "Origin: " ⧺ remoteloc
         putStrLn $ "Local: "  ⧺ localloc
         if remoteloc ≢ localloc ∨ frs
             then do exec $ msGit ⧺ " pull origin " ⧺ branch
                     hashupdate remoteloc path
                     return (True, True)
             else return (True, False)
       _ → return (False, False)

    hgX :: IO (Bool, Bool)
    hgX = vd ".hg" path $ do
      exec "hg pull --update"
      return (True, True)

    execPull :: IO (Bool, Bool)
    execPull = return (False, False) ≫= chk gitX
                                     ≫= chk hgX