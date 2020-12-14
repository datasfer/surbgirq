{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Book where


import GHC.Generics

import Data.Text (Text)

-- cassava
import Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , (.:)
    , (.=)
    )

import Surbgirq.Shell.Theographic.CSV.Types.Helpers
import Surbgirq.Shell.Theographic.CSV.Types.Testament

-- | Book
data BookCsv = BookCsv
    {
      osisName     :: String
    , bookOrder    :: Int
    , bookName     :: String
    , bookDiv      :: String
    , testament    :: Testament
    , shortName    :: String
    , slug         :: String
    , yearWritten  :: Maybe String
    , placeWritten :: Maybe String
    , chapters     :: String
    , chapterCount :: Int
    , verseCount   :: Int
    , writers      :: String
    , peopleCount  :: Int
    , placeCount   :: Int
    , modified     :: String
    } deriving (Eq, Show, Generic)

instance DefaultOrdered BookCsv





instance FromNamedRecord BookCsv where
  parseNamedRecord m = BookCsv <$>
    m .: "osisName" <*>
    m .: "bookOrder" <*>
    m .: "bookName" <*>
    m .: "bookDiv" <*>
    m .: "testament" <*>
    m .: "shortName" <*>
    m .: "slug" <*>
    m .:? "yearWritten" <*>
    m .:? "placeWritten" <*>
    m .: "chapters" <*>
    m .: "chapterCount" <*>
    m .: "verseCount" <*>
    m .: "writers" <*>
    m .: "peopleCount" <*>
    m .: "placeCount" <*>
    m .: "modified"
