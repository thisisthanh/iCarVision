# iCarVision - AI Car Recognition App

Ứng dụng iOS sử dụng AI để nhận diện thông tin xe hơi từ ảnh.

## Tính năng

### 🚗 Nhận diện xe hơi
- **Online Mode**: Sử dụng Carnet API để nhận diện chi tiết
- **Offline Mode**: Sử dụng CoreML models để nhận diện cơ bản
- Tự động chuyển đổi giữa online/offline dựa trên kết nối internet

### 📱 Giao diện
- Chụp ảnh trực tiếp từ camera
- Chọn ảnh từ thư viện
- Hiển thị thông tin chi tiết về xe
- Lưu lịch sử nhận diện

### 🤖 AI Models
- **CarModelClassifier.mlmodel**: Nhận diện hãng và model xe
- **CarColorClassifier.mlmodel**: Nhận diện màu sắc xe

## Cách sử dụng

1. **Mở camera**: Nhấn "Take Photo" để chụp ảnh xe
2. **Chọn ảnh**: Nhấn "Library" để chọn ảnh từ thư viện
3. **Nhận diện**: Nhấn "Recognize" để phân tích ảnh
4. **Xem kết quả**: Thông tin xe sẽ hiển thị bao gồm:
   - Hãng xe (Make)
   - Model xe (Model)
   - Thế hệ (Generation) - N/A khi offline
   - Năm sản xuất (Year) - N/A khi offline
   - Màu sắc (Color)
   - Góc nhìn (View Angle) - N/A khi offline
   - Độ tin cậy (Confidence)

## Cài đặt

1. Clone repository
2. Mở file `iCarVision.xcodeproj` trong Xcode
3. Thêm API key Carnet vào `ContentViewModel.swift` (dòng có `<API_KEY>`)
4. Build và chạy ứng dụng

## Cấu trúc project

```
iCarVision/
├── Models/                    # CoreML models
│   ├── CarModelClassifier.mlmodel
│   └── CarColorClassifier.mlmodel
├── View/                      # SwiftUI Views
│   ├── ContentView.swift
│   ├── RecognitionView.swift
│   └── HistoryView.swift
├── ViewModel/                 # ViewModels
│   ├── ContentViewModel.swift
│   └── HistoryItem.swift
├── Networking/                # Network services
│   ├── Networking.swift
│   ├── NetworkMonitor.swift
│   └── CoreMLService.swift
├── Component/                 # Reusable components
│   └── ImagePicker.swift
└── Assets.xcassets/          # App assets
```

## Quyền cần thiết

- **Camera**: Để chụp ảnh xe
- **Photo Library**: Để chọn ảnh từ thư viện

## Lưu ý

- Khi online: Sử dụng Carnet API với đầy đủ thông tin
- Khi offline: Sử dụng CoreML models với thông tin cơ bản (hãng, model, màu sắc)
- Các trường không có dữ liệu sẽ hiển thị "N/A"
