{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE TemplateHaskell #-}

module Types.Settings where

import Data.Aeson
import Data.String
import Katip

import Data.Text                (Text)
import Network.Wai.Handler.Warp (HostPreference)

import qualified Data.Text as T

import Common.Aeson
import Surbgirq.Neo4j
import Surbgirq.Service
import Types.Logger
-------------------------------------------------------------------------------
--




instance FromJSON HostPreference where
  parseJSON = withText "HostPreference" $ \t -> do
    pure $ fromString . T.unpack $ t

data ServerSettings = ServerSettings
  { serverHost                   :: !HostPreference
  -- ^ Server host name
  , serverPort                   :: !Int
  -- ^ Server port number
  -- , serverTlsConf              :: !(Maybe TlsConfig)
  -- -- ^ Tls files for https
  -- , serverTlsParams            :: !HttpQueryTlsParams
  -- -- ^ How to query worker over http
  , serverDetailedRequestLogging :: !Bool
  , serverStaticDir              :: !FilePath
  , serverNewsDir                :: !FilePath
  , serverIpFromHeader           :: !Bool
  -- ^ If set, HTTP log would be more readable
  , serverMonitoringPort         :: !(Maybe Int)
  } deriving (Eq, Show)


data SqliteConfig = SqliteConfig
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



-- | Surbgirq settings
data SurbgirqSettings = SurbgirqSettings
  { surbgirq'server :: !ServerSettings
  -- ^ the server front settings, port ...
  , surbgirq'logs   :: !LogSpec
  -- ^ the logs settings
  , surbgirq'stores :: !StoreSpec
  -- ^ the storage settings
  } deriving (Show)

$(deriveFromJSON dropPrefixOptions ''SurbgirqSettings)
$(deriveJSON dropPrefixOptions     ''LogSpec)
$(deriveFromJSON dropPrefixOptions ''ServerSettings)
$(deriveJSON dropPrefixOptions     ''SqliteConfig)
$(deriveJSON dropPrefixOptions     ''Neo4jConfig)
$(deriveJSON dropPrefixOptions     ''StoreSpec)
