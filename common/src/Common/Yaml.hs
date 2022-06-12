module Common.Yaml(
   readYaml
) where

import Data.Aeson
import Data.Yaml.Config (loadYamlSettings, useEnv)


------------------------------------------------------------
--
------------------------------------------------------------

readYaml :: FromJSON a => FilePath -> IO a
readYaml file = loadYamlSettings [file] [] useEnv
