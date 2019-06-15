{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}


module Surbgirq.Types.ApiInfo (
 ApiInfo(..)
 ) where

import Common.Aeson
import Data.Aeson   (Value)
import Data.Text    (Text)
import GHC.Generics

-------------------------------------------------------------------------------
--

-- | Api info, git tags, hashes ...
data ApiInfo = ApiInfo
  { apiinfo'version   :: Text
  , apiinfo'changeset :: Text
  , apiinfo'branch    :: Text
  , apiinfo'git       :: Value
  } deriving (Show, Generic)

$(deriveJSON dropPrefixOptions ''ApiInfo)
