import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedItem: HistoryItem? = nil
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("History")
                    .font(.largeTitle.bold())
                    .foregroundColor(.blue)
                    .padding(.top, 24)
                    .padding(.leading)
                if viewModel.history.isEmpty {
                    Spacer()
                    Text("No history yet.")
                        .foregroundColor(.gray)
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(viewModel.history) { item in
                                Button(action: {
                                    selectedItem = item
                                    showDetail = true
                                }) {
                                    HStack(alignment: .center, spacing: 16) {
                                        if let data = item.localImage, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 70, height: 50)
                                                .cornerRadius(10)
                                                .shadow(radius: 2)
                                        } else if let urlStr = item.carImageURL, let url = URL(string: urlStr) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView().frame(width: 70, height: 50)
                                                case .success(let img):
                                                    img.resizable().scaledToFill().frame(width: 70, height: 50).cornerRadius(10)
                                                case .failure:
                                                    Image(systemName: "car.fill").resizable().scaledToFit().frame(width: 70, height: 50).foregroundColor(.gray)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        } else {
                                            Image(systemName: "car.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 70, height: 50)
                                                .foregroundColor(.gray)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.carName ?? "Unknown")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            if let type = item.carType, !type.isEmpty {
                                                Text(type)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let conf = item.confidence {
                                                Text(String(format: "Confidence: %.1f%%", conf * 100))
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        Spacer()
                                        Text(item.date, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.85))
                                    .cornerRadius(14)
                                    .shadow(color: .black.opacity(0.07), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .sheet(item: $selectedItem) { item in
                CarDetailSheet(item: item)
            }
        }
    }
}

struct CarDetailSheet: View {
    let item: HistoryItem
    @State private var carIntelligenceGenerator: CarIntelligenceGenerator?
    @State private var isLoadingIntelligence = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let data = item.localImage, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .cornerRadius(16)
            }
            Text(item.carName ?? "Unknown")
                .font(.title.bold())
                .foregroundColor(.blue)
            if let brand = item.carBrand {
                Text("Brand: \(brand)")
                    .font(.headline)
            }
            if let type = item.carType {
                Text("Generation: \(type)")
            }
            if let color = item.carColor {
                Text("Color: \(color)")
            }
            if let conf = item.confidence {
                Text(String(format: "Confidence: %.1f%%", conf * 100))
                    .foregroundColor(.blue)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Details : (Generated by Apple Intelligence)")
                    .font(.headline)
                
                if isLoadingIntelligence {
                    ProgressView("Generating car intelligence...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let intelligence = carIntelligenceGenerator?.carIntelligence {
                    CarIntelligenceView(intelligence: intelligence)
                } else {
                    Text("Tap to generate intelligent car information")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .onTapGesture {
                            generateCarIntelligence()
                        }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(24)
        .presentationDetents([.medium, .large])
        .onAppear {
            generateCarIntelligence()
        }
    }
    
    private func generateCarIntelligence() {
        guard let carName = item.carName,
              let carBrand = item.carBrand,
              let carType = item.carType else { return }
        
        let carInfo = CarInfo(
            make: carBrand,
            model: carName,
            generation: carType,
            years: nil,
            prob: nil
        )
        
        carIntelligenceGenerator = CarIntelligenceGenerator(carInfo: carInfo)
        isLoadingIntelligence = true
        
        Task {
            do {
                try await carIntelligenceGenerator?.generateCarIntelligence()
                await MainActor.run {
                    isLoadingIntelligence = false
                }
            } catch {
                await MainActor.run {
                    isLoadingIntelligence = false
                }
            }
        }
    }
}

struct CarIntelligenceView: View {
    let intelligence: CarIntelligence.PartiallyGenerated
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title = intelligence.title {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
                
                if let specifications = intelligence.specifications {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔹 Specifications")
                            .font(.headline)
                        Text(specifications)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                if let advantages = intelligence.advantages {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔸 Advantages")
                            .font(.headline)
                        Text(advantages)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                if let disadvantages = intelligence.disadvantages {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Disadvantages")
                            .font(.headline)
                        Text(disadvantages)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                if let insights = intelligence.insights {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Market Insights")
                            .font(.headline)
                        Text(insights)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: ContentViewModel())
    }
} 
