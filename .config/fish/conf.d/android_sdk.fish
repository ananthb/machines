if test -d ~/Android/Sdk
  set -gx ANDROID_SDK ~/Android/Sdk
  set -gx PATH $ANDROID_SDK/emulator $ANDROID_SDK/tools $PATH
end
