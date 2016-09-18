#!/bin/sh

su postgres -c "psql possum" << EOF
  SELECT * FROM bdr.bdr_node_slots;
EOF
