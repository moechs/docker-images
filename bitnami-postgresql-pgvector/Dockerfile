ARG IMAGE_NAME=moechs/bitnami-postgresql-pgvector
ARG IMAGE_VERSION=18.7.0

FROM alpine/git:2.54.1 AS git

WORKDIR /workspace
RUN git clone --branch master https://github.com/pgvector/pgvector.git

FROM moechs/bitnami-postgresql:18.7.0-debian-12-r4

USER root
COPY --from=git /workspace/pgvector /tmp/pgvector
RUN apt-get update && \
		apt-mark hold locales && \
		apt-get install -y --no-install-recommends build-essential && \
    deluser postgres && \
    groupadd -g 1001 postgres && \
    useradd -u 1001 -g 1001 -m -s /bin/bash postgres && \
		cd /tmp/pgvector && \
		make clean && \
		make OPTFLAGS="" && \
		make install && \
		mkdir /usr/share/doc/pgvector && \
		cp LICENSE README.md /usr/share/doc/pgvector && \
    cd /tmp && \
		rm -r /tmp/pgvector && \
		apt-get remove -y build-essential && \
		apt-get autoremove -y && \
		apt-mark unhold locales && \
		rm -rf /var/lib/apt/lists/*

USER postgres
