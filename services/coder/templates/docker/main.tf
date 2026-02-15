terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.7.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.6.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_provisioner" "me" {}

data "coder_parameter" "image" {
  name         = "container_image"
  description  = "Container image to run for the workspace."
  type         = "string"
  default      = "codercom/example-universal:ubuntu"
  mutable      = true
  display_name = "Container Image"
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<-EOT
    set -e

    as_root() {
      if [ "$(id -u)" -eq 0 ]; then
        "$@"
      elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
      else
        "$@"
      fi
    }

    if ! command -v curl >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
      as_root apt-get update
      as_root apt-get install -y curl
    fi

    if [ ! -x /tmp/code-server/bin/code-server ]; then
      curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
    fi

    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    if ! command -v gh >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
      as_root apt-get update
      as_root apt-get install -y gh
    fi

    if ! command -v npm >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
      as_root apt-get update
      as_root apt-get install -y npm
    fi

    if command -v npm >/dev/null 2>&1 && ! command -v codex >/dev/null 2>&1; then
      if [ "$(id -u)" -eq 0 ]; then
        npm install -g @openai/codex
      elif command -v sudo >/dev/null 2>&1; then
        sudo npm install -g @openai/codex
      else
        npm install -g @openai/codex
      fi
    fi
  EOT
}

resource "coder_app" "terminal" {
  agent_id     = coder_agent.main.id
  slug         = "terminal"
  display_name = "Terminal"
  command      = "bash"
  icon         = "/icon/terminal.svg"
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"
}

resource "docker_container" "workspace" {
  name     = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
  image    = data.coder_parameter.image.value
  hostname = data.coder_workspace.me.name

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  entrypoint = ["sh", "-c", coder_agent.main.init_script]

  volumes {
    volume_name    = docker_volume.home.name
    container_path = "/home/coder"
  }

  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }

  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
}
