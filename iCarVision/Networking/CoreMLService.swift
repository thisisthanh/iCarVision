import Foundation
import CoreML
import Vision
import UIKit
import CoreImage

class CoreMLService {
    private var carModelClassifier: CarModelClassifier?
    private var carColorClassifier: CarColorClassifier?
    
    init() {
        loadModels()
    }
    
    private func loadModels() {
        do {
            carModelClassifier = try CarModelClassifier()
            carColorClassifier = try CarColorClassifier()
        } catch {
            print("Error loading CoreML models: \(error)")
        }
    }
    
    func classifyCar(image: UIImage, completion: @escaping (Result<CarNetResponse, Error>) -> Void) {
        guard let carModelClassifier = carModelClassifier,
              let carColorClassifier = carColorClassifier else {
            completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Models not loaded"])))
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])))
            return
        }
        
        // Convert CGImage to CVPixelBuffer
        guard let pixelBuffer = cgImage.toCVPixelBuffer() else {
            completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to pixel buffer"])))
            return
        }
        
        // Classify car model
        classifyCarModel(pixelBuffer: pixelBuffer, classifier: carModelClassifier) { [weak self] result in
            switch result {
            case .success(let carResult):
                // Classify car color
                self?.classifyCarColor(pixelBuffer: pixelBuffer, classifier: carColorClassifier) { colorResult in
                    switch colorResult {
                    case .success(let color):
                        let response = CarNetResponse(
                            car: carResult,
                            color: color,
                            angle: nil, // CoreML doesn't provide angle info
                            bbox: nil   // CoreML doesn't provide bbox info
                        )
                        completion(.success(response))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func classifyCarModel(pixelBuffer: CVPixelBuffer, classifier: CarModelClassifier, completion: @escaping (Result<CarInfo, Error>) -> Void) {
        guard let vnModel = try? VNCoreMLModel(for: classifier.model) else {
            completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create VNCoreMLModel"])))
            return
        }
        
        let request = VNCoreMLRequest(model: vnModel) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid classification results"])))
                return
            }
            
            guard let topResult = results.first else {
                completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No classification results"])))
                return
            }
            
            // Parse the prediction result
            let topPrediction = topResult.identifier
            let confidence = Double(topResult.confidence)
            
            // Split the prediction to extract make and model
            let components = topPrediction.components(separatedBy: " ")
            let make = components.first ?? "Unknown"
            let model = components.dropFirst().joined(separator: " ")
            
            let carInfo = CarInfo(
                make: make,
                model: model,
                generation: "N/A",
                years: "N/A",
                prob: String(format: "%.2f", confidence * 100)
            )
            
            completion(.success(carInfo))
        }
        
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    private func classifyCarColor(pixelBuffer: CVPixelBuffer, classifier: CarColorClassifier, completion: @escaping (Result<CarColor, Error>) -> Void) {
        guard let vnModel = try? VNCoreMLModel(for: classifier.model) else {
            completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create VNCoreMLModel"])))
            return
        }
        
        let request = VNCoreMLRequest(model: vnModel) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid classification results"])))
                return
            }
            
            guard let topResult = results.first else {
                completion(.failure(NSError(domain: "CoreMLService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No classification results"])))
                return
            }
            
            let topPrediction = topResult.identifier
            let confidence = Double(topResult.confidence)
            
            let carColor = CarColor(
                name: topPrediction,
                probability: confidence
            )
            
            completion(.success(carColor))
        }
        
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
}

// Extension to convert CGImage to CVPixelBuffer
extension CGImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let width = self.width
        let height = self.height
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
} 
