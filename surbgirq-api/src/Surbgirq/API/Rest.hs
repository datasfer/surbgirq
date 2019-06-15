{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}


module Surbgirq.API.Rest where

import Data.Int    (Int64)
import Servant.API

import Servant.API.Generic
import Surbgirq.API.Types
import Surbgirq.Types

------------------------------------------------------------
-- Bex API endpoints
------------------------------------------------------------
type GetApiInfoEndpoint = "info" :> Summary "Get Api Information"
    :> Get '[JSON] GetApiInfoResponse


type GetBooksListEndpoint = "books" :> Summary "Get Available Books" :> Get '[JSON] [Book]

type GetChapterEndpoint = "chapter"   :> Summary "Get Chapter"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Get '[JSON] [Chapter]

type GetSectionEndpoint = "section"   :> Summary "Get Section"
    :> Capture "girq" Girq
    :> Capture "ch" Int
    :> Capture "sec" Int
    :> Get '[JSON] Section

type GetParagraphEndpoint = "paragraph" :> Summary "Get Paragraph" :> Get '[JSON] Paragraph
type GetVerseEndpoint = "verse"     :> Summary "Get Verse"     :> Get '[JSON] Verse

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
type SurbgirqRestAPI = "api" :> (
            GetApiInfoEndpoint
       :<|> GetBooksListEndpoint
       :<|> GetChapterEndpoint
      )
