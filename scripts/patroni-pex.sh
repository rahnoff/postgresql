#!/bin/bash
#
# Compile Patroni as pex in Docker

set -eu -o pipefail

if [[ "$#" -lt 1 ]]; then
  echo "Usage: `basename $0` 3.9.2 or `basename $0` 3.8.6"
  echo "3.9.2 or 3.8.6 - Python version on machines where"
  echo "Patroni will be installed"
  exit 1
fi

if [[ "$PWD" != "$HOME/postgresql" ]]; then
  echo "Current directory should be $HOME/postgresql"
  exit 1
fi

echo -e "Compiling Patroni\n"

python_version_no_dots=${1//./}

docker image build \
  --build-arg python_version="$1" \
  --build-arg python_version_no_dots="$python_version_no_dots" \
  -f "$HOME/postgresql/dockerfiles/Patroni" \
  -t patroni:latest .

docker container cp $(docker container create \
  patroni:latest):/patroni/patroni-pex .

tar -cf patroni.tar patroni-pex

gzip patroni.tar

mv patroni.tar.gz ../ansible-playbooks/roles/patroni/files

rm -rf patroni-pex

echo -e "\n"

echo -e "Removing a container\n"

docker container rm $(docker container ls -a | \
  grep "patroni:latest" | awk '{print $1}')

echo -e "\n"

echo -e "Removing an image\n"

docker image rm patroni:latest
