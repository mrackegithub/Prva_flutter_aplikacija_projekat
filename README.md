# Eko Redar — Community Problem Reporting App

> A Flutter mobile application for reporting, tracking, and collaborating on ecological, social, and communal infrastructure problems in your local community.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Variables](#environment-variables)
  - [Firebase Configuration](#firebase-configuration)
  - [Running the App](#running-the-app)
- [Building for Production](#building-for-production)
- [Architecture](#architecture)
- [Screens](#screens)
- [Role System](#role-system)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Overview

**Eko Redar** ("Eco Warden") is a community-driven mobile application built as a school project. It allows citizens to photograph and report communal problems — broken infrastructure, illegal dumping, flooding, and similar issues — directly to a shared database where administrators and other community members can track and resolve them.

The app uses AI-powered image analysis (Google Gemini) to automatically validate submitted photos, ensuring that only genuine communal problems are accepted into the system.

---

## Features

### For Citizens
- **Report Problems** — Photograph a problem, add a title and description, and submit it with your GPS location automatically attached.
- **AI Image Validation** — Submissions are analysed by Google Gemini. Images that do not depict a real communal or ecological problem are automatically rejected before saving.
- **Reverse Geocoding** — Precise coordinates are converted into a human-readable address and stored alongside the report.
- **Community Help Requests** — Mark a problem as needing help from other community members, making it visible in the public "Available Problems" feed.
- **My Problems** — View and track the status of all problems you have submitted.
- **Map View** — Browse all reported problems on an interactive OpenStreetMap map, colour-coded by status.

### For Administrators
- **Admin Panel** — Full overview of every submitted problem with filtering and sorting controls.
- **Resolve & Delete** — Mark problems as resolved or permanently delete them from the database.
- **Statistics Dashboard** — At-a-glance counts of total, resolved, and help-needed problems.
- **Map Access** — Same interactive map view available to regular users.

### Authentication
- Email/Password sign-up with mandatory email verification before first login.
- Google Sign-In (OAuth 2.0 via Firebase).
- Password reset by email.
- Role-based routing — users land on the citizen home screen; admins are taken directly to the admin panel.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | [Flutter](https://flutter.dev) (Dart) |
| Backend / Database | [Firebase Firestore](https://firebase.google.com/products/firestore) |
| Authentication | [Firebase Auth](https://firebase.google.com/products/auth) + [Google Sign-In](https://pub.dev/packages/google_sign_in) |
| Image Hosting | [Cloudinary](https://cloudinary.com) |
| AI Analysis | [Google Gemini API](https://ai.google.dev) (`gemini-2.5-flash-lite`) |
| Maps | [flutter_map](https://pub.dev/packages/flutter_map) + [OpenStreetMap](https://www.openstreetmap.org) |
| Geolocation | [geolocator](https://pub.dev/packages/geolocator) + [geocoding](https://pub.dev/packages/geocoding) |
| Environment Config | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |

---

## Project Structure

```
lib/
├── Ekrani/                  # All UI screens
│   ├── admin.dart           # Admin panel (problem management, statistics)
│   ├── available_problems.dart  # Public feed of problems needing help
│   ├── login.dart           # Login and registration screen
│   ├── mapa.dart            # Interactive map screen
│   ├── my_problems.dart     # Logged-in user's submitted problems
│   ├── user.dart            # Problem submission form
│   └── welcome.dart         # Citizen home / navigation hub
├── services/
│   ├── auth_service.dart    # Firebase Auth + Google Sign-In wrapper
│   ├── cloudinary.dart      # Image upload to Cloudinary
│   ├── gemini.dart          # Gemini AI image analysis
│   └── prijave.dart         # (Reserved for future reporting services)
├── firebase_options.dart    # Auto-generated FlutterFire configuration
└── main.dart                # App entry point + AuthWrapper routing
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — version matching `pubspec.yaml` (`^3.10.4`)
- Dart SDK `>=3.10.4 <4.0.0`
- Android Studio or Xcode (for native device builds)
- A Firebase project with **Authentication**, **Firestore**, and **Storage** enabled
- A [Cloudinary](https://cloudinary.com) account with an unsigned upload preset
- A [Google AI Studio](https://aistudio.google.com) API key for Gemini

Verify your Flutter setup:

```bash
flutter doctor
```

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/eko-redar.git
cd eko-redar

# Install dependencies
flutter pub get
```

### Environment Variables

Create a `.env` file in the project root (next to `pubspec.yaml`). This file is listed in `flutter.assets` and loaded at runtime via `flutter_dotenv`.

```env
GEMINI_API=your_google_gemini_api_key_here
```

> **Warning:** Never commit `.env` to version control. It is already listed in `.gitignore`.

### Firebase Configuration

The repository ships with placeholder Firebase configuration files. To connect your own Firebase project:

1. Create a project at [https://console.firebase.google.com](https://console.firebase.google.com).
2. Add an **Android** app with package name `com.example.flutter_aplikacija`.
3. Download `google-services.json` and place it at `android/app/google-services.json`.
4. Regenerate `lib/firebase_options.dart` using the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

5. In Firestore, create a `users` collection. Each document uses the user's Firebase UID as the document ID and must contain at minimum:

```json
{
  "name": "string",
  "email": "string",
  "role": "user"   // or "admin"
}
```

6. Set Firestore security rules appropriate for your use case before deploying.

### Running the App

```bash
# List available devices
flutter devices

# Run on a connected device or emulator
flutter run -d <device-id>
```

---

## Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

Ensure a `key.properties` file exists at `android/key.properties` with your signing credentials before building a release APK. See the [Flutter documentation](https://docs.flutter.dev/deployment/android) for details.

---

## Architecture

The app follows a straightforward screen-service architecture:

```
AuthWrapper (main.dart)
│
├── Firebase Auth stream
│
├── User not logged in ──────► AuthPage (login/register)
│
└── User logged in
    ├── role == "admin" ──────► AdminPage
    └── role == "user"  ──────► WelcomeScreen
                                    ├── HomePage (submit problem)
                                    │     ├── GeminiService (AI validation)
                                    │     ├── Geolocator (GPS)
                                    │     └── Cloudinary (image upload)
                                    ├── AvailableProblemsScreen
                                    ├── MyProblemsScreen
                                    └── MapaScreen (flutter_map)
```

State is handled locally within each `StatefulWidget`. All persistent data lives in Firebase Firestore, with real-time streams powering the problem lists.

---

## Screens

| Screen | Description |
|---|---|
| **Login / Register** | Email+password and Google OAuth. Email verification is enforced before first login. |
| **Welcome** | Navigation hub showing available actions for the logged-in citizen. |
| **Submit Problem** | Camera capture, title/description form, GPS lookup, optional community-help flag, and AI validation before saving. |
| **My Problems** | Filterable list of the current user's submitted reports with status badges. |
| **Available Problems** | Public feed of problems where the author has requested community assistance. |
| **Map** | OpenStreetMap view with colour-coded markers (red = active, green = resolved). Tap a marker for details. |
| **Admin Panel** | Full problem management with resolve/delete actions, status filtering, date/status sorting, and a statistics modal. |

---

## Role System

Roles are stored as a `role` field (`"user"` or `"admin"`) in each user's Firestore document. The `AuthWrapper` in `main.dart` reads this field after login and routes accordingly:

- Assigning `name = "admin"` during registration is the current method for creating admin accounts (see `auth_service.dart`). For production deployments, admin accounts should be created exclusively via the Firebase console or a secure back-end function.

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes following existing code conventions.
4. Run static analysis before pushing: `flutter analyze`
5. Open a Pull Request with a clear description of the change.

Please add relevant tests for any new business logic.

---

## Security

- API keys and secrets must never be committed to the repository. Use `.env` for Gemini keys and `key.properties` for signing credentials — both are excluded by `.gitignore`.
- Firebase API keys present in `google-services.json` and `firebase_options.dart` are restricted by package name and SHA certificate on the Firebase console; they are safe to include in Android builds but the files themselves are gitignored.
- Review and tighten Firestore security rules before any public deployment to prevent unauthorised reads or writes.
- The admin role-assignment mechanism (based on the user's first name) is a development shortcut and **must be replaced** with a secure method before going to production.

---

## License

This project is licensed under the **MIT License**. See the [`LICENSE`](LICENSE) file for details.
