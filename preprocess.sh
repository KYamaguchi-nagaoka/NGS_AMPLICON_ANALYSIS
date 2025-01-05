#!/bin/bash

# 確認: 必要なツールがインストールされているか確認
#conda install -c bioconda bbmap
#conda install -c bioconda flash
#conda install -c bioconda fastx_toolkit
#conda install -c bioconda seqkit
#conda install -c bioconda sickle-trim

# ディレクトリ内の全てのR1.fastq.gzファイルを処理
for r1_file in *_R1_001.fastq.gz; do
  r2_file="${r1_file/_R1_001.fastq.gz/_R2_001.fastq.gz}"
  base=$(basename $r1_file _R1_001.fastq.gz)

  # 入力ファイルの存在を確認
  if [ ! -f "$r1_file" ]; then
    echo "Error: $r1_file not found."
    continue
  fi
  if [ ! -f "$r2_file" ]; then
    echo "Error: $r2_file not found."
    continue
  fi

  # 解凍
  gunzip -c $r1_file > ${base}_R1_001.fastq
  gunzip -c $r2_file > ${base}_R2_001.fastq

  # ログファイルの準備
  log_file="${base}_process.log"
  echo "Log for ${base}" > $log_file

  # Generate files for Forward and Reverse with N from 0 to 5 bases
  for i in {0..5}; do
    for j in {0..5}; do
      # Handle Forward sequences
      fastx_trimmer -f $(($i + 1)) -i ${base}_R1_001.fastq -o ${base}_temp_R1_N${i}${j}.fastq
      sed 's/^@/@N'${i}${j}'_/' ${base}_temp_R1_N${i}${j}.fastq > ${base}_output_R1_N${i}${j}.fastq
      rm ${base}_temp_R1_N${i}${j}.fastq

      # Handle Reverse sequences
      fastx_trimmer -f $(($j + 1)) -i ${base}_R2_001.fastq -o ${base}_temp_R2_N${i}${j}.fastq
      sed 's/^@/@N'${i}${j}'_/' ${base}_temp_R2_N${i}${j}.fastq > ${base}_output_R2_N${i}${j}.fastq
      rm ${base}_temp_R2_N${i}${j}.fastq
    done
  done

  
  cat ${base}_output_R1_N*.fastq > ${base}_output_R1.fastq
  cat ${base}_output_R2_N*.fastq > ${base}_output_R2.fastq

  # Forwardプライマーと一致する配列を抽出
  cat ${base}_output_R1.fastq | fastx_barcode_splitter.pl --bol --exact --bcfile 16S-F.txt --prefix ${base}_output_R1_ >> $log_file

  # Rename output files to have .fastq extension
  for file in ${base}_output_R1_515f_*; do
    mv "$file" "${file}.fastq"
  done

  # 抽出されたリードのidを取得
  awk 'NR%4==1 {print substr($1, 2)}' ${base}_output_R1_515f_01.fastq > ${base}_forward_matched_ids.txt
  awk 'NR%4==1 {print substr($1, 2)}' ${base}_output_R1_515f_02.fastq >> ${base}_forward_matched_ids.txt

  # 抽出されたリードのidの数を確認
  grep "^N" ${base}_forward_matched_ids.txt | wc -l

  # 抽出したRead1と同じidのRead2を抽出
  #seqkit grep -f ${base}_forward_matched_ids.txt ${base}_output_R2.fastq -o ${base}_filtered_output_R2.fastq
   grep -A 3 -Ff ${base}_forward_matched_ids.txt ${base}_output_R2.fastq | grep -v "^--$" > ${base}_filtered_output_R2.fastq



  # リード数の確認
  grep "^@" ${base}_filtered_output_R2.fastq | wc -l

  # Reverseプライマーと一致する配列を抽出
  cat ${base}_filtered_output_R2.fastq | fastx_barcode_splitter.pl --bol --exact --bcfile 16S-R.txt --prefix ${base}_output_R2_ >> $log_file

  # Rename output files to have .fastq extension
  for file in ${base}_output_R2_806r_*; do
    mv "$file" "${file}.fastq"
  done

  # ファイルをまとめる
  cat ${base}_output_R1_515f_*.fastq > ${base}_output_R1_primer_matched.fastq
  cat ${base}_output_R2_806r_*.fastq > ${base}_output_R2_primer_matched.fastq

  awk 'NR%4==1 {print substr($1, 2)}' ${base}_output_R2_806r_01.fastq > ${base}_reverse_matched_ids.txt
  awk 'NR%4==1 {print substr($1, 2)}' ${base}_output_R2_806r_*.fastq >> ${base}_reverse_matched_ids.txt

  #seqkit grep -f ${base}_reverse_matched_ids.txt ${base}_output_R1_primer_matched.fastq -o ${base}_filtered_output_R1.fastq
   grep -A 3 -Ff ${base}_reverse_matched_ids.txt ${base}_output_R1_primer_matched.fastq | grep -v "^--$" > ${base}_filtered_output_R1.fastq

  # ペアエンドリードのペアを修正
  repair.sh in1=${base}_filtered_output_R1.fastq in2=${base}_output_R2_primer_matched.fastq out1=${base}_filtered_output_R1_repaired.fastq out2=${base}_filtered_output_R2_repaired.fastq outs=${base}_singletons.fastq nullifybrokenquality

  # プライマー配列の除去
  fastx_trimmer -f 20 -i ${base}_filtered_output_R1_repaired.fastq -o ${base}_output_R1_trimmed.fastq
  fastx_trimmer -f 21 -i ${base}_filtered_output_R2_repaired.fastq -o ${base}_output_R2_trimmed.fastq

  # クオリティチェック
  sickle pe -f ${base}_output_R1_trimmed.fastq -r ${base}_output_R2_trimmed.fastq -t sanger -o ${base}_output_R1_HQ.fastq -p ${base}_output_R2_HQ.fastq -s ${base}_single.fastq -q 20 -l 130 >> $log_file

  # リードの結合
  flash2 -f 310 -r 230 -m 10 -o ${base}_merge_R1_R2_${base} ${base}_output_R1_HQ.fastq ${base}_output_R2_HQ.fastq >> $log_file

  # 再圧縮
  gzip -c ${base}_output_R1_HQ.fastq > ${base}_R1_HQ.fastq.gz
  gzip -c ${base}_output_R2_HQ.fastq > ${base}_R2_HQ.fastq.gz

  # 不要ファイルの削除
  rm ${base}_output_R1_N*.fastq ${base}_output_R2_N*.fastq ${base}_output_R1.fastq ${base}_output_R2.fastq ${base}_output_R1_515f_*.fastq ${base}_output_R2_806r_*.fastq ${base}_output_R1_primer_matched.fastq ${base}_output_R2_primer_matched.fastq ${base}_forward_matched_ids.txt ${base}_filtered_output_R2.fastq ${base}_reverse_matched_ids.txt ${base}_filtered_output_R1.fastq ${base}_output_R1_trimmed.fastq ${base}_output_R2_trimmed.fastq ${base}_single.fastq ${base}_output_R1_HQ.fastq.gz ${base}_output_R2_HQ.fastq.gz ${base}_R1_001.fastq ${base}_R2_001.fastq ${base}_output_R1_unmatched ${base}_output_R2_unmatched ${base}_filtered_output_R1_repaired.fastq ${base}_filtered_output_R2_repaired.fastq
${base}_singletons.fastq ${base}_merge_R1_R2_{base}.notCombined_1.fastq ${base}_merge_R1_R2_{base}.notCombined_2.fastq 


done

#!/bin/bash

# マニフェストファイルのヘッダーを作成
echo "sample-id,absolute-filepath,direction" > ./Manifest.txt

# 現在のディレクトリパスを取得
current_dir=$(pwd)

# ファイルの処理
for file in ./*.extendedFrags.fastq; do
  sample_id=$(basename "$file" | awk -F_ '{print $1}')
  abs_filepath="${current_dir}/${file}"
  direction="forward"
  echo "${sample_id},${abs_filepath},${direction}" >> ./Manifest.txt
done

#　配列データのインポート
# Single readの場合
qiime tools import --type SampleData"[SequencesWithQuality]" --input-path Manifest.txt --output-path sequence.qza --input-format SingleEndFastqManifestPhred33

qiime demux summarize   \
--i-data sequence.qza   \
--o-visualization sequence.qzv

# DADA2
qiime dada2 denoise-single --i-demultiplexed-seqs sequence.qza --p-trunc-len 0 --o-representative-sequences repset.qza --o-table table.qza --p-n-threads 4 --output-dir OTU


# 系統推定
qiime feature-classifier classify-sklearn --i-classifier ./classifier/classifier.qza --i-reads repset.qza --o-classification taxonomy.qza

#　バーチャートの作成
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy.qza --m-metadata-file map.txt --o-visualization taxa-barplot.qzv

# taxa-barplot.qzvをhtmlファイルとして出力
 qiime tools export --input-path taxa-barplot.qzv --output-path exported-visualization
