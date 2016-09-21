#!/bin/sh -ex

if ! (pg_lsclusters | grep possum); then
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
EOF

  # stop to exec
  pg_ctlcluster 9.4 possum stop
fi

exec su postgres  -c '/usr/lib/postgresql/9.4/bin/postgres --config-file=/etc/postgresql/9.4/possum/postgresql.conf'
