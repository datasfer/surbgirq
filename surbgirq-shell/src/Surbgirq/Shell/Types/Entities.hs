{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Shell.Types.Entities (
   Scripture(..)
 , Book(..)
 , Chapter (..)
 , Section(..)
 , Paragraph(..)
 , Verse(..)
 , Testament (..)
 , BookRef(..)
 , VerseRef(..)
 , RefType(..)
 ) where

import Data.Aeson (Value)
import Data.Text  (Text)

import Common.Aeson

import Surbgirq.Types.Girq
-------------------------------------------------------------------------------
--


data RefType = RefBooks   [Text]
             | RefChapter Text
             | RefVerse   Text
             | RefWord    Text
             | RefText    Text
               deriving (Show, Read)
-- |
data Book = Book
  { book'book        :: Girq
  , book'labels      :: Maybe Text
  -- ^ neo4j node labels
  , book'title       :: Text
  , book'number      :: Int
  , book'chapters    :: Int
  , book'testament   :: Testament
  , book'translation :: Text
  , book'language    :: Language
  , book'dialect     :: Dialect
  , book'input       :: Maybe Text
    -- ^ the path to text files to process, if nothing then take the path = toLower  $ show book'book
  , book'output      :: Maybe Text
  -- ^ the path to store processed result
  } deriving (Show)

data Chapter = Chapeter
    { chapter'number   :: Int
    , chapter'title    :: Text
    , chapter'sections :: [Section]
    } deriving (Show)


data Section = Section
    { section'title      :: Text
    , section'number     :: Int
    , section'paragraphs :: [Paragraph]
    } deriving (Show)


data Paragraph = Paragraph
    { paragraph'number :: Int
    , paragraph'verses :: [Verse]
    } deriving (Show)


data Verse = Verse
  { verse'verse   :: Int
  , verse'content :: Text
--   , verse'grabar    :: Text
  , verse'ref     :: Maybe VerseRef
  } deriving (Show)


-- word
data Ban = Ban
    { ban'index :: Int
    , ban'word  :: Text
    , ban'ref   :: VerseRef
    } deriving (Show)

data VerseRef = VerseRef
    { verseRef'index :: Int
    , verseRef'type  :: RefType
    } deriving (Show, Read)


data BookRef =  BookRef
    {
      bookRef'book :: Book
    , bookRef'ref  :: RefType
    }

data Scripture = Scripture
    { scripture'book     :: Book
    , scripture'chapters :: [Chapter]
    } deriving (Show)



$(deriveJSON dropPrefixOptions ''Book)
$(deriveJSON dropPrefixOptions ''Scripture)
$(deriveJSON dropPrefixOptions ''Chapter)
$(deriveJSON dropPrefixOptions ''Section)
$(deriveJSON dropPrefixOptions ''Paragraph)
$(deriveJSON dropPrefixOptions ''Verse)
$(deriveJSON dropPrefixOptions ''RefType)
$(deriveJSON dropPrefixOptions ''VerseRef)
$(deriveJSON dropPrefixOptions ''BookRef)
$(deriveJSON dropPrefixOptions ''Ban)




