{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
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

getApiInfoHandler :: AppM GetApiInfoResponse
getApiInfoHandler = return $ GetApiInfoResponse getApiInfo



getApiInfo :: ApiInfo
getApiInfo =  ApiInfo
              { apiinfo'version   = pack $ showVersion Cabal.version
              , apiinfo'changeset = $(gitHash)
              , apiinfo'branch    = $(gitBranch)
              , apiinfo'git = object
                       [
                         "commitDate" .= concat [ $(gitCommitDate)]
                       , "commitCount" .= concat [$(gitCommitCount)]
                       , "desc" .= concat [$(gitDescribe)]
                       , "branch" .= concat [$(gitBranch), "@", $(gitHash)]
                       , "status" .=  concat [dirty, " ", dirtyTrack]
                       ]
              }
  where
    dirty | $(gitDirty) = "(uncommitted files present)"
          | otherwise   = ""

    dirtyTrack | $(gitDirtyTracked) = "(changes to tracked files present)"
               | otherwise   = ""
