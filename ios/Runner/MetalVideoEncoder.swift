import Foundation
import AVFoundation
import CoreGraphics

class MetalVideoEncoder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isRecording = false
    private var startTimeStamp: CMTime?
    
    func startRecording(outputURL: URL, orientation: AVCaptureVideoOrientation) -> Bool {
        try? FileManager.default.removeItem(at: outputURL)
        
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            videoInput?.transform = transformForOrientation(orientation)
            
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: 1080,
                kCVPixelBufferHeightKey as String: 1920
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput!,
                sourcePixelBufferAttributes: attributes
            )
            
            if assetWriter?.canAdd(videoInput!) == true {
                assetWriter?.add(videoInput!)
            }
            
            assetWriter?.startWriting()
            self.startTimeStamp = nil
            self.isRecording = true
            print("🎬 [MetalVideoEncoder] Bắt đầu ghi hình...")
            return true
        } catch {
            print("❌ [MetalVideoEncoder] Lỗi khởi tạo AVAssetWriter: \(error)")
            return false
        }
    }
    
    func encodeFrame(pixelBuffer: CVPixelBuffer, timeStamp: CMTime) {
        guard isRecording,
              let videoInput = videoInput,
              videoInput.isReadyForMoreMediaData,
              let adaptor = pixelBufferAdaptor else { return }
        
        if startTimeStamp == nil {
            startTimeStamp = timeStamp
            assetWriter?.startSession(atSourceTime: .zero)
        }
        
        guard let start = startTimeStamp else { return }
        let frameTime = CMTimeSubtract(timeStamp, start)
        adaptor.append(pixelBuffer, withPresentationTime: frameTime)
    }
    
    func stopRecording(completion: @escaping (Bool) -> Void) {
        guard isRecording else {
            completion(false)
            return
        }
        
        isRecording = false
        videoInput?.markAsFinished()
        
        assetWriter?.finishWriting { [weak self] in
            let success = self?.assetWriter?.status == .completed
            print(success ? "✅ [MetalVideoEncoder] Xuất file MP4 thành công!" : "❌ [MetalVideoEncoder] Lỗi xuất file MP4")
            completion(success)
        }
    }
    
    // 🟢 SỬA CHUẨN MA TRẬN XOAY VIDEO
    // 🟢 ĐÃ SỬA: Transform chuẩn giữ nguyên hướng hình ảnh thực tế
    // 🟢 SỬA CHUẨN: Đảo ngược lại góc Transform để Video MP4 không bị chổng ngược 180°
    private func transformForOrientation(_ orientation: AVCaptureVideoOrientation) -> CGAffineTransform {
        switch orientation {
        case .landscapeLeft:
            // Đổi từ .pi / 2 thành -.pi / 2 để lật lại 180 độ cho video xem lại
            return CGAffineTransform(rotationAngle: -.pi / 2)
            
        case .landscapeRight:
            // Đổi từ -.pi / 2 thành .pi / 2
            return CGAffineTransform(rotationAngle: .pi / 2)
            
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: .pi)
            
        case .portrait:
            return CGAffineTransform.identity
            
        @unknown default:
            return CGAffineTransform.identity
        }
    }
}
