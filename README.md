# Occazio – Your Smart Event Booking Assistant

Occazio is a smart mobile application that revolutionizes the way you plan and book events. Whether you're organizing a wedding, birthday, corporate event, or private party, Occazio connects you with the perfect venues and vendors — all based on your preferences, budget, and location. No more endless phone calls or in-person visits!

## ✨ Features

- 🔍 Personalized Event Planning: Input your event type, date, budget, guest count, and preferred location — Occazio takes care of the rest.
- 🏛️ Venue & Vendor Discovery: Instantly browse through curated lists of banquets, caterers, decorators, and more.
- 🤝 Smart Matching Engine: Our recommendation system suggests the best options based on your needs and past user reviews.
- 💬 In-App Booking & Communication: No need to call! Book and communicate with vendors directly within the app.
- 🛡️ Privacy-Centric Profiles: Customize your settings, manage your profile, and control what vendors see.

## 🛠️ Tech Stack
- Frontend: Flutter (Dart)
- Backend: Firebase (Firestore, Auth, Storage)
- Database: Firebase Firestore
- Authentication: Firebase Auth
- AI Recommendation: Custom ML Model (Python backend in progress)
- Design: Figma

## 📱 Screens
- Login / Signup
- Home (Recommendations & Featured)
- Search & Filter
- Event Details
- Profile & Settings
- Booking History

## 📂 Project Structure (Simplified)
```
Occazio/
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   ├── services/
│   └── main.dart
├── assets/
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started
1. Clone the repository
   ```bash
   git clone https://github.com/saketjndl/Occazio.git
   cd Occazio
   ```
2. Install dependencies
   ```bash
   flutter pub get
   ```
3. Run the app
   ```bash
   flutter run
   ```
4. (Optional) Connect Firebase
   - Follow Firebase setup docs to link your project
   - Add google-services.json or GoogleService-Info.plist to the project as needed

## 🤝 Team Occazio
- UI/UX Design: [Member Name]
- Authentication & Home Screen: [Member Name]
- Database & Backend Integration: [Member Name]
- Settings/Profile/Privacy: [Member Name]
- Documentation & Research: [Member Name]

## 📌 Future Scope
- AI-powered vendor recommendation engine
- Dynamic pricing and availability tracking
- Chatbot support for planning queries
- Vendor-side dashboard portal

---

## Firebase Configuration

This project requires a `google-services.json` file in `android/app/` for Firebase to work. This file is not included in the public repository for security reasons. Please obtain your own from the Firebase Console and place it in the correct directory.
