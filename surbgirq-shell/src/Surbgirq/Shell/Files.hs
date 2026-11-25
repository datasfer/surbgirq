-- | UTF-8 and LF line endings for the files the pipeline programs read and write, whatever the machine's locale and
-- platform. Without them, a run under @LANG=C@ (ASCII) stops at the first Armenian letter, and a run on Windows writes
-- CRLF and reads no line of the word list.
module Surbgirq.Shell.Files
    ( useUtf8
    , openOutFile
    , openInFile
    ) where

import GHC.IO.Encoding (setLocaleEncoding, utf8)
import System.IO       (Handle, IOMode (..), hSetEncoding, hSetNewlineMode, noNewlineTranslation, openFile, stderr,
                        stdout)

-- | The first line of every program: every file opened after it, and the standard output and error, use UTF-8.
useUtf8 :: IO ()
useUtf8 = do
    setLocaleEncoding utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

-- | A file opened for writing, in UTF-8, with LF line endings on every platform.
openOutFile :: FilePath -> IO Handle
openOutFile = openUtf8 WriteMode

-- | A file opened for reading, in UTF-8, with its line endings as they are (Windows' text mode would turn CRLF into
-- LF).
openInFile :: FilePath -> IO Handle
openInFile = openUtf8 ReadMode

openUtf8 :: IOMode -> FilePath -> IO Handle
openUtf8 mode path = do
    h <- openFile path mode
    hSetEncoding h utf8
    hSetNewlineMode h noNewlineTranslation
    return h
