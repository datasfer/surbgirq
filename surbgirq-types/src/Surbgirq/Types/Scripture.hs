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

class HasOffset a where
    toOffset :: Int -> a -> (a, Maybe Text)

class CmdToken a where
    toCmd :: a -> Text

data TranslationID = E1994T
                   | AR94T
                   | E2004T
                   | V1805T
                   | Z1805T
                   | SinodalT
                   | KJVT
                   | Narek_Grabar
                   | Narek_Xer
                   | Narek_Gev
                   | Narek_Goch
                 deriving (Eq, Generic, Read, Enum, Bounded)

instance Show TranslationID where
    show t = case t of
               E1994T       -> "e1994-T"
               AR94T        -> "ar94-T"
               E2004T       -> "e2004-T"
               V1805T       -> "v1805-T"
               Z1805T       -> "z1805-T"
               SinodalT     -> "sinodal-T"
               KJVT         -> "kjv-T"
               Narek_Grabar -> "narekaci-T"
               Narek_Xer    -> "narek_xer-T"
               Narek_Gev    -> "narek_gev-T"
               Narek_Goch   -> "narek_goch-T"


instance ToJSON TranslationID
instance FromJSON TranslationID

instance CmdToken TranslationID where
    toCmd t = case t of
               E1994T       -> "e1994#"
               AR94T        -> "ar94#"
               E2004T       -> "e2004#"
               V1805T       -> "v1805#"
               Z1805T       -> "z1805#"
               SinodalT     -> "sinodal#"
               KJVT         -> "kjv#"
               Narek_Grabar -> "narek_grabar#"
               Narek_Xer    -> "narek_xer#"
               Narek_Gev    -> "narek_gev#"
               Narek_Goch   -> "narek_goch#"

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


data BibleDivision = BibleDivision
    { bibleDivision'ID   :: Text
    , bibleDivision'name :: Text
    } deriving (Show, Read)


data VerseReference = VerseReference
    { verseRef'translation :: Maybe TranslationID
    , verseRef'book        :: Girq
    , verseRef'chapter     :: Int
    , verseRef'from        :: Maybe Int
    , verseRef'to          :: Maybe Int
    , verseRef'combine     :: Bool
    -- ^ combine resutl to one record from till to verses
    } deriving (Read, Show)


instance HasId VerseReference where
    toId VerseReference{..}  =
        case (verseRef'from, verseRef'to) of
          (Nothing, Nothing)   -> [qc|{verseRef'book}_{verseRef'chapter}|]
          (Just from, Nothing) -> [qc|{verseRef'book}_{verseRef'chapter}_{from}|]
          (Just from, Just to) -> [qc|{verseRef'book}_{verseRef'chapter}_{from}_{to}|]
          (Nothing, Just to)   -> [qc|{verseRef'book}_{verseRef'chapter}_{to}|]


instance HasOffset VerseReference where
    toOffset pageSize verRef@(VerseReference tr girq ch (Just from) (Just to) False) =
        if (to - from > pageSize)
        then ( verRef { verseRef'to = Just $ from + pageSize - 1 },
               Just [qc|{girq} {ch} {from + 50} {to}|])
        else  (verRef, Nothing)

    -- if from is nothing lets consider from 1, and to is big number 2000, later will get from cache real number
    toOffset pageSize verRef@(VerseReference tr girq ch Nothing Nothing False) =
        (verRef { verseRef'to = Just $ 1 + pageSize - 1 }, Just [qc|{girq} {ch} {51} {2000}|])

    -- TODO: get max verse number for each chapter
    toOffset _ verRef =  (verRef, Nothing)

$(deriveJSON dropPrefixOptions ''Testament)
$(deriveJSON dropPrefixOptions ''Dialect)
$(deriveJSON dropPrefixOptions ''Language)
$(deriveJSON dropPrefixOptions ''Translation)
-- $(deriveJSON dropPrefixOptions ''Scripture)
