/*
PHASE 1 - SCAN & REPORT
Generated from clean branch source at: clean-branch/lib

Important baseline note:
- This branch does not currently have a lib/features/ directory.
- The project is still organized in a flat layout under lib/views, lib/providers,
  lib/services, lib/models, and lib/routes.
- The logical role placement below is therefore a migration map for the existing
  files that will need to move into the target feature-based structure.

========================================================================
1. LOGICAL FILE MAP BY ROLE / DOMAIN
========================================================================

AUTH
- providers/account_type_controller.dart
- providers/auth_provider.dart
- providers/auth_providers.dart
- providers/email_verification_controller.dart
- providers/login_controller.dart
- providers/signup_controller.dart
- services/auth_repository.dart
- services/auth_repository_impl.dart
- services/auth_service.dart
- services/google_auth_service.dart
- services/services_google_auth_service.dart
- services/user_repository.dart
- services/user_repository_impl.dart
- views/account_type_selection_screen.dart
- views/auth_action_state.dart
- views/email_verification_screen.dart
- views/forgot_password_screen.dart
- views/login_screen.dart
- views/signup_screen.dart
- views/welcome_screen.dart

CLIENT
- models/client_model.dart
- views/client_edit_profile_screen.dart
- views/client_home_screen.dart
- views/client_profile_setup_screen.dart
- views/rate_client_screen.dart
- views/screens_client_profile_setup_screen.dart
- views/setup_client_screen.dart

WORK PROVIDER
- models/verification_status.dart
- models/work_provider_model.dart
- providers/provider_edit_profile_screen.dart
- providers/provider_feature_card.dart
- providers/provider_home_screen.dart
- providers/provider_popup_card.dart
- providers/provider_profile_screen.dart
- providers/provider_setup_screen.dart
- providers/screens_provider_profile_screen.dart
- providers/setup_provider_screen.dart
- providers/verification_controller.dart
- providers/work_provider_profile_setup_screen.dart
- services/document_verification_repository.dart
- services/document_verification_service.dart
- views/credential_upload_widget.dart
- views/pending_verification_screen.dart
- views/verification_result.dart

MARKETPLACE
- models/marketplace_model.dart
- views/marketplace_edit_profile_screen.dart
- views/marketplace_home_screen.dart
- views/marketplace_profile_screen.dart
- views/marketplace_profile_setup_screen.dart
- views/marketplace_taxonomy.dart
- views/merchant_profile_screen.dart
- views/merchant_setup_screen.dart
- views/setup_marketplace_screen.dart

ADMIN
- services/admin_service.dart
- views/admin_dashboard_screen.dart

SHARED / CROSS-ROLE / CORE-CANDIDATE
- app.dart
- firebase_options.dart
- l10n/app_localizations.dart
- l10n/app_localizations_ar.dart
- l10n/app_localizations_en.dart
- l10n/app_localizations_fr.dart
- main.dart
- models/chat_message_model.dart
- models/chat_models.dart
- models/chat_session_model.dart
- models/discovery_models.dart
- models/message_model.dart
- models/review_model.dart
- models/user_model.dart
- providers/availability_provider.dart
- providers/best_providers_screen.dart
- providers/chat_controller.dart
- providers/chat_provider.dart
- providers/chat_session_provider.dart
- providers/home_provider.dart
- providers/locale_provider.dart
- providers/profile_provider.dart
- providers/search_results_controller.dart
- routes/app_router.dart
- routes/route_paths.dart
- routes/simple_router.dart
- services/chat_service.dart
- services/chat_session_repository.dart
- services/chat_session_repository_impl.dart
- services/discovery_service.dart
- services/distance_service.dart
- services/geocoding_service.dart
- services/groq_chat_service.dart
- services/location_lookup_service.dart
- services/location_service.dart
- services/notification_service.dart
- services/profile_service.dart
- services/rate_service_screen.dart
- services/review_service.dart
- services/screens_rate_service_screen.dart
- services/search_repository.dart
- services/services_notification_service.dart
- services/services_review_service.dart
- services/storage_service.dart
- views/ai_chat_page.dart
- views/app_bottom_navbar.dart
- views/app_colors.dart
- views/app_constants.dart
- views/app_spacing.dart
- views/app_text_styles.dart
- views/availability_badge.dart
- views/availability_screen.dart
- views/category_chip.dart
- views/chat_history_page.dart
- views/chat_message.dart
- views/chat_screen.dart
- views/chat_session.dart
- views/conversation_tile.dart
- views/conversations_list_screen.dart
- views/edit_profile_screen.dart
- views/favorites_screen.dart
- views/ghost_button.dart
- views/google_sign_in_button.dart
- views/home_map_screen.dart
- views/language_selector_screen.dart
- views/loading_shimmer.dart
- views/logout_button.dart
- views/main_scaffold_wrapper.dart
- views/map_marker_widget.dart
- views/map_preview_widget.dart
- views/map_results_screen.dart
- views/message_bubble.dart
- views/notifications_screen.dart
- views/primary_button.dart
- views/profile_card.dart
- views/public_profile_screen.dart
- views/reviews_screen.dart
- views/search_params.dart
- views/search_results_screen.dart
- views/search_screen.dart
- views/section_card.dart
- views/settings_screen.dart
- views/star_rating_row.dart
- views/top_rated_screen.dart
- views/verified_badge.dart

Files that are especially misplaced even before the refactor:
- providers/provider_home_screen.dart
- providers/provider_profile_screen.dart
- providers/provider_edit_profile_screen.dart
- providers/provider_setup_screen.dart
- providers/work_provider_profile_setup_screen.dart
- services/rate_service_screen.dart
- services/screens_rate_service_screen.dart
- services/services_google_auth_service.dart
- services/services_notification_service.dart
- services/services_review_service.dart
- views/screens_client_profile_setup_screen.dart
- providers/screens_provider_profile_screen.dart

========================================================================
2. OCCURRENCES OF "backgroundcolor" (lowercase c)
========================================================================

No occurrences found in clean-branch/lib.

========================================================================
3. OCCURRENCES OF ".withOpacity("
========================================================================

No occurrences found in clean-branch/lib.

========================================================================
4. GOROUTER ROUTES WITH NO CORRESPONDING SCREEN FILE
========================================================================

No missing route target files were found in routes/app_router.dart.

Notes:
- AppRoutes.home is a redirect-only route and intentionally has no screen file.
- routes/simple_router.dart currently returns an empty list from
  buildSimpleAuthRoutes(), so it contributes no screen routes at runtime.
- Several routes resolve to existing files that are stored in the wrong folders:
  - providers/setup_provider_screen.dart
  - providers/best_providers_screen.dart
  - providers/provider_home_screen.dart
  - providers/provider_profile_screen.dart
  - services/rate_service_screen.dart

========================================================================
5. SCREEN FILES NEVER REFERENCED IN routes/app_router.dart
========================================================================

These files exist but are not imported by routes/app_router.dart and are
therefore currently outside the main route table:
- providers/provider_edit_profile_screen.dart
- providers/provider_setup_screen.dart
- providers/screens_provider_profile_screen.dart
- providers/work_provider_profile_setup_screen.dart
- services/screens_rate_service_screen.dart
- views/admin_dashboard_screen.dart
- views/availability_screen.dart
- views/client_edit_profile_screen.dart
- views/client_profile_setup_screen.dart
- views/credential_upload_widget.dart
- views/home_map_screen.dart
- views/map_marker_widget.dart
- views/map_preview_widget.dart
- views/map_results_screen.dart
- views/marketplace_edit_profile_screen.dart
- views/marketplace_profile_setup_screen.dart
- views/merchant_profile_screen.dart
- views/merchant_setup_screen.dart
- views/screens_client_profile_setup_screen.dart

========================================================================
6. RIVERPOD PROVIDERS DEFINED BUT NEVER CONSUMED
========================================================================

The following provider symbols appear only at their definition site during the
Phase 1 text scan and are likely unused:
- providers/auth_providers.dart -> isEmailVerifiedProvider
- providers/auth_providers.dart -> isProfileCompleteProvider
- providers/auth_providers.dart -> workProviderNeedsReviewProvider
- providers/availability_provider.dart -> availabilityProvider
- providers/home_provider.dart -> selectedRadiusProvider
- providers/home_provider.dart -> selectedMinimumRatingProvider
- providers/home_provider.dart -> availableOnlyProvider
- providers/home_provider.dart -> useCurrentLocationProvider
- providers/home_provider.dart -> manualSearchAddressProvider
- providers/profile_provider.dart -> providerDataProvider
- providers/profile_provider.dart -> merchantDataProvider
- services/review_service.dart -> reviewServiceProvider

Warning:
- This is a text-reference scan, not a semantic Dart analyzer graph.
- These entries should be verified again after the folder move and import repair.

========================================================================
7. IMPORTS THAT REFERENCE FILES THAT DO NOT EXIST
========================================================================

No broken internal Dart imports were found in clean-branch/lib.

========================================================================
ADDITIONAL STRUCTURAL OBSERVATIONS
========================================================================

- The clean branch still mixes screen files into views/, providers/, and even
  services/, which will make the Phase 2 move large but straightforward.
- routes/app_router.dart currently depends on package imports pointing into the
  flat layout, so nearly all imports there will need to be updated after moves.
- There are duplicate or near-duplicate file names that suggest drift during
  previous migrations:
  - setup_client_screen.dart vs client_profile_setup_screen.dart
  - setup_marketplace_screen.dart vs marketplace_profile_setup_screen.dart
  - setup_provider_screen.dart vs provider_setup_screen.dart vs
    work_provider_profile_setup_screen.dart
  - provider_profile_screen.dart vs screens_provider_profile_screen.dart
  - rate_service_screen.dart vs screens_rate_service_screen.dart
  - google_auth_service.dart vs services_google_auth_service.dart
  - notification_service.dart vs services_notification_service.dart
  - review_service.dart vs services_review_service.dart

========================================================================
PHASE 1 BASELINE STATUS
========================================================================

- backgroundcolor typo count: 0
- withOpacity count: 0
- missing internal import count: 0
- missing route target file count: 0
- unreferenced screen file count: 19
- suspected unused provider count: 12

PHASE 1 COMPLETE - 0 immediate scan errors in the report generation step.
*/
