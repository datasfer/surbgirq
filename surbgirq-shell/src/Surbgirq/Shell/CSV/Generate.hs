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
       arrayDel = "|";
   books :: [Book] <- readYaml bookFile -- path </> "books.yaml"

   -- Booksx
   forM_ books $ \Book{..} -> do

     let inPath = fromMaybe (T.toLower . T.pack $ show book'book ) book'input
         bookDir = path </> (T.unpack inPath)

         -- cypher out file
         outCypherFileRoot = outPath </> (takeDirectory $ T.unpack inPath)
         outFile = outCypherFileRoot </> [qc|{T.toLower . T.pack $ show book'book}.csv|]
         outFileHeader = outCypherFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_header.csv|]

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
                  h2 <- openFile outFile WriteMode
                  h3 <- openFile outRefFile WriteMode
                  return (h1, h2, h3))
                (\(h1, h2, h3) -> do
                   hClose h1
                   hClose h2
                   hClose h3) $ \(outh, outhHeader, outRefh) -> do


         TIO.hPutStrLn outhHeader ""

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



data FileHandlers =  FileHandlers
    {
     -- * scriptures
  --    outTranslationh :: Handle
  --  , outDivisionh :: Handle
  --  , outTestamenth :: Handle
  --  , outScriptureBookRelth :: Handle
    -- * book
    -- ,  outBookh :: Handle
    -- , outBookHeaderh :: Handle
     
      outBookChapterRelh :: Handle
    , outBookChapterRelHeaderh :: Handle
    -- * chapter
    , outChh :: Handle
    , outChHeaderh :: Handle
    , outChSecRelh :: Handle
    , outChSecRelHeaderh :: Handle
    , outChVerseRelh :: Handle
    , outChVerseRelHeaderh :: Handle
    -- * section
    , outSech :: Handle
    , outSecHeaderh :: Handle
    , outSecPrghRelh :: Handle
    , outSecPrghRelHeaderh :: Handle
    -- * paragraph
    , outPrghh :: Handle
    , outPrghHeaderh :: Handle
    , outPrghVerseRelh :: Handle
    , outPrghVerseRelHeaderh :: Handle
    -- * verse
    , outVerseh :: Handle
    , outVerseHeaderh :: Handle
      -- * word/tokens
    , outWordsh :: Handle
    , outWordsHeaderh :: Handle
    , outVerseWordRelh:: Handle
    , outVerseWordRelHeaderh:: Handle
    -- * refs
    , outRefsh :: Handle
    , outRefsHeaderh :: Handle
    , outRefRelh :: Handle
    , outRefRelHeaderh :: Handle
  }
    

closeHs :: FileHandlers -> IO ()
closeHs FileHandlers {..} = do

  -- scriptures with headers
--  hClose outTranslationh
--  hClose outDivisionh       
--  hClose outTestamenth
--  hClose outScriptureBookRelth

  -- books
  -- hClose outBookh
  -- hClose outBookHeaderh       
  hClose outBookChapterRelh       
  hClose outBookChapterRelHeaderh

  -- books
  -- hClose outBookh
  -- hClose outBookHeaderh       
  hClose outBookChapterRelh       
  hClose outBookChapterRelHeaderh
  -- Chapters
  hClose outChh
  hClose outChHeaderh       
  hClose outChVerseRelh       
  hClose outChVerseRelHeaderh
  hClose outChSecRelh       
  hClose outChSecRelHeaderh
  -- sections
  hClose outSech
  hClose outSecHeaderh 
  hClose outSecPrghRelh
  hClose outSecPrghRelHeaderh
  -- paragraphs
  hClose outPrghh
  hClose outPrghHeaderh 
  hClose outPrghVerseRelh
  hClose outPrghVerseRelHeaderh
  -- verses
  hClose outVerseh
  hClose outVerseHeaderh
  -- words         
  hClose outWordsh 
  hClose outWordsHeaderh 
  hClose outVerseWordRelh
  hClose outVerseWordRelHeaderh
  -- refs
  hClose outRefsh
  hClose outRefsHeaderh
  hClose outRefRelh
  hClose outRefRelHeaderh



openHs :: FilePath -> FilePath -> Book -> IO FileHandlers
openHs outFileRoot outRefFileRoot Book{..} = do
       let
           -- Books
           -- outBook = outFileRoot </> [qc|books.csv|]
           -- outBookHeader = outFileRoot </> [qc|book_header.csv|]
           outBookChapterRel = outFileRoot </> [qc|BookChapterRel.csv|]
           outBookChapterRelHeader = outFileRoot </> [qc|BookChapterRel_Header.csv|]

           -- Chapters
           outCh = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_chapters.csv|]
           outChHeader = outFileRoot </> [qc|chapter_header.csv|]
           outChSecRel = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_ChapterSectionRel.csv|]
           outChSecRelHeader = outFileRoot </> [qc|ChapterSectionRel_Header.csv|]

           outChVerseRel = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_ChapterVerseRel.csv|]
           outChVerseRelHeader = outFileRoot </> [qc|ChapterVerseRel_Header.csv|]

           -- Sections
           outSec = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_sections.csv|]
           outSecHeader = outFileRoot </> [qc|section_header.csv|]

           outSecPrghRel = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_SectionPrghRel.csv|]
           outSecPrghRelHeader = outFileRoot </> [qc|SectionPrghRel_Header.csv|]

           -- Paragraphs
           outPrgh = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_prghs.csv|]
           outPrghHeader = outFileRoot </> [qc|prgh_header.csv|]

           outPrghVerseRel = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_PrghVerseRel.csv|]
           outPrghVerseRelHeader = outFileRoot </> [qc|PrghVerseRel_Header.csv|]

           -- Verses
           outVerse = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_verses.csv|]
           outVerseHeader = outFileRoot </> [qc|verse_header.csv|]
           outVerseWordRel = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_VerseWordRel.csv|]
           outVerseWordRelHeader = outFileRoot </> [qc|VerseWordRel_Header.csv|]

           -- Words
           outWords = outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_words.csv|]
           outWordsHeader = outFileRoot </> [qc|word_header.csv|]

           -- ref file
           outRefsHeader = outRefFileRoot </> [qc|ref_header.csv|]
           outRefs = outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_refs.csv|]
           outRefRel = outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_WordRefRel.csv|]
           outRefRelHeader = outRefFileRoot </> [qc|WordRefRel_Header.csv|]

       -- scriptures -- append

       -- books -- append
  --     outBookh <- openFile outBook AppendMode
       --- outBookHeaderh <- openFile outBookHeader WriteMode
       outBookChapterRelh <- openFile outBookChapterRel AppendMode
       outBookChapterRelHeaderh <- openFile outBookChapterRelHeader WriteMode

       -- chapter
       outChh <- openFile outCh WriteMode
       outChHeaderh <- openFile outChHeader WriteMode
       outChSecRelh <- openFile outChSecRel WriteMode
       outChSecRelHeaderh <- openFile outChSecRelHeader WriteMode
       outChVerseRelh <- openFile outChVerseRel WriteMode
       outChVerseRelHeaderh <- openFile outChVerseRelHeader WriteMode

       -- section
       outSech <- openFile outSec WriteMode
       outSecHeaderh <- openFile outSecHeader WriteMode
       outSecPrghRelh <- openFile outSecPrghRel WriteMode
       outSecPrghRelHeaderh <- openFile outSecPrghRelHeader WriteMode

       -- paragraph
       outPrghh <- openFile outPrgh WriteMode
       outPrghHeaderh <- openFile outPrghHeader WriteMode
       outPrghVerseRelh <- openFile outPrghVerseRel WriteMode
       outPrghVerseRelHeaderh <- openFile outPrghVerseRelHeader WriteMode

       -- veses
       outVerseh <- openFile outVerse WriteMode
       outVerseHeaderh <- openFile outVerseHeader WriteMode
       outVerseWordRelh <- openFile outVerseWordRel  WriteMode
       outVerseWordRelHeaderh <- openFile outVerseWordRelHeader WriteMode

       -- words
       outWordsh <- openFile outWords WriteMode
       outWordsHeaderh <- openFile outWordsHeader WriteMode

       -- reference
       outRefsh <- openFile outRefs WriteMode
       outRefsHeaderh <- openFile outRefsHeader WriteMode
       outRefRelh <- openFile outRefRel WriteMode
       outRefRelHeaderh <- openFile outRefRelHeader WriteMode

       return  FileHandlers {..}  


-- removeIfExists :: FilePath -> IO ()
-- removeIfExists fileName = removeFile fileName `catch` handleExists
--  where handleExists e
--          | isDoesNotExistError e = return ()
--          | otherwise = throwIO e
                        
-- | Generate all possible csv file for a book
-- to use with neo4j-import '* scheme'
generateAllCsv :: FilePath -> FilePath -> FilePath -> IO ()
generateAllCsv bookFile path outPath = do
   let del = ';';
       arrayDel = "|"      

   scriptures :: [Scripture] <- readYaml bookFile -- path </> "books.yaml"

   let outRootPath = outPath </> "scriptures" 


   createDirectoryIfMissing True outRootPath
    
   bracket (do
              h1 <- openFile (outRootPath </> [qc|books.csv|]) WriteMode -- save all books in one place
              h2 <- openFile (outRootPath </> [qc|translations.csv|]) WriteMode
              h3 <- openFile (outRootPath </> [qc|divisions.csv|]) WriteMode
              h4 <- openFile (outRootPath </> [qc|testaments.csv|]) WriteMode
              h5 <- openFile (outRootPath </> [qc|scriptureRel.csv|]) WriteMode
              return (h1,h2,h3,h4,h5))
            (\(h1, h2, h3, h4, h5) -> do
               hClose h1
               hClose h2
               hClose h3
               hClose h4
               hClose h5
             ) $ \(outBookh, outTranslationh, outDivisionh, outTestamenth, outScriptureBookRelth) -> do


     TIO.hPutStrLn outBookh [qc|bookID:ID{del}book{del}title{del}bookOrder:int{del}chapters:int{del}testament{del}translation{del}:LABEL|]
     TIO.hPutStrLn outTranslationh [qc|translationID:ID{del}book{del}title{del}bookOrder:int{del}chapters:int{del}testament{del}translation{del}:LABEL|]
                      
     -- scriptures
     forM_ scriptures $ \scripture@Scripture{..} -> do

       let outFileRoot = outRootPath </> T.unpack scripture'dataFolder
           outRefFileRoot = outFileRoot </> "refs"
           dataFolder = path </> T.unpack scripture'dataFolder

       TIO.putStrLn [qc|Scripture: {dataFolder}|]

       exists <- doesDirectoryExist dataFolder
         -- check if books input directory exists
       when exists $ do
           -- here no need to error check
           createDirectoryIfMissing True outFileRoot
           createDirectoryIfMissing True outRefFileRoot

       -- Books
       forM_ scripture'books $ \book@Book{..} -> do

           TIO.putStrLn [qc|Book: {book'input}|]

           let bookInput = T.unpack $ fromMaybe (T.toLower . T.pack $ show book'book ) book'input
               bookDir = dataFolder </> bookInput
               bookLabel = maybe (show book'book) ((show book'book) ++)  (T.unpack <$> book'labels)
               bookTestament = show book'testament
               bookName = show book'book
               lang = show   book'language
               dialect = show  book'dialect
               translation = T.unpack $ translation'ID scripture'translation

           TIO.putStrLn [qc|Book text path: {bookDir}|]

           -- check if bookdir exist
           exists <- doesDirectoryExist bookDir
           -- check if books input directory exists
           when exists $ do
             txtFiles <- listDirectory bookDir `catchError` \_ -> do
                                          liftIO $ putStrLn (concat [bookDir, " does not exist."])
                                          return []

             bracket (openHs outFileRoot outRefFileRoot book) closeHs
                         $ \FileHandlers {..} -> do


               -- book csv
               let bookNodeLabels = intercalate arrayDel [bookName, lang, dialect, bookLabel, bookTestament, "Book"]
                   bookID = concat [T.unpack book'shortName, translation, lang, show book'number]
                   bookLine = [qc|{bookID}{del}{book'book}{del}{book'title}{del}{book'number}{del}{book'chapters}{del}{book'testament}{del}{book'translation}{del}{bookNodeLabels}|]

               TIO.hPutStrLn outBookh bookLine


               -- Book Headers
               -- TIO.hPutStrLn outBookHeaderh [qc|bookID:ID{del}book{del}title{del}bookOrder:int{del}chapters:int{del}testament{del}translation{del}:LABEL|]
               TIO.hPutStrLn outBookChapterRelHeaderh [qc|:START_ID{del}:END_ID(CHAPTER-ID)|]

               -- Chapter Headers
               TIO.hPutStrLn outChHeaderh [qc|chapterID:ID(CHAPTER-ID){del}title{del}num:int{del}book|]
               TIO.hPutStrLn outChSecRelHeaderh [qc|:START_ID(CHAPTER-ID){del}:END_ID(CHAPTER-ID)|]

               TIO.hPutStrLn outChVerseRelHeaderh [qc|:START_ID(CHAPTER-ID){del}:END_ID(VERSE-ID)|]

               -- Section Headers
               TIO.hPutStrLn outSecHeaderh [qc|sectionID:ID(CHAPTER-ID){del}title{del}num:int{del}chapter:int|]
               TIO.hPutStrLn outSecPrghRelHeaderh  [qc|:START_ID(CHAPTER-ID){del}:END_ID(CHAPTER-ID)|]

               -- Paragraph Headers
               TIO.hPutStrLn outPrghHeaderh [qc|prghID:ID(CHAPTER-ID){del}title{del}num:int{del}section:int{del}chapter:int|]

               -- Verse Headers
               TIO.hPutStrLn outVerseHeaderh [qc|verseID:ID(VERSE-ID){del}book{del}chapter:int{del}section:int{del}paragraph:int{del}verse:int{del}verseText|]

               -- Words Headers
               TIO.hPutStrLn outWordsHeaderh [qc|wordID:ID(WORD-ID){del}word{del}book{del}chapter:int{del}section:int{del}paragraph:int{del}verse:int{del}token{del}versePos:int{del}:LABEL|]
               TIO.hPutStrLn outVerseWordRelHeaderh [qc|:START_ID(VERSE-ID){del}:END_ID(WORD-ID)|]

               -- Ref Headers
               TIO.hPutStrLn outRefsHeaderh [qc|refID:ID(REF-ID){del}text{del}index:int{del}:LABEL|]
               TIO.hPutStrLn outRefRelHeaderh [qc|:START_ID(WORD-ID){del}:END_ID(REF-ID){del}:TYPE|]




               -- a file == a chapter
               -- Chapter
               forM_ (sort txtFiles) $ \file -> when (doesFilenameMatch file) $ do
                 ch@Chapeter{..} <- readChapter (bookDir </> file)
                 let chapterID = concat [bookID, "-", show chapter'number ]
                     chNode = [qc|{chapterID}{del}Գլ. {chapter'number}{del}{chapter'number}{del}{show book'book}|]
                     bookRel  = [qc|{bookID}{del}{chapterID}|]

                 TIO.hPutStrLn outChh chNode
                 TIO.hPutStrLn outBookChapterRelh bookRel

                 -- Sections
                 forM_ chapter'sections $ \Section{..} -> do
                   let sectionID = concat [chapterID, "-", show section'number ]
                       secLine = [qc|{sectionID}{del}{section'title}{del}{section'number}{del}{chapter'number}|]
                   TIO.hPutStrLn outSech secLine
                   TIO.hPutStrLn outChSecRelh  [qc|{chapterID}{del}{sectionID}|]

                    -- Paragraphs
                   forM_ section'paragraphs $ \Paragraph{..} -> do
                     let prghID = concat [sectionID, "-", show paragraph'number ]
                         prghLine = [qc|{prghID}{del}{section'title}{del}{paragraph'number}{del}{section'number}{del}{chapter'number}|]
                     TIO.hPutStrLn outPrghh prghLine
                     TIO.hPutStrLn outSecPrghRelh  [qc|{sectionID}{del}{prghID}|]

                     -- Verses
                     forM_ paragraph'verses $ \v@Verse{..} -> do
                       let verseID = concat [chapterID, ".", show verse'verse]
                           verseLine = [qc|{verseID}{del}{bookLabel}{del}{chapter'number}{del}{section'number}{del}{paragraph'number}{del}{verse'verse}{del}{verse'content}|]
                           -- verseWords = T.words verse'content
                           verseWords = filter ((>0) . T.length) $ T.splitOn " " verse'content

                       TIO.hPutStrLn outVerseh verseLine
                       TIO.hPutStrLn outChVerseRelh  [qc|{chapterID}{del}{verseID}|]
                       TIO.hPutStrLn outChVerseRelh  [qc|{prghID}{del}{verseID}|]

                       let wordIDPrefix = concat ["word_", T.unpack book'shortName, "_", show  chapter'number, show section'number, show paragraph'number, show verse'verse]
                       forM_ (zip [1..] verseWords) $ \(index,word) -> do
                         let wordID = concat [ wordIDPrefix, "-", show index]
                             wordNodeLabels = wordLabels word (show book'language) (show book'dialect) arrayDel
                             token = word
                             wordLine = [qc|{wordID}{del}{word}{del}{bookLabel}{del}{chapter'number}{del}{section'number}{del}{paragraph'number}{del}{verse'verse}{del}{token}{del}{index}{del}{wordNodeLabels}|]
                             vwRel  = [qc|{verseID}{del}{wordID}|]


                         TIO.hPutStrLn outWordsh wordLine
                         TIO.hPutStrLn outVerseWordRelh vwRel

                       -- verse ref processing
                       case verse'ref of
                          Nothing -> return ()
                          Just VerseRef{..} -> do
                            case verseRef'type of
                              RefText txt -> do
                                let refWordID = concat [wordIDPrefix, "-", show verseRef'index]
                                    footnoteID = concat ["ref_", wordIDPrefix, "-", show verseRef'index]
                                    footnoteLine = [qc|{footnoteID}{del}{txt}{del}{verseRef'index}{del}Footnote|]
                                    footnoteRel  = [qc|{refWordID}{del}{footnoteID}{del}REF_FOOTNOTE|]
                                TIO.hPutStrLn outRefsh footnoteLine
                                TIO.hPutStrLn outRefRelh footnoteRel
                              _ -> return ()


  where
    wordLabels :: Text -> String -> String -> String -> String
    wordLabels w lang dialect arrayDel =
        if isLower $ T.head w
        then concat [lang, arrayDel, dialect, arrayDel, "Word"]
        else concat [lang, arrayDel, dialect, arrayDel, "Capitalized", arrayDel, "Word"]

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



