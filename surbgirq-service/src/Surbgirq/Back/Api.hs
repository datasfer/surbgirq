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
module Surbgirq.Back.Api where


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

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
#define SUMMARY(d) Summary d :>


type BexAPI = BexRestAPI :<|> BexWebSocketAPI

type SwaggerApi = SwaggerSchemaUI "docs" "swagger.json"

type BexSwaggerAPI = SwaggerApi :<|> BexAPI


api :: Proxy  BexAPI
api = Proxy


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
