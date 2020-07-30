{-# LANGUAGE QuasiQuotes     #-}
{-# LANGUAGE RecordWildCards #-}


module Surbgirq.Bot.Server.Responses where

import Control.Monad                 (forM_)
import Control.Monad.IO.Class        (liftIO)
import Data.Char                     (isNumber)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)
import Text.Regex.Posix              (getAllTextMatches, (=~))

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Control.Monad.Reader
import Lucid
import Web.Telegram.API.Bot

import Surbgirq.Bot.ClientRequests
import Surbgirq.Bot.Help
import Surbgirq.Bot.Lucid.Instances
import Surbgirq.Bot.Monad
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------

sendHelpMessage :: ChatId -> Bot ()
sendHelpMessage chatId = do
  BotConfig{..} <- ask
  liftIO $ sendMessage telegramToken (helpMessage chatId) manager >> return ()
  return ()

sendAphorism :: ChatId -> Text -> Bot ()
sendAphorism chatId args = do
  BotConfig{..} <- ask
  let cantidad' = getHeadNumber $ parseChatCommandArgs args
      cantidad = case cantidad' of
        Just c  -> c
        Nothing -> 1
  let sentences = ["liftIO $ replicateM cantidad eligeSentenceFromBlog"]
  let requests = map (\s -> sendMessageRequest chatId (T.pack s)) sentences
  _ <- ($) liftIO $ forM_ requests $ (\r -> sendMessage telegramToken r manager)
  return ()

sendHtml :: ChatId -> Text -> Bot ()
sendHtml chatId msg = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId msg (Just HTML) Nothing Nothing Nothing Nothing
    _ <- ($) liftIO $ sendMessage telegramToken request manager
    return ()

sendText :: ChatId -> Text -> Bot ()
sendText chatId msg = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId msg Nothing Nothing Nothing Nothing Nothing
    _ <- ($) liftIO $ sendMessage telegramToken request manager
    return ()



sendBooks :: ChatId -> Text -> Bot ()
sendBooks chatId book | T.null book = allBooks chatId
                      | otherwise = do
    let girq = (readMaybe $ T.unpack  book) :: Maybe Girq
    case girq of
      Nothing -> sendHtml chatId  $ T.pack $ [qc|Unknown book name: <b>{book}</b>|]
      Just girq -> do
                liftIO $ print $ show girq
                sendHtml chatId  $ T.pack $ show girq


sendVerse :: ChatId -> Text -> Bot ()
sendVerse chatId verseRef =
    let res = parseVerseRef verseRef
    in case res of
      Left e -> sendHtml chatId e
      Right vRef@VerseReference{..} -> do
                  vs <- liftIO $ case verseRef'to of
                                  Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from)
                                  Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)
                  liftIO $ print $ show vRef
                  liftIO $ print $ show vs
                  forM_ vs $ \verse -> let htmlText = TL.toStrict . renderText $ toHtml verse in sendHtml chatId htmlText
                  let verseRefHtml =  TL.toStrict . renderText $ toHtml vRef
                  sendHtml chatId  verseRefHtml

sendVerse' :: ChatId -> VerseReference -> Bot ()
sendVerse' chatId vRef@VerseReference{..} = do
                  vs <- liftIO $ case verseRef'to of
                                  Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from)
                                  Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)
                  liftIO $ print $ show vRef
                  liftIO $ print $ show vs
                  forM_ vs $ \verse -> let htmlText = TL.toStrict . renderText $ toHtml verse in sendHtml chatId htmlText
                  let verseRefHtml =  TL.toStrict . renderText $ toHtml vRef
                  sendHtml chatId  verseRefHtml

                  -- sendText chatId  $ T.pack $ show vs


sendVerse_ :: ChatId -> Text -> Bot ()
sendVerse_ chatId verseRef =
    let res = parseVerseRef verseRef
    in case res of
      Left e -> sendHtml chatId e
      Right vRef@VerseReference{..} -> do
                  vs <- liftIO $ case verseRef'to of
                                  Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from)
                                  Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)
                  let verseHtml =  TL.toStrict . renderText $ (toHtml vs <> toHtml vRef)
                  sendHtml chatId  verseHtml



allBooks :: ChatId -> Bot ()
allBooks chatId = do
    books <- liftIO getBooksHandler
    forM_ books $ \book -> let htmlText = TL.toStrict . renderText $ toHtml book in sendHtml chatId htmlText

sendBooks_ :: ChatId -> Bot ()
sendBooks_ chatId = do
    books <- liftIO getBooksHandler
    let booksHtml =  TL.toStrict . renderText $ toHtml books
    sendHtml chatId  booksHtml


parseChatCommandArgs :: Text -> [String]
parseChatCommandArgs text = getAllTextMatches $ ((T.unpack text) :: String) =~ ("\\w+" :: String) :: [String]
getHeadNumber :: [String] -> Maybe Int
getHeadNumber args = do
  arg <- if null args then Nothing else Just $ head args
  if all isNumber arg then Just $ read arg else Nothing
