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
                "You are an expert automotive analyst specializing in car analysis and recommendations."
                
                "Your job is to provide comprehensive car intelligence for users."
                
                "Each analysis must include specifications, features, safety, market position, pros/cons, ownership experience, and recommendations."
                
                """
                Always focus on the specific car: \(carInfo.carName ?? "Unknown") \(carInfo.year ?? "")
                
                Provide accurate, practical information that helps buyers make informed decisions.
                
                Keep responses concise but comprehensive, focusing on the most important aspects.
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
            "Generate a comprehensive analysis for \(carInfo.carName ?? "this car") \(carInfo.year ?? "")."
            
            "Give it a clear title and detailed sections."
            
            "Focus on the most important aspects: specifications, features, safety, market position, pros/cons, ownership, and recommendations."
            
            "Keep information accurate, practical, and helpful for car buyers."
        }
        
        for try await partialResponse in stream {
            carIntelligence = partialResponse
        }
    }
    
    func prewarm() {
        session.prewarm()
    }
} 
