#!/usr/bin/env bash
ROOT=~/csv_data # this folder name coming from docker volume mapping
SCRIPTURES=$ROOT/scriptures

E1994=$SCRIPTURES/bible/am/e1994-J
V1805=$SCRIPTURES/bible/am/v1805
KJV=$SCRIPTURES/bible/en/kjv

# not used 
Z1805=$SCRIPTURES/bible/am/z1805
AR94=$SCRIPTURES/bible/am/ar94

# Narek
NAREK_XER=$SCRIPTURES/narek/am/xeranyan
NAREK_GRABAR=$SCRIPTURES/narek/am/grabar

HEADERS=$SCRIPTURES/headers
ARMATS=$ROOT/words

#    --overwrite-destination \
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
    --nodes=Chapter="$HEADERS/chapter_header.csv,$E1994/.*_chapters.csv" \
    --nodes=Chapter="$HEADERS/chapter_header.csv,$V1805/.*_chapters.csv" \
    --nodes=Chapter="$HEADERS/chapter_header.csv,$NAREK_XER/.*_chapters.csv" \
    --nodes=Chapter="$HEADERS/chapter_header.csv,$NAREK_GRABAR/.*_chapters.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$E1994/.*_sections.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$V1805/.*_sections.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$NAREK_XER/.*_sections.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$NAREK_GRABAR/.*_sections.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$E1994/.*_verses.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$V1805/.*_verses.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$NAREK_XER/.*_verses.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$NAREK_GRABAR/.*_verses.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$E1994/.*_words.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$V1805/.*_words.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$NAREK_XER/.*_words.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$NAREK_GRABAR/.*_words.csv" \
    --nodes="$HEADERS/footnote_header.csv,$E1994/refs/.*_footnotes.csv" \
    --nodes="$HEADERS/footnote_header.csv,$V1805/refs/.*_footnotes.csv" \
    --nodes="$HEADERS/footnote_header.csv,$NAREK_XER/refs/.*_footnotes.csv" \
    --nodes="$HEADERS/footnote_header.csv,$NAREK_GRABAR/refs/.*_footnotes.csv" \
    --relationships=CONTAINS="$HEADERS/book_chapter_header.csv,$SCRIPTURES/BookChapterRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$E1994/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$V1805/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$NAREK_XER/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$NAREK_GRABAR/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$E1994/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$V1805/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$NAREK_XER/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$NAREK_GRABAR/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$E1994/.*_VerseWordRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$V1805/.*_VerseWordRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$NAREK_XER/.*_VerseWordRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$NAREK_GRABAR/.*_VerseWordRel.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$E1994/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$V1805/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$NAREK_XER/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$NAREK_GRABAR/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$E1994/refs/.*_verse_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$V1805/refs/.*_verse_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$NAREK_XER/refs/.*_verse_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$NAREK_GRABAR/refs/.*_verse_footnote.csv" \
    --relationships="$SCRIPTURES/scriptureRel.csv" \
    --nodes=Token="$ARMATS/wordForms.csv" \
    --nodes=Armat="$ARMATS/armats.csv" \
    --relationships=ARMAT="$ARMATS/WordArmatRel.csv" \
    --nodes="$KJV/periods.csv" \
    --nodes="$KJV/events.csv" \
    --nodes="$KJV/eastons.csv" \
    --nodes="$KJV/books.csv" \
    --nodes="$KJV/chapters.csv" \
    --nodes="$KJV/verses.csv" \
    --nodes="$KJV/persons.csv" \
    --nodes="$KJV/places.csv" \
    --relationships="$KJV/Testament_BookRel.csv" \
    --relationships="$KJV/Book_ChapterRel.csv" \
    --relationships="$KJV/Chapter_VerseRel.csv" \
    --relationships="$KJV/Person_ChapterRel.csv" \
    --relationships="$KJV/Person_YearRel.csv" \
    --relationships="$KJV/Verse_PersonRel.csv" \
    --relationships="$KJV/Verse_PlaceRel.csv" \
    --relationships="$KJV/Verse_EventRel.csv" \
    --relationships="$KJV/Event_YearRel.csv" \
    --relationships="$KJV/Commentary_EastonRel.csv" \
    --relationships="$KJV/Translation_KJVRel.csv" \
    bibles
# --nodes=Movie=movies.csv --nodes=Actor=actors.csv --relationships=roles.csv \
    
