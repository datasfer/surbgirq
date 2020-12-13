{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Period where


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


data PeriodCsv = PeriodCsv
 {
   period'yearNum       :: String
 , period'formattedYear :: String
 , period'era           :: String
 , period'isoYear       :: String
 , period'BC_AD         :: String
 , period'peopleBorn    :: String
 , period'peopleDied    :: String
 , period'events        :: String
 , period'booksWritten  :: String
 , period'modified      :: String
    } deriving (Eq, Show, Generic)



instance FromNamedRecord PeriodCsv where
  parseNamedRecord m = PeriodCsv <$>
    m .: "yearNum" <*>
    m .: "formattedYear" <*>
    m .: "era" <*>
    m .: "isoYear" <*>
    m .: "BC-AD" <*>
    m .: "peopleBorn" <*>
    m .: "peopleDied" <*>
    m .: "events" <*>
    m .: "booksWritten" <*>
    m .: "modified"

instance DefaultOrdered PeriodCsv


