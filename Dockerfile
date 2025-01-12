# ベースイメージとして Ubuntu 20.04 を使用
FROM ubuntu:20.04

# 必要なパッケージのインストール
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        wget \
        bzip2 \
        ca-certificates \
        curl \
        git \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ロケールの設定
RUN locale-gen ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# 必要なパッケージのインストール
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        wget \
        curl \
        git \
        autoconf \
        automake \
        libtool \
        pkg-config \
        zlib1g-dev \
        libbz2-dev \
        libncurses5-dev \
        libncursesw5-dev \
        liblzma-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        python3 \
        python3-pip \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# seqkit のインストール
RUN wget https://github.com/shenwei356/seqkit/releases/download/v2.3.0/seqkit_linux_amd64.tar.gz && \
    tar -zxvf seqkit_linux_amd64.tar.gz && \
    mv seqkit /usr/local/bin/ && \
    rm seqkit_linux_amd64.tar.gz && \
    seqkit version

# Minicondaのインストール
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh

# 環境変数の設定
ENV PATH=/opt/conda/bin:$PATH

# Biocondaの設定とパッケージのインストール
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda install -y fastx_toolkit flash2 sickle && \
    conda install -y fastx_toolkit flash2 sickle-trim bbmap && \
    conda clean -y --all

# QIIME 2 のインストール
#conda env create -n qiime2-amplicon-2024.10 --file https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml
RUN wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml && \
    conda env create -n qiime2-amplicon-2024.10 --file qiime2-amplicon-2024.10-py310-linux-conda.yml && \
    conda clean -y --all && \
    echo "source activate qiime2-amplicon-2024.10" >> ~/.bashrc && \
    rm qiime2-amplicon-2024.10-py310-linux-conda.yml


# 作業ディレクトリの設定
WORKDIR /data

# コンテナ起動時のデフォルトコマンド
CMD ["/bin/bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate qiime2-amplicon-2024.10 && bash"]

