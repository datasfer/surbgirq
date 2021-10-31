{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}


module Surbgirq.Utils.Scripture.ArmenianNumerals where

import Data.Aeson (Value)
import Data.Char  (toUpper)
import Data.Maybe (catMaybes)
import Data.Text  (Text)
import Text.Read  (readMaybe)

import Common.Aeson
import Data.List

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


-- |
-- add dumy simbol at beginning to force index start from 1 on forward
miavors     = '_' : ['Ա'..'Թ']
tasnavors   = '_' : ['Ժ'..'Ղ']
haryuravors = '_' : ['Ճ'..'Ջ']
hazaravors  = '_' : ['Ռ'..'Ք']

ranks = [1, 10, 100, 1000]

majuscules  = [miavors, tasnavors, haryuravors, hazaravors]

findWeight c = (\(a,b) -> (a *) <$> b) <$> ( zip ranks  xs)
       where
         xs = let uC = toUpper c
              in findIndex (==uC) <$> majuscules


toDigits :: Int -> [Int]
toDigits n = map read . map (:[]) $ show n

toArmenianNumeral :: Int -> Maybe String
toArmenianNumeral n | n > 9999 = Nothing
                    | otherwise = Just $ case toDigits n of
                            [m] -> [qc|{getMiavor m}|]
                            [t, m] -> [qc|{getTasnavor t}{getMiavor m}|]
                            [h, t, m] -> [qc|{getHaryuravor h}{getTasnavor t}{getMiavor m}|]
                            [hh, h, t, m] -> [qc|{getHazaravor hh}{getHaryuravor h}{getTasnavor t}{getMiavor m}|]

   where
     getMiavor n = miavors !! n
     getTasnavor n = tasnavors !! n
     getHaryuravor n = haryuravors !! n
     getHazaravor n = hazaravors !! n


-- |
-- > fromArmenianNumber "ՌՋՀԵ"
-- >>> 1975
-- > fromArmenianNumber "ՍՄԻԲ"
-- >>> 2222
-- > fromArmenianNumber "ՍԴ"
-- >>> 2004
-- > fromArmenianNumber "ՃԻ"
-- >>> 120
-- > fromArmenianNumber "Ծ"
-- >>> 50
fromArmenianNumber :: String -> Int
fromArmenianNumber  = sum . catMaybes . concatMap findWeight


toNumber1 :: String -> String
toNumber1 numeral | length  numeral > 4 = "121"
                 | otherwise = case numeral of
                            [m] -> [qc|{getMiavor m}|]
                            [t, m] -> [qc|{getTasnavor t}{getMiavor m}|]
                            [h, t, m] -> [qc|{getHaryuravor h}{getTasnavor t}{getMiavor m}|]
                            [hh, h, t, m] -> [qc|{getHazaravor hh}{getHaryuravor h}{getTasnavor t}{getMiavor m}|]

   where
     getMiavor n = findIndex (== n) miavors
     getTasnavor n = findIndex (== n) tasnavors
     getHaryuravor n = findIndex (== n) haryuravors
     getHazaravor n = findIndex (== n) hazaravors









