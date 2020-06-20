{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE OverloadedLabels    #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where


import Control.Exception    (bracket)
import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)

import Data.Aeson
import Data.Char
import Data.Maybe (catMaybes, fromMaybe)
import Data.Text  (Text, pack, split, splitOn)

import qualified Data.Text               as T
import qualified Data.Text.Encoding      as TE
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import           Data.Text.Lazy.Encoding as TLE

import Options.Applicative
import System.Directory      (createDirectoryIfMissing)
import System.FilePath       (splitFileName)
import System.FilePath.Posix (takeBaseName)

import System.IO
import Text.InterpolatedString.Perl6 (qc)

import Control.Monad
import Data.List
import System.FilePath

import Database.Selda
import Database.Selda.SQLite

import Common.Yaml
import Surbgirq.Shell.Commands
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq

import Surbgirq.Shell.Store.ParseFile
import Surbgirq.Shell.Store.SQLite.Selda

main :: IO ()
main = --  liftIO $ createDirectoryIfMissing True $ "db"
  withSQLite "db/ban.sqlite" $ do
    createTable engLemmaTable
    createTable wordFormTable

    xs <- liftIO $ parseLemmaFile "data/txt/engLemmas.txt"
    insert_ engLemmaTable xs

    ys <- liftIO $ parseWordFormFile "data/txt/wordForms.txt"
    insert_ wordFormTable ys

    return ()


{-
main1 :: IO ()
main1 = do
 -- bs <- readBooks "./data/yaml/books.yaml"
--  ss1 <- readScriptures "./data/yaml/matthew/1.yaml"
--  ss <- readSections "./data/yaml/matthew/1.yaml"
  ch <- readChapter "./data/yaml/matthew/1.yaml"
--  mapM_  (\Section{..} -> )chapter'sections
  hSetEncoding stdout utf8
  let res = (TL.toStrict . TLE.decodeUtf8 $ encode ch)
  TIO.writeFile "file.txt" res
  TIO.putStrLn res
  TIO.putStrLn "Գիրք ծննդեան"
-}
