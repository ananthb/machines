if test -d ~/src/Android/Sdk
  set -gx ANDROID_SDK ~/src/Android/Sdk
  set -gx PATH $ANDROID_SDK/emulator $ANDROID_SDK/tools $PATH
end
