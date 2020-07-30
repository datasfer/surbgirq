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
import Data.List                     (intercalate, intersperse)
import Data.List.Split               (chunksOf)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

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

import Surbgirq.Bot.Help
import Surbgirq.Bot.Lucid.Instances
import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils



------------------------------------------------------------
--
------------------------------------------------------------


handleInlineQuery :: InlineQuery -> Bot ()
handleInlineQuery iq = do
  let cmdArgs = parseInlineQuery $ query_query iq
      iqId = query_id iq

      onCommand = case cmdArgs of
                    Just (cmd,args) | cmd == "goat" -> inlineAphorisms iqId args False
                                    | cmd == "koza" -> inlineAphorisms iqId args True
                                    | cmd == "qb" || cmd == "quote" || cmd == "quotebook" -> inlineQuote (return "eligeQuote") iqId args
                                    | cmd == "qsearch" -> inlineQuoteSearch (\str -> pure "eligeQuoteByHuman") iqId args
--                                    | cmd == "its" || cmd == "itemplates" || cmd == "insulttemplates" -> dishITemplates iqId args
                                    | otherwise -> return ()
                    Nothing -> return ()
  liftIO $ putStrLn $ "inline query args -> " ++ (show cmdArgs)
  liftIO $ putStrLn $ "Inline query -> " ++ (show iq)
  onCommand


handleCallbackQuery :: CallbackQuery -> Bot ()
handleCallbackQuery cbq = do
  BotConfig{..} <- ask
  let cqId = cq_id cbq
      Just cqMessage = cq_message cbq
      chatId = ChatId $ chat_id $ chat cqMessage
      tCommand = cq_data cbq

      respuesta :: ChatId -> Token -> Manager -> String -> Bot ()
      respuesta chatId telegramToken manager details = do
        let request = SendMessageRequest chatId (T.pack details) Nothing Nothing Nothing Nothing Nothing
        res <- ($) liftIO $ sendMessage telegramToken request manager
        return ()

      onCommand (T.stripPrefix "template#" -> Just tName) = do
        let insult = "<- liftIO $ insultTemplate (T.unpack tName) >>= evalInsult"
        respuesta chatId telegramToken manager insult
      onCommand (T.stripPrefix "wordgroup#" -> Just wgName) = do
        let ws = ["liftIO $ wordGroupWords", "(T.unpack wgName)"]
        respuesta chatId telegramToken manager $ concat $ intersperse ", " ws
      onCommand _ = return ()

  case tCommand of
    Just tc -> onCommand tc
    Nothing -> return ()



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

  let classifyButton = InlineKeyboardButton (T.pack "classify aphorism") Nothing (Just "classify") Nothing Nothing Nothing Nothing
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
  let inlineQueryResults = map (\(a,idx) -> InlineQueryResultArticle (T.pack $ "quote" ++ show idx) (Just $ T.pack $ "quote #" ++ show idx) (Just $ InputTextMessageContent (T.pack a) Nothing Nothing) Nothing Nothing Nothing (Just $ T.pack a) Nothing Nothing Nothing) (zip quotes [1..n])
      request = AnswerInlineQueryRequest iqId inlineQueryResults (Just 1) Nothing Nothing Nothing Nothing
  res <- ($) liftIO $ answerInlineQuery telegramToken request manager
  case res of
    Left e -> do
      _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
      return ()
    Right r -> do
      _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
      return ()

