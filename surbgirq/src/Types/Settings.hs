{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE TemplateHaskell #-}

{-|
Module      : Types.Settings
Description : Settings types

Settings types
-}

module Types.Settings where

import Data.Aeson
import Data.String

import Data.Text                (Text)
import Network.Wai.Handler.Warp (HostPreference)

import qualified Data.Text as T

import Common.Aeson
-- import Surbgirq.Neo4j
-- import Surbgirq.Service
import Types.Logger

------------------------------------------------------------
--
------------------------------------------------------------

instance FromJSON HostPreference where
  parseJSON = withText "HostPreference" $ \t ->
    pure $ fromString . T.unpack $ t


data ExplorerSettings = ExplorerSettings
  { explorer'server      :: !ServerSettings
  , explorer'graphApiUrl :: !String
  -- ^ surbgirq-graph-api's root, without /api (GRAPH_API_URL)
  , explorer'defaultBible :: !Text
  -- ^ the Bible whose books the front page lists (EXPLORER_DEFAULT_BIBLE)
  } deriving (Show)

data ServerSettings = ServerSettings
  { serverHost                   :: !HostPreference
  , serverPort                   :: !Int
  , serverDetailedRequestLogging :: !Bool
  , serverStaticDir              :: !FilePath
  , serverIpFromHeader           :: !Bool
  } deriving (Eq, Show)


newtype SqliteConfig = SqliteConfig
    { sqliteConfig'dbName :: String
    } deriving (Show)

data StoreSpec = StoreSpec
  {
    storeSpec'neo4j  :: Neo4jConfig
  -- ^ Neo4j store settings
  , storeSpec'sqlite :: SqliteConfig
    -- ^ Sqlite Store settings
  } deriving(Show)



data Neo4jConfig = Neo4jConfig
    { neo4jConfig'user :: Text
    , neo4jConfig'pass :: Text
    } deriving(Show)


-- | Specification of logging
data LogSpec = LogSpec
  { logSpec'logFiles       :: [ScribeSpec]
    -- ^ Log files to write to
  , logSpec'hostnameSuffix :: Maybe String
    -- ^ Suffix to append to host name in logs.
  , logSpec'clusterId      :: Maybe Text
    -- ^ Cluster ID will written to @env@ field of logs
  } deriving(Show)


data LocalNeo4jApiConfig = LocalNeo4jApiConfig
    { localNeo4jApiConfig'baseUrl :: Text
    , localNeo4jApiConfig'port    :: Int
    } deriving(Show)

-- | Surbgirq settings
data SurbgirqSettings = SurbgirqSettings
  { surbgirq'server        :: !ServerSettings
  -- ^ the server front settings, port ...
  , surbgirq'logs          :: !LogSpec
  -- ^ the logs settings
  , surbgirq'stores        :: !StoreSpec
  -- ^ the storage settings
  , surbgirq'localNeo4jApi :: !LocalNeo4jApiConfig
  -- ^ the storage settings
  } deriving (Show)

$(deriveJSON dropPrefixOptions     ''LogSpec)
$(deriveFromJSON dropPrefixOptions ''ServerSettings)
$(deriveFromJSON dropPrefixOptions     ''ExplorerSettings)

$(deriveJSON dropPrefixOptions     ''SqliteConfig)
$(deriveJSON dropPrefixOptions     ''Neo4jConfig)
$(deriveJSON dropPrefixOptions     ''LocalNeo4jApiConfig)
$(deriveJSON dropPrefixOptions     ''StoreSpec)
$(deriveFromJSON dropPrefixOptions ''SurbgirqSettings)
