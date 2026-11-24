{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Bot.Server.Helpers.Helpers where

import Data.Maybe

import Control.Monad.Reader (ask, asks, liftIO)
import Data.Text            (Text)


import qualified Data.Text as T

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.State
import Surbgirq.Bot.Store
import Surbgirq.Bot.Types
import Surbgirq.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------


-- | The translation for a reference to this book without a translation word of its own: the user's setting, else the
-- server's default (BOT_DEFAULT_BIBLE, or BOT_DEFAULT_NAREK for Narek).
getCfgTranslation :: BotConfig -> UserSettings -> Girq -> TranslationID
getCfgTranslation botConfig cfg Narek = settingOrDefault (defaultNarek botConfig) (config'narek cfg)
getCfgTranslation botConfig cfg _     = settingOrDefault (defaultBible botConfig) (config'bible cfg)


-- | The reference with its translation filled in, and that translation: the reference's own translation word if it has
-- one, else the user's setting, else the server's default. What comes after (the texts, the title, the page buttons)
-- then uses that same translation.
withTranslation :: UserSettings -> VerseReference -> Bot (TranslationID, VerseReference)
withTranslation cfg parsed = do
  botConfig <- ask
  let translation = fromMaybe (getCfgTranslation botConfig cfg (verseRef'book parsed)) (verseRef'translation parsed)
  pure (translation, parsed { verseRef'translation = Just translation })

