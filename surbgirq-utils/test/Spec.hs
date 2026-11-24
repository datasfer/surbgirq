{-# LANGUAGE OverloadedStrings #-}
-- | What a verse reference typed in the bot becomes ('parseVerseRef').
module Main (main) where

import Data.Either (isLeft)
import Data.Text   (Text)
import Test.Hspec

import Surbgirq.Types (Girq (..), TranslationID (..), VerseReference (..))
import Surbgirq.Utils (parseVerseRef)

-- | A parsed reference's parts, compared as a tuple since 'VerseReference' has no 'Eq' instance: the translation, the
-- book, the chapter, the first and the last verse, and whether the verses are combined into one message.
type Parts = (Maybe TranslationID, Girq, Int, Maybe Int, Maybe Int, Bool)

parts :: VerseReference -> Parts
parts r = ( verseRef'translation r, verseRef'book r, verseRef'chapter r
          , verseRef'from r, verseRef'to r, verseRef'combine r )

parsesTo :: Text -> Parts -> Expectation
parsesTo reference expected = fmap parts (parseVerseRef reference) `shouldBe` Right expected

main :: IO ()
main = hspec $
  describe "parseVerseRef" $ do
    it "reads a chapter and a verse range written with : and -" $
      "Mat 5:3-12" `parsesTo` (Just KJVT, Matthew, 5, Just 3, Just 12, True)
    it "reads a chapter and a verse separated by spaces" $
      "Մատթ 5 3" `parsesTo` (Just E1994T, Matthew, 5, Just 3, Nothing, False)
    it "reads a chapter alone" $
      "Gen 1" `parsesTo` (Just KJVT, Genesis, 1, Nothing, Nothing, False)
    it "ignores the abbreviation's case" $
      "MATT 5 3" `parsesTo` (Just KJVT, Matthew, 5, Just 3, Nothing, False)
    it "takes a translation word before the book" $
      "kjv Ծննդ 1 1" `parsesTo` (Just KJVT, Genesis, 1, Just 1, Nothing, False)
    it "finds the book in the second word" $
      "read Mat 5" `parsesTo` (Just KJVT, Matthew, 5, Nothing, Nothing, False)
    it "reads Narek by a translation's name" $
      "Նարեկացի 3 1" `parsesTo` (Just Narek_Grabar, Narek, 3, Just 1, Nothing, False)
    it "refuses empty text" $
      parseVerseRef "" `shouldSatisfy` isLeft
    it "refuses an unknown book" $
      parseVerseRef "xyz 1 2" `shouldSatisfy` isLeft
    it "refuses a book without a chapter" $
      parseVerseRef "Mat" `shouldSatisfy` isLeft
