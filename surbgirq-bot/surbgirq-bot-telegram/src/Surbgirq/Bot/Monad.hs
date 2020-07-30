{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}


module Surbgirq.Bot.Monad where

import Control.Monad.Except
import Control.Monad.Reader

import Data.Monoid
import Servant.Server (Handler, ServerError)

import Surbgirq.Bot.Types

------------------------------------------------------------
--
------------------------------------------------------------

newtype Bot a = Bot
    { runBot :: ReaderT BotConfig Handler a
    } deriving ( Functor, Applicative, Monad, MonadIO, -- classes from base and transformers
                 MonadReader BotConfig, MonadError ServerError) -- classes from mtl for

