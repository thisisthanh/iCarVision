//
//  ContentView.swift
//  iCarVision
//
//  Created by Thành Nguyễn on 21/7/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedTab = 0
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $selectedTab) {
                    RecognitionView(viewModel: viewModel)
                        .tag(0)
                        .tabItem {
                            VStack(spacing: 4) {
                                Image(systemName: selectedTab == 0 ? "camera.viewfinder" : "camera.viewfinder")
                                    .font(.system(size: 26, weight: .bold))
                                Text("Recognition")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    HistoryView(viewModel: viewModel)
                        .tag(1)
                        .tabItem {
                            VStack(spacing: 4) {
                                Image(systemName: selectedTab == 1 ? "clock.arrow.circlepath" : "clock.arrow.circlepath")
                                    .font(.system(size: 26, weight: .bold))
                                Text("History")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                }
            }
        }
    }
}

#Preview("Content View") {
    ContentView(viewModel: ContentViewModel())
}

#Preview("Content View - Dark Mode") {
    ContentView(viewModel: ContentViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Content View - With History") {
    let viewModel = ContentViewModel()
    viewModel.history = [
        HistoryItem(
            carName: "Outlander",
            carType: "III facelift 2 (2015-2018)",
            carColor: "Gray/Brown",
            carBrand: "Mitsubishi",
            carImageURL: nil,
            localImage: nil,
            confidence: 0.95
        ),
        HistoryItem(
            carName: "Civic",
            carType: "11th generation (2022-present)",
            carColor: "White",
            carBrand: "Honda",
            carImageURL: nil,
            localImage: nil,
            confidence: 0.87
        )
    ]
    return ContentView(viewModel: viewModel)
}
