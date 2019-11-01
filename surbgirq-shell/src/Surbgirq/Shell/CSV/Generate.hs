{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.CSV.Generate where




import Control.Exception    (bracket)
import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)

import Data.Aeson
import Data.Char
import Data.Maybe (fromMaybe)
import Data.Text  (Text, pack)

import qualified Data.Text               as T
import qualified Data.Text.Encoding      as TE
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import qualified Data.Text.Lazy.Builder  as TB
import           Data.Text.Lazy.Encoding as TLE

import Options.Applicative
import System.Directory
import System.FilePath.Posix         (takeBaseName, takeDirectory)
import System.IO
import Text.InterpolatedString.Perl6 (qc)

import Control.Monad
import Data.List
import System.FilePath

import Common.Yaml
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq





generateVerseCsv :: FilePath -> FilePath -> FilePath -> IO ()
generateVerseCsv bookFile path outPath = do
   let del = ';';

   books :: [Book] <- readYaml bookFile -- path </> "books.yaml"

   -- Booksx
   forM_ books $ \Book{..} -> do

     let inPath = fromMaybe (T.toLower . T.pack $ show book'book ) book'input
         bookDir = path </> (T.unpack inPath)

         -- cypher out file
         outCypherFileRoot = outPath </> (takeDirectory $ T.unpack inPath)
         outFile = outCypherFileRoot </> [qc|{T.toLower . T.pack $ show book'book}.csv|]

         -- ref file
         outRefFileRoot = outCypherFileRoot </> "refs"
         outRefFile = outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}.ref|]

         bookLabel = maybe (show book'book) ((show book'book) ++)  (T.unpack <$> book'labels)
         bookTestament = show book'testament
         bookName = T.toLower . T.pack  $ show book'book
         lang = show book'language
         dialect = show book'dialect



     exists <- doesDirectoryExist bookDir
     -- check if books input directory exists
     when exists $ do
       -- here no need to error check
       createDirectoryIfMissing True outCypherFileRoot
       createDirectoryIfMissing True outRefFileRoot
       txtFiles <- listDirectory bookDir `catchError` \_ -> do
                                      liftIO $ putStrLn (concat [bookDir, " does not exist."])
                                      return []

       bracket (do
                  h1 <- openFile outFile WriteMode
                  h2 <- openFile outRefFile WriteMode
                  return (h1, h2))
                (\(h1, h2) -> do
                   hClose h1
                   hClose h2) $ \(outh, outRefh) -> do

         -- a file == a chapter
         forM_ (sort txtFiles) $ \file -> when (doesFilenameMatch file) $ do
           ch@Chapeter{..} <- readChapter (bookDir </> file)
           -- Sections
           forM_ chapter'sections $ \Section{..} -> do
              -- Paragraphs
             forM_ section'paragraphs $ \Paragraph{..} -> do
               -- Verses
               forM_ paragraph'verses $ \v@Verse{..} -> do
                 let verseLine = [qc|{bookLabel}{del} {chapter'number}{del} {section'number}{del} {paragraph'number}{del} {verse'verse}{del} {verse'content} |]
                 TIO.hPutStrLn outh verseLine



                 -- -- verse ref processing
                 -- case verse'ref of
                 --   Nothing -> return ()
                 --   Just VerseRef{..} -> do
                 --     case verseRef'type of
                 --       RefText txt -> do
                 --         let wordN = concat [verseName, del, "word", show verseRef'index]
                 --             footnoteName = concat [wordN, del, "footnote", show verseRef'index]
                 --             footnoteNode = [qc| ({footnoteName}:Footnote \{text: '{txt}', index: {verseRef'index}}),|]
                 --             footnoteRel  = [qc| ({wordN})-[:REF_FOOTNOTE]->({footnoteName}),|]
                 --         TIO.hPutStrLn outh footnoteNode
                 --         TIO.hPutStrLn outh footnoteRel
                 --       _ -> return ()


  where
    tail' :: [a] -> [a]
    tail' []     = []
    tail' (x:xs) = xs
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".yaml", ".yml"]
    isDir :: FilePath -> Bool
    isDir path = takeExtension path == ""
    readChapter :: FilePath -> IO Chapter
    readChapter file = do
      book <- readYaml file
      return book



