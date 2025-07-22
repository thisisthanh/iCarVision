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
            ContentView(viewModel: viewModel)
        }
    }
}
