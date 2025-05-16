FROM --platform=$BUILDPLATFORM golang:1.22.6-alpine3.19 as builder

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=v0.0.0

RUN apk add --no-cache build-base libc-dev git make

WORKDIR /app

COPY . .

WORKDIR /app/op-proposer

RUN make op-proposer TARGETOS=$TARGETOS TARGETARCH=$TARGETARCH

FROM alpine:3.19

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/op-proposer/bin/op-proposer /usr/local/bin

ENTRYPOINT ["op-proposer"]