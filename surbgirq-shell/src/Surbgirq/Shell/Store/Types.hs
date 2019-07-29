{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Shell.Store.Types where

import Data.Text
import Database.Selda
import GHC.Generics

data EngLemma = EngLemma
  { lemmaID :: ID EngLemma
  , amWord  :: Text
  , enWord  :: Text
  } deriving (Show, Generic)

data WordForm = WordForm
  { formID :: ID WordForm
  , form   :: Text
  , armat  :: Text
  , tags   :: Text
  } deriving (Show, Generic)



data Armat = Armat
  { armatID   :: ID Armat
  , armatWord :: Text
  } deriving (Show, Generic)

data ArmatForm = ArmatForm
  { armatFormID :: ID ArmatForm
  , relArmat    :: ID Armat
  , wordForm    :: Text
  } deriving (Show, Generic)
