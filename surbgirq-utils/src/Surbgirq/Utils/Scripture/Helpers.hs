{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Utils.Scripture.Helpers where

-- import           Data.Char
-- import           Data.List
import           Control.Applicative           ((<|>))
import           Data.Maybe
import           Data.Text                     (Text)
import qualified Data.Text                     as T
import           GHC.Unicode
import           Surbgirq.Types
import           Text.InterpolatedString.Perl6 (qc)
import           Text.Read

-- | parse text to verseRef data
-- Ղուկ. 6.20-23
-- >> e1994t mat 2
-- >>> VerseReference {verseRef'translation = Just e1994-T, verseRef'book = Matthew, verseRef'chapter = 2, verseRef'from = Nothing, verseRef'to = Nothing, verseRef'combine = False}
--
-- The translation is the reference's own translation word ("e1994t" above), or Nothing, and then the caller takes the
-- user's setting, else the server's default ('settingOrDefault'). A book abbreviation's language doesn't choose one,
-- but Narek's names do ('narekByName').
parseVerseRef :: Text -> Either Text VerseReference
parseVerseRef verseRange | T.null verseRange = Left "error: empty verse ref text"
                         | otherwise =
     let str = verseRange
         maybeTranslation = readTranslation $ take 1 $ T.words str
         combine = T.any (\x -> x ==':' || x =='-') str
     in case readGirqs str of
           Nothing -> Left [qc|Unknown book name: {verseRange}|]
           Just ((girq, trans), nameEnd) ->
               -- The numbers are read after the book's name, so a digit in it ("1John") isn't taken for the chapter.
               let translation = maybeTranslation <|> narekByName girq trans
               in case readNums nameEnd str of
                         (a:b:c:_) -> Right $ VerseReference translation girq a (Just b) (Just c) combine
                         (a:b:_)   -> Right $ VerseReference translation girq a (Just b) Nothing False
                         (a:_)     -> Right $ VerseReference translation girq a Nothing Nothing False
                         []        -> Left "Failed parse verse numbers"


-- | Narek's names that name a translation: Նարեկացի (the Grabar original), Նարեկ-Գեւ and Նարեկ-Գոչ. The plain Նարեկ
-- or Narek maps to Kheranyan's translation in the abbreviation table, but names none.
narekByName :: Girq -> TranslationID -> Maybe TranslationID
narekByName Narek trans | trans /= Narek_Xer = Just trans
narekByName _     _                          = Nothing


-- | The translation a user's setting names (the value the settings keyboard stored, such as "kjv#"), or the server's
-- default when the setting is empty or names none. A reference's own translation word comes before both.
settingOrDefault :: TranslationID -> Text -> TranslationID
settingOrDefault serverDefault setting = fromMaybe serverDefault (findTransByAbbr setting)


readNums :: Int -> Text -> [Int]
readNums n =
    catMaybes . map (readMaybe . T.unpack) . T.groupBy
                  (\x y -> isDigit x && isDigit y) . T.unwords . drop n . T.words

readTranslation :: [Text] -> Maybe TranslationID
readTranslation []  = Nothing
readTranslation [s] = findTransByAbbr s

-- | The book a reference names, and how many words it takes up to the end of the name: the chapter and the verses come
-- after it. The name starts at the first word, or at the second (after a translation word, or a word such as @read@).
-- It's one word, or two when the first isn't a name on its own: "Թագ Ա", "Ա Հովհ.", or a book's number and its name,
-- written with or without the space ("1 John"; "1 Jn" for "1Jn"). So "John 1 1" stays John, "Ezra 1 5" reads as
-- before, and "1 John 4 8" is no longer John 4:8.
readGirqs :: Text -> Maybe ((Girq, TranslationID), Int)
readGirqs txt =
    let ws = T.words txt
        starts = case readTranslation (take 1 ws) of
                   Nothing -> [0, 1]
                   Just _  -> [1]
    in listToMaybe $ mapMaybe (bookAt ws) starts
  where
    bookAt ws i = case drop i ws of
        (w : _)      | Just book <- findByAbbr w                -> Just (book, i + 1)
        (w : w' : _) | Just book <- findByAbbr (w <> " " <> w') -> Just (book, i + 2)
                     | isBookNumber w
                     , Just book <- findByAbbr (number w <> " " <> w') <|> findByAbbr (number w <> w')
                                                                -> Just (book, i + 2)
        _                                                       -> Nothing
    number = T.dropWhileEnd (== '.')
    isBookNumber w = number w `elem` bookNumbers

-- | The numbers that begin the numbered books' names, as in "1 John" and "Ա Յովհ.".
bookNumbers :: [Text]
bookNumbers = ["1", "2", "3", "4", "Ա", "Բ", "Գ", "Դ"]


verseRefRange :: VerseReference -> [VerseReference]
verseRefRange vRef@VerseReference{..} =
  case (verseRef'from, verseRef'to) of
    (Nothing, Nothing) -> [ vRef{ verseRef'from = (Just v), verseRef'to = Nothing} | v <- [1..200]]
                          -- ^ all verses from the chapter
    (Just from, Nothing) -> [vRef]
    (Nothing, Just to) -> [ vRef{ verseRef'from = (Just v), verseRef'to = Nothing} | v <- [1..to]]
    (Just from, Just to) -> [ vRef{  verseRef'from = (Just v), verseRef'to = Nothing} | v <- [from..to]]


toVerseStyle :: Int -> String
toVerseStyle  = map toSmallDigit . show

toSmallDigit :: Char -> Char
toSmallDigit '0' = '⁰'
toSmallDigit '1' = '¹'
toSmallDigit '2' = '²'
toSmallDigit '3' = '³'
toSmallDigit '4' = '⁴'
toSmallDigit '5' = '⁵'
toSmallDigit '6' = '⁶'
toSmallDigit '7' = '⁷'
toSmallDigit '8' = '⁸'
toSmallDigit '9' = '⁹'

