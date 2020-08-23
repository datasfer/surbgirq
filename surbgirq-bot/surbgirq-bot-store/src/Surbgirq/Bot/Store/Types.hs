{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Bot.Store.Types where

import Data.Map.Strict (Map)
import Data.Text       (Text)
import GHC.Generics    (Generic)

import qualified Data.Map.Strict as Map

import Common.Aeson
import Data.Aeson
import Data.Default
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

