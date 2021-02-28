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
import           Surbgirq.Types
import           Text.InterpolatedString.Perl6 (qc)
import           Text.Read

-- | parse text to verseRef data
-- Ղուկ. 6.20-23

parseVerseRef :: Text -> Either Text VerseReference
parseVerseRef verseRange | T.null verseRange = Left "error: empty verse ref text"
                         | otherwise =
     let str = verseRange
         ws = T.words str
         gs = readGirqs str
         maybeTranslation = readTranslation $ take 1 ws
         skip = maybe 1 (const 2) maybeTranslation
         ns' = readNums skip str
         ns = if null ns' then readNums 2 str else ns'
     in case gs of
           Nothing -> Left [qc|Unknown book name: {verseRange}|]
           Just (girq, trans) ->
               let translation = Just $ fromMaybe trans maybeTranslation
               in case ns of
                         (a:b:c:_) -> Right $ VerseReference translation girq a (Just b) (Just c)
                         (a:b:_)   -> Right $ VerseReference translation girq a (Just b) Nothing
                         (a:_)     -> Right $ VerseReference translation girq a Nothing Nothing
                         []        -> Left "Failed parse verse numbers"


readNums :: Int -> Text -> [Int]
readNums n =
    catMaybes . map (readMaybe . T.unpack) . T.groupBy
                  (\x y -> isDigit x && isDigit y) . T.unwords . drop n . T.words

readTranslation :: [Text] -> Maybe TranslationID
readTranslation []  = Nothing
readTranslation [s] = findTransByAbbr s

readGirqs :: Text -> Maybe (Girq, TranslationID)
readGirqs txt =
    let ws = T.words txt
        trans = readTranslation $ take 1 ws
    in case (ws, trans) of
         ((x:y:xs), Nothing) -> listToMaybe $ catMaybes $ ([findByAbbr x]) ++ ([findByAbbr y])
         ((_:x:xs), Just _)  -> findByAbbr x -- . T.groupBy (\x y -> isAlpha x && isAlpha y)
         _                   -> Nothing


verseRefRange :: VerseReference -> [VerseReference]
verseRefRange vRef@VerseReference{..} =
  case (verseRef'from, verseRef'to) of
    (Nothing, Nothing) -> [ vRef{ verseRef'from = (Just v), verseRef'to = Nothing} | v <- [1..200]]
                          -- ^ all verses from the chapter
    (Just from, Nothing) -> [vRef]
    (Nothing, Just to) -> [ vRef{ verseRef'from = (Just v), verseRef'to = Nothing} | v <- [1..to]]
    (Just from, Just to) -> [ vRef{  verseRef'from = (Just v), verseRef'to = Nothing} | v <- [from..to]]

