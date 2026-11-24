{-# LANGUAGE CPP                        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE KindSignatures             #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TypeApplications           #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE UndecidableInstances       #-}
module VerseExplorer.App where

import Control.Monad.Logger
import Control.Monad.Reader
import Data.Proxy
import Network.Wai.Middleware.Cors
import Servant

import Data.Text                            (Text)
import Network.Wai                          (Application)
import Network.Wai.Middleware.RequestLogger (logStdoutDev)

import Lucid.Instances ()
import Servant.Client     (ClientEnv)
import Servant.HTML.Lucid

import qualified Data.Text as T

import Surbgirq.API.GraphDBClient
import Surbgirq.Bot.ClientRequests
import Surbgirq.Types
import VerseExplorer.Types

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

data ServerEnv = ServerEnv

-- | Servant application
newtype AppM a = AppM { unAppM :: ReaderT ServerEnv  (LoggingT Handler) a
  } deriving (Functor, Applicative, Monad, MonadReader ServerEnv, MonadIO)


-- | Execution of 'AppM'
runAppM :: ServerEnv -> AppM a -> Handler a
runAppM e = runStdoutLoggingT . flip runReaderT e . unAppM

api :: Proxy ExplorerAPI
api = Proxy

-- | Make WAI application of a verse explorer API server; it calls surbgirq-graph-api through the given
-- client (GRAPH_API_URL), and its front page lists the books of the given Bible (EXPLORER_DEFAULT_BIBLE)
app :: ClientEnv -> TranslationID -> Application
app graphApi defaultBible = simpleCors $ logStdoutDev $
        serve api $ (hoistServer api liftIO (server graphApi defaultBible))


testBooks :: TranslationID -> IO [Book]
testBooks _ = do
  putStrLn "enter testBooks"
  return [b1]
b1 = Book 1 "bookId" [] Matthew "title" 0 0 New "e1994"


type GetApiInfoEndpoint = "books" :> Summary "Get books" :> Get '[JSON, HTML] [Book]
type SearchByWordEndpoint = "search" :> Summary "Search by word"
    :> ReqBody '[FormUrlEncoded] SearchRequest
    :> Post '[JSON, HTML] SearchFound

type ExplorerAPI = Summary "books list" :> Get '[JSON, HTML] [Book]
    :<|> "about" :> Summary "About" :> Get '[JSON, HTML] About
    :<|> SearchByWordEndpoint -- :> Summary "Search by word"
    :<|> GraphDBLocalAPI

 --    Summary "status" :> Get '[JSON, HTML] [Book]
 -- --   :<|> "books" :> Get '[JSON, HTML] [Book]
 --      :<|> "text" :> Summary "Get books by translation ID"
 --                 :> Capture ":translation" Text -- TranslationID
 --                 :> "books" :> Get '[JSON, HTML] [Book]
 --      :<|> "translation" :> Summary "Get books by translation ID"
 --                 :> Capture ":translation" TranslationID
 --                 :> "books" :> Get '[JSON, HTML] [Book]

bookList :: IO [Book]
bookList  = do
  putStrLn "enter bookList"
  return [b1]

bookListByText :: Text ->  IO [Book]
bookListByText txt  = do
  putStrLn "enter bookList"
  putStrLn $ T.unpack txt
  return [b1]

about :: IO About
about = return $ About "About page"

searchByWordEndpoint :: SearchRequest -> IO SearchFound
searchByWordEndpoint (SearchRequest word) = return FoundNothing

-- server :: ServerT ExplorerAPI IO
-- server = bookList :<|> bookListByText -- getBooksHandler -- E1994T) -- bookList
--          :<|> getBooksHandler
-- --         :<|> testBooks
server :: ClientEnv -> TranslationID -> ServerT ExplorerAPI IO
server graphApi defaultBible =
         ( (getBooksHandler graphApi defaultBible)
         :<|> about
         :<|> searchByWordEndpoint
         :<|> getBooksHandler graphApi
         :<|> getVerseRangeHandler graphApi
         :<|> getOneVerseHandler graphApi
         :<|> getChapterSectionsHandler graphApi
         :<|> getChapterOneSectionHandler graphApi
         :<|> getBookSectionsHandler graphApi
         :<|> getChapterVerseNumberHandler graphApi
         )


-- getBooksHandler1 = liftIO . getBooksHandler
-- getVerseRangeHandler1 = liftIO . getVerseRangeHandler
-- getOneVerseHandler1 = liftIO . getOneVerseHandler
-- getChapterSectionsHandler1 = liftIO . getChapterSectionsHandler
-- getChapterOneSectionHandler1 = liftIO .  getChapterOneSectionHandler
-- getBookSectionsHandler1 = liftIO . getBookSectionsHandler
-- getChapterVerseNumberHandler1 = liftIO . getChapterVerseNumberHandler
