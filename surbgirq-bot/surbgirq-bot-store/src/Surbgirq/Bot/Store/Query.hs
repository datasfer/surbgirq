{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Bot.Store.Query where

import Control.Concurrent.STM
import Control.Monad.Reader

import Data.Default    (def)
import Data.Map.Strict (Map)
import Data.Maybe      (fromMaybe)
import Data.Text       (Text)
import GHC.Generics    (Generic)

import qualified Data.Map.Strict as Map

import Common.Aeson
import Data.Aeson
import Data.Default
import Surbgirq.Bot.State
import Surbgirq.Bot.Types
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

getUserConfig :: (MonadReader BotConfig m, MonadIO m) => UserId ->  m UserSettings
getUserConfig uId = do
  tvar <- asks state
  st@BotState{..} <- liftIO $ readTVarIO tvar
  let userCfg = Map.lookup uId state'configs
  return $ case userCfg of
      Nothing  -> def
      Just cfg -> cfg



modifyUserConfig :: (MonadReader BotConfig m, MonadIO m) => UserId -> UserSettings ->  m UserSettings
modifyUserConfig uId cfg = do
  tvar <- asks state
  liftIO $ atomically $ do
    state@BotState{..} <- readTVar tvar
    let xs = Map.insertWith (\new old -> new ) uId cfg state'configs
        state' = state {state'configs = xs}

    writeTVar tvar state'
    return cfg


