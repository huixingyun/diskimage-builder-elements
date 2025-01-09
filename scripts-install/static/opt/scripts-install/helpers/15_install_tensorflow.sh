#!/bin/bash

PIP_LINKS=${PIP_LINKS:-"whl"}
TENSORFLOW_VERSION=${TENSORFLOW_VERSION:-"2.15.0"}
TENSORFLOW_LINKS=${TENSORFLOW_LINKS:-"$PIP_LINKS"}
TENSORRT_VERSION=${TENSORRT_VERSION:-"8.6.1"}
TENSORRT_LINKS=${TENSORRT_LINKS:-"$PIP_LINKS"}

install_tensorflow_pip() {
    local option=""
    if [[ -d "${TENSORFLOW_LINKS}" ]]; then
        echo "TensorFlow install from local whl files: ${TENSORFLOW_LINKS}"
        option="--no-index --find-links ${TENSORFLOW_LINKS}"
    fi
    python3 -m pip install tensorflow[and-cuda]==${TENSORFLOW_VERSION} ${option}
}

install_tensorrt_pip() {
    local option=""
    if [[ -d "${TENSORRT_LINKS}" ]]; then
        echo "TensorRT install from local whl files: ${TENSORRT_LINKS}"
        option="--no-index --find-links ${TENSORRT_LINKS}"
    fi
    python3 -m pip install tensorrt==${TENSORRT_VERSION} ${option}
}

verify_tensorflow() {
    python3 -c "import tensorflow as tf; print(tf.__version__)"
}

verify_tensorflow_gpu() {
    python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
}

fix_links() {
    # ref: https://www.tensorflow.org/install/pip#step-by-step_instructions
    pushd $(dirname $(python3 -c 'print(__import__("tensorflow").__file__)'))
    ln -svf ../nvidia/*/lib/*.so* .
    popd
}

verify_tensorrt() {
    python3 -c "import tensorrt as trt; print(trt.__version__)"
}

install_tensorflow() {
    install_miniconda

    ## Install TensorRT
    if ! verify_tensorrt; then
        install_tensorrt_pip
    fi

    ## Install TensorFlow
    if ! verify_tensorflow; then
        install_tensorflow_pip
    fi

    echo "TensorFlow ${TENSORFLOW_VERSION} and TensorRT ${TENSORRT_VERSION} installed"
}
