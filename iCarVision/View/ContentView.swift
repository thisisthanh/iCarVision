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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel())
    }
}
