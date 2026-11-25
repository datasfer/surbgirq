{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Txt.PlainText where

import Control.Exception             (bracket)
import Control.Monad.Except          (MonadError, MonadIO, catchError, liftIO)
import Data.Maybe                    (fromMaybe)
import Data.Text                     (Text, pack)
import System.FilePath.Posix         (takeBaseName, takeDirectory)
import Text.InterpolatedString.Perl6 (qc)

import Prelude         hiding (catch)
import System.IO.Error hiding (catch)

import qualified Data.Text               as T
import qualified Data.Text.Encoding      as TE
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import qualified Data.Text.Lazy.Builder  as TB
import           Data.Text.Lazy.Encoding as TLE

import Control.Exception
import Data.Aeson
import Data.Char
import Options.Applicative
import System.Directory
import System.IO

import Control.Monad
import Data.List
import System.FilePath

import Common.Yaml
import Surbgirq.Shell.Files (openOutFile)
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq
import Surbgirq.Types.Scripture


encodeChaptersToFile :: FilePath -> Text -> [Chapter] -> IO ()
encodeChaptersToFile file bookTitle chapters = do
  outh <- openOutFile file
  TIO.hPutStrLn outh  [qc|\b {bookTitle}|]
  forM_ chapters $ \ ch@Chapter{..} -> do
      TIO.hPutStrLn outh  [qc|\c {chapter'number}|]
      forM_ chapter'sections $ \Section{..} -> do
        TIO.hPutStrLn outh  [qc|\s {section'number} {section'title}|]
        when (not $ T.null section'ref) $ TIO.hPutStrLn outh  [qc|\r {section'ref}|]
        forM_ section'verses $ \v@Verse{..} -> do
          TIO.hPutStrLn outh  [qc|\v {verse'verse} {verse'content}|]
  hClose outh

