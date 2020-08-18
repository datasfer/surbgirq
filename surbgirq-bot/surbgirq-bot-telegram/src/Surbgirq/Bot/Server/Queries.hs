{-# LANGUAGE AllowAmbiguousTypes        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE ViewPatterns               #-}

{-|
Module      : Surbgirq.Bot.Server.Queries
Description : Handlers for inline and callback  queries

Implement Handlers for telegram queries
-}

module Surbgirq.Bot.Server.Queries where


import Control.Monad                 (replicateM)
import Data.Char                     (isNumber)
import Data.Char                     (isSpace)
import Data.List                     (intercalate, intersperse)
import Data.List                     (intercalate, intersperse)
import Data.List.Split               (chunksOf)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import Data.IORef


import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Lucid

import Control.Monad.Except
import Control.Monad.Reader
import Data.Aeson
import Data.Maybe
import Data.Monoid
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.Server
import System.Environment
import Text.Regex.Posix
import Web.Telegram.API.Bot
import Web.Telegram.API.Bot.API.Edit


import Surbgirq.Bot.ClientRequests
import Surbgirq.Bot.Help
import Surbgirq.Bot.Lucid.Instances
import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Server.SettingsInline
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils


------------------------------------------------------------
--
------------------------------------------------------------


handleInlineQuery :: InlineQuery -> Bot ()
handleInlineQuery iq = do
  let iqId = query_id iq
--   liftIO $ putStrLn $ "inline query args -> " ++ (show cmdArgs)
  liftIO $ putStrLn $ "Inline query -> " ++ (show iq)
  onCommand $ query_query iq

  where
    iqId = query_id iq
    onCommand (T.stripPrefix "/random" -> Just _)      = return ()
    onCommand (parseVerseRef  -> Right verseRef)        = inlineVerse' iqId verseRef
    onCommand (all isSpace . T.unpack   -> True)                       = inlineSettings iqId
    onCommand str                                      = do
                                  liftIO $ print $ T.append "=================== Unknown Command"  str
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


handleCallbackQuery :: CallbackQuery -> Bot ()
handleCallbackQuery CallbackQuery{..} = do
  BotConfig{..} <- ask
  case cq_data of
    Just tc -> onCommand tc
    Nothing -> return ()

  where
      cqId = cq_id
      Just cqMessage = cq_message
      chatId = case cq_message of
        Just cqMessage -> ChatId $ chat_id $ chat cqMessage
        Nothing        -> ChatId $ fromIntegral $ user_id cq_from

      onCommand (T.stripPrefix "settings#" -> Just _) = editRespuesta chatId "Settings for surbgirq bot" $ Just settingsKeyboardMarkup
      onCommand (T.stripPrefix "parallel-langs#" -> Just _) = editRespuesta chatId "Parallel bible reading setting" $ Just parallelsKeyboardMarkup
      onCommand (T.stripPrefix "languages#" -> Just _) = editRespuesta chatId "Set default Language" $ Just languagesKeyboardMarkup
      onCommand (T.stripPrefix "dialects#" -> Just _) = editRespuesta chatId "Choose Dialect" $ Just dialectsKeyboardMarkup

      -- onCommand (T.stripPrefix "template#" -> Just tName) = do
      --   let insult = "<- liftIO $ insultTemplate (T.unpack tName) >>= evalInsult"
      --   respuesta chatId telegramToken manager insult
      -- onCommand (T.stripPrefix "wordgroup#" -> Just wgName) = do
      --   let ws = ["liftIO $ wordGroupWords", "(T.unpack wgName)"]
      --   respuesta chatId telegramToken manager $ concat $ intersperse ", " ws
      onCommand _                                     = return ()


respuesta :: ChatId -> String -> Maybe ReplyKeyboard -> Bot ()
respuesta chatId  msg keyborad = do
  BotConfig{..} <- ask
  let request = SendMessageRequest chatId (T.pack msg) Nothing Nothing Nothing Nothing keyborad
  res <- ($) liftIO $ sendMessage telegramToken request manager
  liftIO $ putStrLn "response: --------------------"
  liftIO $ putStrLn $ show res

  let id_ = case res of
              Right rm -> message_id $ result rm
              Left e   -> error $ show e
  liftIO $ writeIORef ref id_
  return ()

editRespuesta :: ChatId -> String -> Maybe InlineKeyboardMarkup -> Bot ()
editRespuesta chatId  msg keyborad = do
  BotConfig{..} <- ask
  msgId <- liftIO $ readIORef ref
  liftIO $ putStrLn $ show msgId

  let request = EditMessageTextRequest (Just chatId) (Just msgId) Nothing (T.pack msg) Nothing Nothing keyborad
  res <- ($) liftIO $ editMessageText telegramToken request manager
  liftIO $ putStrLn $ show res
  let id_ = case res of
              Right rm -> message_id $ result rm
              Left e   -> error $ show e
  liftIO $ putStrLn $ show id_
  liftIO $ writeIORef ref id_
  return ()


-- | Helpers
parseInlineQuery :: Text -> Maybe (String,[String])
parseInlineQuery textQuery = do
  let stringQuery = (T.unpack textQuery) :: String
      re = "\\w+" :: String
      argsList = getAllTextMatches $ (stringQuery =~ re :: AllTextMatches [] String)
  if null argsList then Nothing else Just (head argsList, tail argsList)


inlineAphorisms :: Text -> [String] -> Bool -> Bot ()
inlineAphorisms iqId args askToClassify = do
  BotConfig{..} <- ask
  let n = if null args then 5 else read $ head args
  sentences <- liftIO $ replicateM n (return "eligeSentenceFromBlog")
  sentences <- liftIO $ replicateM n (return "eligeSentenceFromBlog")

  -- _ <- liftIO $ putStrLn (show sentences)
  -- _ <- liftIO $ hashUm sentences

  let classifyButton = InlineKeyboardButton (T.pack "classify aphorism") Nothing (Just "settings#") Nothing Nothing Nothing Nothing
      keyboard = InlineKeyboardMarkup [ [classifyButton] ]
      inlineQueryResults = map (\(a,idx) -> InlineQueryResultArticle (T.pack $ "aphorism" ++ show idx) (Just $ T.pack $ "aphorism #" ++ show idx) (Just $ InputTextMessageContent (T.pack a) Nothing Nothing) (if askToClassify then (Just keyboard) else Nothing) Nothing Nothing (Just $ T.pack a) Nothing Nothing Nothing) (zip sentences [1..n])
      request = AnswerInlineQueryRequest iqId inlineQueryResults (Just 1) Nothing Nothing Nothing Nothing
  res <- ($) liftIO $ answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()

inlineQuoteSearch :: (String -> IO String) -> Text -> [String] -> Bot ()
inlineQuoteSearch qFn iqId args = if null args then return () else inlineQuote (qFn $ head args) iqId (tail args)

inlineQuote :: IO String -> Text -> [String] -> Bot ()
inlineQuote qFn iqId args = do
  BotConfig{..} <- ask
  let n = if null args then 3 else (read . head) args
  quotes <- liftIO $ replicateM n qFn
  let inlineQueryResults = map (\(a,idx) ->
                                    InlineQueryResultArticle (T.pack $ "quote" ++ show idx)
                                                             (Just $ T.pack $ "quote #" ++ show idx)
                                                             (Just $ InputTextMessageContent (T.pack a) Nothing Nothing) Nothing Nothing Nothing (Just $ T.pack a) Nothing Nothing Nothing) (zip quotes [1..n])
      request = AnswerInlineQueryRequest iqId inlineQueryResults (Just 1) Nothing Nothing Nothing Nothing
  res <- ($) liftIO $ answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()




-- | Surbgirq inline queries


inlineVerse :: Text -> [String] -> Bot ()
inlineVerse iqId args = do
  let arg = intercalate " " args
      vRef = parseVerseRef $ T.pack arg
  case vRef of
    Left e ->  do
              _ <- liftIO $ putStrLn $ "Verse Reference parse error: " ++ (show e)
              return ()
    Right vRef -> inlineVerse' iqId vRef


inlineSettings :: Text -> Bot ()
inlineSettings iqId = do
  BotConfig{..} <- ask
  liftIO $ putStrLn "space command"
  let settingsButton = InlineKeyboardButton (T.pack "Settings") Nothing (Just "settings#") Nothing Nothing Nothing Nothing
      keyboard = InlineKeyboardMarkup [ [settingsButton --  { ikb_url = Just "http://telegram.me/surbgirqbot" }
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

      request = AnswerInlineQueryRequest iqId [inlineSettingResult] (Just 1) Nothing Nothing Nothing Nothing
  res <- ($) liftIO $ answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()



inlineVerse' :: Text -> VerseReference -> Bot ()
inlineVerse' iqId verseRef@VerseReference{..} = do
  BotConfig{..} <- ask
  vs <- liftIO $ getVerses Ashxarhabar verseRef
         -- liftIO $ case verseRef'to of
         --     Nothing -> getOneVerseHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum <$> verseRef'from)
         --     Just v  -> getVerseRangeHandler Ashxarhabar verseRef'book (ChapterNum verseRef'chapter) (VerseNum verseRef'from) (VerseNum <$> Just v)

  let inlineQueryResults = map (\(verse, vRef) ->
                                    InlineQueryResultArticle (toId vRef)
                                                             -- ^ Unique identifier for this result
                                                             (Just $ T.pack $ show vRef)
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
      request = AnswerInlineQueryRequest iqId inlineQueryResults (Just 1) Nothing Nothing Nothing Nothing
  res <- ($) liftIO $ answerInlineQuery telegramToken request manager
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
