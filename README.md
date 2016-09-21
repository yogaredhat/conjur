# Possum multi-master POC

## Prerequisites

- docker
- conjurinc/possum docker image with possum
- python API in ../api-python (if you want to use it; uncomment it first in docker-compose.yml)

## Running

Since the first node becomes unoperative when put into BDR mode until a second
node joins, let's start with a standalone first node.

### First node

Start database and possum:

    $ docker-compose up possum-sol

Setup the token key:

    $ docker-compose exec possum-sol possum token-key generate example

Load the policy:

    $ docker-compose exec possum-sol possum policy load example /policy/policy.yml

Enable BDR:

    $ docker-compose exec sol /opt/possum/init.sh sol

### Other nodes

Note that you need to start the database first and join it to the cluster.
Otherwise possum will try to initialize it.

Start database:

    $ docker-compose up sirius

Prepare the cluster:

    $ docker-compose exec sol /opt/possum/prepare.sh sirius

Join it:

    $ docker-compose exec sirius /opt/possum/join.sh sirius sol

Start possum:

    $ docker-compose up possum-sirius

You can do the above again replacing `sirius` with `centauri` for a third node.

## Trying it out

Assuming you have api-python in correct location and enabled it (see prerequisites):

    $ docker-compose run --rm python-api

    >>> import conjur
    >>> sol = conjur.new_from_password('admin', 'secret', configuration=conjur.Config(account='example', url='http://possum-sol'))
    >>> sirius = conjur.new_from_password('admin', 'secret', configuration=conjur.Config(account='example', url='http://possum-sirius'))
    >>> sol.resource('variable', 'myapp/ssl_cert').add_secret('very secret, such resource')
    >>> sirius.resource('variable', 'myapp/ssl_cert').secret()
    u'very secret, such resource'
