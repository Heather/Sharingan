module Shell
  ( exec,
    exc,
    gpull,
    gclone,
    rebasefork,
    gentooSync
  ) where

import System.Directory
import System.Process

import Control.Monad
{----------------------------------------------------------------------------------------}
exec :: [Char] -> IO()
exec args = do
    pid <- runCommand args
    waitForProcess pid >> return ()
{----------------------------------------------------------------------------------------}
exc :: [Char] -> [Char] -> IO()
exc path args = setCurrentDirectory path >> exec args
{----------------------------------------------------------------------------------------}
rebasefork :: [Char] -> [Char] -> [Char] -> IO Bool
rebasefork path branch upstream =
    doesDirectoryExist path >>= \dirExist ->
        if dirExist
            then do exc path $ "git checkout "                          ++ branch   
                        ++ " & git rebase --abort & git pull origin "   ++ branch
                        ++ " & git fetch "                              ++ upstream
                        ++ " & git pull --rebase "                      ++ upstream
                        ++ " & git push --force origin "                ++ branch
                    return True
            else    return False
{----------------------------------------------------------------------------------------}
gentooSync :: [Char] -> Int -> IO()
gentooSync path jobs = exc path $ " cvs update "
            ++ "egencache --update --repo=gentoo --portdir=" ++ path
            ++ " --jobs=" ++ show jobs
{----------------------------------------------------------------------------------------}
gpull :: [Char] -> [Char] -> IO()
gpull path branch =
    doesDirectoryExist path >>= (flip when
        $ exc path $ "git pull origin " ++ branch)
{----------------------------------------------------------------------------------------}
gclone :: [Char] -> [Char] -> IO()
gclone path project =
    doesDirectoryExist path >>= \dirExist -> 
        if dirExist then putStrLn $ "directory already exist"
                    else exec $ "git clone " ++ project ++ " " ++ path
{----------------------------------------------------------------------------------------}
