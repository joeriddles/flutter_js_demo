#!/usr/bin/env sh
set -eux

act \
  --workflows .github/workflows/test.yaml \
  --job test \
  --container-architecture linux/amd64 \
  --pull=false \
  --verbose
