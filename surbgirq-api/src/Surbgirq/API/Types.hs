{-# LANGUAGE TemplateHaskell #-}
module Surbgirq.API.Types where

import Data.Default

import Data.Text (Text)
import GHC.Int   (Int64)

import Common.Aeson

import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

data GetApiInfoResponse = GetApiInfoResponse
  { apiInfoResponse'apiInfo   :: ApiInfo
  } deriving (Show)



$(deriveJSON dropPrefixOptions ''GetApiInfoResponse)
