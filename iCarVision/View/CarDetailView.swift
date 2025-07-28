import SwiftUI

struct CarDetailView: View {
    let item: HistoryItem
    @State private var carIntelligenceGenerator: CarIntelligenceGenerator?
    @State private var isLoadingIntelligence = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.08),
                            Color.purple.opacity(colorScheme == .dark ? 0.15 : 0.08),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 0) {
                            // Hero Image Section
                            HeroImageSection(item: item, geometry: geometry)

                            // Car Info Section
                            CarInfoSection(item: item)

                            // AI Analysis Section
                            AIAnalysisSection(
                                item: item,
                                carIntelligenceGenerator: $carIntelligenceGenerator,
                                isLoadingIntelligence: $isLoadingIntelligence
                            )
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Car Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* Share action */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
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

// MARK: - Hero Image Section

struct HeroImageSection: View {
    let item: HistoryItem
    let geometry: GeometryProxy
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image or placeholder
            if let data = item.localImage, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                    .clipped()
            } else {
                CarHeroPlaceholder()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
            }

            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.6),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geometry.size.height * 0.4)

            // Car name overlay
            VStack(alignment: .leading, spacing: 8) {
                Text(item.carName ?? "Unknown Car")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                if let brand = item.carBrand, !brand.isEmpty {
                    Text(brand)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

struct CarHeroPlaceholder: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6),
                    colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(.tertiary)

                Text("Car Image")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Car Info Section

struct CarInfoSection: View {
    let item: HistoryItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Stats Row - Only show if we have at least one piece of data
            if (item.confidence != nil && item.confidence! > 0) ||
                (item.carColor != nil && !item.carColor!.isEmpty) ||
                (item.carType != nil && !item.carType!.isEmpty) {
                HStack(spacing: 0) {
                    if let confidence = item.confidence, confidence > 0 {
                        let confidencePercentage = min(confidence, 1.0) * 100
                        let confidenceColor: Color = {
                            switch confidencePercentage {
                            case 90...100:
                                return .green
                            case 70..<90:
                                return .yellow
                            case 50..<70:
                                return .orange
                            default:
                                return .red
                            }
                        }()
                        
                        StatItem(
                            value: String(format: "%.0f%%", confidencePercentage),
                            label: "Confidence",
                            icon: "checkmark.circle.fill",
                            color: confidenceColor
                        )

                        if (item.carColor != nil && !item.carColor!.isEmpty) ||
                            (item.carType != nil && !item.carType!.isEmpty) {
                            Divider()
                                .frame(height: 40)
                                .padding(.horizontal, 20)
                        }
                    }

                    if let carColor = item.carColor, !carColor.isEmpty {
                        StatItem(
                            value: carColor,
                            label: "Color",
                            icon: "paintpalette.fill",
                            color: .blue
                        )

                        if item.carType != nil && !item.carType!.isEmpty && item.carType != "N/A" {
                            Divider()
                                .frame(height: 40)
                                .padding(.horizontal, 20)
                        }
                    }

                    if let carType = item.carType, !carType.isEmpty, carType != "N/A" {
                        StatItem(
                            value: carType.components(separatedBy: " ").first ?? carType,
                            label: "Generation",
                            icon: "number.circle.fill",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
                .padding(.horizontal, 20)
            }

            // Additional Info
            if let type = item.carType, type != "N/A" {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Generation Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    Text(type)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AI Analysis Section

struct AIAnalysisSection: View {
    let item: HistoryItem
    @Binding var carIntelligenceGenerator: CarIntelligenceGenerator?
    @Binding var isLoadingIntelligence: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .center, spacing: 2) {
                Text("AI-Powered Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Intelligent insights about this vehicle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }

        // Content
        if isLoadingIntelligence {
            LoadingIntelligenceView()
        } else if let intelligence = carIntelligenceGenerator?.carIntelligence {
            EnhancedCarIntelligenceView(intelligence: intelligence)
        } else {
            GenerateIntelligenceButton {
                generateIntelligence()
            }
        }
    }

    private func generateIntelligence() {
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

struct LoadingIntelligenceView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Animated loading icon
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())

                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("Analyzing Vehicle...")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Our AI is generating comprehensive insights about this car")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.05),
            radius: 12,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 20)
    }
}

struct GenerateIntelligenceButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Generate AI Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Get intelligent insights about this vehicle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground),
                                colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
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

// MARK: - Enhanced Car Intelligence View

struct EnhancedCarIntelligenceView: View {
    let intelligence: CarIntelligence.PartiallyGenerated
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            if let title = intelligence.title {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }

            LazyVStack(spacing: 16) {
                if let specifications = intelligence.specifications {
                    EnhancedIntelligenceCard(
                        title: "Specifications",
                        content: specifications,
                        color: .blue,
                        icon: "gearshape.fill"
                    )
                }

                if let features = intelligence.features {
                    EnhancedIntelligenceCard(
                        title: "Features",
                        content: features,
                        color: .purple,
                        icon: "star.fill"
                    )
                }

                if let safety = intelligence.safety {
                    EnhancedIntelligenceCard(
                        title: "Safety",
                        content: safety,
                        color: .green,
                        icon: "shield.fill"
                    )
                }

                if let marketPosition = intelligence.marketPosition {
                    EnhancedIntelligenceCard(
                        title: "Market Position",
                        content: marketPosition,
                        color: .orange,
                        icon: "chart.bar.fill"
                    )
                }

                // Pros and Cons side by side
                HStack(spacing: 12) {
                    if let pros = intelligence.pros {
                        EnhancedIntelligenceCard(
                            title: "Pros",
                            content: pros,
                            color: .green,
                            icon: "checkmark.circle.fill"
                        )
                    }

                    if let cons = intelligence.cons {
                        EnhancedIntelligenceCard(
                            title: "Cons",
                            content: cons,
                            color: .red,
                            icon: "xmark.circle.fill"
                        )
                    }
                }

                if let ownership = intelligence.ownership {
                    EnhancedIntelligenceCard(
                        title: "Ownership Experience",
                        content: ownership,
                        color: .indigo,
                        icon: "house.fill"
                    )
                }

                if let recommendation = intelligence.recommendation {
                    EnhancedIntelligenceCard(
                        title: "Recommendation",
                        content: recommendation,
                        color: .blue,
                        icon: "target",
                        isHighlighted: true
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct EnhancedIntelligenceCard: View {
    let title: String
    let content: String
    let color: Color
    let icon: String
    var isHighlighted: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)

                Spacer()

                if isHighlighted {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(color)
                        .symbolEffect(.bounce, options: .repeating)
                }
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(3)
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
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

// MARK: - Previews

#Preview("Car Detail View") {
    let sampleItem = HistoryItem(
        carName: "Outlander",
        carType: "III facelift 2 (2015-2018)",
        carColor: "Gray/Brown",
        carBrand: "Mitsubishi",
        carImageURL: nil,
        localImage: nil,
        confidence: 0.95
    )
    return CarDetailView(item: sampleItem)
}

#Preview("Car Detail View - Dark Mode") {
    let sampleItem = HistoryItem(
        carName: "Outlander",
        carType: "III facelift 2 (2015-2018)",
        carColor: "Gray/Brown",
        carBrand: "Mitsubishi",
        carImageURL: nil,
        localImage: nil,
        confidence: 0.30
    )
    return CarDetailView(item: sampleItem)
        .preferredColorScheme(.dark)
}

#Preview("Hero Image Section") {
    let sampleItem = HistoryItem(
        carName: "Outlander",
        carType: "III facelift 2 (2015-2018)",
        carColor: "Gray/Brown",
        carBrand: "Mitsubishi",
        carImageURL: nil,
        localImage: nil,
        confidence: 0.95
    )
    return GeometryReader { geometry in
        HeroImageSection(item: sampleItem, geometry: geometry)
    }
}

#Preview("Car Info Section") {
    let sampleItem = HistoryItem(
        carName: "Outlander",
        carType: "III facelift 2 (2015-2018)",
        carColor: "Gray/Brown",
        carBrand: "Mitsubishi",
        carImageURL: nil,
        localImage: nil,
        confidence: 0.95
    )
    return CarInfoSection(item: sampleItem)
}

#Preview("Loading Intelligence View") {
    LoadingIntelligenceView()
}

#Preview("Generate Intelligence Button") {
    GenerateIntelligenceButton {
        print("Generate tapped")
    }
}

#Preview("Enhanced Intelligence Card") {
    VStack(spacing: 16) {
        EnhancedIntelligenceCard(
            title: "🔧 Specifications",
            content: "The Mitsubishi Outlander features a 2.0L or 2.4L engine with CVT transmission. Available in both FWD and AWD configurations with excellent fuel efficiency.",
            color: .blue,
            icon: "gearshape.fill"
        )

        EnhancedIntelligenceCard(
            title: "🎯 Recommendation",
            content: "Perfect for families seeking a reliable, spacious SUV with good fuel economy and comfortable ride quality.",
            color: .blue,
            icon: "target",
            isHighlighted: true
        )
    }
    .padding()
}
