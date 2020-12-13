{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Shell.Theographic.CSV.Types.Place where


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


-- | Place
data PlaceCsv = PlaceCsv
 {
    place'placeLookup      :: String
  , place'status           :: String
  , place'displayTitle     :: String
  , place'ambiguous        :: String
  , place'duplicate_of     :: String
  , place'placeID          :: String
  , place'kjvName          :: String
  , place'esvName          :: String
  , place'recogitoComments :: String
  , place'featureType      :: String
  , place'featureSubType   :: String
  , place'openBibleLat     :: String
  , place'openBibleLong    :: String
  , place'rootID           :: String
  , place'precision        :: String
  , place'aliases          :: String
  , place'comment          :: String
  , place'verses           :: String
  , place'verseCount       :: String
  , place'eastons          :: String
  , place'dictText         :: String
  , place'recogitoUri      :: String
  , place'recogitoLat      :: String
  , place'recogitoLon      :: String
  , place'peopleBorn       :: String
  , place'peopleDied       :: String
  , place'recogitoStatus   :: String
  , place'recogitoType     :: String
  , place'recogitoLabel    :: String
  , place'recogitoUID      :: String
  , place'booksWritten     :: String
  , place'eventsHere       :: String
  , place'eventGroups      :: String
  , place'hasBeenHere      :: String
  , place'latitude         :: String
  , place'longitude        :: String
  , place'alphaGroup       :: String
  , place'slug             :: String
 } deriving (Eq, Show, Generic)

instance FromNamedRecord PlaceCsv where
  parseNamedRecord m = PlaceCsv <$>
    m .: "placeLookup" <*>
    m .: "status" <*>
    m .: "displayTitle" <*>
    m .: "ambiguous" <*>
    m .: "duplicate_of" <*>
    m .: "placeID" <*>
    m .: "kjvName" <*>
    m .: "esvName" <*>
    m .: "recogitoComments" <*>
    m .: "featureType" <*>
    m .: "featureSubType" <*>
    m .: "openBibleLat" <*>
    m .: "openBibleLong" <*>
    m .: "rootID" <*>
    m .: "precision" <*>
    m .: "aliases" <*>
    m .: "comment" <*>
    m .: "verses" <*>
    m .: "verseCount" <*>
    m .: "eastons" <*>
    m .: "dictText" <*>
    m .: "recogitoUri" <*>
    m .: "recogitoLat" <*>
    m .: "recogitoLon" <*>
    m .: "peopleBorn" <*>
    m .: "peopleDied" <*>
    m .: "recogitoStatus" <*>
    m .: "recogitoType" <*>
    m .: "recogitoLabel" <*>
    m .: "recogitoUID" <*>
    m .: "booksWritten" <*>
    m .: "eventsHere" <*>
    m .: "eventGroups" <*>
    m .: "hasBeenHere" <*>
    m .: "latitude" <*>
    m .: "longitude" <*>
    m .: "alphaGroup" <*>
    m .: "slug"

instance DefaultOrdered PlaceCsv

