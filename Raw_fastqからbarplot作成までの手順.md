### **データ解析方法 (16S rRNA)**
 1. プライマー配列に一致したリードの抽出  
FASTX-Toolkit (ver. 0.0.14)のfastx_barcode_splitter toolを
用いて得られたリード配列の読み始めが使用したプライ
マー配列と完全に一致するリード配列のみを抽出しました。  
プライマー配列にN-mixを含む場合、Nの数(フォワード側
6種類 x リバース側6種類= 36種類)を考慮して、この操作
を繰り返しました。  
抽出したリードからプライマー配列を
FASTX-Toolkitのfastx_trimmerで削除しました。  
その後、
sickle (ver. 1.33)を用いて品質値が20未満の配列を取り除
き、130塩基以下の長さとなった配列とそのペア配列を破
棄いたしました。  

 2. リードの結合  
~~ペアエンドリード結合スクリプトFLASH (ver. 1.2.11)を用
いてリードを結合しました。~~  
ペアエンドリード結合スクリプトFLASH2を用
いてリードを結合しました。  
(ver.1.2.11だとなぜか結合率が低かったため。)

 3. Qiime2を用いた解析  
Qiime2 (ver. 2024.10)のdada2プラグインでキメラ配列とノ
イズ配列を除去した後、代表配列とASV表を出力しました。  
feature-classifierプラグインを用いて、取得した代表配列
とGreengene (ver. 13_8)の97% OTU を比較し系統推定致
しました。  
系統樹の作成には、Alignmentとphylogenyプラ
グインを使用しました。


### **実際の処理コマンド**  
#### 36通りのNに対応したファイルを生成する(R1,R2:計72ファイル)
```
for i in {0..5}; do
  for j in {0..5}; do
    # Handle Forward sequences
    fastx_trimmer -f $(($i + 1)) -i Komaki-0129_S88_L001_R1_001.fastq.gz -o temp_R1_N${i}${j}.fastq
    sed 's/^@/@N'${i}${j}'_/' temp_R1_N${i}${j}.fastq > output_R1_N${i}${j}.fastq
    rm temp_R1_N${i}${j}.fastq

    # Handle Reverse sequences
    fastx_trimmer -f $(($j + 1)) -i Komaki-0129_S88_L001_R2_001.fastq.gz -o temp_R2_N${i}${j}.fastq
    sed 's/^@/@N'${i}${j}'_/' temp_R2_N${i}${j}.fastq > output_R2_N${i}${j}.fastq
    rm temp_R2_N${i}${j}.fastq
  done
done 
```

#### 生成したファイルをまとめる
```
cat output_R1_N*.fastq > output_R1.fastq
cat output_R2_N*.fastq > output_R2.fastq
```


#### プライマーと一致する配列を抽出<br>
1. forward primerと完全一致する配列を抽出
2. 計算量削減のため抽出した配列idと一致するR2リードを抽出
3. reverse primerと完全に一致する配列を抽出
```
cat output_R1.fastq | fastx_barcode_splitter.pl --bol --exact --bcfile 16S-F.txt --prefix output_R1_

# 拡張子つけなおす
for file in output_R1_515f_*; do
  mv "$file" "${file}.fastq"
done

# 抽出されたリードのidを取得
awk 'NR%4==1 {print substr($1, 2)}' output_R1_515f_01.fastq > forward_matched_ids.txt
awk 'NR%4==1 {print substr($1, 2)}' output_R1_515f_02.fastq >> forward_matched_ids.txt

# 抽出されたリードのidの数を確認
grep "^N" forward_matched_ids.txt | wc -l

# 抽出したRead1と同じidのRead2を抽出
seqkit grep -f forward_matched_ids.txt output_R2.fastq -o filtered_output_R2.fastq

# リード数の確認
grep "^@" filtered_output_R2.fastq | wc -l

# Reverseプライマーと一致する配列を抽出
cat filtered_output_R2.fastq | fastx_barcode_splitter.pl --bol --exact --bcfile 16S-R.txt --prefix output_R2_

# Rename output files to have .fastq extension
for file in output_R2_806r_*; do
  mv "$file" "${file}.fastq"
done

# ファイルをまとめる
cat output_R1_515f_*.fastq > output_R1_primer_matched.fastq
cat output_R2_806r_*.fastq > output_R2_primer_matched.fastq

awk 'NR%4==1 {print substr($1, 2)}'  output_R2_806r_01.fastq> reverse_matched_ids.txt
awk 'NR%4==1 {print substr($1, 2)}'  output_R2_806r_*.fastq >> reverse_matched_ids.txt

seqkit grep -f reverse_matched_ids.txt output_R1_primer_matched.fastq -o filtered_output_R1.fastq 
```

#### ペアエンドリードのペアを修正 (プライマーと一致する配列を抽出した際にR1,R2のリードペアの同期が崩れてしまっているため)
```
repair.sh in1=filtered_output_R1.fastq in2=filtered_output_R2.fastq out1=filtered_output_R1_repaired.fastq out2=filtered_output_R2_repaired.fastq outs=singletons.fastq
```

#### プライマー配列の除去
```
fastx_trimmer -f 20 -i filtered_output_R1_repaired.fastq -o output_R1_trimmed.fastq
fastx_trimmer -f 21 -i filtered_output_R2_repaired.fastq -o output_R2_trimmed.fastq
```

#### クオリティチェック
```
sickle pe -f output_R1_trimmed.fastq -r output_R2_trimmed.fastq -t sanger -o output_R1_HQ.fastq -p output_R2_HQ.fastq -s single.fastq -q 20 -l 130
```

#### リードの結合
```
flash2 -f 310 -r 230 -m 10 -o merge_R1_R2 output_R1_HQ.fastq output_R2_HQ.fastq
```


#### 分類器作成(greenegenes 13_8) [参考リンク](https://note.com/nanaimo_/n/n601094548c2c)
```
qiime tools import \
 --type 'FeatureData[Sequence]' \
 --input-path 99_otus.fasta \
 --output-path 99_otus.qza

qiime tools import \
 --type 'FeatureData[Taxonomy]' \
 --input-format HeaderlessTSVTaxonomyFormat \
 --input-path 99_otu_taxonomy.txt \
 --output-path ref-taxonomy.qza


qiime feature-classifier extract-reads \
 --i-sequences 99_otus.qza \
 --p-f-primer GTGCCAGCMGCCGCGGTAA \
 --p-r-primer GGACTACHVGGGTWTCTAAT \
 --p-max-length 291\
 --o-reads ref-seqs.qza

qiime feature-classifier fit-classifier-naive-bayes \
 --i-reference-reads ref-seqs.qza \
 --i-reference-taxonomy ref-taxonomy.qza \
 --o-classifier classifier.qza

```


#### 配列データのインポート
```
# Single readの場合
qiime tools import --type SampleData"[SequencesWithQuality]" --input-path manifest.txt --output-path sequence.qza --input-format SingleEndFastqManifestPhred33
```

#### DADA2
```
qiime dada2 denoise-single --i-demultiplexed-seqs sequence.qza --p-trunc-len 0 --o-representative-sequences repset.qza --o-table table.qza --p-n-threads 4 --output-dir OTU
```


#### 系統推定
```
qiime feature-classifier classify-sklearn --i-classifier ./classifier/classifier.qza --i-reads repset.qza --o-classification taxonomy.qza
```

#### バーチャートの作成
```
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy.qza --m-metadata-file map.txt --o-visualization taxa-barplot.qzv
```

#### .qzvをhtmlに変換
```
 qiime tools export --input-path taxa-barplot.qzv --output-path exported-visualization
 ```


