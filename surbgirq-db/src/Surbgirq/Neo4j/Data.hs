{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

{-|
Module      : Surbgirq.Neo4j.Data
Description : Neo4j queries

All queries to Neo4j db
-}

module Surbgirq.Neo4j.Data (
  -- * Book meta info Queries
   queryBooks
 , queryChapterNums
 , querySectionNums
 , queryChapterVerseNums

  -- * Scripture entity queries
 , queryAllSections
 , queryAllVerses
 , queryChapter
 , querySection
 , queryVerse
 , queryVerseInterval

  -- * Helpers
 , boltBooks
 ) where


import Control.Monad.IO.Class     (MonadIO)
import Control.Monad.Trans.Reader (ReaderT)

import Data.Map.Strict (fromList)
import Data.Text       (Text, pack)
import Database.Bolt   hiding (pack)

import qualified Data.Map as M

import Surbgirq.Neo4j.Instances ()
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------


-- | for debug
boltBooks :: BoltActionT IO [Record]
boltBooks = query "MATCH (book:Book) RETURN book;"



-- | query to return all nodes labeled `BOOK` as `Book` data type
queryBooks :: BoltActionT IO [Book]
queryBooks = do
        rs <- query "MATCH (book:Book) RETURN book;"
        nodes <- traverse (`at` "book") rs
        traverse exact nodes

-- | query to return all chapters info tuples of book @girq
-- match (b:Book {book: 'Matthew'})-[r:HAS_CH]->(ch:Chapter) return ch.number;
queryChapterNums :: Girq -> BoltActionT IO [(Int,Text)]
queryChapterNums girq = zipTraversExact cypherQ params "ch.num" "ch.title"
        -- rs <- queryP cypherQ params
        -- numProps <- traverse (`at` "ch.num") rs
        -- titleProps <- traverse (`at` "ch.title") rs
        -- nums <- traverse exact numProps
        -- ts <- traverse exact titleProps
        -- return $ zip nums ts
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH]->(ch:Chapter) RETURN ch.num, ch.title order by ch.num;"
         params = fromList [("girq", T . pack $ show girq)]

-- | query to return all sections info tuples of chapter @ch_num of  book @girq
querySectionNums :: Girq -> ChapterNum -> BoltActionT IO [(Int,Text)]
querySectionNums girq (ChapterNum ch_num) = zipTraversExact cypherQ params "s.num" "s.title"
        -- fromList [("s.num",I 1),("s.title",T "Title 1")]
        -- rs <- queryP cypherQ params
        -- numProps <- traverse (`at` "s.num") rs
        -- titleProps <- traverse (`at` "s.title") rs
        -- nums <- traverse exact numProps
        -- ts <- traverse exact titleProps
        -- return $ zip nums ts
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(s:Section) return s.num, s.title order by s.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]


-- | query to return all verses numbers list of chapter @ch_num of  book @girq
queryChapterVerseNums :: Girq -> ChapterNum -> BoltActionT IO [Int]
queryChapterVerseNums girq (ChapterNum ch_num) = traversExact cypherQ params "v.num"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "v.num") rs
        -- traverse exact nodes
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) return v.num order by v.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]



-------------------------------------------------------------------------------
-- Scriptures Data
-------------------------------------------------------------------------------



-- |
-- return all sections of chapter
queryAllSections :: Girq -> ChapterNum -> BoltActionT IO [Section]
queryAllSections girq (ChapterNum ch_num) = traversExact cypherQ params "s"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "s") rs
        -- traverse exact nodes
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(s:Section) return s order by s.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]

-- |
-- return all verses of chapter
queryAllVerses :: Girq -> ChapterNum -> BoltActionT IO [Verse]
queryAllVerses girq (ChapterNum ch_num) = traversExact cypherQ params "v"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "v") rs
        -- traverse exact nodes
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) return v order by v.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]


-- match (b:Book {book: "Matthew"})-[:HAS_CH {num: 1}]->(ch) return ch;
-- match (b:Book {book: "Matthew"})-[:HAS_CH]->(ch:Chapter) where ch.number = 1 return ch;
-- |
-- return chapter
queryChapter :: Girq -> ChapterNum -> BoltActionT IO [Chapter]
queryChapter girq (ChapterNum ch_num) = traversExact cypherQ params "ch"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "ch") rs
        -- traverse exact nodes
   where cypherQ = "match (Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]->(ch) RETURN ch;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num)]

-- |
-- return the section of chapter
querySection :: Girq -> ChapterNum -> SectionNum -> BoltActionT IO [Section]
querySection girq (ChapterNum ch_num) (SectionNum sec_num)= traversExact cypherQ params "s"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "s") rs
        -- traverse exact nodes
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(s:Section {num: {sec_num}}) return s order by s.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("sec_num", I sec_num)]

-- |
-- return verse
-- ?? if remove `b:` then will ignore chapter filter, strange behaviour
queryVerse :: Girq -> ChapterNum -> VerseNum -> BoltActionT IO [Verse]
queryVerse girq (ChapterNum ch_num) (VerseNum verse_num) = traversExact cypherQ params "v"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "v") rs
        -- traverse exact nodes
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse{num: {verse_num}}) return v;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("verse_num", I verse_num)]



-- |
-- return verse interval of chapter
queryVerseInterval :: Girq -> ChapterNum -> VerseNum -> VerseNum -> BoltActionT IO [Verse]
queryVerseInterval girq (ChapterNum ch_num) (VerseNum verse_from) (VerseNum verse_to) =
    traversExact cypherQ params "v"
        -- rs <- queryP cypherQ params
        -- nodes <- traverse (`at` "v") rs
        -- traverse exact nodes
   where cypherQ = "match (b:Book {book: {girq}})-[:HAS_CH {num: {ch_num}}]-()-[*]->(v:Verse) WHERE v.num >= {verse_from} AND v.num <= {verse_to} return v order by v.num;"
         params = fromList [("girq", T . pack $ show girq), ("ch_num", I ch_num), ("verse_from", I verse_from), ("verse_to", I verse_to)]



-------------------------------------------------------------------------------
-- Book descriptive query
-------------------------------------------------------------------------------


-- | select object by attr from query and coerce to types
traversExact :: (MonadIO m, RecordValue b)
   => Text
   -> M.Map Text Value
   -> Text
   -> ReaderT Pipe m [b]
traversExact cypherQ params attr = do
        rs <- queryP cypherQ params
        nodes <- traverse (`at` attr) rs
        traverse exact nodes

-- | select object by @attr1 and @attr2 from query,  coerce to types and zip
zipTraversExact :: (MonadIO m, RecordValue a, RecordValue b)
   => Text
   -> M.Map Text Value
   -> Text
   -> Text
   -> ReaderT Pipe m [(a,b)]
zipTraversExact cypherQ params attr1 attr2 = do
        rs <- queryP cypherQ params
        numProps <- traverse (`at` attr1) rs
        titleProps <- traverse (`at` attr2) rs
        nums <- traverse exact numProps
        ts <- traverse exact titleProps
        return $ zip nums ts

