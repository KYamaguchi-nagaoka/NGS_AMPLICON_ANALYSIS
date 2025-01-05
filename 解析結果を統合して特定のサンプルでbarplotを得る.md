
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
Tokyo1-normal	1.Tokyo1-normal
Tokyo2-normal	2.Tokyo2-normal
Tokyo3-normal	3.Tokyo3-normal
Tokyo1-mochi	4.Tokyo1-mochi
Tokyo2-mochi	5.Tokyo2-mochi
Tokyo3-mochi	6.Tokyo3-mochi
Kyoto-0518	7.Kyoto-0518
Kyoto-1125	8.Kyoto-1125
Kyoto-0129	9.Kyoto-0129
Komaki-0518	10.Komaki-0518
Komaki-1125	11.Komaki-1125
Komaki-0129	12.Komaki-0129
Before	13.Before
After	14.After
0823	15.0823
0906	16.0906
0912	17.0912
0922	18.0922
1003	19.1003
1019	20.1019
1026	21.1026
1109	22.1109
1121	23.1121
1206	24.1206
1219	25.1219
0118	26.0118
0201	27.0201
0222	28.0222
0321	29.0321

```
- SQLでSample_idを抽出
```
qiime feature-table filter-samples \
  --i-table merged-table.qza \
  --m-metadata-file map.txt \
  --p-where "Sample-id IN ('Tokyo1-normal', '0321', '1219')" \
  --o-filtered-table filtered-table.qza
```

### 手順5: バープロットの作成
```
qiime taxa barplot \
  --i-table filtered-table.qza \
  --i-taxonomy merged-taxonomy.qza \
  --m-metadata-file map.txt \
  --o-visualization taxa-bar-plots.qzv
```
### オプション:htmlに変換
```
 qiime tools export --input-path taxa-barplot.qzv --output-path exported-visualization
 ```




