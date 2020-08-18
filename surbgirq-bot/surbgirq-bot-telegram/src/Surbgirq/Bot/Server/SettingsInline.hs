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
Module      : Surbgirq.Bot.Server.SettingsInline
Description : Implement Settings inline keyboards and callback query handlers

Implement Settings inline keyboards and callback query handlers
-}

module Surbgirq.Bot.Server.SettingsInline where

import Web.Telegram.API.Bot


-- go_seetings_menu = undefined

-- | Inline Buttons Markup

-- main menu
settingsKeyboardReplyMarkup = ReplyInlineKeyboardMarkup settingsKeyboard

settingsKeyboardMarkup = InlineKeyboardMarkup settingsKeyboard
settingsKeyboard = [[parallelLangBtn], [dialectBtn, languageBtn], [backToSetting]]

-- sub menus
dialectsKeyboardMarkup  =  InlineKeyboardMarkup dialectsKeyboard
dialectsKeyboard = [[grabarBtn, ashxarhabarBtn], [backToSetting]]

parallelsKeyboardMarkup = InlineKeyboardMarkup parallelsKeyboard
parallelsKeyboard = [[armBtn, ruBtn, enBtn], [backToSetting]]
languagesKeyboardMarkup =  InlineKeyboardMarkup languagesKeyboard
languagesKeyboard = [[armLangBtn, ruLangBtn, enLangBtn], [backToSetting]]

-- Dialect's submenu
grabarBtn = mkInlineBtn "Grabar" "grabar#"
ashxarhabarBtn = mkInlineBtn "Ashxarhabar" "ashxarhabar#"

-- Parallel Languages
armBtn = mkInlineBtn "Armenian" "armParallel#"
ruBtn = mkInlineBtn "Russian" "ruParallel#"
enBtn = mkInlineBtn "English" "enParallel#"

-- Languages
armLangBtn = mkInlineBtn "Armenian" "armLang#"
ruLangBtn = mkInlineBtn "Russian" "ruLang#"
enLangBtn = mkInlineBtn "English" "enLang#"

-- Settings menu
dialectBtn = mkInlineBtn "Dialect" "dialects#"
languageBtn = mkInlineBtn "Languages" "languages#"
parallelLangBtn = mkInlineBtn "Parallel Langs" "parallel-langs#"
backToSetting = mkInlineBtn "<< Back to Settings" "settings#"





mkInlineBtn text callback_data = InlineKeyboardButton text Nothing (Just callback_data) Nothing Nothing Nothing Nothing


-- | A settings keyboard markup schema
settingsKeyboardSchema =
     [ ("Dialect", ["Grabar", "Ashxarhabar" ])
     , ("Parallel Scriptures", [ "Grabar", "Russian" ])
     ]
