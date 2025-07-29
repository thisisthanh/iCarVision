import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedItem: HistoryItem? = nil
    @State private var showDetail = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
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
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedItem) { item in
                CarDetailView(item: item)
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
                            .purple.opacity(0.6),
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

    private func formatCarName(_ item: HistoryItem) -> String {
        let carName = item.carName ?? "Unknown Car"

        // Clean up car name
        if carName.lowercased() == "unknown" {
            return "Unknown Car"
        }

        return carName
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                // Car image
                CarImageView(item: item)

                // Car details
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatCarName(item))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let color = item.carColor, !color.isEmpty, color.lowercased() != "unknown" {
                        HStack(spacing: 4) {
                            Text("Color: \(color)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if let year = item.carYear, !year.isEmpty {
                        HStack(spacing: 4) {
                            Text(year)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let conf = item.confidence, conf > 0 {
                        let confidencePercentage = min(conf, 1.0) * 100
                        let confidenceColor: Color = {
                            switch confidencePercentage {
                            case 90 ... 100:
                                return .green
                            case 70 ..< 90:
                                return .yellow
                            case 50 ..< 70:
                                return .orange
                            default:
                                return .red
                            }
                        }()

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(confidenceColor)
                            Text(String(format: "%.0f%% confidence", confidencePercentage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Date and arrow
                VStack(alignment: .trailing, spacing: 4) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(item.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

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
                    case let .success(img):
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
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5),
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

#Preview("History View - Empty") {
    HistoryView(viewModel: ContentViewModel())
}

#Preview("History View - With Data") {
    let viewModel = ContentViewModel()
    viewModel.history = [
        HistoryItem(
            carName: "Outlander",
            carType: nil,
            carColor: "Gray/Brown",
            carBrand: "Mitsubishi",
            carYear: "2015",
            carImageURL: nil,
            localImage: nil,
            confidence: 0.95
        ),
        HistoryItem(
            carName: "Civic",
            carType: nil,
            carColor: "White",
            carBrand: "Honda",
            carYear: "2020",
            carImageURL: nil,
            localImage: nil,
            confidence: 0.87
        ),
        HistoryItem(
            carName: "Corolla",
            carType: nil,
            carColor: "Blue",
            carBrand: "Toyota",
            carYear: "2019",
            carImageURL: nil,
            localImage: nil,
            confidence: 0.92
        ),
    ]
    return HistoryView(viewModel: viewModel)
}

#Preview("History View - Dark Mode") {
    HistoryView(viewModel: ContentViewModel())
        .preferredColorScheme(.dark)
}
