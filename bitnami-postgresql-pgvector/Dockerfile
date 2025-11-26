ARG PGVECTOR_TAG=v0.8.1
ARG PG_VERSION=17.6.0
FROM bitnamilegacy/git:2.51.0 AS git

ARG PGVECTOR_TAG
WORKDIR /workspace
RUN git clone https://github.com/pgvector/pgvector && cd pgvector && git checkout ${PGVECTOR_TAG}

ARG PG_MAJOR
FROM bitnamilegacy/postgresql:${PG_VERSION}

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
