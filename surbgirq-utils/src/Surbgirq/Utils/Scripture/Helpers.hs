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
     in case gs of
           [] -> Left [qc|Unknown book name: {verseRange}|]
           (girq:_) -> case ns of
                         []        -> Left "Failed parse verse numbers"
                         (a:b:c:_) -> Right $ VerseReference girq a b (Just c)
                         (a:b:_)   -> Right $ VerseReference girq a b Nothing
                         _         -> Left "Failed parse verse numbers"



readNums :: Text -> [Int]
readNums  = catMaybes . map (readMaybe . T.unpack) . T.groupBy (\x y -> isDigit x && isDigit y)


readGirqs :: Text -> [Girq]
readGirqs  = catMaybes . map findByAbbr . T.groupBy (\x y -> isAlpha x && isAlpha y)


verseRefRange :: VerseReference -> [VerseReference]
verseRefRange vRef@VerseReference{..} =
  case verseRef'to of
    Nothing -> [vRef]
    Just to -> [ VerseReference  verseRef'book verseRef'chapter verseRef'from (Just toV) | toV <- [verseRef'from..to]]
