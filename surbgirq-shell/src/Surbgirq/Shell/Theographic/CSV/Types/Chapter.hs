{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Chapter where


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

-- | Chapter
data ChapterCsv = ChapterCsv
 {
   chapter'osisRef     :: String
 , chapter'book        :: String
 , chapter'chapterNum  :: Int
 , chapter'writer      :: String
 , chapter'verses      :: String
 , chapter'slug        :: String
 , chapter'peopleCount :: Int
 , chapter'placesCount :: Int
 , chapter'modified    :: String
    } deriving (Eq, Show, Generic)



instance FromNamedRecord ChapterCsv where
  parseNamedRecord m = ChapterCsv <$>
    m .: "osisRef" <*>
    m .: "book" <*>
    m .: "chapterNum" <*>
    m .: "writer" <*>
    m .: "verses" <*>
    m .: "slug" <*>
    m .: "peopleCount" <*>
    m .: "placesCount" <*>
    m .: "modified"

instance DefaultOrdered ChapterCsv
