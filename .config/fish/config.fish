# Machine specific configuration goes in a folder named after the
# machine's hostname in the $XDG_CONFIG_HOME/fish directory 
if test -f ~/.config/fish/(hostname).fish
  source ~/.config/fish/(hostname).fish
end
