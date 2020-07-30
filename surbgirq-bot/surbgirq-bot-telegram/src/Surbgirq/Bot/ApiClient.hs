{-# LANGUAGE DataKinds #-}

{-|
Module      : Surbgirq.Back.Server.Rest.Book
Description : Provide high level information of the Book

Implement Book meta info related endpoints handlers
-}

module Surbgirq.Bot.ApiClient (
   getBooksHandler
 -- , bookChapterNums
 -- , bookChapterSectionNums
 -- , bookChapterVerseNums
 ) where

import Servant.Client

import Network.HTTP.Client (defaultManagerSettings, newManager)
-- import Network.HTTP.Client.TLS (tlsManagerSettings)


import Surbgirq.API.Client
import Surbgirq.Types

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------


