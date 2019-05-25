{-# LANGUAGE DataKinds   #-}
{-# LANGUAGE TypeOperators   #-}


module Surbgirq.API.Rest where

import Data.Int    (Int64)
import Servant.API

import Surbgirq.API.Types

------------------------------------------------------------
-- Bex API endpoints
------------------------------------------------------------
type GetApiInfoEndpoint = "info" :> Summary "Get Api Information"
    :> Get '[JSON] GetApiInfoResponse

{-       
type GetBlockEndpoint = "block" :> Summary "Get Block of level :height"
    :> Capture ":height" Int64
    :> Get '[JSON] GetBlockInfoResponse

type GetBlockchainStatusEndpoint = "blockchain"
    :> "status"
    :> Summary "Blockchain status"
    :> Get '[JSON]  GetBChainStatusResponse

type PostBlockListEndpoint = "blocks" :> Summary "Get Blocks list"
    :> ReqBody '[JSON] PostBlockListRequest
    :> Post '[JSON] PostBlockListResponse


type PostSearchByHashEndpoint = "blocks" :> "search" :> Summary "Search by hash"
    :> ReqBody '[JSON] PostSearchByHashRequest
    :> Post '[JSON] PostSearchByHashResponse


type InitBlocksPageEndpoint = "initblocks" :> Summary "Get first page Blocks list if any and information to render the pagination buttons"
    :> ReqBody '[JSON] InitBlocksPageRequest
    :> Post '[JSON] PostBlockListResponse

-}
type BexRestAPI = "api" :> GetApiInfoEndpoint
