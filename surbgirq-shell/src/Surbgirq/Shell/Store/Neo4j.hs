{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Store.Neo4j where

import Data.IORef
import System.Directory
import System.FilePath
import System.IO

import Control.Exception             (bracket)
import Control.Monad                 (forM_)
import Data.List                     (sortBy)
import Data.Ord                      (comparing)
import Data.Text                     (Text)
import System.FilePath               (FilePath)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.HashMap.Strict as HMap
import qualified Data.Text           as T
import qualified Data.Text.IO        as TIO

import Surbgirq.Shell.Store.ParseFile
import Surbgirq.Shell.Types


wordFormsCypher :: FilePath -> FilePath -> IO ()
wordFormsCypher wordFormFile outPath = do
  wordForms <- parseWordFormFile wordFormFile
  let outFile = outPath </> "wordForms.cypher"
  ref <- newIORef (0 :: Int)
  subRef <- newIORef (0 :: Int)

  hashMapRef <- newIORef (HMap.empty :: HMap.HashMap Text Text)


  bracket (openFile outFile WriteMode) hClose $ \outh -> do

    TIO.hPutStrLn outh "CREATE"

    forM_ (sortBy (comparing armat) wordForms) $ \WordForm{..} -> do
      hashMap <- readIORef hashMapRef

      armatName <- case HMap.lookup armat hashMap  of
        Just name -> return name
        Nothing -> do
          modifyIORef ref (+1)
          writeIORef subRef 0

          suf <- readIORef ref
          let v = [qc|hw_{suf}|]
              m = HMap.insert armat v hashMap
          writeIORef hashMapRef m

          -- add headWord only for fiurst accurance
          let headWordNode = [qc| ({v}:HeadWord \{word: '{armat}' }), |]
          TIO.hPutStrLn outh headWordNode

          return v


      suffix <- readIORef ref
      subSuffix <- readIORef subRef

      -- if prop. then add label NAME or
      let formWordName = T.pack $ concat ["wf_", show suffix, "_",  show subSuffix ]
          formWordNode = [qc| ({formWordName}:WordForm \{word: '{form}' }), |]

          formWordRel  = [qc| ({armatName})-[:HAS_WORDFORM \{form: '{tags}' }]->({formWordName}),|]

      modifyIORef subRef (+1)

      TIO.hPutStrLn outh formWordNode
      TIO.hPutStrLn outh formWordRel




