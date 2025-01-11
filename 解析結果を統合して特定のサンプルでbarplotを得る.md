
### 手順1: フィーチャーテーブルのマージ
```
qiime feature-table merge \
  --i-tables table1.qza \
  --i-tables table2.qza \
  --o-merged-table merged-table.qza
```

### 手順2: リファレンスシーケンスのマージ
```
qiime feature-table merge-seqs \
  --i-data repset1.qza \
  --i-data repset2.qza \
  --o-merged-data merged-rep-seqs.qza
```

### 手順3: タクソノミーのマージ
```
qiime feature-table merge-taxa \
  --i-data taxonomy1.qza \
  --i-data taxonomy2.qza \
  --o-merged-data merged-taxonomy.qza
```

### 手順4: 特定のサンプルを抽出  
- map.txtは結合する2解析分を合体したものを用意する

```
#SampleID	Description
A-normal	1.A-normal
B-normal	2.B-normal
C-normal	3.C-normal
A-01	4.A-01
B-01	5.B-01
C-01	6.C-01
A-02	7.A-02
B-02	8.B-02
C-02	9.C-02
A-03	10.A-03
B-03	11.B-03
C-03	12.C-03
Before	13.Before
After	14.After
001	15.001
002	16.002
003	17.003
004	18.004
005	19.005
006	20.006
007	21.007
008	22.008
009	23.009
010	24.010
011	25.011
012	26.012
013	27.013
014	28.014
015	29.015

```
- SQLでSample_idを抽出
```
qiime feature-table filter-samples \
  --i-table merged-table.qza \
  --m-metadata-file map.txt \
  --p-where "Sample-id IN ('A-normal', '005', '012')" \
  --o-filtered-table filtered-table.qza
```

### 手順5: バープロットの作成
```
qiime taxa barplot \
  --i-table filtered-table.qza \
  --i-taxonomy merged-taxonomy.qza \
  --m-metadata-file map.txt \
  --o-visualization taxa-barplot.qzv
```
### オプション:htmlに変換
```
 qiime tools export --input-path taxa-barplot.qzv --output-path exported-visualization
 ```




