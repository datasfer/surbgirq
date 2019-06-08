{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
module Main where

import Common.Yaml
import Data.Text (pack, Text)
import qualified Data.Text as T
import Data.Aeson 
import System.IO
import qualified Data.Text.Encoding as TE
import Data.Text.Lazy.Encoding as TLE
import qualified Data.Text.IO as TIO
import qualified Data.Text.Lazy as TL
import Options.Applicative
import System.Directory
import Text.InterpolatedString.Perl6 (qc)
import System.FilePath.Posix (takeBaseName)

    
import           Control.Monad
import           System.FilePath
import           Data.List

    
import Surbgirq.Shell.Commands
import Surbgirq.Types

main1 :: IO ()
main1 = do
 -- bs <- readBooks "./data/yaml/books.yaml"
--  ss1 <- readScriptures "./data/yaml/matthew/1.yaml"
--  ss <- readSections "./data/yaml/matthew/1.yaml"
  ch <- readChapter "./data/yaml/matthew/1.yaml"
--  mapM_  (\Section{..} -> )chapter'sections
  hSetEncoding stdout utf8
  let res = (TL.toStrict . TLE.decodeUtf8 $ encode ch)               
  TIO.writeFile "file.txt" res
  TIO.putStrLn res
  TIO.putStrLn "Գիրք ծննդեան"


main :: IO ()
main = do
  cmd <- customExecParser (prefs showHelpOnError) $
         info (helper <*> parser) $
         fullDesc <> progDesc "Format Scriptures to convenient formats."
                  <> header   "Surbgirq text formatter."
                  <> footer   ("the generated json or neo4j sypther will be used to populate db")

  case cmd of
    Command{..} -> do
             ch <- readChapter prmChapterFile
             let res = (TL.toStrict . TLE.decodeUtf8 $ encode ch)
             generateInitCypher "./data/yaml"
             TIO.writeFile "file.txt" res
             TIO.putStrLn res

readBooks :: FilePath -> IO [Book]
readBooks file = do
  books <- readYaml file
  putStrLn $ mconcat ["Loaded ", show $ length books, " books"]
  return books

readScriptures :: FilePath -> IO [Scripture]
readScriptures file = do
  book <- readYaml file
  return book

readSections :: FilePath -> IO [Section]
readSections file = do
  book <- readYaml file
  return book

readChapter :: FilePath -> IO Chapter
readChapter file = do
  book <- readYaml file
  return book

readBook :: FilePath -> IO Book
readBook file = do
  book <- readYaml file
  return book



-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

class NodeName t where
    node :: t -> Text

instance NodeName Book where
    node _ = "Book"

generateInitCypher :: FilePath -> IO ()
generateInitCypher path = do
    names <- listDirectory path
    forM_ names $ \name -> when (isDir name) $ do
      let bookDir = path </> name
          outFile = path </> [qc|{name}.cypher|]           
      txtFiles <- listDirectory bookDir
      outh <- openFile outFile WriteMode
      TIO.hPutStrLn outh "CREATE"
      TIO.hPutStrLn outh [qc|  ({name}:Matthew:New:Book \{title: '{name}'}),|]

      let del = "_";
      -- a file == a chapter   
      forM_ (sort txtFiles) $ \file -> when (doesFilenameMatch file) $ do
        ch@Chapeter{..} <- readChapter (bookDir </> file)
                             
        let chName = concat [name, del, "ch", takeBaseName file]
            chNode = [qc|  ({chName}:Chapter \{title: 'Գլ. {chapter'number}'}),|]
            chRel  = [qc|  ({name})-[:HAS_CH]->({chName}),|]

        TIO.hPutStrLn outh chNode
        TIO.hPutStrLn outh chRel

        -- Sections   
        forM_ chapter'sections $ \Section{..} -> do
          let secName = concat [chName, del, "sec", show section'number ]
              secNode = [qc|  ({secName}:Section \{title: '{section'title}'}),|]
              secRel  = [qc|  ({chName})-[:HAS_SEC]->({secName}),|]

          TIO.hPutStrLn outh secNode
          TIO.hPutStrLn outh secRel

           -- Paragraphs
          forM_ section'paragraphs $ \Paragraph{..} -> do
            let prghName = concat [secName, del, "prgh", show paragraph'number]
                prghNode = [qc|  ({prghName}:Paragraph \{title: ''}),|]
                prghRel  = [qc|  ({secName})-[:HAS_PRGH]->({prghName}),|]

            TIO.hPutStrLn outh prghNode
            TIO.hPutStrLn outh prghRel

            -- Verses
            forM_ paragraph'verses $ \Verse{..} -> do
              let verseName = concat [prghName , del, "verse", show verse'verse]
                  verseNode = [qc|  ({verseName}:Verse \{book: '{name}', content: '{verse'content}', verse: {verse'verse}, section: {section'number}, paragraph: {paragraph'number}, chapter: {chapter'number}  }),|]
                  verseRel  = [qc|  ({prghName})-[:HAS_VERSE]->({verseName}),|]
              TIO.hPutStrLn outh verseNode
              TIO.hPutStrLn outh verseRel

              let ws = T.splitOn " " verse'content
              -- add each word as node
              forM_ (zip ws [1..] ) $ \(word, index) -> do
                let wordName = concat [verseName, del, "word", show index]
                    wordNode = [qc|  ({wordName}:Word \{word: '{word}', index: {index}}),|]
                    wordRel  = [qc|  ({verseName})-[:HAS_WORD]->({wordName}),|]
                TIO.hPutStrLn outh wordNode
                TIO.hPutStrLn outh wordRel
              -- add [NEEXT] relationshipp between words
              forM_ (zip (zip ws (tail' ws)) [1..] ) $ \((w1, w2), index) -> do
                let w1Name = concat [verseName, del, "word", show index]
                    w2Name = concat [verseName, del, "word", show $ index + 1]
                    nextRel  = [qc|  ({w1Name})-[:NEXT]->({w2Name}),|]
                TIO.hPutStrLn outh nextRel

                 

--          let res = (TL.toStrict . TLE.decodeUtf8 $ encode ch)
      hClose outh
  where
    tail' :: [a] -> [a]
    tail' [] = []
    tail' (x:xs) = xs
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".yaml", ".yml"]
    isDir :: FilePath -> Bool
    isDir path = takeExtension path == ""
