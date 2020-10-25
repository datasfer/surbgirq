{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Utils.Scripture.Abbr where

import Common.Aeson
import Data.Aeson   (Value)
import Data.Maybe
import Data.Text    (Text)
import GHC.Generics

import Prelude hiding (lookup)

import           Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map


import Surbgirq.Types.Girq


-- newtype  AbbrMap = Map.Map Text Girq


findByAbbr :: Text -> Maybe Girq
findByAbbr name = listToMaybe $ fst <$> filter (\ (girq, xs) ->  any (==name) xs) abbr


-- (Մարկ. 1.1-8, Ղուկ. 3.1-18, Յովհ. 1.19-28, Մատթ. 1.1-3)
abbr :: [(Girq, [Text])]
abbr = [ (Matthew, ["Մատթ.", "Մատթ", "Մտ", "Mt", "Mat", "Matt","mat", "matt", "Matthew"])
       , (Mark,    ["Մարկ", "Մր", "Mark", "Mk", "mark"])
       , (Luke,    ["Ղուկ.", "Ղուկ", "Ղկ", "Lk", "Luke", "Luk"])
       , (John,    [ "Յովհ.", "Յովհ", "Յհ", "John", "john"])
       , (Acts, ["Գրծ", "Acts"])
       , (James, ["Յկ", "Jas", "James" ])
       , (Peter1, ["Ա Պտ", "1Pet"])
       , (Peter2, ["Բ Պտ", "2Pet"])
       , (John1, ["Ա Յհ", "1John"])
       , (John2, ["Բ Յհ", "2John"])
       , (John3, ["Գ Յհ", "3John"])
       , (Jude, ["Յդ", "Jude"])
       , (Romans, ["Հռ", "Rom"])
       , (Corinthians1, ["Ա Կր", "1Cor"])
       , (Corinthians2, ["Բ Կր", "2Cor"])
       , (Galatians, ["Գղ", "Gal"])
       , (Ephesians, ["Եփ", "Eph"])
       , (Philippians, ["Փպ", "Phil"])
       , (Colossians, ["Կղ", "Col"])
       , (Thessalonians1, ["Ա Թս"])
       , (Thessalonians2, ["Բ Թս"])
       , (Hebrews, ["Եբ", "Heb"])
       , (Timothy1, ["Ա Տմ", "1Tim"])
       , (Timothy2, ["Բ Տմ", "2Tim"])
       , (Titus, ["Տտ", "Titus"])
       , (Philemon, ["Փմ", "Phlm"])
       , (Revelation, ["Յտ", "Rev"])
       ]


