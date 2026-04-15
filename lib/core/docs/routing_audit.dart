/*
ROUTING AUDIT REPORT
Snapshot source: clean branch router before the routing fixes in this phase.
Audited file: lib/routes/app_router.dart

========================================================================
A. ROUTE INVENTORY
========================================================================

Path: /welcome
- Route name: none
- Screen widget: WelcomeScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /signup
- Route name: none
- Screen widget: SignupScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /login
- Route name: none
- Screen widget: LoginScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /forgot-password
- Route name: none
- Screen widget: ForgotPasswordPage
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /email-verification
- Route name: none
- Screen widget: EmailVerificationScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /account-type
- Route name: none
- Screen widget: AccountTypeSelectionScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /setup-client
- Route name: none
- Screen widget: SetupClientScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /setup-provider
- Route name: none
- Screen widget: SetupProviderScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /setup-marketplace
- Route name: none
- Screen widget: SetupMarketplaceScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /pending-verification
- Route name: none
- Screen widget: PendingVerificationPage
- Screen file exists on disk: yes
- Auth guard applied: partial

Path: /home
- Route name: none
- Screen widget: redirect only, no widget
- Screen file exists on disk: not applicable
- Auth guard applied: yes

Path: /client-home
- Route name: none
- Screen widget: ClientHomeScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /provider-home
- Route name: none
- Screen widget: ProviderHomeScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /marketplace-home
- Route name: none
- Screen widget: MarketplaceHomeScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /best-providers
- Route name: none
- Screen widget: BestProvidersScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /messages
- Route name: none
- Screen widget: ConversationsListScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /ai-chat
- Route name: none
- Screen widget: ChatHistoryPage
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /top-rated
- Route name: none
- Screen widget: TopRatedScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /profile
- Route name: none
- Screen widget: EditProfileScreen
- Screen file exists on disk: yes
- Auth guard applied: partial via parent redirect

Path: /search-results
- Route name: none
- Screen widget: SearchResultsScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /messages/:conversationId
- Route name: none
- Screen widget: ChatScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /ai-chat/session
- Route name: none
- Screen widget: AIChatPage
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /provider-profile/:id
- Route name: none
- Screen widget: ProviderProfileScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /marketplace-profile/:id
- Route name: none
- Screen widget: MarketplaceProfileScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /reviews/:providerId
- Route name: none
- Screen widget: ReviewsScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /profile/:userId
- Route name: none
- Screen widget: PublicProfileScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /rate-service/:providerId
- Route name: none
- Screen widget: RateServiceScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /favorites
- Route name: none
- Screen widget: FavoritesScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /notifications
- Route name: none
- Screen widget: NotificationsScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /settings
- Route name: none
- Screen widget: SettingsScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /language
- Route name: none
- Screen widget: LanguageSelectorScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /search
- Route name: none
- Screen widget: SearchScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

Path: /rate-client/:clientId
- Route name: none
- Screen widget: RateClientScreen
- Screen file exists on disk: yes
- Auth guard applied: yes

========================================================================
B. GUARD LOGIC ANALYSIS
========================================================================

Current redirect() logic in code, as originally implemented:
1. Reads authStateProvider and currentUserDataProvider.
2. If auth state is loading, returns null.
3. If user is null:
   - allows /welcome, /login, /signup, /forgot-password
   - redirects every other path to /welcome
4. If FirebaseAuth user.emailVerified is false:
   - redirects everything except /email-verification to /email-verification
5. If currentUserDataProvider is loading, returns null.
6. Reads accountType from Firestore and normalizes it.
7. If accountType is missing:
   - redirects to /account-type
8. Reads profile completion using:
   - profileComplete == true OR profileCompleted == true
9. If profile is incomplete:
   - redirects to setup route based on normalized account type
10. If location is /home:
    - redirects to role-specific path from homeForAccountType()
11. If user is already onboarded and tries to visit auth-flow paths:
    - redirects to role-specific home path
12. Otherwise allows navigation.

Deviations from REQUIRED AUTH GUARD SEQUENCE:
- Step 1 deviation: unauthenticated redirects go to /welcome, not /login.
- Step 4 deviation: guard reads profileCompleted as a fallback even though
  profileComplete is supposed to be the only source of truth.
- Step 5 deviation: /home does not load a role-aware screen; it redirects to
  role-specific routes from an older routing model.
- Step 6 deviation: there is no admin branch in the guard at all.
- Admin protection deviation: /admin is not defined in the router, and no
  admin-only redirect exists.
- Admin blocking deviation: admins are not blocked from /home, /messages,
  /ai-chat, or /profile.
- Onboarding loop deviation: because /home redirects to old per-role paths and
  there is no admin handling, routing can skip the new unified home entry.

========================================================================
C. ROLE-BASED HOME ROUTING
========================================================================

How /home behaved before the fix:
- /home was not a real screen route.
- It immediately redirected using resolveAuthenticatedRoute(userData).
- resolveAuthenticatedRoute() returned:
  - /account-type if accountType missing
  - /setup-* if profileComplete OR profileCompleted was false
  - /client-home, /provider-home, or /marketplace-home if onboarded

Problems:
- /home did not directly resolve to a role-aware widget.
- The app still depended on legacy per-role home paths from the single-role era.
- There was no admin home resolution at all.

========================================================================
D. ORPHANED ROUTES
========================================================================

No route in the original app_router.dart pointed to a missing screen file.

========================================================================
E. UNREACHABLE SCREENS
========================================================================

Screen files on disk that were not referenced by the original app_router.dart:
- lib/providers/provider_edit_profile_screen.dart
- lib/providers/provider_setup_screen.dart
- lib/providers/screens_provider_profile_screen.dart
- lib/providers/work_provider_profile_setup_screen.dart
- lib/services/screens_rate_service_screen.dart
- lib/views/admin_dashboard_screen.dart
- lib/views/availability_screen.dart
- lib/views/client_edit_profile_screen.dart
- lib/views/client_profile_setup_screen.dart
- lib/views/credential_upload_widget.dart
- lib/views/home_map_screen.dart
- lib/views/map_marker_widget.dart
- lib/views/map_preview_widget.dart
- lib/views/map_results_screen.dart
- lib/views/marketplace_edit_profile_screen.dart
- lib/views/marketplace_profile_setup_screen.dart
- lib/views/merchant_profile_screen.dart
- lib/views/merchant_setup_screen.dart
- lib/views/screens_client_profile_setup_screen.dart

========================================================================
F. SHELL ROUTE INTEGRITY
========================================================================

Original ShellRoute tabs by role:
- Client:
  Home | Search | AI Chat | Top Rated | Profile
- Work Provider:
  Home | Search | AI Chat | Profile
- Marketplace:
  Home | Search | AI Chat | Top Rated | Profile
- Admin:
  No shell handling at all

Required ShellRoute tabs:
- Client:
  Home | Search | AI Chat | Messages | Profile
- Work Provider:
  Home | Messages | Profile
- Marketplace:
  Home | Messages | Profile
- Admin:
  Not in ShellRoute

Integrity findings:
- Client is missing Messages and incorrectly includes Top Rated in the shell.
- Work Provider incorrectly includes Search and AI Chat, and is missing Messages.
- Marketplace incorrectly includes Search and AI Chat, and is missing Messages.
- Admin has no dedicated routing path and no shell exclusion logic.

ROUTING AUDIT COMPLETE - pre-fix findings captured.
*/
