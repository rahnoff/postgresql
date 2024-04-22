#!/bin/bash
#
# Compile components of an HA PostgreSQL in Docker

set -eu -o pipefail

# if [[ "$#" -lt 1 ]]; then
#   echo "Usage: `basename $0` 3.9.2 or `basename $0` 3.8.6"
#   echo "3.9.2 or 3.8.6 - Python version on machines where"
#   echo "Patroni will be installed"
#   exit 1
# fi

compile_patroni()
{
  docker image build \
    --build-arg python_version="$1" \
    --build-arg python_version_no_dots="$python_version_no_dots" \
    -f "$PWD/dockerfiles/Patroni" \
    -t patroni:latest .
  
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

main()
{
  if compile_patroni; then
    error "Couldn't compile Patroni"
    exit 1
  fi
}

main