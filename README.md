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
| `jetbrains` | remote (SSE) | JetBrains IDE integration, host configured via `JETBRAINS_IDE_HOST` |

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
      JETBRAINS_IDE_HOST: ${JETBRAINS_IDE_HOST:-host.docker.internal}
    network_mode: "${OPENCODE_NETWORK_MODE:-}"
    stdin_open: true
    tty: true
    restart: unless-stopped

volumes:
  opencode-data:
  opencode-state:
```

> **macOS (Docker Desktop):** `host.docker.internal` is provided automatically — no extra config needed.
>
> **Linux:** PHPStorm binds to `127.0.0.1` only. Set the following in your `.env` file or shell:
> ```
> OPENCODE_NETWORK_MODE=host
> JETBRAINS_IDE_HOST=127.0.0.1
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
```
