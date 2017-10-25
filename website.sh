#!/bin/bash -ex

docker-compose build apidocs # builds conjur-apidocs image
docker run --rm conjur-apidocs > docs/_includes/api.html

docker-compose run --rm  \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e CONJUR_WEB_BUCKET -e CONJUR_WEB_CFG_BUCKET \
  -e CONJUR_WEB_USER -e CONJUR_WEB_PASSWORD \
  -e CPANEL_URL \
  docs bash -ec '
mkdir -p /output
jekyll build --destination /output/_site

echo "${CONJUR_WEB_USER}:$(openssl passwd -apr1 ${CONJUR_WEB_PASSWORD})" | aws s3 cp - s3://${CONJUR_WEB_CFG_BUCKET}/htpasswd

aws s3 sync --delete /output/_site s3://${CONJUR_WEB_BUCKET}
'
