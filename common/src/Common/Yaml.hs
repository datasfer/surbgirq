module Common.Yaml(
   readYaml
) where

import Data.Aeson
import Data.Yaml.Config (loadYamlSettings, useEnv)


------------------------------------------------------------
--
------------------------------------------------------------

readYaml :: FromJSON settings => FilePath -> IO settings
readYaml file = loadYamlSettings [file] [] useEnv
