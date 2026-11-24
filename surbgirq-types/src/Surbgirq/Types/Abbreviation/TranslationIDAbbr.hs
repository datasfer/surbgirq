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


-- | Every form a translation is known by, e.g. in the verse explorer's paths (scripture/z1805/books or
-- scripture/z1805-T/books) and in the user's settings. The first two come from the translation itself, so none can be
-- missing: its ID ('show', "z1805-T") and the value the settings keyboard stores ('toCmd', "z1805#"). Then the short
-- forms people type.
abbr :: [AbbrTrans]
abbr = [ AbbrTrans t (T.pack (show t) : toCmd t : typed t) | t <- [minBound .. maxBound] ]
  where
    typed t = case t of
      E1994T -> ["e1994T", "e1994", "e94", "e94T"]
      E2004T -> ["e2004T", "e2004", "e04", "e04T"]
      V1805T -> ["v1805T", "v1805", "v05", "v05T"]
      Z1805T -> ["z1805T", "z1805"]
      AR94T  -> ["ar94", "ar94T"]
      KJVT   -> ["kjvT", "kjv"]
      _      -> []
