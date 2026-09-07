import CoreImage
import CoreGraphics
import UIKit
import CoreMotion
import AVFoundation

struct TelemetryData {
    var appName: String = "70mai"
    var timestampString: String = ""
    var speedKmH: Int = 0
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var isRecording: Bool = false
    var recordingDurationString: String = "00:00"
}

class TelemetryOverlayRenderer {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let fontName = "HelveticaNeue-Bold"
    private var pixelBufferPool: CVPixelBufferPool?
    
    func renderOverlay(
        on pixelBuffer: CVPixelBuffer,
        detectedObjects: [DetectedObject],
        telemetry: TelemetryData,
        orientation: AVCaptureVideoOrientation
    ) -> CVPixelBuffer? {
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let size = CGSize(width: width, height: height)
        
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1.0
        rendererFormat.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        
        let overlayImage = renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext
            
            // 1. Vẽ Bounding Box AI
            cgContext.setLineWidth(4.0)
            cgContext.setStrokeColor(UIColor(red: 0.0, green: 0.95, blue: 0.4, alpha: 1.0).cgColor)
            
            for object in detectedObjects {
                let rect = CGRect(
                    x: object.rect.origin.x * CGFloat(width),
                    y: object.rect.origin.y * CGFloat(height),
                    width: object.rect.size.width * CGFloat(width),
                    height: object.rect.size.height * CGFloat(height)
                )
                cgContext.addRect(rect)
                cgContext.strokePath()
            }
            
            // 2. Vẽ Text Telemetry
            drawTelemetryAndTimerText(
                cgContext: cgContext,
                size: size,
                telemetry: telemetry,
                orientation: orientation
            )
        }
        
        guard let overlayCGImage = overlayImage.cgImage else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let overlayCIImage = CIImage(cgImage: overlayCGImage)
        
        let combinedImage = overlayCIImage.composited(over: ciImage)
        
        if pixelBufferPool == nil {
            pixelBufferPool = makePixelBufferPool(width: width, height: height)
        }
        
        guard let pool = pixelBufferPool else { return nil }
        var outputPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &outputPixelBuffer)
        
        if let outputBuffer = outputPixelBuffer {
            context.render(combinedImage, to: outputBuffer)
            return outputBuffer
        }
        return nil
    }
    
    private func drawTelemetryAndTimerText(
        cgContext: CGContext,
        size: CGSize,
        telemetry: TelemetryData,
        orientation: AVCaptureVideoOrientation
    ) {
        let width = size.width
        let height = size.height
        let fontSize: CGFloat = 28.0
        
        let textShadow = NSShadow()
        textShadow.shadowColor = UIColor.black.withAlphaComponent(0.9)
        textShadow.shadowOffset = CGSize(width: 2.0, height: 2.0)
        textShadow.shadowBlurRadius = 4.0
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor.white,
            .shadow: textShadow
        ]
        
        cgContext.saveGState()
        
        // 🟢 ĐÃ SỬA: Đảo lại góc quay để Text vẽ đúng chiều xuôi trên Preview
        switch orientation {
        case .landscapeLeft:
            cgContext.translateBy(x: width, y: 0)
            cgContext.rotate(by: .pi / 2)
            drawLandscapeText(width: height, height: width, telemetry: telemetry, attributes: baseAttributes)
            
        case .landscapeRight:
            cgContext.translateBy(x: 0, y: height)
            cgContext.rotate(by: -.pi / 2)
            drawLandscapeText(width: height, height: width, telemetry: telemetry, attributes: baseAttributes)
            
        default: // Portrait
            drawPortraitText(width: width, height: height, telemetry: telemetry, attributes: baseAttributes)
        }
        
        cgContext.restoreGState()
    }
    
    private func drawLandscapeText(
        width: CGFloat,
        height: CGFloat,
        telemetry: TelemetryData,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let marginBottom: CGFloat = 40.0
        let lineHeight: CGFloat = 36.0
        let bottomY = height - marginBottom - lineHeight
        
        if telemetry.isRecording {
            let timerText = telemetry.recordingDurationString
            let attrTimer = NSAttributedString(string: timerText, attributes: attributes)
            attrTimer.draw(in: CGRect(x: 50.0, y: 50.0, width: 300.0, height: lineHeight))
        }
        
        let leftText = "\(telemetry.appName)  \(telemetry.timestampString)"
        let attrLeft = NSAttributedString(string: leftText, attributes: attributes)
        attrLeft.draw(in: CGRect(x: 50.0, y: bottomY, width: 450.0, height: lineHeight))
        
        let speedText = "\(telemetry.speedKmH) km/h"
        let attrSpeed = NSAttributedString(string: speedText, attributes: attributes)
        attrSpeed.draw(in: CGRect(x: (width - 160.0) / 2.0, y: bottomY, width: 160.0, height: lineHeight))
        
        let gpsText = formatGPS(lat: telemetry.latitude, lon: telemetry.longitude)
        let attrGPS = NSAttributedString(string: gpsText, attributes: attributes)
        attrGPS.draw(in: CGRect(x: width - 50.0 - 400.0, y: bottomY, width: 400.0, height: lineHeight))
    }
    
    private func drawPortraitText(
        width: CGFloat,
        height: CGFloat,
        telemetry: TelemetryData,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let marginBottom: CGFloat = 40.0
        let lineHeight: CGFloat = 36.0
        
        if telemetry.isRecording {
            let timerText = telemetry.recordingDurationString
            let attrTimer = NSAttributedString(string: timerText, attributes: attributes)
            attrTimer.draw(in: CGRect(x: 40.0, y: 50.0, width: 300.0, height: lineHeight))
        }
        
        let lines = [
            formatGPS(lat: telemetry.latitude, lon: telemetry.longitude),
            telemetry.timestampString,
            "\(telemetry.speedKmH) km/h",
            telemetry.appName
        ]
        
        for (index, lineText) in lines.enumerated() {
            let currentY = height - marginBottom - (CGFloat(index + 1) * lineHeight)
            let attrText = NSAttributedString(string: lineText, attributes: attributes)
            attrText.draw(in: CGRect(x: 40.0, y: currentY, width: width - 80.0, height: lineHeight))
        }
    }
    
    private func formatGPS(lat: Double, lon: Double) -> String {
        guard lat != 0.0 || lon != 0.0 else { return "105° 46.116' E, 21° 2.541' N" }
        let latRef = lat >= 0 ? "N" : "S"
        let lonRef = lon >= 0 ? "E" : "W"
        
        let absLat = abs(lat)
        let absLon = abs(lon)
        
        let latDeg = Int(absLat)
        let latMin = (absLat - Double(latDeg)) * 60.0
        
        let lonDeg = Int(absLon)
        let lonMin = (absLon - Double(lonDeg)) * 60.0
        
        return String(format: "%03d° %06.3f' %@, %02d° %06.3f' %@", lonDeg, lonMin, lonRef, latDeg, latMin, latRef)
    }
    
    private func makePixelBufferPool(width: Int, height: Int) -> CVPixelBufferPool? {
        var pool: CVPixelBufferPool?
        let poolAttributes: [String: Any] = [kCVPixelBufferPoolMinimumBufferCountKey as String: 12]
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pool)
        return pool
    }
}
