# 1. Tạo các thư mục cấu trúc theo Clean Architecture
mkdir -p assets/models assets/sounds assets/icons
mkdir -p lib/core/constants lib/core/utils lib/core/services
mkdir -p lib/features/dashcam/data/models lib/features/dashcam/data/datasources
mkdir -p lib/features/dashcam/presentation/controllers lib/features/dashcam/presentation/views lib/features/dashcam/presentation/widgets
mkdir -p lib/features/trip_history/data/models lib/features/trip_history/data/datasources
mkdir -p lib/features/trip_history/presentation/controllers lib/features/trip_history/presentation/views lib/features/trip_history/presentation/widgets
mkdir -p lib/features/settings/presentation/views lib/features/settings/presentation/widgets

# 2. Tạo các file cho module Core
touch lib/core/constants/app_colors.dart
touch lib/core/constants/distance_thresholds.dart
touch lib/core/utils/distance_calculator.dart
touch lib/core/utils/kalman_filter.dart
touch lib/core/utils/image_converter.dart
touch lib/core/services/audio_service.dart
touch lib/core/services/gps_service.dart

# 3. Tạo các file cho Feature Dashcam & AI
touch lib/features/dashcam/data/models/detection_result.dart
touch lib/features/dashcam/data/models/vehicle_distance.dart
touch lib/features/dashcam/data/datasources/tflite_service.dart
touch lib/features/dashcam/presentation/controllers/dashcam_controller.dart
touch lib/features/dashcam/presentation/views/dashcam_screen.dart
touch lib/features/dashcam/presentation/widgets/camera_preview_widget.dart
touch lib/features/dashcam/presentation/widgets/distance_overlay_widget.dart
touch lib/features/dashcam/presentation/widgets/speed_hud_widget.dart

# 4. Tạo các file cho Feature Trip History
touch lib/features/trip_history/presentation/views/history_screen.dart

# 5. Tạo các file cho Feature Settings
touch lib/features/settings/presentation/views/settings_screen.dart