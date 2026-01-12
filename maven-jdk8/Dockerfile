FROM moechs/jdk:8u202-20260111

ENV MAVEN_HOME=/usr/local/maven
ENV PATH=/usr/local/maven/bin:/usr/java/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

USER root

RUN dnf install -y maven openssh-clients git  \
    && mkdir -p /app/.m2 \
    && chown -R app:app /app \
    && rm -rf /var/cache/dnf/* /var/log/dnf.* /tmp/*

USER app

ENTRYPOINT ["/usr/local/maven/bin/mvn"]

CMD ["-v"]
