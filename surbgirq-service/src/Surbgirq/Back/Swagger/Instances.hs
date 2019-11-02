{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

{-|
Module      : Surbgirq.Back.Swagger.Instances
Description : Instances for Swagger schemes

Implement Swagger schemes instances
-}

module Surbgirq.Back.Swagger.Instances where

import Control.Lens ((&), (.~), (?~))
import Data.Swagger

import Data.Aeson (Value)
import Data.Char  (isLower, isPunctuation, isUpper, toLower)
import Data.List
import Data.Proxy


import Surbgirq.API
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

instance ToSchema Girq
instance ToParamSchema Testament
instance ToSchema Testament
instance ToParamSchema Language
instance ToSchema Language
instance ToParamSchema ChapterNum
instance ToParamSchema SectionNum
instance ToParamSchema VerseNum
instance ToParamSchema Girq

instance ToSchema Value where
    declareNamedSchema = genericDeclareNamedSchemaUnrestricted $ stripPrefixOption "aeson-value'"

instance ToSchema Chapter where
    declareNamedSchema = genericDeclareNamedSchema $ stripPrefixOption "chapter'"

instance ToSchema Section where
    declareNamedSchema = genericDeclareNamedSchema $ stripPrefixOption "section'"

instance ToSchema Verse where
    declareNamedSchema = genericDeclareNamedSchema $ stripPrefixOption "verse'"

instance ToSchema Book where
    declareNamedSchema = genericDeclareNamedSchema $ stripPrefixOption "book'"

instance ToSchema GetApiInfoResponse where
    declareNamedSchema = genericDeclareNamedSchema $ stripPrefixOption "apiInfoResponse'"

instance ToSchema ApiInfo where
    declareNamedSchema = genericDeclareNamedSchema $ stripPrefixOption "apiinfo'"


stripPrefixOption prefix = defaultSchemaOptions {
                               fieldLabelModifier = headToLower . stripExactPrefix prefix . dropPunctuation
                           }


stripConstructorPrefix :: String -> String
stripConstructorPrefix t =
   maybe t (flip drop t . decrementSafe) $ findIndex isLower t
 where
   decrementSafe 0 = 0
   decrementSafe i = i - 1


dropPunctuation :: String -> String
dropPunctuation = filter (not . isPunctuation)


-- | Converts first symbol to lower case
headToLower :: String -> String
headToLower []           = []
headToLower (x:xs@(y:_)) = (if isLower y then toLower else id) x : xs -- So that HTTP remains as is
headToLower (x:xs)       = toLower x : xs


-- | Strip prefix of name that exactly matches specified prefix
stripExactPrefix ::
    String -- ^ Prefix
 -> String -- ^ Name
 -> String -- ^ Name without prefix
stripExactPrefix = go
   where
   go [] name = name
   go (p : ps) name@(x : xs)
       | p == x = go ps xs
       | otherwise = name
   go _ [] = []
