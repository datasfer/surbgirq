{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Exception      (bracket)
import Control.Monad.IO.Class (liftIO)

import Database.Bolt
import System.IO

import qualified Data.Text as T

import           Data.Aeson
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import           Data.Text.Lazy.Encoding as TLE
import           Surbgirq.Neo4j
import           Surbgirq.Types

main :: IO ()
main = do
    hSetEncoding stdout utf8

    bracket (connect localCfg) close $ \pipe -> run pipe $ do
        rs <- boltBooks
        nodes <- traverse (`at` "book") rs
        (liftIO . print) nodes

        books <- queryBooks
        let booksRes = (TL.toStrict . TLE.decodeUtf8 $ encode books)
        (liftIO . TIO.putStrLn) booksRes

        chs <- queryChapter Matthew (ChapterNum 2)
        let res = (TL.toStrict . TLE.decodeUtf8 $ encode chs)
        (liftIO . TIO.putStrLn) res

        liftIO $ TIO.writeFile "file.txt" res

--        return ()
