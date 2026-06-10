variable "ALPINE_VERSION" {
  default = "3.24"
}

variable "OPENCODE_VERSION" {
  default = "latest"
}

variable "STREAM" {
  default = "latest"
}

variable "VERSION" {
  default = "v1"
}

variable "PLATFORMS" {
  type = list(string)
  default = [
    "linux/amd64",
    "linux/arm64",
  ]
}

variable "REGISTRIES" {
  default = ["ghcr.io"]
}

group "default" {
  targets = ["prod"]
}

target "test" {
  context   = "."
  target    = "test"
  platforms = ["linux/amd64"]

  args = {
    OPENCODE_VERSION = OPENCODE_VERSION
  }

  secret = [
    "id=SKILLS_TOKEN,env=SKILLS_TOKEN",
    "id=GITHUB_TOKEN,env=GH_TOKEN",
  ]
}

target "prod" {
  context   = "."
  target    = "run"
  platforms = PLATFORMS

  args = {
    ALPINE_VERSION   = ALPINE_VERSION
    OPENCODE_VERSION = OPENCODE_VERSION
  }

  # Pass the GitHub token for cloning the private skills repo.
  # The secret value is read from the SKILLS_TOKEN environment variable
  # and is never written to any image layer.
  secret = [
    "id=SKILLS_TOKEN,env=SKILLS_TOKEN",
    "id=GITHUB_TOKEN,env=GH_TOKEN",
  ]

  tags = [
    for r in REGISTRIES :
    "${r}/skpr/opencode:${VERSION}-${STREAM}"
  ]
}
