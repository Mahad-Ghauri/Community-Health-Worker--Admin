---
description: Repository Information Overview
alwaysApply: true
---

# CHW TB Management Admin Information

## Summary
A Flutter application for TB management by Community Health Workers (CHWs). The app provides an administrative interface for managing patients with tuberculosis, healthcare facilities, and community health workers. It includes role-based access control with different interfaces for administrators and staff members.

## Structure
- **lib/**: Core application code organized in a feature-based structure
- **android/**, **ios/**, **web/**, **macos/**, **linux/**: Platform-specific code
- **assets/**: Application assets including icons
- **pubspec.yaml**: Flutter dependency management and configuration

## Language & Runtime
**Language**: Dart
**Version**: SDK ^3.9.0
**Framework**: Flutter
**Package Manager**: pub (Flutter/Dart package manager)

## Dependencies
**Main Dependencies**:
- firebase_core: ^4.1.0
- firebase_auth: ^6.0.2
- cloud_firestore: ^6.0.1
- firebase_storage: ^13.0.1
- provider: ^6.1.5+1
- go_router: ^14.6.1
- intl: ^0.20.2
- geolocator: ^14.0.2

**Development Dependencies**:
- flutter_test: SDK
- flutter_lints: ^5.0.0

## Build & Installation
```bash
flutter pub get
flutter build web  # For web deployment
flutter build apk  # For Android
flutter build ios  # For iOS (requires macOS)
```

## Firebase Integration
**Project ID**: community-health-a340d
**Configuration**: Firebase configuration for web, Android, and iOS platforms
**Services Used**: Authentication, Firestore, Storage, Realtime Database

## Main Files & Resources
**Entry Point**: lib/main.dart
**Models**: lib/models/ (Patient, User, Facility, etc.)
**Screens**: lib/screens/ (Dashboard, Auth, Users, Facilities)
**Services**: lib/services/ (Auth, User, Facility, Dashboard)
**Providers**: lib/providers/ (State management using Provider)
**Routing**: lib/config/app_router.dart (Using go_router)

## Application Features
**Authentication**: Role-based login system
**User Management**: Admin can create and manage users
**Facility Management**: Create and manage healthcare facilities
**Patient Tracking**: Monitor TB patients and their treatment status
**Staff Dashboard**: Specialized interface for staff members
**Audit Logging**: Track system activities