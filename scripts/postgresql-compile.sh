if [ "$#" -lt 2 ]
then
  echo "Usage: `basename $0` Debian 12 or `basename $0` RHEL 14"
  echo "Debian or RHEL - Linux flavor, 12 or 14 - PostgreSQL version"
  exit 1
fi

# linux_flavor="$1"

# postgresql_version="$2"

echo -e "Compiling PostgreSQL $2\n"

docker image build --build-arg version="$2" \
  -f ../dockerfiles/PostgreSQL-"$1" \
  -t postgresql-initialized:latest .

echo -e "\n"

echo -e "Copying /usr/local/postgresql and config files\n"

files_to_extract=("/usr/local/postgresql" "/var/lib/postgresql/pg_hba.conf" \
  "/var/lib/postgresql/pg_ident.conf" "/var/lib/postgresql/postgresql.conf")

for item in ${files_to_extract[@]}
do
  docker container cp $(docker container create \
    postgresql-initialized:latest):$item .
done

tar -cf postgresql.tar postgresql

tar -cf postgresql-conf.tar pg_hba.conf pg_ident.conf postgresql.conf

gzip postgresql.tar postgresql-conf.tar

mv postgresql.tar.gz ../ansible-playbooks/roles/postgresql/files

mv postgresql-conf.tar.gz ../ansible-playbooks/roles/postgresql/files

rm -rf postgresql pg_hba.conf pg_ident.conf postgresql.conf

echo -e "\n"

echo -e "Removing containers\n"

docker container rm $(docker container ls -a | \
  grep "postgresql-initialized:latest" | awk '{print $1}')

echo -e "\n"

echo -e "Removing an image\n"

docker image rm postgresql-initialized:latest
