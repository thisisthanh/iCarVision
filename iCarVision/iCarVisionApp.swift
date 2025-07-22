//
//  iCarVisionApp.swift
//  iCarVision
//
//  Created by Thành Nguyễn on 21/7/25.
//

import SwiftUI

@main
struct iCarVisionApp: App {
    @StateObject var viewModel = ContentViewModel()
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "camera.viewfinder")
                        Text("Nhận diện")
                    }
                HistoryView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Lịch sử")
                    }
            }
        }
    }
}
