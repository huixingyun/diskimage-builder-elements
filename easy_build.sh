#!/bin/bash
set -e

CURRENT_DIR="$(dirname "$0")"
pushd $CURRENT_DIR
git pull
popd

TM=$(date +%Y%m%d)
OUTPUT_DIR="${OUTPUT_DIR:-${CURRENT_DIR}/output}"

pushd $OUTPUT_DIR
for i in $@; do
    NAME=$(basename $i)

    $CURRENT_DIR/build.sh \
        $CURRENT_DIR/etc/${i}.yaml | tee ${NAME}.log

    mv "${NAME}.qcow2" "${NAME}_${TM}.qcow2"
done
popd
