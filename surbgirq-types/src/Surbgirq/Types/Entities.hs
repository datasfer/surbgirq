{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE RecordWildCards #-}

module Surbgirq.Types.Entities (
   Book(..)
 , Chapter (..)
 , Section(..)
 , Paragraph(..)
 , Verse(..)
 , ChapterNum (..)
 , SectionNum(..)
 , VerseNum(..)
 ) where

import Data.Aeson (Value)
import Data.Text  (Text)

import GHC.Generics

import Common.Aeson
import Data.Aeson
import Surbgirq.Types.Girq



newtype ChapterNum = ChapterNum Int
  deriving (Show, Eq, Read,  Ord, Generic)

newtype SectionNum = SectionNum Int
  deriving (Show, Eq, Read, Ord, Generic)

newtype VerseNum = VerseNum Int
  deriving (Show, Eq, Read, Ord, Generic)

 -- "bookOrder": 1,
 --  "testament": "New",
 --  "chapters": 40,
 --  "book": "Matthew",
 --  "bookID": "ՄատթT1AM1"
data Book = Book
    { book'id          :: Int
    , book'labels      :: [Text]
    , book'book        :: Girq
    , book'title       :: Text
    , book'number      :: Int
    , book'chapters    :: Int
    , book'testament   :: Testament
    , book'translation :: Text
    } deriving (Show, Eq, Generic)

data Chapter = Chapter
    { chapter'id     :: Int
    , chapter'book   :: Girq
    , chapter'number :: Int
    , chapter'title  :: Text
    } deriving (Show, Eq, Generic)


data Section = Section
    { section'id     :: Int
--    , section'book  :: Girq
    , section'number :: Int
    , section'title  :: Text
    } deriving (Show, Eq, Generic)


data Paragraph = Paragraph
    { paragraph'title  :: Text
    , paragraph'number :: Int
    } deriving (Show, Eq, Generic)

data Verse = Verse
    { verse'id            :: Int
    , verse'book          :: Girq
    , verse'chapter       :: Int
    , verse'sectionNumber :: Int
    , verse'sectionTitle  :: Text
    , verse'paragraph     :: Int
    , verse'verse         :: Int
    , verse'content       :: Text
    } deriving (Show, Eq, Generic)


$(deriveJSON dropPrefixOptions ''Chapter)
$(deriveJSON dropPrefixOptions ''Section)
$(deriveJSON dropPrefixOptions ''Paragraph)
$(deriveJSON dropPrefixOptions ''Verse)

-- $(deriveJSON dropPrefixOptions ''Book)
instance ToJSON Book
instance FromJSON Book where
  parseJSON = withObject "book" $ \o -> do
    let book'id = 111 --  <- o .: "bookID"
    book'book  <- o .: "book"
    book'title  <- o .: "bookID"
    book'number       <- o .: "bookOrder"
    book'chapters       <- o .: "chapters"
    book'testament       <- o .: "testament"
    let book'translation = "translation"
    let book'labels = ["Book"]

    return Book{..}


