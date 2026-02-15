variable "docker_host" {
  type        = string
  description = "Docker/Podman socket for the workspace runtime."
  default     = "unix:///run/podman/podman.sock"
}
