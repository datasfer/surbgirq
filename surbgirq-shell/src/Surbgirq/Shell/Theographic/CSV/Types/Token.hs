{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Token where


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



-- | Tokens
data WordCsv = WordCsv
 {
   word'BookID     :: String
 , word'Chapter    :: String
 , word'ParaID     :: String
 , word'SentID     :: String
 , word'VerseID    :: String
 , word'VerseNum   :: String
 , word'VersePos   :: String
 , word'WordID     :: String
 , word'Word       :: String
 , word'Punc       :: String
 , word'Italic     :: String
 , word'cParen     :: String
 , word'oParen     :: String
 , word'PlaceID    :: String
 , word'Syllables  :: String
 , word'YearNum    :: String
 , word'PersonID   :: String
 , word'RunCharLen :: String
 } deriving (Eq, Show, Generic)



instance FromNamedRecord WordCsv where
  parseNamedRecord m = WordCsv <$>
    m .: "BookID" <*>
    m .: "Chapter" <*>
    m .: "ParaID" <*>
    m .: "SentID" <*>
    m .: "VerseID" <*>
    m .: "VerseNum" <*>
    m .: "VersePos" <*>
    m .: "WordID" <*>
    m .: "Word" <*>
    m .: "Punc" <*>
    m .: "Italic" <*>
    m .: "cParen" <*>
    m .: "oParen" <*>
    m .: "PlaceID" <*>
    m .: "Syllables" <*>
    m .: "YearNum" <*>
    m .: "PersonID" <*>
    m .: "RunCharLen"


instance DefaultOrdered WordCsv
