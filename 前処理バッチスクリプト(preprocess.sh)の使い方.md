## フォルダ内のRaw-fastqからbarplotを作成するpreprocess.shの使い方 

1. Raw-fastqの中の.fastqとmap.txt(.fastqに対応するように編集)を新しい作業ファイルにコピー
2. 16S-F.txt,16S-R.txtとgreenegenes13_8とプライマー配列で学習済みの分類器(classifier.qza)が入ったclassifierフォルダを作業フォルダに用意
3. preprocess.shを作業フォルダにコピー
   ```
   作業フォルダ
      |_XXXX_L001_R1_001.fastq(.gzファイル)
      |_XXXX_L001_R2_001.fastq(.gzファイル)
      |_map.txt
      |_16S-F.txt
      |_16S-R.txt
      |_preprocess.sh
      |_classifier
           |_classifier.qza(学習済みの分類器)
   ```

4. docker run -v 作業ファイルディレクトリ:/data -it ビルドしたdocker imageの名前
5. ```
   chmod +x preprocess.sh
   

6. ```
   ./preprocess.sh # コマンドを実行
   ```
