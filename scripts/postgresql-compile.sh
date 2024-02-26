#!/bin/bash
#
# Compile PostgreSQL in Docker

set -o pipefail

if [[ "$#" -lt 2 ]]; then
  echo "Usage: $(basename $0) Debian 12.1 or $(basename $0) RHEL 14.2"
  echo "Debian or RHEL - Linux flavor, 12.1 or 14.2 - PostgreSQL version"
  exit 1
fi

echo -e "Compiling PostgreSQL $2\n"

docker image build --build-arg version="$2" \
  -f ../dockerfiles/PostgreSQL-"$1" \
  -t postgresql-compiled:latest .

echo -e "\n"

echo -e "Copying /usr/local/postgresql\n"

docker container cp $(docker container create \
  postgresql-compiled:latest):/usr/local/postgresql .

tar -cf postgresql.tar postgresql

gzip postgresql.tar

mv postgresql.tar.gz ../ansible-playbooks/roles/postgresql/files

rm -rf postgresql

echo -e "\n"

echo -e "Removing containers\n"

docker container rm $(docker container ls -a \
  | grep "postgresql-compiled:latest" \
  | awk '{print $1}')

echo -e "\n"

echo -e "Removing an image\n"

docker image rm postgresql-compiled:latest
