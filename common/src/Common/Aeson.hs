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

import Data.Aeson(decode, decode', encode)
import Data.Aeson.TH (Options (..), SumEncoding (..))
import Data.Aeson.Types (ToJSON(..), FromJSON(..), ToJSONKey(..), FromJSONKey(..))
import Data.Char (isUpper, toLower, isLower, isPunctuation)
import Data.List (findIndex)

import qualified Data.Aeson.TH as A
import qualified Data.List as L
import qualified Data.ByteString.Lazy as LB
import qualified Data.ByteString as B




    
-- | Converts first symbol to lower case
headToLower :: String -> String
headToLower [] = []
headToLower (x:xs@(y:_)) = (if (isLower y) then toLower else id) x : xs
                           -- So that HTTP remains as is
headToLower (x:xs) = toLower x : xs

-- | Drop prefix of name until first upper letter is occured
stripFieldPrefix :: String -> String
stripFieldPrefix str = case b of
  []   -> dropWhile (not . isUpper) str
  _:xs -> xs
  where
    (_, b) = L.span (/= '\'') str

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

-- | Remove from names things like ' and etc
dropPunctuation :: String -> String
dropPunctuation = filter (not . isPunctuation)

-- | Drop upper case prefixes from constructor names
--
-- Example:
-- >>> stripConstructorPrefix "ABCombo"
-- "Combo"
--
-- >>> stripConstructorPrefix "Combo"
-- "Combo"
stripConstructorPrefix :: String -> String
stripConstructorPrefix t =
   maybe t (flip drop t . decrementSafe) $ findIndex isLower t
 where
   decrementSafe 0 = 0
   decrementSafe i = i - 1

-- | Options for aeson TH generator, that generates following fields:
--
-- * without punctuation
-- * without lowercase prefix
--
-- And generates constructor tags without uppercase prefixes with
-- 'stripConstructorPrefix'.
--
-- Sums are encoded as one object with only one field corresponding the
-- constructor used.
dropPrefixOptions :: Options
dropPrefixOptions =
   A.defaultOptions
   { fieldLabelModifier = headToLower . stripFieldPrefix
   , constructorTagModifier = stripConstructorPrefix
   , omitNothingFields = True
   , sumEncoding = ObjectWithSingleField
   }
