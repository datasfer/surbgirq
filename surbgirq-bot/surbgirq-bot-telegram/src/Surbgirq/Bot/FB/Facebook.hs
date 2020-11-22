{-# LANGUAGE AllowAmbiguousTypes        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE ViewPatterns               #-}

module Surbgirq.Bot.FB.Facebook where

import Control.Monad                 (replicateM)
import Data.Char                     (isNumber)
import Data.List                     (intercalate, intersperse)
import Data.List.Split               (chunksOf)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Lucid

import Control.Monad.Except
import Control.Monad.Reader
import Data.Aeson
import Data.Maybe
import Data.Monoid
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.Server
import System.Environment
import Text.Regex.Posix

import Surbgirq.Bot.Lucid.Instances
import Surbgirq.Bot.Server
import Surbgirq.Types
import Surbgirq.Utils

------------------------------------------------------------
--
------------------------------------------------------------
