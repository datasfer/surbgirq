{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Person where


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



-- | Person
instance DefaultOrdered PersonCsv

data PersonCsv = PersonCsv
    {
      person'personLookup           :: String
    , person'status                 :: String
    , person'personID               :: String
    , person'displayTitle           :: String
    , person'name                   :: String
    , person'surname                :: String
    , person'alsoCalled             :: String
    , person'isProperName           :: String
    , person'ambiguous              :: String
    , person'Disambiguation         :: String
    , person'gender                 :: String
    , person'occupations            :: String
    , person'birthYear              :: String
    , person'minYear                :: String
    , person'deathYear              :: String
    , person'maxYear                :: String
    , person'birthPlace             :: String
    , person'deathPlace             :: String
    , person'memberOf               :: String
    , person'eastons                :: String
    , person'dictText               :: String
    , person'events                 :: String
    , person'eventGroups            :: String
    , person'verseCount             :: Int
    , person'verses                 :: String
    , person'mother                 :: String
    , person'father                 :: String
    , person'partners               :: String
    , person'children               :: String
    , person'siblings               :: String
    , person'halfSiblingsSameFather :: String
    , person'halfSiblingsSameMother :: String
    , person'chaptersWritten        :: String
    , person'alphaGroup             :: String
    , person'slug                   :: String
    , person'modified               :: String
    } deriving (Show, Read, Generic)


instance FromNamedRecord PersonCsv where
  parseNamedRecord m = PersonCsv <$>
    m .: "personLookup" <*>
    m .: "status" <*>
    m .: "personID" <*>
    m .: "displayTitle" <*>
    m .: "name" <*>
    m .: "surname" <*>
    m .: "alsoCalled" <*>
    m .: "isProperName" <*>
    m .: "ambiguous" <*>
    m .: "Disambiguation (temp)" <*>
    m .: "gender" <*>
    m .: "occupations" <*>
    m .: "birthYear" <*>
    m .: "minYear" <*>
    m .: "deathYear" <*>
    m .: "maxYear" <*>
    m .: "birthPlace" <*>
    m .: "deathPlace" <*>
    m .: "memberOf" <*>
    m .: "eastons" <*>
    m .: "dictText" <*>
    m .: "events" <*>
    m .: "eventGroups" <*>
    m .: "verseCount" <*>
    m .: "verses" <*>
    m .: "mother" <*>
    m .: "father" <*>
    m .: "partners" <*>
    m .: "children" <*>
    m .: "siblings" <*>
    m .: "halfSiblingsSameMother" <*>
    m .: "halfSiblingsSameFather" <*>
    m .: "chaptersWritten" <*>
    m .: "alphaGroup" <*>
    m .: "slug" <*>
    m .: "modified"
