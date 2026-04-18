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
- [x] **AI Chatbot Service (`features/shared/ai_chat`)**
  - Integrated Gemini 1.5 Flash API for intelligent assistance.
  - Persistent session management with Firestore.
  - Context-aware search suggestions for localized results.
- [x] **Client Feature Constraints (`features/client`)**
  - Specialized Client Home with Explore/Search/Chat/AI/Alerts/Profile tabs.
  - Private Profile view showing received ratings.
  - Role-based route protection (Admin access blocked for clients).
  - Multi-target search support (Work Providers & Marketplace).
- [x] **Work Provider Feature Constraints (`features/work_provider`)**
  - Specialized Work Provider Home with Earnings summary and Availability toggle.
  - Verified badge system via GroqVision document upload and admin approval.
  - Public profile with star ratings, review count, location, and radius.
  - Dedicated search interface locked to Marketplace accounts.
  - Access to AI Chatbot and direct client messaging.
- [x] **Marketplace Feature Constraints (`features/marketplace`)**
  - Specialized Shop Home with Store statistics and Open/Closed toggle.
  - Profile excludes verified badge and manual uploads.
  - Search map queries actively filter out the active user's own profile marker.
  - URL redirects securely pass exclude criteria automatically for inner lists.

## Security & Architecture
- [x] **Firestore Rules Rewrite (v0.3.2)**: Rewrote `firestore.rules` completely to fix `PERMISSION_DENIED` errors on all collections:
  - `users/{userId}`: Any authenticated user can read profiles; only the owner can write.
  - `users/{userId}/ai_sessions` + `/messages`: Owner-only read/write.
  - `conversations/{id}`: Participants (via `participantIds`) can read/write; any auth user can create. Messages subcollection: any auth user.
  - `notifications/{id}`: Owner reads/writes their own; any auth user can create.
  - `reviews/{id}`: All authenticated users can read; only the reviewer can create/update/delete.
- [x] Correctly locked down `ai_sessions` and `messages` Firestore subcollections to only permit read/write access to the authenticated owner (`request.auth.uid == userId`).
- [x] Fixed all role-based `Profile` screens (Client, Work Provider, Marketplace) to use a unified Riverpod `StreamProvider` (`userProfileProvider`) pulling dynamically from Firestore.
- [x] Fixed `firebase_app_check` activation to use correct v0.4.x provider classes (`AndroidDebugProvider`, `AppleDebugProvider`) replacing deprecated enum values.

## Home Screen Redesign & AI Restoration (v0.3.1)
All 3 home screens fully redesigned as fullscreen flutter_map experiences:
- **Shared widgets**: `HomeSearchBar`, `CategoryChipsBar`, `MapProviderMarker` (reusable, in `features/shared/widgets/`)
- **Restored AI Chatbot**: "Ask AI" tab correctly restored to all roles with consistent 6-tab navigation.
- **Routing Update**: Standardized `/conversations` route to `/messages` for clarity.
- **AI Session logic**: Improved `/ai-chat/session` route to handle optional `sessionId` with safe fallbacks.
- **Client home**: 6 tabs, searches `work_provider` + `marketplace`.
- **Work Provider home**: 6 tabs, searches `marketplace` only.
- **Marketplace home**: 6 tabs, searches `marketplace` excluding own userId.
- **Map markers**: CircleAvatar with gold ★ rating badge (shown only if `reviewCount >= 3`).
- **FAB**: GPS recenter button (bottom right of map).
- **Bottom nav**: role-specific tabs in `AppColors.primaryNavy` bar.
- `dart analyze lib/` → **No issues found** ✅

## AI Chat Service Rewrite (v0.3.2)
Completely rewrote `lib/features/shared/ai_chat/services/ai_chat_service.dart`:
- Correct Gemini `v1beta` REST format: `contents[].parts[].text` with `role: user|model`
- System prompt injected into the **first user turn** of every request (never sent as a separate role)
- Per-step error surfacing: HTTP errors throw `AiChatException('Error <status>: <body>')`, parse failures throw `AiChatException('Failed to parse ...')` — **no silent swallowing**
- 30-second timeout via `.timeout()` with network error caught and re-thrown clearly
- Fixed type mismatch in `ai_chat_providers.dart`: `List<Map<String,dynamic>>` history now cast to `List<Map<String,String>>` before being passed to the service
- `SEARCH_SUGGESTION:[category]` system prompt updated with full valid category list
- `dart analyze lib/features/shared/ai_chat/` → **No issues found** ✅

## Discovery Home & Search Flow (v0.4.0)
Replaced the map-first home screens with a clean discovery-oriented UI and a robust filtering system.
- **Client Home**: White, clean UI. Prominent search banner triggering a bottom sheet to choose between Work Provider or Marketplace searches. Displays top-rated Work Providers (`reviewCount >= 3`) horizontally.
- **Work Provider Home**: Search banner (auto-routes to Marketplace), "Your Status" card with live toggle (`isAvailable`), and a list of the 3 most recent conversations.
- **Marketplace Home**: Search banner (auto-routes to Marketplace excluding self), "Shop Status" card with live toggle (`isOpen`), and recent conversations.
- **Advanced Search Filter (`/search-filter`)**:
  - Validates and obtains GPS location using `geolocator` and reverse geocodes area names with `geocoding`.
  - Configurable filters: Radius slider (1-50km), Minimum Rating (1-5★), Category chips (dynamic by target), Availability toggle, and Verification toggle.
  - State managed securely via Riverpod 3.x `Notifier` + `SearchFilterModel`.
- **Search Results (`/search-results`)**:
  - Complex multi-step filtering applied dynamically via `search_results_provider.dart` (`FutureProvider`).
  - Implements Haversine formula client-side distance calculation.
  - Result cards beautifully present Avatar, verified badges, robust star ratings, distance/location, and correct CTA routing based on target type.
- **App Router Updates**: Simplified redirection logic and cleanly integrated new search routes using Typed Extras.

## Version Reached
Current Application Version: **0.4.0**

## AI Chat Service Rewrite - Gemini 2.0 Flash (v0.4.4)
Completely rewrote `lib/features/shared/ai_chat/services/ai_chat_service.dart` to implement the latest Google Gemini 2.0 Flash API:
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- Core changes: Implemented custom mapping to resolve Gemini's lack of a native system role by strictly prepending system instructions to the first history element as `SYSTEM INSTRUCTIONS:`. Enforced strict alternating standard roles for stability.
- Removed legacy traces of Mistral and ZhipuAI logic and tests.
- Simplified parsing logic with strict `AiChatException` error throwing to surface parsing exceptions seamlessly to UI state controllers.

## Image Picker UI Addition (v0.4.5)
Upgraded `AiChatSessionScreen` to include an image-picking interface leveraging `image_picker`:
- Converted chat to stateful widget tracking transient `_selectedImage` user selection logic natively.
- Connected a `showModalBottomSheet` supporting camera and library retrieval tied safely to new native Android/iOS permission nodes.
- Integrated a floating animated hovering image preview directly over the `DashChat` input field.

## Gemini Vision Send Flow (v0.4.6)
Implemented the full end-to-end messaging flow for image + text payloads using Firebase Storage.

## In-Memory Gemini Vision (v0.4.7)
Refactored the image messaging flow to be completely ephemeral and privacy-focused:
- **Zero Storage Persistence**: Removed all Firebase Storage dependencies. Images are no longer uploaded or hosted.
- **In-Memory Payloads**: Images picked via `image_picker` are kept in memory and sent directly to `gemini-2.5-flash` as Base64 `inline_data`.
- **Session-Local UI**: Implemented a local state cache in `AiChatSessionScreen` to maintain visual consistency of images during the active session using `Image.file`.
- **Firestore Simplification**: Optimized `AiChatRepository` to store only text-based metadata, ensuring no sensitive image data persists in the database.

## Version Reached
Current Application Version: **0.4.7**
