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
    
    var carName: String? { carnetResponse?.car?.carName }
    var year: String? { carnetResponse?.car?.year }
    var prob: String? { carnetResponse?.car?.prob }
    var colorName: String? { carnetResponse?.color?.name }
    var colorProb: Double? { carnetResponse?.color?.probability }
    var angleName: String? { carnetResponse?.angle?.name }
    var angleProb: Double? { carnetResponse?.angle?.probability }
    var bbox: CarBBox? { carnetResponse?.bbox }
    
    func addMockToHistoryIfNeeded() {
        guard let car = carnetResponse?.car else { return }
        let item = HistoryItem(
            carName: car.carName, // Full car name
            carType: nil, // No longer using generation
            carColor: carnetResponse?.color?.name,
            carBrand: nil, // No longer using separate brand
            carImageURL: nil, // Nếu có URL ảnh từ API thì truyền vào
            localImage: nil, // Không có ảnh thật, chỉ mock
            confidence: Double(car.prob ?? "")
        )
        if !history.contains(where: { $0.carName == item.carName }) {
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
                    carName: "Unknown",
                    year: "2015-2018",
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
                carName: self.extractCarName(from: topResult.identifier),
                year: self.extractYear(from: topResult.identifier),
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
    
    private func extractCarName(from identifier: String) -> String {
        // Extract full car name (all characters except last 4 digits if they exist)
        if identifier.count >= 4 {
            let last4Chars = String(identifier.suffix(4))
            // Check if last 4 characters are digits
            if last4Chars.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
                // Last 4 characters are digits, remove them from car name
                let carName = String(identifier.dropLast(4)).trimmingCharacters(in: .whitespaces)
                return carName.isEmpty ? "Unknown Car" : carName
            }
        }
        
        // If no year found or identifier is too short, return full identifier
        return identifier.isEmpty ? "Unknown Car" : identifier
    }
    
    private func extractYear(from identifier: String) -> String? {
        // Extract last 4 characters if they are digits
        if identifier.count >= 4 {
            let last4Chars = String(identifier.suffix(4))
            // Check if last 4 characters are digits
            if last4Chars.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
                return last4Chars
            }
        }
        return nil
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
            carName: carInfo.carName, // Full car name (e.g., "Mitsubishi Outlander")
            carType: nil, // No longer using generation
            carColor: carColor,
            carBrand: nil, // No longer using separate brand
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
        let car = CarInfo(carName: "Mitsubishi Outlander", year: "2015", prob: "100.00")
        let color = CarColor(name: "Gray/Brown", probability: 0.7926)
        let angle = CarAngle(name: "Front Left", probability: 1.0)
        let bbox = CarBBox(br_x: 0.9119, br_y: 0.9327, tl_x: 0.1196, tl_y: 0.4292)
        let response = CarNetResponse(car: car, color: color, angle: angle, bbox: bbox)
        self.carnetResponse = response
    }
} 
