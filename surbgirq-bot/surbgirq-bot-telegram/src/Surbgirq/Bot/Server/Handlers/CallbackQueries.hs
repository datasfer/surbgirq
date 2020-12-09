{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}

{-|
Module      : Surbgirq.Bot.Server.Handlers.CallbackQueries
Description : Handlers for inline and callback  queries

Implement Handlers for telegram queries
-}

module Surbgirq.Bot.Server.Handlers.CallbackQueries
    ( handleCallbackQuery
    ) where


import Data.IORef
import Lucid

import Control.Concurrent.STM        (readTVarIO)
import Control.Monad                 (void)
import Control.Monad.Reader          (ask, asks, liftIO)
import Data.Maybe                    (fromMaybe)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Set       as Set
import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Helpers.HelpMessages
import Surbgirq.Bot.Server.Helpers.Pagination
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

handleCallbackQuery :: CallbackQuery -> Bot ()
handleCallbackQuery cbq@CallbackQuery{cq_from = User{..},..} = do
  BotConfig{..} <- ask
  liftIO $ putStrLn [qc|=========== callback Query {cbq}|]
  cfg <- getUserConfig (UserId user_id)
  let  lang = config'menuLanguage cfg
  liftIO $ putStrLn [qc|=========== User settings {cfg}|]

  maybe (return ()) (onCommand cfg) cq_data

  where
      cqId = cq_id
--      lang = EN
      userId = UserId user_id
      msg_id = maybe 0 message_id cq_message

      chatId = case cq_message of
        Just cqMessage -> ChatId $ chat_id $ chat cqMessage
        Nothing        -> ChatId $ fromIntegral $ user_id

      -- | Back button - Go back to Settings button handler
      onCommand cfg (T.stripPrefix "goBackToSettings#" -> Just _) = do
          editRespuesta chatId msg_id "Settings for surbgirq bot" $
                        Just (settingsKeyboardMarkup (config'menuLanguage cfg))
          showToolTip cqId $ Just "Settings Main Menu"

      -- | Top Menu Item Handlers
      onCommand cfg (T.stripPrefix "bibles#" -> Just _) = do
        BotConfig{..} <- ask
        let  lang = config'menuLanguage cfg
             title = T.unpack $ i18n lang BiblesTile
        editRespuesta chatId msg_id title $ Just (biblesKeyboardMarkup lang $ config'bible cfg)
        showToolTip cqId Nothing


      onCommand cfg (T.stripPrefix "narek#" -> Just _) = do
          let  lang = config'menuLanguage cfg
               title = T.unpack $ i18n lang NarekTitle
          editRespuesta chatId msg_id title $ Just (nareksKeyboardMarkup lang $ config'narek cfg)
          showToolTip cqId $ Just "Narek's books Sub Menu"

      onCommand cfg (T.stripPrefix "parallelNarek#" -> Just _) = do
          let  lang = config'menuLanguage cfg
               title = T.unpack $ i18n lang ParallelNarekTitle
          editRespuesta chatId msg_id title $ Just (parallelNareksKeyboardMarkup lang $ config'parallelNarek cfg)
          showToolTip cqId $ Just "Parallel Narek's books Sub Menu"

      onCommand cfg (T.stripPrefix "parallelBible#" -> Just _) = do
        cfg <- getUserConfig (UserId user_id)
        let  lang = config'menuLanguage cfg
             title = T.unpack $ i18n lang ParallelBibleTitle

        editRespuesta chatId msg_id  title $ Just (parallelBiblesKeyboardMarkup lang $ config'parallelBibles cfg)
        showToolTip cqId $ Just "Parallel Bibles Sub Menu"

      onCommand cfg (T.stripPrefix "subscribe-dailybible#" -> Just _) = do
        BotConfig{..} <- ask

        -- tvar <- asks state
        -- st <- liftIO $ readTVarIO tvar
        -- liftIO $ putStrLn [qc|=========== Bot Config {st}|]
--        buttons <- liftIO $ inline_page_buttons "category" 0
        let buttons = generatePageBtns 0 1 12 "go_to#" "args"
            lang = config'menuLanguage cfg
            enabledMode =  if (config'subscriptionMode cfg)
                          then "enabled"
                          else "disabled"
            title = [qc|{i18n lang SubscriptionTitle} {enabledMode}|]
        editRespuesta chatId msg_id title $
                       -- Just $ InlineKeyboardMarkup buttons
                      Just (InlineKeyboardMarkup $  subscriptionKeyboard enabledMode)
        showToolTip cqId Nothing

      onCommand cfg (T.stripPrefix "subscribe-on#" -> Just _) = return ()

      onCommand cfg (T.stripPrefix "menu-amlang#" -> Just _) = do
        BotConfig{..} <- ask
        -- let cfg' = cfg {config'menuLanguage = AM}
        -- modifyUserConfig userId cfg'
        -- liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'}|]
        -- tvar <- asks state
        -- st <- liftIO $ readTVarIO tvar

        -- liftIO $ putStrLn [qc|=========== Bot Config {st}|]

        let title = T.unpack $ i18n lang SettingsMenuTitle
            lang = AM
        setLang cfg userId lang
        editRespuesta chatId msg_id title $ Just (settingsKeyboardMarkup lang)
        showToolTip cqId $ Just "Set Menu language to AM"

      onCommand cfg (T.stripPrefix "menu-enlang#" -> Just _) = do
        BotConfig{..} <- ask
        let title = T.unpack $ i18n lang SettingsMenuTitle
            lang = EN
        setLang cfg userId lang
        editRespuesta chatId msg_id title $ Just (settingsKeyboardMarkup lang)
        showToolTip cqId $ Just  "Set Menu language to EN"

      onCommand cfg (T.stripPrefix "menu-rulang#" -> Just _) = do
        BotConfig{..} <- ask
        let title = T.unpack $ i18n lang SettingsMenuTitle
            lang = RU
        setLang cfg userId lang
        editRespuesta chatId msg_id title $ Just (settingsKeyboardMarkup lang)
        showToolTip cqId $ Just "Set Menu language to RU"

      -- end Top menu items

      -- | Bible Sub menu items handler
      onCommand cfg (T.stripPrefix "bibleItem#" -> Just arg) = do
          let bibleName = T.strip arg
              cfg' = cfg { config'bible = bibleName }
          us <- modifyUserConfig userId cfg'
          let  lang = config'menuLanguage cfg

          liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'} - returned {us}|]
          liftIO $ putStrLn [qc|=========== modifed settings user: {bibleName} |]
          editRespuesta chatId msg_id [qc|Bibles - choosed {bibleName}|] $ Just (biblesKeyboardMarkup lang bibleName)
          showToolTip cqId $ Just bibleName

      -- | Parallel Bible Sub menu items handler
      onCommand cfg (T.stripPrefix "parallelBibleItem#" -> Just arg) = do
          let bibleName = T.strip arg
              biblesSet = config'parallelBibles cfg

              pSet = if Set.member bibleName biblesSet
                     then Set.delete bibleName biblesSet
                     else Set.insert bibleName biblesSet
              cfg' = cfg { config'parallelBibles = pSet }
          us <- modifyUserConfig userId cfg'
          let  lang = config'menuLanguage cfg

          liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'} - returned {us}|]
          liftIO $ putStrLn [qc|=========== modifed settings user: {bibleName} |]
          editRespuesta chatId msg_id [qc|Parallel Bibles - choosed {pSet}|] $
                        Just (parallelBiblesKeyboardMarkup lang pSet)
          showToolTip cqId $ Just bibleName



      -- | Narek's Sub menu items handler
      onCommand cfg (T.stripPrefix "narekItem#" -> Just arg) = do
          let narekTranslationName = T.strip arg
              cfg' = cfg { config'narek = narekTranslationName }
          us <- modifyUserConfig userId cfg'
          let  lang = config'menuLanguage cfg

          liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'} - returned {us}|]
          liftIO $ putStrLn [qc|=========== modifed settings user: {narekTranslationName} |]
          editRespuesta chatId msg_id [qc|Narek - choosed {narekTranslationName}|] $
                        Just (nareksKeyboardMarkup lang narekTranslationName)
          showToolTip cqId $ Just narekTranslationName


      onCommand cfg (T.stripPrefix "parallelNarekItem#" -> Just arg) = do
          let narekName = T.strip arg
              narekSet = config'parallelNarek cfg

              pSet = if Set.member narekName narekSet
                     then Set.delete narekName narekSet
                     else Set.insert narekName narekSet
              cfg' = cfg { config'parallelNarek = pSet }
          us <- modifyUserConfig userId cfg'
          let  lang = config'menuLanguage cfg

          liftIO $ putStrLn [qc|=========== modifed settings user: {userId} {cfg'} - returned {us}|]
          liftIO $ putStrLn [qc|=========== modifed settings user: {narekName} |]
          editRespuesta chatId msg_id [qc|Parallel Nareks - choosed {pSet}|] $
                        Just (parallelNareksKeyboardMarkup lang pSet)
          showToolTip cqId $ Just narekName


      -- | verse pagination
      onCommand UserSettings{..} (T.stripPrefix "go_to_verseRef#" -> Just args) = do
        liftIO $ putStrLn [qc|=========== verse pagination {args}|]

        case parseVerseRef args of
          Right verseRef@VerseReference{..} -> do
            let def1 = fromMaybe E1994T (readTranslation [config'bible])
                defaultTrans = fromMaybe def1 verseRef'translation

            vs <- liftIO $ getVerse' defaultTrans chatId verseRef
            let verseHtml = TL.toStrict . renderText $ (toHtml vs <> toHtml verseRef)

            liftIO $ putStrLn . T.unpack $ toRefText defaultTrans verseRef

            let currentPage = fromMaybe 1 verseRef'from
                buttons = prevNextPageBtns currentPage 24 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]
                -- buttons = generatePageBtns 0 page 12 "go_to_verseRef#" [qc|{verseRef'book} {verseRef'chapter} |]

            liftIO $ print buttons

            editRespuesta chatId msg_id [qc|{verseHtml}|] $ Just $ InlineKeyboardMarkup buttons
            showToolTip cqId $ Nothing

          Left e         -> error $ " failed parse verse in pagination " ++ show e




      -- | pagination ellipsing logic demo
      onCommand cfg (T.stripPrefix "go_to#" -> Just args) = do

        let all@(x:y:_) = T.splitOn " " $ T.strip args
        liftIO $ putStrLn [qc|=========== Args {all}|]

        let page = read (T.unpack y) :: Int
            buttons = generatePageBtns 0 page 12 "go_to#" "args"
        liftIO $ putStrLn [qc|=========== Page {page}|]
        liftIO $ putStrLn [qc|=========== Page {page}|]

        editRespuesta chatId msg_id [qc|Pagination  {page} bible subscribtion is currently <b>enabled</b>|] $ Just $ InlineKeyboardMarkup buttons --  subscriptionKeyboardMarkup


      onCommand _ _                                    = return ()



-- respuesta :: ChatId -> String -> Maybe ReplyKeyboard -> Bot ()
-- respuesta chatId  msg keyborad = do
--   BotConfig{..} <- ask
--   let request = SendMessageRequest chatId (T.pack msg) Nothing Nothing Nothing Nothing keyborad
--   res <- ($) sendMessage telegramToken request manager
--   liftIO $ putStrLn "response: --------------------"
--   liftIO $ putStrLn $ show res

--   let id_ = case res of
--               Right rm -> message_id $ result rm
--               Left e   -> error $ show e
--   liftIO $ writeIORef ref id_
--   return ()

editRespuesta :: ChatId -> Int -> String -> Maybe InlineKeyboardMarkup -> Bot ()
editRespuesta chatId  msgId msg keyborad = do
  BotConfig{..} <- ask
 -- msgId <- liftIO $ readIORef ref
  liftIO $ putStrLn $ show msgId

  let request = EditMessageTextRequest (Just chatId) (Just msgId) Nothing (T.pack msg)
                (Just HTML)
                Nothing keyborad
  res <- ($) editMessageText telegramToken request manager
  liftIO $ putStrLn $ show res
  -- let id_ = case res of
  --             Right rm -> message_id $ result rm
  --             Left e   -> error $ show e
  -- liftIO $ putStrLn $ show id_
  -- liftIO $ writeIORef ref id_
  return ()

-- | Show notification bar/popup tooltip
-- and fix the "keep the loading circle turning on Android" issue
showToolTip :: Text -> Maybe Text -> Bot ()
showToolTip callback_id msg = do
  BotConfig{..} <- ask
  let request = AnswerCallbackQueryRequest callback_id msg Nothing Nothing (Just 0)
  void $ answerCallbackQuery telegramToken request manager


setLang :: UserSettings -> UserId -> Language -> Bot UserSettings
setLang cfg userId  lang = do
    let cfg' = cfg { config'menuLanguage = lang }
    modifyUserConfig userId cfg'



-- | Helpers
-- parseInlineQuery :: Text -> Maybe (String,[String])
-- parseInlineQuery textQuery = do
--   let stringQuery = (T.unpack textQuery) :: String
--       re = "\\w+" :: String
--       argsList = getAllTextMatches $ (stringQuery =~ re :: AllTextMatches [] String)
--   if null argsList then Nothing else Just (head argsList, tail argsList)


-- inlineAphorisms :: Text -> [String] -> Bool -> Bot ()
-- inlineAphorisms iqId args askToClassify = do
--   BotConfig{..} <- ask
--   let n = if null args then 5 else read $ head args
--   sentences <- liftIO $ replicateM n (return "eligeSentenceFromBlog")
--   sentences <- liftIO $ replicateM n (return "eligeSentenceFromBlog")

--   -- _ <- liftIO $ putStrLn (show sentences)
--   -- _ <- liftIO $ hashUm sentences

--   let classifyButton = InlineKeyboardButton (T.pack "classify aphorism") Nothing (Just "settings#") Nothing Nothing Nothing Nothing
--       keyboard = InlineKeyboardMarkup [ [classifyButton] ]
--       inlineQueryResults = map (\(a,idx) -> InlineQueryResultArticle (T.pack $ "aphorism" ++ show idx) (Just $ T.pack $ "aphorism #" ++ show idx) (Just $ InputTextMessageContent (T.pack a) Nothing Nothing) (if askToClassify then (Just keyboard) else Nothing) Nothing Nothing (Just $ T.pack a) Nothing Nothing Nothing) (zip sentences [1..n])
--       request = AnswerInlineQueryRequest iqId inlineQueryResults (Just 1) Nothing Nothing Nothing Nothing
--   res <- ($) answerInlineQuery telegramToken request manager
--   case res of
--     Left e -> do
--       _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
--       return ()
--     Right r -> do
--       _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
--       return ()

-- inlineQuoteSearch :: (String -> IO String) -> Text -> [String] -> Bot ()
-- inlineQuoteSearch qFn iqId args = if null args then return () else inlineQuote (qFn $ head args) iqId (tail args)

-- inlineQuote :: IO String -> Text -> [String] -> Bot ()
-- inlineQuote qFn iqId args = do
--   BotConfig{..} <- ask
--   let n = if null args then 3 else (read . head) args
--   quotes <- liftIO $ replicateM n qFn
--   let inlineQueryResults = map (\(a,idx) ->
--                                     InlineQueryResultArticle (T.pack $ "quote" ++ show idx)
--                                                              (Just $ T.pack $ "quote #" ++ show idx)
--                                                              (Just $ InputTextMessageContent (T.pack a) Nothing Nothing) Nothing Nothing Nothing (Just $ T.pack a) Nothing Nothing Nothing) (zip quotes [1..n])
--       request = AnswerInlineQueryRequest iqId inlineQueryResults (Just 1) Nothing Nothing Nothing Nothing
--   res <- ($) answerInlineQuery telegramToken request manager
--   case res of
--     Left e -> do
--       _ <- liftIO $ putStrLn $ "Error: " ++ (show e)
--       return ()
--     Right r -> do
--       _ <- liftIO $ putStrLn $ "Response: " ++ (show r)
--       return ()




-- | Surbgirq inline queries


