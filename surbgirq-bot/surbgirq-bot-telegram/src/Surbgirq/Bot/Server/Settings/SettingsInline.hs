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

module Surbgirq.Bot.Server.Settings.InlineSettings where

import Web.Telegram.API.Bot

import Data.Set                      (Set)
import Data.Text                     (Text)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Set as Set

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
        parallelNarek = mkInlineBtn "Parallel Narek" "parallelNarek#"
        parallelBible = mkInlineBtn "Parallel Bible" "parallelBible#"
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
        parallelNarek = mkInlineBtn "Զուգահեռ Նարեկ" "parallelNarek#"
        parallelBible = mkInlineBtn "Զւոգահեռ Աստուածաշունչ" "parallelBible#"
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
-- parallelBiblesKeyboardMarkup = InlineKeyboardMarkup parallelBiblesKeyboard
-- parallelBiblesKeyboard =
--     let armBible = mkInlineBtn "Աստուածաշունչ Մատեան" "parallel-armBible#"
--         ruBible = mkInlineBtn "Библия" "parallel-ruBible#"
--         enBible = mkInlineBtn "Bible" "parallel-enBible#"
--     in [[armBible, ruBible, enBible], [backToSetting]]
parallelBiblesKeyboardMarkup :: Set Text -> InlineKeyboardMarkup
parallelBiblesKeyboardMarkup ss = InlineKeyboardMarkup (parallelBiblesKeyboard "parallelBibleItem#" ss)

parallelBiblesKeyboard :: Text -> Set Text -> [[InlineKeyboardButton]]
parallelBiblesKeyboard cmdPrefix xs = map (map toKbd ) booksBible ++ [[backToSetting]]
    where
      toKbd :: (Text,Text) -> InlineKeyboardButton
      toKbd (title, cb_data) =
          let name = if Set.member cb_data xs
                     then [qc|{title} ✝|]
                     else title
          in mkInlineBtn name [qc|{cmdPrefix} {cb_data}|]


parallelNareksKeyboardMarkup = InlineKeyboardMarkup parallelNareksKeyboard
parallelNareksKeyboard = let toKbd = map (\(title, d) -> mkInlineBtn title [qc|parallelNarek# {d}|])
                         in map toKbd booksNarek ++ [[backToSetting]]



nareksKeyboardMarkup = InlineKeyboardMarkup parallelNareksKeyboard
nareksKeyboard = let toKbd = map (\(title, d) -> mkInlineBtn title d)
                 in map toKbd booksNarek ++ [[backToSetting]]



-- |
-- Existing bible setting, version, translation and etc

--  Armenian Bible's sub menu
biblesKeyboardMarkup :: Text -> InlineKeyboardMarkup
biblesKeyboardMarkup chName = InlineKeyboardMarkup (biblesKeyboard chName)

biblesKeyboard :: Text -> [[InlineKeyboardButton]]
biblesKeyboard chName = map (map (toKbd chName)) booksBible ++ [[backToSetting]]
    where
      toKbd :: Text -> (Text,Text) -> InlineKeyboardButton
      toKbd checkedName (title, cb_data) =
          let name = if checkedName == cb_data
                     then [qc|{title} ✝|]
                     else title
          in mkInlineBtn name [qc|bibleItem# {cb_data}|]



armBiblesKeyboardMarkup = InlineKeyboardMarkup armBiblesKeyboard
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
backToSetting = mkInlineBtn "⮨ Back" "settings#"





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
-- http://www.biblesociety.am/main.php?testament_id=5&book_id=150&chapter_id=2621&submit=%3E%3E&lang=a&content=bible&page-id=8&subpage-id=3
booksBible :: [ [(Text,Text)] ]
booksBible = [ [("Գրաբար 1805", "v1805-T"), ("Գրաբար 1905", "grabar1905#")]
             , [("«Էջմիածին» թարգմանություն 1994", "e1994-T")]
             , [("«Էջմիածին» թարգմանություն(Նոր) 2004", "e2004-T")]
             , [("Sinodial", "ruSinodial#")]
             , [("KJV", "kjv-T"), ("EVN", "envBible#")]
             ]

booksNarek :: [ [(Text,Text)] ]
booksNarek = [ [("Նարեկ Գրաբար", "grabarNarek#"), ("Նարեկ Խերանյան", "xerNarek#")]
             , [("Նարեկ Գևորգյան", "gevNarek#"), ("Նարեկ Գօչունեան", "gochNarek#")]
             , [("Книга скорбных песнопений", "ruNarek#")]
             , [("Book of Lamentations", "enNarek#")]
             ]
