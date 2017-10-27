#!/bin/bash -ex

eval $(minikube docker-env)

docker build -t myapp -f Dockerfile.myapp .
docker build -t authenticator -f Dockerfile.authenticator .

