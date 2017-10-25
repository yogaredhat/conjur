#!/bin/bash -ex

kubectl create namespace conjur-dev
kubectl config set-context $(kubectl config current-context) --namespace=conjur-dev

if [ ! -f data_key ]; then
  echo "Generating data key"
  docker run --rm conjur data-key generate > data_key
fi

export CONJUR_DATA_KEY="$(cat data_key)"

echo Launching Postgres service

kubectl create -f dev_pg.yaml

echo Launching Conjur service

kubectl create secret generic conjur-data-key --from-literal "data-key=$CONJUR_DATA_KEY"

kubectl create -f dev_conjur.yaml

echo Launching Conjur CLI

kubectl create -f dev_cli.yaml
