{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Theographic.CsvTypes where


import GHC.Generics

import Data.Text (Text)

-- cassava
import           Data.ByteString   (ByteString)
import           Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , Header
    , NamedRecord
    , Parser
    , ToField(toField)
    , ToNamedRecord(toNamedRecord)
    , record
    , (.:)
    , (.=)
    )
import qualified Data.Csv          as Cassava
import qualified Data.HashMap.Lazy as HM
-- import Network.URI (parseURI, URI)
import Data.List.Split



data BookCsv = BookCsv
    {
      osisName     :: String
    , bookOrder    :: Int
    , bookName     :: String
    , bookDiv      :: String
    , testament    :: TestamentType
    , shortName    :: String
    , slug         :: String
    , yearWritten  :: Maybe String
    , placeWritten :: Maybe String
    , chapters     :: String
    , chapterCount :: Int
    , verseCount   :: Int
    , writers      :: String
    , peopleCount  :: Int
    , placeCount   :: Int
    , modified     :: String
    } deriving (Eq, Show, Generic)

instance DefaultOrdered BookCsv

data ChapterCsv = ChapterCsv
 {
   chapter'osisRef     :: String
 , chapter'book        :: String
 , chapter'chapterNum  :: String
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


data VerseCsv = VerseCsv
    {
      verse'osisRef         :: String
    , verse'status          :: String
    , verse'verseID         :: String
    , verse'book            :: String
    , verse'chapter         :: String
    , verse'verseNum        :: String
    , verse'verseText       :: String
    , verse'richText        :: String
    , verse'mdText          :: String
    , verse'people          :: String
    , verse'peopleCount     :: String
    , verse'places          :: String
    , verse'placesCount     :: String
    , verse'yearNum         :: String
    , verse'peopleGroups    :: String
    , verse'eventsDescribed :: String
    , verse'timeline        :: String
    , verse'modified        :: String
    } deriving (Show, Read, Generic)

instance DefaultOrdered VerseCsv

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

data TestamentType
  = NewTestament
  | OldTestament
  | Other Text
   deriving (Eq, Show)

instance FromField TestamentType where
  parseField s | s == "Old Testament" = pure OldTestament
               | s == "New Testament" = pure NewTestament
               | otherwise = Other <$> parseField s

instance FromNamedRecord BookCsv where
  parseNamedRecord m = BookCsv <$>
    m .: "osisName" <*>
    m .: "bookOrder" <*>
    m .: "bookName" <*>
    m .: "bookDiv" <*>
    m .: "testament" <*>
    m .: "shortName" <*>
    m .: "slug" <*>
    m .:? "yearWritten" <*>
    m .:? "placeWritten" <*>
    m .: "chapters" <*>
    m .: "chapterCount" <*>
    m .: "verseCount" <*>
    m .: "writers" <*>
    m .: "peopleCount" <*>
    m .: "placeCount" <*>
    m .: "modified"



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



(.:?) :: FromField a => NamedRecord -> ByteString -> Parser (Maybe a)
(.:?) m name = maybe (pure Nothing) parseField $ HM.lookup name m

-- instance FromField URI where
--   parseField f = parseField f >>= maybe (fail "invalid URL") pure . parseURI

-- instance FromField Date where
--   parseField x = parseField x >>= f where
--     f (splitAt 4 -> (ys, splitAt 2 -> (ms, ds)))
--       | length ds == 2
--       , Just [y,m,d] <- mapM readMay [ys,ms,ds]
--       = pure $ Date y m d
--     f d = fail $ "invalid date: " ++ d

-- instance FromField Time where
--   parseField x = parseField x >>= f where
--     f (mapM readMay . splitOn ":" -> Just [h,m,s])
--       = pure $ Time h m s
--     f s = fail $ "invalid time: " ++ s



enumParseField :: forall a. (Enum a, Bounded a) => ByteString -> Parser a
enumParseField xs = parseField xs >>= conv where
  mx = fromEnum (maxBound :: a)
  conv n
    | n > mx    = fail ("out of range: " ++ show n)
    | otherwise = pure (toEnum n)

-- instance FromField LocationType  where parseField = enumParseField


