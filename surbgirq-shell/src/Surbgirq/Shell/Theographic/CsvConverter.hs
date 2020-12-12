{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.Theographic.CsvConverter where







-- base
import           Control.Exception (IOException)
import qualified Control.Exception as Exception
import qualified Data.Foldable     as Foldable

import Data.List.Split
-- bytestring
import           Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as ByteString

-- cassava
import           Data.Csv
    ( DefaultOrdered(headerOrder)
    , FromField(parseField)
    , FromNamedRecord(parseNamedRecord)
    , HasHeader(..)
    , Header
    , ToField(toField)
    , ToNamedRecord(toNamedRecord)
    , (.:)
    , (.=)
    )
import qualified Data.Csv as Cassava

-- text
import           Data.Text          (Text)
import qualified Data.Text.Encoding as Text

-- vector
import           Data.Vector (Vector)
import qualified Data.Vector as Vector

----------------------------------------------




import Control.Exception             (bracket)
import Control.Monad.Except          (MonadError, MonadIO, catchError, liftIO)
import Data.Maybe                    (fromMaybe)
import Data.Text                     (Text, pack)
import System.FilePath.Posix         (takeBaseName, takeDirectory)
import Text.InterpolatedString.Perl6 (qc)

import Prelude         hiding (catch)
import System.IO.Error hiding (catch)

import qualified Data.ByteString.Lazy    as B
import qualified Data.Text               as T
import qualified Data.Text.Encoding      as TE
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import qualified Data.Text.Lazy.Builder  as TB
import           Data.Text.Lazy.Encoding as TLE


import qualified Data.ByteString.Lazy as BL

import qualified Data.Vector as V

import Control.Exception
-- import Data.Aeson
import Data.Char
import Options.Applicative
import System.Directory
import System.IO

import Control.Monad
import Data.List
import System.FilePath

import Common.Yaml
import Surbgirq.Shell.Theographic.CsvTypes
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq
import Surbgirq.Types.Scripture


toTestamentId NewTestament = "new"
toTestamentId OldTestament = "old"
toTestamentId _            = "new"

-- | inPath: "./data/theodata/CSV"  outPath: ./data/csv
--  convertKjvCsv "./data/theodata/CSV" "./data/csv"
convertKjvCsv :: FilePath -> FilePath -> IO ()
convertKjvCsv inPath outPath = do
   let del = ';';
       arrayDel = "|"

   let outRootPath = outPath </> "scriptures"
       outFileRoot = outRootPath </>  "./bible/en/kjv"
       dataFolder = inPath

   createDirectoryIfMissing True outRootPath

   exists <- doesDirectoryExist dataFolder
     -- check if books input directory exists
   when exists $ do
       createDirectoryIfMissing True outFileRoot

   -- Books
   let booksFile = dataFolder </> "Books.csv"
   houtBooks <- openFile (outFileRoot </> "books.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Testament_BookRel.csv") WriteMode
   TIO.hPutStrLn houtBooks [qc|id:ID(KJV-BOOK-ID){del}bookOrder{del}osisref{del}shortName{del}slug{del}title{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(TESTAMENT-ID){del}:END_ID(KJV-BOOK-ID){del}:TYPE|]
   readEntity booksFile >>= \ v ->
       V.forM_  v $ \ (BookCsv{..}) -> do
           let bookID = osisName
               bookRow = [qc|{bookID}{del}{bookOrder}{del}{osisName}{del}{shortName}{del}{slug}{del}{bookName}{del}Book|]
               relRow = [qc|{toTestamentId testament}{del}{bookID}{del}CONTAINS|]
           TIO.hPutStrLn houtBooks bookRow
           TIO.hPutStrLn houtRelation relRow

   hClose houtBooks
   hClose houtRelation

   -- Chapters
   let chaptersFile = dataFolder </> "Chapters.csv"
   houtChapters <- openFile (outFileRoot </> "chapters.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Book_ChapterRel.csv") WriteMode
   TIO.hPutStrLn houtChapters [qc|id:ID(KJV-CHAPTER-ID){del}chapterNum{del}osisref{del}slug{del}title{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(KJV-BOOK-ID){del}:END_ID(KJV-CHAPTER-ID){del}:TYPE|]

   readEntity chaptersFile >>= \ v ->
       V.forM_  v $ \ (ChapterCsv{..}) -> do
           let chapterID = [qc|{chapter'osisRef}|]
               chapterTitle = [qc|{chapter'book} {chapter'chapterNum}|]
               chapterRow = [qc|{chapterID}{del}{chapter'chapterNum}{del}{chapter'osisRef}{del}{chapter'slug}{del}{chapterTitle}{del}Chapter|]
               relRow = [qc|{chapter'book}{del}{chapterID}{del}CONTAINS|]
           TIO.hPutStrLn houtChapters chapterRow
           TIO.hPutStrLn houtRelation relRow

   hClose houtChapters
   hClose houtRelation

   -- -- Verses
   let versesFile = dataFolder </> "Verses.csv"
   houtVerses <- openFile (outFileRoot </> "verses.csv") WriteMode
   houtRelation <- openFile (outFileRoot </> "Chapter_VerseRel.csv") WriteMode
   TIO.hPutStrLn houtVerses [qc|id:ID(KJV-VERSE-ID){del}verseNum{del}fullRef{del}osisRef{del}shortRef{del}mdText{del}verseText{del}title{del}:LABEL|]
   TIO.hPutStrLn houtRelation [qc|:START_ID(KJV-CHAPTER-ID){del}:END_ID(KJV-VERSE-ID){del}:TYPE|]

   readEntity versesFile >>= \ v ->
       V.forM_  v $ \ (VerseCsv{..}) -> do
           let verseID = verse'verseID
               shortRef = case splitOn "." verse'osisRef of
                            [book, ch, v] -> [qc|{book} {ch}:{v}|]
                            _             -> error verse'osisRef
               verseTitle = shortRef
               verseRow = [qc|{verseID}{del}{verse'verseNum}{del}{verse'osisRef}{del}{verse'osisRef}{del}{shortRef}{del}"{verse'mdText}"{del}"{verse'verseText}"{del}{verseTitle}{del}Verse|]
               relRow = [qc|{verse'chapter}{del}{verseID}{del}CONTAINS|]
           TIO.hPutStrLn houtVerses verseRow
           TIO.hPutStrLn houtRelation relRow

   -- Words
   -- let wordsFile = dataFolder </> "WordIndex.csv"
   -- readEntity wordsFile >>= \ v ->
   --     V.forM_  v $ \ (WordCsv{..}) -> print [qc|{word'BookID} {word'Word} |]


-- | "./data/theodata/CSV/Books.csv"
readEntity :: (FromNamedRecord a) => FilePath -> IO (Vector a)
readEntity booksFile = do
  csvData <- BL.readFile booksFile
  return $ case Cassava.decodeByName csvData of
        Left err      -> error err
        Right  (_, v) -> v


demoW :: IO ()
demoW = do
    csvData <- BL.readFile "./data/theodata/CSV/WordIndex.csv"
    case Cassava.decodeByName csvData of
        Left err -> putStrLn err
        Right  (_, v) -> V.forM_  v $ \ (WordCsv{..}) -> do
                    print [qc|{word'WordID} {word'Word}|]

demoV :: IO ()
demoV = do
    csvData <- BL.readFile "./data/theodata/CSV/Verses.csv"
    case Cassava.decodeByName csvData of
        Left err -> putStrLn err
        Right  (_, v) -> V.forM_  v $ \ (VerseCsv{..}) -> do
                    print [qc|{verse'osisRef} {verse'book}|]


demo1 :: IO ()
demo1 = do
    csvData <- BL.readFile "./data/theodata/CSV/Books.csv"
    case Cassava.decode HasHeader  csvData of
        Left err -> putStrLn err
        -- Right v -> print $ (V.toList v :: [String])
        Right  v -> do
          print "============================Start====================="
          V.forM_ v $ \a -> do
                    let xs = V.toList a :: [Text] -- (osisName,bookOrder) ->
                    print xs


