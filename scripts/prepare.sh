#!/bin/sh

HOST="$1"

if [ -z "$HOST" ]; then
  echo hostname required
  exit 1
fi

echo Preparing to accept $HOST...

su postgres -c "psql possum" << EOF
  SELECT bdr.bdr_replicate_ddl_command(
    'CREATE USER "$HOST" LOGIN SUPERUSER IN GROUP possum_mm_nodes'
  );
EOF
