{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where


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
import Surbgirq.Shell.Commands
import Surbgirq.Shell.Store.Neo4j
import Surbgirq.Shell.Types
import Surbgirq.Types.Girq

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

-- |  stack exec -- surbgirq-shell --bible -c ./data/yaml/books.yaml -i ./data/yaml -o ./data/cypher
main :: IO ()
main = do
  cmd <- customExecParser (prefs showHelpOnError) $
         info (helper <*> parser) $
         fullDesc <> progDesc "Format Scriptures to convenient formats."
                  <> header   "Surbgirq text formatter."
                  <> footer   ("the generated json or neo4j cypther will be used to populate db"
                              <> "e.g. surbgirq-shell --bible -c ./data/yaml/books.yaml -i ./data/yaml -o ./data/cypher"
                              )

  case cmd of
    Command{..} -> do
--             ch <- readChapter prmChapterFile
--             let res = (TL.toStrict . TLE.decodeUtf8 $ encode ch)
             case cmd'book of
               Bible -> do
                 TIO.putStrLn "Start genererating Bible scriptures for neo4j input..."
                 generateInitCypher cmd'config cmd'inPath cmd'outPath --  "./data/yaml" "./data/cypher"
                 generateRefCypher  cmd'config cmd'inPath cmd'outPath
                 TIO.putStrLn "Bible scriptures generation success!"
               Narek -> do
                 TIO.putStrLn "Narek scriptures generation not ready yet!"
                 -- wordFormsCypher "./data/txt/wordForms.txt" "./data/cypher/words"
                 wordFormsCSV "./data/txt/wordForms.txt" "./data/csv/words"


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


generateRefCypher :: FilePath -> FilePath -> FilePath -> IO ()
generateRefCypher bookFile path outPath = do
   books :: [Book] <- readYaml bookFile

   forM_ books $ \Book{..} -> do
     -- ref file fo the book
     let inRefFile = maybe "" (path </>) (T.unpack <$> book'inputRef)
         inPath = fromMaybe (T.toLower . T.pack $ show book'book ) book'input
         outCypherFileRoot = outPath </> (takeDirectory $ T.unpack inPath)
         bookLabel = maybe (show book'book) ((show book'book) ++)  (T.unpack <$> book'labels)

         -- ref file
         outRefFileRoot = outCypherFileRoot </> "refs"
         outRefFile = outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}-ref.cypher|]

         bookMatch = concat [show book'language, ":", show book'dialect, ":", bookLabel, ":", "Book" ]

     unless (null inRefFile) $ do
       refs :: [Ref] <- readYaml inRefFile
       bracket (openFile outRefFile WriteMode) hClose $ \refh -> do
         forM_  refs $ \(Ref from  rs) -> do
             let matchFrom = case from of
                               RefChapter n -> [qc|match (b:{bookMatch})-[:HAS_CH \{num: {n}}]->(from:Chapter) |]
                               RefSection n m -> [qc|match (b:{bookMatch})-[:HAS_CH \{num: {n}}]-()-[*]->(from:Section: \{num: {m}}) |]
             TIO.hPutStrLn refh matchFrom

             forM_  rs $ \ r -> do
               case r of
                 YouTube url author title desc ->   do
                                  TIO.hPutStrLn refh [qc|  merge (yt:YouTube \{url: '{url}', author: '{author}', title: '{title}', desc: '{desc}'})|]
                                  TIO.hPutStrLn refh [qc|  create (from)-[:YOUTUBE_REF \{author: '{author}'} ]->(yt)|]
                 ScriptureBible ref ->  TIO.hPutStrLn refh [qc|  merge (from)-[]->()|]
             TIO.hPutStrLn refh ";"


generateInitCypher :: FilePath -> FilePath -> FilePath -> IO ()
generateInitCypher bookFile path outPath = do
   let del = "_";

   books :: [Book] <- readYaml bookFile -- $ path </> "books.yaml"

   -- Booksx
   forM_ books $ \Book{..} -> do

     let inPath = fromMaybe (T.toLower . T.pack $ show book'book ) book'input
         bookDir = path </> (T.unpack inPath)

         -- cypher out file
         outCypherFileRoot = outPath </> (takeDirectory $ T.unpack inPath)
         outFile = outCypherFileRoot </> [qc|{T.toLower . T.pack $ show book'book}.cypher|]

         -- ref file
         outRefFileRoot = outCypherFileRoot </> "refs"
         outRefFile = outRefFileRoot </> [qc|{T.toLower . T.pack $ show book'book}.ref|]

         bookLabel = maybe (show book'book) ((show book'book) ++)  (T.unpack <$> book'labels)
         bookTestament = show book'testament
         bookName = T.toLower . T.pack  $ show book'book
         lang = show book'language
         dialect = show book'dialect



    -- TODO: process ref file for each book
         -- ref file fo the book
         kk = maybe "" (path </>) (T.unpack <$> book'inputRef)
         inRefFile =  kk

     unless (null kk) $ do
       refs :: [Ref] <- readYaml inRefFile
       forM_ refs $ \r -> print $ createRef r

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

         TIO.hPutStrLn outh "CREATE"
         TIO.hPutStrLn outh [qc| ({bookName}:{lang}:{dialect}:{bookLabel}:{bookTestament}:Book \{book: '{book'book}', title: '{book'title}', num: {book'number}, chapters: {book'chapters}, testament: '{book'testament}', translation: '{book'translation}' } ),
                             |]

         -- a file == a chapter
         forM_ (sort txtFiles) $ \file -> when (doesFilenameMatch file) $ do
           ch@Chapeter{..} <- readChapter (bookDir </> file)

           let chName = concat [T.unpack bookName, del, "ch", show chapter'number]
               chNode = [qc| ({chName}:Chapter \{title: 'Գլ. {chapter'number}', book: '{show book'book}', num: {chapter'number} }),|]
               chRel  = [qc| ({bookName})-[:HAS_CH \{num: {chapter'number}}]->({chName}),|]

           TIO.hPutStrLn outh chNode
           TIO.hPutStrLn outh chRel

           unless (T.null $ T.strip chapter'ref) $ do
               let chRefRel  = [qc| ({chName})-[:REF_TO]->({chapter'ref}),|]
               TIO.hPutStrLn outRefh chRefRel

           -- Sections
           forM_ chapter'sections $ \Section{..} -> do
             let secName = concat [chName, del, "sec", show section'number ]
                 secNode = [qc| ({secName}:Section \{title: '{section'title}', num: {section'number}}),|]
                 secRel  = [qc| ({chName})-[:HAS_SEC \{num: {section'number}} ]->({secName}),|]

             TIO.hPutStrLn outh secNode
             TIO.hPutStrLn outh secRel

             unless (T.null $ T.strip section'ref) $ do
                 let secRefRel  = [qc|  ({secName})-[:REF_TO]->({section'ref}),|]
                 TIO.hPutStrLn outRefh secRefRel

              -- Paragraphs
             forM_ section'paragraphs $ \Paragraph{..} -> do
               let prghName = concat [secName, del, "prgh", show paragraph'number]
                   prghNode = [qc|  ({prghName}:Paragraph \{num: {paragraph'number}}),|]
                   prghRel  = [qc|  ({secName})-[:HAS_PRGH \{num: {paragraph'number}} ]->({prghName}),|]

               TIO.hPutStrLn outh prghNode
               TIO.hPutStrLn outh prghRel

               -- Verses
               forM_ paragraph'verses $ \v@Verse{..} -> do
                 let verseName = concat [prghName , del, "verse", show verse'verse]
                     verseNode = [qc|  ({verseName}:Verse \{book: '{bookLabel}', content: '{verse'content}', num: {verse'verse}, section: {section'number}, section_title: '{section'title}', paragraph: {paragraph'number}, chapter: {chapter'number}  }),|]
                     verseRel  = [qc|  ({prghName})-[:HAS_VERSE \{num: {verse'verse}}]->({verseName}),|]
                 TIO.hPutStrLn outh verseNode
                 TIO.hPutStrLn outh verseRel


                 let ws = filter ((>0) . T.length) $ T.splitOn " " verse'content
                 -- add each word as node
                 forM_ (zip ws [1..] ) $ \(word, index) -> do
                   let wordName = concat [verseName, del, "word", show index]


                       wordNodeLabels = if isLower $ T.head word
                                        then concat [lang, ":", dialect, ":", "Word"]
                                        else concat [lang, ":", dialect, ":", "Capitalized", ":", "Word"]
                       wordNode = [qc|  ({wordName}:{wordNodeLabels} \{word: '{word}', index: {index}}),|]

                       wordRel  = if index == 1
                                  then [qc|  ({verseName})-[:FIRST_WORD]->({wordName}), ({verseName})-[:HAS_WORD \{num: {index}}]->({wordName}),|]
                                  else [qc|  ({verseName})-[:HAS_WORD \{num: {index}}]->({wordName}),|]

                       -- relArmat = [qc| (match (wf:WordForm \{word: '{word}'})<-[:HAS_WORDFORM]-(wh:WordHead)),
                       --                (Create ({wordName})-[:HAS_ARMAT]->(wh)), |]

                   TIO.hPutStrLn outh wordNode
                   TIO.hPutStrLn outh wordRel
                 -- TIO.hPutStrLn outh relArmat

                 -- add [NEEXT] relationshipp between words
                 forM_ (zip (zip ws (tail' ws)) [1..] ) $ \((w1, w2), index) -> do
                   let w1Name = concat [verseName, del, "word", show index]
                       w2Name = concat [verseName, del, "word", show $ index + 1]
                       nextRel = [qc|  ({w1Name})-[:NEXT]->({w2Name}),|]



                   TIO.hPutStrLn outh nextRel


                 -- verse ref processing
                 case verse'ref of
                   Nothing -> return ()
                   Just VerseRef{..} -> do
                     case verseRef'type of
                       RefText txt -> do
                         let wordN = concat [verseName, del, "word", show verseRef'index]
                             footnoteName = concat [wordN, del, "footnote", show verseRef'index]
                             footnoteNode = [qc|  ({footnoteName}:Footnote \{text: '{txt}', index: {verseRef'index}}),|]
                             footnoteRel  = [qc|  ({wordN})-[:REF_FOOTNOTE]->({footnoteName}),|]
                         TIO.hPutStrLn outh footnoteNode
                         TIO.hPutStrLn outh footnoteRel
                       _ -> return ()





  where
    tail' :: [a] -> [a]
    tail' []     = []
    tail' (x:xs) = xs
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".yaml", ".yml"]
    isDir :: FilePath -> Bool
    isDir path = takeExtension path == ""



createRef :: Ref -> TB.Builder
createRef (Ref from  rs) =
   let matchFrom = case from of
                 RefChapter n -> [qc|match (b:Grabar:Book) -[:HAS_CH \{num: {n}}]->(from:Chapter) |]
                 RefSection n m -> [qc|match (b:Book)-[:HAS_CH \{num: {n}}]-()-[*]->(from:Section: \{num: {m}}) |]

       xs = map (\r ->
            case r of
              YouTube url _ _ _        ->  [qc| merge (yt:YouTube \{url: {url}}|]  <> (TB.fromText $ T.pack $ show '\n') <> [qc| create (from) -[:YOUTUBE_REF]->(yt)|]
              ScriptureBible ref ->  [qc| {ref}|]
                ) rs
   in foldl (<>) matchFrom  xs



     -- data RefType = RefBooks   [Text]
     --         | RefChapter Int
     --         | RefSection Int Int
     --         | RefVerse   Text
     --         | RefWord    Text
     --         | RefText    Text
     --           deriving (Show, Read)
