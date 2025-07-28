import Foundation
import FoundationModels
import Observation

@Generable
struct CarIntelligence: Equatable {
    @Guide(description: "A comprehensive title for the car model.")
    let title: String
    
    @Guide(description: "Detailed technical specifications of the car.")
    let specifications: String
    
    @Guide(description: "Key advantages and strengths of this car model.")
    let advantages: String
    
    @Guide(description: "Potential drawbacks or limitations of this car model.")
    let disadvantages: String
    
    @Guide(description: "Additional insights about the car's market position, reliability, or unique features.")
    let insights: String
}

@Observable
@MainActor
final class CarIntelligenceGenerator {
    private(set) var carIntelligence: CarIntelligence.PartiallyGenerated?
    private var session: LanguageModelSession
    var error: Error?
    
    let carInfo: CarInfo
    
    init(carInfo: CarInfo) {
        self.carInfo = carInfo
        self.session = LanguageModelSession(
            instructions: Instructions {
                "Your job is to generate intelligent, detailed information about cars."
                
                "You are an expert automotive analyst with deep knowledge of car specifications, market trends, and consumer insights."
                
                """
                Generate comprehensive information about the car based on:
                - Make: \(carInfo.make ?? "Unknown")
                - Model: \(carInfo.model ?? "Unknown")
                - Generation: \(carInfo.generation ?? "Unknown")
                - Years: \(carInfo.years ?? "Unknown")
                """
                
                "Provide accurate, factual information about specifications, features, and market positioning."
                
                "Focus on practical insights that would be valuable to car buyers and enthusiasts."
            }
        )
    }
    
    func generateCarIntelligence() async throws {
        let stream = session.streamResponse(
            generating: CarIntelligence.self,
            options: GenerationOptions(sampling: .greedy),
            includeSchemaInPrompt: false
        ) {
            """
            Generate comprehensive intelligence about the \(carInfo.make ?? "") \(carInfo.model ?? "") 
            from generation \(carInfo.generation ?? "") (\(carInfo.years ?? "")).
            
            Provide detailed specifications, advantages, disadvantages, and market insights.
            Make the information practical and valuable for car buyers.
            """
        }
        
        for try await partialResponse in stream {
            carIntelligence = partialResponse
        }
    }
    
    func prewarm() {
        session.prewarm()
    }
} 