{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}


module Surbgirq.Bot.Server.TelegramAPI
    ( sendMessage
    , editMessageText
    , answerInlineQuery
    , answerCallbackQuery
    , module TelegramBotAPI
    )where


import Control.Monad.Reader

import Network.HTTP.Client (Manager)

-- re-import telegram-api functions hiding part of them
import Surbgirq.Bot.Server.Imports.TelegramAPI as TelegramBotAPI


import qualified Data.Text            as T
import qualified Web.Telegram.API.Bot as Tg

-- import Servant.API    (botApiHost)
import Servant.Client
    (BaseUrl(..), ClientEnv(..), ClientError, Scheme(..), defaultMakeClientRequest)

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Types

------------------------------------------------------------
--
------------------------------------------------------------

answerInlineQuery :: Token -> AnswerInlineQueryRequest -> Manager -> Bot (Either ClientError InlineQueryResponse)
answerInlineQuery = runM Tg.answerInlineQueryM

answerCallbackQuery :: Token -> AnswerCallbackQueryRequest -> Manager -> Bot (Either ClientError CallbackQueryResponse)
answerCallbackQuery = runM Tg.answerCallbackQueryM

sendMessage :: Token -> SendMessageRequest -> Manager -> Bot (Either ClientError MessageResponse)
sendMessage = runM Tg.sendMessageM

editMessageText :: Token -> EditMessageTextRequest -> Manager -> Bot (Either ClientError MessageResponse)
editMessageText = runM Tg.editMessageTextM

runM :: (r -> TelegramClient a) -> Token -> r -> Manager -> Bot (Either ClientError a)
runM tcm token request = runCustomClient (tcm request) token

runCustomClient :: TelegramClient a -> Token -> Manager -> Bot (Either ClientError a)
runCustomClient tcm token manager = do
    BotConfig{..} <- ask
    let url = T.unpack $ botApiHost
        telegramBaseUrl = BaseUrl Https url botApiPort ""

    liftIO $ Tg.runClient' tcm token (ClientEnv manager telegramBaseUrl Nothing defaultMakeClientRequest)

-- IO context seems more preferable, it easy to lift than unlift
-- sendMessage :: Token -> SendMessageRequest -> Manager -> Bot (Either ClientError MessageResponse)
-- sendMessage t s m = do
--     BotConfig{..} <- ask
--     let url = T.unpack $ botApiHost
--         telegramBaseUrl = BaseUrl Https url botApiPort ""

--     liftIO $ runM sendMessageM telegramBaseUrl t s m


-- runClient :: TelegramClient a -> BaseUrl -> Token -> Manager -> IO (Either ClientError a)
-- runClient tcm url token manager = Tg.runClient' tcm token (ClientEnv manager url Nothing)

-- runM :: (r -> TelegramClient a) -> BaseUrl -> Token -> r -> Manager -> IO (Either ClientError a)
-- runM tcm url token request = runClient (tcm request) url token
