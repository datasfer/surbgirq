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

type GetChapterSectionsEndpoint = "sections"   :> Summary "Get Sections of Chapter"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Get '[JSON] [Section]

type GetChapterVersesEndpoint = "verse"   :> Summary "Get all Verses of Chapter"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Get '[JSON] [Verse]

type GetVerseEndpoint = "verse"   :> Summary "Get Verse by number"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Capture "verse" VerseNum
    :> Get '[JSON] [Verse]

type GetVerseIntervalEndpoint = "verses" :> Summary "Get Verse interval"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Capture "verseFrom" VerseNum
    :> Capture "verseTo" VerseNum
    :> Get '[JSON] [Verse]

type GetSectionEndpoint = "section"   :> Summary "Get Section"
    :> Capture "girq" Girq
    :> Capture "ch"   ChapterNum
    :> Capture "sec"  SectionNum
    :> Get '[JSON] Section

type GetParagraphEndpoint = "paragraph" :> Summary "Get Paragraph" :> Get '[JSON] Paragraph

type SurbgirqRestAPI = "api" :> (
            GetApiInfoEndpoint
       :<|> GetBooksListEndpoint
       :<|> GetChapterEndpoint
       :<|> GetChapterSectionsEndpoint
       :<|> GetVerseEndpoint
       :<|> GetVerseIntervalEndpoint
      )
