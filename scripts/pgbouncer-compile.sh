echo -e "Compiling PgBouncer 1.20.0\n"

docker image build -f dockerfiles/Dockerfile-PgBouncer-Debian \
                   -t pgbouncer .

echo -e "\n"

echo -e "Copying pgbouncer binary and libraries"

docker container cp $(docker container create --name pgbouncer \
       pgbouncer:latest):/usr/local/bin/pgbouncer .

docker container cp pgbouncer:/usr/lib/x86_64-linux-gnu/libcares.so.2.4.2 .

docker container cp pgbouncer:/usr/lib/x86_64-linux-gnu/libevent-2.1.so.7.0.1 .

mv libcares.so.2.4.2 libcares.so.2

mv libevent-2.1.so.7.0.1 libevent-2.1.so.7

tar -cvf pgbouncer.tar pgbouncer libcares.so.2 libevent-2.1.so.7

gzip pgbouncer.tar

mv pgbouncer.tar.gz ansible-playbooks/roles/pgbouncer/files

rm -rf pgbouncer libcares.so.2 libevent-2.1.so.7

echo -e "\n"

echo -e "Removing a container\n"

docker container rm pgbouncer

echo -e "\n"

echo -e "Removing an image\n"

docker image rm pgbouncer:latest
