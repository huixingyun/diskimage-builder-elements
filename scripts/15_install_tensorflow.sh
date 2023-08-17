#!/bin/bash
set -euxo pipefail

TENSORFLOW_VERSION=${TENSORFLOW_VERSION:-"2.12.*"}
TENSORRT_VERSION=${TENSORRT_VERSION:-"8.6.1"}

install_jupyterlab() {
    install_miniconda
    ## Install TensorFlow
    python3 -m pip install tensorflow==${TENSORFLOW_VERSION}
    ## (optional) Install TensorRT
    python3 -m pip install tensorrt==${TENSORRT_VERSION}
}

install_jupyterlab