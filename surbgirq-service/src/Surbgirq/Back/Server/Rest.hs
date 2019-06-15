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

import Control.Monad.Trans (lift, liftIO)
-- import Control.Monad.Trans.Reader (ask)

import Data.Maybe  (fromMaybe)
import Data.Pool   (withResource)
import Data.String (IsString(..))
import Data.Text   (pack, unpack)
import GHC.Int     (Int64)

import Text.InterpolatedString.Perl6 (qc)

import Database.Bolt hiding (pack)

import qualified Data.ByteString.Char8  as BC8
import qualified Database.SQLite.Simple as SQL

import Surbgirq.API
import Surbgirq.Back.App.Env
import Surbgirq.Back.Server.ApiInfo
import Surbgirq.Neo4j
import Surbgirq.Types

-----------------------------------------------------------------
--  Api info

runQ :: BoltActionT IO a -> AppM a
runQ act = do env <- ask
              liftIO $ withResource (env'pool env) (`run` act)

getApiInfoHandler :: AppM GetApiInfoResponse
getApiInfoHandler = return $ GetApiInfoResponse getApiInfo


getBooksHandler :: AppM [Book]
getBooksHandler = runQ $ queryBooks


getChapterHandler :: Girq -> ChapterNum -> AppM [Chapter]
getChapterHandler girq ch_num = runQ $ queryChapter girq ch_num
--    getChapterNode girq ch_num
