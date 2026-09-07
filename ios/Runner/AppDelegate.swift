import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // 1. Đăng ký tất cả các Plugin chính thức của Flutter
        GeneratedPluginRegistrant.register(with: self)

        // 2. Đăng ký Channel Native Dashcam thông qua Registrar chuẩn
        if let registrar = self.registrar(forPlugin: "DashcamRecorderPlugin") {
            DashcamRecorderPlugin.register(with: registrar)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

// 🟢 Tách riêng Plugin Handler để tránh xung đột Protocol với AppDelegate
class DashcamRecorderPlugin: NSObject, FlutterPlugin {
    private static let CHANNEL = "com.app.mycamapp/recorder"
    private var cameraManager: CameraNativeManager?

    init(registrar: FlutterPluginRegistrar) {
        self.cameraManager = CameraNativeManager(textureRegistry: registrar.textures())
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: registrar.messenger())
        let instance = DashcamRecorderPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let cameraManager = self.cameraManager else {
            result(FlutterError(code: "UNAVAILABLE", message: "CameraManager chưa sẵn sàng", details: nil))
            return
        }

        switch call.method {
        case "initializeCamera":
            cameraManager.initializeCamera { textureId in
                if let textureId = textureId {
                    result(textureId)
                } else {
                    result(FlutterError(code: "INIT_ERROR", message: "Khởi tạo Camera iOS thất bại", details: nil))
                }
            }

            // 🟢 Đã bỏ case "updateTelemetry" vì Native tự đọc tốc độ GPS
//        case "updateTelemetry":
//            if let args = call.arguments as? [String: Any],
//               let speed = args["speed"] as? Double {
//                cameraManager.updateTelemetry(speed: speed)
//            }
//            result(true)

        case "startRecording":
            if let args = call.arguments as? [String: Any],
               let path = args["path"] as? String {
                let success = cameraManager.startRecording(filePath: path)
                result(success)
            } else {
                result(FlutterError(code: "INVALID_PATH", message: "Đường dẫn không hợp lệ", details: nil))
            }

        case "stopRecording":
            cameraManager.stopRecording { success in
                result(success)
            }

        case "dispose":
            cameraManager.dispose()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
