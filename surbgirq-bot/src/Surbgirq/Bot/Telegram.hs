{-# LANGUAGE OverloadedStrings #-}

module Surbgirq.Bot.Telegram where

import           Data.Text (Text)
import qualified Data.Text as T

import           Telegram.Bot.API
import qualified Telegram.Bot.API    as Telegram
import           Telegram.Bot.Simple
-- import           Telegram.Bot.Simple
-- import           Telegram.Bot.Simple.Debug
-- import           Telegram.Bot.Simple.UpdateParser (updateMessageText)
import Telegram.Bot.Simple.UpdateParser



type Model = ()

data Action
  = NoOp
  | Echo Text
  | Start


echoBot :: BotApp Model Action
echoBot = BotApp
  { botInitialModel = (),
    botAction = updateToAction,
    botHandler = handleAction,
    botErrorHandlers = [],
    botForkErrorHandler = Nothing,
    botJobs = []
  }

updateToAction :: Update -> Model -> Maybe Action
updateToAction update _ =
  case updateMessageText update of
    Just ("/start") -> Just Start
    Just txt        -> Just (Echo txt)
    Nothing         -> Nothing

handleAction :: Action -> Model -> Eff Action Model
handleAction action model = case action of
  NoOp -> pure model
  Echo msg -> model <# do
    replyText (T.append msg "--inqna")
    return NoOp
  Start -> model <# do
    reply (toReplyMessage startMessage)
        { replyMessageReplyMarkup = Just
            (Telegram.SomeReplyKeyboardMarkup startMessageKeyboard)
        }
    return NoOp


run :: Text -> IO ()
run token = do
  env <- defaultTelegramClientEnv (Token token)
--  startBot_ (conversationBot updateChatId echoBot) env
  startBot_ defaultPeriod (conversationBot updateChatId echoBot) env


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



-- | A start keyboard with some helpful todo suggestions.
startMessageKeyboard :: Telegram.ReplyKeyboardMarkup
startMessageKeyboard = Telegram.ReplyKeyboardMarkup
  { Telegram.replyKeyboardMarkupKeyboard =
      [ [ "Drink water", "Eat fruit" ]
      , [ "Build a house", "Raise a son", "Plant a tree" ]
      , [ "Spend time with family", "Call parents" ]
      ]
  , Telegram.replyKeyboardMarkupResizeKeyboard = Just True
  , Telegram.replyKeyboardMarkupOneTimeKeyboard = Just True
  , Telegram.replyKeyboardMarkupSelective = Just True
  }
