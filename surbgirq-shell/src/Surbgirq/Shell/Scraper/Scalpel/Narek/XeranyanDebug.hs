{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Scraper.Scalpel.Narek.XeranyanDebug where


import Data.Text (Text)

import Control.Monad.Except          (MonadError, MonadIO, catchError, liftIO)
import Text.InterpolatedString.Perl6 (qc)

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

import           Data.Yaml
import           Text.RawString.QQ
import           Text.Regex.PCRE
import qualified Text.Regex.PCRE.Heavy as PCRE

import Common.Aeson

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

data BookData = BookData
 { book'title    :: Text
 , book'chapters :: [ChapterData]
 } deriving (Show, Generic)


data ChapterData = ChapterData
 { chapter'number   :: Text
 , chapter'sections :: [SectionData]
 } deriving(Show, Generic)

data SectionData = SectionData
 { title           :: Text
 , p_ref           :: Text
 , sections'verses :: [VerseData]
 } deriving(Show, Generic)

data VerseData = VerseData
 { verse'nums     :: [Text]
 , verse'refs     :: [Text]
 , verse'ref_word :: [(String, [String])]
 , verse'num      :: Text
 , verse'verse    :: Text
 } deriving(Show, Generic)


-- instance ToJSON VerseData
-- instance ToJSON SectionData
-- instance ToJSON ChapterData
-- instance ToJSON BookData

test :: IO ()
test = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  exampleHtml <- readFile "../data/scriptures/narek/txt/001.html"
  let ts = scrapeStringLike exampleHtml parseNarekHtml
  case ts of
    Just xs -> do
            encodeFile "../data/scriptures/narek/txt/gen-parseHtml.yaml" xs
            hFile <- openFile "../data/scriptures/narek/txt/scalpel.out" WriteMode
            forM_ xs (printBook hFile)
    Nothing -> error $ "failed parse html file "



parseNarekTest :: IO ()
parseNarekTest = parseNarekByXeranyanHtml "../data/html/narek/xeranyan" "../data/yaml"

-- | stack exec -- html-scraper --narek  --yaml  -i ./data/html/narek/xeranyan -o ./data/yaml
parseNarekByXeranyanHtml :: FilePath -> FilePath -> IO ()
parseNarekByXeranyanHtml dataRootPath  outPutPath = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  let datDir = dataRootPath
      outRootDir = outPutPath </> "narek/am"

  createDirectoryIfMissing True outRootDir

  txtFiles <- ((datDir </> ) <$>) <$> listDirectory datDir `catchError` \_ -> do
                                          liftIO $ putStrLn (concat [datDir, " does not exist."])
                                          return []


  forM_  (sort txtFiles)
          $ \file -> when (doesFilenameMatch file) $ do

    let lastFolderName = (last . splitPath $ takeDirectory file)
    htmlText <- readFile file
    print file
    -- print htmlText
    let ts = scrapeStringLike htmlText parseNarekHtml

    case ts of
      Just xs  -> do
              encodeFile "parseHtml.yaml" xs
      --        A.encodeFile "parseHtml.json" xs
              print $  length xs
              when (length xs > 0) $ do
                let outDir = outRootDir </> lastFolderName </> (takeBaseName file)
                createDirectoryIfMissing True outDir

                forM_ xs $ \book -> do
                  forM_ (book'chapters book) $ \ ch@ChapterData{..} -> do
                            let file = outDir </> [qc|{chapter'number}.yaml|]
                            print file
                            encodeFile file ch
                            -- A.encodeFile file ch

      Nothing -> error $ "failed parse html file "
  where
    doesFilenameMatch :: FilePath -> Bool
    doesFilenameMatch path = takeExtension path `elem` [ ".html", ".HTML"]


parseNarekHtml :: Scraper String [BookData]
parseNarekHtml = chroots ("div" @: [hasClass "content"]) $ inSerial innerScraper
  where
    innerScraper = do
       title <- seekNext $ T.pack <$> text "h2"
       chapters <- many $ do

         chapter <- seekNext $ T.pack <$> text "h3" -- <|> return "****************"
         sections <- untilNext (matches "h3")
                     (many $ do
            sectionTitle <- (seekNext $ T.pack <$> text "h4")
            p_ref <- (seekNext $ T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return "ref empty"

            ps <- untilNext (matches "h4")
                  (
                   many $ seekNext $ parseVerse1
                  )
            return $ SectionData sectionTitle p_ref $ concat ps )
         return $ ChapterData chapter  sections
       return $ BookData title chapters


parseVerse1 :: Scraper String [VerseData]
parseVerse1 = do
  let del = "\160"
      pTag = "p"  @: [hasClass "verse-text"]
--
  verse <- T.pack <$> innerHTML pTag
--  vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef
  num <- T.pack <$> (attr "verse-num" pTag)


  let vs = filter (not . T.null) $ PCRE.split rr_1 verse
      rs = PCRE.scan refRegex $ T.unpack verse

--  let xs = map (\(num, v) -> VerseData [] (versRefs) rs (T.pack $ show num) v $ T.pack verse)  (zip [4..] vs)
  let xs = map (\v -> VerseData [] (versRefs) rs num v)  vs
  return xs
  where
    parseVerseNum :: Scraper String Text
    parseVerseNum = do
           txt <- T.pack <$> (attr "id" $ "span")
           return txt
    parseVerseRef :: Scraper String Text
    parseVerseRef = do
           txt <- T.pack <$> text "a"
           return txt


refRegex = [PCRE.re|(?:\S+\s)?\S*<\s*a[^>]*>(.*?)<\s*/\s*a>|]
rr_1 = [PCRE.re|<\s*span[^>]*>(.*?)<\s*/\s*span>|]


printBook hFile BookData{..} = do
   TIO.putStrLn (T.append "    " book'title)
   TIO.hPutStrLn hFile (T.append "    " book'title)
   forM_ book'chapters $ printChapter hFile

printChapter hFile  ChapterData{..} = do
           TIO.putStrLn (T.append "    " chapter'number)
           TIO.hPutStrLn hFile (T.append "    " chapter'number)
           forM_ chapter'sections $ printSection hFile


printSection hFile SectionData{..} = do
    (TIO.putStrLn . T.append "      ")  title
    (TIO.putStrLn . T.append "      ")  p_ref
    (TIO.hPutStrLn hFile . T.append "      ")  title
    (TIO.hPutStrLn hFile . T.append "      ")  p_ref
    forM_ sections'verses $ printVerse hFile

printVerse hFile VerseData{..} = do
--  TIO.putStrLn "{#}"
  let line =  [qc|{verse'num}. {verse'verse}|]

  TIO.hPutStrLn hFile line
  TIO.putStrLn line


printVerse' VerseData{..} = do
--  TIO.putStrLn " -- - dadatam"
--  let del = [qc|<\span>|]
--  TIO.putStrLn $T.pack . show $ verse'nums
--  TIO.putStrLn $T.pack . show $ verse'refs
  let vs = filter (not . T.null ) $ PCRE.split rr_1  verse'verse
--      rs = filter (not . T.null  ) $ PCRE.scan refRegex  verse
--      rs = PCRE.scan refRegex  verse
  mapM (\(link, [z]) -> do

          let kv = [qc|{T.pack z} -> {T.pack link}|] :: Text
          TIO.putStrLn kv -- $ T.pack link
--          TIO.putStrLn $ T.pack z
       ) verse'ref_word

  TIO.putStrLn $ [qc|{verse'num}. {verse'verse}|]

--   forM_ (zip verse'nums vs) $ \(num, v) -> do
-- --      TIO.putStrLn "-->"
--       TIO.putStrLn $ [qc|{num}. {v}|]

delS :: Text
delS = [qc|</span>|]


$(deriveJSON dropPrefixOptions ''VerseData)
$(deriveJSON dropPrefixOptions ''ChapterData)
$(deriveJSON dropPrefixOptions ''SectionData)
$(deriveJSON dropPrefixOptions ''BookData)
