import argparse
import subprocess


GIT_DIRECTORY: str = subprocess.check_output(['git', 'rev-parse', '--show-toplevel']).decode('utf-8').strip()
DOCKERFILES_DIRECTORY: str = f'{GIT_DIRECTORY}/dockerfiles'


def compile_patroni(docker_image_sha256: str, python_version: str) -> None:
    '''
    Compile Patroni and its CLI into single files with all defined dependencies
    bundled, a compilation takes places in a Docker container, a succesfull one
    results in tarballs being created in a respective Ansible role directory.
    '''
    build_arg_first: str = f'docker_image_sha256={docker_image_sha256}'
    build_arg_second: str = f'python_version={python_version}'
    dockerfile: str = f'{DOCKERFILES_DIRECTORY}/Patroni'
    docker_image_name: str = 'patroni-pex:latest'
    executables: tuple[str] = ('patroni', 'patronictl')
    subprocess.run(['docker', 'image', 'build', '-f', dockerfile, '-t', docker_image_name, '--build-arg', build_arg_first, '--build-arg', build_arg_second, '--no-cache', '.'])
    docker_container_id: str = subprocess.check_output(['docker', 'container', 'create', docker_image_name]).decode('utf-8').strip()
    for executable in executables:
        subprocess.run(['docker', 'container', 'cp', f'{docker_container_id}:/opt/patroni/{executable}', '.'])
        subprocess.run(['tar', '-cf', f'{executable}.tar', f'{executable}'])
        subprocess.run(['gzip', '-f', f'{executable}.tar'])
        subprocess.run(['mv', f'{executable}.tar.gz', f'{GIT_DIRECTORY}/ansible-playbooks/roles/patroni/files'])
        subprocess.run(['rm', '-fr', f'{executable}'])
    subprocess.run(['docker', 'container', 'rm', docker_container_id])
    subprocess.run(['docker', 'image', 'rm', docker_image_name])


def compile_postgresql(linux_flavor: str, postgresql_version: str) -> None:
    '''
    Compile PostgreSQL, a compilation takes places in a Docker container,
    a succesfull one results in a tarball being created in a respective
    Ansible role directory.
    '''
    build_arg_first: str = f'postgresql_version={postgresql_version}'
    if linux_flavor == 'Debian':
        dockerfile: str = f'{DOCKERFILES_DIRECTORY}/PostgreSQL-Debian'
    elif linux_flavor == 'RHEL':
        dockerfile: str = f'{DOCKERFILES_DIRECTORY}/PostgreSQL-RHEL'
    else:
        print(f'{linux_flavor} is irrelevant in this function')
    docker_image_name: str = 'postgresql-compiled:latest'
    executable: str = 'postgresql'
    subprocess.run(['docker', 'image', 'build', '-f', dockerfile, '-t', docker_image_name, '--build-arg', build_arg_first, '--no-cache', '.'])
    docker_container_id: str = subprocess.check_output(['docker', 'container', 'create', docker_image_name]).decode('utf-8').strip()
    subprocess.run(['docker', 'container', 'cp', f'{docker_container_id}:/usr/local/{executable}', '.'])
    subprocess.run(['tar', '-cf', f'{executable}.tar', f'{executable}'])
    subprocess.run(['gzip', '-f', f'{executable}.tar'])
    subprocess.run(['mv', f'{executable}.tar.gz', f'{GIT_DIRECTORY}/ansible-playbooks/roles/postgresql/files'])
    subprocess.run(['rm', '-fr', f'{executable}'])
    subprocess.run(['docker', 'container', 'rm', docker_container_id])
    subprocess.run(['docker', 'image', 'rm', docker_image_name])


def parse_cli_args() -> None:
    parser: argparse.ArgumentParser = argparse.ArgumentParser()
    parser.add_argument('action', help='compile or install', type=str)
    parser.add_argument('item', help='patroni, pgbackrest, postgresql', type=str)
    parser.add_argument('--docker_image_sha256', help='Patroni Docker image SHA256', type=str)
    parser.add_argument('--linux_flavor', help='Debian or RHEL', type=str)
    parser.add_argument('--postgresql_version', help='12.18, to illustrate', type=str)
    parser.add_argument('--python_version', help='3.10.3, for instance', type=str)
    args: argparse.Namespace = parser.parse_args()
    match args.action:
        case 'compile':
            match args.item:
                case 'patroni':
                    compile_patroni(args.docker_image_sha256, args.python_version)
                case 'postgresql':
                    compile_postgresql(args.linux_flavor, args.postgresql_version)
        case 'install':
            return 'install'
    


def compile_pgbackrest(linux_flavor: str, pgbackrest_version: str) -> None:
    '''
    Compile PgBackRest, download libraries it hinges on, a succesfull execution
    results in tarballs being created in a root directory.
    '''
    build_arg_first: str = f'version={pgbackrest_version}'
    if linux_flavor == 'Debian':
        dockerfile: str = f'{DOCKERFILES_DIRECTORY}/PgBackRest-Debian'
    elif linux_flavor == 'RHEL':
        dockerfile: str = f'{DOCKERFILES_DIRECTORY}/PgBackRest-RHEL'
    else:
        print('That Linux flavor is irrelevant here')
    docker_image_name: str = 'pgbackrest:latest'
    executable_with_libraries: tuple[str] = ('pgbackrest', 'libpq-13.11-1.el8.x86_64.rpm', 'libssh2-1.9.0-5.el8.hpc.x86_64.rpm')


def main() -> None:
    # compile_patroni('sha256:afc139a0a640942491ec481ad8dda10f2c5b753f5c969393b12480155fe15a63', '3.3.0', '3.12.3')
    parse_cli_args()


if __name__ == '__main__':
    main()
