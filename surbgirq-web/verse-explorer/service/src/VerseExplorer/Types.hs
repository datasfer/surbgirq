{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TupleSections              #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE TypeOperators              #-}

module VerseExplorer.Types where

import Control.Monad.IO.Class
import Control.Monad.Logger
import Control.Monad.Reader
import Data.Typeable
import Web.Internal.FormUrlEncoded

import Data.Aeson   (FromJSON, ToJSON, Value, object, (.=))
import Data.Int     (Int64)
import Data.String  (IsString(..))
import Data.Text    (Text)
import GHC.Generics (Generic)

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

-- | About page
data About = About Text
             deriving (Generic, Show)

instance FromJSON About
instance ToJSON About
-------------------------------------------------------------------------------
-- NotFound page

-- | not found page
data NotFound = NotFound
  { notFound'msg   :: Text
  } deriving (Generic, Show)


-------------------------------------------------------------------------------
-- Apiinfo

-- | Api info, git tags, hashes ...
data ApiInfo = ApiInfo
  { apiinfo'version   :: Text
  , apiinfo'changeset :: Text
  , apiinfo'branch    :: Text
  , apiinfo'git       :: Value
  } deriving (Generic, Show)



-- | Data type to pass the search word from front
data SearchRequest = SearchRequest
    {
      searchWord :: Text
    } deriving (Show, Generic)

instance FromJSON SearchRequest
instance ToJSON SearchRequest

instance FromForm SearchRequest where
  fromForm f = SearchRequest <$> parseUnique "word" f


data SearchFound = FoundNothing
                 | FoundVerse [Text]
                   deriving (Show, Generic)

instance FromJSON SearchFound
instance ToJSON SearchFound

