# Skpr OpenCode Images

Docker image for running [OpenCode](https://opencode.ai) in local development environments.

Add this image to your project's Docker Compose setup to run OpenCode inside a container, scoped to your project — without access to your host's home directory, SSH keys, or environment variables.

## Streams

* `stable` - Production/stable upstream.
* `latest` - Recently merged changes.

## Images

Published to the GitHub Container Registry only. These are **private** packages —
you must authenticate to pull them.

```
ghcr.io/skpr/opencode:v1-stable
ghcr.io/skpr/opencode:v1-latest
```

### Authenticating to pull

Log in to GHCR with a GitHub token that has `read:packages` scope:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u <your-username> --password-stdin
```

## What's included

| Tool | Purpose |
|---|---|
| [OpenCode](https://opencode.ai) | AI coding assistant (latest musl binary) |
| Node.js | Runtime for MCP servers and LSP tools |
| [Intelephense](https://intelephense.com) | PHP language server |
| PHP 8.4 | PHP CLI + extensions for LSP analysis |
| Git, curl, make, rsync, patch | Standard dev utilities |
| bash, vim, jq, less, tar, zip | Shell and file utilities |
| Chromium | Browser for chrome-devtools MCP |
| openssh-client | SSH for git operations |
| g++, python3, autoconf, automake, nasm, vips-dev | Native build tools for npm packages (e.g. sharp) |

## MCP servers

The bundled `config.json` configures two MCP servers:

| Server | Type | Notes |
|---|---|---|
| `chrome-devtools` | local (`npx`) | Browser automation via Chromium |
| `jetbrains` | remote (SSE) | JetBrains IDE integration via `host.docker.internal:${JETBRAINS_MCP_PORT}` (default `64343`) |

## Usage

See `docker-compose.example.yml` for a complete example. The minimal setup:

```yaml
services:
  opencode:
    image: ghcr.io/skpr/opencode:v1-latest
    volumes:
      - .:/data
      - opencode-data:/home/skpr/.local/share/opencode
      - opencode-state:/home/skpr/.local/state/opencode
    environment:
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      JETBRAINS_MCP_PORT: ${JETBRAINS_MCP_PORT:-64343}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    stdin_open: true
    tty: true
    restart: unless-stopped

volumes:
  opencode-data:
  opencode-state:
```

> **JetBrains MCP:** The JetBrains MCP server only binds to `127.0.0.1` and validates the `Host`
> header. Use `caddy` on the host to reverse-proxy it so the container can reach it via
> `host.docker.internal` with the correct `Host` header.
>
> ```bash
> # Install
> brew install caddy   # macOS
> # or
> apt install caddy    # Linux
>
> # Run on the host before starting the container.
> # caddy listens on 64343 (JETBRAINS_MCP_PORT) and forwards to JetBrains MCP on 64342,
> # rewriting the Host header to 127.0.0.1:64342 as PhpStorm expects.
> # If 64343 is already in use, pick any free port and set JETBRAINS_MCP_PORT in your .env.
> caddy reverse-proxy --from :64343 --to 127.0.0.1:64342
> ```

Start the container in the background. It will restart automatically after a reboot:

```bash
docker compose up -d
```

Attach to the running container to open the opencode TUI:

```bash
docker attach $(docker compose ps -q opencode)
```

Detach without stopping the container with `Ctrl+P, Ctrl+Q`. Session history is persisted in the `opencode-data` named volume.

## Local builds

```bash
SKILLS_TOKEN=<github-token> PLATFORMS="linux/amd64" docker buildx bake
```

`SKILLS_TOKEN` requires read access to `previousnext/skills`. Generate one with `gh auth token` if you have access, or use a fine-grained PAT with `Contents: Read` on that repo.

## API keys

Pass your API key via a `.env` file (ensure it is in `.gitignore`) — do not bake it into the image:

```
ANTHROPIC_API_KEY=sk-ant-...
JETBRAINS_MCP_PORT=64343  # only needed if 64343 is already in use
```
