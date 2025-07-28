import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var carnetResponse: CarNetResponse? = nil
    @Published var errorText: String? = nil
    @Published var history: [HistoryItem] = []
    @Published var carIntelligenceGenerator: CarIntelligenceGenerator?
    
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
        let apiKey = "<API_KEY>" // <-- Thay bằng API KEY thực tế
        isUploading = true
        carnetResponse = nil
        errorText = nil
        Networking.uploadImage(image: image, apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                switch result {
                case .success(let carnetResponse):
                    self?.carnetResponse = carnetResponse
                    // Generate car intelligence when we have car info
                    if let carInfo = carnetResponse.car {
                        self?.generateCarIntelligence(for: carInfo)
                    }
                    // Có thể lưu vào history nếu muốn
                case .failure(let error):
                    self?.errorText = "Lỗi: \(error.localizedDescription)"
                }
            }
        }
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
    
    func saveToHistory(carImage: UIImage) {
        let item = HistoryItem(
            carName: carnetResponse?.car?.model,
            carType: carnetResponse?.car?.generation,
            carColor: carnetResponse?.color?.name,
            carBrand: carnetResponse?.car?.make,
            carImageURL: nil, // Nếu có URL ảnh từ API thì truyền vào
            localImage: carImage.jpegData(compressionQuality: 0.8),
            confidence: Double(carnetResponse?.car?.prob ?? "")
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