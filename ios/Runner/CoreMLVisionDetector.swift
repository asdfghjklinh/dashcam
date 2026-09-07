// Đây là xử lý theo kiểu: CoreMLVisionDetector.swift
//import Foundation
//import Vision
//import CoreML
//
//struct DetectedObject {
//    let rect: CGRect
//    let label: String
//    let confidence: Float
//    let distanceMeters: Float
//}
//
//class CoreMLVisionDetector {
//    private var detectionRequest: VNCoreMLRequest?
//    var onObjectsDetected: (([DetectedObject]) -> Void)?
//
//    // Tiêu cự giả định (Calibrated Focal Length)
//    private let focalLengthPixels: CGFloat = 1000.0
//    // Chiều cao thực tế trung bình của Xe ô tô (1.5m)
//    private let realVehicleHeightMeters: CGFloat = 1.5
//
//    init() {
//        setupVision()
//    }
//
//    private func setupVision() {
//        // Dùng mô hình MobileNetV3 / YOLOv8 (.mlmodelc) được biên dịch sẵn
//        guard let modelURL = Bundle.main.url(forResource: "MobileNetV3", withExtension: "mlmodelc") ??
//            Bundle.main.url(forResource: "MobileNetV3", withExtension: "mlmodel"),
//              let visionModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
//            print("⚠️ [CoreML] Không tìm thấy file model MLModel trong iOS Bundle.")
//            return
//        }
//
//        detectionRequest = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
//            guard let self = self,
//                  let results = request.results as? [VNRecognizedObjectObservation] else { return }
//
//            var detectedObjects: [DetectedObject] = []
//
//            for observation in results {
//                let topCandidate = observation.labels.first
//                let label = topCandidate?.identifier ?? "Vehicle"
//                let confidence = topCandidate?.confidence ?? 0.0
//
//                if confidence > 0.4 {
//                    // Bounding Box chuẩn hóa (0.0 -> 1.0) từ Vision
//                    let boundingBox = observation.boundingBox
//
//                    // Tính khoảng cách theo công thức Pinhole: D = (f * H_real) / h_pixel
//                    // Chiều cao pixel tương đối = boundingBox.height
//                    let distance = Float((self.focalLengthPixels * self.realVehicleHeightMeters) / (boundingBox.height * 1080.0))
//
//                    let object = DetectedObject(
//                        rect: boundingBox,
//                        label: label,
//                        confidence: confidence,
//                        distanceMeters: max(1.0, min(distance, 100.0))
//                    )
//                    detectedObjects.append(object)
//                }
//            }
//
//            self.onObjectsDetected?(detectedObjects)
//        }
//
//        // Bắt buộc đẩy tính toán sang Apple Neural Engine (ANE)
//        detectionRequest?.preferBackgroundProcessing = true
//        detectionRequest?.imageCropAndScaleOption = .scaleFit
//    }
//
//    func processFrame(pixelBuffer: CVPixelBuffer) {
//        guard let request = detectionRequest else { return }
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
//        try? imageRequestHandler.perform([request])
//    }
//}
