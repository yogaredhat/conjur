#!/bin/bash

target=$1

if [[ "$target" == "" ]]; then
  echo "Usage: $0 <target>"
  exit 1
fi

kubectl cp $(pwd)/../../$target conjur-dev:/src/conjur-server/$target -c conjur

