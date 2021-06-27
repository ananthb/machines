set android_sdk ~/Android/Sdk
if test -d $android_sdk
  set -gx ANDROID_SDK $android_sdk
  fish_add_path $android_sdk/emulator $android_sdk/tools
end
