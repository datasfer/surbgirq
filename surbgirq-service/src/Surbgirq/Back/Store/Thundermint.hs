{-# LANGUAGE DataKinds #-}

module Bex.Back.Store.Thundermint where

import Control.Monad.Reader

import Bex.Back.App.Env
import Thundermint.Store

import Thundermint.Store.Internal.Query        (runQueryRO)
import Web.Xeno.Plugins.Blockchain.Main.Bchain (Bchain(..))
import XChain.Types                            (SignedTx(..))



query :: Query 'RO Alg [SignedTx] a -> AppM m a
query q = do
  conn <- asks (bchain'store . env'bchain)
  runQueryRO conn q
