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

import Surbgirq.Shell.Store.SQLite.Selda

main :: IO ()
main = --  liftIO $ createDirectoryIfMissing True $ "db"
  withSQLite "db/ban.sqlite" $ do
    createTable engLemma
    createTable wordFrom

    xs <- liftIO $ parseLemmaFile "data/txt/engLemmas.txt"
    insert_ engLemma xs

    ys <- liftIO $ parseWordFormFile "data/txt/wordForms.txt"
    insert_ wordFrom ys

    return ()

parseLemmaFile :: FilePath -> IO [EngLemma]
parseLemmaFile file = do
  bracket (openFile file ReadMode) hClose $ \handle -> do
    _ <- TIO.hGetLine handle -- read header
    content <- TIO.hGetContents handle     -- read the rest of file

    return $ catMaybes $ map lineToEntity (splitOn "\r\n" content)
  where
    lineToEntity :: Text -> Maybe EngLemma
    lineToEntity line =
        let ws = T.words (T.strip line)
        in  case ws of
              (w1:w2) -> Just $ EngLemma w1 (T.unwords w2)
              _       -> Nothing


parseWordFormFile :: FilePath -> IO [WordForm]
parseWordFormFile file = do
  bracket (openFile file ReadMode) hClose $ \handle -> do
    _ <- TIO.hGetLine handle -- read header
    content <- TIO.hGetContents handle     -- read the rest of file

    return $ catMaybes $ map lineToEntity (splitOn "\r\n" content)
  where
    lineToEntity :: Text -> Maybe WordForm
    lineToEntity line =
        let ws = T.words (T.strip line)
        in  case ws of
              (w1:w2:w3) -> Just $ WordForm w1 w2 (T.unwords w3)
              _          -> Nothing



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
