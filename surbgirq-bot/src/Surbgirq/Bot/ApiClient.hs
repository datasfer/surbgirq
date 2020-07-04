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

import Network.HTTP.Client (newManager, defaultManagerSettings)
-- import Network.HTTP.Client.TLS (tlsManagerSettings)


import Surbgirq.API.Client
import Surbgirq.Types

-------------------------------------------------------------------------------
--  
-------------------------------------------------------------------------------


getBooksHandler :: IO [Book]
getBooksHandler = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33001"
--  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getAllBooks' -- mgr
  case mres of
    Left e -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a
