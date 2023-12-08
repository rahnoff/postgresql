echo -e "Compiling PostgreSQL 12\n"

docker image build -f ../dockerfiles/PostgreSQL-Debian \
                   -t postgresql-binaries-all .

echo -e "\n"

echo -e "Copying postgresql directory"

docker container cp $(docker container create --name postgresql \
       postgresql-binaries-all:latest):/usr/local/postgresql .

tar -cvf postgresql.tar postgresql

gzip postgresql.tar

mv postgresql.tar.gz ../ansible-playbooks/roles/postgresql/files

rm -rf postgresql

echo -e "\n"

echo -e "Removing a container\n"

docker container rm postgresql

echo -e "\n"

echo -e "Removing an image\n"

docker image rm postgresql-binaries-all:latest
