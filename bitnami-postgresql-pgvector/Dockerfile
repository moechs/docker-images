ARG PGVECTOR_TAG=v0.8.0
ARG PG_VERSION=14.8.0
FROM bitnami/git:2.48.1 AS git

ARG PGVECTOR_TAG
WORKDIR /workspace
RUN git clone https://github.com/pgvector/pgvector && cd pgvector && git checkout ${PGVECTOR_TAG}

ARG PG_MAJOR
FROM bitnami/postgresql:${PG_VERSION}

USER root
COPY --from=git /workspace/pgvector /tmp/pgvector
RUN apt-get update && \
		apt-mark hold locales && \
		apt-get install -y --no-install-recommends build-essential && \
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

USER 1001
