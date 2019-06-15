{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Surbgirq.Back.App.Env
    ( ServerEnv(..)
    , AppM(..)
    , ExternalStore(..)
    ) where

import Control.Monad.Logger
import Control.Monad.Reader

import qualified Database.SQLite.Simple as SQL

import Data.Pool     (Pool, createPool)
import Database.Bolt
import Servant       (Handler)
------------------------------------------------------------
--
------------------------------------------------------------

newtype AppM a = AppM { unAppM :: ReaderT ServerEnv (LoggingT Handler) a
  } deriving (Functor, Applicative, Monad, MonadReader ServerEnv, MonadIO)


data ServerEnv = ServerEnv
  { env'pool          :: Pool Pipe
  -- ^ Neo4j db pool
  , env'externalStore :: ExternalStore
  -- ^ the external store, mostly will be used to hold derived data on block commit event.
  }

-- | External store data type
data ExternalStore = ExternalStore { getConn :: SQL.Connection}
