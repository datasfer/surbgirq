{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
module Surbgirq.Back.Server.ApiInfo(
 getApiInfo
 ) where

import Data.Aeson
import Development.GitRev

import Data.Text    (pack)
import Data.Version (showVersion)

import qualified Paths_surbgirq_service as Cabal (version)

import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------



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
