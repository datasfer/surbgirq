{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

{-|
Module      : Surbgirq.Neo4j.Instances
Description : Instances for Neo4j representations

Instances to coerce from/to Neo4j
-}

module Surbgirq.Neo4j.Instances where

import Database.Bolt

import qualified Data.Text as T

-- import           Database.Bolt.Extras.Template

import Common.Aeson
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

data HAS_CH = HAS_CH
data HAS_VERSE = HAS_VERSE



-- fromList [("b",S (Structure {signature = 78, fields = [I 0,L [T "Book"],M (fromList [("title",T "matthew")])]}))]
-- fromList [("b",S (Structure {signature = 78, fields = [I 41,L [T "Book"],M (fromList [("title",T "matthew")])]}))]
-- fromList [("b",
--S (Structure {signature = 78, fields = [I 640
--                                       ,L [T "Book",T "Matthew",T "New"]
--                                       ,M (fromList [("title",T "Matthew")])
--                                       ]   } )

-- [S (Structure {signature = 78,
-- fields = [I 0,L [T "Book"],M (fromList [("title",T "matthew")])]}),
-- S (Structure {signature = 78, fields = [I 41,L [T "Book"],M (fromList [("title",T "matthew")])]}),S (Structure {signature = 78, fields = [I 640,L [T "Book",T "Matthew",T "New"],M (fromList [("title",T "Matthew")])]})]


-------------------------------------------------------------------------------
-- Book Node
-------------------------------------------------------------------------------

-- | parse Neo4j bolt representation to `Book` data type
instance RecordValue Book where
    exact (S Structure {fields = (I i: L labels : M props : _)}) | T "Book" `elem` labels =
        do
            title <- exact =<< props `at` "title"
            lbs   <- traverse exact labels
            number <- exact =<< props `at` "num"
            numOfChatpters <- exact =<< props `at` "chapters"
            translation <- exact =<< props `at` "translation"
            girq :: Girq <-  exact =<< props `at` "book"
            tes :: Testament <-  exact =<< props `at` "testament"
            bookId  <-  exact =<< props `at` "bookId"

            return $ Book i bookId lbs girq title number numOfChatpters tes translation
    exact x = fail $ show x ++ " is not a Book"


-- | parse Neo4j bolt representation to `Girq` data type
instance RecordValue Girq where
    exact (T book) = return $ read $ T.unpack  book
    exact x        = fail $ show x ++ " is not a Girq"

-- | parse Neo4j bolt representation to `Testament` data type
instance RecordValue Testament where
    exact (T tes) = return $ read $ T.unpack  tes
    exact x       = fail $ show x ++ " is not a Testament"

-- \{book: '{bookName}', title: '{book'title}', number: {book'orderNum}, chapters: {book'chapters}, testament: {book'testament}, translation: {book'translation} } ),


-------------------------------------------------------------------------------
-- Chapter Node
-------------------------------------------------------------------------------

-- | parse Neo4j bolt representation to `Chapter` data type
instance RecordValue Chapter where
    exact (S Structure {fields = (I i : L labels : M props :_)}) | T "Chapter" `elem` labels =
        do
            title <- exact =<< props `at` "title"
            number <- exact =<< props `at` "num"
            girq :: Girq <-  exact =<< props `at` "book"

            return $ Chapter i girq number title
    exact x = fail $ show x ++ " is not a Chapter Node"


-------------------------------------------------------------------------------
-- Section Node
-------------------------------------------------------------------------------


-- | parse Neo4j bolt representation to `Section` data type
instance RecordValue Section where
    exact (S Structure {fields = (I i : L labels : M props : _)}) | T "Section" `elem` labels =
        do
            title <- exact =<< props `at` "title"
            number <- exact =<< props `at` "num"
            chapter <- exact =<< props `at` "chapter"
--            girq :: Girq <-  exact =<< props `at` "book"
            lbs   <- traverse exact labels
            sectionID  <-  exact =<< props `at` "sectionID"

            return $ Section i sectionID lbs chapter number title
    exact x = fail $ show x ++ " is not a Section Node"




-------------------------------------------------------------------------------
-- Verse Node
-------------------------------------------------------------------------------

-- | parse Neo4j bolt representation to `Verse` data type
instance RecordValue Verse where
    exact (S Structure {fields = (I i : L labels : M props : _)}) | T "Verse" `elem` labels =
        do
            chNum <- exact =<< props `at` "chapter"
--            secNum <- exact =<< props `at` "section"
            secTitle <- exact =<< props `at` "section_title"
            prgNum <- exact =<< props `at` "paragraph"
            verseNum <- exact =<< props `at` "num"
            content <- exact =<< props `at` "content"

            girq :: Girq <-  exact =<< props `at` "book"
            lbs   <- traverse exact labels
            verseID  <-  exact =<< props `at` "verseID"

            return $ Verse i verseID lbs girq chNum  secTitle prgNum verseNum content
    exact x = fail $ show x ++ " is not a Verse Node"





