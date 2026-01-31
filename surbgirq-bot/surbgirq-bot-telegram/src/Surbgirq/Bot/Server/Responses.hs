{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}


module Surbgirq.Bot.Server.Responses where

import Control.Monad                 (forM_)
import Control.Monad.IO.Class        (liftIO)
import Data.Char                     (isNumber)
import Data.Maybe                    (fromMaybe)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)
import Text.Regex.Posix              (getAllTextMatches, (=~))

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Data.IORef

import Control.Monad.Reader
import Lucid


import Surbgirq.Bot.ClientRequests
import Surbgirq.Bot.Lucid.Instances
import Surbgirq.Bot.Monad
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types

import Surbgirq.Bot.Server.Helpers
import Surbgirq.Bot.Server.TelegramAPI

import Surbgirq.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------

sendHelpMessage :: ChatId -> Bot ()
sendHelpMessage chatId = do
  BotConfig{..} <- ask
  sendMessage telegramToken (helpMessage chatId) manager >> return ()
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
    books <- liftIO $ getBooksHandler E1994T
    sendAsParts chatId books
--    forM_ books $ \book -> let htmlText = TL.toStrict . renderText $ toHtml book in sendHtml chatId htmlText

sendBooks_ :: ChatId -> Bot ()
sendBooks_ chatId = do
    books <- liftIO $ getBooksHandler E1994T
    let booksHtml =  TL.toStrict . renderText $ toHtml books
    sendHtml chatId  booksHtml




-- | Sections
sendChapterSections :: ChatId -> UserId -> Text -> Bot ()
sendChapterSections chatId userId argString = do
  BotConfig{..} <- ask
  cfg <- getUserConfig  userId

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
      -- translation =  fromMaybe E1994T $ readTranslation [config'narek cfg]
  -- liftIO $ putStrLn [qc|TTTT Translation: {translation}|]

  secRes <- liftIO $ case (bookRes, chRes, secRes) of
    (Just girq, Just chapter, Just section) -> Right <$> getChapterOneSectionHandler (getCfgTranslation cfg girq) girq chapter section
    (Just girq, Just chapter, Nothing) -> Right <$> getChapterSectionsHandler (getCfgTranslation cfg girq) girq chapter
    (Just girq, Nothing, Nothing) -> Right <$> getBookSectionsHandler (getCfgTranslation cfg girq) girq
    (Nothing, _, _) ->  pure $ Left [qc|Failed parse book: {book}|]
  case secRes of
    Right secs -> do
        let sectionHtml =  TL.toStrict . renderText $ toHtml secs
        sendHtml chatId  sectionHtml
--        forM_ secs $ \sec -> let htmlText = TL.toStrict . renderText $ toHtml sec in sendHtml chatId htmlText
    Left e -> sendHtml chatId  e


-- | verse
sendVerse :: Bool -> ChatId -> UserId -> Text -> Bot ()
sendVerse sendAtOnce chatId userId verseRef =
    let res = parseVerseRef verseRef
    in case res of
      Left e     -> sendHtml chatId e
      Right vRef -> sendVerse' sendAtOnce chatId userId  vRef


-- | if sendAtOnce True then send all verses of chapter as one text post
-- otherwise will send sperae post, and only for last verse ill have next button
sendVerse' :: Bool -> ChatId -> UserId -> VerseReference -> Bot ()
sendVerse' sendAtOnce chatId userId vRef@VerseReference{..} = do
      BotConfig{..} <- ask
      cfg <- getUserConfig  userId

      let defaultTrans = fromMaybe E1994T $ readTranslation [config'bible cfg]

      vs <- liftIO $ getVerses defaultTrans vRef
      maxVerseNum <- liftIO $ getChapterVerseNumberHandler defaultTrans verseRef'book $ ChapterNum verseRef'chapter

      if sendAtOnce
      then do
        let verseHtml = TL.toStrict . renderText $ (toHtml vs <> toHtml vRef)
            currentPage = fromMaybe 1 verseRef'from
            buttons = prevNextPageBtns currentPage maxVerseNum "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]
            -- buttons = generatePageBtns 0 page 12 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]
        sendTextReplyKb (ReplyInlineKeyboardMarkup buttons)  chatId verseHtml
      else do
        sendAsParts chatId vs
        let verseRefHtml = TL.toStrict . renderText $ toHtml vRef
            currentPage = fromMaybe 1 verseRef'from
            -- buttons = generatePageBtns 0 page 12 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]
            buttons = prevNextPageBtns currentPage maxVerseNum "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]


        sendTextReplyKb (ReplyInlineKeyboardMarkup buttons)  chatId verseRefHtml



getVerse' :: TranslationID -> ChatId -> VerseReference -> IO [Verse]
getVerse' defaTrans chatId vRef@VerseReference{..} = getVerses defaTrans vRef


getVerses :: TranslationID -> VerseReference -> IO [Verse]
getVerses defTrans vRef@VerseReference{..} = do
  let translation = fromMaybe defTrans verseRef'translation
  maxVerseNum <- getChapterVerseNumberHandler translation verseRef'book $ ChapterNum verseRef'chapter
  case (verseRef'from, verseRef'to) of
    (Nothing, Nothing)   -> getVerseRangeHandler translation verseRef'book (ChapterNum verseRef'chapter) (VerseNum 1) (VerseNum <$> Just maxVerseNum)
    (Just from, Nothing) -> getOneVerseHandler translation verseRef'book (ChapterNum verseRef'chapter) (VerseNum from)
    (Just from, Just to) -> getVerseRangeHandler translation verseRef'book (ChapterNum verseRef'chapter) (VerseNum from) (VerseNum <$> Just  to)
    (Nothing, Just to)   -> getVerseRangeHandler translation verseRef'book (ChapterNum verseRef'chapter) (VerseNum 1) (VerseNum <$> Just to)


getChapterVerses :: TranslationID -> VerseReference -> IO [Verse]
getChapterVerses defTrans vRef@VerseReference{..} = do
  let translation = fromMaybe defTrans verseRef'translation
  maxVerseNum <- getChapterVerseNumberHandler translation verseRef'book $ ChapterNum verseRef'chapter
  getVerseRangeHandler translation verseRef'book (ChapterNum verseRef'chapter) (VerseNum 1) (VerseNum <$> Just maxVerseNum)



-- | Auxiliary functions
sendAsParts chatId xs = forM_ xs $ \x ->
                let htmlText = TL.toStrict . renderText $ toHtml x
                in sendHtml chatId htmlText

sendHtml :: ChatId -> Text -> Bot ()
sendHtml chatId msg = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId msg (Just HTML) Nothing Nothing Nothing Nothing
    _ <- ($) sendMessage telegramToken request manager
    return ()

sendText :: ChatId -> Text -> Bot ()
sendText chatId msg = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId msg Nothing Nothing Nothing Nothing Nothing
    _ <- ($) sendMessage telegramToken request manager
    return ()

-- | send text with reply keybords
sendTextReplyKb :: ReplyKeyboard -> ChatId -> Text -> Bot ()
sendTextReplyKb keyborad chatId msg = do
    BotConfig{..} <- ask
    let request = SendMessageRequest chatId msg (Just HTML) Nothing Nothing Nothing (Just keyborad)
    res <- ($) sendMessage telegramToken request manager
    liftIO $ putStrLn $ show res
    let id_ = case res of
                Right rm -> message_id $ result rm
                Left e   -> error $ show e
    liftIO $ writeIORef ref id_

    return ()


-- | send text with inline reply keybords
sendTextInlineReplyKb :: InlineKeyboardMarkup  -> ChatId -> Text -> Bot ()
sendTextInlineReplyKb keyboard chatId msg = do
    BotConfig{..} <- ask
    let inlineQuery = InlineQueryResultArticle  "inlineSettingButton"
                                -- ^ Unique identifier for this result
                                (Just "Settings")
                                -- ^ Title of the result
                                (Just $ InputTextMessageContent ("button") Nothing Nothing)
                                -- ^ Content of the message to be sent
                                (Just keyboard)
                                -- ^ Inline keyboard attached to the message
                                Nothing
                                -- ^ URL of the result
                                Nothing
                                -- ^ Pass True, if you don't want the URL to be shown in the message
                                Nothing
                                -- ^ Short description of the result
                                Nothing
                                -- ^ Url of the thumbnail for the result
                                Nothing
                                -- ^ Thumbnail width
                                Nothing
                                -- ^ Thumbnail height

            -- SendMessageRequest chatId msg Nothing Nothing Nothing Nothing (Just keyborad)
        request = AnswerInlineQueryRequest msg [inlineQuery] apiCachTime Nothing Nothing Nothing Nothing
    res <- ($) answerInlineQuery telegramToken request manager
    liftIO $ putStrLn $ show res
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
  _ <- ($) forM_ requests $ (\r -> sendMessage telegramToken r manager)
  return ()



---
buttons0 = replyKeyboardMarkup [[keyboardButton "🎰 Магазин"], [keyboardButton "➕ Добавить бота"]]
buttons0' = inlineKeyboardMarkup [[inlineKeyboardButton "🎰 Магазин"], [inlineKeyboardButton "➕ Добавить бота"]]

cancel_button = replyKeyboardMarkup [[keyboardButton "🅾️ Отмена"]]

category_buttons = replyKeyboardMarkup [[keyboardButton "💰 ТОП Платных", keyboardButton "💥 ТОП Бесплатных"], [keyboardButton "🎮 Игры", keyboardButton "📕 Образование"], [keyboardButton "🚑 Здоровье", keyboardButton "🎶 Музыка"], [keyboardButton "🎲 Другое", keyboardButton "🎯 Спорт"],
                                                                                                                 [keyboardButton "<-"]]

choose_category_buttons = replyKeyboardMarkup [[keyboardButton "🎮 Игры", keyboardButton "📕 Образование"], [keyboardButton "🚑 Здоровье", keyboardButton "🎶 Музыка"], [keyboardButton "🎲 Другое", keyboardButton "🎯 Спорт"],
                                                                                                              [keyboardButton "🅾️ Отмена"]]

bot_type_buttons = ReplyInlineKeyboardMarkup  [[inlineKeyboardButton "Key 1", inlineKeyboardButton "Key 2"], [inlineKeyboardButton "Cancel"]]

in_btn =  ReplyInlineKeyboardMarkup  [[classifyButton, classifyButton1, classifyButton], [classifyButton1, classifyButton], [classifyButton]]

inlineBtns = InlineKeyboardMarkup [ [classifyButton, classifyButton, classifyButton], [classifyButton, classifyButton] ]


classifyButton = InlineKeyboardButton (T.pack "Settings") Nothing (Just "settings#") Nothing Nothing (Just "query") Nothing
classifyButton1 = InlineKeyboardButton (T.pack "Btn _1") Nothing (Just "template#") Nothing Nothing (Just "query") Nothing


