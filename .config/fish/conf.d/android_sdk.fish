if test -d ~/Android/Sdk
  set -gx ANDROID_SDK ~/Android/Sdk
  fish_add_path $ANDROID_SDK/emulator $ANDROID_SDK/tools
end
