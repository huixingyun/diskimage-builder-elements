#!/bin/bash

setup_pip_mirror() {
  mkdir -p ${HOME}/.pip
  cat >${HOME}/.pip/pip.conf <<EOF
[global]
index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/
#extra-index-url = https://mirrors.bfsu.edu.cn/pypi/web/simple
EOF
  echo "pip mirror already set"
}

setup_conda_mirror() {
  cat >${HOME}/.condarc <<EOF
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  deepmodeling: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
EOF
  echo "conda mirror already set"
}
