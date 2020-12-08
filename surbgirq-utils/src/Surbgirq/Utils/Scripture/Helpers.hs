{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Utils.Scripture.Helpers where

-- import           Data.Char
-- import           Data.List
import           Data.Maybe
import           Data.Text                     (Text)
import qualified Data.Text                     as T
import           GHC.Unicode
import           Surbgirq.Types.Girq
import           Surbgirq.Types.Scripture
import           Surbgirq.Utils.Scripture.Abbr
import           Text.InterpolatedString.Perl6 (qc)
import           Text.Read

-- | parse text to verseRef data
-- Ղուկ. 6.20-23

parseVerseRef :: Text -> Either Text VerseReference
parseVerseRef verseRange | T.null verseRange = Left "error: empty verse ref text"
                         | otherwise =
     let str = verseRange
         gs = readGirqs str
         ns = readNums str
         translation = E1994T
     in case gs of
           [] -> Left [qc|Unknown book name: {verseRange}|]
           (girq:_) -> case ns of
                         (a:b:c:_) -> Right $ VerseReference translation girq a (Just b) (Just c)
                         (a:b:_)   -> Right $ VerseReference translation girq a (Just b) Nothing
                         (a:_)     -> Right $ VerseReference translation girq a Nothing Nothing
                         []        -> Left "Failed parse verse numbers"


readNums :: Text -> [Int]
readNums  = catMaybes . map (readMaybe . T.unpack) . T.groupBy (\x y -> isDigit x && isDigit y) . T.unwords . drop 1 . T.words


readGirqs :: Text -> [Girq]
readGirqs txt = case T.words txt of
                  (x:xs) -> catMaybes $ [findByAbbr x] -- . T.groupBy (\x y -> isAlpha x && isAlpha y)
                  _      -> []


verseRefRange :: VerseReference -> [VerseReference]
verseRefRange vRef@VerseReference{..} =
  case (verseRef'from, verseRef'to) of
    (Nothing, Nothing) -> [ vRef{ verseRef'from = (Just v), verseRef'to = Nothing} | v <- [1..200]]
                          -- ^ all verses from the chapter
    (Just from, Nothing) -> [vRef]
    (Nothing, Just to) -> [ vRef{ verseRef'from = (Just v), verseRef'to = Nothing} | v <- [1..to]]
    (Just from, Just to) -> [ vRef{  verseRef'from = (Just v), verseRef'to = Nothing} | v <- [from..to]]

