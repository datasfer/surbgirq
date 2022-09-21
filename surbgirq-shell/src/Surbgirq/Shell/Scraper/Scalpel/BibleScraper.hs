{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Scraper.Scalpel.BibleScraper
    (parseE1994BibleHtml)
    where

import Data.Maybe (fromMaybe)
import Data.Text  (Text)
import Text.Read  (readMaybe)

import Text.InterpolatedString.Perl6 (qc)


import Control.Monad.Except (MonadError, MonadIO, catchError, liftIO)
import Prelude              hiding (catch)
import System.IO.Error      hiding (catch)

import System.FilePath

import           Control.Applicative
import           Control.Monad
import           Control.Monad.IO.Class
import           Data.List
import           Data.List.Split
import qualified Data.Text              as T
import qualified Data.Text.Encoding     as TE
import qualified Data.Text.IO           as TIO
import           GHC.Generics
import           GHC.IO.Encoding
import           System.Directory
import           System.FilePath
import           System.IO
import           Text.HTML.Scalpel

import qualified Data.Aeson            as A
import           Data.Yaml
import           Surbgirq.Shell.Types
import           Text.RawString.QQ
import           Text.Regex.PCRE
import qualified Text.Regex.PCRE.Heavy as PCRE

import Surbgirq.Shell.Txt.PlainText

data Book' = Book'
 { b'title     :: Text
 , b'chapters  :: [Chapter]
 , b'footnotes :: [FootnoteData]
 } deriving (Show, Generic)

data FootnoteData = FootnoteData Text Text
                  deriving (Show, Generic)


instance ToJSON Book'
instance ToJSON FootnoteData

data OutFormat =  YAML
                | JSON
                | TEXT
                  deriving(Eq)
test :: IO ()
test = do
    setLocaleEncoding utf8
    hSetEncoding stdout utf8
    let file = "./data/e1994/html/New/01.Matthew.html"
        outDir = takeBaseName file

    htmlText <- readFile file

    let ts = scrapeStringLike htmlText parseBibleHtml
        gs = scrapeStringLike htmlText parseFootnotes

    case (ts, gs) of
      (Just xs, Just fs )  -> do
              case xs of
                [b] -> do
                        let chapters = b'chapters b
                        encodeChaptersToFile [qc|{outDir}.txt|] (b'title b) chapters

                        forM_ chapters $ \ ch@Chapter{..} -> do
                                encodeFile "matt-parseHtml_chapter.yaml" ch
                                A.encodeFile "matt-parseHtml_chapter.json" ch
                                print chapter'number
              encodeFile "matt-parseHtml_all.yaml" xs
              A.encodeFile "matt-parseHtml_all.json" xs
      (_, _) -> error $ "failed parse html file "


parseBibleTest :: IO ()
parseBibleTest = parseE1994BibleHtml' YAML "bible/am/e1994" "./data/e1994/html" "./data/yaml"

texte1994 :: IO ()
texte1994 =      parseE1994BibleHtml' TEXT "e1994" "./data/raw_html/e1994" "./data"

-- | stack exec -- html-scraper --e1994  --yaml  -i ./data/html/e1994 -o ./data/yaml
parseE1994BibleHtml :: FilePath -> FilePath -> FilePath -> IO ()
parseE1994BibleHtml  = parseE1994BibleHtml' YAML



parseE1994BibleHtml' :: OutFormat -> FilePath -> FilePath -> FilePath -> IO ()
parseE1994BibleHtml' format outputSubPath dataRootPath  outPutPath  = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8

  let -- outputSubPath = "bible/am/e1994"
      datDir = dataRootPath </> "New"
      datDirOld = dataRootPath </> "Old"
      outRootDir = outPutPath </> outputSubPath
      outTxtRootDir = outRootDir </> "text"

  createDirectoryIfMissing True outRootDir
  createDirectoryIfMissing True outTxtRootDir
  createDirectoryIfMissing True (outTxtRootDir </> "New" )
  createDirectoryIfMissing True (outTxtRootDir </> "Old" )

  txtFiles <- ((datDir </> ) <$>) <$> listDirectory datDir `catchError` \_ -> do
                                          liftIO $ putStrLn (concat [datDir, " does not exist."])
                                          return []

  txtFilesOld <- ((datDirOld </> ) <$>) <$> listDirectory datDirOld `catchError` \_ -> do
                                            liftIO $ putStrLn (concat [datDirOld, " does not exist."])
                                            return []

  forM_  (sort (txtFiles ++ txtFilesOld) )
          $ \file -> when (doesFilenameMatch file) $ do

    let lastFolderName = (last . splitPath $ takeDirectory file)
    htmlText <- readFile file
    print file
    let ts = scrapeStringLike htmlText parseBibleHtml
        gs = scrapeStringLike htmlText parseFootnotes

    case (ts, gs) of
      (Just xs, Just fs )  -> do
              encodeFile "parseHtml.yaml" xs
              A.encodeFile "parseHtml.json" xs
              print $  length xs
              print $  length fs
              when (length xs > 0) $ do
                let outDir = outRootDir </> lastFolderName </> (takeBaseName file)
                let outTxtDir = outTxtRootDir </> lastFolderName </> (takeBaseName file)

                when (format /= TEXT) $ do
                    createDirectoryIfMissing True outDir

                forM_ xs $ \book -> do
                  let chapters = b'chapters book
                  if format == TEXT
                  then do
                    encodeChaptersToFile [qc|{outTxtDir}.txt|] (b'title book) chapters
                  else  do
                    forM_ chapters $ \ ch@Chapter{..} -> do
                            let file = outDir </> if chapter'number < 10
                                                  then [qc|0{chapter'number}|]
                                                  else [qc|{chapter'number}|]
                            print file
                            case format of
                              YAML -> encodeFile [qc|{file}.yaml|] ch
                              JSON -> A.encodeFile  [qc|{file}.JSON|] ch

      (_, _) -> error $ "failed parse html file "
  where
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".html", ".HTML"]

-- <a id="footnote-265-903-backlink" class="footnote-link" href="#footnote-265-903">(903)</a>
parseVerse :: [FootnoteData] -> Scraper String [Verse]
parseVerse fs = do
  rawVerseHtml <- innerHTML $ "p"  @: [hasClass "Body-Text"]
  vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef

  let vs = filter (not . T.null) $ PCRE.split rr_1 $ T.strip $ T.pack rawVerseHtml
      rs :: [(String, [String])]
      rs = PCRE.scan refRegex rawVerseHtml

      verseRefs = map (\(index, rData) -> toVerseRef index rData) (zip [1..] rs)
      xs = map (\(n, verse) ->
                    let num = fromMaybe 0 $ ((readMaybe  $ T.unpack n) :: Maybe Int)
                        vR = filter (prRefBelongs verse) verseRefs
                        v = case vR of
                              [] -> T.strip verse
                              _  -> removeLinkTag verse
                    in Verse num (T.strip v) vR)
               (zip vNums vs)
  return xs
  where
    removeLinkTag str =
        T.intercalate "" $ PCRE.split linkRegex str

    toVerseRef :: Int -> (String,[String]) -> VerseRef
    toVerseRef i (footnote, [key]) = VerseRef i (RefFootnote (T.strip $ T.pack key) (removeLinkTag $ T.strip $ T.pack footnote) )

    -- predicate reference belongs to verse
    prRefBelongs :: Text -> VerseRef -> Bool
    prRefBelongs verse VerseRef{..} =
        case verseRef'type of
          -- check if footnote belongs to the verse
          RefFootnote key _ -> T.isInfixOf key verse
          _                 -> False

    parseVerseNum :: Scraper String Text
    parseVerseNum = do
           txt <- T.strip . T.pack <$> text "span" --  (attr "id" $ "span")
           return txt
    parseVerseRef :: Scraper String Text
    parseVerseRef = do
           txt <- T.strip . T.pack <$> text "a"
           return txt

parseBibleHtml :: Scraper String [Book']
parseBibleHtml = do
        footnotes <- chroots ("div" @:  [hasClass "footnote"]) $ parseFootnote

        book <- chroots ("div" @: [hasClass "content"]) $ inSerial (innerScraper footnotes)
        case book of
          [b@(Book'{b'footnotes = a})] -> return [b{b'footnotes = footnotes}]
          _                            -> return []
  where
    parseFootnote :: Scraper String FootnoteData
    parseFootnote = do
           txt <- T.strip . T.pack <$> text "p"
           num <- T.strip . T.pack <$> text ("p" // "a"  )
           return $ FootnoteData num txt

    innerScraper :: [FootnoteData] -> SerialScraper String Book'
    innerScraper fs = do
       title <- seekNext $ T.strip . T.pack <$> text "h2"
       chapters <- many $ do

         chapter <- seekNext $ T.strip . T.pack <$> text "h3" --  <|> return "999"
         let chNum = fromMaybe 0 $ ((readMaybe  $ T.unpack chapter) :: Maybe Int)

         sections <- untilNext (matches "h3") $
                     many $ do
            sectionTitle <- (seekNext $ T.strip . T.pack <$> text "h4")
           --  p_ref <- (seekNext $ T.strip . T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return T.empty
            p_ref <- (stepNext $ T.strip . T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return T.empty
            ps <- untilNext (matches "h4") $ many $ seekNext $ parseVerse fs
            return $ Section sectionTitle 111 p_ref $ concat ps
         let secs = zipWith (\n s@(Section{section'number = m}) -> s{section'number = n}) [1..] sections
         return $ Chapter chNum "" "" secs
       return $ Book' title   chapters []




-- printBook hFile BookData{..} = do
--    TIO.putStrLn (T.append "    " book'title)
--    TIO.hPutStrLn hFile (T.append "    " book'title)
--    forM_ book'chapters $ printChapter hFile

-- printChapter hFile  ChapterData{..} = do
--            TIO.putStrLn (T.append "    " chapterNum)
--            TIO.hPutStrLn hFile (T.append "    " chapterNum)
--            forM_ chapter'sections $ printSection hFile

-- printSection hFile SectionData{..} = do
--     (TIO.putStrLn . T.append "      ")  title
--     (TIO.putStrLn . T.append "      ")  p_ref
--     (TIO.hPutStrLn hFile . T.append "      ")  title
--     (TIO.hPutStrLn hFile . T.append "      ")  p_ref
-- --    forM_ verses $ printVerse'

-- printVerse hFile VerseData{..} = do
--   TIO.putStrLn "{#}"
--   TIO.hPutStrLn hFile verse'verse
--   TIO.putStrLn verse'verse


-- printVerse' VerseData{..} = do
--   TIO.putStrLn " -- - dadatam"
-- --  let del = "\160"
--   let del = [qc|<\span>|]
-- --  forM_ (T.splitOn del $  verse) $ \v -> TIO.putStrLn $ v
--   TIO.putStrLn $T.pack . show $  verse'num
-- --  TIO.putStrLn $T.pack . show $  verse'refs
--   let vs = filter (not . T.null  ) $ PCRE.split rr_1  verse
-- --      rs = filter (not . T.null  ) $ PCRE.scan refRegex  verse
--       rs = PCRE.scan refRegex  verse
--   mapM (\(link, [z]) -> do
--           TIO.putStrLn link
--           TIO.putStrLn z
--        )   rs

--   forM_ (zip verse'nums vs) $ \(num, v) -> do
-- --      TIO.putStrLn "-->"
--       TIO.putStrLn $ [qc|{num}. {v}|]

delS :: Text
delS = [qc|</span>|]



rr_1 = [PCRE.re|<\s*span[^>]*>(.*?)<\s*/\s*span>|]


-- ref link with the worde before that
refRegex = [PCRE.re|(?:\S+\s)?\S*<\s*a[^>]*>(.*?)<\s*/\s*a>|]

linkRegex = [PCRE.re|<\s*a[^>]*>(.*?)<\s*/\s*a>|]


-- | Footnotes
parseFootnotes :: Scraper String [FootnoteData]
parseFootnotes = do
    chroots ("div" @:  [hasClass "footnote"]) $ parseFootnote
  where
    parseFootnote :: Scraper String FootnoteData
    parseFootnote = do
           txt <- T.strip . T.pack <$> text "p"
           num <- T.strip . T.pack <$> text ("p" // "a"  )
           return $ FootnoteData num txt

parseFootNoteTest :: IO ()
parseFootNoteTest = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  exampleHtml <- readFile "./data/html/1994/matthew.html"
  let ts = scrapeStringLike exampleHtml parseFootnotes
  case ts of
    Just xs -> do
            hFile <- openFile "footnotes.out" WriteMode
            forM_ xs printFootnote
    Nothing -> error $ "failed parse html file "
 where
   printFootnote (FootnoteData a b) = do
                      TIO.putStrLn (T.append "    " a)
                      TIO.putStrLn (T.append "    " b)
