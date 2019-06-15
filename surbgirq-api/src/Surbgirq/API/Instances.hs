{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.API.Instances where

import Data.Bifunctor
import Text.Read

import Data.Char (toUpper)
import Data.Text (pack, unpack)

import Surbgirq.Types
import Web.HttpApiData


instance ToHttpApiData Girq where
  toUrlPiece = pack . show

instance FromHttpApiData Girq where
  parseUrlPiece = bimap pack id . readEither . capitalized . unpack


instance ToHttpApiData ChapterNum where
  toUrlPiece (ChapterNum n) = toUrlPiece n
  {-# INLINE toUrlPiece #-}

instance FromHttpApiData ChapterNum where
  parseUrlPiece = fmap ChapterNum . parseUrlPiece
  {-# INLINE parseUrlPiece #-}

-- | will parse matthew as well
capitalized :: String -> String
capitalized (head:tail) = toUpper head : tail
capitalized []          = []
