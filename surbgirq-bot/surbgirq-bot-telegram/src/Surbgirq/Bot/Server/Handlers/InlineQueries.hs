{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}

{-|
Module      : Surbgirq.Bot.Server.Handlers.Queries
Description : Handlers for inline and callback  queries

Implement Handlers for telegram queries
-}

module Surbgirq.Bot.Server.Handlers.InlineQueries
    ( handleInlineQuery
    )where

import Control.Monad.Reader
import Lucid

import Data.Char                     (isSpace)
import Data.List                     (intercalate, intersperse)
import Data.Maybe                    (fromMaybe)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Helpers.Pagination
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------
handleInlineQuery :: InlineQuery -> Bot ()
handleInlineQuery iq@InlineQuery{query_from = User{..}, ..} = do
  liftIO $ putStrLn $ "Inline query -> " ++ (show iq)
  onCommand query_query
  cfg <- getUserConfig (UserId user_id)
  liftIO $ putStrLn $  show cfg

  where
    iqId = query_id
    onCommand (T.stripPrefix "/random" -> Just _)   = return ()
    onCommand (T.stripPrefix "read" -> Just verseRef)  = inlineReadVerses (UserId user_id) iqId verseRef
    onCommand (parseVerseRef  -> Right verseRef)    = inlineVerse' (UserId user_id) iqId verseRef
    onCommand (all isSpace . T.unpack   -> True)    = inlineSettings iqId
    onCommand (parseVerseRef  -> Left error)        = liftIO $ print $ T.append "==== Verse Parse Error:    "  error

    onCommand str                                   = do
                                  liftIO $ print $ T.append "=================== Unknown Command\n"  str
                                  return ()

   --  cmdArgs = parseInlineQuery $ query_query iq
--     iqId = query_id iq

--     onCommand = case cmdArgs of
--                     Just (cmd,args) | cmd == "goat" -> inlineAphorisms iqId args False
--                                     | cmd == "verse" -> inlineVerse iqId args
--                                     | cmd == "koza" -> inlineAphorisms iqId args True
--                                     | cmd == "qb" || cmd == "quote" || cmd == "quotebook" -> inlineQuote (return "eligeQuote") iqId args
--                                     | cmd == "qsearch" -> inlineQuoteSearch (\str -> pure "eligeQuoteByHuman") iqId args
-- --                                    | cmd == "its" || cmd == "itemplates" || cmd == "insulttemplates" -> dishITemplates iqId args
--                                     | otherwise -> return ()
--                     Nothing -> return ()

inlineReadVerses :: UserId -> Text -> Text -> Bot ()
inlineReadVerses userId iqId verseRef =
    let res = parseVerseRef verseRef
    in case res of
      Left e     -> liftIO $ putStrLn $ "Error: " ++ (show e)
      Right vRef -> inlineReadVerses' userId iqId vRef

inlineReadVerses' :: UserId -> Text -> VerseReference -> Bot ()
inlineReadVerses' userId iqId verseRef@VerseReference{..} = do
  BotConfig{..} <- ask
  cfg <- getUserConfig  userId
  let def1 = fromMaybe E1994T (readTranslation [config'bible cfg])
      defaultTrans = fromMaybe def1 verseRef'translation

  vs <- liftIO $ getVerses defaultTrans verseRef

  let
      currentPage = fromMaybe 1 verseRef'from
      buttons = prevNextPageBtns currentPage 20 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]
      verseNum = fromMaybe 1 verseRef'from
      verseToShow = case  filter ((== verseNum) . snd) $ zip vs [1..]  of
                      [(v, _)] -> v
                      []       -> error "Error: there are no verses to select one."
                      _        -> vs!!0

      verseHtml = TL.toStrict . renderText $ (toHtml verseToShow <> toHtml verseRef)


      miKtorovInlineQueryResults = [InlineQueryResultArticle (toId verseRef)
                                                             -- ^ Unique identifier for this result
                                                             (Just $ toRefText defaultTrans verseRef)
                                                             -- ^ Title of the result
                                                             -- (Just $ InputTextMessageContent (html2Text' verse vRef) (Just HTML) Nothing)
                                                             (Just $ InputTextMessageContent verseHtml (Just HTML) Nothing)
                                                             -- ^ Content of the message to be sent
                                                             (Just $ InlineKeyboardMarkup buttons)
                                                             -- ^ Inline keyboard attached to the message
                                                             Nothing
                                                             -- ^ URL of the result
                                                             Nothing
                                                             -- ^ Pass True, if you don't want the URL to be shown in the message
                                                             (Just $ T.take 100 $  html2Text' verseToShow verseRef)
                                                             -- ^ Short description of the result
                                                             Nothing
                                                             -- ^ Url of the thumbnail for the result
                                                             Nothing
                                                             -- ^ Thumbnail width
                                                             Nothing
                                                             -- ^ Thumbnail height
                                   ]
      request = AnswerInlineQueryRequest iqId miKtorovInlineQueryResults apiCachTime Nothing Nothing Nothing Nothing

  res <- ($) answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()
  where
    -- html2Text = TL.toStrict . renderText . toHtml
    html2Text' a b = TL.toStrict . renderText $ (toHtml a <> toHtml b)


inlineVerse :: UserId -> Text -> [String] -> Bot ()
inlineVerse userId iqId args = do
  let arg = intercalate " " args
      vRef = parseVerseRef $ T.pack arg
  case vRef of
    Left e ->  do
              _ <- liftIO $ putStrLn $ "Verse Reference parse error: " ++ (show e)
              return ()
    Right vRef -> inlineVerse' userId iqId vRef

inlineVerse' :: UserId -> Text -> VerseReference -> Bot ()
inlineVerse' userId iqId verseRef@VerseReference{..} = do
  BotConfig{..} <- ask
  cfg <- getUserConfig  userId
  let def1 = fromMaybe E1994T (readTranslation [config'bible cfg])
      defaultTrans = fromMaybe def1 verseRef'translation

  vs <- liftIO $ getVerses defaultTrans verseRef
         -- liftIO $ case verseRef'to of
         --     Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum <$> verseRef'from)
         --     Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)
  _ <- liftIO $ putStrLn $ "Inline Ref: " ++ (show verseRef)

  let inlineQueryResults = map (\(verse, vRef) ->
                                    InlineQueryResultArticle (toId vRef)
                                                             -- ^ Unique identifier for this result
                                                             (Just $ toRefText defaultTrans vRef)
                                                             -- ^ Title of the result
                                                             (Just $ InputTextMessageContent (html2Text' verse vRef) (Just HTML) Nothing)
                                                             -- ^ Content of the message to be sent
                                                             Nothing
                                                             -- ^ Inline keyboard attached to the message
                                                             Nothing
                                                             -- ^ URL of the result
                                                             Nothing
                                                             -- ^ Pass True, if you don't want the URL to be shown in the message
                                                             (Just $ T.take 50 . T.drop 10 $  html2Text  verse)
                                                             -- ^ Short description of the result
                                                             Nothing
                                                             -- ^ Url of the thumbnail for the result
                                                             Nothing
                                                             -- ^ Thumbnail width
                                                             Nothing
                                                             -- ^ Thumbnail height
                                                              ) (zip vs (verseRefRange verseRef))


      miKtorovInlineQueryResults = [InlineQueryResultArticle (toId verseRef)
                                                             -- ^ Unique identifier for this result
                                                             (Just $ toRefText defaultTrans verseRef)
                                                             -- ^ Title of the result
                                                             -- (Just $ InputTextMessageContent (html2Text' verse vRef) (Just HTML) Nothing)
                                                             (Just $ InputTextMessageContent (html2Text' vs verseRef) (Just HTML) Nothing)

                                                             -- ^ Content of the message to be sent
                                                             Nothing
                                                             -- ^ Inline keyboard attached to the message
                                                             Nothing
                                                             -- ^ URL of the result
                                                             Nothing
                                                             -- ^ Pass True, if you don't want the URL to be shown in the message
                                                             (Just $ T.take 100 $  html2Text' vs verseRef)
                                                             -- ^ Short description of the result
                                                             Nothing
                                                             -- ^ Url of the thumbnail for the result
                                                             Nothing
                                                             -- ^ Thumbnail width
                                                             Nothing
                                                             -- ^ Thumbnail height
                                   ]
      request = case verseRef'combine of
                  True  -> AnswerInlineQueryRequest iqId miKtorovInlineQueryResults apiCachTime Nothing Nothing Nothing Nothing
                  False -> AnswerInlineQueryRequest iqId inlineQueryResults apiCachTime Nothing Nothing Nothing Nothing
  res <- ($) answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()
  where
    html2Text = TL.toStrict . renderText . toHtml
    html2Text' a b = TL.toStrict . renderText $ (toHtml a <> toHtml b)

--    miKtorov = TL.toStrict . renderText . toHtml






-- | Inline Settings
inlineSettings :: Text -> Bot ()
inlineSettings iqId = do
  BotConfig{..} <- ask
  liftIO $ putStrLn "space command"
  let settingsButton = InlineKeyboardButton (T.pack "Settings-1") Nothing (Just "settings#") Nothing Nothing Nothing Nothing
      keyboard = InlineKeyboardMarkup [ [settingsButton { ikb_url = Just "http://telegram.me/surbgirqbot" }
                                        ] ]
      inlineSettingResult = InlineQueryResultArticle  "inlineSettingButton"
                                -- ^ Unique identifier for this result
                                (Just "Settings")
                                -- ^ Title of the result
                                (Just $ InputTextMessageContent ("Settings for Surbgirq bot:") Nothing Nothing)
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

      request = AnswerInlineQueryRequest iqId [] -- [inlineSettingResult]
                                              apiCachTime Nothing Nothing  (Just "Settings") ( Just "settings")
  res <- ($) answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()



