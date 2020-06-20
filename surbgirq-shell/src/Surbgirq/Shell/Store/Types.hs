{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Shell.Store.Types where

import Data.Text
import Database.Selda
import GHC.Generics

data EngLemma = EngLemma
  { lemmaID :: Int -- ID EngLemma
  , amWord  :: Text
  , enWord  :: Text
  } deriving (Show, Generic)

data WordForm = WordForm
  { formID :: Int -- ID WordForm
  , form   :: Text
  , armat  :: Text
  , tags   :: Text
  } deriving (Show, Generic)



data Armat = Armat
  { armatID   :: Int -- ID Armat
  , armatWord :: Text
  } deriving (Show, Generic)

data ArmatForm = ArmatForm
  { armatFormID :: Int -- ID ArmatForm
  , relArmat    :: Int -- ID Armat
  , wordForm    :: Text
  } deriving (Show, Generic)
