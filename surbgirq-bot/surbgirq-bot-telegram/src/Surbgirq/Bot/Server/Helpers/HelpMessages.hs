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
    , "/ton - ԵԿԵՂԵՑԱԿԱՆ ՏՈՆԵՐ - today and the next feasts"
    , "/ton 2027 - the feasts and fasts of a year"
    , "/zatik [year] - Easter (Զատիկ): the next one, or that year's"
    , "/md    -  markdown test"
    , "/html  - html markdown test"
    ]



data SettingMenuMsgs =
          Narekaci
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
      Narekaci       -> "Նարեկացի"
      NarekParallel  -> "Նարեկ Զւոգահեռ Թարգմանություններ"
      Subscription   -> "Բաժանորդագրվել"
      Armenian       -> "Հայերեն"
      Russian        -> "Русский"
      English        -> "English"
    RU -> case v of
      Bibles         -> "Библия"
      BiblesParallel -> "Библия параллельные переводы"
      Narekaci       -> "Григор Нарекаци"
      NarekParallel  -> "Нарекаци параллельные переводы"
      Subscription   -> "Подписаться"
      Armenian       -> "Հայերեն"
      Russian        -> "Русский"
      English        -> "English"
    EN -> case v of
      Bibles         -> "Bibles"
      BiblesParallel -> "Bibles Parallel Translations"
      Narekaci       -> "Narek"
      NarekParallel  -> "Narek Parallel Translations"
      Subscription   -> "Subscribe"
      Armenian       -> "Հայերեն"
      Russian        -> "Русский"
      English        -> "English"

class I18n a where
  i18n :: Language -> a -> Text




-- data BibleTranslationsMsgs =
--           Grabar1805
--         | E1994
--         | E2004
--         | Sinodal
--         | KJV



instance I18n TranslationID where
  i18n lang v = case lang of

    AM -> case v of
        V1805T   -> "Գրաբար"
        E1994T   -> "Ս. ԷՋՄԻԱԾԻՆ (1994)"
        E2004T   -> "Ս. ԷՋՄԻԱԾԻՆ (2004)"
        SinodalT -> "Սինոդալ"
        KJVT     -> "KJV"
    RU -> case v of
        V1805T   -> "RU grabar"
        E1994T   -> "E 1994"
        E2004T   -> "E 2004"
        SinodalT -> "Sinodal"
        KJVT     -> "KJV"
    EN -> case v of
        V1805T   -> "Classical Armenian"
        E1994T   -> "E 1994"
        E2004T   -> "E 2004"
        SinodalT -> "Sinodal"
        KJVT     -> "KJV"

data SubMenuTitleMsgs =
          BiblesTile
        | ParallelBibleTitle
        | NarekTitle
        | ParallelNarekTitle
        | SubscriptionTitle
        | SettingsMenuTitle


instance I18n SubMenuTitleMsgs where
  i18n lang v = case lang of

    AM -> case v of
            BiblesTile         -> "Աստուածաշունչ Մատեան"
            ParallelBibleTitle -> "Աստուածաշունչ Մատեանի Զւոգահեռ Թարգմանություններ"
            NarekTitle         -> "Նարեկացի"
            ParallelNarekTitle -> "Նարեկ Զւոգահեռ Թարգմանություններ"
            SubscriptionTitle  -> "Բաժանորդագրվել"
            SettingsMenuTitle  -> "Կարգավորումներ"
    RU -> case v of
            BiblesTile         -> "Библия"
            ParallelBibleTitle -> "Библия параллельные переводы"
            NarekTitle         -> "Григор Нарекаци"
            ParallelNarekTitle -> "Нарекаци параллельные переводы"
            SubscriptionTitle  -> "Подписаться"
            SettingsMenuTitle  -> "Настройки"
    EN -> case v of
            BiblesTile         -> "Bibles"
            ParallelBibleTitle -> "Bibles Parallel Translations"
            NarekTitle         -> "Narek"
            ParallelNarekTitle -> "Narek Parallel Translations"
            SubscriptionTitle  -> "Subscribe"
            SettingsMenuTitle  -> "Settings"



