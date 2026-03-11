# Vectra Integration Testing Complete Guide & Workflow

## Overview of Completed Tests

We successfully built and ran integration tests across the Vectra Stack (NestJS Backend + Flutter Rider/Driver Apps). An integration test evaluates how parts of the system interact, particularly bridging APIs, Databases, WebSockets, and UI State models.

### 1. Backend Integration Tests (NestJS)
**Location:** `/backend/test/`
- `app.e2e-spec.ts`: Default check to see if the root endpoint `/api/v1` bootstraps correctly.
- `ride-requests.e2e-spec.ts`: 
  - Simulates a Rider creating a real `POST /api/v1/ride-requests` request.
  - Tests whether the `RideRequestsController` can talk to the `RideRequestsService`.
  - Mocks the `TypeORM` Database and `DataSource` to isolate the DB logic without needing Postgres.
  - Critically, verifying whether `SocketGateway.emitTripStatus` pushes a `REQUESTED` real-time WebSocket event correctly down to clients.
- `trips.e2e-spec.ts`:
  - Simulates a Driver updating their location via `PATCH /api/v1/trips/:id/location`.
  - Mocks Jwt Auth and Database.
  - Verifies that `SocketGateway.emitLocationUpdate` broadcasts to listeners successfully.

### 2. Frontend Integration Tests (Flutter)
**Location:** `/frontend/rider_app/test/` and `/frontend/driver_app/test/`
- **Driver App Widget Test (`widget_test.dart`)**:
  - Tests if the `VectraApp` correctly mounts to the Flutter tree and initial views render.
- **Rider App RideBloc Integration (`ride_bloc_integration_test.dart`)**:
  - Tests the entire booking state machine (`RideBloc`).
  - Mocks the `RideRepository` (REST API).
  - Uses `mocktail` to inject mock WebSocket streams inside the test.
  - Triggers a ride request -> forces the mock Socket stream to emit the `ASSIGNED` backend status -> Asserts that the app successfully transitions its state from `searching` to `driverFound`.
- **Rider App TripSocketService Test (`trip_socket_service_test.dart`)**:
  - Mocks the actual `socket_io_client` using a `socketBuilder` override.
  - Connects to a dummy token, verifies if listeners attach correctly, and asserts that Socket streams decode JSON arrays from NestJS cleanly into typed Dart objects (`TripStatusEvent`).

---

## Workflow: How to run Integration Tests

### Step 1: Backend (NestJS API & Sockets)
1. Open the terminal and navigate to the backend directory:
   ```bash
   cd VectraApp/backend
   ```
2. Run the End-to-End Jest Testing command:
   ```bash
   npm run test:e2e
   ```
3. Read the output. If a test fails due to a new dependency (e.g., adding a new Repository or Library to a service), you'll need to mock it in the `Test.createTestingModule` providers list inside the corresponding `.e2e-spec.ts` file.

### Step 2: Rider App (Flutter)
1. Open the terminal and navigate to the rider app directory:
   ```bash
   cd VectraApp/frontend/rider_app
   ```
2. Run the flutter test command for UI Integration:
   ```bash
   flutter test test/features/ride/bloc/ride_bloc_integration_test.dart
   ```
3. Run the flutter test for Socket Logic Integration:
   ```bash
   flutter test test/features/ride/services/trip_socket_service_test.dart
   ```

### Step 3: Driver App (Flutter)
1. Open the terminal and navigate to the driver app directory:
   ```bash
   cd VectraApp/frontend/driver_app
   ```
2. Run the flutter widget test:
   ```bash
   flutter test test/widget_test.dart
   ```

---

## Scope: Are 3 Backend Tests Enough?

Currently, we only have **3 backend and 3 frontend tests** running. This is a solid **"Happy Path"** starting ground—proving that the foundational bridges work. 

However, there is **immense scope for adding more cases**. To make the app truly production-ready, testing should be expanded to include edge cases and failures. 

### Recommended Expansions (Future Scope)

#### 1. Backend Edge Cases (NestJS)
- **Token Authorization Testing:** Currently Auth is bypassed/mocked. We need tests that provide *invalid* tokens or *expired* tokens and assert that the API throws an HTTP 401 Unauthorized instead of processing the request or crashing.
- **Ride Cancellation Matrix:** Test what happens to the WebSocket connections when a driver cancels, a rider cancels, or no drivers are found.
- **Duplicate Request Guards:** What happens if a User hits the `Request Ride` API twice in 1 second? Integration tests should ensure a race condition doesn't create two simultaneous rides.

#### 2. Frontend Edge Cases (Flutter BLoC & Sockets)
- **Socket Disconnection Strategy:** Expand `trip_socket_service_test.dart` to simulate a sudden Wi-Fi loss. The Integration test should assert that the Socket client attempts an exponential backoff reconnect, rather than abandoning the ride state.
- **Driver Arrival/OTP Workflow:** The `ride_bloc_integration_test.dart` currently goes up to the `ASSIGNED` state. We should extend it to mock the REST API for `verifyOtp()` and socket stream for `IN_PROGRESS` and `COMPLETED`. 

#### 3. E2E System Test Matrix (Beyond Mocking)
**Integration tests still mock the Database.** To prove standard reliability, we need full system E2E tests:
- Setup a script that spins up the NestJS Server locally, connects it to a temporary local PostgreSQL test database, and fires REST API calls from `supertest` hitting real data inserts, updating foreign keys, and completing exactly what the app would in real life.
