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



-- | Books
sendBooks :: ChatId -> Text -> Bot ()
sendBooks chatId book | T.null book = allBooks chatId
                      | otherwise = do
    let girq = (readMaybe $ T.unpack  book) :: Maybe Girq
    case girq of
      Nothing -> sendHtml chatId  $ T.pack $ [qc|Unknown book name: <b>{book}</b>|]
      Just girq -> do
                liftIO $ print $ show girq
                sendHtml chatId  $ T.pack $ show girq




allBooks :: ChatId -> Bot ()
allBooks chatId = do
    books <- liftIO getBooksHandler
    sendAsParts chatId books
--    forM_ books $ \book -> let htmlText = TL.toStrict . renderText $ toHtml book in sendHtml chatId htmlText

sendBooks_ :: ChatId -> Bot ()
sendBooks_ chatId = do
    books <- liftIO getBooksHandler
    let booksHtml =  TL.toStrict . renderText $ toHtml books
    sendHtml chatId  booksHtml




-- | Sections
sendChapterSections :: ChatId -> Text -> Bot ()
sendChapterSections chatId argString = do
  let args = parseChatCommandArgs argString
      (book, chapter, section) =
          case args of
            (a:b:c:_) -> (a, b, c)
            [a, b]    -> (a, b, "")
            [a]       -> (a, "", "")
            _         -> ("", "", "")

      bookRes = (readMaybe  book) :: Maybe Girq
      chRes = ChapterNum <$> readMaybe chapter :: Maybe ChapterNum
      secRes = SectionNum <$>  readMaybe section :: Maybe SectionNum
      dialect = Ashxarhabar
  secRes <- liftIO $ case (bookRes, chRes, secRes) of
    (Just girq, Just chapter, Just section) -> Right <$> getChapterOneSectionHandler dialect girq chapter section
    (Just girq, Just chapter, Nothing) -> Right <$> getChapterSectionsHandler dialect girq chapter
    (Just girq, Nothing, Nothing) -> Right <$> getBookSectionsHandler dialect girq
    (Nothing, _, _) ->  pure $ Left [qc|Failed parse book: {book}|]
  case secRes of
    Right secs -> do
        let sectionHtml =  TL.toStrict . renderText $ toHtml secs
        sendHtml chatId  sectionHtml
--        forM_ secs $ \sec -> let htmlText = TL.toStrict . renderText $ toHtml sec in sendHtml chatId htmlText
    Left e -> sendHtml chatId  e



-- | verse
sendVerse :: Bool -> ChatId -> Text -> Bot ()
sendVerse sendAtOnce chatId verseRef =
    let res = parseVerseRef verseRef
    in case res of
      Left e     -> sendHtml chatId e
      Right vRef -> sendVerse' sendAtOnce chatId vRef


sendVerse' :: Bool -> ChatId -> VerseReference -> Bot ()
sendVerse' sendAtOnce chatId vRef@VerseReference{..} = do
                  vs <- liftIO $ case verseRef'to of
                                  Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from)
                                  Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)

                  if sendAtOnce
                  then let verseHtml =  TL.toStrict . renderText $ (toHtml vs <> toHtml vRef)
                       in sendHtml chatId  verseHtml
                  else do
                    sendAsParts chatId vs
                    let verseRefHtml =  TL.toStrict . renderText $ toHtml vRef
                    sendHtml chatId  verseRefHtml



-- | Auxiliary functions
sendAsParts chatId xs = forM_ xs $ \x ->
                let htmlText = TL.toStrict . renderText $ toHtml x
                in sendHtml chatId htmlText

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

parseChatCommandArgs :: Text -> [String]
parseChatCommandArgs text = getAllTextMatches $ ((T.unpack text) :: String) =~ ("\\w+" :: String) :: [String]

getHeadNumber :: [String] -> Maybe Int
getHeadNumber args = do
  arg <- if null args then Nothing else Just $ head args
  if all isNumber arg then Just $ read arg else Nothing


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
