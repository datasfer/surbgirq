{-# LANGUAGE TypeOperators #-}

{-|
Module      : Surbgirq.Back.Server
Description : Endpoints handlers

Construct endpoints handlers as  ADT
-}

module Surbgirq.Back.Server where

import Servant.API
import Servant.API.Generic
import Servant.Server
import Servant.Server.Generic

import Surbgirq.API
import Surbgirq.Back.Api
import Surbgirq.Back.App.Env
import Surbgirq.Back.Server.Rest
import Surbgirq.Back.Server.WebSocket

------------------------------------------------------------
--
------------------------------------------------------------

surbgirqServer :: ServerT SurbgirqAPI AppM
surbgirqServer = toServant bookServer :<|> toServant scriptureServer
-- surbgirqServer = SurbgirqAPI
--                  { bookApi  =  toServant bookServer
--                  , scriptureAPI = toServant scriptureServer
--                 } 




bookServer :: BookAPI (AsServerT AppM)
bookServer =  BookAPI
              { booksListEndpoint = getBooksHandler
              , bookChapterNumsEndpoint = bookChapterNums
              , bookChapterSectionNumsEndpoint = bookChapterSectionNums
              , bookChapterVerseNumsEndpoint = bookChapterVerseNums
              }


scriptureServer :: ScriptureAPI (AsServerT AppM)
scriptureServer =  ScriptureAPI
              { scriptureChapterEndpoint = scriptureChapter
              , scriptureChapterAllSectionsEndpoint = scriptureChapterAllSections
              , scriptureChapterSectionEndpoint = scriptureChapterSection
              -- Verses
              , scriptureChapterAllVersesEndpoint = scriptureChapterAllVerses
              , scriptureVerseEndpoint = scriptureVerse
              , scriptureVerseFromToEndpoint = scriptureVerseFromTo
              , scriptureVerseByRefTextEndpoint = scriptureVerseByRefText
              }


