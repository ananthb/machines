# Coder Docker Template (Podman-backed)

This template provisions a Coder workspace as a Docker/Podman container and
starts the Coder agent inside it.

## Usage

1. From the Coder host (or your CLI with access), create a template:

```sh
coder templates create docker-podman --directory /home/ananth/src/machines/services/coder/templates/docker
```

2. Create a workspace from the template and select an image if desired.

## Notes

- Default runtime socket: `unix:///run/podman/podman.sock`.
- The container is labeled with workspace metadata for cleanup.
