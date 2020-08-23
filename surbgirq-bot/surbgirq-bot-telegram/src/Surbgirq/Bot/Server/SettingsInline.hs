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

import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

-- go_seetings_menu = undefined

-- | Inline Buttons Markup

-- main menu
settingsKeyboardReplyMarkup = ReplyInlineKeyboardMarkup settingsKeyboard

-- settingsKeyboardMarkup :: Language -> Int
settingsKeyboardMarkup lang =
    case lang of
         AM -> InlineKeyboardMarkup amSettingsKeyboard
         EN -> InlineKeyboardMarkup settingsKeyboard

settingsKeyboard =
    let bibles = mkInlineBtn "Bibles" "bibles#"
        -- ruBible = mkInlineBtn "Библия" "ruBible#"
        -- enBible = mkInlineBtn "Bible" "enBible#"
        narek = mkInlineBtn "Narek" "narek#"
        parallelNarek = mkInlineBtn "Parallel Narek" "parallel-narek#"
        parallelBible = mkInlineBtn "Parallel Bible" "parallel-bible#"
        subscribe = mkInlineBtn "Subscribe" "subscribe-bible#"
        amMenuLang = mkInlineBtn "Arm" "menu-amlang#"
    in [ [bibles]
       , [parallelBible]
--       , [ruBible, enBible]
       , [narek, parallelNarek]
       , [subscribe]
       , [amMenuLang]
       ]


amSettingsKeyboardMarkup = InlineKeyboardMarkup amSettingsKeyboard
amSettingsKeyboard =
    let bibles = mkInlineBtn "Աստուածաշունչ Մատեան" "bibles#"
        -- ruBible = mkInlineBtn "Библия" "ruBible#"
        -- enBible = mkInlineBtn "Bible" "enBible#"
        narek = mkInlineBtn "Նարեկացի" "narek#"
        parallelNarek = mkInlineBtn "Զուգահեռ Նարեկ" "parallel-narek#"
        parallelBible = mkInlineBtn "Զւոգահեռ Աստուածաշունչ" "parallel-bible#"
        subscribe = mkInlineBtn "Բաժանորդագրվել" "subscribe-bible#"
        enMenuLang = mkInlineBtn "English" "menu-enlang#"
    in [ [bibles]
       , [parallelBible]
--       , [ruBible, enBible]
       , [narek, parallelNarek]
       , [subscribe]
       , [enMenuLang]
       ]



-- sub menus

subscriptionKeyboardMarkup = InlineKeyboardMarkup subscriptionKeyboard
subscriptionKeyboard =
    let subscribtionMode = mkInlineBtn "Turn Subscription mode on" "subscribtion-on#"
    in [[subscribtionMode], [backToSetting]]

-- | parallel sub menu
parallelBiblesKeyboardMarkup = InlineKeyboardMarkup parallelBiblesKeyboard
parallelBiblesKeyboard =
    let armBible = mkInlineBtn "Աստուածաշունչ Մատեան" "parallel-armBible#"
        ruBible = mkInlineBtn "Библия" "parallel-ruBible#"
        enBible = mkInlineBtn "Bible" "parallel-enBible#"
    in [[armBible, ruBible, enBible], [backToSetting]]


parallelNareksKeyboardMarkup = InlineKeyboardMarkup parallelNareksKeyboard
parallelNareksKeyboard = let toKbd = map (\(title, d) -> mkInlineBtn title [qc|parallelNarek# {d}|])
                         in map toKbd booksNarek ++ [[backToSetting]]



nareksKeyboardMarkup = InlineKeyboardMarkup parallelNareksKeyboard
nareksKeyboard = let toKbd = map (\(title, d) -> mkInlineBtn title d)
                 in map toKbd booksNarek ++ [[backToSetting]]



-- |
-- Existing bible setting, version, translation and etc

--  Armenian Bible's sub menu
biblesKeyboardMarkup = InlineKeyboardMarkup biblesKeyboard
biblesKeyboard = let toKbd = map (\(title, d) -> mkInlineBtn title [qc|bibleItem# {d}|])
                 in map toKbd booksBible ++ [[backToSetting]]



armBiblesKeyboardMarkup = InlineKeyboardMarkup biblesKeyboard
armBiblesKeyboard =
    let grabar1895 = mkInlineBtn "Գրաբար 1895" "grabar1895#"
        grabar1905 = mkInlineBtn "Գրաբար 1905" "grabar1905#"
        ejmiacin1994 = mkInlineBtn "Էջմիածին 1994" "ejmiacin1994#"
    in [[grabar1895, grabar1905, ejmiacin1994], [backToSetting]]

-- Russian Bible's sub menu
ruBiblesKeyboardMarkup = InlineKeyboardMarkup ruBiblesKeyboard
ruBiblesKeyboard =
    let sinodial = mkInlineBtn "Sinodial" "ruSinodial#"
    in [[sinodial], [backToSetting]]

-- English Bible's versions  sub menu
enBiblesKeyboardMarkup = InlineKeyboardMarkup enBiblesKeyboard
enBiblesKeyboard =
    let kjv = mkInlineBtn "KJV" "kjvBible#"
        evn = mkInlineBtn "EVN" "envBible#"
    in [ [kjv, evn], [backToSetting] ]



dialectsKeyboardMarkup  =  InlineKeyboardMarkup dialectsKeyboard
dialectsKeyboard = [[grabarBtn, ashxarhabarBtn], [backToSetting]]

languagesKeyboardMarkup =  InlineKeyboardMarkup languagesKeyboard
languagesKeyboard = [[armLangBtn, ruLangBtn, enLangBtn], [backToSetting]]


armDialectsKeyboardMarkup  =  InlineKeyboardMarkup armDialectsKeyboard
armDialectsKeyboard = [[grabarBtn, ashxarhabarBtn], [backToSetting]]




-- Dialect's submenu
grabarBtn = mkInlineBtn "Grabar" "grabar#"
ashxarhabarBtn = mkInlineBtn "Ashxarhabar" "ashxarhabar#"

sinodialBtn = mkInlineBtn "Sinodial" "sinodial#"

-- Parallel Bibles
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
backToSetting = mkInlineBtn "<< Back to Settings" "settings#"





mkInlineBtn text callback_data = InlineKeyboardButton text Nothing (Just callback_data) Nothing Nothing Nothing Nothing

checkBtn btn  = let txt = [qc|{ikb_text btn}++|]
                in btn {ikb_text = txt}


-- | A settings keyboard markup schema
settingsKeyboardSchema =
     [ ("Dialect", ["Grabar", "Ashxarhabar" ])
     , ("Parallel Scriptures", [ "Grabar", "Russian" ])
     ]



data Menu = Menu
 { menu'title :: Text
 , menu'data  :: Text

 }


-- | Menu and sub menu titles and schema
booksBible = [ [("Գրաբար 1895", "grabar1895#"), ("Գրաբար 1905", "grabar1905"), ("Էջմիածին 1994", "ejmiacin1994#")]
             , [("Sinodial", "ruSinodial#")]
             , [("KJV", "kjvBible#"), ("EVN", "envBible#")]
             ]

booksNarek = [ [("Նարեկ Գրաբար", "grabarNarek#"), ("Նարեկ Խերանյան", "xerNarek#")]
             , [("Նարեկ Գևորգյան", "gevNarek#"), ("Նարեկ Գօչունեան", "gochNarek#")]
             , [("Книга скорбных песнопений", "ruNarek#")]
             , [("Book of Lamentations", "enNarek#")]
             ]
