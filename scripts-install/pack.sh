#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

cp -av ../health-check/static/* static/
# cp -av ../node-exporter/static/* static/
# cp -av ../docker-daemon-config/static/* static/
# cp -av ../systemd-comfyui/static/* static/
# cp -av ../systemd-rvc-webui/static/* static/

cp -av ../health-check/bin/* static/usr/local/bin/
cp -av ../hcp/bin/* static/usr/local/bin/
cp -av ../bolt-app/bin/* static/usr/local/bin/
# cp -av ../systemd-jupyterlab/bin/* static/usr/local/bin/
# cp -av ../prometheus/bin/* static/usr/local/bin/
# cp -av ../open-webui/bin/* static/usr/local/bin/

# cp -av ../comfyui/bin/* static/usr/local/bin/
# cp -av ../rvc-webui-public-data/bin/* static/usr/local/bin/
# cp -av ../sd-webui-common/bin/* static/usr/local/bin/
# cp -av ../fooocus/bin/* static/usr/local/bin/

tar -czvf scripts.tgz -C static/ .
