{-# LANGUAGE AllowAmbiguousTypes        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE ViewPatterns               #-}
module Surbgirq.Bot.Telegram
    ( startApp
    , app
    ) where
import Control.Monad                 (replicateM)
import Data.Char                     (isNumber)
import Data.List                     (intercalate, intersperse)
import Data.List.Split               (chunksOf)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Lucid

import Control.Monad.Except
import Control.Monad.Reader
import Data.Aeson
import Data.Maybe
import Data.Monoid
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.Server
import System.Environment
import Text.Regex.Posix
import Web.Telegram.API.Bot

import Surbgirq.Bot.App
import Surbgirq.Bot.Types

------------------------------------------------------------
--
------------------------------------------------------------


startApp :: IO ()
startApp = do
  putStrLn "Surbgirq bot started..."
  manager' <- newManager tlsManagerSettings
  fbManager <- newManager tlsManagerSettings
  let telegramToken' = "REMOVED-TELEGRAM-TOKEN"
      fbVerifyToken = "123456"
      fbPageToken = "REMOVED-FACEBOOK-TOKEN"
      config = BotConfig
        { telegramToken = Token $ T.pack $ "bot" <> telegramToken'
        , facebookVerifyToken = fbVerifyToken
        , facebookPageToken = fbPageToken
        , manager = manager'
        , facebookManager = fbManager
        }
  run 5000 $ app config
