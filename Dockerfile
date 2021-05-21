# Install required libraries
FROM golang:alpine AS builder

# Update installed packages
RUN apk -U upgrade

RUN apk add --no-cache git

# Install core dependencies
RUN go get github.com/google/go-jsonnet/cmd/jsonnet && \
    go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb

# Install jsonnet bundles
COPY jsonnetfile.json jsonnetfile.lock.json /go/
RUN jb install

# Create image for dashboard generation
FROM alpine:latest

# Update installed packages
RUN apk -U upgrade

RUN apk add --no-cache \
     ca-certificates

WORKDIR /app

COPY --from=builder /go/vendor /app/vendor
COPY --from=builder /go/bin/* /usr/local/bin/

ENV JSONNET_PATH=/app/vendor
