# 🌾 Smart Crop Yield Prediction System

A complete, production-ready Flutter mobile application for AI-powered agricultural yield prediction. Built with **Material 3**, **Firebase**, and clean architecture.

---

## 📱 Screenshots & Screens

| Screen | Description |
|--------|-------------|
| 🟢 Splash Screen | Animated logo with staggered fade + scale |
| 🔐 Login | Email/password auth with error handling |
| 📝 Sign Up | Full registration with dropdown state selector |
| 🏠 Dashboard | Weather banner, quick action cards, seasonal tips |
| 🌱 Crop Data Entry | Complete form with dropdowns + validation |
| 🏆 Prediction Result | Animated confidence ring, tips, suggested variety |
| 📜 History | Shimmer loading, delete, detail bottom sheet |
| 👤 Profile | Account info, settings, language picker, logout |

---

## 🗂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── crop_input.dart          # CropInput model + Firestore serialization
│   └── user_model.dart          # UserModel
├── services/
│   ├── auth_service.dart        # Firebase Auth (ChangeNotifier)
│   ├── firestore_service.dart   # Firestore CRUD operations
│   └── prediction_service.dart  # ML API simulation / dummy predictions
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   ├── home_screen.dart     # Bottom nav shell
│   │   └── dashboard_tab.dart   # Home dashboard
│   ├── crop_data/
│   │   └── crop_data_screen.dart
│   ├── prediction/
│   │   └── prediction_result_screen.dart
│   ├── history/
│   │   └── history_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/
│   ├── custom_button.dart       # CustomButton, OutlineButton
│   ├── custom_text_field.dart   # CustomTextField, CustomDropdown, InfoChip
│   └── loading_overlay.dart     # LoadingOverlay, AppErrorWidget, EmptyStateWidget
└── utils/
    ├── app_theme.dart           # Material 3 green theme, colors, gradients
    └── app_constants.dart       # Crop types, soil types, locations, dummy predictions
```

---

## ⚙️ Setup Instructions

### 1. Prerequisites

- Flutter SDK ≥ 3.0.0 (run `flutter --version`)
- Dart ≥ 3.0.0
- Android Studio or VS Code with Flutter plugin
- A Firebase project

### 2. Clone & Install

```bash
# Navigate to project
cd smart_crop_yield

# Install dependencies
flutter pub get
```

### 3. Firebase Setup

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → name it `smart-crop-yield`
3. Enable **Google Analytics** (optional)

#### Step 2: Add Android App
1. In Firebase console → Project Settings → Add app → Android
2. Package name: `com.example.smart_crop_yield`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### Step 3: Add iOS App (optional)
1. Add iOS app with bundle ID: `com.example.smartCropYield`
2. Download `GoogleService-Info.plist`
3. Place it in: `ios/Runner/GoogleService-Info.plist`

#### Step 4: Enable Authentication
1. Firebase Console → Authentication → Get Started
2. Enable **Email/Password** provider

#### Step 5: Enable Firestore
1. Firebase Console → Firestore Database → Create database
2. Start in **test mode** (for development)
3. Collection: `crop_inputs`

#### Step 6: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=smart-crop-yield
```

This generates `lib/firebase_options.dart`.

#### Step 7: Uncomment Firebase in Code

In `lib/main.dart`, uncomment:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

In `lib/services/auth_service.dart` and `lib/services/firestore_service.dart`,
uncomment the Firebase implementation blocks and comment out the demo mode blocks.

### 4. Android Configuration

In `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

In `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 5. Run the App

```bash
# Debug mode
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

---

## 🔥 Firestore Data Schema

### Collection: `crop_inputs`

```json
{
  "userId": "string",
  "location": "string",
  "soilType": "string",
  "cropType": "string",
  "rainfall": "number (mm)",
  "temperature": "number (°C)",
  "humidity": "number (%)",
  "timestamp": "timestamp",
  "predictedYield": "number (tons/hectare)",
  "suggestedCrop": "string"
}
```

### Collection: `users`

```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "phone": "string",
  "location": "string",
  "createdAt": "timestamp"
}
```

### Firestore Security Rules (Production)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /crop_inputs/{docId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.userId;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }
  }
}
```

---

## 🤖 Connecting a Real ML Model

In `lib/services/prediction_service.dart`, replace the dummy logic with an HTTP call:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<PredictionResult> predictYield({...}) async {
  final response = await http.post(
    Uri.parse('https://your-ml-api.com/predict'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'crop_type': cropType,
      'soil_type': soilType,
      'location': location,
      'rainfall': rainfall,
      'temperature': temperature,
      'humidity': humidity,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return PredictionResult(
      yieldValue: data['yield'].toDouble(),
      unit: data['unit'],
      confidencePercent: data['confidence'],
      suggestedCrop: data['suggested_crop'],
      waterTip: data['water_tip'],
      fertilizerTip: data['fertilizer_tip'],
      generalTip: data['general_tip'],
      cropType: cropType,
    );
  } else {
    throw Exception('Prediction API error: ${response.statusCode}');
  }
}
```

Add `http` to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

---

## 🎨 Theme Customization

Colors are defined in `lib/utils/app_theme.dart`:

```dart
static const Color primaryGreen = Color(0xFF2E7D32);
static const Color lightGreen   = Color(0xFF66BB6A);
static const Color accentGreen  = Color(0xFF43A047);
```

Change these to rebrand the app for any agricultural theme.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Email/password authentication |
| `cloud_firestore` | Database for crop records |
| `provider` | State management |
| `google_fonts` | Poppins typography |
| `shimmer` | Loading skeleton animations |
| `percent_indicator` | Circular confidence ring |
| `intl` | Date formatting |
| `fl_chart` | Charts (ready for analytics screen) |
| `page_transition` | Smooth screen transitions |

---

## ✅ Demo Mode

The app ships in **demo mode** — no Firebase required. A demo user (`Rajesh Kumar`) and 5 sample records are pre-loaded. Perfect for hackathon presentations.

To enable demo login on the login screen, tap **"Use Demo Account"**.

---

## 🏆 Hackathon Tips

- App works fully offline with demo mode — no live Firebase needed for demo
- All screens are presentation-ready with smooth animations
- The prediction flow takes ~2 seconds (simulated) for realistic UX
- History screen shows 5 pre-seeded records from Firestore service
- Profile screen shows stats, settings, and multi-language selector

---

*Built with ❤️ for farmers using Flutter + Firebase*
