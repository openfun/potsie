# Install required libraries
FROM golang:alpine3.18 AS builder

# Update installed packages
RUN apk -U upgrade

RUN apk add --no-cache git

# Install core dependencies
RUN go install github.com/google/go-jsonnet/cmd/jsonnet@latest && \
    go install github.com/google/go-jsonnet/cmd/jsonnet-lint@latest && \
    go install github.com/google/go-jsonnet/cmd/jsonnetfmt@latest && \
    go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest

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
