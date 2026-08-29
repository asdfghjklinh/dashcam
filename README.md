# dashcam

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


lib/
├── main.dart                   # File entry point (Khởi tạo dịch vụ, cấu hình app)
│
├── core/                       # Chứa mã nguồn dùng chung cho toàn bộ App (Shared/Global)
│   ├── constants/              # Khai báo hằng số (Màu sắc, mốc khoảng cách, âm thanh)
│   │   ├── app_colors.dart
│   │   └── distance_thresholds.dart    # Định nghĩa mức Safe/Warning/Danger theo tốc độ
│   ├── services/
│   │   ├── audio_service.dart             # Quản lý âm thanh cảnh báo (audioplayers)
│   │   └── gps_service.dart               # Quản lý Geolocator (Tốc độ, Tọa độ, Quãng đường)
│   └── utils/
│       ├── distance_calculator.dart       # Chứa duy nhất 1 công thức Pin-hole camera
│       └── kalman_filter.dart             # Làm mượt khoảng cách/tốc độ (tránh nhiễu/giật box)
│
├── features/
│   ├── dashcam/                           # Feature 1: Luồng quay & Cảnh báo ADAS
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── mlkit_detector.dart             # Khởi tạo ML Kit Object Detection (Đổi tên cho chuẩn)
│   │   │   └── models/
│   │   │       ├── detection_result.dart           # BoundingBox thô từ ML Kit
│   │   │       └── vehicle_distance.dart           # Object chứa Box + Mét + WarningLevel
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── dashcam_controller.dart         # Tổng hợp dữ liệu từ MLKit, GPS, Audio
│   │       ├── views/
│   │       │   └── dashcam_screen.dart             # Màn hình chính
│   │       └── widgets/
│   │           ├── camera_preview_widget.dart
│   │           ├── distance_overlay_widget.dart    # Vẽ khung & số mét đè lên video
│   │           └── speed_hud_widget.dart           # Hiển thị tốc độ xe
│   │
│   ├── trip_history/                      # Feature 2: Lưu vết chuyến đi
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   └── models/
│   │   │       └── trip_model.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── trip_controller.dart
│   │       ├── views/
│   │       │   └── history_screen.dart             # Chỉnh ngưỡng cảnh báo, độ nhạy GPS
│   │       └── widgets/
│   │
│   └── settings/
│       ├── data/
│       │   └── datasources/
│       │       └── settings_local_datasource.dart # SharedPreferences
│       └── presentation/
│           ├── controllers/
│           │   └── settings_controller.dart
│           └── views/
│               └── settings_screen.dart
│
└── assets/                     # Nằm ngoài lib/ (Khai báo trong pubspec.yaml)
    ├── models/                 # Thư mục chứa file AI
    │   └── license_plate_yolov8n.tflite
    ├── sounds/                 # Thư mục chứa còi cảnh báo
    │   ├── warning_yellow.mp3
    │   └── alert_red.mp3
    └── icons/