{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Types.Abbr where

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
findByAbbr str = listToMaybe $ snd <$> filter (\ (xs, girq) -> any (==str) xs) abbr


-- (Մարկ. 1.1-8, Ղուկ. 3.1-18, Յովհ. 1.19-28, Մատթ. 1.1-3)

abbr = [ (["Մատթ", "Մատթ", "Mat", "Matt","mat", "matt"], Matthew)
       , (["Ղուկ.", "Mark", "mark"], Mark)
       , (["Յովհ.", "John", "john"], John)
       ]

-- (  Մատթ. 3.1-12, Ղուկ. 3.1-18, Յովհ. 1.19-28
abbrBooks :: Map Text Girq -- AbbrMap
abbrBooks = Map.fromList
            [ ("Մատթ.", Matthew)
            , ("Ղուկ.", Mark)
            , ("Յովհ.", John)]
