# NearWork Local Services App

## Project Context
NearWork is a production-ready Flutter mobile application for a local services marketplace. The project uses a Clean Architecture design pattern with a Firebase backend. It integrates open-source mapping and geolocation services, aiming to provide a comprehensive set of user-facing screens and functionalities for Clients, Providers, and Merchants.

## Architecture and Technologies
- **Framework:** Flutter (SDK ^3.11.1)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Backend Services:** Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Messaging
- **Maps & Geolocation:** `flutter_map`, `latlong2`, `geolocator`
- **UI & Helpers:** Google Fonts, Shimmer, Timeago, Dash Chat 2, Cached Network Image, etc.

## Tasks and Implementation Status
Here is a summary of the tasks and current implementation features:

- [x] **Project Setup & Base Architecture**
  - Dependency integration via `pubspec.yaml`
  - Core app structure organized by features (`lib/core` and `lib/features`).
- [x] **Authentication Flow (`features/auth`)**
  - Login/Register capabilities.
  - Integration with Firebase Auth and Google Sign-in.
- [x] **Home & Map Discovery (`features/home`)**
  - Interactive map integration using `flutter_map`.
  - Geolocation capabilities to discover nearby services.
- [x] **User Profile Management (`features/profile`)**
  - Viewing and editing user details.
- [x] **Search Functionality (`features/search`)**
  - Search tools for finding local services and providers.
- [x] **Messaging & Chat (`features/chat`)**
  - Real-time communications between clients and providers using `dash_chat_2`.
- [x] **Reviews & Ratings (`features/reviews`)**
  - Feedback system for services through `flutter_rating_bar`.
- [x] **Favorites (`features/favorites`)**
  - Saving preferred services and providers.
- [x] **Notifications (`features/notifications`)**
  - Push notifications setup for important updates.
- [x] **Settings (`features/settings`)**
  - Application preferences and user settings.

## Version Reached
Current Application Version: **0.1.0+1**
