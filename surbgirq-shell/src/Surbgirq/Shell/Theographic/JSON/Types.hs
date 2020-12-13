{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
module Surbgirq.Shell.Theographic.JSON.Types where

import Data.Aeson
import GHC.Generics

data TheoBook = TheoBook
    {
      id          :: String
    , fields      :: TheoBookFields
    , createdTime :: String
    } deriving (Show, Read, Generic)


instance FromJSON TheoBook
 --    where
 -- parseJSON (Object v) =
 --    TheoBook <$> v .: "id"
 --             <*> v .: "fields"
 --             <*> v .: "createdTime"


data TheoBookFields = TheoBookFields
    {
      osisName     :: String
    , bookName     :: String
    , bookDiv      :: String
    , shortName    :: String
    , bookOrder    :: Int
    , verses       :: [String]
    , chapters     :: [String]
    , testament    :: String
    , chapterCount :: Int
    , verseCount   :: Int
    , writers      :: [String]
    , slug         :: String
    , peopleCount  :: Int
    , placeCount   :: Int
    } deriving (Show, Read, Generic)

instance FromJSON TheoBookFields



data TheoChapter = TheoChapter
    {
      chapter'id          :: String
    , chapter'fields      :: TheoChapterFields
    , chapter'createdTime :: String
    } deriving (Show, Read, Generic)


data TheoChapterFields = TheoChapterFields
    {
      chapter'osisRef     :: String
    , chapter'book        :: [String]
    , chapter'chapterNum  :: Int
    , chapter'writer      :: [String]
    , chapter'verses      :: [String]
    , chapter'slug        :: String
    , chapter'peopleCount :: Int
    , chapter'placesCount :: Int
    , chapter'modified    :: String
    } deriving (Show, Read, Generic)


instance FromJSON TheoChapter where
 parseJSON (Object v) =
    TheoChapter <$> v .: "id"
                <*> v .: "fields"
                <*> v .: "createdTime"

instance FromJSON TheoChapterFields where
 parseJSON (Object v) =
    TheoChapterFields <$> v .: "osisRef"
                <*> v .: "book"
                <*> v .: "chapterNum"
                <*> v .:? "writer" .!= []
                <*> v .: "verses"
                <*> v .: "slug"
                <*> v .: "peopleCount"
                <*> v .: "placesCount"
                <*> v .: "modified"



data TheoVerse = TheoVerse
    {
      verse'id          :: String
    , verse'fields      :: TheoVerseFields
    , verse'createdTime :: String
    } deriving (Show, Read, Generic)


data TheoVerseFields = TheoVerseFields
    {
      verse'osisRef         :: String
    , verse'verseNum        :: String
    , verse'verseText       :: String
    , verse'book            :: [String]
    , verse'eventsDescribed :: [String]
    , verse'people          :: [String]
    , verse'yearNum         :: Maybe Int
    , verse'chapter         :: [String]
    , verse'status          :: String
    , verse'mdText          :: String
    , verse'richText        :: String
    , verse'verseID         :: String
    , verse'timeline        :: [String]
    , verse'peopleCount     :: Int
    , verse'placesCount     :: Int
    , verse'modified        :: String
    } deriving (Show, Read, Generic)


instance FromJSON TheoVerse where
 parseJSON (Object v) =
    TheoVerse <$> v .: "id"
                <*> v .: "fields"
                <*> v .: "createdTime"

instance FromJSON TheoVerseFields where
 parseJSON (Object v) =
    TheoVerseFields <$> v .: "osisRef"
                <*> v .: "verseNum"
                <*> v .: "verseText"
                <*> v .: "book"
                <*> v .:? "eventsDescribed" .!= []
                <*> v .:? "people" .!= []
                <*> v .:? "yearNum"

                <*> v .: "chapter"
                <*> v .: "status"
                <*> v .: "mdText"
                <*> v .: "richText"
                <*> v .: "verseID"
                <*> v .:? "timeline" .!= []
                <*> v .: "peopleCount"
                <*> v .: "placesCount"
                <*> v .: "modified"




data TheoEaston = TheoEaston
    {
      easton'id          :: String
    , easton'fields      :: TheoEastonFields
    , easton'createdTime :: String
    } deriving (Show, Read, Generic)


data TheoEastonFields = TheoEastonFields
    {
      easton'dictLookup   :: String
    , easton'termID       :: String
    , easton'termLabel    :: String
    , easton'def_id       :: String
    , easton'has_list     :: String
    , easton'itemNum      :: Int
    , easton'matchType    :: String
    , easton'matchSlugs   :: String
    , easton'dictText     :: String
    , easton'personLookup :: [String]
    , easton'index        :: String
    } deriving (Show, Read, Generic)


instance FromJSON TheoEaston where
 parseJSON (Object v) =
    TheoEaston <$> v .: "id"
                <*> v .: "fields"
                <*> v .: "createdTime"

instance FromJSON TheoEastonFields where
 parseJSON (Object v) =
    TheoEastonFields <$> v .: "dictLookup"
                <*> v .: "termID"
                <*> v .: "termLabel"
                <*> v .: "def_id"
                <*> v .: "has_list"
                <*> v .: "itemNum"
                <*> v .: "matchType"

                <*> v .: "matchSlugs"
                <*> v .: "dictText"
                <*> v .:? "personLookup" .!= []
                <*> v .: "index"
