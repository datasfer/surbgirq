{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Store.Neo4j where

import Data.IORef
import Database.Selda
import System.Directory
import System.FilePath
import System.IO
import Text.Printf

import Control.Exception             (bracket)
import Control.Monad                 (forM_, when)
import Data.List                     (sortBy, splitAt)
import Data.Maybe                    (isNothing)
import Data.Ord                      (comparing)
import Data.Text                     (Text)
import System.FilePath               (FilePath)
import Text.InterpolatedString.Perl6 (qc)

import qualified Data.HashMap.Strict as HMap
import qualified Data.Text           as T
import qualified Data.Text.IO        as TIO

import Surbgirq.Shell.Store.ParseFile
import Surbgirq.Shell.Types

chunk :: Int -> [a] -> [[a]]
chunk n xs = case splitAt n xs of
  (c,[]) -> [c]
  (c,cs) -> c : chunk n cs

wordFormsCypher :: FilePath -> FilePath -> IO ()
wordFormsCypher wordFormFile outPath = do
  wordForms <- parseWordFormFile wordFormFile

  hashMapRef <- newIORef (HMap.empty :: HMap.HashMap Text Text)
  ref <- newIORef (0 :: Int)

  let sortedWs = sortBy (comparing armat) wordForms

  forM_ (zip ([1..] :: [Int]) (chunk 500 sortedWs)) $ \(index, ws) -> do

    let outFile = outPath </> (concat ["wordForms_", printf "%03d" index, ".cypher"])
    subRef <- newIORef (0 :: Int)

    bracket (openFile outFile WriteMode) hClose $ \outh -> do

      forM_ (sortBy (comparing armat) ws) $ \WordForm{..} -> do
          hashMap <- readIORef hashMapRef

          armatName <- case HMap.lookup armat hashMap  of
            Just name -> do
                -- this need to get the var for cypher file, this is in case if we seperated cypher files
                mode <- readIORef subRef
                when (mode == 0) $  do
                           let hw = [qc|MERGE ({name}:HeadWord \{word: '{armat}' }) |]
                           TIO.hPutStrLn outh hw

                return name
            Nothing -> do
              modifyIORef ref (+1)
              writeIORef subRef 0

              suf <- readIORef ref
              let v = [qc|hw_{suf}|]
                  m = HMap.insert armat v hashMap
              writeIORef hashMapRef m

              -- add headWord only for fiurst accurance
              let headWordNode = [qc|CREATE ({v}:HeadWord \{word: '{armat}' }) |]
              TIO.hPutStrLn outh headWordNode

              return v


          suffix <- readIORef ref
          subSuffix <- readIORef subRef

          -- if prop. then add label NAME or
          let formWordName = T.pack $ concat ["wf_", show suffix, "_",  show subSuffix ]
              formWordNode = [qc|CREATE ({formWordName}:WordForm \{word: '{form}' })|]

              formWordRel  = [qc|CREATE ({armatName})-[:HAS_WORDFORM \{form: '{tags}' }]->({formWordName})|]

          modifyIORef subRef (+1)

          TIO.hPutStrLn outh formWordNode
          TIO.hPutStrLn outh formWordRel

      TIO.hPutStrLn outh ";"





-- |
-- generate csv file to
wordFormsCSV :: FilePath -> FilePath -> IO ()
wordFormsCSV wordFormFile outPath = do

  TIO.putStrLn "Words processing..."

  createDirectoryIfMissing True outPath

  wordForms <- parseWordFormFile wordFormFile

  hashMapRef <- newIORef (HMap.empty :: HMap.HashMap Text Int)
  armatRef <- newIORef (0 :: Int)
  formRef <- newIORef (0 :: Int)

  let outFileArmat = outPath </> "armats.csv"
      outFileForms = outPath </> "wordForms.csv"
      outFileRel   = outPath </> "WordArmatRel.csv"
      del = ';'

  bracket (do
            h1 <- openFile outFileArmat WriteMode
            h2 <- openFile outFileForms WriteMode
            h3 <- openFile outFileRel WriteMode
            return (h1, h2, h3))
           (\(h1, h2, h3) -> do
              hClose h1
              hClose h2
              hClose h3) $ \(outArmath, outFormh, outRelh) -> do

      TIO.hPutStrLn outFormh  [qc|armatID:ID(ARMAT-ID){del}token{del}armat{del}tags|]
      TIO.hPutStrLn outArmath [qc|formID:ID(WORDFORM-ID){del}armat|]
      TIO.hPutStrLn outRelh   [qc|:START_ID(WORDFORM-ID){del}:END_ID(ARMAT-ID)|]

      forM_ (sortBy (comparing armat) wordForms) $ \WordForm{..} -> do
          hashMap <- readIORef hashMapRef
          modifyIORef formRef (+1)
          form_ID <- readIORef formRef


          let formLine = [qc|{form_ID}{del}{form}{del}{armat}{del}{tags}|]
          TIO.hPutStrLn outFormh formLine

          let armatExists = HMap.lookup armat hashMap
          when (isNothing armatExists) $ do
              modifyIORef armatRef (+1)
              headID <- readIORef armatRef

              let m = HMap.insert armat headID hashMap
              writeIORef hashMapRef m

              -- add headWord only for fiurst accurance
              let headWordLine = [qc|{headID}{del}{armat}|]
              TIO.hPutStrLn outArmath headWordLine


          -- add relationship
          aID <- readIORef armatRef
          let armatRel = [qc|{aID}{del}{form_ID}|]
          TIO.hPutStrLn outRelh armatRel




