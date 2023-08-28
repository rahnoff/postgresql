echo -e "Compiling PostgreSQL 12\n"

docker image build -t postgresql-binaries-all .

echo -e "\n"

echo -e "Copying pgsql directory"

docker container cp $(docker container create \
       postgresql-binaries-all:latest):/usr/local/pgsql .

echo -e "\n"

echo -e "Removing containers\n"

docker container rm $(docker container ls -aq)

echo -e "\n"

echo -e "Removing an image\n"

docker image rm postgresql-binaries-all:latest