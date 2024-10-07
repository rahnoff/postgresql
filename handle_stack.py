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

    executables: List[str] = ['patroni', 'patronictl']

    image_name: str = 'patroni:latest'
    
    command: str = f'''docker image build
        -f {dockerfile}
        -t patroni:latest
        --build-arg image_sha256={docker_image_sha256}
        --build-arg python_version={python_version}
        --no-cache
        .'''

    subprocess.run(['docker', 'image', 'build',
                    '-f',
                    dockerfile,
                    '-t',
                    image_name,
                    '--build-arg',
                    build_arg_first,
                    '--build-arg',
                    build_arg_second,
                    '--no-cache',
                    '.'])


def parse_input():


def main() -> None:
    compile_patroni('sha256:afc139a0a640942491ec481ad8dda10f2c5b753f5c969393b12480155fe15a63', '3.3.4', '3.12.3')

if __name__ == '__main__':
    main()
