{-# LANGUAGE OverloadedStrings #-}

-- | Church feast days from the tomarion library: the /ton and /zatik commands.
--
-- The replies are built by pure functions, so the tests can check them without Telegram. "Today" is the
-- date in Armenia (UTC+4 all year), taken from the message's own Telegram time, so it doesn't depend on
-- the server's clock or time zone. Tomarion has Armenian and English names; the Russian menu gets the
-- English ones for now.
module Surbgirq.Bot.Server.Handlers.Feasts
    ( -- * Commands
      sendTon
    , sendZatik
      -- * Pure parts, for the tests
    , YearArg (..)
    , parseYearArg
    , armeniaDay
    , formatDate
    , tonReply
    , zatikReply
    ) where

import Data.Char             (isDigit, isSpace)
import Data.Text             (Text)
import Data.Time.Calendar    (Day, DayOfWeek (..), dayOfWeek, toGregorian)
import Data.Time.Clock       (addUTCTime, utctDay)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)
import Text.Read             (readMaybe)

import qualified Data.Text as T

import Tomarion.Core (Feast, Lang (..), Period, allPeriods, easter, feastName, feastsOf, feastsOn,
                      isTabernacle, periodDates, periodName, upcoming)

import Surbgirq.Bot.Monad                           (Bot)
import Surbgirq.Bot.Server.Helpers.HelpMessages     (I18n (..))
import Surbgirq.Bot.Server.Responses                (sendHtml)
import Surbgirq.Bot.Server.Settings.KeyboardMarkups (getLanguage)
import Surbgirq.Bot.Server.TelegramAPI              (ChatId)
import Surbgirq.Bot.State                           (UserId (..))
import Surbgirq.Types                               (Language (..))
------------------------------------------------------------
--
------------------------------------------------------------

-- | /ton: today's feasts and the next five; /ton 2027: the feasts and fasts of that year.
sendTon :: ChatId -> UserId -> Int -> Text -> Bot ()
sendTon chatId userId messageDate args = do
    lang <- getLanguage (unUserId userId)
    sendHtml chatId (tonReply lang (armeniaDay messageDate) args)

-- | /zatik: the next Easter; /zatik 2030: Easter in that year.
sendZatik :: ChatId -> UserId -> Int -> Text -> Bot ()
sendZatik chatId userId messageDate args = do
    lang <- getLanguage (unUserId userId)
    sendHtml chatId (zatikReply lang (armeniaDay messageDate) args)

-- | What follows the command: nothing, a year, or anything else.
data YearArg = NoYear | AYear Integer | BadArg
    deriving (Eq, Show)

-- | Reads the text after the command. A bot name right after it ("/ton@SurbgirqBot 2027", as Telegram
-- sends commands in groups) is skipped. Years run from 1924, when the Church's Gregorian dates begin,
-- to 9999.
parseYearArg :: Text -> YearArg
parseYearArg args = case T.words (skipBotName args) of
    [] -> NoYear
    [w] | T.length w == 4, T.all isDigit w
        , Just y <- readMaybe (T.unpack w), y >= 1924 -> AYear y
    _ -> BadArg
  where
    skipBotName t = case T.uncons t of
        Just ('@', rest) -> T.dropWhile (not . isSpace) rest
        _                -> t

-- | The date in Armenia at a Unix time, such as a message's 'date'. Armenia keeps UTC+4 all year.
armeniaDay :: Int -> Day
armeniaDay unixTime =
    utctDay (addUTCTime (4 * 60 * 60) (posixSecondsToUTCTime (fromIntegral unixTime)))

-- | "ապրիլի 5, կիրակի" in Armenian, "Sunday 5 April" in English (and for the Russian menu).
formatDate :: Language -> Day -> Text
formatDate lang d = case lang of
    AM -> (monthsHy !! (m - 1)) <> " " <> tshow dd <> ", " <> weekdayHy (dayOfWeek d)
    _  -> tshow (dayOfWeek d) <> " " <> tshow dd <> " " <> (monthsEn !! (m - 1))
  where
    (_, m, dd) = toGregorian d

-- | The answer to /ton, in Telegram's HTML.
tonReply :: Language -> Day -> Text -> Text
tonReply lang today args = case parseYearArg args of
    NoYear  -> todayReply lang today
    AYear y -> yearReply lang y
    BadArg  -> i18n lang Usage

-- | The answer to /zatik, in Telegram's HTML. Without a year: the next Easter, or today's if today
-- is Easter.
zatikReply :: Language -> Day -> Text -> Text
zatikReply lang today args = case parseYearArg args of
    NoYear  -> easterLine (if easter thisYear >= today then thisYear else thisYear + 1)
    AYear y -> easterLine y
    BadArg  -> i18n lang Usage
  where
    (thisYear, _, _) = toGregorian today
    easterLine y     = bold (i18n lang (EasterOf y)) <> " " <> formatDate lang (easter y)

-- | Today: its feasts (or none), the fast or Holy Week it falls in, and the next five feasts.
todayReply :: Language -> Day -> Text
todayReply lang today = T.intercalate "\n" $
       [ bold (i18n lang TodayIs <> " " <> formatDate lang today) ]
    ++ (if null todays then [ i18n lang NoFeastToday ] else map (feastLabel lang) todays)
    ++ [ italic (escape (periodName (nameLang lang) p)) | p <- periodsOn today ]
    ++ [ "", bold (i18n lang NextFeasts) ]
    ++ map (feastLine lang) next
  where
    todays = feastsOn today
    next   = take 5 (dropWhile ((<= today) . snd) (upcoming today))

-- | A whole year: every feast by date, then the fasts and Holy Week.
yearReply :: Language -> Integer -> Text
yearReply lang y = T.intercalate "\n" $
       [ bold (i18n lang (FeastsOfYear y)) ]
    ++ map (feastLine lang) (feastsOf y)
    ++ [ "", bold (i18n lang Fasts) ]
    ++ map periodLine allPeriods
  where
    periodLine p =
        let (from, to) = periodDates y p
        in  formatDate lang from <> " – " <> formatDate lang to
                <> " — " <> escape (periodName (nameLang lang) p)

-- | One feast with its date.
feastLine :: Language -> (Feast, Day) -> Text
feastLine lang (feast, d) = formatDate lang d <> " — " <> feastLabel lang feast

-- | A feast's name; the five great (Tabernacle) feasts in bold.
feastLabel :: Language -> Feast -> Text
feastLabel lang feast
    | isTabernacle feast = bold name
    | otherwise          = name
  where
    name = escape (feastName (nameLang lang) feast)

-- | The fasts and Holy Week that include a day.
periodsOn :: Day -> [Period]
periodsOn d = [ p | p <- allPeriods, let (from, to) = periodDates y p, from <= d, d <= to ]
  where
    (y, _, _) = toGregorian d

-- | Tomarion's names exist in Armenian and English; the Russian menu gets English for now.
nameLang :: Language -> Lang
nameLang AM = Hy
nameLang _  = En

-- | The fixed phrases of the replies.
data Phrase
    = TodayIs
    | NoFeastToday
    | NextFeasts
    | FeastsOfYear Integer
    | Fasts
    | EasterOf Integer
    | Usage

instance I18n Phrase where
  i18n lang p = case lang of

    AM -> case p of
      TodayIs        -> "Այսօր՝"
      NoFeastToday   -> "Այսօր տոն չկա։"
      NextFeasts     -> "Առաջիկա տոներ"
      FeastsOfYear y -> tshow y <> " թ. տոներ"
      Fasts          -> "Պահքեր"
      EasterOf y     -> "Զատիկ " <> tshow y <> "՝"
      Usage          -> "Օրինակ՝ /ton, /ton 2027 կամ /zatik 2030 (1924–9999 թվականներ)։"
    RU -> i18n EN p
    EN -> case p of
      TodayIs        -> "Today:"
      NoFeastToday   -> "No feast today."
      NextFeasts     -> "Next feasts"
      FeastsOfYear y -> "Feasts in " <> tshow y
      Fasts          -> "Fasts"
      EasterOf y     -> "Easter " <> tshow y <> ":"
      Usage          -> "Usage: /ton, /ton 2027 or /zatik 2030 (years 1924–9999)."

monthsHy, monthsEn :: [Text]
monthsHy = [ "հունվարի", "փետրվարի", "մարտի", "ապրիլի", "մայիսի", "հունիսի"
           , "հուլիսի", "օգոստոսի", "սեպտեմբերի", "հոկտեմբերի", "նոյեմբերի", "դեկտեմբերի" ]
monthsEn = [ "January", "February", "March", "April", "May", "June"
           , "July", "August", "September", "October", "November", "December" ]

-- | Weekdays in Armenian, as Tomarion's glossary spells them, in lower case for use inside a date.
weekdayHy :: DayOfWeek -> Text
weekdayHy w = case w of
    Monday    -> "երկուշաբթի"
    Tuesday   -> "երեքշաբթի"
    Wednesday -> "չորեքշաբթի"
    Thursday  -> "հինգշաբթի"
    Friday    -> "ուրբաթ"
    Saturday  -> "շաբաթ"
    Sunday    -> "կիրակի"

tshow :: Show a => a -> Text
tshow = T.pack . show

bold, italic :: Text -> Text
bold t   = "<b>" <> t <> "</b>"
italic t = "<i>" <> t <> "</i>"

-- | Escapes the three characters that Telegram's HTML mode reads as markup.
escape :: Text -> Text
escape = T.replace "<" "&lt;" . T.replace ">" "&gt;" . T.replace "&" "&amp;"
