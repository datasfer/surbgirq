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
queryChapter :: Girq -> ChapterNum -> BoltActionT IO [Chapter]
queryChapter girq (ChapterNum ch_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "ch") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]->(ch) RETURN ch;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]


-- |
-- return verse
-- ?? if remove `b:` then will ignore chapter filter, strange behaviour
queryVerse :: Girq -> ChapterNum -> VerseNum -> BoltActionT IO [Verse]
queryVerse girq (ChapterNum ch_num) (VerseNum verse_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "v") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse{verse: {verse_num}}) return v;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("verse_num", I verse_num)]


-- |
-- return verse interval
queryVerseInterval :: Girq -> ChapterNum -> VerseNum -> VerseNum -> BoltActionT IO [Verse]
queryVerseInterval girq (ChapterNum ch_num) (VerseNum verse_from) (VerseNum verse_to) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "v") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) WHERE v.verse >= {verse_from} AND v.verse <= {verse_to} return v order by v.verse;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("verse_from", I verse_from), ("verse_to", I verse_to)]



