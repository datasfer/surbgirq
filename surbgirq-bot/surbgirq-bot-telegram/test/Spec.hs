{-# LANGUAGE OverloadedStrings #-}

-- | Tests for the feast commands (/ton, /zatik). The expected dates come from tomarion's verified test
-- data (testdata/feasts-2000-2026.csv in the tomarion repo).
module Main (main) where

import Data.Text          (Text)
import Data.Time.Calendar (fromGregorian)
import Test.Hspec

import qualified Data.Text as T

import Surbgirq.Bot.Server.Handlers.Feasts
import Surbgirq.Types                      (Language (..))

main :: IO ()
main = hspec $ do

  describe "armeniaDay (UTC+4)" $ do
    it "is still 4 April 2026 at 19:59:59 UTC" $
      armeniaDay 1775332799 `shouldBe` fromGregorian 2026 4 4
    it "is 5 April 2026 (Easter) from 20:00 UTC on" $
      armeniaDay 1775332800 `shouldBe` fromGregorian 2026 4 5

  describe "parseYearArg" $ do
    it "reads nothing as today" $ do
      parseYearArg "" `shouldBe` NoYear
      parseYearArg "  " `shouldBe` NoYear
      parseYearArg "@SurbgirqBot" `shouldBe` NoYear
    it "reads a year, also after the bot's name" $ do
      parseYearArg " 2027" `shouldBe` AYear 2027
      parseYearArg "@SurbgirqBot 2027" `shouldBe` AYear 2027
      parseYearArg " 1924" `shouldBe` AYear 1924
      parseYearArg " 9999" `shouldBe` AYear 9999
    it "refuses anything else" $
      map parseYearArg [" 1923", " 10000", " 0999", " abc", " 2027 2028", "ight", " -2027"]
        `shouldBe` replicate 7 BadArg

  describe "formatDate" $ do
    it "writes Armenian dates" $
      formatDate AM easter2026 `shouldBe` "ապրիլի 5, կիրակի"
    it "writes English dates, also for the Russian menu" $ do
      formatDate EN easter2026 `shouldBe` "Sunday 5 April"
      formatDate RU easter2026 `shouldBe` "Sunday 5 April"

  describe "/ton on a day" $ do
    it "Easter 2026: the feast in bold, then the next feasts" $ do
      let reply = tonReply EN easter2026 ""
      reply `shouldContainText` "<b>Today: Sunday 5 April</b>"
      reply `shouldContainText` "<b>Holy Easter: Resurrection of Christ (Zatik)</b>"
      reply `shouldContainText` "Monday 6 April — Remembrance of the Dead (Merelots) after Easter"
    it "7 April 2023: two feasts, inside Great Lent and Holy Week" $ do
      let reply = tonReply EN (fromGregorian 2023 4 7) ""
      reply `shouldContainText` "Annunciation of the Holy Mother of God"
      reply `shouldContainText` "Good Friday"
      reply `shouldContainText` "<i>Great Lent</i>"
      reply `shouldContainText` "<i>Holy Week (Great Week)</i>"
    it "23 November 2026: no feast, and the next five run into 2027" $ do
      let reply = tonReply EN (fromGregorian 2026 11 23) ""
      reply `shouldContainText` "No feast today."
      reply `shouldContainText` "Wednesday 9 December — Conception of the Holy Mother of God"
      reply `shouldContainText` "Wednesday 13 January — Naming of Jesus Christ"
    it "answers in Armenian for the Armenian menu" $ do
      let reply = tonReply AM easter2026 ""
      reply `shouldContainText` "<b>Այսօր՝ ապրիլի 5, կիրակի</b>"
      reply `shouldContainText` "<b>Սուրբ Զատիկ</b>"

  describe "/ton for a year" $ do
    let reply2026 = tonReply EN easter2026 " 2026"
    it "lists 2026 as in tomarion's test data" $ do
      reply2026 `shouldContainText` "Saturday 31 January — Feast of St. Sargis the Warrior"
      reply2026 `shouldContainText` "Sunday 5 April — <b>Holy Easter: Resurrection of Christ (Zatik)</b>"
      reply2026 `shouldContainText` "Sunday 12 July — <b>Transfiguration of Christ (Vardavar)</b>"
      reply2026 `shouldContainText` "Sunday 13 September — <b>Exaltation of the Holy Cross (Khachverats)</b>"
    it "has one line per feast and period, plus two headings and a blank line" $
      length (T.lines reply2026) `shouldBe` 36 + 3 + 3
    it "fits in one Telegram message (4,096 characters) in every language" $
      [ T.length (tonReply lang easter2026 " 2026") | lang <- [AM, RU, EN] ]
        `shouldSatisfy` all (< 4096)
    it "answers years before 1924 with the usage line" $
      tonReply EN easter2026 " 1900"
        `shouldBe` "Usage: /ton, /ton 2027 or /zatik 2030 (years 1924–9999)."

  describe "/zatik" $ do
    it "without a year: the next Easter" $
      zatikReply EN (fromGregorian 2026 11 23) "" `shouldBe` "<b>Easter 2027:</b> Sunday 28 March"
    it "on Easter day: that day" $
      zatikReply EN easter2026 "" `shouldBe` "<b>Easter 2026:</b> Sunday 5 April"
    it "for a given year" $
      zatikReply EN easter2026 " 2030" `shouldBe` "<b>Easter 2030:</b> Sunday 21 April"
    it "in Armenian" $
      zatikReply AM easter2026 " 2030" `shouldBe` "<b>Զատիկ 2030՝</b> ապրիլի 21, կիրակի"
  where
    easter2026 = fromGregorian 2026 4 5

-- | The reply contains this piece of text.
shouldContainText :: Text -> Text -> Expectation
shouldContainText reply part = reply `shouldSatisfy` T.isInfixOf part
