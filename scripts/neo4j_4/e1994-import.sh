#!/usr/bin/env bash


ROOT_PATH=/var/lib/neo4j/data/csv

# be carefull not to leave space after line ends with simbol \
export E1994=$ROOT_PATH/scriptures/bible/am/e1994-J

export SCRIPTURES=$ROOT_PATH/scriptures
export HEADERS=$ROOT_PATH/scriptures/headers
export ARMATS=$ROOT_PATH/words

neo4j-admin import \
    --database=bibleam \
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
    --nodes=Chapter="$HEADERS/chapter_header.csv,$E1994/.*_chapters.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$E1994/.*_sections.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$E1994/.*_verses.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$E1994/.*_words.csv" \
    --nodes="$HEADERS/footnote_header.csv,$E1994/refs/.*_footnotes.csv" \
    --relationships=CONTAINS="$HEADERS/book_chapter_header.csv,$SCRIPTURES/BookChapterRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$E1994/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$E1994/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$E1994/.*_VerseWordRel.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$E1994/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$E1994/refs/.*_verse_footnote.csv" \
    --relationships="$SCRIPTURES/scriptureRel.csv" \
    --nodes=Token="$ARMATS/wordForms.csv" \
    --nodes=Armat="$ARMATS/armats.csv" \
    --relationships=ARMAT="$ARMATS/WordArmatRel.csv" \
    
# --nodes=Movie=movies.csv --nodes=Actor=actors.csv --relationships=roles.csv \
    
