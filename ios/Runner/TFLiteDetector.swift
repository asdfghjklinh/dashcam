
// Đây là xử lý theo kiểu: TFLiteDetector.swift
import Foundation
import AVFoundation
import UIKit
import TensorFlowLite

struct DetectedObject {
    let rect: CGRect
    let label: String
    let confidence: Float
    let distanceMeters: Float
}

class TFLiteDetector {
    private var interpreter: Interpreter?
    var onObjectsDetected: (([DetectedObject]) -> Void)?
    
    // Serial Queue chuyên biệt đảm bảo Thread-Safety cho TFLite
    private let processingQueue = DispatchQueue(label: "com.dashcam.tflite.processing", qos: .userInitiated)
    private var isProcessing = false
    
    private let focalLengthPixels: CGFloat = 1000.0
    private let realVehicleHeightMeters: CGFloat = 1.5
    
    // CIContext dùng chung để tránh leak bộ nhớ GPU/CPU
    private let ciContext: CIContext = {
        if #available(iOS 16.0, *) {
            return CIContext(options: [
                .useSoftwareRenderer: false,
                .cacheIntermediates: false
            ])
        } else {
            return CIContext(options: [.useSoftwareRenderer: false])
        }
    }()
    
    init() {
        setupTFLiteDynamic()
    }
    
    // 🟢 Tối ưu hoá việc chọn Delegate theo phiên bản iOS & Phần cứng
    private func setupTFLiteDynamic() {
        guard let modelPath = Bundle.main.path(forResource: "efficientdet_lite0", ofType: "tflite") else {
            print("⚠️ [TFLite] Không tìm thấy file efficientdet_lite0.tflite")
            return
        }
        
        var options = Interpreter.Options()
        var delegates: [Delegate] = []
        
        if #available(iOS 16.0, *) {
            // 1. Cấu hình Metal Options theo chuẩn API mới nhất
            var metalOptions = MetalDelegate.Options()
            metalOptions.isPrecisionLossAllowed = true // Tăng tốc GPU/ANE qua FP16
            metalOptions.waitType = .passive
            
            // 2. Khởi tạo MetalDelegate
            let metalDelegate = MetalDelegate(options: metalOptions)
            delegates.append(metalDelegate)
            print("🚀 [TFLite] Đã kích hoạt Metal GPU Delegate (iOS 16+ Mode)")
        } else {
            // iOS 15 Fallback: CPU Multi-threading
            options.threadCount = min(4, ProcessInfo.processInfo.activeProcessorCount)
            print("🛡️ [TFLite] Khởi chạy ở chế độ CPU Safe Mode (iOS 15 Fallback)")
        }
        
        // 3. Khởi tạo Interpreter
        do {
            interpreter = try Interpreter(modelPath: modelPath, options: options, delegates: delegates)
            try interpreter?.allocateTensors()
            print("✅ [TFLite] Đã khởi tạo Interpreter thành công")
        } catch {
            print("❌ [TFLite] Lỗi khởi tạo Interpreter: \(error)")
        }
    }
    
    // 🟢 HÀM XỬ LÝ FRAME ĐÃ ĐƯỢC SỬA LỖI TENSOR INDEX DỨT ĐIỂM
    func processFrame(pixelBuffer: CVPixelBuffer) {
        guard let interpreter = interpreter else { return }
        
        // Drop frame nếu frame trước chưa xử lý xong (Tránh nghẽn GPU/CPU)
        guard !isProcessing else { return }
        isProcessing = true
        
        processingQueue.async { [weak self] in
            defer { self?.isProcessing = false }
            guard let self = self else { return }
            
            // Trích xuất dữ liệu khung hình 320x320 [RGB]
            guard let inputData = self.extractRGBDataAdaptive(from: pixelBuffer, width: 320, height: 320) else {
                return
            }
            
            do {
                try interpreter.copy(inputData, toInputAt: 0)
                try interpreter.invoke()
                
                var detectedObjects: [DetectedObject] = []

                // 🟢 ĐOẠN ĐÃ SỬA: Tự động phân loại cấu trúc Output của Model TFLite
                if interpreter.outputTensorCount >= 4 {
                    // Chuẩn Legacy 4 Output Tensors (Locations, Classes, Scores, Count)
                    let locations = try interpreter.output(at: 0).data.toArray(type: Float32.self)
                    let classes = try interpreter.output(at: 1).data.toArray(type: Float32.self)
                    let scores = try interpreter.output(at: 2).data.toArray(type: Float32.self)
                    
                    let count = min(10, scores.count)
                    for i in 0..<count {
                        let confidence = scores[i]
                        if confidence > 0.4 {
                            let ymin = CGFloat(locations[i * 4 + 0])
                            let xmin = CGFloat(locations[i * 4 + 1])
                            let ymax = CGFloat(locations[i * 4 + 2])
                            let xmax = CGFloat(locations[i * 4 + 3])
                            
                            let rect = CGRect(x: xmin, y: ymin, width: xmax - xmin, height: ymax - ymin)
                            let classId = Int(classes[i])
                            let label = classId == 0 ? "Pedestrian" : "Vehicle"
                            let distance = Float((self.focalLengthPixels * self.realVehicleHeightMeters) / ((ymax - ymin) * 1080.0))
                            
                            detectedObjects.append(DetectedObject(
                                rect: rect,
                                label: label,
                                confidence: confidence,
                                distanceMeters: max(1.0, min(distance, 100.0))
                            ))
                        }
                    }
                } else {
                    // Chuẩn TFLite EfficientDet Mới (2 Output Tensors: Box+Score+Class gộp chung Tensor 0)
                    let boundingBoxesTensor = try interpreter.output(at: 0)
                    let rawData = boundingBoxesTensor.data.toArray(type: Float32.self)
                    
                    let numDetections = rawData.count / 6
                    for i in 0..<min(10, numDetections) {
                        let offset = i * 6
                        let confidence = rawData[offset + 4]
                        
                        if confidence > 0.4 {
                            let ymin = CGFloat(rawData[offset + 0])
                            let xmin = CGFloat(rawData[offset + 1])
                            let ymax = CGFloat(rawData[offset + 2])
                            let xmax = CGFloat(rawData[offset + 3])
                            
                            let rect = CGRect(x: xmin, y: ymin, width: xmax - xmin, height: ymax - ymin)
                            let classId = Int(rawData[offset + 5])
                            let label = classId == 0 ? "Pedestrian" : "Vehicle"
                            let distance = Float((self.focalLengthPixels * self.realVehicleHeightMeters) / ((ymax - ymin) * 1080.0))
                            
                            detectedObjects.append(DetectedObject(
                                rect: rect,
                                label: label,
                                confidence: confidence,
                                distanceMeters: max(1.0, min(distance, 100.0))
                            ))
                        }
                    }
                }
                
                // Trả kết quả về Callback
                self.onObjectsDetected?(detectedObjects)
                
            } catch {
                print("❌ [TFLite] Lỗi Invoke: \(error)")
            }
        }
    }
    
    // Pre-processing thích ứng
    private func extractRGBDataAdaptive(from pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> Data? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let scaleX = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let scaleY = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = self.ciContext.createCGImage(resizedImage, from: CGRect(x: 0, y: 0, width: width, height: height)) else {
            return nil
        }
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let cgContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Chuyển đổi định dạng UInt8 -> Float32 [320x320x3]
        var floatValues = [Float32](repeating: 0, count: width * height * 3)
        for i in 0..<(width * height) {
            floatValues[i * 3 + 0] = Float32(pixelData[i * 4 + 0]) / 255.0 // R
            floatValues[i * 3 + 1] = Float32(pixelData[i * 4 + 1]) / 255.0 // G
            floatValues[i * 3 + 2] = Float32(pixelData[i * 4 + 2]) / 255.0 // B
        }
        
        return Data(buffer: UnsafeBufferPointer(start: floatValues, count: floatValues.count))
    }
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            guard let baseAddress = $0.baseAddress else { return [] }
            let pointer = baseAddress.assumingMemoryBound(to: T.self)
            return Array(UnsafeBufferPointer(start: pointer, count: self.count / MemoryLayout<T>.size))
        }
    }
}
