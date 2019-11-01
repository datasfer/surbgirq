{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}

{-|
Module      : Surbgirq.API.Types
Description : REST API types

Types to wrap REST API request/response
-}

module Surbgirq.API.Types (
  GetApiInfoResponse(..)
 ) where

import Data.Default

import Common.Aeson
import Data.Text    (Text)
import GHC.Generics
import GHC.Int      (Int64)

import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

newtype GetApiInfoResponse = GetApiInfoResponse
  { apiInfoResponse'apiInfo   :: ApiInfo
  } deriving (Show, Generic)



$(deriveJSON dropPrefixOptions ''GetApiInfoResponse)
