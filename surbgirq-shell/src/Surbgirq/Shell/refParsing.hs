{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.RefParsing where

import Text.InterpolatedString.Perl6 (qc)

import Data.Text(Text)

import qualified Data.Text as T


refSample :: Text
refSample = "Մարկ. 9.49, Ղուկ. 14.34-35"    
    
parse1994Ref :: Text -> [Text]
parse1994Ref ref =
    let xs = T.splitOn "," ref
    in concatMap (T.splitOn " ") xs
