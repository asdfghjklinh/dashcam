# 1. Tạo thư mục Assets
mkdir -p assets/models assets/sounds
mkdir -p android/app/src/main/assets

# 2. Tạo các thư mục Dart ở tầng Flutter (lib)
mkdir -p lib/core/constants \
         lib/core/services \
         lib/core/utils \
         lib/controllers \
         lib/providers \
         lib/screens \
         lib/widgets

touch lib/core/services/service_ad.dart \
      lib/core/services/service_iap.dart \
      lib/core/services/service_audio.dart \
      lib/controllers/controller_dashcam_native.dart \
      lib/providers/provider_ad.dart \
      lib/providers/provider_gps.dart \
      lib/providers/provider_settings.dart \
      lib/screens/screen_main_tab.dart \
      lib/screens/screen_dashcam_home.dart \
      lib/screens/screen_fullscreen.dart \
      lib/screens/screen_video_gallery.dart \
      lib/screens/screen_video_player.dart \
      lib/screens/screen_premium.dart \
      lib/screens/screen_settings.dart \
      lib/widgets/widget_camera_preview.dart \
      lib/widgets/widget_video_album.dart \
      lib/widgets/widget_banner_ad.dart \
      lib/core/constants/app_constants.dart

# 4. Tạo thư mục và file Native Android (Kotlin)
# (Lưu ý: Thay 'com/example/dashcam_app' bằng package_name tương ứng của bạn nếu khác)
PACKAGE_DIR="android/app/src/main/kotlin/hnit/nvh/dashcam"
mkdir -p $PACKAGE_DIR/camera $PACKAGE_DIR/gpu

touch $PACKAGE_DIR/camera/CameraNativeManager.kt
touch $PACKAGE_DIR/camera/MediaPipeDetector.kt
touch $PACKAGE_DIR/gpu/GpuVideoEncoder.kt
touch $PACKAGE_DIR/gpu/OpenGLRenderer.kt

# 5. Tạo các file Native iOS (Swift)
touch ios/Runner/CameraNativeManager.swift
touch ios/Runner/CoreMLVisionDetector.swift
touch ios/Runner/MetalVideoEncoder.swift