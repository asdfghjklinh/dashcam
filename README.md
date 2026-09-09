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

```
dashcam_app/
├── assets/
│   ├── models/
│   └── sounds/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── assets/
│               │   └── efficientdet_lite0.tflite
│               └── kotlin/com/app/dashcam/
│                   ├── MainActivity.kt
│                   ├── camera/
│                   │   ├── CameraNativeManager.kt
│                   │   └── MediaPipeDetector.kt
│                   └── gpu/
│                       ├── GpuVideoEncoder.kt
│                       └── OpenGLRenderer.kt
├── ios/
│   └── Runner/
│       ├── AppDelegate.swift
│       ├── CameraNativeManager.swift
│       ├── MetalVideoEncoder.swift
│       ├── SceneDelegate.swift
│       ├── TFLiteDetector.swift
│       ├── TelemetryOverlayRenderer.swift
│       └── efficientdet_lite0.tflite
│
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/                  # App constants, UI colors, Theme
│   │   ├── services/
│   │   │   ├── service_ad.dart         # Quản lý 4 loại Ads (Open App, Banner, Interstitial, Rewarded)
│   │   │   ├── service_iap.dart        # Quản lý In-App Purchase / Premium status
│   │   │   └── service_audio.dart      # Cảnh báo âm thanh (Audio alert)
│   │   └── utils/
│   ├── controllers/
│   │   └── controller_dashcam_native.dart      # Điều khiển GPU/Native render
│   ├── providers/
│   │   ├── provider_ad.dart            # Trạng thái ẩn/hiện Ads dựa trên Premium
│   │   ├── provider_gps.dart           # Cập nhật tọa độ, tốc độ
│   │   └── provider_settings.dart      # Lưu cấu hình quay (Dọc/Ngang), Resolution...
│   ├── screens/
│   │   ├── screen_main_tab.dart        # Bottom Tabbar (Home, Premium, Settings)
│   │   ├── screen_dashcam_home.dart    # Màn hình chính (Preview + Video Album)
│   │   ├── screen_fullscreen.dart      # Màn hình xem Fullscreen (Quay Ngang hoặc Dọc)
│   │   ├── screen_video_gallery.dart   # Màn hình Album danh sách video
│   │   ├── screen_video_player.dart    # Màn hình xem lại video đã quay
│   │   ├── screen_premium.dart         # Màn hình mua gói Premium (IAP)
│   │   └── screen_settings.dart        # Màn hình cài đặt app
│   └── widgets/
│       ├── widget_camera_preview.dart  # Frame preview (Ngang/Dọc) hiển thị ở Home
│       ├── widget_video_album.dart     # Widget hiển thị danh sách video theo ngày
│       └── widget_banner_ad.dart       # Widget Banner Ad tái sử dụng nhiều nơi
```


### - Tầng Native Android (Kotlin):
* `MediaPipeDetector.kt`: Chạy mô hình `efficientdet_lite0.tflite` ở luồng Async để trả về Bounding Box $(x, y, w, h)$.
* `OpenGLRenderer.kt`: Vẽ hình ảnh Camera + đè các khung Bounding Box + khoảng cách + thông số GPS/Vận tốc trực tiếp lên GPU Texture.
* `GpuVideoEncoder.kt`: Nhận Texture từ OpenGL và đẩy vào `MediaCodec` nén thẳng thành `.mp4`.
* `CameraNativeManager.kt`: Quản lý lifecycle CameraX và cầu nối `MethodChannel` gửi `TextureID` lên Flutter.

### - Tầng Native iOS (Swift):
* `CoreMLVisionDetector.swift`: Gọi Apple Neural Engine (ANE) xử lý nhận diện vật thể bằng `Vision` + `CoreML`.
* `MetalVideoEncoder.swift`: Dùng Metal/CoreImage vẽ Overlay và nén bằng `AVAssetWriter`.
* `CameraNativeManager.swift`: Quản lý `AVCaptureSession` và tương tác với Flutter.

### - Tầng Flutter (Dart):
* `dashcam_native_controller.dart`: Gọi lệnh `initialize`, `startRecording`, `stopRecording` xuống Native.
* `camera_preview_screen.dart`: Chứa `Texture(textureId: id)` nhận luồng xem trực tiếp từ GPU Native và nút bấm Start/Stop.
* `gps_provider.dart`: Cung cấp vận tốc, tọa độ real-time để gửi xuống Native Renderer.


