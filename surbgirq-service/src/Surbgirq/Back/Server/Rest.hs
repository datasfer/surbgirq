{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

module Surbgirq.Back.Server.Rest(
   getApiInfoHandler
 , getBooksHandler
 , getChapterHandler
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

import Surbgirq.Neo4j
import Surbgirq.Types

-----------------------------------------------------------------
--  Api info

getApiInfoHandler :: AppM GetApiInfoResponse
getApiInfoHandler = return $ GetApiInfoResponse getApiInfo


getBooksHandler :: AppM [Book]
getBooksHandler = undefined


getChapterHandler :: Girq -> Int -> AppM Chapter
getChapterHandler girq ch_num = undefined -- getChapterNode girq ch_num
