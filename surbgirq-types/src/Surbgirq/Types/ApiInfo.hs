{-# LANGUAGE TemplateHaskell              #-}


module Surbgirq.Types.ApiInfo (
 ApiInfo(..)
 ) where

import Data.Aeson (Value)
import Data.Text  (Text)

import Common.Aeson

-------------------------------------------------------------------------------
--

-- | Api info, git tags, hashes ...
data ApiInfo = ApiInfo
  { apiinfo'version   :: Text
  , apiinfo'changeset :: Text
  , apiinfo'branch    :: Text
  , apiinfo'git       :: Value
  } deriving (Show)

$(deriveJSON dropPrefixOptions ''ApiInfo)
