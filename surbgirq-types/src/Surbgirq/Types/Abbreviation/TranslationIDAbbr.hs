{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Types.Abbreviation.TranslationIDAbbr
    ( findTransByAbbr
    )
    where

import Common.Aeson
import Data.Aeson   (Value)
import Data.Maybe
import Data.Text    (Text)
import GHC.Generics

import Prelude hiding (lookup)

import Data.Map.Strict               (Map)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.Map.Strict as Map
import qualified Data.Text       as T


import Surbgirq.Types.Scripture

------------------------------------------------------------
--
------------------------------------------------------------

data AbbrTrans = AbbrTrans TranslationID [Text]


findTransByAbbr :: Text -> Maybe TranslationID
findTransByAbbr name = findAbbr name abbr
  where
    findAbbr :: Text -> [AbbrTrans] -> Maybe TranslationID
    findAbbr _ [] = Nothing
    findAbbr name ( AbbrTrans t ts : xs ) | any (\b -> T.toLower b == T.toLower name) ts = Just t
                                        | otherwise = findAbbr name xs


-- | list all version of string we expected to get as request param for translation param in verse explorer app
-- | e.g. scripture/z1805/books -  or scripture/z1805-T/books
abbr :: [AbbrTrans]
abbr  = [ AbbrTrans E1994T ["e1994-T", "e1994T", "e1994", "e94", "e94T", "e1994#"]
        , AbbrTrans E2004T ["e2004-T", "e2004T", "e2004", "e04", "e04T"]
        , AbbrTrans V1805T ["v1805-T", "v1805T", "v1805", "v05", "v05T"]
        , AbbrTrans Z1805T ["z1805-T", "z1805T", "z1805"]
        , AbbrTrans AR94T ["ar94", "ar94-T", "ar94T"]
        , AbbrTrans SinodalT [""]
        , AbbrTrans KJVT ["kjv-T", "kjvT", "kjv"]

        , AbbrTrans Narek_Grabar ["narekaci-T", "narek_grabar#"]
        , AbbrTrans Narek_Xer    ["narek_xer-T", "narek_xer#"]
        , AbbrTrans Narek_Gev    ["narek_gev-T", "narek_gev#"]
        , AbbrTrans Narek_Goch   ["narek_goch-T", "narek_gocj#"]
        ]
