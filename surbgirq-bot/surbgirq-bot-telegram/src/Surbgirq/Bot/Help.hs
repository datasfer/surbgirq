{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Bot.Help where

import           Data.Text (Text)
import qualified Data.Text as T

import Surbgirq.Bot.Server.TelegramAPI




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



