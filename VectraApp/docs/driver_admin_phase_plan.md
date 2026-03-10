# Driver and Admin Execution Plan

## Scope
This plan follows rider stabilization and focuses on productionizing remaining driver and admin surfaces.

## Current Snapshot
- Rider app: backend workflows integrated, analyzer clean, widget smoke tests passing.
- Driver app: core realtime and wallet/history integrations are in place, but map home and parts of signup/profile still use simulated data/placeholder flows.
- Admin web: socket and pending-driver approval workflows are connected, but key dashboard metrics are synthetic and safety operations are still local-only (no backend state transitions).

## Driver Phase (execute first)

### D1. Remove simulated map home data
Files:
- frontend/driver_app/lib/features/map_home/presentation/providers/map_home_providers.dart

Tasks:
1. Replace `_loadInitialData` simulated earnings and heatmap generation with API-backed fetches.
2. Remove `_generateMockHeatmap` and move fallback behavior to empty-state UI.
3. Implement `_updateHeatmapData` and `_updateSurgeData` with socket payload parsing.
4. Ensure current location defaults come from geolocation or backend profile, not hardcoded city coordinates.

Acceptance criteria:
- No simulated map home data paths remain.
- Heatmap/surge changes are visible from live socket events.
- Driver app analyze passes.

### D2. Complete signup/profile placeholders
Files:
- frontend/driver_app/lib/screens/signup_screen.dart
- frontend/driver_app/lib/screens/signup_stages/preview_screen.dart
- frontend/driver_app/lib/screens/profile/personal_info_screen.dart
- frontend/driver_app/lib/screens/profile/document_info_screen.dart
- frontend/driver_app/lib/screens/signin_screen.dart

Tasks:
1. Replace simulated signup API delays with real auth/profile endpoint calls.
2. Replace dummy profile/document fallback values with persisted backend data.
3. Add forgot-password flow wiring (or hide/disable until backend endpoint is ready).
4. Add error/retry UX and loading states for each transition.

Acceptance criteria:
- Signup and profile read/write paths are backend-driven.
- No dummy document/profile values shown in standard flow.
- Authentication screens have deterministic loading/error handling.

### D3. Driver regression gate
Tasks:
1. Run flutter analyze on full driver app.
2. Run existing driver tests and add smoke tests for map home provider and signup happy-path.
3. Validate reconnect + room rejoin behavior manually for trip lifecycle.

Acceptance criteria:
- Analyzer clean, tests passing.
- No functional regressions in trip lifecycle or map home.

## Admin Phase (after driver)

### A1. Replace synthetic dashboard metrics
Files:
- frontend/admin_web/src/hooks/useFleetData.ts
- frontend/admin_web/src/App.tsx

Tasks:
1. Replace `computeDemandIndex` synthetic model with backend-supplied metrics endpoints.
2. Introduce metrics polling cadence or socket channel for demand and wait-time cards.
3. Remove hardcoded default metric assumptions.

Acceptance criteria:
- Dashboard cards render backend metrics.
- Insights chart source is backend/event-driven, not synthetic generation.

### A2. Safety hub action wiring
Files:
- frontend/admin_web/src/App.tsx
- frontend/admin_web/src/hooks/useFleetData.ts

Tasks:
1. Add backend action endpoint calls for SOS resolve/escalate.
2. On resolve, persist state server-side and refresh alert list from backend/socket acknowledgment.
3. Add optimistic UI with rollback on failure.

Acceptance criteria:
- Resolve/escalate operations persist in backend.
- Safety table and dashboard alert badge remain consistent after actions.

### A3. Admin auth hardening
Files:
- frontend/admin_web/src/services/fleetSocket.ts
- frontend/admin_web/src/components/UserOpsView.tsx

Tasks:
1. Replace demo token fallback usage with explicit authenticated admin session source.
2. Add token expiry handling and reconnect strategy for socket.
3. Gate privileged views on role verification and missing-token handling.

Acceptance criteria:
- No implicit demo-token dependency in production path.
- Admin socket reconnects securely after token refresh.

## Validation Sequence
1. Driver phase validations after each subphase (analyze + targeted tests).
2. Admin phase validations (type check/build + runtime smoke in local env).
3. End-to-end runbook:
- Driver online/offline
- Trip request assign/arrive/start/complete
- SOS generation from rider/driver and admin resolution
- Wallet and trip history consistency checks

## Recommended Order
1. D1
2. D2
3. D3
4. A1
5. A2
6. A3

## Dependencies and Risks
- Admin metrics endpoints may need backend expansion if not already exposed.
- Safety action persistence may require additional backend event contracts.
- Driver map heatmap payload schema must match socket/backend implementation.

## Ready-to-start first implementation target
Start with D1 in map home provider because it removes the highest concentration of simulation and unlocks realistic driver dispatch behavior.
