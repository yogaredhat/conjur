#!/bin/sh -e

EXTERNAL_HOST_NAME="$1"

if [ -z "$EXTERNAL_HOST_NAME" ]; then
  echo hostname required
  exit 1
fi

echo Initializing cluster with hostname $EXTERNAL_HOST_NAME...

su postgres -c "psql possum" << EOF
  ALTER SYSTEM SET bdr.extra_apply_connection_options TO 'dbname=possum user=$EXTERNAL_HOST_NAME';
  CREATE GROUP possum_mm_nodes;
  CREATE USER "$EXTERNAL_HOST_NAME" LOGIN SUPERUSER IN GROUP possum_mm_nodes;
  SELECT bdr.bdr_group_create(
    local_node_name := '$EXTERNAL_HOST_NAME',
    node_external_dsn := 'host=$EXTERNAL_HOST_NAME'
  );
EOF
