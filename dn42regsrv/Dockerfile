FROM alpine/git as source
RUN git clone https://github.com/moechs/dn42regsrv.git /source

ARG PROJECT_VERSION=1.0.0

FROM golang AS builder
ENV CGO_ENABLED=0 GO111MODULE=on
COPY --from=source /source /source
WORKDIR /source
RUN go build -trimpath -ldflags "-w -s -X 'main.Version=${PROJECT_VERSION}'" -o /dn42regsrv


FROM scratch
ENV PATH=/
WORKDIR /registry
EXPOSE 8042
COPY --from=source /source/StaticRoot /StaticRoot
COPY --from=builder /dn42regsrv /dn42regsrv

ENTRYPOINT ["/dn42regsrv", "-d", "/registry", "-s", "/StaticRoot"]



