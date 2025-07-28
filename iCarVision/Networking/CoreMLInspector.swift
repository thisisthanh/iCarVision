import Foundation
import CoreML

class CoreMLInspector {
    static func inspectModels() {
        print("🔍 Inspecting CoreML Models...")
        
        // Inspect CarModelClassifier
        do {
            let carModelClassifier = try CarModelClassifier()
            print("📋 CarModelClassifier Output Description:")
            print(carModelClassifier.model.modelDescription)
            
            // Check output features
            for (key, feature) in carModelClassifier.model.modelDescription.outputDescriptionsByName {
                print("🔑 Output Key: \(key)")
                print("📊 Feature Type: \(feature.type)")
                if let multiArrayConstraint = feature.type as? MLMultiArrayConstraint {
                    print("📐 Shape: \(multiArrayConstraint.shape)")
                }
            }
        } catch {
            print("❌ Error inspecting CarModelClassifier: \(error)")
        }
        
        // Inspect CarColorClassifier
        do {
            let carColorClassifier = try CarColorClassifier()
            print("\n📋 CarColorClassifier Output Description:")
            print(carColorClassifier.model.modelDescription)
            
            // Check output features
            for (key, feature) in carColorClassifier.model.modelDescription.outputDescriptionsByName {
                print("🔑 Output Key: \(key)")
                print("📊 Feature Type: \(feature.type)")
                if let multiArrayConstraint = feature.type as? MLMultiArrayConstraint {
                    print("📐 Shape: \(multiArrayConstraint.shape)")
                }
            }
        } catch {
            print("❌ Error inspecting CarColorClassifier: \(error)")
        }
    }
} 