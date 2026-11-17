ARG PGVECTOR_TAG=master
ARG PG_VERSION=18.7.0-debian-12-r0
FROM alpine/git:latest AS git

ARG PGVECTOR_TAG
WORKDIR /workspace
RUN git clone --branch ${PGVECTOR_TAG} https://github.com/pgvector/pgvector.git

ARG PG_VERSION
FROM moechs/bitnami-postgresql:${PG_VERSION}

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
