FROM alpine/git as source
RUN git clone https://github.com/moechs/dn42regsrv.git /source

ARG PROJECT_VERSION=1.0.0

FROM golang AS builder
ENV CGO_ENABLED=0 GO111MODULE=on
COPY --from=source /source /source
WORKDIR /source
RUN go build -trimpath -ldflags "-w -s -X 'main.Version=${PROJECT_VERSION}'" -o /dn42regsrv


FROM alpine/git
ENV AUTHTOKEN="secret"
ENV INTERVAL="60m"
ENV BRANCH="master"
WORKDIR /registry
EXPOSE 8042
COPY --from=source /source/StaticRoot /StaticRoot
COPY --from=builder /dn42regsrv /dn42regsrv
RUN git config --global --add safe.directory /registry
ENTRYPOINT ["/dn42regsrv", "-d", "/registry", "-s", "/StaticRoot", "-p", "${BRANCH}", "-t", "${AUTHTOKEN}", "-i", "${INTERVAL}"]



