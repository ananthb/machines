set android_sdk ~/Android/Sdk
if test -d $android_sdk
  set -gx ANDROID_SDK $android_sdk
  contains $android_sdk $fish_user_paths; or set -Ua fish_user_paths $android_sdk
  # fish 3.2.0: fish_add_path $android_sdk/emulator $android_sdk/tools
end
