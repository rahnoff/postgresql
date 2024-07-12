#!/bin/bash
#
# Compile components of an HA PostgreSQL in Docker

set -e

# Quoting a command substitution consisting of Docker makes it exit with an
# error, that's why Docker CLI commands are unquoted

#############################################################################
# Compile Patroni and its CLI into single files with all defined dependencies
# bundled, a compilation takes places in a Docker container, a succesfull one
# results in tarballs being created in a root directory.
# Globals:
#   $1
#   $2
# Arguments:
#   patroni
#   target environment's Python version, to illustrate, 3.9.2
# Returns:
#   0 if tarballs have been created, non-zero on error.
#############################################################################
function compile_patroni() {
  pushd "$(git rev-parse --show-toplevel)" 1> /dev/null

  local executable

  declare -a executables

  executables=('patroni' 'patronictl')

  readonly executables

  docker image build \
    --build-arg python_version="$2" \
    -f - \
    -t patroni:latest .

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
  pushd "$(git rev-parse --show-toplevel)" 1> /dev/null

  local dockerfile

  if [[ "$2" == 'debian' ]]; then
    dockerfile='dockerfiles/PostgreSQL-Debian'
  elif [[ "$2" == 'rhel' ]]; then
    dockerfile='dockerfiles/PostgreSQL-RHEL'
  fi
  
  docker image build \
    -f "$(echo "${dockerfile}")" \
    -t postgresql:latest \
    --build-arg version="$3" \
    .

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
      echo -e '3 different components can be compiled:
  - Patroni
  - PgBouncer
  - PostgreSQL\n'
      echo 'By the way of illustration:
  $ compile_components postgresql debian 12.18
  $ compile_components patroni 3.9.6 sha256:546kl45j654jk6jk546'
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
      error "Parameters should be defined, for available ones, run with -h \
or --help option"
      exit 1
      ;;
  esac
}


main "$@"
