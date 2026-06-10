#!/usr/bin/make -f

VERSION=v1
STREAM=latest
PLATFORMS="linux/amd64,linux/arm64"

# Example build command for local development.
# See Github Actions for multi-arch and multi-stream building.
# Requires a SKILLS_TOKEN env var with read access to previousnext/skills.
# In CI this is generated automatically via the GitHub App.
# Locally, generate one with: gh auth token  (if you have access)
# or use a fine-grained PAT with Contents:Read on previousnext/skills.
bake:
	VERSION=${VERSION} STREAM=${STREAM} PLATFORMS=${PLATFORMS} docker buildx bake

test:
	docker run --rm \
		-v .:/etc/cstest:ro \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		ghcr.io/googlecontainertools/container-structure-test:latest test \
		-c /etc/cstest/tests.yml \
		-i ghcr.io/skpr/opencode:${VERSION}-${STREAM}

.PHONY: *
