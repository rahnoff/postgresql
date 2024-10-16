import subprocess


GIT_DIRECTORY: str = subprocess.check_output(['git', 'rev-parse', '--show-toplevel']).decode('utf-8').strip()
DOCKERFILES_DIRECTORY: str = f'{GIT_DIRECTORY}/dockerfiles'


def compile_patroni(docker_image_sha256: str,
                    patroni_version: str,
                    python_version: str) -> None:
    '''
    Compile Patroni and its CLI into single files with all defined dependencies
    bundled, a compilation takes places in a Docker container, a succesfull one
    results in tarballs being created in a root directory.
    '''
    build_arg_first: str = f'docker_image_sha256={docker_image_sha256}'
    build_arg_second: str = f'python_version={python_version}'
    dockerfile: str = f'{DOCKERFILES_DIRECTORY}/Patroni'
    executables: tuple[str] = ('patroni', 'patronictl')
    docker_image_name: str = 'patroni:latest'
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

# def parse_cli_args() -> None:


def main() -> None:
    compile_patroni('sha256:afc139a0a640942491ec481ad8dda10f2c5b753f5c969393b12480155fe15a63', '3.3.0', '3.12.3')


if __name__ == '__main__':
    main()
