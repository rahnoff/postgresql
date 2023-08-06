FROM debian:bullseye-slim@sha256:0781db7f3f74866059cf161d145af0bc16fb13493b6e0f87ca20d7e34498d691
WORKDIR /src
RUN apt update && apt install -y curl gcc make libreadline-dev libsystemd-dev zlib1g-dev
RUN curl -O https://ftp.postgresql.org/pub/source/v12.0/postgresql-12.0.tar.gz
RUN curl -O https://ftp.postgresql.org/pub/source/v12.0/postgresql-12.0.tar.gz.md5
RUN md5sum --check postgresql-12.0.tar.gz.md5
RUN gunzip postgresql-12.0.tar.gz
RUN tar -xvf postgresql-12.0.tar
RUN postgresql-12.0/configure --with-systemd
RUN make world && make install