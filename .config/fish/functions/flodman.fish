function flodman
  if set -q CONTAINER_HOST
    set -e CONTAINER_HOST
  else
    set -gx CONTAINER_HOST "tcp://podman.internal:8080"
  end
end
