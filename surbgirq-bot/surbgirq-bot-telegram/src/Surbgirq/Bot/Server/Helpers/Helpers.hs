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


getCfgTranslation :: UserSettings -> Girq -> TranslationID
getCfgTranslation cfg Narek = fromMaybe Narek_Xer $ readTranslation [config'narek cfg]
getCfgTranslation cfg _     = fromMaybe E1994T $ readTranslation [config'bible cfg]

