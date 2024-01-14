#!/usr/bin/env bash

# Narek
export NAREK_XER=./scriptures/narek/am/xeranyan

export SCRIPTURES=./scriptures
export HEADERS=./scriptures/headers
export ARMATS=./words

neo4j-admin database import full \
    --verbose \
    --id-type STRING \
    --delimiter ";" \
    --array-delimiter "|" \
    --multiline-fields=true \
    --nodes=Scripture="$SCRIPTURES/scriptures.csv" \
    --nodes="$SCRIPTURES/translations.csv" \
    --nodes="$SCRIPTURES/testaments.csv" \
    --nodes="$SCRIPTURES/divisions.csv" \
    --nodes="$SCRIPTURES/commentaries.csv" \
    --nodes=Book="$SCRIPTURES/books.csv" \
    --nodes=Chapter="$HEADERS/chapter_header.csv,$NAREK_XER/.*_chapters.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$NAREK_XER/.*_sections.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$NAREK_XER/.*_verses.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$NAREK_XER/.*_words.csv" \
    --nodes="$HEADERS/footnote_header.csv,$NAREK_XER/refs/.*_footnotes.csv" \
    --relationships=CONTAINS="$HEADERS/book_chapter_header.csv,$SCRIPTURES/BookChapterRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$NAREK_XER/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$NAREK_XER/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$NAREK_XER/.*_VerseWordRel.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$NAREK_XER/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$NAREK_XER/refs/.*_verse_footnote.csv" \
    --relationships="$SCRIPTURES/scriptureRel.csv" \
    --nodes=Token="$ARMATS/wordForms.csv" \
    --nodes=Armat="$ARMATS/armats.csv" \
    --relationships=ARMAT="$ARMATS/WordArmatRel.csv" \
    narek.xeranyan
    
