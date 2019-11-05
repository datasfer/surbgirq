{-|
Module      : Common.Yaml
Description : Helpers to parse yaml

Helpers to parse yaml text or bytestring to type
-}

module Common.Yaml(
    loadYaml
  , readYaml
  , readYaml'
) where

import Data.Aeson

import Data.ByteString  (ByteString)
import Data.Yaml        (decodeEither')
import Data.Yaml.Config (loadYamlSettings, useEnv)

import Data.ByteString as BS (readFile)

import qualified Control.Exception as Exception

------------------------------------------------------------
--
------------------------------------------------------------

loadYaml  ::  FromJSON settings => ByteString -> IO settings
loadYaml bs = loadYamlSettings [] [value] useEnv
  where
    value = either Exception.throw id $ decodeEither' bs

readYaml' :: FromJSON settings => FilePath -> IO settings
readYaml' file = loadYaml =<< BS.readFile file

readYaml :: FromJSON settings => FilePath -> IO settings
readYaml file = loadYamlSettings [file] [] useEnv
