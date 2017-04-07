#!/bin/bash -e

set -o pipefail

function wait() {
  sleep 3
}

echo "Logging in: GET http://possum/authn/cucumber/login"
wait

api_key=$(curl -s --user admin:admin http://possum/authn/cucumber/login)

echo "Authenticating: POST http://possum/authn/cucumber/admin/authenticate"
wait

auth_token=$(curl -X POST -s --data $api_key http://possum/authn/cucumber/admin/authenticate | base64 -w0)

echo "Storing the database password: POST http://possum/secrets/cucumber/variable/inventory-db/password"
wait

password=$(openssl rand -hex 12)
curl -X POST -s --data $password -H "Authorization: Token token=\"$auth_token\"" "http://possum/secrets/cucumber/variable/inventory-db/password"

echo "Creating the host factory token: POST http://possum/host_factory_tokens"
wait

year=$(date --iso-8601 | cut -c 1-4)
expiration="$year-12-31"
hf_token=$(curl -X POST -s -H "Authorization: Token token=\"$auth_token\"" "http://possum/host_factory_tokens?host_factory=cucumber%3Ahost_factory%3Ainventory&expiration=$expiration" | jq -r .[0].token)

echo Placing the host factory token into the Puppet manifest
wait

cp manifest-original.pp manifest.pp
sed -ie "s/<HOST_FACTORY_TOKEN>/$hf_token/; w /dev/stdout" manifest.pp

echo Running puppet
wait

puppet apply manifest.pp

echo "Listing the contents of file /tmp/dbpass (should be $password)"
wait

cat /tmp/dbpass

echo
