{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Back.Server.Rest(
   getApiInfoHandler
 ) where


import Control.Monad.Reader
import Data.Time.Clock.POSIX

import Data.Maybe                    (fromMaybe)
import Data.String                   (IsString(..))
import Data.Text                     (pack, unpack)
import GHC.Int                       (Int64)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.ByteString.Char8  as BC8
import qualified Database.SQLite.Simple as SQL

import Surbgirq.API

import Surbgirq.Back.App.Env
import Surbgirq.Back.Server.ApiInfo

import Surbgirq.Types

-----------------------------------------------------------------
--  Api info

getApiInfoHandler :: AppM GetApiInfoResponse
getApiInfoHandler = return $ GetApiInfoResponse getApiInfo
