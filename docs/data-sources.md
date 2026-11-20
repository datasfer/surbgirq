# Data sources and licences

None of this data is in the repository. This page says where each dataset came from, what its status is, and what can be
shared, so the graph can be rebuilt from the right sources, with credit.

| Dataset | IDs in the code | Digital source used | Status | Shared? |
|---|---|---|---|---|
| **Zohrab Bible**, Venice 1805, Classical Armenian (Grabar), edited by Hovhannes Zohrabian, with his variant notes | `v1805-T`, `z1805-T` | `v1805`: an EPUB e-book, probably made from qahana.am's typed text (to be confirmed). `z1805`: the Zohrab text of the Arak29 Foundation's site (bible.armeniancathedral.org), with the variant notes | Public domain | Planned, as a release download |
| **Narek**, Grigor Narekatsi's *Book of Lamentations* (about 1002), the Classical Armenian original, 95 chapters | `narekaci-T` (`Narek_Grabar`) | to be confirmed | Public domain | Planned, once the source is confirmed |
| **King James Version** (the 1769 text) | `kjv-T` | through Theographic | Public domain, except in the UK (Crown rights) | Through Theographic |
| **Theographic Bible Metadata**: people, places, events, years, people groups, Easton's Bible Dictionary (1897), all linked to KJV verses; by Robert Rouse | the KJV layer | [github.com/robertrouse/theographic-bible-metadata](https://github.com/robertrouse/theographic-bible-metadata) | CC BY-SA 4.0, which applies to the CSVs derived from it too | Download it from its repository and convert it with `theographic` |
| **The 1994 Etchmiadzin translation**, modern Eastern Armenian in classical spelling, translated 1985–1991 | `e1994-T` (also `ar94`, a second digitization) | qahana.am pages; the Arak29 site | © Mother See of Holy Etchmiadzin and the Bible Society of Armenia | No |
| **Narek in Mkrtich Kheranyan's modern translation** (Yerevan, 1960) | `narek_xer-T` | to be confirmed | © until the end of 2040 (the author died in 1970) | No |
| **The Classical Armenian word list**: 49,955 word forms, 11,742 roots, grammar tags, 7,856 English glosses | `Armat`, `Token` | the Arak29 Foundation's annotated Classical Armenian Bible ([arak29.org/bible](https://arak29.org/bible/)) | "All Rights Reserved Arak29" | No |

The code also has IDs for translations the pipeline never loaded (`e2004-T`, the Russian Synodal, two more Narek
translations); `theodata/corpora.conf` doesn't include them.

## What "shared" will look like

- **A release download** (planned) with the public-domain texts as YAML and as the import CSVs, plus a `DATA-LICENSES.md`
  with one row per dataset and its credits.
- **Theographic** stays in its own repository: download it and run `theographic` ([data-pipeline.md](data-pipeline.md)).
- **With these,** anyone can build a working graph: Classical Armenian (Zohrab, Narek) and the KJV layer with people, places
  and events. It's smaller than the author's private graph, which also has the copyrighted texts.

## Credits

- **qahana.am:** typed texts of the Armenian Bible: the saved pages, and probably the e-book's source.
- **The Arak29 Charitable Foundation** (arak29.org, bible.armeniancathedral.org): the annotated Classical Armenian Bible and
  the Zohrab text with variant notes.
- **Theographic Bible Metadata** by Robert Rouse (CC BY-SA 4.0), and the sources it credits.
