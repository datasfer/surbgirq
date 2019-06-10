{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Exception      (bracket)
import Control.Monad.IO.Class (liftIO)

import Database.Bolt


import Surbgirq.Neo4j


main :: IO ()
main = do
    bracket (connect localCfg) close $ \pipe -> run pipe $ do
        rs <- getBooks
        nodes <- traverse (`at` "book") rs
        (liftIO . print) nodes
        (liftIO . print) =<< getBookNodes
--        return ()
