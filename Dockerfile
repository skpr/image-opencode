# syntax=docker/dockerfile:1
FROM alpine:3.24

RUN apk --update --no-cache add \
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
  php84-tokenizer \
  php84-xml \
  php84-zip

# Install PHP language server and pnpm
RUN npm install -g intelephense pnpm

# Install opencode — use musl binaries for Alpine compatibility.
# TARGETARCH is set automatically by docker buildx: amd64 or arm64.
ARG TARGETARCH
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") && \
    curl -fsSL \
      "https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-${ARCH}-musl.tar.gz" \
      | tar -xz -C /usr/local/bin/

RUN adduser -D -u 1000 skpr
RUN mkdir /data && chown skpr:skpr /data

# Opencode config
RUN mkdir -p /home/skpr/.config/opencode
COPY config.json /home/skpr/.config/opencode/config.json

# Clone the PreviousNext skills repository.
# The token is passed via a BuildKit secret and never written to any image layer.
RUN --mount=type=secret,id=SKILLS_TOKEN \
    git clone \
      "https://$(cat /run/secrets/SKILLS_TOKEN)@github.com/previousnext/skills.git" \
      /home/skpr/.config/opencode/skills && \
    # Strip the remote URL so the token is not retained in the .git config
    git -C /home/skpr/.config/opencode/skills remote set-url origin https://github.com/previousnext/skills.git

RUN chown -R skpr:skpr /home/skpr/.config

WORKDIR /data

USER skpr
