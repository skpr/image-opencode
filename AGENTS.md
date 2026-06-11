# AGENTS.md

## Key files

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage image build (Alpine-based) |
| `docker-bake.hcl` | Multi-platform build config (`linux/amd64`, `linux/arm64`) |
| `goss.yml` | Smoke tests that run inside the `test` build stage |
| `config.json` | OpenCode config baked into the image at `/home/skpr/.config/opencode/config.json` |
| `agents/` | Custom OpenCode sub-agents baked into the image at `/home/skpr/.config/opencode/agents/` |

## Non-obvious details

**`/data` is a mount point**, not just a working directory. The host project is mounted there at runtime.

**The `test` stage is amd64-only.** The `prod` stage builds for both `linux/amd64` and `linux/arm64`.

**The `test` stage fails the build if goss exits non-zero.** The default image tag is `ghcr.io/skpr/opencode:v1-latest` (from `VERSION=v1` and `STREAM=latest` in `docker-bake.hcl`).

## BuildKit secret

`SKILLS_TOKEN` is required to clone the private `previousnext/skills` repo. It is passed as an env var and never written to any image layer:

```sh
SKILLS_TOKEN=ghp_... docker buildx bake test
```

In CI it is provided via a GitHub Actions secret.
