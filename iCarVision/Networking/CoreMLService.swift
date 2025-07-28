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
            
            // Process the prediction to extract make and model
            let (make, model) = self.processCarModelPrediction(topPrediction)
            
            let carInfo = CarInfo(
                make: make,
                model: model,
                generation: "N/A",
                years: "N/A",
                prob: String(format: "%.1f", confidence * 100)
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
    
    private func processCarModelPrediction(_ prediction: String) -> (make: String, model: String) {
        // Clean up the prediction text
        let cleanedPrediction = prediction
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by spaces and process
        let components = cleanedPrediction.components(separatedBy: " ")
        
        // Common car makes that should be kept together
        let commonMakes = [
            "Mercedes", "Benz", "Mercedes-Benz",
            "Alfa", "Romeo", "Alfa Romeo",
            "Land", "Rover", "Land Rover",
            "Rolls", "Royce", "Rolls Royce",
            "Aston", "Martin", "Aston Martin",
            "Range", "Rover", "Range Rover"
        ]
        
        // Try to identify make and model
        if components.count >= 2 {
            // Check for common two-word makes
            if components.count >= 3 {
                let firstTwo = "\(components[0]) \(components[1])"
                if commonMakes.contains(firstTwo) {
                    let make = firstTwo
                    let model = components.dropFirst(2).joined(separator: " ")
                    return (make: make, model: model.isEmpty ? "Unknown Model" : model)
                }
            }
            
            // Check for common three-word makes
            if components.count >= 4 {
                let firstThree = "\(components[0]) \(components[1]) \(components[2])"
                if commonMakes.contains(firstThree) {
                    let make = firstThree
                    let model = components.dropFirst(3).joined(separator: " ")
                    return (make: make, model: model.isEmpty ? "Unknown Model" : model)
                }
            }
            
            // Default: first word is make, rest is model
            let make = components[0]
            let model = components.dropFirst().joined(separator: " ")
            return (make: make, model: model.isEmpty ? "Unknown Model" : model)
        } else {
            // Single word - treat as make
            return (make: cleanedPrediction, model: "Unknown Model")
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
            
            // Process the color prediction to make it more readable
            let processedColor = self.processColorPrediction(topPrediction)
            
            let carColor = CarColor(
                name: processedColor,
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
    
    private func processColorPrediction(_ prediction: String) -> String {
        // Clean up the prediction text
        let cleanedPrediction = prediction
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        // Color mapping for better display
        let colorMapping: [String: String] = [
            "white": "White",
            "black": "Black",
            "red": "Red",
            "blue": "Blue",
            "green": "Green",
            "yellow": "Yellow",
            "orange": "Orange",
            "purple": "Purple",
            "pink": "Pink",
            "brown": "Brown",
            "gray": "Gray",
            "grey": "Gray",
            "silver": "Silver",
            "gold": "Gold",
            "beige": "Beige",
            "cream": "Cream",
            "navy": "Navy Blue",
            "maroon": "Maroon",
            "burgundy": "Burgundy",
            "teal": "Teal",
            "turquoise": "Turquoise",
            "lime": "Lime Green",
            "olive": "Olive Green",
            "tan": "Tan",
            "champagne": "Champagne",
            "bronze": "Bronze",
            "copper": "Copper"
        ]
        
        // Try to find a match in the color mapping
        for (key, value) in colorMapping {
            if cleanedPrediction.contains(key) {
                return value
            }
        }
        
        // If no match found, capitalize the first letter and return
        return cleanedPrediction.capitalized
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
