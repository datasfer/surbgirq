#!/usr/bin/env bash

set -euo pipefail

## Load paths from .env if available
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

## Root path for data
rootPath="./scriptures"

## Base Directories
declare -A PATHS=(
  [E1994]="$rootPath/bible/am/e1994-J"
  [V1805]="$rootPath/bible/am/v1805"
  [KJV]="$rootPath/bible/en/kjv"
  [Z1805]="$rootPath/bible/am/z1805"   # Unused
  [AR94]="$rootPath/bible/am/ar94"     # Unused
  [NAREK_XER]="$rootPath/narek/am/xeranyan"
  [NAREK_GRABAR]="$rootPath/narek/am/grabar"
  [SCRIPTURES]="$rootPath"
  [HEADERS]="$rootPath/headers"
  [ARMATS]="./words"
)

## Validate paths exist
for key in "${!PATHS[@]}"; do
  if [ ! -d "${PATHS[$key]}" ]; then
    echo "❌ Directory not found: ${PATHS[$key]} ($key)" >&2
    exit 1
  fi
done

## Helper to build import options
function add_node() {
  if [[ -z "$1" ]]; then
    echo -n "--nodes=\"$2\" \\\n"
  else
    echo -n "--nodes=$1=\"$2\" \\\n"
  fi
}

function add_rel() {
  if [[ -z "$1" ]]; then
    echo -n "--relationships=\"$2\" \\\n"
  else
    echo -n "--relationships=$1=\"$2\" \\\n"
  fi
}

## Define import command
IMPORT_CMD=$(cat <<EOF
neo4j-admin database import full \
  --verbose \
  --id-type STRING \
  --delimiter ";" \
  --array-delimiter "|" \
  --multiline-fields=true \
  
  # Nodes
  $(add_node Scripture       "\${PATHS[SCRIPTURES]}/scriptures.csv")
  $(add_node ""             "\${PATHS[SCRIPTURES]}/translations.csv")
  $(add_node ""             "\${PATHS[SCRIPTURES]}/testaments.csv")
  $(add_node ""             "\${PATHS[SCRIPTURES]}/divisions.csv")
  $(add_node ""             "\${PATHS[SCRIPTURES]}/commentaries.csv")
  $(add_node Book           "\${PATHS[SCRIPTURES]}/books.csv")
  $(add_node Token          "\${PATHS[ARMATS]}/wordForms.csv")
  $(add_node Armat          "\${PATHS[ARMATS]}/armats.csv")
  $(add_node ""             "\${PATHS[SCRIPTURES]}/scriptureRel.csv")
  $(add_node ""             "\${PATHS[KJV]}/periods.csv")
  $(add_node ""             "\${PATHS[KJV]}/events.csv")
  $(add_node ""             "\${PATHS[KJV]}/eastons.csv")
  $(add_node ""             "\${PATHS[KJV]}/books.csv")
  $(add_node ""             "\${PATHS[KJV]}/chapters.csv")
  $(add_node ""             "\${PATHS[KJV]}/verses.csv")
  $(add_node ""             "\${PATHS[KJV]}/persons.csv")
  $(add_node ""             "\${PATHS[KJV]}/places.csv")

  # Relationships
  $(add_rel ARMAT           "\${PATHS[ARMATS]}/WordArmatRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Testament_BookRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Book_ChapterRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Chapter_VerseRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Person_ChapterRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Person_YearRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Verse_PersonRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Verse_PlaceRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Verse_EventRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Event_YearRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Commentary_EastonRel.csv")
  $(add_rel ""             "\${PATHS[KJV]}/Translation_KJVRel.csv")

  bibles
EOF
)

## Run import
echo "🚀 Running Neo4j import..."
eval "$IMPORT_CMD"
echo "✅ Import completed."




## Option 2
#!/usr/bin/env bash

# Base paths
rootPath="./scriptures"
HEADERS="$rootPath/headers"
E1994="$rootPath/bible/am/e1994-J"
V1805="$rootPath/bible/am/v1805"
NAREK_XER="$rootPath/narek/am/xeranyan"
NAREK_GRABAR="$rootPath/narek/am/grabar"
ARMATS="./words"
KJV="$rootPath/bible/en/kjv"

function add_node() {
  if [[ -z "$1" ]]; then
    echo -n "--nodes=\"$2\" \\\n"
  else
    echo -n "--nodes=$1=\"$2\" \\\n"
  fi
}

function add_rel() {
  if [[ -z "$1" ]]; then
    echo -n "--relationships=\"$2\" \\\n"
  else
    echo -n "--relationships=$1=\"$2\" \\\n"
  fi
}

cat <<EOF
neo4j-admin database import full \\
    --verbose \\
    --id-type STRING \\
    --delimiter ";" \\
    --array-delimiter "|" \\
    --multiline-fields=true \\
EOF

add_node Scripture "$rootPath/scriptures.csv"
add_node "" "$rootPath/translations.csv"
add_node "" "$rootPath/testaments.csv"
add_node "" "$rootPath/divisions.csv"
add_node "" "$rootPath/commentaries.csv"
add_node Book "$rootPath/books.csv"

add_node Chapter "$HEADERS/chapter_header.csv,$E1994/.*_chapters.csv"
add_node Chapter "$HEADERS/chapter_header.csv,$V1805/.*_chapters.csv"
add_node Chapter "$HEADERS/chapter_header.csv,$NAREK_XER/.*_chapters.csv"
add_node Chapter "$HEADERS/chapter_header.csv,$NAREK_GRABAR/.*_chapters.csv"

add_node Section "$HEADERS/section_header.csv,$E1994/.*_sections.csv"
add_node Section "$HEADERS/section_header.csv,$V1805/.*_sections.csv"
add_node Section "$HEADERS/section_header.csv,$NAREK_XER/.*_sections.csv"
add_node Section "$HEADERS/section_header.csv,$NAREK_GRABAR/.*_sections.csv"

add_node Verse "$HEADERS/verse_header.csv,$E1994/.*_verses.csv"
add_node Verse "$HEADERS/verse_header.csv,$V1805/.*_verses.csv"
add_node Verse "$HEADERS/verse_header.csv,$NAREK_XER/.*_verses.csv"
add_node Verse "$HEADERS/verse_header.csv,$NAREK_GRABAR/.*_verses.csv"

add_node Word "$HEADERS/word_header.csv,$E1994/.*_words.csv"
add_node Word "$HEADERS/word_header.csv,$V1805/.*_words.csv"
add_node Word "$HEADERS/word_header.csv,$NAREK_XER/.*_words.csv"
add_node Word "$HEADERS/word_header.csv,$NAREK_GRABAR/.*_words.csv"

add_node "" "$HEADERS/footnote_header.csv,$E1994/refs/.*_footnotes.csv"
add_node "" "$HEADERS/footnote_header.csv,$V1805/refs/.*_footnotes.csv"
add_node "" "$HEADERS/footnote_header.csv,$NAREK_XER/refs/.*_footnotes.csv"
add_node "" "$HEADERS/footnote_header.csv,$NAREK_GRABAR/refs/.*_footnotes.csv"

add_rel CONTAINS "$HEADERS/book_chapter_header.csv,$rootPath/BookChapterRel.csv"
add_rel CONTAINS "$HEADERS/chapter_section_header.csv,$E1994/.*_ChapterSectionRel.csv"
add_rel CONTAINS "$HEADERS/chapter_section_header.csv,$V1805/.*_ChapterSectionRel.csv"
add_rel CONTAINS "$HEADERS/chapter_section_header.csv,$NAREK_XER/.*_ChapterSectionRel.csv"
add_rel CONTAINS "$HEADERS/chapter_section_header.csv,$NAREK_GRABAR/.*_ChapterSectionRel.csv"

add_rel CONTAINS "$HEADERS/chapter_verse_header.csv,$E1994/.*_ChapterVerseRel.csv"
add_rel CONTAINS "$HEADERS/chapter_verse_header.csv,$V1805/.*_ChapterVerseRel.csv"
add_rel CONTAINS "$HEADERS/chapter_verse_header.csv,$NAREK_XER/.*_ChapterVerseRel.csv"
add_rel CONTAINS "$HEADERS/chapter_verse_header.csv,$NAREK_GRABAR/.*_ChapterVerseRel.csv"

add_rel CONTAINS "$HEADERS/verse_word_header.csv,$E1994/.*_VerseWordRel.csv"
add_rel CONTAINS "$HEADERS/verse_word_header.csv,$V1805/.*_VerseWordRel.csv"
add_rel CONTAINS "$HEADERS/verse_word_header.csv,$NAREK_XER/.*_VerseWordRel.csv"
add_rel CONTAINS "$HEADERS/verse_word_header.csv,$NAREK_GRABAR/.*_VerseWordRel.csv"

add_rel "" "$HEADERS/word_footnote_header.csv,$E1994/refs/.*_word_footnote.csv"
add_rel "" "$HEADERS/word_footnote_header.csv,$V1805/refs/.*_word_footnote.csv"
add_rel "" "$HEADERS/word_footnote_header.csv,$NAREK_XER/refs/.*_word_footnote.csv"
add_rel "" "$HEADERS/word_footnote_header.csv,$NAREK_GRABAR/refs/.*_word_footnote.csv"

add_rel "" "$HEADERS/verse_footnote_header.csv,$E1994/refs/.*_verse_footnote.csv"
add_rel "" "$HEADERS/verse_footnote_header.csv,$V1805/refs/.*_verse_footnote.csv"
add_rel "" "$HEADERS/verse_footnote_header.csv,$NAREK_XER/refs/.*_verse_footnote.csv"
add_rel "" "$HEADERS/verse_footnote_header.csv,$NAREK_GRABAR/refs/.*_verse_footnote.csv"

add_rel "" "$rootPath/scriptureRel.csv"

add_node Token "$ARMATS/wordForms.csv"
add_node Armat "$ARMATS/armats.csv"

add_rel ARMAT "$ARMATS/WordArmatRel.csv"

add_node "" "$KJV/periods.csv"
add_node "" "$KJV/events.csv"
add_node "" "$KJV/eastons.csv"
add_node "" "$KJV/books.csv"
add_node "" "$KJV/chapters.csv"
add_node "" "$KJV/verses.csv"
add_node "" "$KJV/persons.csv"
add_node "" "$KJV/places.csv"

add_rel "" "$KJV/Testament_BookRel.csv"
add_rel "" "$KJV/Book_ChapterRel.csv"
add_rel "" "$KJV/Chapter_VerseRel.csv"
add_rel "" "$KJV/Person_ChapterRel.csv"
add_rel "" "$KJV/Person_YearRel.csv"
add_rel "" "$KJV/Verse_PersonRel.csv"
add_rel "" "$KJV/Verse_PlaceRel.csv"
add_rel "" "$KJV/Verse_EventRel.csv"
add_rel "" "$KJV/Event_YearRel.csv"
add_rel "" "$KJV/Commentary_EastonRel.csv"
add_rel "" "$KJV/Translation_KJVRel.csv"

echo "bibles"


project/
│
├── scripts/
│   └── import.sh
│
├── scriptures/
│   └── bible/
│       ├── am/
│       └── en/
│
├── words/
│   └── armats.csv
│   └── wordForms.csv
│
├── docker-compose.yml
├── .env
└── Makefile



# .env
NEO4J_VERSION=5.26.6-enterprise
NEO4J_PASSWORD=CHANGE_ME
NEO4J_UID=1000
NEO4J_GID=999
NEO4J_DATA_DIR=${HOME}/neo4j_data
SCRIPTURES_DIR=${HOME}/scriptures
SCRIPTS_DIR=./scripts