import Foundation
import AVFoundation
import Flutter
import CoreMotion
import CoreLocation

class CameraNativeManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate, FlutterTexture {
    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var textureRegistry: FlutterTextureRegistry
    private var textureId: Int64 = -1
    
    private var currentPixelBuffer: CVPixelBuffer?
    private let visionDetector = TFLiteDetector()
    private let videoEncoder = MetalVideoEncoder()
    private let overlayRenderer = TelemetryOverlayRenderer()
    
    private var detectedObjects: [DetectedObject] = []
    
    // Cảm biến & Telemetry Data
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private var currentDeviceOrientation: AVCaptureVideoOrientation = .portrait
    private var currentTelemetry = TelemetryData()
    
    private var timestampTimer: Timer?
    private var recordingTimer: Timer?
    private var recordingSeconds: Int = 0
    private var isRecording = false
    
    init(textureRegistry: FlutterTextureRegistry) {
        self.textureRegistry = textureRegistry
        super.init()
        
        // 1. Nhận diện AI
        visionDetector.onObjectsDetected = { [weak self] objects in
            self?.detectedObjects = objects
        }
        
        // 2. Kích hoạt cảm biến Hướng, GPS & Đồng hồ
        setupSensorsAndGPS()
    }
    
    private func setupSensorsAndGPS() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data, let self = self else { return }
                let x = data.acceleration.x
                let y = data.acceleration.y
                
                var newOrientation: AVCaptureVideoOrientation = self.currentDeviceOrientation
                
                if abs(x) > abs(y) {
                    // 🟢 ĐỘC HƯỚNG CHUẨN CỦA GIA TỐC KẾ CẢM BIẾN IPHONE
                    if x < -0.3 {
                        newOrientation = .landscapeLeft
                    } else if x > 0.3 {
                        newOrientation = .landscapeRight
                    }
                } else {
                    if y > 0.3 {
                        newOrientation = .portraitUpsideDown
                    } else if y < -0.3 {
                        newOrientation = .portrait
                    }
                }
                
                if newOrientation != self.currentDeviceOrientation {
                    self.currentDeviceOrientation = newOrientation
                }
            }
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        timestampTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTelemetry.timestampString = formatter.string(from: Date())
        }
    }
    
    // Delegate GPS cập nhật Tốc độ & Tọa độ
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let speed = max(0, Int(location.speed * 3.6))
        self.currentTelemetry.speedKmH = speed
        self.currentTelemetry.latitude = location.coordinate.latitude
        self.currentTelemetry.longitude = location.coordinate.longitude
    }
    
    func initializeCamera(completion: @escaping (Int64?) -> Void) {
        self.captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("❌ [CameraNativeManager] Không tìm thấy Camera sau")
            completion(nil)
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue", qos: .userInitiated))
        
        if captureSession.canAddOutput(self.videoOutput) {
            captureSession.addOutput(self.videoOutput)
        }
        
        // Cố định Frame nhận từ Camera luôn luôn là Portrait
        if let connection = self.videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        self.captureSession.commitConfiguration()
        textureId = textureRegistry.register(self)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                completion(self.textureId)
            }
        }
    }
    
    // 🟢 1. Bắt đầu ghi hình
    func startRecording(filePath: String) -> Bool {
        let fileURL = URL(fileURLWithPath: filePath)
        let success = videoEncoder.startRecording(outputURL: fileURL, orientation: self.currentDeviceOrientation)
        
        if success {
            self.isRecording = true
            self.currentTelemetry.isRecording = true
            self.currentTelemetry.recordingDurationString = "00:00"
            self.recordingSeconds = 0
            
            DispatchQueue.main.async { [weak self] in
                self?.recordingTimer?.invalidate()
                self?.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.recordingSeconds += 1
                    let minutes = self.recordingSeconds / 60
                    let seconds = self.recordingSeconds % 60
                    self.currentTelemetry.recordingDurationString = String(format: "%02d:%02d", minutes, seconds)
                }
            }
            print("🎬 [CameraNativeManager] Bắt đầu ghi hình thành công: \(filePath)")
        }
        
        return success
    }
    
    // 🟢 2. Dừng ghi hình
    func stopRecording(completion: @escaping (Bool) -> Void) {
        self.isRecording = false
        
        DispatchQueue.main.async { [weak self] in
            self?.recordingTimer?.invalidate()
            self?.recordingTimer = nil
        }
        
        self.currentTelemetry.isRecording = false
        self.currentTelemetry.recordingDurationString = "00:00"
        self.recordingSeconds = 0
        
        videoEncoder.stopRecording { success in
            print(success ? "✅ [CameraNativeManager] Dừng ghi hình thành công" : "❌ [CameraNativeManager] Dừng ghi hình thất bại")
            completion(success)
        }
    }
    
    // 🟢 Callback xử lý từng Frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let rawPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // 1. Nhận diện AI
        visionDetector.processFrame(pixelBuffer: rawPixelBuffer)
        
        // 2. Render Overlay (Vẽ Bounding Box & Text xoay theo hướng cảm biến)
        let renderedPixelBuffer = overlayRenderer.renderOverlay(
            on: rawPixelBuffer,
            detectedObjects: self.detectedObjects,
            telemetry: self.currentTelemetry,
            orientation: self.currentDeviceOrientation
        ) ?? rawPixelBuffer
        
        self.currentPixelBuffer = renderedPixelBuffer
        
        // 3. Ghi hình bằng GPU Metal (Nếu đang Record)
        if isRecording {
            videoEncoder.encodeFrame(pixelBuffer: renderedPixelBuffer, timeStamp: timeStamp)
        }
        
        // 4. Cập nhật Flutter Preview
        textureRegistry.textureFrameAvailable(textureId)
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let pixelBuffer = currentPixelBuffer else { return nil }
        return Unmanaged.passRetained(pixelBuffer)
    }
    
    func dispose() {
        timestampTimer?.invalidate()
        recordingTimer?.invalidate()
        motionManager.stopAccelerometerUpdates()
        locationManager.stopUpdatingLocation()
        captureSession.stopRunning()
        if textureId != -1 {
            textureRegistry.unregisterTexture(textureId)
        }
    }
}
