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

FROM minio/mc:latest

COPY --from=build /out/mc /usr/bin/mc
COPY --from=build /out/mc.sha256sum /usr/bin/mc.sha256sum

ENTRYPOINT ["mc"]
