{-# LANGUAGE OverloadedStrings #-}
module Surbgirq.Back.Swagger.Doc where

import Control.Lens    ((&), (.~), (?~))
import Data.Proxy
import Data.Swagger    (Swagger, description, info, title, version)
import Servant.Swagger (toSwagger)

import Surbgirq.API
import Surbgirq.Back.Api
import Surbgirq.Back.Swagger.Instances ()

swaggerDoc :: Swagger
swaggerDoc = toSwagger (Proxy :: Proxy SurbgirqRestAPI)
    & info.title       .~ "Surbgirq REST API"
    & info.version     .~ "2019.05.20"
    & info.description ?~ "This is an API for surbgirq scriptures."
