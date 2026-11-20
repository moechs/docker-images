ARG IMAGE_NAME=moechs/dn42regsrv
ARG IMAGE_VERSION=1.0.1

FROM alpine/git:2.54.1 AS source
RUN git clone https://github.com/moechs/dn42regsrv.git /source

FROM golang:1.27.4 AS builder
ARG IMAGE_VERSION
COPY --from=source /source /source
WORKDIR /source
RUN CGO_ENABLED=0 GO111MODULE=on go build -trimpath -ldflags "-w -s -X 'main.Version=${IMAGE_VERSION}'" -o /dn42regsrv

FROM alpine/git:2.54.1
COPY --from=source /source/StaticRoot /StaticRoot
COPY --from=builder /dn42regsrv /dn42regsrv
COPY entrypoint.sh /entrypoint.sh
WORKDIR /registry
RUN chmod 755 /entrypoint.sh \
    && addgroup -S registry \
    && adduser -S -D -H -h /registry -s /sbin/nologin -g registry -G registry registry
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8042
