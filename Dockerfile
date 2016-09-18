FROM debian:jessie

ADD pubkeys/pgdg.asc /tmp
RUN apt-key add /tmp/pgdg.asc && rm /tmp/pgdg.asc && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

ADD pubkeys/bdr.asc /tmp
RUN apt-key add /tmp/bdr.asc && rm /tmp/bdr.asc && \
  echo "deb http://packages.2ndquadrant.com/bdr/apt/ jessie-2ndquadrant main" \
    > /etc/apt/sources.list.d/bdr.list

RUN apt-get update && \
  apt-get install -y postgresql-common && \
  echo "create_main_cluster = false"  > /etc/postgresql-common/createcluster.conf && \
  apt-get install -y postgresql-bdr-9.4 postgresql-bdr-9.4-bdr-plugin && \
  apt-get clean

CMD /opt/possum/create.sh

ADD createcluster.conf /etc/postgresql-common/createcluster.conf
ADD create.sh /opt/possum/
