{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Types.Logger where

import           Data.Aeson
import           Katip
import           Katip.Scribes.ElasticSearch

import           Control.Monad               (unless)
import           Data.Text                   (Text)
import           GHC.Generics                (Generic)

import           Common.Aeson
-------------------------------------------------------------------------------
--

-- | Type of scribe to use
data ScribeType
  = ScribeJSON
  | ScribeES { elasticIndex :: Text }
  | ScribeTXT
  deriving (Show,Eq,Ord,Generic)
instance ToJSON   ScribeType where
  toJSON = \case
    ScribeJSON   -> String "ScribeJSON"
    ScribeTXT    -> String "ScribeTXT"
    ScribeES{..} -> object [ "tag"   .= ("ScribeES" :: Text)
                           , "index" .= elasticIndex
                           ]
instance FromJSON ScribeType where
  parseJSON (String "ScribeJSON") = return ScribeJSON
  parseJSON (String "ScribeTXT" ) = return ScribeTXT
  parseJSON (String _           ) = fail "Unknown string while decoding ScribeType"
  parseJSON (Object o) = do
    tag <- o .: "tag"
    unless (tag == ("ScribeES" :: Text)) $ fail "Unexpected tag for ScribeType"
    elasticIndex <- o .: "index"
    return ScribeES{..}
  parseJSON _                     = fail "Expecting string or object while decoding ScribeType"

-- | Description of scribe
data ScribeSpec = ScribeSpec
  { scribe'type      :: !ScribeType
    -- ^ Type of scribe to use
  , scribe'path      :: !(Maybe FilePath)
    -- ^ Log file if not specified will log to stdout
  , scribe'severity  :: !Severity
  , scribe'verbosity :: !Verbosity
  }
  deriving (Show,Eq,Ord,Generic)


$(deriveJSON dropPrefixOptions      ''ScribeSpec)
