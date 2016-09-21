#!/bin/sh -e

HOST="$1"
UPSTREAM="$2"

if [ -z "$HOST" ]; then
  echo hostname required
  exit 1
fi

if [ -z "$UPSTREAM" ]; then
  echo upstream required
  exit 1
fi


echo Joining $UPSTREAM as $HOST...

LIST_NODES="
SELECT rolname FROM pg_roles WHERE oid IN (
  SELECT member FROM pg_auth_members WHERE roleid = (
    SELECT oid FROM pg_roles WHERE rolname = 'possum_mm_nodes'
));
"

NODES=`echo $LIST_NODES | psql -qAt "user=$HOST host=$UPSTREAM dbname=possum"`

su postgres -c "psql possum -c 'CREATE GROUP possum_mm_nodes'"
for node in $NODES; do
  su postgres -c "psql possum -c 'CREATE USER "$node" LOGIN SUPERUSER IN GROUP possum_mm_nodes'"
done

su postgres -c "psql possum" << EOF
  SELECT bdr.bdr_group_join(
    local_node_name := '$HOST',
    node_external_dsn := 'host=$HOST',
    node_local_dsn := 'dbname=possum', -- this is only used for initialization
    join_using_dsn := 'host=$UPSTREAM'
  )
EOF
