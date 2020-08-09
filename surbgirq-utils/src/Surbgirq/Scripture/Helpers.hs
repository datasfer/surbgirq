{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

module Surbgirq.Types.Scripture.Helpers where

-- import           Data.Char
-- import           Data.List
import           Data.Maybe
import           Data.Text                     (Text)
import qualified Data.Text                     as T
import           GHC.Unicode
import           Surbgirq.Types.Abbr
import           Surbgirq.Types.Girq
import           Text.InterpolatedString.Perl6 (qc)
import           Text.Read

-- | parse text to verseRef data
-- Ղուկ. 6.20-23

parseVerseRef :: Text -> Either Text VerseRef
parseVerseRef verseRange | T.null verseRange = Left "error: empty verse ref text"
                         | otherwise =
     let str = verseRange
         gs = readGirqs str
         ns = readNums str
     in case gs of
           [] -> Left [qc|Unknown book name: {verseRange}|]
           (girq:_) -> case ns of
                         (a:b:c:_) -> Right $ VerseRef girq a b (Just c)
                         (a:b:_)   -> Right $ VerseRef girq a b Nothing
                         _         -> Left "Failed parse verse numbers"


readNums :: Text -> [Int]
readNums  = catMaybes . map (readMaybe . T.unpack) . T.groupBy (\x y -> isDigit x && isDigit y)


readGirqs :: Text -> [Girq]
readGirqs  = catMaybes . map findByAbbr . T.groupBy (\x y -> isAlpha x && isAlpha y)
