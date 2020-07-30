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


-- (  Մատթ. 3.1-12, Ղուկ. 3.1-18, Յովհ. 1.19-28
abbrBooksAm :: Map Girq String -- AbbrMap
abbrBooksAm = Map.fromList
            [ (Matthew, "Մատթ.")
            , (Mark, "Ղուկ.")
            , (John, "Յովհ.")]
