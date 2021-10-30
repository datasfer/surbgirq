{-# LANGUAGE DeriveGeneric       #-}

{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE QuasiQuotes         #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}

module Surbgirq.Shell.CSV.Narek where

import           Control.Applicative
import           Control.Monad
import           Data.Aeson
import           Data.List.Split
import qualified Data.Text               as T
import qualified Data.Text.IO            as TIO
import qualified Data.Text.Lazy          as TL
import qualified Data.Text.Lazy.Builder  as TB
import           Data.Text.Lazy.Encoding as TLE
import           GHC.Generics
import           System.IO

data LineMessage = Title String String
              | Section String
              | Verse String (Maybe String)
              | Unknown String
  deriving (Generic, Show, Eq)

data NarekChapter = NarekChapter String [NarekSection]
  deriving (Generic, Show, Eq)

data NarekSection = NarekSection String [NarekVerse]
  deriving (Generic, Show, Eq)

data NarekVerse = NarekVerse String (Maybe String)
  deriving (Generic, Show, Eq)


instance ToJSON LineMessage
data MessageTree = Leaf
                 | Node MessageTree LineMessage MessageTree
  deriving (Show, Eq)

-- | @testParse p n f@ tests the log file parser @p@ by running it
--   on the first @n@ lines of file @f@.
testParse :: (String -> [LineMessage])
          -> Int
          -> FilePath
          -> IO [LineMessage]
testParse parse n file = take n . parse <$> readFile file

-- | @testWhatWentWrong p w f@ tests the log file parser @p@ and
--   warning message extractor @w@ by running them on the log file
--   @f@.
testWhatWentWrong :: (String -> [LineMessage])
                  -> ([LineMessage] -> [String])
                  -> FilePath
                  -> IO [String]
testWhatWentWrong parse whatWentWrong file
  = whatWentWrong . parse <$> readFile file


parse :: String -> [LineMessage]
parse = map parseMessage .  lines


parseMessage :: String
             -> LineMessage
parseMessage e =
    let xs =  splitOn "|" e
        ys = map (T.unpack . T.strip . T.pack) xs
    in case (filter (not . null) ys) of
         ["T",n,t] ->  Title n t
         ["N",n]   ->  Section n
         ["V",t]   ->  Verse t Nothing
         ["V",t,r] ->  Verse t (Just r)

test = do
  hSetEncoding stdout utf8
  xs <- take 15 . parse <$> readFile "../data/scriptures/narek/txt/001.txt"
  TIO.putStrLn (T.pack $ show xs)

  forM_  xs $ \b -> do
        let res = (TL.toStrict . TLE.decodeUtf8 $  encode b)
        TIO.putStrLn res -- $ T.pack $ show b

a = do
  xs <- parse <$> readFile "../data/scriptures/narek/txt/001.txt"
  let ys = siew xs
  TIO.putStrLn (T.pack $ show ys)
  -- let ys = process xs
  -- TIO.putStrLn (T.pack $ show ys)

 where
  process (Title a b:xs)            = NarekChapter a (processSection xs)
  processSection (Section a: xs)       = [NarekSection a (processVerse xs)]
  processVerse (s@(Verse  _ _):xs) = map (\(Verse a b) -> NarekVerse a b) $ takeWhile isVerse (s:xs)

  siew :: [LineMessage] -> [[LineMessage]]
  siew []                 = []
  siew (t@(Title a b):xs) = [t]:siew xs
  siew (s@(Section a):xs) = [s] : siew xs
  siew (v@(Verse a b):xs) = [v] : (takeWhile isVerse xs): siew (dropWhile isVerse xs)

  isSection (Section _) = True
  isSection _           = False
  isVerse (Verse _ _) = True
  isVerse _           = False

