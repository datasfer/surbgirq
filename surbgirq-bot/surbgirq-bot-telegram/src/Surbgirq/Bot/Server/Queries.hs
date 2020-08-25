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
import Data.Set                      (Set)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import Data.IORef


import qualified Data.Set       as Set
import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Lucid

import Control.Concurrent.STM
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
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils

import Surbgirq.Bot.Server.Pagination
import Surbgirq.Bot.ShopBotExample
------------------------------------------------------------
--
------------------------------------------------------------

-- InlineQuery {query_id = "1096629775692860954", query_from = User {user_id = 255329016, user_is_bot = False,
-- user_first_name = "arthur", user_last_name = Nothing, user_username = Just "arthurvard",
-- user_language_code = Just
-- (LanguageCode "en")}, query_location = Nothing, query_query = "Mat", query_offset = ""}
handleInlineQuery :: InlineQuery -> Bot ()
handleInlineQuery iq@InlineQuery{query_from = User{..}, ..} = do
--   liftIO $ putStrLn $ "inline query args -> " ++ (show cmdArgs)
  liftIO $ putStrLn $ "Inline query -> " ++ (show iq)
  onCommand query_query
  cfg <- getUserConfig (UserId user_id)
  liftIO $ putStrLn $  show cfg
  where
    iqId = query_id
    onCommand (T.stripPrefix "/random" -> Just _)   = return ()
    onCommand (parseVerseRef  -> Right verseRef)    = inlineVerse' iqId verseRef
    onCommand (all isSpace . T.unpack   -> True)    = inlineSettings iqId
    onCommand str                                   = do
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
handleCallbackQuery cqy@CallbackQuery{cq_from = User{..},..} = do
  BotConfig{..} <- ask
  liftIO $ putStrLn [qc|=========== callback Query {cqy}|]
  cfg <- getUserConfig (UserId user_id)
  let  lang = config'menuLanguage cfg
  liftIO $ putStrLn [qc|=========== User settings {cfg}|]

  maybe (return ()) (onCommand cfg) cq_data

  where
      cqId = cq_id
      userId = UserId user_id
      msg_id = maybe 0 message_id cq_message

      chatId = case cq_message of
        Just cqMessage -> ChatId $ chat_id $ chat cqMessage
        Nothing        -> ChatId $ fromIntegral $ user_id

      onCommand cfg (T.stripPrefix "settings#" -> Just _) = editRespuesta chatId msg_id "Settings for surbgirq bot" $ Just (settingsKeyboardMarkup (config'menuLanguage cfg))
      -- onCommand (T.stripPrefix "subscribe-bible#" -> Just _) = editRespuesta chatId msg_id "Parallel bible reading setting" $ Just parallelsKeyboardMarkup
      -- onCommand (T.stripPrefix "languages#" -> Just _) = editRespuesta chatId msg_id "Set default Language" $ Just languagesKeyboardMarkup
      -- onCommand (T.stripPrefix "dialects#" -> Just _) = editRespuesta chatId msg_id "Choose Dialect" $ Just dialectsKeyboardMarkup

      -- | Bible Menu click
      onCommand cfg (T.stripPrefix "bibles#" -> Just _) =
          editRespuesta chatId msg_id "Bibles" $ Just (biblesKeyboardMarkup $ config'bible cfg)
      --  sub menu items of bile menu -  handler
      onCommand cfg (T.stripPrefix "bibleItem#" -> Just arg) = do

          let bibleName = T.strip arg
              cfg' = cfg { config'bible = bibleName }
          us <- modifyUserConfig userId cfg'

          liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'} - returned {us}|]
          liftIO $ putStrLn [qc|=========== modifed settings user: {bibleName} |]
          editRespuesta chatId msg_id [qc|Bibles - choosed {bibleName}|] $ Just (biblesKeyboardMarkup bibleName)


      onCommand cfg (T.stripPrefix "parallel-armBible#" -> Just _) = editRespuesta chatId msg_id "Parallel Armenian Bibles config" $ Just armBiblesKeyboardMarkup
      onCommand cfg (T.stripPrefix "ruBible#" -> Just _) = editRespuesta chatId msg_id "Russian Bibles" $ Just ruBiblesKeyboardMarkup
      onCommand cfg (T.stripPrefix "parallel-ruBible#" -> Just _) = editRespuesta chatId msg_id "Arm Bible translations" $ Just ruBiblesKeyboardMarkup
      onCommand cfg (T.stripPrefix "enBible#" -> Just _) = editRespuesta chatId msg_id "Arm Bible translations" $ Just enBiblesKeyboardMarkup
      onCommand cfg (T.stripPrefix "parallel-enBible#" -> Just _) = editRespuesta chatId msg_id "Arm Bible translations" $ Just enBiblesKeyboardMarkup
      onCommand cfg (T.stripPrefix "narek#" -> Just _) = editRespuesta chatId msg_id "Arm Bible translations" $ Just nareksKeyboardMarkup

      onCommand cfg (T.stripPrefix "parallelNarek#" -> Just _) = editRespuesta chatId msg_id "Parallel Narek config" $ Just parallelNareksKeyboardMarkup
      onCommand cfg (T.stripPrefix "parallelBible#" -> Just _) = editRespuesta chatId msg_id "Parallel Narek config" $ Just (parallelBiblesKeyboardMarkup $ config'parallelBibles cfg)
      onCommand cfg (T.stripPrefix "parallelBibleItem#" -> Just arg) = do
          let bibleName = T.strip arg
              biblesSet = config'parallelBibles cfg

              pSet = if Set.member bibleName biblesSet
                     then Set.delete bibleName biblesSet
                     else Set.insert bibleName biblesSet
              cfg' = cfg { config'parallelBibles = pSet }
          us <- modifyUserConfig userId cfg'

          liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'} - returned {us}|]
          liftIO $ putStrLn [qc|=========== modifed settings user: {bibleName} |]
          editRespuesta chatId msg_id [qc|Parallel Bibles - choosed {pSet}|] $ Just (parallelBiblesKeyboardMarkup pSet)

      -- Menu language
      onCommand cfg (T.stripPrefix "menu-amlang#" -> Just _) = do
        let cfg' = cfg {config'menuLanguage = AM}
        modifyUserConfig userId cfg'
        liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'}|]
        tvar <- asks state
        st <- liftIO $ readTVarIO tvar

        liftIO $ putStrLn [qc|=========== Bot Config {st}|]

        editRespuesta chatId msg_id "Arm Settings for surbgirq bot" $ Just amSettingsKeyboardMarkup
      onCommand cfg (T.stripPrefix "menu-enlang#" -> Just _) = do
        let cfg' = cfg { config'menuLanguage = EN }
        modifyUserConfig userId cfg'
        editRespuesta chatId msg_id "Settings for surbgirq bot" $ Just (settingsKeyboardMarkup EN)

      -- Pagination btn callbacks

      onCommand cfg (T.stripPrefix "go_to_verseRef#" -> Just args) = do
        case parseVerseRef args of
          Right verseRef@VerseReference{..} -> do
            vs <- liftIO $ getVerse' chatId verseRef
            let verseHtml = TL.toStrict . renderText $ (toHtml vs <> toHtml verseRef)

            liftIO $ putStrLn $ show verseRef

            let currentPage = fromMaybe 1 verseRef'from
                buttons = prevNextPageBtns currentPage 24 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]
                -- buttons = generatePageBtns 0 page 12 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]

            liftIO $ print buttons

            editRespuesta chatId msg_id [qc|{verseHtml}|] $ Just $ InlineKeyboardMarkup buttons

          Left e         -> error $ " failed parse verse in pagination " ++ show e


      onCommand cfg (T.stripPrefix "go_to#" -> Just args) = do

        let all@(x:y:_) = T.splitOn " " $ T.strip args
        liftIO $ putStrLn [qc|=========== Args {all}|]

        let page = read (T.unpack y) :: Int
            buttons = generatePageBtns 0 page 12 "go_to#" "args"
        liftIO $ putStrLn [qc|=========== Page {page}|]
        liftIO $ putStrLn [qc|=========== Page {page}|]

        editRespuesta chatId msg_id [qc|Pagination  {page} bible subscribtion is currently <b>enabled</b>|] $ Just $ InlineKeyboardMarkup buttons --  subscriptionKeyboardMarkup

      onCommand cfg (T.stripPrefix "subscribe-bible#" -> Just _) = do
        tvar <- asks state
        st <- liftIO $ readTVarIO tvar

        liftIO $ putStrLn [qc|=========== Bot Config {st}|]
--        buttons <- liftIO $ inline_page_buttons "category" 0
        let buttons = generatePageBtns 0 1 12 "go_to#" "args"
        editRespuesta chatId msg_id "Daily bible subscribtion is currently <b>enabled</b>" $ Just $ InlineKeyboardMarkup buttons --  subscriptionKeyboardMarkup

      -- onCommand (T.stripPrefix "template#" -> Just tName) = do
      --   let insult = "<- liftIO $ insultTemplate (T.unpack tName) >>= evalInsult"
      --   respuesta chatId telegramToken manager insult
      -- onCommand (T.stripPrefix "wordgroup#" -> Just wgName) = do
      --   let ws = ["liftIO $ wordGroupWords", "(T.unpack wgName)"]
      --   respuesta chatId telegramToken manager $ concat $ intersperse ", " ws
      onCommand _ _                                    = return ()


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

editRespuesta :: ChatId -> Int -> String -> Maybe InlineKeyboardMarkup -> Bot ()
editRespuesta chatId  msgId msg keyborad = do
  BotConfig{..} <- ask
 -- msgId <- liftIO $ readIORef ref
  liftIO $ putStrLn $ show msgId

  let request = EditMessageTextRequest (Just chatId) (Just msgId) Nothing (T.pack msg)
                (Just HTML)
                Nothing keyborad
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
                                              (Just 1) Nothing Nothing  (Just "Settings") ( Just "settings")
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
