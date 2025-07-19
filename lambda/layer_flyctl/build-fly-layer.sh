#!/bin/bash

set -e
mkdir -p ./bin
curl -L https://fly.io/install.sh | sh
cp ~/.fly/bin/flyctl ./bin
zip -r9 flyctl-layer.zip .