{-# LANGUAGE DataKinds #-}

{-|
Module      : Surbgirq.Back.Server.Rest.Book
Description : Provide high level information of the Book

Implement Book meta info related endpoints handlers
-}

module Surbgirq.Back.Server.Rest.Book (
   getBooksHandler
 , bookChapterNums
 , bookChapterSectionNums
 , bookChapterVerseNums
 ) where

import Control.Monad.Reader
import Data.Time.Clock.POSIX

-- import Control.Monad.Trans.Reader (ask)
import Control.Monad.Trans     (lift, liftIO)
import Data.Maybe              (fromMaybe)
import Data.Pool               (withResource)
import Data.String             (IsString(..))
import Data.Text               (Text, pack, unpack)
import GHC.Int                 (Int64)
import Network.HTTP.Client     (Manager, defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Text.Read               (readMaybe)

import Servant.Client
import Text.InterpolatedString.Perl6 (qc)

import Database.Bolt hiding (pack)

import qualified Data.ByteString.Char8  as BC8
import qualified Data.Text              as T
import qualified Database.SQLite.Simple as SQL

import Surbgirq.API
import Surbgirq.Back.App.Env
import Surbgirq.Neo4j
import Surbgirq.Types

import Surbgirq.API.GraphDBClient


------------------------------------------------------------
--
------------------------------------------------------------

-- | execute a neo4j query
-- get the neo4j pool resource from env and run neo4j query
runQ :: BoltActionT IO a -> AppM a
runQ act = do env <- ask
              liftIO $ withResource (env'pool env) (`run` act)

-- | get all books from neo4j db
getBooksHandler :: AppM [Book]
getBooksHandler = do
  env <- liftIO $ mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <- liftIO $ newManager tlsManagerSettings
--  mres <- liftIO $ flip runClientM env $ getAllBooks'
  let mres = Right [] :: Either String [Book] --  <- liftIO $ getAllBooks  mgr
  case mres of
    Left e  -> error $  e -- throwIO $ ClientError e
    Right a -> pure a
-- runQ queryBooks

-- +sendBooks :: ChatId -> Bot ()
-- +sendBooks chatId = do
-- +    BotConfig{..} <- ask
-- +    books <- liftIO getBooksHandler
-- +    let requests = map (\s -> sendMessageRequest chatId (T.pack s)) ["map", "show", " books"]
-- +    return ()
-- +  where
-- +    markupBooks []     = ""
-- +    markupBooks (b:bs) = ""


-- runGraphDBClient :: MonadIO m => ClientM a -> AppM a
-- runGraphDBClient m = do
--   env <- ask
--   mres <- runClientM m ccfg
--   case mres of
--     Left e -> throwIO $ ClientError e
--     Right a -> pure a

-- | return the @girq' chpaters list info
-- return a list of tuples chapter number and chapter title
bookChapterNums :: Girq -> AppM [(Int, Text)]
bookChapterNums girq = runQ $ queryChapterNums girq

-- | return the @girq' @chNum chpater' sections list info
-- return a list of tuples section number and section title
bookChapterSectionNums :: Girq -> ChapterNum -> AppM [(Int, Text)]
bookChapterSectionNums girq chNum = runQ $ querySectionNums girq chNum

-- | return the @girq' @chNum chpater' verses numbers list
bookChapterVerseNums :: Girq -> ChapterNum -> AppM [Int]
bookChapterVerseNums girq chNum = runQ $ queryChapterVerseNums girq chNum

