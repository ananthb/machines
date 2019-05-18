# System
if set -q PREFIX then
  set -x XDG_DATA_DIRS $PREFIX/usr/share $PREFIX/usr/local/share
  set -x XDG_CONFIG_DIRS $PREFIX/etc/xdg
else
  set -x XDG_DATA_DIRS /usr/share /usr/local/share
  set -x XDG_CONFIG_DIRS /etc/xdg
end

# User
set -x XDG_CACHE_HOME ~/.cache
set -x XDG_CONFIG_HOME ~/.config
set -x XDG_DATA_HOME ~/.local/share
set -x XDG_DESKTOP_DIR ~/Desktop
set -x XDG_DOWNLOAD_DIR ~/Downloads
set -x XDG_DOCUMENTS_DIR ~/Documents
set -x XDG_MUSIC_DIR ~/Music
set -x XDG_PICTURES_DIR ~/Pictures
set -x XDG_VIDEOS_DIR ~/Videos
