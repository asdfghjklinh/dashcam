# 1. Tạo thư mục Assets
mkdir -p assets/models assets/sounds
mkdir -p android/app/src/main/assets

# 2. Tạo các thư mục Dart ở tầng Flutter (lib)
mkdir -p lib/controllers lib/providers lib/screens lib/services

# 3. Tạo các file Dart cần thiết
touch lib/controllers/dashcam_native_controller.dart
touch lib/providers/gps_provider.dart
touch lib/providers/settings_provider.dart
touch lib/screens/camera_preview_screen.dart
touch lib/screens/video_gallery_screen.dart
touch lib/screens/video_player_screen.dart
touch lib/services/audio_alert_service.dart

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