{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

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


-------------------------------------------------------------------------------
-- Book descriptive query
-------------------------------------------------------------------------------

queryBooks :: BoltActionT IO [Book]
queryBooks = do
        rs <- query "MATCH (book:Book) RETURN book;"
        nodes <- traverse (`at` "book") rs
        bs <- traverse exact nodes
        return bs

-- match (b:Book {book: 'Matthew'})-[r:HAS_CH]->(ch:Chapter) return ch.number;
queryChapterNums :: Girq -> BoltActionT IO [(Int,Text)]
queryChapterNums girq = do
        rs <- queryP cypherQ params
        numProps <- traverse (`at` "ch.num") rs
        titleProps <- traverse (`at` "ch.title") rs
        nums <- traverse exact numProps
        ts <- traverse exact titleProps
        return $ zip nums ts
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH]->(ch:Chapter) RETURN ch.num, ch.title order by ch.num;"
         params = fromList [("girq", T . pack $ show girq)]

querySectionNums :: Girq -> ChapterNum -> BoltActionT IO [(Int,Text)]
querySectionNums girq (ChapterNum ch_num) = do
        -- fromList [("s.num",I 1),("s.title",T "Title 1")]
        rs <- queryP cypherQ params
        numProps <- traverse (`at` "s.num") rs
        titleProps <- traverse (`at` "s.title") rs
        nums <- traverse exact numProps
        ts <- traverse exact titleProps
        return $ zip nums ts
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(s:Section) return s.num, s.title order by s.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]


queryChapterVerseNums :: Girq -> ChapterNum -> BoltActionT IO [Int]
queryChapterVerseNums girq (ChapterNum ch_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "v.num") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) return v.num order by v.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]



-------------------------------------------------------------------------------
-- Scriptures Data
-------------------------------------------------------------------------------

-- match (b:Book {book: "Matthew"})-[:HAS_CH {num: 1}]->(ch) return ch;
-- match (b:Book {book: "Matthew"})-[:HAS_CH]->(ch:Chapter) where ch.number = 1 return ch;
-- |
-- return chapter
queryChapter :: Girq -> ChapterNum -> BoltActionT IO [Chapter]
queryChapter girq (ChapterNum ch_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "ch") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]->(ch) RETURN ch;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]



-- |
-- return all sections of chapter
queryAllSections :: Girq -> ChapterNum -> BoltActionT IO [Section]
queryAllSections girq (ChapterNum ch_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "s") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(s:Section) return s order by s.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]

-- |
-- return the section of chapter
querySection :: Girq -> ChapterNum -> SectionNum -> BoltActionT IO [Section]
querySection girq (ChapterNum ch_num) (SectionNum sec_num)= do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "s") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(s:Section {num: {sec_num}}) return s order by s.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("sec_num", I sec_num)]

-- |
-- return verse
-- ?? if remove `b:` then will ignore chapter filter, strange behaviour
queryVerse :: Girq -> ChapterNum -> VerseNum -> BoltActionT IO [Verse]
queryVerse girq (ChapterNum ch_num) (VerseNum verse_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "v") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse{num: {verse_num}}) return v;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("verse_num", I verse_num)]


-- |
-- return all verses of chapter
queryAllVerses :: Girq -> ChapterNum -> BoltActionT IO [Verse]
queryAllVerses girq (ChapterNum ch_num) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "v") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) return v order by v.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]


-- |
-- return verse interval of chapter
queryVerseInterval :: Girq -> ChapterNum -> VerseNum -> VerseNum -> BoltActionT IO [Verse]
queryVerseInterval girq (ChapterNum ch_num) (VerseNum verse_from) (VerseNum verse_to) = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` "v") rs
        bs <- traverse exact nodes
        return bs
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) WHERE v.num >= {verse_from} AND v.num <= {verse_to} return v order by v.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("verse_from", I verse_from), ("verse_to", I verse_to)]



