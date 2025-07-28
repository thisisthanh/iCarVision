import Foundation
import UIKit

struct HistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let carName: String?
    let carType: String?
    let carColor: String?
    let carBrand: String?
    let carYear: String?
    let carImageURL: String?
    let localImage: Data? // Ảnh gốc do user chọn
    let confidence: Double?
    
    init(date: Date = Date(), carName: String?, carType: String?, carColor: String?, carBrand: String?, carYear: String?, carImageURL: String?, localImage: Data?, confidence: Double?) {
        self.id = UUID()
        self.date = date
        self.carName = carName
        self.carType = carType
        self.carColor = carColor
        self.carBrand = carBrand
        self.carYear = carYear
        self.carImageURL = carImageURL
        self.localImage = localImage
        self.confidence = confidence
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(carName)
        hasher.combine(carType)
        hasher.combine(carColor)
        hasher.combine(carBrand)
        hasher.combine(carYear)
        hasher.combine(carImageURL)
        hasher.combine(confidence)
        // Note: We don't hash localImage Data as it can be large and changes frequently
    }
    
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.carName == rhs.carName &&
               lhs.carType == rhs.carType &&
               lhs.carColor == rhs.carColor &&
               lhs.carBrand == rhs.carBrand &&
               lhs.carYear == rhs.carYear &&
               lhs.carImageURL == rhs.carImageURL &&
               lhs.confidence == rhs.confidence
    }
}
