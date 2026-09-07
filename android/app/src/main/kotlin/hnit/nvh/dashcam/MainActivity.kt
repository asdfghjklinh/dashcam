package com.app.dashcam

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.app.dashcam/recorder"

    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var isRecording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Đăng ký MethodChannel lắng nghe từ Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeCamera" -> {
                    try {
                        // 1. Tạo một Surface Texture trong Flutter Registry
                        textureEntry = flutterEngine.renderer.createSurfaceTexture()

                        val textureId = textureEntry?.id()

                        // TODO: Truyền textureEntry.surfaceTexture() vào CameraX / OpenGL Renderer
                        // Để Native tiến hành render luồng video kèm Bounding Box lên Texture này

                        if (textureId != null) {
                            // Trả về Texture ID cho Flutter để hiển thị bằng Widget Texture(textureId: id)
                            result.success(textureId)
                        } else {
                            result.error("UNAVAILABLE", "Khởi tạo Texture thất bại", null)
                        }
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", e.localizedMessage, null)
                    }
                }

                "updateTelemetry" -> {
                    val speed = call.argument<Double>("speed") ?: 0.0
                    val latitude = call.argument<Double>("latitude") ?: 0.0
                    val longitude = call.argument<Double>("longitude") ?: 0.0

                    // Cập nhật thông số vận tốc, vị trí vào OpenGL Renderer để vẽ Overlay
                    result.success(true)
                }

                "startRecording" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        // Kích hoạt MediaCodec nén trực tiếp luồng GPU ra file MP4
                        isRecording = true
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "Đường dẫn lưu file không hợp lệ", null)
                    }
                }

                "stopRecording" -> {
                    // Dừng MediaCodec
                    isRecording = false
                    result.success(true)
                }

                "dispose" -> {
                    textureEntry?.release()
                    textureEntry = null
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}