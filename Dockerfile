# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=3.24
FROM alpine:${ALPINE_VERSION} AS base

LABEL org.opencontainers.image.source="https://github.com/skpr/image-opencode" \
      org.opencontainers.image.description="opencode AI coding agent image"

RUN apk --update --no-cache add \
  aws-cli \
  bash \
  ca-certificates \
  curl \
  git \
  github-cli \
  jq \
  less \
  make \
  openssh-client \
  patch \
  rsync \
  tar \
  vim \
  zip \
  # Build tools (for native npm packages e.g. sharp)
  g++ \
  python3 \
  autoconf \
  automake \
  libpng-dev \
  libtool \
  nasm \
  vips-dev \
  # Chromium (for chrome-devtools MCP)
  chromium \
  # Node.js LTS (for intelephense and MCP servers)
  nodejs \
  npm \
  # PHP 8.4 + extensions (for Intelephense LSP)
  php84 \
  php84-common \
  php84-curl \
  php84-dom \
  php84-fileinfo \
  php84-iconv \
  php84-intl \
  php84-mbstring \
  php84-openssl \
  php84-phar \
  php84-posix \
  php84-simplexml \
  php84-tokenizer \
  php84-xml \
  php84-xmlwriter \
  php84-zip

# Symlink php84 -> php so tools expecting `php` in PATH work correctly.
RUN ln -sf /usr/bin/php84 /usr/local/bin/php

# Install PHP language server and pnpm
RUN npm install -g intelephense pnpm

# Install opencode — use musl binaries for Alpine compatibility.
# TARGETARCH is set automatically by docker buildx: amd64 or arm64.
# OPENCODE_VERSION defaults to "latest" (resolves via GitHub API) but can be
# pinned to a specific release tag (e.g. v1.17.0) for stable builds.
ARG TARGETARCH
ARG OPENCODE_VERSION=latest
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") && \
    RESOLVED=$([ "$OPENCODE_VERSION" = "latest" ] && \
      curl -fsSL https://api.github.com/repos/anomalyco/opencode/releases/latest | jq -r '.tag_name' || \
      echo "$OPENCODE_VERSION") && \
    curl -fsSL \
      "https://github.com/anomalyco/opencode/releases/download/${RESOLVED}/opencode-linux-${ARCH}-musl.tar.gz" \
      | tar -xz -C /usr/local/bin/

RUN adduser -D -u 1000 skpr && \
    mkdir /data && chown skpr:skpr /data

# Opencode config
RUN mkdir -p /home/skpr/.config/opencode
COPY --chown=skpr:skpr config.json /home/skpr/.config/opencode/config.json
COPY --chown=skpr:skpr agents/ /home/skpr/.config/opencode/agents/

# Clone the PreviousNext skills repository.
# The token is passed via a BuildKit secret and never written to any image layer.
RUN --mount=type=secret,id=SKILLS_TOKEN \
    SKILLS_TOKEN=$(cat /run/secrets/SKILLS_TOKEN | tr -d '[:space:]') && \
    git clone \
      "https://x-access-token:${SKILLS_TOKEN}@github.com/previousnext/skills.git" \
      /home/skpr/.config/opencode/skills && \
    # Strip the remote URL so the token is not retained in the .git config
    git -C /home/skpr/.config/opencode/skills remote set-url origin https://github.com/previousnext/skills.git && \
    chown -R skpr:skpr /home/skpr/.config/opencode/skills

# Pre-create XDG dirs so named volumes are initialised with skpr ownership, not root.
RUN mkdir -p \
      /home/skpr/.local/share/opencode \
      /home/skpr/.local/state/opencode && \
    chown -R skpr:skpr /home/skpr/.local

# Ensure correct permissions for AWS credentials handling.
RUN mkdir -p /home/skpr/.aws && chown -R skpr:skpr /home/skpr/.aws

WORKDIR /data

USER skpr

# Run the test stage to verify the image.
FROM base AS test
COPY --from=ghcr.io/goss-org/goss:latest /usr/bin/goss /usr/bin/goss
COPY goss.yml /tmp/goss.yml
RUN goss --gossfile /tmp/goss.yml validate

# This is our run image.
FROM base AS run
ENTRYPOINT ["/bin/bash"]
