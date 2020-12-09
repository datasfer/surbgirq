{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}



module Surbgirq.Types.Scripture where

import Data.Aeson                    (Value)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Map.Strict as Map
import qualified Text.Read       as T

import Common.Aeson
import GHC.Generics

import Surbgirq.Types.Girq


class HasId a where
    toId :: a -> Text

class CmdToken a where
    cmdToken :: a -> Text

data TranslationID = E1994T
                   | E2004T
                   | V1805T
                   | SinodalT
                   | KJVT
                 deriving (Eq, Generic, Read)

instance Show TranslationID where
    show t = case t of
               E1994T   -> "e1994-T"
               E2004T   -> "e2004-T"
               V1805T   -> "v1805-T"
               SinodalT -> "sinodal-T"
               KJVT     -> "kjv-T"



instance ToJSON TranslationID
instance FromJSON TranslationID

instance CmdToken TranslationID where
    cmdToken t = case t of
               E1994T   -> "e1994#"
               E2004T   -> "e2004#"
               V1805T   -> "v1805#"
               SinodalT -> "sinodal#"
               KJVT     -> "kjv#"

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
    { verseRef'translation :: Maybe TranslationID
    , verseRef'book        :: Girq
    , verseRef'chapter     :: Int
    , verseRef'from        :: Maybe Int
    , verseRef'to          :: Maybe Int
    } deriving (Read)


instance HasId VerseReference where
    toId VerseReference{..}  =
        case (verseRef'from, verseRef'to) of
          (Nothing, Nothing)   -> [qc|{verseRef'book}_{verseRef'chapter}|]
          (Just from, Nothing) -> [qc|{verseRef'book}_{verseRef'chapter}_{from}|]
          (Just from, Just to) -> [qc|{verseRef'book}_{verseRef'chapter}_{from}_{to}||]
          (Nothing, Just to)   -> [qc|{verseRef'book}_{verseRef'chapter}_{to}|]


$(deriveJSON dropPrefixOptions ''Testament)
$(deriveJSON dropPrefixOptions ''Dialect)
$(deriveJSON dropPrefixOptions ''Language)
$(deriveJSON dropPrefixOptions ''Translation)
-- $(deriveJSON dropPrefixOptions ''Scripture)
