{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE TypeOperators     #-}

module Surbgirq.Bot.FB.Server.Webhook where

import Control.Monad.IO.Class        (liftIO)
import Data.Foldable                 (traverse_)
import Data.Maybe                    (fromMaybe)
import Data.Text                     (Text)
import Data.Version                  (makeVersion, showVersion)
import Network.HTTP.Client           (newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)

import Control.Monad.Except
import Control.Monad.Reader
import Servant.Client
import Servant.Server
import Web.FBMessenger.API.Bot
import Web.FBMessenger.API.Bot.WebhookAPI

import qualified Data.ByteString.Lazy.Char8 as C
import qualified Data.Text                  as T

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Types
------------------------------------------------------------
--
------------------------------------------------------------


-- webhook_verify :: Maybe Text -> Maybe Text -> ExceptT ServerError IO Text
webhook_verify verifyTokenStored (Just verifyToken) (Just challenge)
      | verifyToken == verifyTokenStored = return challenge
webhook_verify _ tk ch = let
      eB :: String
      eB = [qc|[ERROR]: wrong validation request. Got (token, challenge) = ({tk}, {ch})"|]
      in do
        liftIO $ putStrLn eB
        throwError err500 { errBody = C.pack eB}

webhook_message pageTokenStored (RemoteEventList res) = do
      r <- traverse echoMessage (concatMap evt_messaging res)
      liftIO $ traverse_ (putStrLn . T.unpack) r
      return "{\"status\":\"fulfilled\"}"
  where
    token = Token pageTokenStored
    echoMessage msg =
      case evtContent msg of
        EmTextMessage _ _ text -> liftIO $ echoTextMessage text (evtSenderId msg)
        _                      -> return "[WARN]: this is just an example, no complex message is echoed."

    echoTextMessage text rcptId = do
      m <- newManager tlsManagerSettings
      -- create the recipient using the sender id
      -- (we know that this is successful when only one argument is not Nothing)
      let (Just rcpt) = recipient (Just rcptId) Nothing
      -- prepare the Send API request body
      let messageReq = sendTextMessageRequest Nothing rcpt text
      -- finally send the message request using the tls http connection manager
      logRsp <- sendTextMessage (Just token) messageReq m
      -- restructure the response to get a decent log out of it
      -- e.g. one could add the response or the error in the log message
      let logMsg = either (\_ -> "[ERROR]: failed to echo message")
                          (\_ -> [qc|[INFO]: sent {text} to {rcpt}|])
                          logRsp
      return (T.pack logMsg)
