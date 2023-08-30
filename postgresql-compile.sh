echo -e "Compiling PostgreSQL 12\n"

docker image build -f dockerfiles/Dockerfile-PostgreSQL-Debian \
                   -t postgresql-binaries-all .

echo -e "\n"

echo -e "Copying pgsql directory"

docker container cp $(docker container create --name postgresql \
       postgresql-binaries-all:latest):/usr/local/pgsql .

tar -cvf pgsql.tar pgsql

gzip pgsql.tar

mv pgsql.tar.gz ansible-playbooks/roles/postgresql/files

echo -e "\n"

echo -e "Removing a container\n"

docker container rm postgresql

echo -e "\n"

echo -e "Removing an image\n"

docker image rm postgresql-binaries-all:latest