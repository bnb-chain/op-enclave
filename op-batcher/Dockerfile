FROM --platform=$BUILDPLATFORM golang:1.22.6-alpine3.19 as builder

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=v0.0.0

RUN apk add --no-cache build-base libc-dev git make

WORKDIR /app

COPY . .

WORKDIR /app/op-batcher

RUN make op-batcher TARGETOS=$TARGETOS TARGETARCH=$TARGETARCH

FROM alpine:3.19

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/op-batcher/bin/op-batcher /usr/local/bin

ENTRYPOINT ["op-batcher"]