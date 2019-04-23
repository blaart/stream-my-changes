#!/bin/sh
cp -r /setup/.aws /root/.
cp /data/*.ipynb /root/.
jupyter notebook /root/testinserts.ipynb \
    --ip=0.0.0.0 \
    --port=8889 \
    --allow-root \
    --no-browser
