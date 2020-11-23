{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Bot.Server.Helpers.HelpMessages where

import Control.Monad.Reader (ask, asks, liftIO)
import Data.Text            (Text)

import qualified Data.Text as T

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types
import Surbgirq.Types
------------------------------------------------------------
--
------------------------------------------------------------

-- | A help message to show on conversation start with bot.
startMessage :: Text
startMessage = T.unlines
 [ "Hi there! I am your personal todo bot :)"
 , ""
 , "I can help you keep track of things to do:"
 , ""
 , "- Just type what you need to do an I'll remember it!"
 , "- Use /remove <item> to remove an item"
 , "- Use /show to show all current things to do"
 , ""
 , "So what's the first thing on your to do list? :)"
 ]



helpMessage :: ChatId -> SendMessageRequest
helpMessage userId =  sendMessageRequest userId $ T.unlines
    [ "/help - show this message and subsequently die the flame death"
    , "/settings  - Settings for bot"
    , "/books  - get a books"
    , "/books book  - get a book"
    , "/_books - get a books one text block"
    , "/verse ref  - get a verse, e.g. ref = Ղուկ. 6.20-23 or ref = Luk. 6.20-23"
    , "/next - verse button"
    , "/Ղուկ. 6.20-23  - get a verse, e.g. ref = Ղուկ. 6.20-23 or ref = Luk. 6.20-23"
    , "/rand || /random - random verse from new testament - TODO"
    , "/rand Mat - random verse from Matthew - TODO"
    , "/today - Աստուածաշունչն այսօր - TODO"
    , "/ton - ԵԿԵՂԵՑԱԿԱՆ ՏՈՆԵՐ - TODO"
    , "/md    -  markdown test"
    , "/html  - html markdown test"
    ]



data SettingMenuMsgs =
          Narek
        | NarekParallel
        | Bibles
        | BiblesParallel
        | Subscription
        | Armenian
        | Russian
        | English



instance I18n SettingMenuMsgs where
  i18n lang v = case lang of

    AM -> case v of
      Bibles         -> "Աստուածաշունչ Մատեան"
      BiblesParallel -> "Աստուածաշունչ Զւոգահեռ Թարգմանություններ"
      Narek          -> "Նարեկացի"
      NarekParallel  -> "Նարեկ Զւոգահեռ Թարգմանություններ"
      Subscription   -> "Բաժանորդագրվել"
      Armenian       -> "Armenian"
      Russian        -> "Ռուսերեն"
      English        -> "Անգլրերն"
    RU -> case v of
      Bibles         -> "Библия"
      BiblesParallel -> "Библия параллельные переводы"
      Narek          -> "Григор Нарекаци"
      NarekParallel  -> "Нарекаци параллельные переводы"
      Subscription   -> "Подписаться"
      Armenian       -> "Армянский"
      Russian        -> "Russian"
      English        -> "Английский"
    EN -> case v of
      Bibles         -> "Bibles"
      BiblesParallel -> "Bibles Parallel Translations"
      Narek          -> "Narek"
      NarekParallel  -> "Narek Parallel Translations"
      Subscription   -> "Subscribe"
      Armenian       -> "Armenian"
      Russian        -> "Russian"
      English        -> "English"

class I18n a where
  i18n :: Language -> a -> Text




data BibleTranslationsMsgs =
          Grabar1805
        | E1994
        | E2004
        | Sinodal
        | KJV



instance I18n BibleTranslationsMsgs where
  i18n lang v = case lang of

    AM -> case v of
        Grabar1805 -> "AM Grabar"
        E1994      -> ""
        E2004      -> ""
        Sinodal    -> ""
        KJV        -> ""
    RU -> case v of
        Grabar1805 -> "RU grabar"
        E1994      -> ""
        E2004      -> ""
        Sinodal    -> ""
        KJV        -> ""
    EN -> case v of
        Grabar1805 -> "EN grabar"
        E1994      -> ""
        E2004      -> ""
        Sinodal    -> ""
        KJV        -> ""

