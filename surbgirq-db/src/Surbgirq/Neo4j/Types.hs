 {-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Neo4j.Types where

import           Data.Text (Text)
import qualified Data.Text as T

-- import           Database.Bolt.Extras.Template
import Database.Bolt

import Surbgirq.Types

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

data BookNode = BookNode
    {
      bookNode'id          :: Int
    , bookNode'labels      :: [Text]
    , bookNode'book        :: Girq
    , bookNode'title       :: Text
    , bookNode'number      :: Int
    , bookNode'chapters    :: Int
    , bookNode'testament   :: Testament
    , bookNode'translation :: Text
    } deriving (Show)


instance RecordValue BookNode where
    exact (S (Structure {fields = (I i:(L labels):(M props):_)})) | elem (T "Book") labels =
        do
            title <- exact =<< props `at` "title"
            lbs   <- traverse exact labels
            number <- exact =<< props `at` "number"
            numOfChatpters <- exact =<< props `at` "chapters"
            translation <- exact =<< props `at` "translation"
            girq :: Girq <-  exact =<< props `at` "book"
            tes :: Testament <-  exact =<< props `at` "testament"

            return $ BookNode i lbs girq title number numOfChatpters tes translation
    exact x = fail $ show x ++ " is not a Book"



instance RecordValue Girq where
    exact (T book) = return $ read $ T.unpack  book
    exact x        = fail $ show x ++ " is not a Girq"


instance RecordValue Testament where
    exact (T tes) = return $ read $ T.unpack  tes
    exact x       = fail $ show x ++ " is not a Testament"

-- \{book: '{bookName}', title: '{book'title}', number: {book'number}, chapters: {book'chapters}, testament: {book'testament}, translation: {book'translation} } ),
