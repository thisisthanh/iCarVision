import Foundation
import UIKit

struct CarNetResponse: Decodable {
    let car: CarInfo?
    let color: CarColor?
    let angle: CarAngle?
    let bbox: CarBBox?
}

struct CarInfo: Decodable {
    let carName: String?
    let year: String?
    let prob: String?
}

struct CarColor: Decodable {
    let name: String?
    let probability: Double?
}

struct CarAngle: Decodable {
    let name: String?
    let probability: Double?
}

struct CarBBox: Decodable {
    let br_x: Double?
    let br_y: Double?
    let tl_x: Double?
    let tl_y: Double?
}

enum Networking {
    static func uploadImage(image: UIImage, apiKey: String, completion: @escaping (Result<CarNetResponse, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Networking", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể chuyển ảnh thành dữ liệu"])) )
            return
        }
        let base64String = imageData.base64EncodedString()
        let url = URL(string: "https://api.carnet.ai/recognize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["image": base64String]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Networking", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không nhận được dữ liệu từ server."])) )
                return
            }
            do {
                let carnetResponse = try JSONDecoder().decode(CarNetResponse.self, from: data)
                completion(.success(carnetResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 
