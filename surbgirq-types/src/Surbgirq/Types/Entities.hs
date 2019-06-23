{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


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

import Surbgirq.Types.Girq



newtype ChapterNum = ChapterNum Int
  deriving (Show, Eq, Ord, Generic)

newtype SectionNum = SectionNum Int
  deriving (Show, Eq, Ord, Generic)

newtype VerseNum = VerseNum Int
  deriving (Show, Eq, Ord, Generic)


data Book = Book
    { book'id          :: Int
    , book'labels      :: [Text]
    , book'book        :: Girq
    , book'title       :: Text
    , book'number      :: Int
    , book'chapters    :: Int
    , book'testament   :: Testament
    , book'translation :: Text
    } deriving (Show, Generic)

data Chapter = Chapter
    { chapter'id     :: Int
    , chapter'book   :: Girq
    , chapter'number :: Int
    , chapter'title  :: Text
    } deriving (Show, Generic)


data Section = Section
    { section'id     :: Int
--    , section'book  :: Girq
    , section'number :: Int
    , section'title  :: Text
    } deriving (Show, Generic)


data Paragraph = Paragraph
    { paragraph'title  :: Text
    , paragraph'number :: Int
    } deriving (Show, Generic)

data Verse = Verse
    { verse'id            :: Int
    , verse'book          :: Girq
    , verse'chapter       :: Int
    , verse'sectionNumber :: Int
    , verse'sectionTitle  :: Text
    , verse'paragraph     :: Int
    , verse'verse         :: Int
    , verse'content       :: Text
    } deriving (Show, Generic)

$(deriveJSON dropPrefixOptions ''Book)
$(deriveJSON dropPrefixOptions ''Chapter)
$(deriveJSON dropPrefixOptions ''Section)
$(deriveJSON dropPrefixOptions ''Paragraph)
$(deriveJSON dropPrefixOptions ''Verse)

