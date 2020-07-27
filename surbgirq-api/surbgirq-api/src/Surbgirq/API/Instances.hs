{-|
Module      : Surbgirq.API.Instances
Description : Instances for http url

Instances for parse and convert to url
-}

module Surbgirq.API.Instances() where

import Data.Bifunctor
import Text.Read

import Data.Char (toLower, toUpper)
import Data.Text (pack, unpack)

import Surbgirq.Types
import Web.HttpApiData


instance ToHttpApiData Girq where
  toUrlPiece = pack . capitalized .show

instance ToHttpApiData Dialect where
  toUrlPiece = pack . capitalized . show

instance FromHttpApiData Girq where
  parseUrlPiece = bimap pack id . readEither . capitalized . unpack


instance ToHttpApiData ChapterNum where
  toUrlPiece (ChapterNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData ChapterNum where
  parseUrlPiece = fmap ChapterNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}

instance ToHttpApiData SectionNum where
  toUrlPiece (SectionNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData SectionNum where
  parseUrlPiece = fmap SectionNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}


instance ToHttpApiData VerseNum where
  toUrlPiece (VerseNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData VerseNum where
  parseUrlPiece = fmap VerseNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}


-- | Make first letter upper case
-- will parse matthew as well
capitalized :: String -> String
capitalized []          = []
capitalized (head:tail) = toUpper head : tail

-- | Make first letter lower case
lowerized :: String -> String
lowerized []          = []
lowerized (head:tail) = toLower head : tail
