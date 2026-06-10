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
| [OpenCode](https://opencode.ai) | AI coding assistant (pinned musl binary) |
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
| `jetbrains` | remote (SSE) | JetBrains IDE integration via `host.docker.internal:64342` |

## Usage

See `docker-compose.example.yml` for a complete example. The minimal setup:

```yaml
services:
  opencode:
    image: ghcr.io/skpr/opencode:v1-latest
    volumes:
      - .:/data
    environment:
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    stdin_open: true
    tty: true
    profiles:
      - tools
```

> **Note:** `extra_hosts: host.docker.internal:host-gateway` is required on Linux for the
> JetBrains MCP server to reach the IDE on the host. Docker Desktop on macOS and Windows
> provides `host.docker.internal` automatically.

The `profiles: [tools]` key excludes the service from `docker compose up -d`. Launch the TUI on demand with:

```bash
docker compose run --rm opencode
```

## Local builds

```bash
SKILLS_TOKEN=<github-token> PLATFORMS="linux/amd64" docker buildx bake
```

`SKILLS_TOKEN` requires read access to `previousnext/skills`. Generate one with `gh auth token` if you have access, or use a fine-grained PAT with `Contents: Read` on that repo.

## API keys

Pass your API key as an environment variable at runtime — do not bake it into the image:

```bash
ANTHROPIC_API_KEY=sk-ant-... docker compose run opencode
```

Or add it to a `.env` file (ensure it is in `.gitignore`):

```
ANTHROPIC_API_KEY=sk-ant-...
```
