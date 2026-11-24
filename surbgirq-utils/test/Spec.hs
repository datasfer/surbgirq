{-# LANGUAGE OverloadedStrings #-}
-- | What a verse reference typed in the bot becomes ('parseVerseRef').
module Main (main) where

import Control.Monad (forM_)
import Data.Either   (isLeft)
import Data.Text     (Text)
import Test.Hspec

import qualified Data.Text as T

import Surbgirq.Types (CmdToken (..), Girq (..), TranslationID (..), VerseReference (..), findTransByAbbr,
                       toRefText)
import Surbgirq.Utils (parseVerseRef, settingOrDefault)

-- | A parsed reference's parts, compared as a tuple since 'VerseReference' has no 'Eq' instance: the translation, the
-- book, the chapter, the first and the last verse, and whether the verses are combined into one message.
type Parts = (Maybe TranslationID, Girq, Int, Maybe Int, Maybe Int, Bool)

parts :: VerseReference -> Parts
parts r = ( verseRef'translation r, verseRef'book r, verseRef'chapter r
          , verseRef'from r, verseRef'to r, verseRef'combine r )

parsesTo :: Text -> Parts -> Expectation
parsesTo reference expected = fmap parts (parseVerseRef reference) `shouldBe` Right expected

main :: IO ()
main = hspec $ do
  describe "findTransByAbbr" $ do
    it "finds every translation by its ID and by the value the settings keyboard stores" $
      forM_ [minBound .. maxBound] $ \t -> do
        findTransByAbbr (T.pack (show t)) `shouldBe` Just t
        findTransByAbbr (toCmd t) `shouldBe` Just t
    it "finds nothing for an empty setting" $
      findTransByAbbr "" `shouldBe` Nothing

  describe "settingOrDefault" $ do
    it "takes the translation the user's setting names" $
      settingOrDefault V1805T "kjv#" `shouldBe` KJVT
    it "takes the server's default for an empty setting" $
      settingOrDefault V1805T "" `shouldBe` V1805T
    it "takes the server's default for a setting that names no translation" $
      settingOrDefault V1805T "gevNarek#" `shouldBe` V1805T

  describe "parseVerseRef" $ do
    it "reads a chapter and a verse range written with : and -" $
      "Mat 5:3-12" `parsesTo` (Nothing, Matthew, 5, Just 3, Just 12, True)
    it "reads a chapter and a verse separated by spaces" $
      "Մատթ 5 3" `parsesTo` (Nothing, Matthew, 5, Just 3, Nothing, False)
    it "reads a chapter alone" $
      "Gen 1" `parsesTo` (Nothing, Genesis, 1, Nothing, Nothing, False)
    it "ignores the abbreviation's case" $
      "MATT 5 3" `parsesTo` (Nothing, Matthew, 5, Just 3, Nothing, False)
    it "takes a translation word before the book" $
      "kjv Ծննդ 1 1" `parsesTo` (Just KJVT, Genesis, 1, Just 1, Nothing, False)
    it "finds the book in the second word" $
      "read Mat 5" `parsesTo` (Nothing, Matthew, 5, Nothing, Nothing, False)
    it "takes the translation from a Narek name that has one" $
      "Նարեկացի 3 1" `parsesTo` (Just Narek_Grabar, Narek, 3, Just 1, Nothing, False)
    it "leaves the translation open for the plain Narek name" $
      "Նարեկ 3 1" `parsesTo` (Nothing, Narek, 3, Just 1, Nothing, False)
    it "refuses empty text" $
      parseVerseRef "" `shouldSatisfy` isLeft
    it "refuses an unknown book" $
      parseVerseRef "xyz 1 2" `shouldSatisfy` isLeft
    it "refuses a book without a chapter" $
      parseVerseRef "Mat" `shouldSatisfy` isLeft
    it "reads a numbered book written with a space" $ do
      "1 John 4 8" `parsesTo` (Nothing, John1, 4, Just 8, Nothing, False)
      "1 Peter 1 3" `parsesTo` (Nothing, Peter1, 1, Just 3, Nothing, False)
    it "reads a numbered book after a translation word" $
      "kjv 1 John 4 8" `parsesTo` (Just KJVT, John1, 4, Just 8, Nothing, False)
    it "reads a numbered book without its abbreviation's trailing dot" $
      "Ա Հովհ 4 8" `parsesTo` (Nothing, John1, 4, Just 8, Nothing, False)
    it "reads a numbered book whose name is listed without the space" $
      "Ա Հովհաննես 4 8" `parsesTo` (Nothing, John1, 4, Just 8, Nothing, False)
    it "reads a book whose number comes last" $
      "Թագ Ա 3 5" `parsesTo` (Nothing, Kings1, 3, Just 5, Nothing, False)
    it "keeps a one-word book when the next word is the chapter" $ do
      "John 1 1" `parsesTo` (Nothing, John, 1, Just 1, Nothing, False)
      "Ezra 1 5" `parsesTo` (Nothing, Ezra2, 1, Just 5, Nothing, False)
    it "reads the numbers after the book's name, not inside it" $ do
      "1John 4 8" `parsesTo` (Nothing, John1, 4, Just 8, Nothing, False)
      "read 1John 5 3" `parsesTo` (Nothing, John1, 5, Just 3, Nothing, False)

  describe "toRefText" $ do
    forM_ [minBound .. maxBound] $ \translation ->
      it ("names every book in " ++ show translation ++ ", with no crash and no leading space") $
        forM_ [Genesis ..] $ \book ->
          toRefText translation (VerseReference (Just translation) book 1 (Just 1) Nothing False)
            `shouldSatisfy` (\title -> not (T.null title) && T.head title /= ' ')
    it "gives Zohrab's text the 1994 text's book name where it has none of its own" $
      toRefText V1805T (VerseReference (Just V1805T) Matthew 5 (Just 3) Nothing False)
        `shouldBe` "Մատթ. 5:3, «Վէնէտիկ» 1805թ."
    it "keeps Zohrab's own book name where it has one" $
      toRefText V1805T (VerseReference (Just V1805T) Kings1 1 (Just 1) Nothing False)
        `shouldBe` "Թագաւորութիւններ Ա 1:1, «Վէնէտիկ» 1805թ."
