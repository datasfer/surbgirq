{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Scraper.Scalpel.Narek.XeranyanScraper where


import Data.Text (Text)

import Control.Monad.Except          (MonadError, MonadIO, catchError, liftIO)
import Data.Maybe                    (fromMaybe)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

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
import Surbgirq.Shell.Types
import Surbgirq.Utils
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

data BookData = BookData
 { bookData'title    :: Text
 , bookData'chapters :: [Chapter]
 } deriving (Show, Generic)

instance ToJSON BookData

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
            return ()
--            forM_ xs (printBook hFile)
    Nothing -> error $ "failed parse html file "


-- | parse all books inside narek
parseNarekTest :: IO ()
parseNarekTest = parseNarekByXeranyanHtml "./data/raw_html/narek/" "./data/yaml"




-- | stack exec -- html-scraper --narek  --yaml  -i ./data/html/narek/xeranyan -o ./data/yaml
parseNarekByXeranyanHtml :: FilePath -> FilePath -> IO ()
parseNarekByXeranyanHtml dataRootPath  outPutPath = do
  setLocaleEncoding utf8
  hSetEncoding stdout utf8
  let datDir = dataRootPath
      outRootDir =  outPutPath </> "narek/am"

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
                let outDir = outRootDir </> (takeBaseName file)
                createDirectoryIfMissing True outDir

                forM_ xs $ \book -> do
                  forM_ (bookData'chapters book) $ \ ch@Chapter{..} -> do
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

         chapter <- seekNext $ text "h3" -- <|> return "****************"
         let chNum = fromArmenianNumber chapter -- fromMaybe 0 $ ((readMaybe  $ T.unpack chapter) :: Maybe Int)

         sections <- untilNext (matches "h3") $
                     many $ do
            sectionTitle <- (seekNext $ T.pack <$> text "h4")
            let secNum = fromArmenianNumber $ T.unpack sectionTitle
            p_ref <- (seekNext $ T.pack <$> text ("p" @: [hasClass "Parallel-References"]))  <|> return "ref empty"

            ps <- untilNext (matches "h4") $ many $ seekNext $ parseVerse1

            return $ Section sectionTitle secNum p_ref $ concat ps
         -- let secs = zipWith (\n s@(Section{section'number = m}) -> s{section'number = secNum}) [1..] sections
         return $ Chapter chNum "" "" sections
       return $ BookData title chapters




parseVerse1 :: Scraper String [Verse]
parseVerse1 = do
  let del = "\160"
      pTag = "p"  @: [hasClass "verse-text"]
--
  verse <- T.pack <$> innerHTML pTag
--  vNums <- chroots ("p" // "span" @:  [hasClass "Numeral"]) $ parseVerseNum
  versRefs <- chroots ("p" // "a" @:  [hasClass "footnote-link"]) $ parseVerseRef
  numTxt <- (attr "verse-num" pTag)
  let num = fromMaybe 0 $ ((readMaybe  numTxt) :: Maybe Int)


  let vs = filter (not . T.null) $ PCRE.split rr_1 verse
      rs = PCRE.scan refRegex $ T.unpack verse

--  let xs = map (\(num, v) -> VerseData [] (versRefs) rs (T.pack $ show num) v $ T.pack verse)  (zip [4..] vs)
  let xs = map (\v -> Verse num v [])  vs
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


-- printBook hFile BookData{..} = do
--    TIO.putStrLn (T.append "    " book'title)
--    TIO.hPutStrLn hFile (T.append "    " book'title)
--    forM_ book'chapters $ printChapter hFile

-- printChapter hFile  ChapterData{..} = do
--            TIO.putStrLn (T.append "    " chapter'number)
--            TIO.hPutStrLn hFile (T.append "    " chapter'number)
--            forM_ chapter'sections $ printSection hFile


-- printSection hFile SectionData{..} = do
--     (TIO.putStrLn . T.append "      ")  title
--     (TIO.putStrLn . T.append "      ")  p_ref
--     (TIO.hPutStrLn hFile . T.append "      ")  title
--     (TIO.hPutStrLn hFile . T.append "      ")  p_ref
--     forM_ sections'verses $ printVerse hFile

-- printVerse hFile VerseData{..} = do
-- --  TIO.putStrLn "{#}"
--   let line =  [qc|{verse'num}. {verse'verse}|]

--   TIO.hPutStrLn hFile line
--   TIO.putStrLn line


-- printVerse' VerseData{..} = do
-- --  TIO.putStrLn " -- - dadatam"
-- --  let del = [qc|<\span>|]
-- --  TIO.putStrLn $T.pack . show $ verse'nums
-- --  TIO.putStrLn $T.pack . show $ verse'refs
--   let vs = filter (not . T.null ) $ PCRE.split rr_1  verse'verse
-- --      rs = filter (not . T.null  ) $ PCRE.scan refRegex  verse
-- --      rs = PCRE.scan refRegex  verse
--   mapM (\(link, [z]) -> do

--           let kv = [qc|{T.pack z} -> {T.pack link}|] :: Text
--           TIO.putStrLn kv -- $ T.pack link
-- --          TIO.putStrLn $ T.pack z
--        ) verse'ref_word

--   TIO.putStrLn $ [qc|{verse'num}. {verse'verse}|]

-- --   forM_ (zip verse'nums vs) $ \(num, v) -> do
-- -- --      TIO.putStrLn "-->"
-- --       TIO.putStrLn $ [qc|{num}. {v}|]

-- delS :: Text
-- delS = [qc|</span>|]


-- $(deriveJSON dropPrefixOptions ''VerseData)
-- $(deriveJSON dropPrefixOptions ''ChapterData)
-- $(deriveJSON dropPrefixOptions ''SectionData)



-- this commented becuase of bump to ghc: 9.4.8, seems the order of instancing is matter, added 
-- tojson instance declaration above
-- $(deriveJSON dropPrefixOptions ''BookData)