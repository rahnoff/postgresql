if [ "$#" -lt 2 ]
then
	echo "Usage: `basename $0` Debian 12 or `basename $0` RHEL 14"
	echo -e "Debian or RHEL - Linux flavor, 12 or 14 - PostgreSQL version"
	exit 1
fi

flavor="$1"
version="$2"

echo -e "Compiling PostgreSQL $version\n"

docker image build --build-arg version="$version" \
                   -f ../dockerfiles/PostgreSQL-$flavor \
                   -t postgresql-binaries-all:latest .

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
