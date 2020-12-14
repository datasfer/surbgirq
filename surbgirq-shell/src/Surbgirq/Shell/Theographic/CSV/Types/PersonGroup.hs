{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.PersonGroup where


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



-- | Event group
data EventGroupCsv = EventGroupCsv
 {
    eventGroup'groupName  :: String
  , eventGroup'members    :: String
  , eventGroup'partOf     :: String
  , eventGroup'verses     :: String
  , eventGroup'events     :: String
  , eventGroup'modified   :: String
  , eventGroup'events_dev :: String
 } deriving (Eq, Show, Generic)

instance FromNamedRecord EventGroupCsv where
  parseNamedRecord m = EventGroupCsv <$>
    m .: "groupName" <*>
    m .: "members" <*>
    m .: "partOf" <*>
    m .: "verses" <*>
    m .: "events" <*>
    m .: "modified" <*>
    m .: "events_dev"

instance DefaultOrdered EventGroupCsv

