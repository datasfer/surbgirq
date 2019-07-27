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
 , RefTo(..)
 , Ref(..)
 ) where

import Data.Aeson (Value)
import Data.Text  (Text)

import Common.Aeson

import Surbgirq.Types.Girq
-------------------------------------------------------------------------------
--



data RefTo = YouTube Text
           | ScriptureSource Text
           | Meknutyun Text
             deriving (Show, Read)



data RefType = RefBooks   [Text]
             | RefChapter Int
             | RefSection Int Int
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
  , book'ref         :: Maybe Text
  , book'input       :: Maybe Text
    -- ^ the path to text files to process, if nothing then take the path = toLower  $ show book'book
  , book'inputRef    :: Maybe Text
  -- ^ the ref file
  , book'output      :: Maybe Text
  -- ^ the path to store processed result
  } deriving (Show)

data Chapter = Chapeter
    { chapter'number   :: Int
    , chapter'title    :: Text
    , chapter'ref      :: Text
    , chapter'sections :: [Section]
    } deriving (Show)


data Section = Section
    { section'title      :: Text
    , section'number     :: Int
    , section'ref        :: Text
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


data BookRef =  BookRef {  bookRef'ref  :: [Ref] }
                deriving (Show, Read)

data Scripture = Scripture
    { scripture'book     :: Book
    , scripture'chapters :: [Chapter]
    } deriving (Show)

data Ref = Ref
    { ref'From :: RefType
    , ref'To   :: [RefTo]
    } deriving (Show, Read)


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
$(deriveJSON dropPrefixOptions ''Ref)
$(deriveJSON dropPrefixOptions ''RefTo)




