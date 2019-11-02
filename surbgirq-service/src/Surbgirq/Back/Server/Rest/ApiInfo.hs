{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

{-|
Module      : Surbgirq.Back.Server.Rest.ApiInfo
Description : Api info handler

Implement method to return the api information (version and etc.)
-}

module Surbgirq.Back.Server.Rest.ApiInfo(
 getApiInfoHandler
 ) where

import Data.Aeson
import Development.GitRev

import Data.Text    (pack)
import Data.Version (showVersion)

import qualified Paths_surbgirq_service as Cabal (version)

import Surbgirq.API
import Surbgirq.Back.App.Env
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

-- | get api info endpoint' handler
getApiInfoHandler :: AppM GetApiInfoResponse
getApiInfoHandler = return $ GetApiInfoResponse getApiInfo


-- | fill @ApiInfo data with cabal version and git information
getApiInfo :: ApiInfo
getApiInfo =  ApiInfo
              { apiinfo'version   = pack $ showVersion Cabal.version
              , apiinfo'changeset = $(gitHash)
              , apiinfo'branch    = $(gitBranch)
              , apiinfo'git = object
                       [
                         "commitDate" .= ($(gitCommitDate) :: String)
                       , "commitCount" .= ($(gitCommitCount) :: String)
                       , "desc" .= ($(gitDescribe) :: String)
                       , "branch" .= concat [$(gitBranch), "@", $(gitHash)]
                       , "status" .=  concat [dirty, " ", dirtyTrack]
                       ]
              }
  where
    dirty | $(gitDirty) = "(uncommitted files present)"
          | otherwise   = ""

    dirtyTrack | $(gitDirtyTracked) = "(changes to tracked files present)"
               | otherwise   = ""
