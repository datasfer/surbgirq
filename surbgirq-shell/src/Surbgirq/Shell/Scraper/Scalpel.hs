{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Shell.Scraper.Scalpel where

import Data.Text(Text)

import           Control.Applicative
import           Data.List
import           Data.List.Split
import qualified Data.Text           as T
import qualified Data.Text.Encoding  as TE
import qualified Data.Text.IO        as TIO
import           System.IO
import           Text.HTML.Scalpel


htmlData :: String
htmlData = "<section id='examples'>\
           \<h2 id='toc_marker-2-1' class='heading2'>Title1 </h2>\
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
    | SectionTitle String
    | SectionNum String
    | VerseLine String
    deriving (Show, Eq)


allItems :: String -> IO (Maybe [Item])
allItems url = scrapeURL url items

items :: Scraper String [Item]
items = chroots ("section" @: ["id" @= "examples"]) item

item :: Scraper String Item
item = bookTitle <|> chNum <|> secTitle <|> verse1 -- (VerseLine <$> parseVerse)

bookTitle :: Scraper String Item
bookTitle = do
  title <- text $ "h2" @: [hasClass "heading2"]
  return $ BookTitle title

chNum :: Scraper String Item
chNum = do
  num <- text $ "h3" @: [hasClass "heading3"]
  return $ SectionNum num

secTitle :: Scraper String Item
secTitle = do
  title <- text $ "h4" @: [hasClass "heading4"]
  return $ SectionTitle title

verse1 :: Scraper String Item
verse1 = do
  title <- text $ "p"
  return $ VerseLine title

sections :: Scraper String [(Text, [(Text, [Text])])]
sections = do
  chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text $ "h2" @: [hasClass "heading2"]
    num <- seekNext $ text $ "h3" @: [hasClass "heading3"]

    ss <- many $ do
         section <- seekNext $ text "h4"

         ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$>  parseVerse)
         return (T.pack (section ++ num), ps)
    return (T.pack (title ++ num), ss)

sections1 :: Scraper String [(Text, [(Text, [Text])])]
sections1 = do
  chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text $ "h2" @: [hasClass "heading2"]
    ss <- many $ do
         section <- seekNext $ text "h4"
         ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$>  parseVerse)
         return (T.pack section, ps)
    return (T.pack title, ss)


parseVerse :: Scraper String String
parseVerse = do
  let del = "\160"
  verse <- text "p"
  return $ (++ "\n") <$> intercalate " " $ splitOn del verse

-- allSections :: String -> IO (Maybe [(T.Text, [[T.Text]])])
allSections url = scrapeURL url (sections <|> sections1)



test1 :: String -> IO (Maybe [[T.Text]])
test1 url = scrapeURL url parse11

data Res = Res T.Text T.Text deriving Show
            
parse11 = chroots ("section" @: ["id" @= "examples"]) $ do
            a <- chroots ("div" // "p") $ do
              contents <- text ("p" @: [hasClass "Parallel-References"])
              return $ T.pack contents
            b<- chroots ("div" // "h4") $ do
              contents <- text ("h4" @: [hasClass "heading4"])
              return $ T.pack contents
            return (a++b)

parseSerial :: Scraper String [(Text, [(Text, [Text])])]
parseSerial = chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text "h2"
    secNum <- seekNext $ text "h3"
    sections <- many $ do
       section <- seekNext $ text "h4"
       num <- seekNext $ text "h3"
       -- num <- (stepNext $ text "h3" <|> return "****************")
       ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$> parseVerse)
       return (T.pack (section ++ num), ps)
    return (T.pack (title ++ secNum), sections)

parseSerial1 :: Scraper String [(Text, [(Text, [Text])])]
parseSerial1 = chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text "h2"
    sections <- many $ do
       section <- seekNext $ text "h4"
       ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$> parseVerse)
       return (T.pack (section), ps)
    return (T.pack (title), sections)


parseSerialHeadings :: Scraper String [(Text, [(Text, [Text])])]
parseSerialHeadings = chroots ("section" @: ["id" @= "examples"]) $ inSerial $ do
    title <- seekNext $ text "h2"
    secNum <- seekNext $ text "h3"
    sections <- many $ do
       section <- seekNext $ text "h4"
       num <- seekNext $ text "h3"
       -- num <- (stepNext $ text "h3" <|> return "****************")
       ps <- untilNext (matches "h4") (many $ seekNext $ T.pack <$> parseVerse)
       return (T.pack (section ++ num), ps)
    return (T.pack (title ++ secNum), sections)




