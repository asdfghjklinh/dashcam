import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dashcam/features/dashcam/data/models/detection_result.dart';

class MediaPipeDetector {
  ObjectDetector? _objectDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Tải mô hình Custom TFLite qua Google ML Kit
  Future<void> loadModel() async {
    try {
      // Sao chép model từ assets ra bộ nhớ máy để ML Kit đọc
      final modelPath = await _getModelPath('assets/models/efficientdet_lite0.tflite');

      final options = LocalObjectDetectorOptions(
        mode: DetectionMode.stream,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
        confidenceThreshold: 0.4,
      );

      _objectDetector = ObjectDetector(options: options);
      _isInitialized = true;
    } catch (e) {
      print('Lỗi khởi tạo MLKit Detector: $e');
    }
  }

  /// Nhận diện đối tượng trực tiếp từ InputImage của Camera Stream
  Future<List<DetectionResult>> detect(InputImage inputImage) async {
    if (!_isInitialized || _objectDetector == null) return [];

    try {
      final detectedObjects = await _objectDetector!.processImage(inputImage);
      List<DetectionResult> results = [];

      for (final obj in detectedObjects) {
        String labelName = 'Vehicle';
        double confidence = 0.0;

        if (obj.labels.isNotEmpty) {
          labelName = obj.labels.first.text;
          confidence = obj.labels.first.confidence;
        }

        results.add(
          DetectionResult(
            label: labelName,
            confidence: confidence,
            boundingBox: obj.boundingBox,
          ),
        );
      }
      return results;
    } catch (e) {
      print('Lỗi detect MLKit: $e');
      return [];
    }
  }

  /// Trích xuất đường dẫn file model từ Assets
  Future<String> _getModelPath(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.create(recursive: true);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
    }
    return file.path;
  }

  void dispose() {
    _objectDetector?.close();
    _isInitialized = false;
  }
}