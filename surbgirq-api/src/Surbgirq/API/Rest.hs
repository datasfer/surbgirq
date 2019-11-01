{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}

{-|
Module      : Surbgirq.API.Rest
Description : REST API endpoints

Web API Endpoints generic definition as ADT
-}

module Surbgirq.API.Rest (
   MetaAPI(..)
 , BookAPI(..)
 , ScriptureAPI(..)
  ) where

import Data.Int     (Int64)
import Data.Text    (Text)
import GHC.Generics (Generic)

import Servant.API
import Servant.API.Generic

import Surbgirq.API.Types
import Surbgirq.Types

------------------------------------------------------------
-- Surbgirq API endpoints
------------------------------------------------------------

-- |
-- info related to api
data MetaAPI route = MetaAPI {
      apiInfoEndpoint :: route :- "info" :> Summary "Get Api Information"
                         :> Get '[JSON] GetApiInfoResponse
}

-- |
-- Book descriptive and quantitive info
data BookAPI route = BookAPI {
      booksListEndpoint :: route :- "list" :> Summary "Get Available Books"
                           :> Get '[JSON] [Book]

    , bookChapterNumsEndpoint :: route :- "chapters" :> Summary "Get chapter nums"
                                 :> Capture "girq" Girq
                                 :> Get '[JSON] [(Int, Text)]

    , bookChapterSectionNumsEndpoint :: route :- "sections" :> Summary "Get chapter section nums"
                                 :> Capture "girq" Girq
                                 :> Capture "chapter" ChapterNum
                                 :> Get '[JSON] [(Int, Text)]

    , bookChapterVerseNumsEndpoint :: route :- "verses" :> Summary "Get chapter verse nums"
                                 :> Capture "girq" Girq
                                 :> Capture "chapter" ChapterNum
                                 :> Get '[JSON] [Int]

} deriving (Generic)



-- |
-- Scriptures info
data ScriptureAPI route = ScriptureAPI {

      scriptureChapterEndpoint :: route :- "chapter" :> Summary "Get Chapter"
                                  :> Capture "girq" Girq
                                  :> Capture "ch" ChapterNum
                                  :> Get '[JSON] [Chapter]

    , scriptureChapterAllSectionsEndpoint :: route :- "chapter" :> "sections"   :> Summary "Get Sections of Chapter"
                                       :> Capture "girq" Girq
                                       :> Capture "ch" ChapterNum
                                       :> Get '[JSON] [Section]

    , scriptureChapterSectionEndpoint :: route :- "section"   :> Summary "Get the Section"
                                  :> Capture "girq" Girq
                                  :> Capture "ch"   ChapterNum
                                  :> Capture "sec"  SectionNum
                                  :> Get '[JSON] [Section]


    -- | Verses endpoints
    , scriptureChapterAllVersesEndpoint :: route :- "chapter" :> "verses" :> Summary "Get all Verses of Chapter"
                                        :> Capture "girq" Girq
                                        :> Capture "ch" ChapterNum
                                        :> Get '[JSON] [Verse]

    , scriptureVerseEndpoint :: route :- "chapter" :> "verse"   :> Summary "Get Verse by chapter and verse number"
                                :> Capture "girq" Girq
                                :> Capture "ch" ChapterNum
                                :> Capture "verse" VerseNum
                                :> Get '[JSON] [Verse]

    , scriptureVerseFromToEndpoint :: route :- "chapter" :> "verse" :> Summary "Get Verse by verse numver [From, Tp]"
                                      :> Capture "girq" Girq
                                      :> Capture "ch" ChapterNum
                                      :> Capture "verseFrom" VerseNum
                                      :> Capture "verseTo" VerseNum
                                      :> Get '[JSON] [Verse]

    , scriptureVerseByRefTextEndpoint :: route :- "verse" :> Summary "Get Verse by ref text 'Book chnum.v1-v2' "
                                         :> Capture "verseRef" Text
                                         :> Get '[JSON] [Verse]

} deriving (Generic)




type GetChapterVersesEndpoint = "verse"   :> Summary "Get all Verses of Chapter"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Get '[JSON] [Verse]



type GetVerseIntervalEndpoint = "verses" :> Summary "Get Verse interval"
    :> Capture "girq" Girq
    :> Capture "ch" ChapterNum
    :> Capture "verse" Text
    :> Get '[JSON] [Verse]

type GetSectionEndpoint = "section"   :> Summary "Get Section"
    :> Capture "girq" Girq
    :> Capture "ch"   ChapterNum
    :> Capture "sec"  SectionNum
    :> Get '[JSON] Section

type GetParagraphEndpoint = "paragraph" :> Summary "Get Paragraph" :> Get '[JSON] Paragraph

{-
type SurbgirqRestAPI = "api" :> (
            GetApiInfoEndpoint
       :<|> GetBooksListEndpoint
       :<|> GetChapterEndpoint
       :<|> GetChapterSectionsEndpoint
       :<|> GetVerseEndpoint
       :<|> GetVerseFromToEndpoint
       :<|> GetVerseIntervalEndpoint
      )
-}
