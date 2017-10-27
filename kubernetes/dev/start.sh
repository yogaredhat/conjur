#!/bin/bash -e

kubectl create namespace conjur-dev
kubectl config set-context $(kubectl config current-context) --namespace=conjur-dev

./build.sh

echo Launching workloads

kubectl create -f workloads

echo Waiting for Conjur
while ! kubectl describe pod conjur | grep Status: | grep -c Running > /dev/null; do
  sleep 1
done

while ! kubectl exec conjur -c conjur -- curl -X OPTIONS -s --fail localhost:80; do
  sleep 1
done

echo Creating account 'cucumber'

if ! kubectl exec conjur -c conjur -- conjurctl account create cucumber; then
  admin_api_key=$(kubectl exec conjur -c conjur -- rails r "puts Role['cucumber:user:admin'].api_key")
  echo API key for admin: $admin_api_key
fi

echo For an interactive session on conjur-dev, run the following command:
echo "kubectl exec -it conjur-dev -- bash"

echo To run tests:
echo "kubectl exec -it conjur-dev -c conjur -- ./bin/rspec"
echo "kubectl exec -it conjur-dev -c conjur -- env CONJUR_APPLIANCE_URL=http://conjur ./bin/cucumber-api"
echo "kubectl exec -it conjur-dev -c conjur -- env CONJUR_APPLIANCE_URL=http://conjur ./bin/cucumber-policy"

echo To sync the local project 'app' directory to conjur-dev:
echo " ./sync_push.sh app"
echo
echo To sync the conjur-dev Gemfile.lock to your local project:
echo " ./sync_pull.sh Gemfile.lock"
