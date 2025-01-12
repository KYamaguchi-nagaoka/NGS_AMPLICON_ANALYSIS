# NGS_AMPLICON_ANALYSIS  

### 用途  
 業者に外注したバッチの異なるアンプリコンシーケンス解析結果を統合してバッチの異なるサンプル間でtaxa-barplotを作成する
 
### 解析環境
```
- ubuntu:20.04 
- seqkit
- Miniconda3-latest
- FASTX-Toolkit (ver. 0.0.14) 
- FLASH v2.2.00
- sickle (ver. 1.33) 
- bbmap 
- qiime2
```
##### 上記の環境をdockerで構築する　

  docker pull kei1201/ngs-bioinformatics:qiime2-amplicon-2024.10　

### ワークフローオプション 

A. 単純にqiime2の解析結果を統合して特定のサンプルを抽出後、taxa-barplotを作成[(詳細)](解析結果を統合して特定のサンプルでbarplotを得る.md)

B. NGSのRaw data(Raw_fastq)から前処理~barplot作成まで業者が行った解析法を忠実に再現する(時間かかる)[(詳細)](Raw_fastqからbarplot作成までの手順.md)  
[バッチ処理](前処理バッチスクリプト(preprocess.sh)の使い方.md)
   
