import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Lịch sử nhận diện")
                    .font(.largeTitle.bold())
                    .foregroundColor(.blue)
                    .padding(.top, 24)
                    .padding(.leading)
                if viewModel.history.isEmpty {
                    Spacer()
                    Text("Chưa có lịch sử nhận diện.")
                        .foregroundColor(.gray)
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(viewModel.history) { item in
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
                                            Text(String(format: "Độ tin cậy: %.1f%%", conf * 100))
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
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: ContentViewModel())
    }
} 