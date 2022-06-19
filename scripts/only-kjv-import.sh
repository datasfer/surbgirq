#!/usr/bin/env bash

export DATA=./scriptures/bible/am/e1994
export DATA1=./scriptures/bible/am/v1805

export KJV=./scriptures/bible/en/kjv

export SCRIPTURES=./scriptures
export HEADERS=./scriptures/headers
export ARMATS=./words

neo4j-admin import \
    --database=vizbible \
    --id-type STRING \
    --delimiter ";" \
    --array-delimiter "|" \
    --multiline-fields=true \
    --nodes=Scripture="$SCRIPTURES/scriptures.csv" \
    --nodes=Translation="$SCRIPTURES/translations.csv" \
    --nodes="$SCRIPTURES/commentaries.csv" \
    --nodes="$SCRIPTURES/testaments.csv" \
    --nodes="$SCRIPTURES/divisions.csv" \
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
    
