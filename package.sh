#!/bin/bash -ex

debify package \
  conjur \
  -- \
  --depends tzdata
