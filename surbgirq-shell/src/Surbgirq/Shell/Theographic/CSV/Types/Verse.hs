{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Verse where


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

-- | Verses
data VerseCsv = VerseCsv
    {
      verse'osisRef         :: String
    , verse'status          :: String
    , verse'verseID         :: String
    , verse'book            :: String
    , verse'chapter         :: String
    , verse'verseNum        :: Int
    , verse'verseText       :: String
    , verse'richText        :: String
    , verse'mdText          :: String
    , verse'people          :: String
    , verse'peopleCount     :: Int
    , verse'places          :: String
    , verse'placesCount     :: Int
    , verse'yearNum         :: String
    , verse'peopleGroups    :: String
    , verse'eventsDescribed :: String
    , verse'timeline        :: String
    , verse'modified        :: String
    } deriving (Show, Read, Generic)


instance FromNamedRecord VerseCsv where
  parseNamedRecord m = VerseCsv <$>
    m .: "osisRef" <*>
    m .: "status" <*>
    m .: "verseID" <*>
    m .: "book" <*>
    m .: "chapter" <*>
    m .: "verseNum" <*>
    m .: "verseText" <*>
    m .: "richText" <*>
    m .: "mdText" <*>
    m .: "people" <*>
    m .: "peopleCount" <*>
    m .: "places" <*>
    m .: "placesCount" <*>
    m .: "yearNum" <*>
    m .: "peopleGroups" <*>
    m .: "eventsDescribed" <*>
    m .: "timeline" <*>
    m .: "modified"


instance DefaultOrdered VerseCsv
