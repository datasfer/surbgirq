{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}


module Surbgirq.Bot.Server.Handlers.Messages where

import Data.Default

import Data.List                     (intercalate, intersperse)
import Data.Maybe                    (maybe)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Map.Strict as M
import qualified Data.Text       as T

import Control.Monad.Reader

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Server.Settings.KeyboardMarkups
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils
------------------------------------------------------------
--
------------------------------------------------------------

handleMessage :: Message -> Bot ()
handleMessage msg@Message{..} = do
--  BotConfig{..} <- ask
--  tvar <- asks state

  -- liftIO $ putStrLn $ "Message id -> " ++ (show $ message_id msg)
  -- liftIO $ putStrLn $ "Message text -> " ++ (T.unpack messageText)
  -- liftIO $ putStrLn $ "Chat id -> " ++ (show $ chat_id $ chat msg)
  let userId = UserId $ maybe 0 user_id  from
  -- case u_id of
  --   Just uId -> initUserSettings uId def
  --   Nothing   -> do
  --               liftIO $ putStrLn $ "Erro: message has not from: to get user_id " ++ (show msg)
  --               return ()
  liftIO $ putStrLn [qc|=========== Message Handler {msg} Message =================|]
  liftIO $ putStrLn [qc|=========== u_id {userId}|]

  BotConfig{..} <- ask
  cfg <- getUserConfig userId

  case text of
    Nothing -> do
              liftIO $ putStrLn $ ">>>>>> Message text is null: \n" ++ (show msg)
    Just messageText -> onCommand userId messageText

  -- liftIO $ atomically $ do
  -- state@BotState{..} <- readTVar tvar
  -- let ps = M.insert (UserId uId) smsCode state'confirmPhone
  --     us =  ((UserId uId), signupUser) : state'users
  --     state' = state {state'confirmPhone = ps, state'users = us}
  -- writeTVar tvar state'

  where
    chatId = ChatId $ chat_id chat
    Just messageText = text

    onCommand userId (T.stripPrefix "/help" -> Just _)          = sendHelpMessage chatId
    onCommand userId (T.stripPrefix "/verse" -> Just verseRef)  = sendVerse True chatId verseRef
    onCommand userId (T.stripPrefix "/_verse" -> Just verseRef) = sendVerse True chatId verseRef
    onCommand userId (T.stripPrefix "/chapter" -> Just args)    = sendChapterSections chatId args
    onCommand userId (T.stripPrefix "/books" -> Just book)      = sendBooks chatId book
    onCommand userId (T.stripPrefix "/_books" -> Just _)        = sendBooks_ chatId
    onCommand userId (T.stripPrefix "/mihatov" -> Just _)       = sendBooks_ chatId
    onCommand userId (T.stripPrefix "/today" -> Just _)         = sendBooks_ chatId
    onCommand userId (T.stripPrefix "/random" -> Just _)        = sendBooks_ chatId
    onCommand userId (T.stripPrefix "/md" -> Just _)            = testMd chatId
    onCommand userId (T.stripPrefix "/html" -> Just _)          = testHtml chatId

    onCommand userId (T.stripPrefix "/start" -> Just _)         = showSettings chatId userId
    onCommand userId (T.stripPrefix "/settings" -> Just _)      = showSettings chatId userId
    onCommand userId (parseVerseRef  -> Right verseRef)         = sendVerse' True chatId verseRef
    onCommand _ _                                               = sendHelpMessage chatId

    -- onCommand str                                        = do
    --                               liftIO $ print $ T.append "=================== Unknown Command"  str
    --                               return ()
    --                                 -- sendHelpMessage chatId


showSettings :: ChatId -> UserId -> Bot ()
showSettings chatId userId = do
    lang <- getLanguage ( unUserId userId)
    liftIO $ putStrLn [qc|=========== UserId {userId} | lang: {lang}|]
    sendTextReplyKb (settingsKeyboardReplyMarkup lang) chatId "Settings"

testMd :: ChatId -> Bot ()
testMd chatId = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId (T.pack formatText) (Just Markdown) Nothing Nothing Nothing Nothing
    _ <- ($) sendMessage telegramToken request manager
    return ()
  where
    formatText = "*boldtext* _italictext_ `fixed width font` [link]   (http://google.com)."


testHtml :: ChatId -> Bot ()
testHtml chatId = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId (T.pack htmlText) (Just HTML) Nothing Nothing Nothing Nothing
    _ <- ($) sendMessage telegramToken request manager
    return ()
  where
    htmlText = intercalate "\n"
               [ "<b>bold</b>, <strong>bold</strong>"
               , "<i>italic</i>, <em>italic</em>"
               , "<u>underline</u>, <ins>underline</ins>"
               , "<s> strikethrough</s>, <strike>strikethrough</strike>, <del>strikethrough</del>"
               , "<b> bold <i>italic bold <s>italic bold strikethrough</s> <u>underline italic bold</u></i> bold</b>"
               , "<a href='http://www.example.com/'>inline URL</a>"
               , "<a href='tg://user?id=123456789'>inline mention of a user</a>"
               , "<code>inline fixed-width code</code>"
               , "<pre>pre-formatted fixed-width code block</pre>"
               , "<pre><code class='language-python'>pre-formatted fixed-width code block written in the Python programming language</code></pre>"
               ]
