{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE TemplateHaskell #-}

module Types.Settings where

import Data.Aeson
import Data.String
import Katip

import Data.Text                (Text)
import Network.Wai.Handler.Warp (HostPreference)

import qualified Data.Text as T

import Surbgirq.Service
import Common.Aeson
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


data SqliteStore = SqliteStore {
      sqliteStore'dbName :: String
    }
 deriving (Show)

data StoreSpec = StoreSpec
  { storeSpec'sqlite :: SqliteStore
    -- ^ Sqlite Store settings
  }
  deriving(Show)




-- | Specification of logging
data LogSpec = LogSpec
  { logSpec'logFiles       :: [ScribeSpec]
    -- ^ Log files to write to
  , logSpec'hostnameSuffix :: Maybe String
    -- ^ Suffix to append to host name in logs.
  , logSpec'clusterId      :: Maybe Text
    -- ^ Cluster ID will written to @env@ field of logs
  }
  deriving(Show)



-- | the block explorer front and thundermint node settings
data SurbgirqSettings = SurbgirqSettings
  { surbgirq'server   :: !ServerSettings
  -- ^ the server front settings, port ...
  , surbgirq'logs     :: !LogSpec
  -- ^ the logs settings
  , surbgirq'stores   :: !StoreSpec
  -- ^ the storage settings
  } deriving (Show)

$(deriveFromJSON dropPrefixOptions ''SurbgirqSettings)
$(deriveJSON dropPrefixOptions     ''LogSpec)
$(deriveFromJSON dropPrefixOptions ''ServerSettings)
$(deriveJSON dropPrefixOptions     ''SqliteStore)
$(deriveJSON dropPrefixOptions     ''StoreSpec)
