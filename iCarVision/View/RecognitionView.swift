import SwiftUI

struct RecognitionView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceActionSheet = false
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 4)
                            Text("iCarVision AI")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .shadow(color: .blue.opacity(0.15), radius: 2)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        
                        // Ảnh
                        ZStack {
                            if viewModel.isUploading && viewModel.image == nil {
                                // Animated gradient border khi đang chờ API
                                GeometryReader { geo in
                                    ZStack {
                                        Image("2001 Acura CL Series S_00n0n_lvm1Irhg4DP_600x450")
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                                    .stroke(
                                                        AngularGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]), center: .center, angle: .degrees(gradientRotation)),
                                                        lineWidth: 4
                                                    )
                                                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: gradientRotation)
                                            )
                                            .background(
                                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                                    .fill(Color.white.opacity(0.10))
                                            )
                                            .frame(width: geo.size.width, height: geo.size.height)
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                            .scaleEffect(2.0)
                                    }
                                    .onAppear {
                                        withAnimation {
                                            gradientRotation = 360
                                        }
                                    }
                                    .onDisappear {
                                        gradientRotation = 0
                                    }
                                }
                                .frame(height: UIScreen.main.bounds.height * 0.48)
                                .padding(8)
                            } else if viewModel.image == nil {
                                // Static border khi không upload
                                Image("2001 Acura CL Series S_00n0n_lvm1Irhg4DP_600x450")
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                                            .stroke(
                                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
                                                lineWidth: 4
                                            )
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                                            .fill(Color.white.opacity(0.10))
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(8)
                            } else {
                                Image(uiImage: viewModel.image!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .cornerRadius(24)
                                    .clipped()
                                    .padding(0)
                                    .transition(.scale.combined(with: .opacity))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.image)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.48)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                        
                        // Kết quả
                        if let make = viewModel.make, let model = viewModel.model {
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 16) {
                                        Image(systemName: "car.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 70)
                                            .cornerRadius(10)
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(make) \(model)")
                                                .font(.title3.bold())
                                                .foregroundColor(.primary)
                                            if let prob = viewModel.prob {
                                                Text("Confidence: \(prob)%")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        Spacer()
                                    }
                                    Group {
                                        if let gen = viewModel.generation, !gen.isEmpty {
                                            self.resultField(title: "Generation", value: gen, icon: "number")
                                        }
                                        if let years = viewModel.years, !years.isEmpty {
                                            self.resultField(title: "Year", value: years, icon: "calendar")
                                        }
                                        if let color = viewModel.colorName {
                                            self.resultField(title: "Color", value: color, icon: "paintpalette.fill")
                                        }
                                        if let angle = viewModel.angleName {
                                            self.resultField(title: "View Angle", value: angle, icon: "arrow.triangle.turn.up.right.diamond.fill")
                                        }
                                        if let bbox = viewModel.bbox {
                                            self.resultField(title: "Bounding Box", value: String(format: "TL:(%.2f, %.2f) - BR:(%.2f, %.2f)", bbox.tl_x ?? 0, bbox.tl_y ?? 0, bbox.br_x ?? 0, bbox.br_y ?? 0), icon: "rectangle.dashed")
                                        }
                                    }
                                }
                                .padding(16)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.07), Color.blue.opacity(0.18)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(18)
                                .shadow(color: .blue.opacity(0.10), radius: 6, x: 0, y: 2)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.make)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        } else if let error = viewModel.errorText {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.headline)
                                .padding()
                                .transition(.opacity)
                                .animation(.easeInOut, value: viewModel.errorText)
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 0)
                }
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: {
                            pickerSource = .photoLibrary
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Library")
                            }
                            .font(.title3.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        Button(action: {
                            pickerSource = .camera
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo")
                            }
                            .font(.title3.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    Button(action: {
                        viewModel.uploadImage()
                    }) {
                        HStack {
                            Image(systemName: "car.rear")
                            Text("Recognize")
                        }
                        .font(.title3.bold())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.orange]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .frame(height: 56)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, safeAreaBottomPadding())
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: pickerSource, selectedImage: Binding(
                    get: { viewModel.image },
                    set: { viewModel.image = $0 }
                ))
            }
        }
    }
}

// Thêm view phụ trợ
extension RecognitionView {
    func resultField(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.18))
        .cornerRadius(10)
    }
    
    func safeAreaBottomPadding() -> CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 16
    }
}

struct RecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionView(viewModel: ContentViewModel())
    }
} 
