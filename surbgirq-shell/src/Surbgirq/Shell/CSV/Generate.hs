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
import Prelude hiding (catch)
import Control.Exception
import System.IO.Error hiding (catch)
    
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



data FileHandlers =  FileHandlers
    {
      outEntityBookRelh :: Handle
    -- * chapter
    , outChh :: Handle
    , outChSecRelh :: Handle
    , outChVerseRelh :: Handle
    -- * section
    , outSech :: Handle
    , outSecPrghRelh :: Handle
    -- * paragraph
    , outPrghh :: Handle
    , outPrghVerseRelh :: Handle
    -- * verse
    , outVerseh :: Handle
    -- * word/tokens
    , outWordsh :: Handle
    , outVerseWordRelh:: Handle
    -- * footnotes
    , outFootnotesh :: Handle
    , outWordFootnoteRelh :: Handle
    , outVerseFootnoteRelh :: Handle
    -- * refs
    , outRefsh :: Handle
    , outRefRelh :: Handle

  }
    

closeHs :: FileHandlers -> IO ()
closeHs FileHandlers {..} = do
  hClose outEntityBookRelh
  -- Chapters
  hClose outChh
  hClose outChVerseRelh       
  hClose outChSecRelh       
  -- sections
  hClose outSech
  hClose outSecPrghRelh
  hClose outPrghh
  hClose outPrghVerseRelh
  -- verses
  hClose outVerseh
  -- words         
  hClose outWordsh 
  hClose outVerseWordRelh
  -- footnotes
  hClose outFootnotesh
  hClose outWordFootnoteRelh
  hClose outVerseFootnoteRelh
  -- refs
  hClose outRefsh
  hClose outRefRelh


openHs :: FilePath -> FilePath -> Book -> IO FileHandlers
openHs outFileRoot outRefFileRoot Book{..} = do

    outEntityBookRelh <- openFile (outFileRoot </> [qc|EntityBookRel.csv|]) WriteMode

    -- chapter
    outChh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_chapters.csv|]) WriteMode
    outChSecRelh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_ChapterSectionRel.csv|]) WriteMode
    outChVerseRelh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_ChapterVerseRel.csv|]) WriteMode

    -- section
    outSech <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_sections.csv|]) WriteMode
    outSecPrghRelh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_SectionPrghRel.csv|]) WriteMode

    -- paragraph
    outPrghh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_prghs.csv|]) WriteMode
    outPrghVerseRelh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_PrghVerseRel.csv|]) WriteMode

    -- veses
    outVerseh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_verses.csv|]) WriteMode
    outVerseWordRelh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_VerseWordRel.csv|])  WriteMode

    -- words
    outWordsh <- openFile (outFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_words.csv|]) WriteMode

    -- footnotes
    outFootnotesh <- openFile (outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_footnotes.csv|]) WriteMode
    outWordFootnoteRelh <- openFile (outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_word_footnote.csv|]) WriteMode
    outVerseFootnoteRelh <- openFile (outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_verse_footnote.csv|]) WriteMode

    -- reference
    outRefsh <- openFile (outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_refs.csv|]) WriteMode
    outRefRelh <- openFile (outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}_WordRefRel.csv|]) WriteMode

    return  FileHandlers {..}  

                        
-- | Generate all possible csv file for a book
-- to use with neo4j-import '* scheme'
generateScripturesCSV :: FilePath -> FilePath -> FilePath -> IO ()
generateScripturesCSV configFile path outPath = do
   let del = ';';
       arrayDel = "|"      

   corpora :: Corpora <- readYaml configFile

   TIO.putStrLn  $ T.pack $ show corpora

   TIO.putStrLn "reading list of Scriptures..."
   scriptures :: [Scripture] <- readYaml (corpora'scripturesPath corpora)

   let outRootPath = outPath </> "scriptures" 

   createDirectoryIfMissing True outRootPath

   dumpCSVHeaders del outRootPath
                            
   bracket (do
              h1 <- openFile (outRootPath </> [qc|books.csv|]) WriteMode -- save all books in one place
              h2 <- openFile (outRootPath </> [qc|translations.csv|]) WriteMode
              h3 <- openFile (outRootPath </> [qc|divisions.csv|]) WriteMode
              h4 <- openFile (outRootPath </> [qc|testaments.csv|]) WriteMode
              h5 <- openFile (outRootPath </> [qc|scriptures.csv|]) WriteMode
              h6 <- openFile (outRootPath </> [qc|scriptureRel.csv|]) WriteMode
              h7 <- openFile (outRootPath </> [qc|BookChapterRel.csv|]) WriteMode
              return (h1,h2,h3,h4,h5,h6, h7))
            (\(h1, h2, h3, h4, h5, h6, h7) -> do
               hClose h1
               hClose h2
               hClose h3
               hClose h4
               hClose h5
               hClose h6
               hClose h7
             ) $ \(outBookh, outTranslationh, outDivisionh, outTestamenth, outScriptureh, outScriptureBookRelth, outBookChapterRelh) -> do


     TIO.hPutStrLn outBookh [qc|bookID:ID{del}book{del}title{del}bookOrder:int{del}chapters:int{del}testament{del}:LABEL|]
     TIO.hPutStrLn outTranslationh [qc|translationID:ID{del}name{del}version{del}language{del}from{del}year{del}dialect{del}lang{del}translators{del}description{del}:LABEL|]
     TIO.hPutStrLn outScriptureh [qc|scriptureID:ID{del}title|]
     TIO.hPutStrLn outScriptureBookRelth [qc|:START_ID{del}:END_ID{del}:TYPE|]

        
     TIO.putStrLn "Reading Translations ..."
     translations :: [Translation] <- readYaml (corpora'translationsPath corpora)
     forM_ translations $ \tr@Translation{..} -> do
       let trTranslators = T.intercalate (T.pack arrayDel) translation'translators
           trLine = [qc|{translation'ID}{del}{translation'name}{del}{translation'version}{del}{translation'language}{del}{translation'from}{del}{translation'year}{del}{translation'dialect}{del}{translation'lang}{del}{trTranslators}{del}{translation'description}{del}Translation|]
       TIO.hPutStrLn outTranslationh trLine

   -- read word forms csv file
   --  wordForms <- parseWordFormFile wordFormFile

        
     -- TODO: read words/WordForms.csv
     -- find verse  tokens in wordForms list and make referecen 
        
     -- scriptures
     forM_ scriptures $ \scripture@Scripture{..} -> do

       let outFileRoot = outRootPath </> T.unpack scripture'dataFolder
           outRefFileRoot = outFileRoot </> "refs"
           dataFolder = path </> T.unpack scripture'dataFolder
           scriptureID = scripture'ID
           scriptureLine = [qc|{scriptureID}{del}{scripture'Info}|]

       TIO.putStrLn [qc|Scripture: {dataFolder}|]
       TIO.hPutStrLn outScriptureh scriptureLine
          

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
               translationID = T.unpack scripture'translationID

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
                   bookID = concat [T.unpack book'shortName, translationID, lang, show book'orderNum]
                   bookLine = [qc|{bookID}{del}{book'book}{del}{book'title}{del}{book'orderNum}{del}{book'chapters}{del}{book'testament}{del}{bookNodeLabels}|]

               TIO.hPutStrLn outBookh bookLine

               let entityBookRel = [qc|{translationID}{del}{bookID}{del}CONTAINS|]
                   scriptureBookRel = [qc|{scriptureID}{del}{bookID}{del}CONTAINS|]
               TIO.hPutStrLn outScriptureBookRelth entityBookRel
               TIO.hPutStrLn outScriptureBookRelth scriptureBookRel
                



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

                       let wordIDPrefix = concat ["word_", T.unpack book'shortName, "_", translationID,  "_", show  chapter'number, show section'number, show paragraph'number, show verse'verse]
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
                                    word_footnote_rel  = [qc|{refWordID}{del}{footnoteID}{del}REF_FOOTNOTE|]
                                    verse_footnote_rel  = [qc|{verseID}{del}{footnoteID}{del}REF_FOOTNOTE|]

                                TIO.hPutStrLn outFootnotesh footnoteLine

                                -- TODO: re-think this ref types
                                when (verseRef'index > 0) $ TIO.hPutStrLn outWordFootnoteRelh word_footnote_rel
                                TIO.hPutStrLn outVerseFootnoteRelh  verse_footnote_rel
                                   
--                              RefVerse txt -> do
--                                let refWordID = concat [wordIDPrefix, "-", show verseRef'index]
--                                    footnoteID = concat ["ref_", wordIDPrefix, "-", show verseRef'index]
--                                    footnoteLine = [qc|{footnoteID}{del}{txt}{del}{verseRef'index}{del}Footnote|]
--                                    footnoteRel  = [qc|{refWordID}{del}{footnoteID}{del}REF_FOOTNOTE|]
--                                TIO.hPutStrLn outRefsh footnoteLine
--                                TIO.hPutStrLn outRefRelh footnoteRel
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




removeIfExists :: FilePath -> IO ()
removeIfExists fileName = removeFile fileName `catch` handleExists
  where handleExists e
          | isDoesNotExistError e = return ()
          | otherwise = throwIO e


data CSVHeader = CSVHeader
    { csvHeader'name :: String
    , csvHeader'file :: FilePath
    , csvHeader'header :: Text
    } deriving (Show)

mkHeader name path template = CSVHeader name path template
dumpCSVHeaders :: Char -> FilePath -> IO ()
dumpCSVHeaders del root = do
                                                  
  let headerRoot = root </> "headers"
      hs = [ mkHeader "Scripture Header" "scripture_header.csv" [qc|scriptureID:ID{del}title|]
           , mkHeader "Scripture to Book relationship Header" "scripture_book_header.csv" [qc|:START_ID{del}:END_ID{del}:TYPE|]
           , mkHeader "Translation Header" "translation_header.csv" [qc|translationID:ID{del}name{del}version{del}language{del}from{del}year{del}dialect{del}lang{del}translators{del}description{del}:LABEL|]
           -- * Book
           , mkHeader "Book Header" "book_header.csv" [qc|bookID:ID{del}book{del}title{del}bookOrder:int{del}chapters:int{del}testament{del}:LABEL|]
           , mkHeader "Book to Chapter return Header" "book_chapter_header.csv" [qc|:START_ID{del}:END_ID(CHAPTER-ID)|]
           -- * Chapter
           , mkHeader "Chapter Header" "chapter_header.csv" [qc|chapterID:ID(CHAPTER-ID){del}title{del}num:int{del}book|]
           , mkHeader "Chapter to Verse Relation Header" "chapter_verse_header.csv" [qc|:START_ID(CHAPTER-ID){del}:END_ID(VERSE-ID)|]
           , mkHeader "Chapter to Section Relation Header" "chapter_section_header.csv" [qc|:START_ID(CHAPTER-ID){del}:END_ID(CHAPTER-ID)|]
           -- * Section Headers
           , mkHeader "Section Header" "section_header.csv"  [qc|sectionID:ID(CHAPTER-ID){del}title{del}num:int{del}chapter:int|]
           , mkHeader "Section to Prgh Relation Header" "section_prgh_header.csv"  [qc|:START_ID(CHAPTER-ID){del}:END_ID(CHAPTER-ID)|]
           -- * prgh
           , mkHeader "Paragraph Header" "prgh_header.csv" [qc|prghID:ID(CHAPTER-ID){del}title{del}num:int{del}section:int{del}chapter:int|]
           -- * Verse
           , mkHeader "Verse Header" "verse_header.csv" [qc|verseID:ID(VERSE-ID){del}book{del}chapter:int{del}section:int{del}paragraph:int{del}verse:int{del}verseText|]
           , mkHeader "Verse to Word Relation Header" "verse_word_header.csv" [qc|:START_ID(VERSE-ID){del}:END_ID(WORD-ID)|]
           , mkHeader "Verse to FootNote  Header" "verse_footnote_header.csv" [qc|:START_ID(VERSE-ID){del}:END_ID(FOOTNOTE-ID){del}:TYPE|]
           -- * Word
           , mkHeader "Word Header" "word_header.csv"  [qc|wordID:ID(WORD-ID){del}word{del}book{del}chapter:int{del}section:int{del}paragraph:int{del}verse:int{del}token{del}versePos:int{del}:LABEL|]
           , mkHeader "Word to Footnote  Header" "word_footnote_header.csv" [qc|:START_ID(WORD-ID){del}:END_ID(FOOTNOTE-ID){del}:TYPE|]
           -- * Footnote header
           , mkHeader "Footnote Header" "footnote_header.csv"  [qc|footnoteID:ID(FOOTNOTE-ID){del}text{del}index:int{del}:LABEL|]
           -- * Ref header
           , mkHeader "Reference Header" "ref_header.csv"  [qc|refID:ID(FOOTNOTE-ID){del}text{del}index:int{del}:LABEL|]
            ]

  createDirectoryIfMissing True headerRoot
                           
  forM_ hs $ \CSVHeader{..} -> do
    let fullPath = headerRoot </> csvHeader'file
    hFile <- openFile fullPath WriteMode
    TIO.hPutStrLn hFile csvHeader'header
    TIO.putStrLn [qc|Created header: {csvHeader'name} - {fullPath}|]
    hClose hFile




-- seems not used

generateVerseCsv :: FilePath -> FilePath -> FilePath -> IO ()
generateVerseCsv bookFile path outPath = do
   let del = ';';
       arrayDel = "|";
   corpora :: Corpora <- readYaml bookFile

   scriptures :: [Scripture] <- readYaml (corpora'scripturesPath corpora)

   let books = let  (x:_) = scriptures in scripture'books x

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



-- | attempt to seperate verse processing
-- there are a lot of paramteres from context
refProcessing _ _ Nothing _ _  = return ()
refProcessing del wordIDPrefix  (Just VerseRef{..}) outRefsh outRefRelh = do
       case verseRef'type of
         RefText txt -> do
           let refWordID = concat [wordIDPrefix, "-", show verseRef'index]
               footnoteID = concat ["ref_", wordIDPrefix, "-", show verseRef'index]
               footnoteLine = [qc|{footnoteID}{del}{txt}{del}{verseRef'index}{del}Footnote|]
               word_footnote_rel  = [qc|{refWordID}{del}{footnoteID}{del}REF_FOOTNOTE|]
--               verse_footnote_rel  = [qc|{verseID}{del}{footnoteID}{del}REF_FOOTNOTE|]

           TIO.hPutStrLn outRefsh footnoteLine
           TIO.hPutStrLn outRefRelh word_footnote_rel
  --                              RefVerse txt -> do
  --                                let refWordID = concat [wordIDPrefix, "-", show verseRef'index]
  --                                    footnoteID = concat ["ref_", wordIDPrefix, "-", show verseRef'index]
  --                                    footnoteLine = [qc|{footnoteID}{del}{txt}{del}{verseRef'index}{del}Footnote|]
  --                                    footnoteRel  = [qc|{refWordID}{del}{footnoteID}{del}REF_FOOTNOTE|]
  --                                TIO.hPutStrLn outRefsh footnoteLine
  --                                TIO.hPutStrLn outRefRelh footnoteRel
         _ -> return ()

