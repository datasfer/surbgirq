{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import qualified Data.Text.IO                   as TIO
import           GHC.IO.Encoding
import           Surbgirq.Shell.Scraper.Scalpel
import           System.IO

main :: IO ()
main = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  ts <- test1  "https://www.qahana.am/bible/NewTestament/Matthew.html"
  case ts of
    Nothing   -> TIO.putStrLn "Գիրք ծննդեան"
    Just [xs] -> mapM_ (TIO.putStrLn) xs


