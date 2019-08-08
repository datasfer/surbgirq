{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Scraper.Scalpel where

import           Control.Applicative
import           Data.List
import           Data.List.Split
import qualified Data.Text           as T
import qualified Data.Text.IO        as TIO
import           System.IO
import           Text.HTML.Scalpel


htmlData :: String
htmlData = "<section id='examples'>\
           \<h2 id='toc_marker-2-1' class='heading2'>ԱՒԵՏԱՐԱՆ ԸՍՏ ՄԱՏԹԷՈՍԻ </h2>\
           \<h3 class='heading3'>1</h3>\
           \<h4 class='heading4'>ՎԵՐՆԱԳԻՐ </h4>\
           \<p class='Body-Text'>verse 1-1</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-2'>1&nbsp;</span>verse 1-2</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-3'>1&nbsp;</span>verse 1-3</p>\
           \<h3 class='heading3'>1</h3>\
           \<h4 class='heading4'>ՎԵՐՆԱԳԻՐ </h4>\
           \<p class='Body-Text'><span class='Numeral' id='1-4'>1&nbsp;</span>verse 1-1</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-5'>1&nbsp;</span>verse 1-2</p>\
           \<p class='Body-Text'><span class='Numeral' id='1-6'>1&nbsp;</span>verse 1-3</p>\
     \</section>"


data Item
    = BookTitle String
    | Section Int String
    | VerseLine String
    deriving (Show, Eq)


allItems :: String -> IO (Maybe [Item])
allItems url = scrapeURL url items

items :: Scraper String [Item]
items = chroots ("section" @: ["id" @= "examples"]) item

item :: Scraper String Item
item = bookTitle

bookTitle :: Scraper String Item
bookTitle = do
  title <- text $ "h2" @: [hasClass "heading2"]
  return $ BookTitle title

sections :: Scraper String [(String, [[String]])]
sections = do
  chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text $ "h2" @: [hasClass "heading2"]
    num <- seekNext $ text $ "h3" @: [hasClass "heading3"]

    ss <- many $ do
         numq <- seekNext $ text $ "h3" @: [hasClass "heading3"]
         section <- seekNext $ text "h4"

         ps <- untilNext (matches "h4") (many $ seekNext parseVerse)
         return ps
    return (title, ss)

sections1 :: Scraper String [(String, [[String]])]
sections1 = do
  chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text $ "h2" @: [hasClass "heading2"]
    ss <- many $ do
         section <- seekNext $ text "h4"
         ps <- untilNext (matches "h4") (many $ seekNext parseVerse)
         return ps
    return (title, ss)


parseVerse :: Scraper String String
parseVerse = do
  let del = "\160"
  verse <- text "p"
  return $ intercalate " " $ splitOn del verse

allSections :: String -> IO (Maybe [(String, [[String]])])
allSections url = scrapeURL url (sections <|> sections1)



test1 :: String -> IO () -- Maybe [String])
test1 url = do
  hSetEncoding stdout utf8

  ts <- scrapeURL url parse
  case ts of
    Nothing   -> TIO.putStrLn "Գիրք ծննդեան"
    Just [xs] -> mapM_ (TIO.putStrLn) xs
    where
  parse = chroots ("section" @: ["id" @= "examples"]) $ do
            a <- chroots ("div" // "p") $ do
              contents <- text ("p" @: [hasClass "Parallel-References"])
              return $ T.pack contents
            b<- chroots ("div" // "h2") $ do
              contents <- text "h2"
              return $ T.pack contents
            return (a++b)

