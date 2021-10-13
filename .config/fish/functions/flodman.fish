function flodman
  env CONTAINER_HOST="tcp://podman.internal:8080" podman --remote $argv
end
