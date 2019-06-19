{-# LANGUAGE TypeOperators #-}

module Surbgirq.Back.Server where


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

{-
server :: ServerT BexAPI AppM
server =  ( getApiInfoHandler
          :<|> getBooksHandler
          :<|> getChapterHandler
          :<|> getChapterSectionsHandler
          :<|> getVerseHandler
          :<|> getVerseFromToHandler
          :<|> getVerseIntervalHandler
          )
          :<|> notifyNewBlock

-}




surbgirqServer :: ServerT SurbgirqAPI AppM
surbgirqServer = toServant bookServer




bookServer :: BookAPI (AsServerT AppM)
bookServer =  BookAPI
              { booksListEndpoint = getBooksHandler
              }

