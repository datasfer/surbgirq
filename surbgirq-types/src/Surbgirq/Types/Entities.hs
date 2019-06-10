{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Types.Entities (
   Scripture(..)
 , Book(..)
 , Chapter (..)
 , Section(..)
 , Paragraph(..)
 , Verse(..)
 , Testament (..)
 , Ref(..)
 , RefType(..)
 ) where

import Data.Aeson (Value)
import Data.Text  (Text)

import Common.Aeson

import Surbgirq.Types.Girq
-------------------------------------------------------------------------------
--



data Group = Pentateuch
            -- ^ Մովսեսի հնգամատյանը
            | Historical
            -- ^ Պատմական
            | Sermon
            -- ^ Ուսուցողական
            | Prophet
            -- ^ Մարգարեություն
            | Evangelie
            -- ^ Ավետարան
            | OtherBook
              -- ^ Պողոս առաքյալի թղթերը
              -- ^ Թղթեր
              deriving (Show)


-- | Book -> Scripture -> Chapter -> Section -> Paragraph -> Verse -> Words

data Testament = Old
               | New
                 deriving (Show, Read)

data TYear = T1994
           | T1969
           | T1805
           | T1895
             deriving (Show)

data Language = Grabar
              | Ashxarhabar
              deriving (Show, Read)

data RefType = RefBook    Text
             | RefChapter Text
             | RefVerse   Text
             | RefWord    Text
             | RefText    Text
               deriving (Show, Read)

data Chapter = Chapeter
    { chapter'book     :: Book
    , chapter'number   :: Int
    , chapter'title    :: Int
    , chapter'language :: Language
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
  , verse'ref     :: Maybe Ref
  } deriving (Show)


-- word
data Ban = Ban
    { ban'index :: Int
    , ban'word  :: Text
    , ban'ref   :: Ref
    } deriving (Show)

data Ref = Ref
    { ref'index :: Int
    , ref'type  :: RefType
    } deriving (Show, Read)

data Scripture = Scripture
    { scripture'book     :: Book
    , scripture'chapters :: [Chapter]
    } deriving (Show)

-- |
data Book = Book
  { book'book        :: Girq
  , book'title       :: Text
  , book'number      :: Int
  , book'chapters    :: Int
  , book'testament   :: Testament
  , book'translation :: Text
  , book'input       :: Maybe Text
    -- ^ the path to text files to process, if nothing then take the path = toLower  $ show book'book
  , book'output      :: Maybe Text
  -- ^ the path to store processed result
  } deriving (Show)


$(deriveJSON dropPrefixOptions ''Testament)
$(deriveJSON dropPrefixOptions ''Group)
$(deriveJSON dropPrefixOptions ''Book)
$(deriveJSON dropPrefixOptions ''Scripture)
$(deriveJSON dropPrefixOptions ''Chapter)
$(deriveJSON dropPrefixOptions ''Section)
$(deriveJSON dropPrefixOptions ''Paragraph)
$(deriveJSON dropPrefixOptions ''Verse)
$(deriveJSON dropPrefixOptions ''RefType)
$(deriveJSON dropPrefixOptions ''Ref)
$(deriveJSON dropPrefixOptions ''Ban)

$(deriveJSON dropPrefixOptions ''Language)
$(deriveJSON dropPrefixOptions ''TYear)



