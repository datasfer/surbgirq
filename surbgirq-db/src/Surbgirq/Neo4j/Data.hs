{-# LANGUAGE OverloadedStrings #-}


module Surbgirq.Neo4j.Data where

import Data.Map.Strict (fromList)

import qualified Data.Text as T

import Data.Text            (Text, pack)
import Database.Bolt        hiding (pack)
import Surbgirq.Neo4j.Types
import Surbgirq.Types


-------------------------------------------------------------------------------
-- for debig

boltBooks :: BoltActionT IO [Record]
boltBooks = do
        resp <- query "MATCH (book:Book) RETURN book;"
        return resp


queryBooks :: BoltActionT IO [Book]
queryBooks = do
        rs <- query "MATCH (book:Book) RETURN book;"
        nodes <- traverse (`at` "book") rs
        bs <- traverse exact nodes
        return bs


-- match (b:Book {book: "Matthew"})-[:HAS_CH {num: 1}]->(ch) return ch;
-- match (b:Book {book: "Matthew"})-[:HAS_CH]->(ch:Chapter) where ch.number = 1 return ch;
queryChapter :: Girq -> Int -> BoltActionT IO [Chapter]
queryChapter girq ch_num = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "ch") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]->(ch) RETURN ch;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]




