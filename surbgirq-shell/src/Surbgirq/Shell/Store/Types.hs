{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Shell.Store.Types where

import Data.Text
import GHC.Generics

data EngLemma = EngLemma
  { amWord :: Text
  , enWord :: Text
  } deriving (Show, Generic)



data WordForm = WordForm
  { form  :: Text
  , armat :: Text
  , tags  :: Text
  } deriving (Show, Generic)
