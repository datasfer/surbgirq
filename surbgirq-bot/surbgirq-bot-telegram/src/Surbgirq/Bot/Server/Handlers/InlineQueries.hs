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
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types

import Surbgirq.Bot.Server.Helpers


import Surbgirq.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------

handleInlineQuery :: InlineQuery -> Bot ()
handleInlineQuery iq@InlineQuery{query_from = User{..}, ..} = do
  liftIO $ putStrLn $ "Inline query -> " ++ (show iq)
  let query = if T.length query_offset > 0
              then query_offset
              else query_query
  onCommand query
  cfg@UserSettings{..} <- getUserConfig (UserId user_id)
  liftIO $ putStrLn $  show cfg

  where
    onCommand (T.stripPrefix "/random" -> Just _)      = return ()
    onCommand (T.stripPrefix "read" -> Just verseRef)  = inlineReadVerses (UserId user_id) query_id verseRef
--    onCommand (readGirqs  -> Just (girq , trans))     = inlineChapter (UserId user_id) query_id (girq, trans)
    onCommand (parseVerseRef  -> Right verseRef)       = inlineVerse (UserId user_id) query_id verseRef
    onCommand (all isSpace . T.unpack   -> True)       = inlineSettings query_id
    onCommand (parseVerseRef  -> Left error)           = liftIO $ print $ T.append "==== Verse Parse Error:    "  error

    onCommand str                                      = do
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


-- | inline read block with next prev buttons navigating withing verse
-- command syntax
-- > read Narek 1
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
  let def1 = getCfgTranslation cfg verseRef'book
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

      request = AnswerInlineQueryRequest iqId miKtorovInlineQueryResults apiCachTime Nothing (Just "Narek 1 20 30") Nothing Nothing

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



-- | list inline verses user can choose one to post
-- Narek 1 # will show all verse in chapter 1
-- Narek 1 5 # will show all verses starting from 5 in chapter 1
-- Narek 1 1 10 # will list all vers in chapter 1 from 1 to 10
-- Narek 1 1:10 # will combine verses 1 till 10 in one peace
-- Narek 1 1-10 # will combine verses 1 till 10 in one peace

-- inlineVerse' :: UserId -> Text -> [String] -> Bot ()
-- inlineVerse' userId iqId args = do
--   let arg = intercalate " " args
--       vRef = parseVerseRef $ T.pack arg
--   case vRef of
--     Left e ->  do
--               _ <- liftIO $ putStrLn $ "Verse Reference parse error: " ++ (show e)
--               return ()
--     Right vRef -> inlineVerse' userId iqId vRef

inlineVerse :: UserId -> Text -> VerseReference -> Bot ()
inlineVerse userId iqId verseRef@VerseReference{..} = do
  BotConfig{..} <- ask
  cfg <- getUserConfig  userId
  let def1 = getCfgTranslation cfg verseRef'book
      defaultTrans = fromMaybe def1 verseRef'translation
      offset@(queryRef, queryOffsetTxt) = toOffset 50 verseRef
  vs <- liftIO $ getVerses defaultTrans queryRef
         -- liftIO $ case verseRef'to of
         --     Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum <$> verseRef'from)
         --     Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)
  _ <- liftIO $ putStrLn $ ">====== Inline Ref: " ++ (show verseRef)
  _ <- liftIO $ putStrLn $ ">====== Offset Ref: " ++ (show offset)

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
                                                             -- (Just $ T.take 50 . T.drop 10 $  html2Text  verse)
                                                             (Just $ html2Text  verse)
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
                                                             (Just $ T.take 500 $  html2Text' vs verseRef)
                                                             -- ^ Short description of the result
                                                             Nothing
                                                             -- ^ Url of the thumbnail for the result
                                                             Nothing
                                                             -- ^ Thumbnail width
                                                             Nothing
                                                             -- ^ Thumbnail height
                                   ]
      request = case verseRef'combine of
                  True  -> AnswerInlineQueryRequest iqId miKtorovInlineQueryResults apiCachTime Nothing queryOffsetTxt Nothing Nothing
                  False -> AnswerInlineQueryRequest iqId inlineQueryResults apiCachTime Nothing queryOffsetTxt Nothing Nothing
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



-------------------------------------------------------------------------------
-- Chapter list
-------------------------------------------------------------------------------
inlineChapter :: UserId -> Text -> (Girq, TranslationID)  -> Bot ()
inlineChapter userId iqId (girq, trans) = do
  BotConfig{..} <- ask
  cfg <- getUserConfig  userId
  let def1 = getCfgTranslation cfg girq
      defaultTrans = trans
      verseRef = VerseReference (Just trans)  girq 1 Nothing Nothing True
      offset@(queryRef, queryOffsetTxt) = toOffset 50 verseRef
  vs <- liftIO $ getChapterVerses defaultTrans queryRef

  _ <- liftIO $ putStrLn $ "Inline Ref: " ++ (show verseRef)
  _ <- liftIO $ putStrLn $ "Offset Ref: " ++ (show offset)

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
                                                             -- (Just $ T.take 50 . T.drop 10 $  html2Text  verse)
                                                             (Just $ html2Text  verse)
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
                                                             (Just $ T.take 500 $  html2Text' vs verseRef)
                                                             -- ^ Short description of the result
                                                             Nothing
                                                             -- ^ Url of the thumbnail for the result
                                                             Nothing
                                                             -- ^ Thumbnail width
                                                             Nothing
                                                             -- ^ Thumbnail height
                                   ]
      request = case verseRef'combine verseRef of
                  True  -> AnswerInlineQueryRequest iqId miKtorovInlineQueryResults apiCachTime Nothing queryOffsetTxt Nothing Nothing
                  False -> AnswerInlineQueryRequest iqId inlineQueryResults apiCachTime Nothing queryOffsetTxt Nothing Nothing
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



