{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}

-- | Client for the Surbgirq web API
module Surbgirq.API.Client where

import Data.Proxy
import Data.Text
import Network.HTTP.Client     (defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant.API
import Servant.Client


import Control.Exception
import Control.Monad.Catch
import Control.Monad.Except
import Control.Monad.Reader
import Data.Bifunctor
import Data.ByteString               (ByteString)
import Data.Proxy
import Data.Text                     (Text)
import GHC.Generics
import Servant.API
import Text.InterpolatedString.Perl6 (qc)

import Network.HTTP.Client hiding (Proxy)

import qualified Data.Text      as T
import qualified Servant.Client as C

import Surbgirq.API
import Surbgirq.Types

-- | Errors in 'ClientM' monad
data ClientError = InvalidBaseUrl !Text | ClientError !C.ClientError
  deriving (Eq, Show, Generic)

-- instance Exception C.ClientError


myApi :: Proxy SurbgirqAPI
myApi = Proxy

-- 'client' allows you to produce operations to query an API from a client.
postNewBook :: Book -> ClientM Book
getAllBooks :: ClientM [Book]
(getAllBooks :<|> postNewBook) = client SurbgirqAPI

{--

-- | Tighten an error info into servant client common client error type
fromClientError :: ClientError -> C.ServantError
fromClientError e@(InvalidBaseUrl{}) = C.ConnectionError (T.pack . show $ e)
fromClientError (ClientError e) = e

-- | Initial environment that is needed to execute 'ClientM' action
data ClientConfig = ClientConfig {
    clientUrl      :: !Text -- ^ Base url for API server
  , clientManager  :: !Manager -- ^ Connection manager
  } deriving (Generic)

-- | Monad that is used to perform calls to Surbigrq API.
newtype ClientM a = ClientM { unClientM :: ReaderT ClientConfig (ExceptT ClientError C.ClientM) a }
  deriving ( Functor, Applicative, Monad, MonadIO, MonadThrow, MonadCatch, Generic
           , MonadError ClientError, MonadReader ClientConfig )

-- | Execute API actions
runClientM :: MonadIO m
  => ClientM a -- ^ Action
  -> ClientConfig -- ^ Required info to execute action
  -> m (Either ClientError a)
runClientM ma cfg@ClientConfig{..} = case C.parseBaseUrl . T.unpack $ clientUrl of
  Left e -> return $ Left . InvalidBaseUrl . T.pack . show $ e
  Right burl -> do
    res <- liftIO $ C.runClientM (runExceptT $ runReaderT (unClientM ma) cfg) $ C.ClientEnv clientManager burl Nothing
    return $ join . first ClientError $ res

-- | Helper to embed 'ClientM' action into more specific monad
liftClientM :: C.ClientM a -> ClientM a
liftClientM = ClientM . lift . lift

getUserExists :: UserId -> ClientM Bool
getUserExists uid = liftClientM (getUserExists' uid)

getInviteMode :: ClientM Bool
getInviteMode = liftClientM getInviteMode'

getBalance :: WalletBack -> ClientM GetBalanceResponse
getBalance req = liftClientM (getBalance' req)

getDepositAddress :: WalletBack -> ClientM DepositAddressResponse
getDepositAddress req = liftClientM (getDepositAddress' req)

getTickerStat :: ClientM TickerStat
getTickerStat = liftClientM getTickerStat'

postTx :: SignedTx -> ClientM PostTxResponse
postTx tx = liftClientM (postTx' tx)

encodeTx :: Tx -> ClientM ByteString
encodeTx tx = unEncodeTxResponse <$> liftClientM (encodeTx' tx)

getApiInfo :: ClientM FrontVersion
getApiInfo = liftClientM getApiInfo'

queryState :: ClientM XenoState
queryState = liftClientM queryState'

getChartHistory :: Maybe CurrencyPair -> Maybe IntTime -> Maybe IntTime -> Maybe Int -> ClientM ChartResponse
getChartHistory mCur mFrom mTo mSize = liftClientM (getChartHistory' mCur mFrom mTo mSize)

getChartCurrent :: Maybe CurrencyPair -> Maybe IntTime -> Maybe IntTime -> Maybe Int -> ClientM ChartResponse
getChartCurrent mCur mFrom mTo mSize = liftClientM (getChartCurrent' mCur mFrom mTo mSize)

getFrontVersion :: ClientM FrontVersion
getFrontVersion = liftClientM getFrontVersion'

getUserAccountPay :: PublicKey -> ClientM AccountPayInfo
getUserAccountPay = liftClientM . getUserAccountPay'

-- Client auto implementation
--
getUserExists' :: UserId -> C.ClientM Bool
getInviteMode' :: C.ClientM Bool
getBalance' :: WalletBack -> C.ClientM GetBalanceResponse
getDepositAddress' :: WalletBack -> C.ClientM DepositAddressResponse
getTickerStat' :: C.ClientM TickerStat
postTx' :: SignedTx -> C.ClientM PostTxResponse
encodeTx' :: Tx -> C.ClientM EncodeTxResponse
getApiInfo' :: C.ClientM FrontVersion
getChartHistory' :: Maybe CurrencyPair -> Maybe IntTime -> Maybe IntTime -> Maybe Int -> C.ClientM ChartResponse
getChartCurrent' :: Maybe CurrencyPair -> Maybe IntTime -> Maybe IntTime -> Maybe Int -> C.ClientM ChartResponse
getFrontVersion' :: C.ClientM FrontVersion
getUserAccountPay' :: PublicKey -> C.ClientM AccountPayInfo
(      getUserExists'
  :<|> getInviteMode'
  :<|> getBalance'
  :<|> getDepositAddress'
  :<|> getTickerStat'
  :<|> postTx'
  :<|> encodeTx'
  :<|> getApiInfo'
  :<|> getChartHistory'
  :<|> getChartCurrent'
  :<|> getFrontVersion'
  :<|> getUserAccountPay'
  ) = C.client (Proxy :: Proxy XenochainRest)

queryState' :: C.ClientM XenoState
queryState' = C.client (Proxy :: Proxy XenochainDebugAPI)

data HttpQueryOps =
  HttpQueryOps {
    httpHost :: Text
  , httpPort :: Int
  }
  | HttpQueryOpsUrl {
    httpUrl :: Text
  }
  deriving (Show, Eq)

makeClientManager' :: (MonadIO m) => m Manager
makeClientManager' = liftIO $ newManager tlsManagerSettings

makeClientConfig :: (MonadIO m) => HttpQueryOps -> m ClientConfig
makeClientConfig ops = do
  mng <- makeClientManager'
  pure $ ClientConfig
      { clientUrl = url
      , clientManager  = mng
      }
  where
    url = case ops of
            HttpQueryOps    {..} -> [qc|http://{httpHost}:{T.pack . show $ httpPort}|]
            HttpQueryOpsUrl {..} -> httpUrl

query :: ClientConfig -> ClientM a -> IO (Either ClientError a)
query = flip runClientM

--}
