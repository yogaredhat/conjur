#!/bin/sh -ex

[ -z "$EXTERNAL_HOST_NAME" ] && exit 1
[ -z "$THIS_NODE_NAME" ] && THIS_NODE_NAME="$EXTERNAL_HOST_NAME"

# NOTE: cluster cannot be precreated in Dockerfile, because
# BDR uses unique cluster ID to identify nodes in replication
pg_createcluster 9.4 possum --start

# TODO: proper authorization
echo hostssl all all all trust >> /etc/postgresql/9.4/possum/pg_hba.conf
echo hostssl replication all all trust >> /etc/postgresql/9.4/possum/pg_hba.conf

su postgres -c "createdb possum"
su postgres -c "psql possum" << EOF
  CREATE EXTENSION btree_gist;
  CREATE EXTENSION bdr;
  CREATE EXTENSION possum_mm;
EOF

# stop to exec
pg_ctlcluster 9.4 possum stop
exec su postgres  -c '/usr/lib/postgresql/9.4/bin/postgres --config-file=/etc/postgresql/9.4/possum/postgresql.conf'
