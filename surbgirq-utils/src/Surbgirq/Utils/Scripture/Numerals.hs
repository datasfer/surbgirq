{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}


module Surbgirq.Utils.Scripture.Numerals where

import Data.Aeson (Value)
import Data.Text  (Text)
import Text.Read  (readMaybe)

import Common.Aeson
import Data.List
import Data.Maybe
import GHC.Generics

import Prelude hiding (lookup)

import           Data.Map.Strict               (Map)
import qualified Data.Map.Strict               as Map
import qualified Data.Text                     as T
import           Text.InterpolatedString.Perl6 (qc)


import Surbgirq.Types.Girq

------------------------------------------------------------
--
------------------------------------------------------------

-- (Մարկ. 1.1-8, Ղուկ. 3.1-18, Յովհ. 1.19-28, Մատթ. 1.1-3)



miavors = ['Ա'..'Թ']
tasnavors = ['Ժ'..'Ղ']
haryuravors = ['Ճ'..'Ջ']
hazaravors = ['Ռ'..'Ք']

toDigits :: Int -> [Int]
toDigits n = map read . map (:[]) $ show n

toNumeral :: Int -> Maybe String
toNumeral n | n > 9999 = Nothing
            | otherwise = Just $ case toDigits n of
                            [m] -> [qc|{getMiavor m}|]
                            [t, m] -> [qc|{getTasnavor t}{getMiavor m}|]
                            [h, t, m] -> [qc|{getHaryuravor h}{getTasnavor t}{getMiavor m}|]
                            [hh, h, t, m] -> [qc|{getHazaravor hh}{getHaryuravor h}{getTasnavor t}{getMiavor m}|]

   where
     getMiavor n = miavors !! (n - 1)
     getTasnavor n = tasnavors !! (n - 1)
     getHaryuravor n = haryuravors !! (n - 1)
     getHazaravor n = hazaravors !! (n - 1)


toNumber :: String -> Maybe Int
toNumber numeral | length  numeral > 4 = Nothing
                 | otherwise = readMaybe $ case numeral of
                            [m] -> [qc|{getMiavor m}|]
                            [t, m] -> [qc|{getTasnavor t}{getMiavor m}|]
                            [h, t, m] -> [qc|{getHaryuravor h}{getTasnavor t}{getMiavor m}|]
                            [hh, h, t, m] -> [qc|{getHazaravor hh}{getHaryuravor h}{getTasnavor t}{getMiavor m}|]
   where
     getMiavor n = findIndex (== n) miavors
     getTasnavor n = findIndex (== n) tasnavors
     getHaryuravor n = findIndex (== n) haryuravors
     getHazaravor n = findIndex (== n) hazaravors








