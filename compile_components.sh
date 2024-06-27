#!/bin/bash
#
# Compile components of an HA PostgreSQL in Docker

set -e

# Quoting a command substitution consisting of Docker makes it exit with an
# error, that's why Docker CLI commands are unquoted

#############################################################################
# Compile Patroni and its CLI into single files with all defined dependencies
# bundled, a compilation takes places in a Docker container, a succesfull one
# results in tarballs being created in a current directory.
# Globals:
#   $1
#   $2
# Arguments:
#   patroni
#   target environment's Python version, to illustrate, 3.9.2
# Returns:
#   0 if a tarball has been created, non-zero on error.
#############################################################################
function compile_patroni() {
  # python_version_no_dots=${1//./}
  local executable

  declare -a executables

  executables=('patroni' 'patronictl')

  readonly executables

  docker image build \
    --build-arg python_version="$2" \
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
          && Python-$python_version/configure \
          --enable-loadable-sqlite-extensions=yes \
          --prefix=$PWD \
          && make \
          && make altinstall \
          && bin/python${python_version%.*} -m pip install \
          --no-cache-dir \
          --upgrade \
          pip \
          && bin/python${python_version%.*} -m pip install \
          --no-cache-dir \
          pysqlite3 \
          setproctitle \
          && bin/python${python_version%.*} -m pip install \
          --no-cache-dir \
          patroni[etcd3,psycopg3] \
          pex \
          && bin/python${python_version%.*} -m pex \
          $(bin/pip${python_version%.*} freeze | grep -vE "pex|pysqlite3") \
          -c patroni \
          -o patroni \
          && bin/python${python_version%.*} -m pex \
          $(bin/pip${python_version%.*} freeze | grep -vE "pex|pysqlite3") \
          -c patronictl \
          -o patronictl
EOF

  for executable in "${executables[@]}"; do
    docker container cp \
      $(docker container create patroni:latest):/patroni/"${executable}" .

    tar -cf "${executable}".tar "${executable}"

    gzip -f "${executable}".tar
    
    rm -rf "${executable}"
  done

  docker container rm \
    $(docker container ls -a -f ancestor=patroni:latest -q)

  docker image rm patroni:latest
}


# compile_pgbouncer()
# {
#
# }


function compile_postgresql() {
  local dockerfile

  if [[ "$2" == 'debian' ]]; then
    dockerfile="$(cat 0<<"EOF"
    FROM rockylinux:8.9-mininal@sha256:6e772539b14a6463bfe3b1a8ee26200fbd01ec830ac02aaff9c16ebf27f2f410
    ARG version
    WORKDIR /src
    RUN microdnf install -y dnf \
          && dnf upgrade -y \
          && dnf -y groupinstall 'Development Tools' \
          && dnf install -y readline-devel
EOF
    )"
  elif [[ "$2" == 'rhel' ]]; then
    dockerfile="
    FROM rockylinux:8.9-minimal@sha256:6e772539b14a6463bfe3b1a8ee26200fbd01ec830ac02aaff9c16ebf27f2f410
    ARG version
    RUN microdnf install -y dnf \
          && dnf upgrade -y \
          && dnf -y groupinstall 'Development Tools' \
          && dnf install -y readline-devel \
          && groupadd -r postgres \
          && useradd -g postgres -rM -s /bin/false postgres \
          && mkdir /src /usr/local/postgresql \
          && chown postgres:postgres /src /usr/local/postgresql
    WORKDIR /src
    USER postgres:postgres
    RUN curl -O https://ftp.postgresql.org/pub/source/v\$version/postgresql-\$version.tar.gz \
          -O https://ftp.postgresql.org/pub/source/v\$version/postgresql-\$version.tar.gz.sha256 \
          && sha256sum -c postgresql-\$version.tar.gz.sha256 \
          && gzip -d postgresql-\$version.tar.gz \
          && tar -xf postgresql-\$version.tar \
          && postgresql-\$version/configure --prefix=/usr/local/postgresql \
          && make world \
          && make check \
          && make install-world
    "
  fi
  
  echo "${dockerfile}" \
    | docker image build --build-arg version="$3" -f - -t postgresql:latest .
  docker container cp \
    $(docker container create postgresql:latest):/usr/local/postgresql .
  tar -cf postgresql.tar postgresql
  gzip -f postgresql.tar
  rm -rf postgresql
  docker container rm \
    $(docker container ls -a -f ancestor=postgresql:latest -q)
  docker image rm postgresql:latest
}


function error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S%z')]: $*" 1>&2
}


function main() {
  case "$1" in
    -h | --help)
      echo -e "3 different components can be compiled:
- Patroni
- PgBouncer
- PostgreSQL"
      ;;
    patroni)
      if ! compile_patroni "$@"; then
        error "Compilation error"
        exit 1
      fi
      ;;
    pgbouncer)
      compile_pgbouncer "$@"
      ;;
    postgresql)
      compile_postgresql "$@"
      ;;
    *)
      error "Parameters should be defined, for available ones, run with -h or
--help option"
      exit 1
      ;;
  esac
}


main "$@"
