{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Surbgirq.Shell.Scraper.Scalpel


main :: IO ()
main = do
  test1  "https://www.qahana.am/bible/NewTestament/Matthew.html"

