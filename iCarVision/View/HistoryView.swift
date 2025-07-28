import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedItem: HistoryItem? = nil
    @State private var showDetail = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.08),
                            Color.purple.opacity(colorScheme == .dark ? 0.15 : 0.08)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    if viewModel.history.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                // Header section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recognition History")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                    
                                    Text("\(viewModel.history.count) car\(viewModel.history.count == 1 ? "" : "s") recognized")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // History items
                                ForEach(viewModel.history) { item in
                                    HistoryItemCard(
                                        item: item,
                                        onTap: {
                                            selectedItem = item
                                            showDetail = true
                                        }
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedItem) { item in
                CarDetailSheet(item: item)
            }
        }
    }
}

struct EmptyHistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .blue.opacity(0.6),
                            .purple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, options: .repeating)
            
            VStack(spacing: 12) {
                Text("No Recognition History")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Your car recognition history will appear here after you identify vehicles")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryItemCard: View {
    let item: HistoryItem
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                // Car image
                CarImageView(item: item)
                
                // Car details
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.carName ?? "Unknown Car")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let brand = item.carBrand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let conf = item.confidence {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(String(format: "%.0f%% confidence", conf * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Date and arrow
                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5),
                                lineWidth: 0.5
                            )
                    )
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}

struct CarImageView: View {
    let item: HistoryItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if let data = item.localImage, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let urlStr = item.carImageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 60)
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        CarPlaceholderView()
                    @unknown default:
                        CarPlaceholderView()
                    }
                }
            } else {
                CarPlaceholderView()
            }
        }
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

struct CarPlaceholderView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6),
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 60)
            .overlay(
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            )
    }
}

struct CarDetailSheet: View {
    let item: HistoryItem
    @State private var carIntelligenceGenerator: CarIntelligenceGenerator?
    @State private var isLoadingIntelligence = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Car image
            if let data = item.localImage, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
            
            // Car basic info
            VStack(spacing: 8) {
                Text(item.carName ?? "Unknown Car")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                
                if let brand = item.carBrand {
                    Text(brand)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                if let type = item.carType {
                    Text(type)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                
                if let color = item.carColor {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                        Text(color)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let conf = item.confidence {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(String(format: "%.0f%% confidence", conf * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Intelligence section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.blue)
                    Text("AI-Powered Analysis")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                if isLoadingIntelligence {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating intelligent car analysis...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                } else if let intelligence = carIntelligenceGenerator?.carIntelligence {
                    CarIntelligenceView(intelligence: intelligence)
                } else {
                    Button(action: generateCarIntelligence) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Generate AI Analysis")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        )
        .cornerRadius(24)
        .presentationDetents([.medium, .large])
        .onAppear {
            generateCarIntelligence()
        }
    }
    
    @MainActor
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
                isLoadingIntelligence = false
            } catch {
                isLoadingIntelligence = false
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
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                }
                
                if let specifications = intelligence.specifications {
                    IntelligenceCard(
                        title: "🔧 Specifications",
                        content: specifications,
                        color: .blue
                    )
                }
                
                if let features = intelligence.features {
                    IntelligenceCard(
                        title: "✨ Features",
                        content: features,
                        color: .purple
                    )
                }
                
                if let safety = intelligence.safety {
                    IntelligenceCard(
                        title: "🛡️ Safety",
                        content: safety,
                        color: .green
                    )
                }
                
                if let marketPosition = intelligence.marketPosition {
                    IntelligenceCard(
                        title: "📊 Market Position",
                        content: marketPosition,
                        color: .orange
                    )
                }
                
                HStack(spacing: 12) {
                    if let pros = intelligence.pros {
                        IntelligenceCard(
                            title: "✅ Pros",
                            content: pros,
                            color: .green
                        )
                    }
                    
                    if let cons = intelligence.cons {
                        IntelligenceCard(
                            title: "❌ Cons",
                            content: cons,
                            color: .red
                        )
                    }
                }
                
                if let ownership = intelligence.ownership {
                    IntelligenceCard(
                        title: "🏠 Ownership Experience",
                        content: ownership,
                        color: .indigo
                    )
                }
                
                if let recommendation = intelligence.recommendation {
                    IntelligenceCard(
                        title: "🎯 Recommendation",
                        content: recommendation,
                        color: .blue,
                        isHighlighted: true
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct IntelligenceCard: View {
    let title: String
    let content: String
    let color: Color
    var isHighlighted: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                
                Spacer()
                
                if isHighlighted {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(color)
                }
            }
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark 
                        ? color.opacity(0.15) 
                        : color.opacity(0.08)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            color.opacity(colorScheme == .dark ? 0.4 : 0.2),
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )
        )
        .shadow(
            color: colorScheme == .dark 
                ? color.opacity(0.2) 
                : color.opacity(0.1),
            radius: isHighlighted ? 8 : 4,
            x: 0,
            y: isHighlighted ? 4 : 2
        )
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: ContentViewModel())
    }
} 
