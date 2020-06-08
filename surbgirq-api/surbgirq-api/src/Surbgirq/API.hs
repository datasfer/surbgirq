{-|
Module      : Surbgirq.API
Description : REST API Endpoints types and definition

REST API Endpoints generic definition as ADT.

The types to wrap request and response of web api.
-}

module Surbgirq.API(
  module X
) where

import Surbgirq.API.Instances as X
import Surbgirq.API.Rest      as X
import Surbgirq.API.Types     as X
import Surbgirq.API.WebSocket as X
