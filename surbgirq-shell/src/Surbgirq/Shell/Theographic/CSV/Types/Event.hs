{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Event where


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

-- | Evetns

data EventCsv = EventCsv
 {
     event'title             :: String
   , event'startDate         :: String
   , event'duration          :: String
   , event'rangeFlag         :: String
   , event'predecessor       :: String
   , event'lag               :: String
   , event'lagType           :: String
   , event'partOf            :: String
   , event'verses            :: String
   , event'personsFromVerses :: String
   , event'participants      :: String
   , event'placesFromVerses  :: String
   , event'locations         :: String
   , event'groups            :: String
   , event'notes             :: String
   , event'verseSort         :: String
   , event'modified          :: String
   , event'sortKey           :: String
 } deriving (Eq, Show, Generic)

instance FromNamedRecord EventCsv where
  parseNamedRecord m = EventCsv <$>
    m .: "title" <*>
    m .: "startDate" <*>
    m .: "duration" <*>
    m .: "rangeFlag" <*>
    m .: "predecessor" <*>
    m .: "lag" <*>
    m .: "lag Type" <*>
    m .: "partOf" <*>
    m .: "verses" <*>
    m .: "people (from verses)" <*>
    m .: "participants" <*>
    m .: "places (from verses)" <*>
    m .: "locations" <*>
    m .: "groups" <*>
    m .: "notes" <*>
    m .: "verseSort" <*>
    m .: "modified" <*>
    m .: "Sort Key"

instance DefaultOrdered EventCsv
