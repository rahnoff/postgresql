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
  pushd "$(git rev-parse --show-toplevel)" 1> /dev/null || exit

  local executable

  declare -a executables

  executables=('patroni' 'patronictl')

  readonly executables

  docker image build \
    -f dockerfiles/Patroni \
    -t patroni:latest \
    --build-arg image_sha256="$2" \
    --build-arg python_version="$3" \
    --no-cache \
    .

  for executable in "${executables[@]}"; do
    docker container cp \
      $(docker container create patroni:latest):/opt/patroni/"${executable}" .

    tar -cf "${executable}".tar "${executable}"

    gzip -f "${executable}".tar

    mv "${executable}".tar.gz ansible-playbooks/roles/patroni/files
    
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
  pushd "$(git rev-parse --show-toplevel)" 1> /dev/null || exit

  local dockerfile

  if [[ "$2" == 'debian' ]]; then
    dockerfile='dockerfiles/PostgreSQL-Debian'
    readonly dockerfile
  elif [[ "$2" == 'rhel' ]]; then
    dockerfile='dockerfiles/PostgreSQL-RHEL'
    readonly dockerfile
  fi
  
  docker image build \
    -f "$(echo "${dockerfile}")" \
    -t postgresql:latest \
    --build-arg version="$3" \
    --no-cache \
    .

  docker container cp \
    $(docker container create postgresql:latest):/usr/local/postgresql .

  tar -cf postgresql.tar postgresql

  gzip -f postgresql.tar

  mv postgresql.tar.gz ansible-playbooks/roles/postgresql/files

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
  $ compile_components postgresql rhel 12.18
  $ compile_components patroni sha256:736b76eb3f64778646ce0051fb5fed4dfbf67016e51563946230ca8bb40ac687 3.9.6'
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
