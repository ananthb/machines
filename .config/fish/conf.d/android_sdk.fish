if test -d ~/Android/Sdk
  set -gx ANDROID_SDK ~/Android/Sdk
  set -g fish_user_paths $ANDROID_SDK/emulator $ANDROID_SDK/tools $fish_user_paths
end
