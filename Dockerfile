# ============================================================
# Stage 1: Build the picoclaw binary
# ============================================================
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git make

WORKDIR /src

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build
COPY . .
RUN make build

# ============================================================
# Stage 2: Minimal runtime image
# ============================================================
FROM alpine:3.23

RUN apk add --no-cache ca-certificates tzdata curl

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:18790/health || exit 1

# Copy binary
COPY --from=builder /src/build/picoclaw /usr/local/bin/picoclaw

# Create non-root user and group
RUN addgroup -g 1000 picoclaw && \
  adduser -D -u 1000 -G picoclaw picoclaw

# Create entrypoint script inline with Unix LF line endings (avoids Windows CRLF issues)
RUN printf '%s\n' \
  '#!/bin/sh' \
  'set -e' \
  'mkdir -p /home/picoclaw/.picoclaw' \
  'cat > /home/picoclaw/.picoclaw/config.json << _EOF_' \
  '{' \
  '  "agents": {' \
  '    "defaults": {' \
  '      "model_name": "mymodel",' \
  '      "workspace": "/home/picoclaw/.picoclaw/workspace",' \
  '      "max_tokens": 8192,' \
  '      "temperature": 0.7,' \
  '      "max_tool_iterations": 20' \
  '    }' \
  '  },' \
  '  "model_list": [' \
  '    {' \
  '      "model_name": "mymodel",' \
  '      "model": "${LLM_MODEL}",' \
  '      "api_key": "${LLM_API_KEY}"' \
  '    }' \
  '  ],' \
  '  "channels": {' \
  '    "telegram": {' \
  '      "enabled": true,' \
  '      "token": "${TELEGRAM_TOKEN}",' \
  '      "allow_from": [${TELEGRAM_ALLOW_FROM}]' \
  '    }' \
  '  },' \
  '  "tools": {' \
  '    "web": {' \
  '      "duckduckgo": { "enabled": true, "max_results": 5 }' \
  '    }' \
  '  }' \
  '}' \
  '_EOF_' \
  'exec picoclaw gateway' \
  > /home/picoclaw/docker-entrypoint.sh && \
  chmod +x /home/picoclaw/docker-entrypoint.sh

# Switch to non-root user
USER picoclaw

# Run onboard to create initial directories and config
RUN /usr/local/bin/picoclaw onboard

ENTRYPOINT ["/home/picoclaw/docker-entrypoint.sh"]
