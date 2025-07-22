import Foundation
import UIKit

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let carName: String?
    let carType: String?
    let carColor: String?
    let carBrand: String?
    let carImageURL: String?
    let localImage: Data? // Ảnh gốc do user chọn
    let confidence: Double?
    
    init(date: Date = Date(), carName: String?, carType: String?, carColor: String?, carBrand: String?, carImageURL: String?, localImage: Data?, confidence: Double?) {
        self.id = UUID()
        self.date = date
        self.carName = carName
        self.carType = carType
        self.carColor = carColor
        self.carBrand = carBrand
        self.carImageURL = carImageURL
        self.localImage = localImage
        self.confidence = confidence
    }
} 