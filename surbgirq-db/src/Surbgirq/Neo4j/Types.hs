{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Neo4j.Types where

import           Data.Text (Text)
import qualified Data.Text as T

-- import           Database.Bolt.Extras.Template
import Database.Bolt

import Common.Aeson
import Surbgirq.Types

data HAS_CH = HAS_CH
data HAS_VERSE = HAS_VERSE



-------------------------------------------------------------------------------
-- Book Node
-------------------------------------------------------------------------------


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



instance RecordValue Book where
    exact (S (Structure {fields = (I i:(L labels):(M props):_)})) | elem (T "Book") labels =
        do
            title <- exact =<< props `at` "title"
            lbs   <- traverse exact labels
            number <- exact =<< props `at` "num"
            numOfChatpters <- exact =<< props `at` "chapters"
            translation <- exact =<< props `at` "translation"
            girq :: Girq <-  exact =<< props `at` "book"
            tes :: Testament <-  exact =<< props `at` "testament"

            return $ Book i lbs girq title number numOfChatpters tes translation
    exact x = fail $ show x ++ " is not a Book"



instance RecordValue Girq where
    exact (T book) = return $ read $ T.unpack  book
    exact x        = fail $ show x ++ " is not a Girq"


instance RecordValue Testament where
    exact (T tes) = return $ read $ T.unpack  tes
    exact x       = fail $ show x ++ " is not a Testament"

-- \{book: '{bookName}', title: '{book'title}', number: {book'number}, chapters: {book'chapters}, testament: {book'testament}, translation: {book'translation} } ),


-------------------------------------------------------------------------------
-- Chapter Node
-------------------------------------------------------------------------------


instance RecordValue Chapter where
    exact (S (Structure {fields = (I i:(L labels):(M props):_)})) | elem (T "Chapter") labels =
        do
            title <- exact =<< props `at` "title"
            number <- exact =<< props `at` "num"
            girq :: Girq <-  exact =<< props `at` "book"

            return $ Chapter i girq number title
    exact x = fail $ show x ++ " is not a Chapter Node"


-------------------------------------------------------------------------------
-- Section Node
-------------------------------------------------------------------------------


instance RecordValue Section where
    exact (S (Structure {fields = (I i:(L labels):(M props):_)})) | elem (T "Section") labels =
        do
            title <- exact =<< props `at` "title"
            number <- exact =<< props `at` "num"
--            girq :: Girq <-  exact =<< props `at` "book"

            return $ Section i number title
    exact x = fail $ show x ++ " is not a Section Node"




-------------------------------------------------------------------------------
-- Verse Node
-------------------------------------------------------------------------------

instance RecordValue Verse where
    exact (S (Structure {fields = (I i:(L labels):(M props):_)})) | elem (T "Verse") labels =
        do
            chNum <- exact =<< props `at` "chapter"
            secNum <- exact =<< props `at` "section"
            secTitle <- exact =<< props `at` "section_title"
            prgNum <- exact =<< props `at` "paragraph"
            verseNum <- exact =<< props `at` "num"
            content <- exact =<< props `at` "content"

            girq :: Girq <-  exact =<< props `at` "book"

            return $ Verse i girq chNum secNum secTitle prgNum verseNum content
    exact x = fail $ show x ++ " is not a Verse Node"





