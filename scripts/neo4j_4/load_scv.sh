

// create index on :Armat(word);
// create index on :BaraDzev(word);


create constraint on (t:Armat) assert t.armatId is unique;
create constraint on (u:BaraDzev) assert u.baradzevId is unique;


LOAD CSV FROM 'file:///armat.csv' AS line FIELDTERMINATOR ';'
CREATE (:Armat { word: line[1], armatId: toInteger(line[0])})



LOAD CSV FROM 'file:///form.csv' AS line FIELDTERMINATOR ';'
Merge (a:Armat { word: line[1], armatId: toInteger(line[0])})
Merge (b:BaraDzev { baradzevId: toInteger(line[0]), word: line[1], armat: line[2], tag: line[3]})
Create (a)-[r:HAS_FORM]->(b)


LOAD CSV FROM 'file:///armatFormRel.csv' AS line FIELDTERMINATOR ';'
MATCH (a:Armat {armatId: toInteger(line[0])}),  (b:BaraDzev {baradzevId: toInteger(line[1])})
Create (a)-[r:HAS_FORM]->(b)


Matthew; 1; 1; 1; 1; Գիրք ծննդեան Յիսուսի Քրիստոսի որդւոյ Դաւթի որդւոյ Աբրահամու։ 
Match (b:Book:Matthew)  
LOAD CSV FROM 'file:///matthew.csv' AS line FIELDTERMINATOR ';'
Merge (ch:Chapter { num: toInteger(line[1])})
Merge (sec:Section {num: toInteger(line[2])})
Merge (prgh:Paragraph {num: toInteger(line[3])})

Create (verse:Verse {num: toInteger(line[4]), content: line[5]})
Create (b)-[r:HAS_CH]->(ch)
Create (ch)-[r:HAS_SEC]->(sec)
Create (sec)-[r:HAS_PRGH]->(prgh)
Create (prgh)-[r:HAS_VERSE]->(verse)


Match (b:Book:Matthew)  
LOAD CSV FROM 'file:///matthew.csv' AS line FIELDTERMINATOR ';'
Merge (ch:Chapter1 { num: line[1]})
Merge (sec:Section1 {num: line[2]})
Merge (prgh:Paragraph1 {num: line[3]})

Merge (verse:Verse1 {num: line[4], content: line[5]})

Merge (b)-[r:HAS_CH]->(ch)
Merge (ch)-[r2:HAS_SEC]->(sec)
Merge (sec)-[r3:HAS_PRGH]->(prgh)
Merge (prgh)-[r4:HAS_VERSE]->(verse)
  WITH split(line[5]," ") as words
  UNWIND range(0,size(words)-2) as idx

  Merge (w1:Word1 {name: words[idx]})
  Merge (w2:Word1 {name: words[idx+1]})
  Merge (verse)-[:HAS_WORD1]->(w1);
  Merge (verse)-[:HAS_WORD2]->(w2);
  Create (w1)-[:NEXT1]->(w2);


Match (b:Book:Matthew)  
LOAD CSV FROM 'file:///matthew.csv' AS line FIELDTERMINATOR ';'
Merge (verse:Verse2 {num: line[4], content: line[5]})
WITH split(line[5]," ") as words
UNWIND range(0,size(words)-2) as idx

Merge (w1:Word1 {name: words[idx]})
Merge (w2:Word1 {name: words[idx+1]})
Merge (verse)-[:HAS_WORD1]->(w1);
Merge (verse)-[:HAS_WORD2]->(w2);
Create (w1)-[:NEXT1]->(w2);


WITH split("Great device but the calls drop too frequently"," ") as words
UNWIND range(0,size(words)-2) as idx

MERGE (w1:Word {name:words[idx]})
MERGE (w2:Word {name:words[idx+1]})
MERGE (w1)-[:NEXT]->(w2);


--
LOAD CSV FROM 'file:///matthew.csv' AS line FIELDTERMINATOR ';'
WITH line LIMIT 5
WITH split(line[5]," ") as words
UNWIND range(0,size(words)-2) as idx
Create (w1:Word3 {name:words[idx]})
Create (w2:Word3 {name:words[idx+1]})
Create (w1)-[:NEXT]->(w2);

return words[idx]
