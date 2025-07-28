import Foundation
import FoundationModels
import Observation

@Generable
struct CarIntelligence: Equatable {
    @Guide(description: "A comprehensive title for the car model.")
    let title: String
    
    @Guide(description: "Key specifications including engine type, performance, fuel efficiency, and drivetrain.")
    let specifications: String
    
    @Guide(description: "Notable features including technology, interior/exterior design, and comfort features.")
    let features: String
    
    @Guide(description: "Safety aspects including ratings and key safety systems.")
    let safety: String
    
    @Guide(description: "Market position and typical competitors.")
    let marketPosition: String
    
    @Guide(description: "Pros and advantages for potential buyers.")
    let pros: String
    
    @Guide(description: "Cons and potential drawbacks for buyers.")
    let cons: String
    
    @Guide(description: "Real-world ownership impressions including reliability, maintenance, and resale value.")
    let ownership: String
    
    @Guide(description: "Summary recommendation: Who is this car best suited for?")
    let recommendation: String
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
                """
                You are an expert automotive analyst with in-depth knowledge of vehicle specifications, market positioning, and consumer needs.
                
                Based on the following car details:
                - Make: \(carInfo.make ?? "Unknown")
                - Model: \(carInfo.model ?? "Unknown")
                - Generation: \(carInfo.generation ?? "Unknown")
                - Years: \(carInfo.years ?? "Unknown")
                
                Please generate a well-structured and insightful overview that includes:
                1. Key specifications (engine type, performance, fuel efficiency, drivetrain).
                2. Notable features (technology, interior/exterior design, comfort).
                3. Safety aspects (ratings, key safety systems).
                4. Market position and typical competitors.
                5. Pros and cons for potential buyers.
                6. Real-world ownership impressions (reliability, maintenance, resale value).
                7. Summary recommendation: Who is this car best suited for?
                
                Focus on providing clear, objective, and practical insights that would help a car buyer or enthusiast make informed decisions.
                """
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
            
            Provide a detailed analysis covering:
            - Technical specifications and performance
            - Features and technology
            - Safety ratings and systems
            - Market positioning and competition
            - Pros and cons for buyers
            - Real-world ownership experience
            - Target audience recommendation
            
            Make the information practical, objective, and valuable for car buyers and enthusiasts.
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