{-|
Module      : Common.Aeson
Description : Re-export some Aeson functions and set up TH options

Re-export some Aeson functions and set up TH options
-}

module Common.Aeson(
    A.deriveJSON
  , A.deriveToJSON
  , A.deriveFromJSON
  , ToJSON(..)
  , FromJSON(..)
  , ToJSONKey(..)
  , FromJSONKey(..)
  , dropPrefixOptions
  ) where

import Data.Aeson       (decode, decode', encode)
import Data.Aeson.TH    (Options(..), SumEncoding(..))
import Data.Aeson.Types (FromJSON(..), FromJSONKey(..), ToJSON(..), ToJSONKey(..))
import Data.Char        (isLower, isPunctuation, isUpper, toLower)
import Data.List        (findIndex)

import qualified Data.Aeson.TH        as A
import qualified Data.ByteString      as B
import qualified Data.ByteString.Lazy as LB
import qualified Data.List            as L

------------------------------------------------------------
--
------------------------------------------------------------
dropPrefixOptions :: Options
dropPrefixOptions =
   A.defaultOptions
   { fieldLabelModifier = headToLower . stripFieldPrefix
   , constructorTagModifier = stripConstructorPrefix
   , omitNothingFields = True
   , sumEncoding = ObjectWithSingleField
   }

-- | Converts first symbol to lower case
headToLower :: String -> String
headToLower []           = []
headToLower (x:xs@(y:_)) = (if isLower y then toLower else id) x : xs
headToLower (x:xs)       = toLower x : xs

-- | Drop prefix of name until first upper letter is occured
stripFieldPrefix :: String -> String
stripFieldPrefix str = case b of
  []   -> dropWhile (not . isUpper) str
  _:xs -> xs
  where
    (_, b) = L.span (/= '\'') str


-- | Drop upper case prefix from constructor name
stripConstructorPrefix :: String -> String
stripConstructorPrefix t =
   maybe t (flip drop t . decrementSafe) $ findIndex isLower t
 where
   decrementSafe 0 = 0
   decrementSafe i = i - 1

