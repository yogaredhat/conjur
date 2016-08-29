\echo Use "CREATE EXTENSION possum_mm" to load this file. \quit

CREATE OR REPLACE FUNCTION init_cluster(external_hostname text, node_name text)
RETURNS void
LANGUAGE sql
AS $$
  SELECT bdr.bdr_group_create(
    local_node_name := $2,
    node_external_dsn := 'host=' || $1
  )
$$;

CREATE OR REPLACE FUNCTION join_cluster(
  external_hostname text, node_name text, bootstrap_hostname text)
RETURNS void
LANGUAGE sql
AS $$
  SELECT bdr.bdr_group_join(
    local_node_name := $2,
    node_external_dsn := 'host=' || $1,
    join_using_dsn := 'host=' || $3
  )
$$;
