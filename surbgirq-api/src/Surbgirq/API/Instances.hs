{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.API.Instances where

import Data.Text (pack, unpack)

import Data.Bifunctor
import Text.Read

import Surbgirq.Types
import Web.HttpApiData


instance ToHttpApiData Girq where
  toUrlPiece = pack . show

instance FromHttpApiData Girq where
  parseUrlPiece = bimap pack id . readEither . unpack
