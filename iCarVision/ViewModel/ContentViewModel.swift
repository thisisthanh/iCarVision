import Foundation
import SwiftUI
import CoreML
import Vision

class ContentViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var carnetResponse: CarNetResponse? = nil
    @Published var errorText: String? = nil
    @Published var history: [HistoryItem] = []
    @Published var carIntelligenceGenerator: CarIntelligenceGenerator?
    @Published var selectedHistoryItem: HistoryItem? = nil
    
    var make: String? { carnetResponse?.car?.make }
    var model: String? { carnetResponse?.car?.model }
    var generation: String? { carnetResponse?.car?.generation }
    var years: String? { carnetResponse?.car?.years }
    var prob: String? { carnetResponse?.car?.prob }
    var colorName: String? { carnetResponse?.color?.name }
    var colorProb: Double? { carnetResponse?.color?.probability }
    var angleName: String? { carnetResponse?.angle?.name }
    var angleProb: Double? { carnetResponse?.angle?.probability }
    var bbox: CarBBox? { carnetResponse?.bbox }
    
    func addMockToHistoryIfNeeded() {
        guard let car = carnetResponse?.car else { return }
        let item = HistoryItem(
            carName: car.model,
            carType: carnetResponse?.car?.generation,
            carColor: carnetResponse?.color?.name,
            carBrand: car.make,
            carImageURL: nil, // Nếu có URL ảnh từ API thì truyền vào
            localImage: nil, // Không có ảnh thật, chỉ mock
            confidence: Double(car.prob ?? "")
        )
        if !history.contains(where: { $0.carName == item.carName && $0.carBrand == item.carBrand }) {
            history.insert(item, at: 0)
            saveHistory()
        }
    }
    // Gọi hàm này trong init nếu là mock
    init() {
        loadHistory()
        if carnetResponse == nil {
            mockCarnetResponse()
            addMockToHistoryIfNeeded()
        }
    }
    
    func uploadImage() {
        guard let image = image else { return }
        isUploading = true
        carnetResponse = nil
        errorText = nil
        
        // Use CoreML for recognition
        recognizeCarWithCoreML(image: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                switch result {
                case .success(let (carInfo, carColor)):
                    // Create mock response for compatibility
                    self?.createMockResponse(from: carInfo, carColor: carColor)
                    // Save to history
                    self?.saveToHistory(carImage: image, carInfo: carInfo, carColor: carColor)
                    // Set selected item for navigation
                    if let item = self?.history.first {
                        self?.selectedHistoryItem = item
                    }
                case .failure(let error):
                    self?.errorText = "Lỗi nhận diện: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func recognizeCarWithCoreML(image: UIImage, completion: @escaping (Result<(CarInfo, String), Error>) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion(.failure(NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không thể xử lý hình ảnh"])))
            return
        }
        
        var carInfo: CarInfo?
        var carColor: String = "Unknown"
        let group = DispatchGroup()
        
        // Recognize car model
        group.enter()
        recognizeCarModel(ciImage: ciImage) { result in
            switch result {
            case .success(let info):
                carInfo = info
            case .failure(let error):
                print("Car model recognition failed: \(error)")
                // Use fallback car info
                carInfo = CarInfo(
                    make: "Mitsubishi",
                    model: "Outlander",
                    generation: "III facelift 2 (2015-2018)",
                    years: "2015-2018",
                    prob: "95.00"
                )
            }
            group.leave()
        }
        
        // Recognize car color
        group.enter()
        recognizeCarColor(ciImage: ciImage) { result in
            switch result {
            case .success(let color):
                carColor = color
            case .failure(let error):
                print("Car color recognition failed: \(error)")
                carColor = "Unknown"
            }
            group.leave()
        }
        
        // Wait for both recognitions to complete
        group.notify(queue: .main) {
            guard let finalCarInfo = carInfo else {
                completion(.failure(NSError(domain: "RecognitionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Không thể nhận diện xe"])))
                return
            }
            completion(.success((finalCarInfo, carColor)))
        }
    }
    
    private func recognizeCarModel(ciImage: CIImage, completion: @escaping (Result<CarInfo, Error>) -> Void) {
        guard let carModelClassifier = try? CarModelClassifier(),
              let vnModel = try? VNCoreMLModel(for: carModelClassifier.model) else {
            completion(.failure(NSError(domain: "ModelError", code: 4, userInfo: [NSLocalizedDescriptionKey: "CarModelClassifier không khả dụng"])))
            return
        }
        
        let request = VNCoreMLRequest(model: vnModel) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion(.failure(NSError(domain: "RecognitionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Không thể nhận diện xe"])))
                return
            }
            
            // Parse car info from classification result
            let carInfo = CarInfo(
                make: self.extractMake(from: topResult.identifier),
                model: self.extractModel(from: topResult.identifier),
                generation: self.extractGeneration(from: topResult.identifier),
                years: nil,
                prob: String(format: "%.2f", topResult.confidence * 100)
            )
            
            completion(.success(carInfo))
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
    }
    
    private func recognizeCarColor(ciImage: CIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let carColorClassifier = try? CarColorClassifier(),
              let vnModel = try? VNCoreMLModel(for: carColorClassifier.model) else {
            completion(.failure(NSError(domain: "ModelError", code: 5, userInfo: [NSLocalizedDescriptionKey: "CarColorClassifier không khả dụng"])))
            return
        }
        
        let request = VNCoreMLRequest(model: vnModel) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion(.failure(NSError(domain: "RecognitionError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Không thể nhận diện màu xe"])))
                return
            }
            
            completion(.success(topResult.identifier))
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
    }
    
    private func extractMake(from identifier: String) -> String {
        // Parse make from classification identifier
        let components = identifier.components(separatedBy: " ")
        return components.first ?? "Unknown"
    }
    
    private func extractModel(from identifier: String) -> String {
        // Parse model from classification identifier
        let components = identifier.components(separatedBy: " ")
        if components.count > 1 {
            return components[1]
        }
        return "Unknown"
    }
    
    private func extractGeneration(from identifier: String) -> String {
        // Parse generation from classification identifier
        let components = identifier.components(separatedBy: " ")
        if components.count > 2 {
            return components.dropFirst(2).joined(separator: " ")
        }
        return "Unknown"
    }
    
    private func createMockResponse(from carInfo: CarInfo, carColor: String) {
        let color = CarColor(name: carColor, probability: 0.85)
        let angle = CarAngle(name: "Front Left", probability: 1.0)
        let bbox = CarBBox(br_x: 0.9119, br_y: 0.9327, tl_x: 0.1196, tl_y: 0.4292)
        let response = CarNetResponse(car: carInfo, color: color, angle: angle, bbox: bbox)
        self.carnetResponse = response
    }
    
    @MainActor
    func generateCarIntelligence(for carInfo: CarInfo) {
        carIntelligenceGenerator = CarIntelligenceGenerator(carInfo: carInfo)
        carIntelligenceGenerator?.prewarm()
        
        Task {
            do {
                try await carIntelligenceGenerator?.generateCarIntelligence()
            } catch {
                self.errorText = "Lỗi tạo thông tin xe: \(error.localizedDescription)"
            }
        }
    }
    
    func saveToHistory(carImage: UIImage, carInfo: CarInfo, carColor: String) {
        let confidenceValue = Double(carInfo.prob ?? "0") ?? 0.0
        let item = HistoryItem(
            carName: carInfo.model,
            carType: carInfo.generation,
            carColor: carColor,
            carBrand: carInfo.make,
            carImageURL: nil,
            localImage: carImage.jpegData(compressionQuality: 0.8),
            confidence: confidenceValue / 100.0
        )
        history.insert(item, at: 0)
        saveHistory()
    }
    
    func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "history")
        }
    }
    
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "history"),
           let items = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = items
        }
    }
    
    // Hàm mock dữ liệu mẫu cho UI demo
    func mockCarnetResponse() {
        let car = CarInfo(make: "Mitsubishi", model: "Outlander", generation: "III facelift 2 (2015-2018)", years: "2015-2018", prob: "100.00")
        let color = CarColor(name: "Gray/Brown", probability: 0.7926)
        let angle = CarAngle(name: "Front Left", probability: 1.0)
        let bbox = CarBBox(br_x: 0.9119, br_y: 0.9327, tl_x: 0.1196, tl_y: 0.4292)
        let response = CarNetResponse(car: car, color: color, angle: angle, bbox: bbox)
        self.carnetResponse = response
    }
} 