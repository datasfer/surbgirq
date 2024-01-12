#!/usr/bin/env bash

export E1994=./scriptures/bible/am/e1994
export AR94=./scriptures/bible/am/ar94
export V1805=./scriptures/bible/am/v1805
export Z1805=./scriptures/bible/am/z1805
export KJV=./scriptures/bible/en/kjv

# Narek
export NAREK_XER=./scriptures/narek/am/xeranyan
export NAREK_GRABAR=./scriptures/narek/am/grabar

export SCRIPTURES=./scriptures
export HEADERS=./scriptures/headers
export ARMATS=./words

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
    --nodes=Chapter="$HEADERS/chapter_header.csv,$E1994/.*_chapters.csv,$AR94/.*_chapters.csv,$V1805/.*_chapters.csv,$Z1805/.*_chapters.csv,$NAREK_XER/.*_chapters.csv,$NAREK_GRABAR/.*_chapters.csv" \
    --nodes=Section="$HEADERS/section_header.csv,$E1994/.*_sections.csv,$AR94/.*_sections.csv,$V1805/.*_sections.csv,$Z1805/.*_sections.csv,$NAREK_XER/.*_sections.csv,$NAREK_GRABAR/.*_sections.csv" \
    --nodes=Paragraph="$HEADERS/prgh_header.csv,$E1994/.*_prghs.csv,$AR94/.*_prghs.csv,$V1805/.*_prghs.csv,$Z1805/.*_prghs.csv,$NAREK_XER/.*_prghs.csv,$NAREK_GRABAR/.*_prghs.csv" \
    --nodes=Verse="$HEADERS/verse_header.csv,$E1994/.*_verses.csv,$AR94/.*_verses.csv,$V1805/.*_verses.csv,$Z1805/.*_verses.csv,$NAREK_XER/.*_verses.csv,$NAREK_GRABAR/.*_verses.csv" \
    --nodes=Word="$HEADERS/word_header.csv,$E1994/.*_words.csv,$AR94/.*_words.csv,$V1805/.*_words.csv,$Z1805/.*_words.csv,$NAREK_XER/.*_words.csv,$NAREK_GRABAR/.*_words.csv" \
    --nodes="$HEADERS/footnote_header.csv,$E1994/refs/.*_footnotes.csv,$AR94/refs/.*_footnotes.csv,$V1805/refs/.*_footnotes.csv,$Z1805/refs/.*_footnotes.csv,$NAREK_XER/refs/.*_footnotes.csv,$NAREK_GRABAR/refs/.*_footnotes.csv" \
    --relationships=CONTAINS="$HEADERS/book_chapter_header.csv,$SCRIPTURES/BookChapterRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_section_header.csv,$E1994/.*_ChapterSectionRel.csv,$AR94/.*_ChapterSectionRel.csv,$V1805/.*_ChapterSectionRel.csv,$Z1805/.*_ChapterSectionRel.csv,$NAREK_XER/.*_ChapterSectionRel.csv,$NAREK_GRABAR/.*_ChapterSectionRel.csv" \
    --relationships=CONTAINS="$HEADERS/section_prgh_header.csv,$E1994/.*_SectionPrghRel.csv,$AR94/.*_SectionPrghRel.csv,$V1805/.*_SectionPrghRel.csv,$Z1805/.*_SectionPrghRel.csv,$NAREK_XER/.*_SectionPrghRel.csv,$NAREK_GRABAR/.*_SectionPrghRel.csv" \
    --relationships=CONTAINS="$HEADERS/chapter_verse_header.csv,$E1994/.*_ChapterVerseRel.csv,$AR94/.*_ChapterVerseRel.csv,$V1805/.*_ChapterVerseRel.csv,$Z1805/.*_ChapterVerseRel.csv,$NAREK_XER/.*_ChapterVerseRel.csv,$NAREK_GRABAR/.*_ChapterVerseRel.csv" \
    --relationships=CONTAINS="$HEADERS/verse_word_header.csv,$E1994/.*_VerseWordRel.csv,$AR94/.*_VerseWordRel.csv,$V1805/.*_VerseWordRel.csv,$Z1805/.*_VerseWordRel.csv,$NAREK_XER/.*_VerseWordRel.csv,$NAREK_GRABAR/.*_VerseWordRel.csv" \
    --relationships="$HEADERS/word_footnote_header.csv,$E1994/refs/.*_word_footnote.csv,$AR94/refs/.*_word_footnote.csv,$V1805/refs/.*_word_footnote.csv,$Z1805/refs/.*_word_footnote.csv,$NAREK_XER/refs/.*_word_footnote.csv,$NAREK_GRABAR/refs/.*_word_footnote.csv" \
    --relationships="$HEADERS/verse_footnote_header.csv,$E1994/refs/.*_verse_footnote.csv,$AR94/refs/.*_verse_footnote.csv,$V1805/refs/.*_verse_footnote.csv,$Z1805/refs/.*_verse_footnote.csv,$NAREK_XER/refs/.*_verse_footnote.csv,$NAREK_GRABAR/refs/.*_verse_footnote.csv" \
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
    
# --nodes=Movie=movies.csv --nodes=Actor=actors.csv --relationships=roles.csv \
    
