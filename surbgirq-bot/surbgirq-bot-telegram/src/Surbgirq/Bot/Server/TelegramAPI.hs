{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}


module Surbgirq.Bot.Server.TelegramAPI
    ( sendMessage
    )where


import Control.Monad.Reader

import Network.HTTP.Client  (Manager)
import Web.Telegram.API.Bot
    (MessageResponse, SendMessageRequest, TelegramClient, Token, sendMessageM)

import qualified Data.Text            as T
import qualified Web.Telegram.API.Bot as Tg

-- import Servant.API    (botApiHost)
import Servant.Client (BaseUrl(..), ClientEnv(..), ClientError, Scheme(..))

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Types

------------------------------------------------------------
--
------------------------------------------------------------




sendMessage :: Token -> SendMessageRequest -> Manager -> Bot (Either ClientError MessageResponse)
sendMessage t s m = do
    BotConfig{..} <- ask
    let url = T.unpack $ botApiHost
        telegramBaseUrl = BaseUrl Https url botApiPort ""

    liftIO $ runM sendMessageM telegramBaseUrl t s m


runClient :: TelegramClient a -> BaseUrl -> Token -> Manager -> IO (Either ClientError a)
runClient tcm url token manager = Tg.runClient' tcm token (ClientEnv manager url Nothing)

runM :: (r -> TelegramClient a) -> BaseUrl -> Token -> r -> Manager -> IO (Either ClientError a)
runM tcm url token request = runClient (tcm request) url token
