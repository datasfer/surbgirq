{-# LANGUAGE GeneralizedNewtypeDeriving #-}

{-|
Module      : Surbgirq.Back.App.Env
Description : Moand AppM

Server Environment data type and AppM Monad
-}

module Surbgirq.Back.App.Env
    ( ServerEnv(..)
    , AppM(..)
    , ExternalStore(..)
    ) where

import Control.Monad.Logger
import Control.Monad.Reader
import Database.Bolt

import Data.Pool (Pool, createPool)
import Servant   (Handler)

import qualified Database.SQLite.Simple as SQL

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
newtype ExternalStore = ExternalStore { getConn :: SQL.Connection}
