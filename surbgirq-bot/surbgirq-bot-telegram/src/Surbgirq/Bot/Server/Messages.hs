{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}


module Surbgirq.Bot.Server.Messages where

import Data.List (intercalate, intersperse)


import qualified Data.Text as T

import Control.Monad.Reader
import Web.Telegram.API.Bot

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------

handleMessage :: Message -> Bot ()
handleMessage msg@Message{..} = do
  BotConfig{..} <- ask
  -- liftIO $ putStrLn $ "Message id -> " ++ (show $ message_id msg)
  -- liftIO $ putStrLn $ "Message text -> " ++ (T.unpack messageText)
  -- liftIO $ putStrLn $ "Chat id -> " ++ (show $ chat_id $ chat msg)
  liftIO $ putStrLn $ "Message: " ++ (show msg)
  case text of
    Nothing -> do
              liftIO $ putStrLn $ ">>>>>> Message text is null: \n" ++ (show msg)
    Just messageText -> onCommand messageText

  where
    chatId = ChatId $ chat_id chat
    Just messageText = text

    onCommand (T.stripPrefix "/help" -> Just _)          = sendHelpMessage chatId
    onCommand (T.stripPrefix "/verse" -> Just verseRef)  = sendVerse False chatId verseRef
    onCommand (T.stripPrefix "/_verse" -> Just verseRef) = sendVerse True chatId verseRef
    onCommand (T.stripPrefix "/chapter" -> Just args)    = sendChapterSections chatId args
    onCommand (T.stripPrefix "/books" -> Just book)      = sendBooks chatId book
    onCommand (T.stripPrefix "/_books" -> Just _)        = sendBooks_ chatId
    onCommand (T.stripPrefix "/mihatov" -> Just _)       = sendBooks_ chatId
    onCommand (T.stripPrefix "/today" -> Just _)         = sendBooks_ chatId
    onCommand (T.stripPrefix "/random" -> Just _)        = sendBooks_ chatId
    onCommand (T.stripPrefix "/md" -> Just _)            = testMd chatId
    onCommand (T.stripPrefix "/html" -> Just _)          = testHtml chatId
    onCommand (parseVerseRef  -> Right verseRef)         = sendVerse' False chatId verseRef
    onCommand str                                        = do
                                  liftIO $ print $ T.append "=================== Unknown Command"  str
                                  return ()
                                    -- sendHelpMessage chatId




testMd :: ChatId -> Bot ()
testMd chatId = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId (T.pack formatText) (Just Markdown) Nothing Nothing Nothing Nothing
    _ <- ($) liftIO $ sendMessage telegramToken request manager
    return ()
  where
    formatText = "*boldtext* _italictext_ `fixed width font` [link]   (http://google.com)."


testHtml :: ChatId -> Bot ()
testHtml chatId = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId (T.pack htmlText) (Just HTML) Nothing Nothing Nothing Nothing
    _ <- ($) liftIO $ sendMessage telegramToken request manager
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
