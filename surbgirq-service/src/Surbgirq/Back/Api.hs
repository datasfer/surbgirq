{-# LANGUAGE CPP                   #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE UndecidableInstances  #-}


{-|
Module      : Surbgirq.Back.Api
Description : Servant API type definitions

Convert REST API adt to servant api type
-}

module Surbgirq.Back.Api (
   SwaggerAPI
 , SurbgirqAPI
 , SurbgirqAPISwagger
 ) where


import Data.Proxy
import Servant
import Servant.API
import Servant.API.Generic
import Servant.Server
import Servant.Swagger.UI

import Data.Text    (Text)
import GHC.Generics (D1, Meta(..), Rep)
import GHC.TypeLits (AppendSymbol, Symbol)

import Surbgirq.API
import Surbgirq.Back.App.Env

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

#define SUMMARY(d) Summary d :>


type SwaggerAPI = SwaggerSchemaUI "docs" "swagger.json"


type SurbgirqAPISwagger = SwaggerAPI :<|> SurbgirqAPI




type family TypeName (x :: *) :: Symbol where
    TypeName Int  = "Int"
    TypeName Text = "Text"
    TypeName x    = GenericTypeName x (Rep x ())

type family GenericTypeName t (r :: *) :: Symbol where
    GenericTypeName t (D1 ('MetaData name mod pkg nt) f x) = name

type Desc t n = Description (AppendSymbol (TypeName t) (AppendSymbol " | " n))

{-
type GirqAPI = ToServantApi GirqRestAPI :<|> ToServantApi GirqWebSocketAPI


-- | Servant API implementation for VPN master
 girqRestServer :: GirqRestAPI AsServerM
 girqRestServer = GirqRestAPI {
               transationsAPI  = toServant transactionsServer
             , blocksAPI       = toServant blocksServer
             }

girqServer :: ServerT GirqAPI ServerM
girqServer = toServant girqRestServer :<|> toServant girqWebSocketServer

-}
