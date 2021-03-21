set PLATFORMIO ~/.platformio

if test -d $PLATFORMIO
    set -gx PATH $PLATFORMIO/penv/bin $PATH
end
