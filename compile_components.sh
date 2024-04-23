#!/bin/bash
#
# Compile components of an HA PostgreSQL in Docker

set -eu -o pipefail

compile_patroni() {
  docker image build \
  --build-arg python_version="$1" \
  --build-arg python_version_no_dots="$python_version_no_dots" \
  -f - \
  -t patroni:latest . 0<<"EOF"
  FROM debian:10-slim@sha256:6a7f39a6a5381fe295b1f2ba5a1514d9fe35affc4410a6f3fa10234070423a73
  ARG python_version
  ARG python_version_no_dots
  WORKDIR /patroni
  RUN apt update \
        && apt upgrade -y \
        && apt install -y \
        build-essential \
        curl \
        libffi-dev \
        libsqlite3-dev \
        libssl-dev \
        zlib1g-dev \
        && curl -O https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz \
        && gzip -d Python-$python_version.tgz \
        && tar -xf Python-$python_version.tar \
        && Python-$python_version/configure --enable-loadable-sqlite-extensions=yes --prefix=$PWD \
        && make \
        && make altinstall \
        && bin/pip${python_version%.*} install pysqlite3 setproctitle \
        && bin/pip${python_version%.*} install patroni[etcd,psycopg2-binary] pex \
        && bin/python${python_version%.*} -m pex $(bin/pip${python_version%.*} freeze \
        | grep -vE "pex|pysqlite3") -c patroni -o patroni
EOF

  docker container cp $(docker container create \ 
    patroni:latest):/patroni/patroni .

  tar -cf patroni.tar patroni \
    && gzip patroni.tar \
    && mv patroni.tar.gz "$PWD/ansible-playbooks/roles/patroni/files" \
    && rm -rf patroni

  docker container rm $(docker container ls -a \
    | grep "patroni:latest" \
    | awk '{print $1}')

  docker image rm patroni:latest
}


# compile_pgbouncer()
# {
#
# }


# compile_postgresql()
# {
#
# }


error()
{
  echo "[$(date +'%Y-%m-%d %H:%M:%S%z')]: $*" 1>&2
}


main() {
  case "$@" in
    "patroni 3.9.2")
      echo "test"
      # compile_patroni
      ;;
  esac
}


main