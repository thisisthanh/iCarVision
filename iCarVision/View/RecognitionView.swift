import SwiftUI

struct RecognitionView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceActionSheet = false
    @State private var gradientRotation: Double = 0
    @State private var showCameraAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
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
                    VStack(spacing: 32) {
                        // Image Section
                        ImageSection(viewModel: viewModel, gradientRotation: $gradientRotation)
                        
                                                    // Action Buttons
                            ActionButtonsSection(
                                viewModel: viewModel,
                                showImagePicker: $showImagePicker,
                                pickerSource: $pickerSource,
                                showCameraAlert: $showCameraAlert
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Car Recognition")
            .navigationBarTitleDisplayMode(.large)
        }
        
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: pickerSource, selectedImage: Binding(
                get: { viewModel.image },
                set: { viewModel.image = $0 }
            ))
        }
        .alert("Camera Not Available", isPresented: $showCameraAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Camera is not available on this device. Please use Photo Library instead.")
        }
    }
}



// MARK: - Image Section
struct ImageSection: View {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var gradientRotation: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if viewModel.isUploading && viewModel.image == nil {
                    // Loading state
                    LoadingImageView(gradientRotation: $gradientRotation)
                } else if viewModel.image == nil {
                    // Default state
                    DefaultImageView()
                } else {
                    // Selected image
                    SelectedImageView(image: viewModel.image!)
                }
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1),
                radius: 16,
                x: 0,
                y: 6
            )
        }
    }
}

struct LoadingImageView: View {
    @Binding var gradientRotation: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            
            // Animated border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .rotationEffect(.degrees(gradientRotation))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: gradientRotation)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                
                Text("Analyzing...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            gradientRotation = 360
        }
    }
}

struct DefaultImageView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            
            // Border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            
            VStack(spacing: 20) {
                Image(systemName: "car.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(.tertiary)
                
                VStack(spacing: 8) {
                    Text("Select a car image")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Choose from library or take a photo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct SelectedImageView: View {
    let image: UIImage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                
                // Border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                
                // Image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var showImagePicker: Bool
    @Binding var pickerSource: UIImagePickerController.SourceType
    @Binding var showCameraAlert: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private func checkCameraAvailability() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private func openCamera() {
        if checkCameraAvailability() {
            pickerSource = .camera
            showImagePicker = true
        } else {
            showCameraAlert = true
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Image source buttons
            HStack(spacing: 12) {
                ActionButton(
                    title: "Library",
                    icon: "photo.on.rectangle",
                    gradient: [.blue, .cyan],
                    action: {
                        pickerSource = .photoLibrary
                        showImagePicker = true
                    }
                )
                
                ActionButton(
                    title: "Camera",
                    icon: "camera",
                    gradient: [.purple, .pink],
                    action: openCamera
                )
            }
            
            // Recognize button
            ActionButton(
                title: "Recognize Car",
                icon: "car.rear",
                gradient: [.orange, .red],
                isPrimary: true,
                action: {
                    viewModel.uploadImage()
                }
            )
            .disabled(viewModel.image == nil)
            .opacity(viewModel.image == nil ? 0.6 : 1.0)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    var isPrimary: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: gradient.first?.opacity(0.3) ?? .black.opacity(0.1),
                radius: isPrimary ? 12 : 8,
                x: 0,
                y: isPrimary ? 6 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Recognition View") {
    RecognitionView(viewModel: ContentViewModel())
}

#Preview("Recognition View - Dark Mode") {
    RecognitionView(viewModel: ContentViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Recognition View - With Image") {
    let viewModel = ContentViewModel()
    // Simulate having an image
    viewModel.image = UIImage(systemName: "car.fill")
    return RecognitionView(viewModel: viewModel)
}

#Preview("Recognition View - Uploading") {
    let viewModel = ContentViewModel()
    viewModel.isUploading = true
    return RecognitionView(viewModel: viewModel)
}
