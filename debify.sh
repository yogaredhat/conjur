#!/bin/bash -ex

mkdir -p usr/local/bin
ln -sf /opt/conjur/conjur/bin/conjur-conjur usr/local/bin/

mkdir -p etc/conjur/nginx.d
cp opt/conjur/conjur/distrib/nginx/* etc/conjur/nginx.d/

mkdir -p etc/service/conjur/conjur/log
ln -sf /etc/service/conjur/plugin-service etc/service/conjur/conjur/run
ln -sf /etc/service/conjur/plugin-logger  etc/service/conjur/conjur/log/run

mkdir -p opt/conjur/etc
cp opt/conjur/conjur/distrib/conjur/etc/* opt/conjur/etc/

mkdir -p opt/conjur/conjur/config
ln -sf /opt/conjur/shared/config/database.yml opt/conjur/conjur/config/database.yml
