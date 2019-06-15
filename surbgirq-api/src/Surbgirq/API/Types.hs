{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}

module Surbgirq.API.Types where

import Data.Default

import Common.Aeson
import Data.Text    (Text)
import GHC.Generics
import GHC.Int      (Int64)

import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

data GetApiInfoResponse = GetApiInfoResponse
  { apiInfoResponse'apiInfo   :: ApiInfo
  } deriving (Show, Generic)



$(deriveJSON dropPrefixOptions ''GetApiInfoResponse)
