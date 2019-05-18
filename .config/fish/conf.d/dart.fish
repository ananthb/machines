if test -d /usr/lib/dart/bin
  set -gx PATH /usr/lib/dart/bin $PATH
end
if test -d ~/.pub-cache/bin
  set -gx PATH ~/.pub-cache/bin $PATH
end
