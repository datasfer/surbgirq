{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}



module Surbgirq.Types.Scripture where

import Data.Aeson                    (Value)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import qualified Text.Read as T

import Common.Aeson
import GHC.Generics

import Surbgirq.Types.Girq



class HasId a where
    toId :: a -> Text

data Testament = Old
               | New
                 deriving (Show, Eq,  Read, Generic)

data Dialect = Grabar
             | Ashxarhabar
              deriving (Show, Eq, Read, Generic)

data Language = AM
              | RU
              | EN
                deriving (Show, Eq, Read, Generic)

type ScriptureID = String

data Translation = Translation
    { translation'ID          :: Text
    , translation'name        :: Text
    , translation'version     :: Text
    , translation'description :: Text
    , translation'language    :: Text
    , translation'from        :: Maybe ScriptureID
    , translation'year        :: Maybe Int
    , translation'dialect     :: Maybe Dialect
    , translation'lang        :: Language
    , translation'translators :: [Text]
    } deriving (Show, Read)


data VerseReference = VerseReference
    { verseRef'book    :: Girq
    , verseRef'chapter :: Int
    , verseRef'from    :: Int
    , verseRef'to      :: Maybe Int
    } deriving (Read)

instance Show VerseReference where
    show VerseReference{..}  =
        case verseRef'to of
          Nothing -> [qc|{verseRef'book} {verseRef'chapter}:{verseRef'from}|]
          Just to -> [qc|{verseRef'book} {verseRef'chapter}.{verseRef'from}-{to}|]

instance HasId VerseReference where
    toId VerseReference{..}  =
        case verseRef'to of
          Nothing -> [qc|{verseRef'book}_{verseRef'chapter}_{verseRef'from}|]
          Just to -> [qc|{verseRef'book}_{verseRef'chapter}.{verseRef'from}_{to}|]

$(deriveJSON dropPrefixOptions ''Testament)
$(deriveJSON dropPrefixOptions ''Dialect)
$(deriveJSON dropPrefixOptions ''Language)
$(deriveJSON dropPrefixOptions ''Translation)
-- $(deriveJSON dropPrefixOptions ''Scripture)
