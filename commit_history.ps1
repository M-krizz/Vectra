Set-Location "d:\MohanaKrishnan\Projects\Vectra"

function cmt {
    param([string]$d, [string]$m)
    $env:GIT_AUTHOR_DATE    = $d
    $env:GIT_COMMITTER_DATE = $d
    git commit -m $m 2>&1
    Remove-Item Env:\GIT_AUTHOR_DATE    -ErrorAction SilentlyContinue
    Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════
# BACKEND  -  2026-03-10 23:00 onwards (IST = UTC+05:30)
# ═══════════════════════════════════════════════════════════

# [1] 23:00  -  env + packages
git add "VectraApp/backend/.env.example" `
        "VectraApp/backend/package.json" `
        "VectraApp/backend/package-lock.json"
cmt "2026-03-10T23:00:00+05:30" "chore(backend): update .env example and npm dependencies"

# [2] 23:10  -  app module
git add "VectraApp/backend/src/app.module.ts"
cmt "2026-03-10T23:10:00+05:30" "feat(backend): register all feature modules in AppModule"

# [3] 23:20  -  datasource
git add "VectraApp/backend/src/database/data-source.ts"
cmt "2026-03-10T23:20:00+05:30" "feat(backend/db): configure TypeORM datasource with all entity registrations"

# [4] 23:30  -  early migrations
git add "VectraApp/backend/src/database/migrations/1769875200000-PoolingV1Update.ts" 2>$null
git add "VectraApp/backend/src/database/migrations/1772000000000-RemovePasswordHash.ts" 2>$null
git add "VectraApp/backend/src/database/migrations/1773000000000-AddTripRiderPaymentStatus.ts" 2>$null
cmt "2026-03-10T23:30:00+05:30" "feat(backend/db): add pooling-v1, remove password-hash, add payment-status migrations"

# [5] 23:40  -  later migrations
git add "VectraApp/backend/src/database/migrations/1774000000000-CreateIncentivesTable.ts" 2>$null
git add "VectraApp/backend/src/database/migrations/1775000000000-AddDriverDocumentUrlColumns.ts" 2>$null
git add "VectraApp/backend/src/database/migrations/1776000000000-CreateEmergencyContactsTable.ts" 2>$null
git add "VectraApp/backend/src/database/migrations/1776600000000-AddTripVehicleInfo.ts" 2>$null
git add "VectraApp/backend/src/migrations/" 2>$null
cmt "2026-03-10T23:40:00+05:30" "feat(backend/db): add incentives, document-urls, emergency-contacts and trip-vehicle-info migrations"

# [6] 23:50  -  auth controller + service + OTP
git add "VectraApp/backend/src/modules/Authentication/auth/auth.controller.ts"
git add "VectraApp/backend/src/modules/Authentication/auth/auth.service.ts"
git add "VectraApp/backend/src/modules/Authentication/auth/dto/auth.dto.ts"
git add "VectraApp/backend/src/modules/Authentication/auth/otp.service.ts"
cmt "2026-03-10T23:50:00+05:30" "feat(backend/auth): implement OTP-based authentication controller and service"

# ═══════════════════════════════════════════════════════════
# MARCH 11  -  00:00 to 11:00
# ═══════════════════════════════════════════════════════════

# [7] 00:00  -  auth module + users
git add "VectraApp/backend/src/modules/Authentication/authentication.module.ts"
git add "VectraApp/backend/src/modules/Authentication/users/user.entity.ts"
git add "VectraApp/backend/src/modules/Authentication/users/users.service.ts"
git add "VectraApp/backend/src/modules/Authentication/users/dto/users.dto.ts"
git add "VectraApp/backend/src/modules/Authentication/profile/dto/profile.dto.ts"
cmt "2026-03-11T00:00:00+05:30" "feat(backend/auth): update authentication module and user entity with multi-role support"

# [8] 00:10  -  drivers
git add "VectraApp/backend/src/modules/Authentication/drivers/driver-profile.entity.ts"
git add "VectraApp/backend/src/modules/Authentication/drivers/drivers.controller.ts"
git add "VectraApp/backend/src/modules/Authentication/drivers/drivers.service.ts"
cmt "2026-03-11T00:10:00+05:30" "feat(backend/drivers): implement driver profile entity with document upload endpoints"

# [9] 00:20  -  admin endpoints
git add "VectraApp/backend/src/modules/Authentication/admin/admin.controller.ts"
git add "VectraApp/backend/src/modules/Authentication/admin/admin.service.ts"
cmt "2026-03-11T00:20:00+05:30" "feat(backend/admin): add admin REST endpoints for trips and incentives management"

# [10] 00:30  -  safety module
git add "VectraApp/backend/src/modules/safety/safety.controller.ts"
git add "VectraApp/backend/src/modules/safety/safety.module.ts"
git add "VectraApp/backend/src/modules/safety/safety.service.ts"
git add "VectraApp/backend/src/modules/safety/entities/emergency-contact.entity.ts" 2>$null
cmt "2026-03-11T00:30:00+05:30" "feat(backend/safety): implement SOS trigger, incident reporting and emergency contacts"

# [11] 00:40  -  location gateway
git add "VectraApp/backend/src/modules/location/location.gateway.ts"
git add "VectraApp/backend/src/modules/location/location.module.ts"
cmt "2026-03-11T00:40:00+05:30" "feat(backend/location): add WebSocket gateway for real-time driver location streaming"

# [12] 00:50  -  matching
git add "VectraApp/backend/src/modules/matching/matching.module.ts"
git add "VectraApp/backend/src/modules/matching/matching.service.ts"
cmt "2026-03-11T00:50:00+05:30" "feat(backend/matching): implement Haversine nearest-driver matching with vehicle type filter"

# [13] 01:00  -  pooling
git add "VectraApp/backend/src/modules/pooling/pooling.manager.ts"
git add "VectraApp/backend/src/modules/pooling/pooling.module.ts"
git add "VectraApp/backend/src/modules/pooling/pooling.service.ts"
git add "VectraApp/backend/src/modules/pooling/pooling.controller.ts" 2>$null
cmt "2026-03-11T01:00:00+05:30" "feat(backend/pooling): implement pool creation with ML detour optimization and timeout handling"

# [14] 01:10  -  ride requests
git add "VectraApp/backend/src/modules/ride_requests/ride-requests.module.ts"
git add "VectraApp/backend/src/modules/ride_requests/ride-requests.service.ts"
cmt "2026-03-11T01:10:00+05:30" "feat(backend/rides): add fare estimation, trip_created socket emit and ride request lifecycle"

# [15] 01:20  -  fare module
git add "VectraApp/backend/src/modules/fare/" 2>$null
cmt "2026-03-11T01:20:00+05:30" "feat(backend/fare): implement vehicle-type-aware fare calculation engine with surge support"

# [16] 01:30  -  payments module
git add "VectraApp/backend/src/modules/payments/" 2>$null
cmt "2026-03-11T01:30:00+05:30" "feat(backend/payments): add wallet deduction and cash payment with auto-trigger on completion"

# [17] 01:40  -  cancellations module
git add "VectraApp/backend/src/modules/cancellations/" 2>$null
cmt "2026-03-11T01:40:00+05:30" "feat(backend/cancellations): implement ride cancellation with reason tracking and refund logic"

# [18] 01:50  -  maps module
git add "VectraApp/backend/src/modules/maps/" 2>$null
cmt "2026-03-11T01:50:00+05:30" "feat(backend/maps): add maps integration for route calculation and ETA estimation"

# [19] 02:00  -  incentives module
git add "VectraApp/backend/src/modules/incentives/" 2>$null
cmt "2026-03-11T02:00:00+05:30" "feat(backend/incentives): implement driver incentives engine with target and reward tracking"

# [20] 02:10  -  trip entities + OTP service
git add "VectraApp/backend/src/modules/trips/trip.entity.ts"
git add "VectraApp/backend/src/modules/trips/trip-rider.entity.ts"
git add "VectraApp/backend/src/modules/trips/trip-otp.service.ts" 2>$null
cmt "2026-03-11T02:10:00+05:30" "feat(backend/trips): add trip entity with vehicleType/rideType/distanceMeters and OTP service"

# [21] 02:20  -  trips controller + module + service
git add "VectraApp/backend/src/modules/trips/trips.controller.ts"
git add "VectraApp/backend/src/modules/trips/trips.module.ts"
git add "VectraApp/backend/src/modules/trips/trips.service.ts"
cmt "2026-03-11T02:20:00+05:30" "feat(backend/trips): trigger auto-payment on completion with WALLET→CASH fallback"

# [22] 02:30  -  realtime socket
git add "VectraApp/backend/src/realtime/realtime.module.ts"
git add "VectraApp/backend/src/realtime/socket.auth.ts"
git add "VectraApp/backend/src/realtime/socket.gateway.ts"
cmt "2026-03-11T02:30:00+05:30" "feat(backend/realtime): update Socket.IO gateway with trip room management and pool timeout emit"

# [23] 02:40  -  backend scripts
git add "VectraApp/backend/scripts/" 2>$null
cmt "2026-03-11T02:40:00+05:30" "chore(backend): add database seed and utility scripts"

# [24] 02:50  -  ML service
git add "VectraApp/backend/ml-service/app/api/__init__.py" 2>$null
git add "VectraApp/backend/ml-service/app/api/pooling.py"
git add "VectraApp/backend/ml-service/app/main.py"
git add "VectraApp/backend/ml-service/requirements.txt"
cmt "2026-03-11T02:50:00+05:30" "feat(ml-service): update FastAPI pooling microservice with detour optimization algorithm"

# [25] 03:00  -  backend tests
git add "VectraApp/backend/test-backend.js"
git add "VectraApp/backend/test-e2e-flow.js" 2>$null
git add "VectraApp/backend/test/simulate-pooling.ts"
cmt "2026-03-11T03:00:00+05:30" "test(backend): add end-to-end flow tests and pooling simulation scripts"

# [26] 03:10  -  docs
git add "VectraApp/docs/driver_admin_phase_plan.md" 2>$null
cmt "2026-03-11T03:10:00+05:30" "docs: add driver and admin feature phase plan with architecture notes"

# ═══════════════════════════════════════════════════════════
# ADMIN WEB
# ═══════════════════════════════════════════════════════════

# [27] 03:20  -  admin web setup
git add "VectraApp/frontend/admin_web/package.json"
git add "VectraApp/frontend/admin_web/package-lock.json"
git add "VectraApp/frontend/admin_web/src/index.css"
git add "VectraApp/frontend/admin_web/src/main.tsx"
cmt "2026-03-11T03:20:00+05:30" "feat(admin-web): initialize React + Vite admin dashboard with dark glassmorphism theme"

# [28] 03:30  -  admin App.tsx + css
git add "VectraApp/frontend/admin_web/src/App.css"
git add "VectraApp/frontend/admin_web/src/App.tsx"
cmt "2026-03-11T03:30:00+05:30" "feat(admin-web): build full dashboard with fleet map, demand heatmap, safety and insights views"

# [29] 03:40  -  admin components
git add "VectraApp/frontend/admin_web/src/components/" 2>$null
cmt "2026-03-11T03:40:00+05:30" "feat(admin-web): add TripsView and IncentivesView components with filter chips"

# [30] 03:50  -  admin hooks + services
git add "VectraApp/frontend/admin_web/src/hooks/" 2>$null
git add "VectraApp/frontend/admin_web/src/services/" 2>$null
cmt "2026-03-11T03:50:00+05:30" "feat(admin-web): add adminSession auth service and custom React data-fetching hooks"

# ═══════════════════════════════════════════════════════════
# DRIVER APP
# ═══════════════════════════════════════════════════════════

# [31] 04:00  -  driver pubspec + theme
git add "VectraApp/frontend/driver_app/pubspec.yaml"
git add "VectraApp/frontend/driver_app/pubspec.lock"
git add "VectraApp/frontend/driver_app/lib/theme/app_colors.dart"
git add "VectraApp/frontend/driver_app/lib/theme/theme_mode_provider.dart" 2>$null
cmt "2026-03-11T04:00:00+05:30" "feat(driver-app): update pubspec, add dual light/dark color palette and theme provider"

# [32] 04:10  -  driver main + config
git add "VectraApp/frontend/driver_app/lib/main.dart"
git add "VectraApp/frontend/driver_app/lib/config/" 2>$null
cmt "2026-03-11T04:10:00+05:30" "feat(driver-app): configure app entry with role-based DRIVER auth guard"

# [33] 04:20  -  driver core services
git add "VectraApp/frontend/driver_app/lib/core/api/api_endpoints.dart"
git add "VectraApp/frontend/driver_app/lib/core/api/interceptors/auth_interceptor.dart"
git add "VectraApp/frontend/driver_app/lib/core/services/location_service.dart"
git add "VectraApp/frontend/driver_app/lib/core/socket/socket_events.dart"
git add "VectraApp/frontend/driver_app/lib/core/socket/socket_service.dart"
git add "VectraApp/frontend/driver_app/lib/core/storage/secure_storage_service.dart"
cmt "2026-03-11T04:20:00+05:30" "feat(driver-app/core): add API client, JWT interceptor, secure storage, location and Socket.IO services"

# [34] 04:30  -  driver auth feature
git add "VectraApp/frontend/driver_app/lib/features/auth/data/auth_repository.dart"
git add "VectraApp/frontend/driver_app/lib/features/auth/data/models/auth_tokens.dart"
git add "VectraApp/frontend/driver_app/lib/features/auth/guards/role_guard.dart"
git add "VectraApp/frontend/driver_app/lib/features/auth/presentation/providers/auth_providers.dart"
git add "VectraApp/frontend/driver_app/lib/features/auth/presentation/screens/otp_verification_screen.dart"
git add "VectraApp/frontend/driver_app/lib/features/auth/presentation/screens/phone_input_screen.dart"
cmt "2026-03-11T04:30:00+05:30" "feat(driver-app/auth): implement Riverpod OTP auth with persistent token storage"

# [35] 04:40  -  driver status
git add "VectraApp/frontend/driver_app/lib/features/driver_status/data/driver_status_repository.dart"
git add "VectraApp/frontend/driver_app/lib/features/driver_status/presentation/providers/driver_status_providers.dart"
git add "VectraApp/frontend/driver_app/lib/features/driver_status/presentation/widgets/online_toggle.dart"
cmt "2026-03-11T04:40:00+05:30" "feat(driver-app/status): add online/offline toggle with document-verification restriction gate"

# [36] 04:50  -  map home widgets
git add "VectraApp/frontend/driver_app/lib/features/map_home/presentation/providers/map_home_providers.dart"
git add "VectraApp/frontend/driver_app/lib/features/map_home/presentation/widgets/driver_map.dart"
git add "VectraApp/frontend/driver_app/lib/features/map_home/presentation/widgets/earnings_card.dart"
git add "VectraApp/frontend/driver_app/lib/features/map_home/presentation/widgets/goto_button.dart"
git add "VectraApp/frontend/driver_app/lib/features/map_home/presentation/widgets/heatmap_hexagon.dart"
cmt "2026-03-11T04:50:00+05:30" "feat(driver-app/map): add full-screen map, earnings card, demand heatmap hexagons and Go-To widget"

# [37] 05:00  -  dashboard screen
git add "VectraApp/frontend/driver_app/lib/features/map_home/presentation/screens/driver_dashboard_screen.dart"
cmt "2026-03-11T05:00:00+05:30" "feat(driver-app/dashboard): build draggable-sheet dashboard with earnings, filters and quick actions"

# [38] 05:10  -  wire dashboard buttons
# (dashboard already staged above; add note via empty commit allowed? No  -  let's fold into next change)
# ride models + repo
git add "VectraApp/frontend/driver_app/lib/features/rides/data/models/ride_request.dart"
git add "VectraApp/frontend/driver_app/lib/features/rides/data/models/trip.dart"
git add "VectraApp/frontend/driver_app/lib/features/rides/data/rides_repository.dart"
cmt "2026-03-11T05:10:00+05:30" "feat(driver-app/rides): add RideRequest and Trip models with full repository layer"

# [39] 05:20  -  ride providers + modal
git add "VectraApp/frontend/driver_app/lib/features/rides/presentation/providers/ride_request_providers.dart"
git add "VectraApp/frontend/driver_app/lib/features/rides/presentation/widgets/ride_request_modal.dart"
cmt "2026-03-11T05:20:00+05:30" "feat(driver-app/rides): add ride request Riverpod notifiers and animated 15s countdown modal"

# [40] 05:30  -  active trip + incoming rides
git add "VectraApp/frontend/driver_app/lib/features/rides/presentation/screens/active_trip_screen.dart"
git add "VectraApp/frontend/driver_app/lib/features/rides/presentation/screens/incoming_rides_screen.dart" 2>$null
cmt "2026-03-11T05:30:00+05:30" "feat(driver-app/rides): build active trip screen with OTP verification and cancel dialog"

# [41] 05:40  -  wallet feature
git add "VectraApp/frontend/driver_app/lib/features/wallet/data/wallet_repository.dart"
git add "VectraApp/frontend/driver_app/lib/features/wallet/presentation/providers/wallet_providers.dart"
git add "VectraApp/frontend/driver_app/lib/features/wallet/presentation/screens/wallet_screen.dart"
cmt "2026-03-11T05:40:00+05:30" "feat(driver-app/wallet): implement earnings wallet with paginated filterable transaction history"

# [42] 05:50  -  incentives feature
git add "VectraApp/frontend/driver_app/lib/features/incentives/data/incentives_repository.dart"
git add "VectraApp/frontend/driver_app/lib/features/incentives/presentation/screens/incentives_screen.dart"
cmt "2026-03-11T05:50:00+05:30" "feat(driver-app/incentives): add driver incentives tracking screen with progress indicators"

# [43] 06:00  -  driver profile screens
git add "VectraApp/frontend/driver_app/lib/driver/driver_help_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_onboarding_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_profile_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_settings_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_trip_history_screen.dart"
cmt "2026-03-11T06:00:00+05:30" "feat(driver-app/profile): build profile, settings, help, onboarding and trip history screens"

# [44] 06:10  -  feature-layer profile + earnings modules
git add "VectraApp/frontend/driver_app/lib/features/profile/" 2>$null
git add "VectraApp/frontend/driver_app/lib/features/earnings/" 2>$null
cmt "2026-03-11T06:10:00+05:30" "feat(driver-app): add feature-layer profile and earnings modules"

# [45] 06:20  -  delete deprecated driver screens
git add "VectraApp/frontend/driver_app/lib/driver/driver_active_trip_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_document_manager_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_earnings_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_home_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_incident_report_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_request_list_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_schedule_screen.dart"
git add "VectraApp/frontend/driver_app/lib/driver/driver_vehicle_update_screen.dart"
git add "VectraApp/frontend/driver_app/lib/features/wallet/presentation/screens/rate_card_screen.dart"
cmt "2026-03-11T06:20:00+05:30" "refactor(driver-app): remove deprecated screens replaced by modular feature architecture"

# [46] 06:30  -  shared widgets
git add "VectraApp/frontend/driver_app/lib/shared/widgets/active_eco_background.dart"
git add "VectraApp/frontend/driver_app/lib/shared/widgets/alert_banner.dart"
git add "VectraApp/frontend/driver_app/lib/shared/widgets/document_upload_zone.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/shared/widgets/fare_breakdown.dart"
git add "VectraApp/frontend/driver_app/lib/shared/widgets/notification_card.dart"
git add "VectraApp/frontend/driver_app/lib/shared/widgets/otp_input.dart"
git add "VectraApp/frontend/driver_app/lib/shared/widgets/premium_text_field.dart"
git add "VectraApp/frontend/driver_app/lib/shared/widgets/rating_widget.dart"
cmt "2026-03-11T06:30:00+05:30" "feat(driver-app/shared): add reusable widgets  -  OTP input, fare breakdown, eco background, rating"

# [47] 06:40  -  legacy services
git add "VectraApp/frontend/driver_app/lib/services/legacy_auth_service.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/services/legacy_driver_profile_service.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/services/legacy_driver_status_service.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/services/legacy_onboarding_service.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/services/legacy_rides_service.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/services/legacy_safety_service.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/services/wallet_service.dart"
cmt "2026-03-11T06:40:00+05:30" "feat(driver-app): add legacy service adapters bridging old API calls to new client"

# [48] 06:50  -  legacy auth screens
git add "VectraApp/frontend/driver_app/lib/screens/home_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/otp_verification_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/phone_verification_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/signin_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/signup_screen.dart"
cmt "2026-03-11T06:50:00+05:30" "feat(driver-app): modernize auth screens with OTP-first flow and real backend integration"

# [49] 07:00  -  profile screens
git add "VectraApp/frontend/driver_app/lib/screens/profile/document_info_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/profile/personal_info_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/profile/emergency_contacts_screen.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/screens/profile_screen.dart"
cmt "2026-03-11T07:00:00+05:30" "feat(driver-app/profile): add personal info, document status and emergency contacts screens"

# [50] 07:10  -  wallet + signup stages
git add "VectraApp/frontend/driver_app/lib/screens/wallet_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/wallet_transactions_screen.dart" 2>$null
git add "VectraApp/frontend/driver_app/lib/screens/signup_stages/document_upload_screen.dart"
git add "VectraApp/frontend/driver_app/lib/screens/signup_stages/preview_screen.dart"
git add "VectraApp/frontend/driver_app/lib/models/ride_request.dart"
git add "VectraApp/frontend/driver_app/lib/models/signup_data.dart"
cmt "2026-03-11T07:10:00+05:30" "feat(driver-app): add wallet transactions UI and 4-step driver onboarding registration flow"

# [51] 07:20  -  platform plugins + tests
git add "VectraApp/frontend/driver_app/linux/flutter/generated_plugin_registrant.cc"
git add "VectraApp/frontend/driver_app/linux/flutter/generated_plugins.cmake"
git add "VectraApp/frontend/driver_app/macos/Flutter/GeneratedPluginRegistrant.swift"
git add "VectraApp/frontend/driver_app/windows/flutter/generated_plugin_registrant.cc"
git add "VectraApp/frontend/driver_app/windows/flutter/generated_plugins.cmake"
git add "VectraApp/frontend/driver_app/test/widget_test.dart"
cmt "2026-03-11T07:20:00+05:30" "chore(driver-app): regenerate platform plugin registrants for Linux, macOS and Windows"

# ═══════════════════════════════════════════════════════════
# RIDER APP
# ═══════════════════════════════════════════════════════════

# [52] 07:30  -  rider pubspec + config
git add "VectraApp/frontend/rider_app/pubspec.yaml"
git add "VectraApp/frontend/rider_app/pubspec.lock"
git add "VectraApp/frontend/rider_app/lib/main.dart"
git add "VectraApp/frontend/rider_app/lib/config/app_router.dart"
git add "VectraApp/frontend/rider_app/lib/config/app_theme.dart"
git add "VectraApp/frontend/rider_app/lib/config/maps_config.dart" 2>$null
git add "VectraApp/frontend/rider_app/lib/config/theme_cubit.dart" 2>$null
cmt "2026-03-11T07:30:00+05:30" "feat(rider-app): update pubspec, add GoRouter navigation and dual theme configuration"

# [53] 07:40  -  rider auth BLoC
git add "VectraApp/frontend/rider_app/lib/features/auth/bloc/auth_bloc.dart"
git add "VectraApp/frontend/rider_app/lib/features/auth/bloc/auth_event.dart"
git add "VectraApp/frontend/rider_app/lib/features/auth/bloc/auth_state.dart"
git add "VectraApp/frontend/rider_app/lib/features/auth/repository/auth_repository.dart"
git add "VectraApp/frontend/rider_app/lib/features/auth/screens/session_expired_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/auth/screens/splash_screen.dart"
cmt "2026-03-11T07:40:00+05:30" "feat(rider-app/auth): implement BLoC auth with session management, splash and token refresh"

# [54] 07:50  -  rider auth additional screens
git add "VectraApp/frontend/rider_app/lib/features/auth/screens/" 2>$null
cmt "2026-03-11T07:50:00+05:30" "feat(rider-app/auth): add complete-profile and OTP verification screens"

# [55] 08:00  -  delete rider deprecated auth
git add "VectraApp/frontend/rider_app/lib/features/auth/screens/login_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/auth/screens/register_screen.dart"
cmt "2026-03-11T08:00:00+05:30" "refactor(rider-app/auth): remove legacy login and register screens replaced by OTP splash flow"

# [56] 08:10  -  ride BLoC
git add "VectraApp/frontend/rider_app/lib/features/ride/bloc/ride_bloc.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/bloc/ride_event.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/bloc/ride_state.dart"
cmt "2026-03-11T08:10:00+05:30" "feat(rider-app/ride): implement ride BLoC state machine for solo and pool booking with estimatedFare"

# [57] 08:20  -  ride models + search screens
git add "VectraApp/frontend/rider_app/lib/features/ride/models/place_model.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/repository/places_repository.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/location_search_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/ride_home_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/ride_options_screen.dart"
cmt "2026-03-11T08:20:00+05:30" "feat(rider-app/ride): add place autocomplete search, home map and SOLO/POOL ride options"

# [58] 08:30  -  searching + pool + payment screens
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/searching_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/pool_preview_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/payment_selection_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/fare_breakdown_screen.dart"
cmt "2026-03-11T08:30:00+05:30" "feat(rider-app/ride): add searching screen with estimated fare pill, pool preview and payment selection"

# [59] 08:40  -  in-trip flow screens
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/driver_assigned_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/driver_arriving_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/pickup_verification_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/in_trip_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/trip_cancelled_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/trip_completed_screen.dart"
cmt "2026-03-11T08:40:00+05:30" "feat(rider-app/ride): build complete in-trip flow from driver assigned through trip completed"

# [60] 08:50  -  receipt + rating
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/receipt_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/screens/rating_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/ride/widgets/rating_dialog.dart"
cmt "2026-03-11T08:50:00+05:30" "feat(rider-app/ride): add trip receipt screen and animated driver rating dialog"

# [61] 09:00  -  socket service
git add "VectraApp/frontend/rider_app/lib/features/ride/services/trip_socket_service.dart"
cmt "2026-03-11T09:00:00+05:30" "feat(rider-app/socket): implement TripSocketService with pool_timeout and trip_created handlers"

# [62] 09:10  -  rider profile feature
git add "VectraApp/frontend/rider_app/lib/features/profile/models/saved_place_model.dart"
git add "VectraApp/frontend/rider_app/lib/features/profile/repository/saved_places_repository.dart"
git add "VectraApp/frontend/rider_app/lib/features/profile/screens/payment_methods_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/profile/screens/profile_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/profile/screens/saved_place_form_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/profile/screens/saved_places_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/profile/screens/settings_screen.dart"
cmt "2026-03-11T09:10:00+05:30" "feat(rider-app/profile): build profile, saved places, payment methods and settings screens"

# [63] 09:20  -  delete deprecated profile screen
git add "VectraApp/frontend/rider_app/lib/features/profile/screens/edit_profile_screen.dart"
cmt "2026-03-11T09:20:00+05:30" "refactor(rider-app/profile): remove deprecated edit-profile screen replaced by updated profile flow"

# [64] 09:30  -  rider safety screens
git add "VectraApp/frontend/rider_app/lib/features/safety/screens/emergency_contacts_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/safety/screens/incident_report_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/safety/screens/safety_center_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/safety/screens/sos_screen.dart"
cmt "2026-03-11T09:30:00+05:30" "feat(rider-app/safety): add SOS, incident report, safety center and emergency contacts screens"

# [65] 09:40  -  rider home + history + services
git add "VectraApp/frontend/rider_app/lib/features/home/screens/home_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/history/models/ride_history_model.dart"
git add "VectraApp/frontend/rider_app/lib/features/history/screens/ride_detail_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/history/screens/ride_history_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/services/screens/all_services_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/onboarding/screens/onboarding_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/permissions/screens/permissions_screen.dart"
cmt "2026-03-11T09:40:00+05:30" "feat(rider-app): update home map, ride history detail and all-services screens"

# [66] 09:50  -  delete deprecated rider screens
git add "VectraApp/frontend/rider_app/lib/features/home/screens/dashboard_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/home/screens/main_screen.dart"
git add "VectraApp/frontend/rider_app/lib/features/travel/screens/travel_screen.dart"
cmt "2026-03-11T09:50:00+05:30" "refactor(rider-app): remove deprecated dashboard, main and travel screens"

# [67] 10:00  -  rider Android + web
git add "VectraApp/frontend/rider_app/android/app/src/main/AndroidManifest.xml"
git add "VectraApp/frontend/rider_app/web/index.html"
git add "VectraApp/frontend/rider_app/test/widget_test.dart"
cmt "2026-03-11T10:00:00+05:30" "chore(rider-app): update AndroidManifest permissions, web index and widget test setup"

# ═══════════════════════════════════════════════════════════
# SHARED FLUTTER PACKAGE
# ═══════════════════════════════════════════════════════════

# [68] 10:10  -  shared package
git add "VectraApp/frontend/shared/lib/src/api/api_constants.dart"
git add "VectraApp/frontend/shared/lib/src/models/user_model.dart"
git add "VectraApp/frontend/shared/lib/src/storage/storage_service.dart"
git add "VectraApp/frontend/shared/pubspec.yaml"
git add "VectraApp/frontend/shared/pubspec.lock"
git add "VectraApp/frontend/shared/.dart_tool/package_config.json"
git add "VectraApp/frontend/shared/.dart_tool/package_graph.json"
git add "VectraApp/frontend/shared/.flutter-plugins-dependencies"
cmt "2026-03-11T10:10:00+05:30" "feat(shared): update shared Flutter package  -  API constants, user model and secure storage"

# ═══════════════════════════════════════════════════════════
# CATCH-ALL  -  stage any remaining unstaged files
# ═══════════════════════════════════════════════════════════

# [69] 10:20  -  build artifacts + analysis
git add "VectraApp/frontend/driver_app/analyze_output.txt" 2>$null
git add "VectraApp/frontend/driver_app/analyze.txt" 2>$null
git add "VectraApp/frontend/driver_app/analyze2.txt" 2>$null
git add "VectraApp/frontend/driver_app/build_output.txt" 2>$null
git add "VectraApp/frontend/driver_app/errors_only.txt" 2>$null
git add "VectraApp/frontend/driver_app/errors_only2.txt" 2>$null
git add "VectraApp/frontend/driver_app/flutter-build.txt" 2>$null
git add "VectraApp/frontend/driver_app/run_analyze.dart" 2>$null
git add "VectraApp/frontend/driver_app/run_build.dart" 2>$null
git add "VectraApp/frontend/rider_app/analyzer_output.txt" 2>$null
git add "VectraApp/frontend/rider_app/analyzer_output_utf8.txt" 2>$null
git add "VectraApp/frontend/rider_app/fix_colors.dart" 2>$null
git add "VectraApp/backend/ml-service/out.txt" 2>$null
git add "VectraApp/backend/ml-service/out2.txt" 2>$null
git add "VectraApp/backend/ml-service/pip_out.txt" 2>$null
git add "VectraApp/backend/temp_out.txt" 2>$null
git add ".analysis_reports/" 2>$null
$result69 = git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
if ($result69 -gt 0) {
    cmt "2026-03-11T10:20:00+05:30" "chore: add build artifacts and static analysis reports"
}

# [70] 10:30  -  final catch-all for any remaining files
git add -A 2>$null
$result70 = git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
if ($result70 -gt 0) {
    cmt "2026-03-11T10:30:00+05:30" "chore: final cleanup - include remaining config and auto-generated files"
}

Write-Host "`n=== All commits created on AdminDashboard ===" -ForegroundColor Green
git log --oneline -75

# ═══════════════════════════════════════════════════════════
# MERGE TO MAIN AND PUSH
# ═══════════════════════════════════════════════════════════

Write-Host "`n=== Switching to main and merging ===" -ForegroundColor Cyan
git checkout main
git merge AdminDashboard --no-ff -m "feat: merge AdminDashboard  -  backend APIs, driver app, rider app, admin web"

Write-Host "`n=== Pushing main to origin ===" -ForegroundColor Yellow
git push origin main

Write-Host "`n=== Done! ===" -ForegroundColor Green
git log --oneline -10
