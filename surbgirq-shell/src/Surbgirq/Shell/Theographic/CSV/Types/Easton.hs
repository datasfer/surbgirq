{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Easton where


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


-- | Easton's Bible Dictionary
data EastonCsv = EastonCsv
 {
   easton'dictLookup   :: String
 , easton'index        :: String
 , easton'termID       :: String
 , easton'termLabel    :: String
 , easton'dictText     :: String
 , easton'itemNum      :: String
 , easton'matchType    :: String
 , easton'matchSlugs   :: String
 , easton'personLookup :: String
 , easton'placeLookup  :: String
 } deriving (Eq, Show, Generic)

instance FromNamedRecord EastonCsv where
  parseNamedRecord m = EastonCsv <$>
    m .: "dictLookup" <*>
    m .: "index" <*>
    m .: "termID" <*>
    m .: "termLabel" <*>
    m .: "dictText" <*>
    m .: "itemNum" <*>
    m .: "matchType" <*>
    m .: "matchSlugs" <*>
    m .: "personLookup" <*>
    m .: "placeLookup"

instance DefaultOrdered EastonCsv

