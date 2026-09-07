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
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── assets/
│               │   └── efficientdet_lite0.tflite
│               └── kotlin/com/example/dashcam_app/
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
│       ├── CoreMLVisionDetector.swift
│       └── MetalVideoEncoder.swift
├── lib/
│   ├── main.dart
│   ├── controllers/
│   │   └── dashcam_native_controller.dart
│   ├── providers/
│   │   ├── gps_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── camera_preview_screen.dart
│   │   ├── video_gallery_screen.dart
│   │   └── video_player_screen.dart
│   └── services/
│       └── audio_alert_service.dart
└── assets/
    ├── models/
    └── sounds/
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


