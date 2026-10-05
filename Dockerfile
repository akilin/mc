FROM golang:1.24-alpine AS build

ARG TARGETOS=linux
ARG TARGETARCH=amd64

ENV GOPATH=/go
ENV CGO_ENABLED=0

WORKDIR /src

RUN apk add -U --no-cache ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN set -eux; \
	mkdir -p /out; \
	GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" go build -trimpath -o /out/mc; \
	sha256sum /out/mc > /out/mc.sha256sum

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS certs

RUN microdnf update --nodocs --assumeyes && microdnf install ca-certificates --nodocs --assumeyes

FROM registry.access.redhat.com/ubi9/ubi-micro:latest

COPY --from=certs /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/

COPY CREDITS /licenses/CREDITS
COPY LICENSE /licenses/LICENSE

COPY --from=build /out/mc /usr/bin/mc
COPY --from=build /out/mc.sha256sum /usr/bin/mc.sha256sum

ENTRYPOINT ["mc"]
