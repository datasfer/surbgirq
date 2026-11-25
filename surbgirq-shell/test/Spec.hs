{-# LANGUAGE OverloadedStrings #-}
-- | The tag matcher that replaced the scrapers' PCRE patterns ('Surbgirq.Shell.Scraper.Tags'). Each expected value is
-- what the old pattern gives on that text, as Python's re computed it (it reads these four patterns as PCRE does).
module Main (main) where

import Test.Hspec

import Surbgirq.Shell.Scraper.Tags (linksWithWordBefore, removeElements, splitAtElements)

main :: IO ()
main = hspec $ do

  describe "splitAtElements" $ do
    it "gives a text with no element back whole" $
      splitAtElements "span" "plain text" `shouldBe` ["plain text"]
    it "cuts out an element in the middle" $
      splitAtElements "span" "a<span>1</span>b" `shouldBe` ["a", "b"]
    it "keeps the empty pieces at both ends" $
      splitAtElements "span" "<span>1</span>a<span>2</span>" `shouldBe` ["", "a", ""]
    it "gives an empty piece between two elements that touch" $
      splitAtElements "span" "<span>1</span><span>2</span>x" `shouldBe` ["", "", "x"]
    it "takes attributes, and spaces around the name and the slash" $
      splitAtElements "span" "< span class=\"Numeral\" id='v2'>2\160< / span>text" `shouldBe` ["", "text"]
    it "needs the > right after the name in a closing tag" $
      splitAtElements "span" "a<span>1</span >b" `shouldBe` ["a<span>1</span >b"]
    it "takes a carriage return inside an element" $
      splitAtElements "span" "a<span>1\r</span>b" `shouldBe` ["a", "b"]
    it "takes a line feed inside the opening tag" $
      splitAtElements "span" "<span\nclass=\"n\">1</span>y" `shouldBe` ["", "y"]
    it "finds no element when a line feed comes before the closing tag" $
      splitAtElements "span" "a<span>1\n</span>b" `shouldBe` ["a<span>1\n</span>b"]
    it "ends an element at the first closing tag: elements do not nest" $
      splitAtElements "span" "<span>a<span>b</span>c</span>d" `shouldBe` ["", "c</span>d"]
    it "goes on searching after an element" $
      splitAtElements "span" "<span>1</span>2</span><span>3</span>" `shouldBe` ["", "2</span>", ""]
    it "matches the name with its case" $
      splitAtElements "span" "<SPAN>1</SPAN>x<span>2</SPAN>" `shouldBe` ["<SPAN>1</SPAN>x<span>2</SPAN>"]
    it "opens an element at a longer name that starts with the name" $
      splitAtElements "span" "<spanx>1</span>z" `shouldBe` ["", "z"]
    it "needs the exact name in the closing tag" $
      splitAtElements "span" "a<span>1</spanx>b" `shouldBe` ["a<span>1</spanx>b"]
    it "leaves an element that never closes" $
      splitAtElements "span" "a<span>b" `shouldBe` ["a<span>b"]
    it "counts tab, vertical tab, form feed and carriage return as spaces" $
      splitAtElements "span" "<\tspan>1<\r/\v\fspan>x" `shouldBe` ["", "x"]
    it "does not count a no-break space as a space" $
      splitAtElements "span" "<\160span>1</span>x" `shouldBe` ["<\160span>1</span>x"]
    it "gives one empty piece for an empty text" $
      splitAtElements "span" "" `shouldBe` [""]
    it "splits a verse paragraph at its verse numbers" $
      splitAtElements "span"
        "<span class=\"Numeral\">1\160</span>In the beginning <span class=\"Numeral\">2\160</span>And the earth"
        `shouldBe` ["", "In the beginning ", "And the earth"]

  describe "removeElements" $ do
    it "drops a footnote link with its text" $
      removeElements "a" "word<a href=\"#f1\" class=\"footnote-link\">(1)</a> rest" `shouldBe` "word rest"
    it "drops a longer tag that starts with a, up to the first closing a" $
      removeElements "a" "x<abbr>y</a>z" `shouldBe` "xz"
    it "leaves a link that never closes" $
      removeElements "a" "x<a>y" `shouldBe` "x<a>y"
    it "drops a footnote block" $
      removeElements "div" "text<div class=\"footnote\">note</div> more" `shouldBe` "text more"

  describe "linksWithWordBefore" $ do
    it "takes the word joined to the link and the word before it" $
      linksWithWordBefore "one two<a href=\"#f1\">(1)</a> three" `shouldBe` [("one two<a href=\"#f1\">(1)</a>", "(1)")]
    it "takes the word before a link that follows a space" $
      linksWithWordBefore "one two <a href=\"#f1\">(1)</a>" `shouldBe` [("two <a href=\"#f1\">(1)</a>", "(1)")]
    it "takes only the joined word after two spaces" $
      linksWithWordBefore "one  two<a>(2)</a>" `shouldBe` [("two<a>(2)</a>", "(2)")]
    it "takes a link at the start of the text" $
      linksWithWordBefore "<a>(1)</a> rest" `shouldBe` [("<a>(1)</a>", "(1)")]
    it "takes two touching links as one match, with the second one's text" $
      linksWithWordBefore "w<a>(1)</a><a>(2)</a> x" `shouldBe` [("w<a>(1)</a><a>(2)</a>", "(2)")]
    it "finds each link, and goes on after each match" $
      linksWithWordBefore "a b<a>1</a> c d<a>2</a>" `shouldBe` [("a b<a>1</a>", "1"), ("c d<a>2</a>", "2")]
    it "joins words at a no-break space" $
      linksWithWordBefore "one two\160three<a>1</a>" `shouldBe` [("one two\160three<a>1</a>", "1")]
    it "takes the spaces inside the opening tag" $
      linksWithWordBefore "see word<a id=\"r1\" class=\"footnote-link\" href=\"#n1\">[1]</a>."
        `shouldBe` [("see word<a id=\"r1\" class=\"footnote-link\" href=\"#n1\">[1]</a>", "[1]")]
    it "finds nothing when a line feed comes before the closing tag" $
      linksWithWordBefore "x <a>1\n</a>" `shouldBe` []
    it "finds nothing in an empty text" $
      linksWithWordBefore "" `shouldBe` []
    it "reads Armenian words" $
      linksWithWordBefore "բառ մեկ<a href=\"#n2\">[2]</a> երկու" `shouldBe` [("բառ մեկ<a href=\"#n2\">[2]</a>", "[2]")]
