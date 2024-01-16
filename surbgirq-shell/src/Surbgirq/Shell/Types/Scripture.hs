{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Shell.Types.Scripture (
   Corpora(..)
 , Scripture(..)
 , Book(..)
 , Chapter (..)
 , Section(..)
 , Verse(..)
 , Testament (..)
 , BookRef(..)
 , VerseRef(..)
 , RefType(..)
 , RefTo(..)
 , Ref(..)
 ) where

import Data.Aeson (Value)
import Data.Text  (Text)

import Common.Aeson

import Surbgirq.Shell.Store.ParseFile
import Surbgirq.Types.Girq
import Surbgirq.Types.Scripture
-------------------------------------------------------------------------------
--




data Corpora = Corpora
     { corpora'scripturesPath   :: [FilePath]
     , corpora'translationsPath :: [FilePath]
     -- , corpora'bibleDivisionsPath :: FilePath
     -- , corpora'testamentsPath     :: FilePath
     , corpora'grabar60kPath    :: FilePath
     } deriving (Show, Read)

data Scripture = Scripture
     { scripture'books         :: [Book]
     , scripture'Info          :: Text
     , scripture'ID            :: Text
     , scripture'dataFolder    :: Text
     , scripture'translationID :: Text
     } deriving (Show, Read)


-- |
data Book = Book
  { book'book      :: Girq
  , book'labels    :: Maybe Text
  -- ^ neo4j node labels
  , book'shortName :: Text
  , book'microName :: Text
  , book'title     :: Text
  , book'orderNum  :: Int
  , book'chapters  :: Int
  , book'testament :: Testament
  , book'language  :: Language
  , book'dialect   :: Dialect
  , book'ref       :: Maybe Text
  , book'input     :: Maybe Text
--                             , scripture'Year   :: Int
 --    , scripture'Author :: Text

    -- ^ the path to text files to process, if nothing then take the path = toLower  $ show book'book
  , book'inputRef  :: Maybe Text
  -- ^ the ref file
  , book'output    :: Maybe Text
  -- ^ the path to store processed result
  } deriving (Show, Read)

data Chapter = Chapter
    { chapter'number   :: Int
    , chapter'title    :: Text
    , chapter'ref      :: Text
    , chapter'sections :: [Section]
    } deriving (Show)


data Section = Section
    { section'title  :: Text
    , section'number :: Int
    , section'ref    :: Text
    , section'verses :: [Verse]
    } deriving (Show)


data Verse = Verse
  { verse'verse   :: Int
  , verse'content :: Text
  , verse'ref     :: [VerseRef]
  } deriving (Show)


-- word
data Ban = Ban
    { ban'index :: Int
    , ban'word  :: Text
    , ban'ref   :: VerseRef
    } deriving (Show)

data VerseRef = VerseRef
    { verseRef'index :: Int
    , verseRef'type  :: RefType
    } deriving (Show, Read)


data BookRef =  BookRef {  bookRef'ref  :: [Ref] }
                deriving (Show, Read)


data Ref = Ref
    { ref'From :: RefType
    , ref'To   :: [RefTo]
    } deriving (Show, Read)

type YtUrl         = Text
type YtAuthor      = Text
type YtTitle       = Text
type YtDesc        = Text

data RefTo = YouTube YtUrl YtAuthor YtTitle YtDesc
           | ScriptureBible Text
           | ScriptureMeknutyun Text
             deriving (Show, Read)



data RefType = RefBooks   [Text]
             | RefChapter Int
             | RefSection Int Int
             | RefVerse Text
             | RefVerseEnd Text Text
               -- ^ do not connected to special word, ref number of original and text
             | RefWord    Text
             | RefText    Text
             | RefFootnote Text Text
               deriving (Show, Read)


$(deriveJSON dropPrefixOptions ''Corpora)
$(deriveJSON dropPrefixOptions ''Girq)
$(deriveJSON dropPrefixOptions ''Book)
$(deriveJSON dropPrefixOptions ''RefTo)
$(deriveJSON dropPrefixOptions ''RefType)
$(deriveJSON dropPrefixOptions ''Ref)
$(deriveJSON dropPrefixOptions ''VerseRef)
$(deriveJSON dropPrefixOptions ''Verse)
$(deriveJSON dropPrefixOptions ''Scripture)
$(deriveJSON dropPrefixOptions ''Section)
$(deriveJSON dropPrefixOptions ''Chapter)
$(deriveJSON dropPrefixOptions ''BookRef)
$(deriveJSON dropPrefixOptions ''Ban)




