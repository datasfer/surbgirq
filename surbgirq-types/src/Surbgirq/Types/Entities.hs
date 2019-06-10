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
  , verse'ref     :: Text
  } deriving (Show)

data Ban = Ban
    { word'number  :: Int
    , word'content :: Text
    , word'ref     :: Footnote
    } deriving (Show)

data Footnote = Footnote
    { footnote'number :: Int
    , footnote'text   :: Text
    } deriving (Show)

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
$(deriveJSON dropPrefixOptions ''Footnote)
$(deriveJSON dropPrefixOptions ''Ban)

$(deriveJSON dropPrefixOptions ''Language)
$(deriveJSON dropPrefixOptions ''TYear)



{-
books :: [Book]
books  = [ Book Genesis 1 50 Old ""
         , Book Exodus  2 40 Old ""
         , Book Leviticus 3 27 Old "leviticus"
         , Book Numbers 4 36 Old "numbers"
         , Book Deuteronomy 5 34 Old ""
         , Book Joshua 6 24 Old ""
         , Book Judges 7 21 Old ""
         , Book Ruth 8 4 Old ""
         , Book Kings1 11 22 Old ""
         , Book Kings2 12 25 Old ""
         , Book Kings3 11 22 Old ""
         , Book Kings4 12 25 Old ""
         , Book Chronicles1 13 29 Old ""
         , Book Chronicles2 14 36 Old ""
         , Book Ezra1 15 10 Old ""
         , Book Ezra2 15 10 Old ""
         , Book Nehemiah 16 13 Old ""
         , Book Esther 17 10 Old ""
         , Book Job  18 42 Old ""
         , Book Psalms 19 150 Old ""
         , Book Proverbs 20 31 Old ""
         , Book Ecclesiastes 21 12 Old ""
         , Book SongofSolomon 22 8 Old ""
         , Book Isaiah 23 66 Old ""
         , Book Jeremiah 24 52 Old ""
         , Book Lamentations 25 5 Old ""
         , Book Ezekiel 26 48 Old ""
         , Book Daniel 27 12 Old ""
         , Book Hosea 28 14 Old ""
         , Book Joel 29 3 Old ""
         , Book Amos 30 9 Old ""
         , Book Obadiah 31 1 Old ""
         , Book Jonah 32 4 Old ""
         , Book Micah 33 7 Old ""
         , Book Nahum 34 3 Old ""
         , Book Habakkuk 35 3 Old ""
         , Book Zephaniah 36 3 Old ""
         , Book Haggai 37 2 Old ""
         , Book Zechariah 38 14 Old ""
         , Book Malachi 39 4 Old ""
         , Book Matthew 40 28 New ""
         , Book Mark 41 16 New ""
         , Book Luke 42 24 New ""
         , Book John 43 21 New ""
         ]
-}

{-
  "Acts": {
    "number": 44,
    "id": 44000000,
    "chapters": 28,
    "testament": "new",
    "url": "acts"
  },
  "Romans": {
    "number": 45,
    "id": 45000000,
    "chapters": 16,
    "testament": "new",
    "url": "romans"
  },
  "1 Corinthians": {
    "number": 46,
    "id": 46000000,
    "chapters": 16,
    "testament": "new",
    "url": "1corinthians"
  },
  "2 Corinthians": {
    "number": 47,
    "id": 47000000,
    "chapters": 13,
    "testament": "new",
    "url": "2corinthians"
  },
  "Galatians": {
    "number": 48,
    "id": 48000000,
    "chapters": 6,
    "testament": "new",
    "url": "galatians"
  },
  "Ephesians": {
    "number": 49,
    "id": 49000000,
    "chapters": 6,
    "testament": "new",
    "url": "ephesians"
  },
  "Philippians": {
    "number": 50,
    "id": 50000000,
    "chapters": 4,
    "testament": "new",
    "url": "philippians"
  },
  "Colossians": {
    "number": 51,
    "id": 51000000,
    "chapters": 4,
    "testament": "new",
    "url": "colossians"
  },
  "1 Thessalonians": {
    "number": 52,
    "id": 52000000,
    "chapters": 5,
    "testament": "new",
    "url": "1thessalonians"
  },
  "2 Thessalonians": {
    "number": 53,
    "id": 53000000,
    "chapters": 3,
    "testament": "new",
    "url": "2thessalonians"
  },
  "1 Timothy": {
    "number": 54,
    "id": 54000000,
    "chapters": 6,
    "testament": "new",
    "url": "1timothy"
  },
  "2 Timothy": {
    "number": 55,
    "id": 55000000,
    "chapters": 4,
    "testament": "new",
    "url": "2timothy"
  },
  "Titus": {
    "number": 56,
    "id": 56000000,
    "chapters": 3,
    "testament": "new",
    "url": "titus"
  },
  "Philemon": {
    "number": 57,
    "id": 57000000,
    "chapters": 1,
    "testament": "new",
    "url": "philemon"
  },
  "Hebrews": {
    "number": 58,
    "id": 58000000,
    "chapters": 13,
    "testament": "new",
    "url": "hebrews"
  },
  "James": {
    "number": 59,
    "id": 59000000,
    "chapters": 5,
    "testament": "new",
    "url": "james"
  },
  "1 Peter": {
    "number": 60,
    "id": 60000000,
    "chapters": 5,
    "testament": "new",
    "url": "1peter"
  },
  "2 Peter": {
    "number": 61,
    "id": 61000000,
    "chapters": 3,
    "testament": "new",
    "url": "2peter"
  },
  "1 John": {
    "number": 62,
    "id": 62000000,
    "chapters": 5,
    "testament": "new",
    "url": "1john"
  },
  "2 John": {
    "number": 63,
    "id": 63000000,
    "chapters": 1,
    "testament": "new",
    "url": "2john"
  },
  "3 John": {
    "number": 64,
    "id": 64000000,
    "chapters": 1,
    "testament": "new",
    "url": "3john"
  },
  "Jude": {
    "number": 65,
    "id": 65000000,
    "chapters": 1,
    "testament": "new",
    "url": "jude"
  },
  "Revelation": {
    "number": 66,
    "id": 66000000,
    "chapters": 22,
    "testament": "new",
    "url": "revelation"
  }
}
-}
