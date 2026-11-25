{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Store.ParseFile where

import System.IO

import Control.Exception (bracket)

import Data.Maybe                    (catMaybes)
import Data.Text                     (Text, pack, split, splitOn)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Text    as T
import qualified Data.Text.IO as TIO

import Surbgirq.Shell.Store.Types

parseLemmaFile :: FilePath -> IO [EngLemma]
parseLemmaFile file = do
  bracket (openFile file ReadMode) hClose $ \handle -> do
    _ <- TIO.hGetLine handle -- read header
    content <- TIO.hGetContents handle     -- read the rest of file

    return $ catMaybes $ map lineToEntity (splitOn "\r\n" content)
  where
    -- the ID stays 0: nothing reads it
    lineToEntity :: Text -> Maybe EngLemma
    lineToEntity line =
        let ws = T.words (T.strip line)
        in  case ws of
              (w1:w2) -> Just $ EngLemma 0 w1 (T.unwords w2)
              _       -> Nothing


parseWordFormFile :: FilePath -> IO [WordForm]
parseWordFormFile file = do
  bracket (openFile file ReadMode) hClose $ \handle -> do
    _ <- TIO.hGetLine handle -- read header
    content <- TIO.hGetContents handle     -- read the rest of file

    return $ catMaybes $ map lineToEntity (splitOn "\r\n" content)
  where
    -- the ID stays 0: wordFormsCSV numbers the forms itself
    lineToEntity :: Text -> Maybe WordForm
    lineToEntity line =
        let ws = T.words (T.strip line)
        in  case ws of
              [w1,w2,w3]    -> Just $ WordForm 0 w1 w2 w3
              [w1,w2,w3,w4] -> Just $ WordForm 0 w1 (w2 <> w3) w4
              _             -> Nothing

