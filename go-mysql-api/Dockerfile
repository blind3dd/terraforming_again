# Build stage
FROM golang:1.21.5-alpine3.19 AS builder

RUN apk add --no-cache git ca-certificates tzdata && \
    apk upgrade --no-cache

RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /opt/go-mysql-api
COPY go.mod go.sum ./

RUN go mod tidy && \
    go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd

# Since it is scratch we need to tak cale of certs,zoneinfo and openssl
FROM scratch 

# Import from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /opt/go-mysql-api/main /opt/go-mysql-api/main

# Create non-root user
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Set working directory
WORKDIR /opt/go-mysql-api

# Use non-root user
USER appuser
EXPOSE 8088

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/opt/go-mysql-api/main", "-health-check"] || exit 1

# Run the application
CMD ["/opt/go-mysql-api/main"]
