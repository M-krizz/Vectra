# Backend API Reference - Port 3000

**Base URL**: `http://localhost:3000/api/v1`

---

## 1. AUTHENTICATION ENDPOINTS

### 1.1 Request OTP

**URL**: `http://localhost:3000/api/v1/auth/request-otp`  
**Method**: POST  
**Authentication**: Not required

**Request Body**:

```json
{
  "channel": "email",
  "identifier": "user@example.com"
}
```

**Response**:

```json
{
  "status": "sent",
  "message": "OTP sent successfully to user@example.com"
}
```

---

### 1.2 Register Rider

**URL**: `http://localhost:3000/api/v1/auth/register/rider`  
**Method**: POST  
**Authentication**: Not required

**Request Body**:

```json
{
  "fullName": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "password": "SecurePassword123!",
  "emergencyContacts": [
    {
      "name": "Jane Doe",
      "phone": "+0987654321",
      "relationship": "Family"
    }
  ]
}
```

**Response**:

```json
{
  "user": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "role": "RIDER",
    "createdAt": "2026-02-10T09:00:00.000Z"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshTokenId": "refresh-token-uuid"
}
```

---

### 1.3 Register Driver

**URL**: `http://localhost:3000/api/v1/auth/register/driver`  
**Method**: POST  
**Authentication**: Not required

**Request Body**:

```json
{
  "fullName": "Driver Smith",
  "email": "driver@example.com",
  "phone": "+1234567891",
  "password": "SecurePassword123!",
  "licenseNumber": "DL12345678",
  "licenseState": "CA",
  "emergencyContacts": [
    {
      "name": "Emergency Contact",
      "phone": "+0987654322",
      "relationship": "Spouse"
    }
  ]
}
```

**Response**:

```json
{
  "user": {
    "userId": "550e8400-e29b-41d4-a716-446655440001",
    "fullName": "Driver Smith",
    "email": "driver@example.com",
    "role": "DRIVER"
  },
  "driverProfile": {
    "id": "driver-profile-uuid",
    "userId": "550e8400-e29b-41d4-a716-446655440001",
    "licenseNumber": "DL12345678",
    "licenseState": "CA",
    "status": "PENDING_APPROVAL"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshTokenId": "refresh-token-uuid"
}
```

---

### 1.4 Verify OTP

**URL**: `http://localhost:3000/api/v1/auth/verify-otp`  
**Method**: POST  
**Authentication**: Not required

**Request Body**:

```json
{
  "identifier": "user@example.com",
  "code": "123456"
}
```

**Response**:

```json
{
  "user": {
    "userId": "user-uuid",
    "email": "user@example.com"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshTokenId": "refresh-token-uuid"
}
```

---

### 1.5 Login

**URL**: `http://localhost:3000/api/v1/auth/login`  
**Method**: POST  
**Authentication**: Not required

**Request Body**:

```json
{
  "email": "john.doe@example.com",
  "password": "SecurePassword123!"
}
```

**Response**:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshTokenId": "550e8400-e29b-41d4-a716-446655440002",
  "user": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "role": "RIDER"
  }
}
```

---

### 1.6 Refresh Token

**URL**: `http://localhost:3000/api/v1/auth/refresh`  
**Method**: POST  
**Authentication**: Refresh token required

**Request Headers**:

```
x-refresh-token-id: 550e8400-e29b-41d4-a716-446655440002
```

**Request Body**:

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response**:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshTokenId": "new-refresh-token-uuid"
}
```

---

### 1.7 Get Current User (Me)

**URL**: `http://localhost:3000/api/v1/auth/me`  
**Method**: GET  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "user": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "role": "RIDER",
    "isVerified": true,
    "createdAt": "2026-02-10T09:00:00.000Z"
  }
}
```

---

### 1.8 List Sessions

**URL**: `http://localhost:3000/api/v1/auth/sessions`  
**Method**: GET  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "sessions": [
    {
      "id": "session-uuid-1",
      "deviceInfo": "Chrome on Windows",
      "ip": "192.168.1.100",
      "createdAt": "2026-02-10T09:00:00.000Z",
      "lastActivity": "2026-02-10T14:30:00.000Z"
    },
    {
      "id": "session-uuid-2",
      "deviceInfo": "Mobile App - Android",
      "ip": "192.168.1.101",
      "createdAt": "2026-02-09T10:00:00.000Z",
      "lastActivity": "2026-02-10T12:00:00.000Z"
    }
  ]
}
```

---

### 1.9 Logout

**URL**: `http://localhost:3000/api/v1/auth/logout`  
**Method**: POST  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
x-refresh-token-id: session-uuid-1
```

**Response**:

```json
{
  "status": "ok",
  "message": "Logged out successfully"
}
```

---

### 1.10 Logout All Sessions

**URL**: `http://localhost:3000/api/v1/auth/logout-all`  
**Method**: POST  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "status": "ok",
  "message": "All sessions terminated",
  "sessionsRevoked": 3
}
```

---

## 2. PROFILE ENDPOINTS

### 2.1 Get Profile

**URL**: `http://localhost:3000/api/v1/profile`  
**Method**: GET  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "fullName": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "bio": "Frequent rider in San Francisco",
  "avatar": "https://example.com/avatars/user.jpg",
  "rating": 4.8,
  "totalRides": 127,
  "privacySettings": {
    "shareLocation": true,
    "shareTrips": false
  }
}
```

---

### 2.2 Update Profile

**URL**: `http://localhost:3000/api/v1/profile`  
**Method**: PATCH  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "fullName": "John Updated Doe",
  "bio": "Updated bio text",
  "avatar": "https://example.com/avatars/new-avatar.jpg"
}
```

**Response**:

```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "fullName": "John Updated Doe",
  "bio": "Updated bio text",
  "avatar": "https://example.com/avatars/new-avatar.jpg",
  "updatedAt": "2026-02-10T14:35:00.000Z"
}
```

---

### 2.3 Update Privacy Settings

**URL**: `http://localhost:3000/api/v1/profile/privacy`  
**Method**: PATCH  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "shareLocation": false,
  "shareTrips": true
}
```

**Response**:

```json
{
  "privacySettings": {
    "shareLocation": false,
    "shareTrips": true
  },
  "updatedAt": "2026-02-10T14:36:00.000Z"
}
```

---

### 2.4 Deactivate Account

**URL**: `http://localhost:3000/api/v1/profile/deactivate`  
**Method**: POST  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "status": "deactivated",
  "message": "Account has been deactivated successfully",
  "reactivationInfo": "You can reactivate by logging in again"
}
```

---

### 2.5 Delete Account

**URL**: `http://localhost:3000/api/v1/profile`  
**Method**: DELETE  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "status": "deleted",
  "message": "Account permanently deleted",
  "deletedAt": "2026-02-10T14:40:00.000Z"
}
```

---

### 2.6 Export User Data

**URL**: `http://localhost:3000/api/v1/profile/export`  
**Method**: GET  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "user": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1234567890"
  },
  "rides": [],
  "payments": [],
  "sessions": [],
  "exportedAt": "2026-02-10T14:45:00.000Z"
}
```

---

## 3. DRIVER ENDPOINTS

### 3.1 Get Driver Profile

**URL**: `http://localhost:3000/api/v1/drivers/profile`  
**Method**: GET  
**Authentication**: JWT required (DRIVER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "driverProfile": {
    "id": "driver-profile-uuid",
    "userId": "550e8400-e29b-41d4-a716-446655440001",
    "licenseNumber": "DL12345678",
    "licenseState": "CA",
    "status": "APPROVED",
    "rating": 4.9,
    "totalTrips": 543,
    "earnings": {
      "total": 15420.5,
      "thisMonth": 2340.0
    }
  }
}
```

---

### 3.2 Update License

**URL**: `http://localhost:3000/api/v1/drivers/license`  
**Method**: PATCH  
**Authentication**: JWT required (DRIVER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "licenseNumber": "DL98765432",
  "licenseState": "NY"
}
```

**Response**:

```json
{
  "driverProfile": {
    "id": "driver-profile-uuid",
    "licenseNumber": "DL98765432",
    "licenseState": "NY",
    "status": "PENDING_REVIEW",
    "updatedAt": "2026-02-10T14:50:00.000Z"
  }
}
```

---

### 3.3 Set Online Status

**URL**: `http://localhost:3000/api/v1/drivers/online`  
**Method**: POST  
**Authentication**: JWT required (DRIVER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "online": true
}
```

**Response**:

```json
{
  "online": true,
  "updatedAt": "2026-02-10T14:55:00.000Z",
  "message": "Driver is now online and available for rides"
}
```

---

### 3.4 Get Vehicles

**URL**: `http://localhost:3000/api/v1/drivers/vehicles`  
**Method**: GET  
**Authentication**: JWT required (DRIVER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "vehicles": [
    {
      "id": "vehicle-uuid-1",
      "make": "Toyota",
      "model": "Camry",
      "year": 2022,
      "color": "Blue",
      "licensePlate": "ABC123",
      "capacity": 4,
      "status": "ACTIVE"
    }
  ]
}
```

---

### 3.5 Add Vehicle

**URL**: `http://localhost:3000/api/v1/drivers/vehicles`  
**Method**: POST  
**Authentication**: JWT required (DRIVER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "make": "Honda",
  "model": "Accord",
  "year": 2023,
  "color": "Silver",
  "licensePlate": "XYZ789",
  "capacity": 4
}
```

**Response**:

```json
{
  "vehicle": {
    "id": "vehicle-uuid-2",
    "make": "Honda",
    "model": "Accord",
    "year": 2023,
    "color": "Silver",
    "licensePlate": "XYZ789",
    "capacity": 4,
    "status": "PENDING_VERIFICATION",
    "createdAt": "2026-02-10T15:00:00.000Z"
  }
}
```

---

## 4. RIDE REQUEST ENDPOINTS

### 4.1 Create Ride Request

**URL**: `http://localhost:3000/api/v1/ride-requests`  
**Method**: POST  
**Authentication**: JWT required (RIDER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "pickupLat": 37.7749,
  "pickupLng": -122.4194,
  "dropoffLat": 37.8049,
  "dropoffLng": -122.4494,
  "pickupAddress": "123 Market St, San Francisco, CA",
  "dropoffAddress": "456 Mission St, San Francisco, CA",
  "seats": 2
}
```

**Response**:

```json
{
  "rideRequest": {
    "id": "ride-request-uuid",
    "riderId": "550e8400-e29b-41d4-a716-446655440000",
    "pickupLocation": {
      "lat": 37.7749,
      "lng": -122.4194,
      "address": "123 Market St, San Francisco, CA"
    },
    "dropoffLocation": {
      "lat": 37.8049,
      "lng": -122.4494,
      "address": "456 Mission St, San Francisco, CA"
    },
    "seats": 2,
    "status": "PENDING",
    "estimatedFare": 15.5,
    "createdAt": "2026-02-10T15:05:00.000Z"
  }
}
```

---

### 4.2 Get Current Ride Request

**URL**: `http://localhost:3000/api/v1/ride-requests/current`  
**Method**: GET  
**Authentication**: JWT required (RIDER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "rideRequest": {
    "id": "ride-request-uuid",
    "status": "ACCEPTED",
    "driverId": "driver-uuid",
    "estimatedArrival": "5 minutes",
    "driver": {
      "name": "Driver Smith",
      "rating": 4.9,
      "vehicle": {
        "make": "Toyota",
        "model": "Camry",
        "color": "Blue",
        "licensePlate": "ABC123"
      }
    }
  }
}
```

---

### 4.3 Cancel Ride Request

**URL**: `http://localhost:3000/api/v1/ride-requests/{id}/cancel`  
**Method**: PATCH  
**Authentication**: JWT required (RIDER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "rideRequest": {
    "id": "ride-request-uuid",
    "status": "CANCELLED",
    "cancelledAt": "2026-02-10T15:10:00.000Z",
    "cancellationReason": "User requested cancellation"
  }
}
```

---

## 5. TRIP ENDPOINTS

### 5.1 Get Trip Details

**URL**: `http://localhost:3000/api/v1/trips/{id}`  
**Method**: GET  
**Authentication**: JWT required

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "trip": {
    "id": "trip-uuid",
    "rideRequestId": "ride-request-uuid",
    "driverId": "driver-uuid",
    "riderId": "rider-uuid",
    "status": "IN_PROGRESS",
    "pickupLocation": {
      "lat": 37.7749,
      "lng": -122.4194,
      "address": "123 Market St, San Francisco, CA"
    },
    "dropoffLocation": {
      "lat": 37.8049,
      "lng": -122.4494,
      "address": "456 Mission St, San Francisco, CA"
    },
    "startedAt": "2026-02-10T15:15:00.000Z",
    "currentLocation": {
      "lat": 37.7849,
      "lng": -122.4294
    },
    "estimatedArrival": "8 minutes"
  }
}
```

---

### 5.2 Update Driver Location

**URL**: `http://localhost:3000/api/v1/trips/{id}/location`  
**Method**: PATCH  
**Authentication**: JWT required (DRIVER role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "lat": 37.7899,
  "lng": -122.4344
}
```

**Response**:

```json
{
  "trip": {
    "id": "trip-uuid",
    "currentLocation": {
      "lat": 37.7899,
      "lng": -122.4344
    },
    "updatedAt": "2026-02-10T15:20:00.000Z"
  }
}
```

---

## 6. ADMIN ENDPOINTS

### 6.1 List All Users

**URL**: `http://localhost:3000/api/v1/admin/users`  
**Method**: GET  
**Authentication**: JWT required (ADMIN role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "users": [
    {
      "userId": "uuid-1",
      "fullName": "John Doe",
      "email": "john@example.com",
      "role": "RIDER",
      "status": "ACTIVE",
      "createdAt": "2026-01-15T10:00:00.000Z"
    },
    {
      "userId": "uuid-2",
      "fullName": "Driver Smith",
      "email": "driver@example.com",
      "role": "DRIVER",
      "status": "ACTIVE",
      "createdAt": "2026-01-20T12:00:00.000Z"
    }
  ],
  "total": 2,
  "page": 1,
  "limit": 20
}
```

---

### 6.2 Get User Details

**URL**: `http://localhost:3000/api/v1/admin/users/{userId}`  
**Method**: GET  
**Authentication**: JWT required (ADMIN role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "user": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "role": "RIDER",
    "status": "ACTIVE",
    "totalRides": 127,
    "rating": 4.8,
    "createdAt": "2026-01-15T10:00:00.000Z",
    "sessions": [],
    "recentActivity": []
  }
}
```

---

### 6.3 Suspend User

**URL**: `http://localhost:3000/api/v1/admin/users/suspend`  
**Method**: POST  
**Authentication**: JWT required (ADMIN role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body**:

```json
{
  "targetUserId": "550e8400-e29b-41d4-a716-446655440000",
  "reason": "Violation of terms of service"
}
```

**Response**:

```json
{
  "status": "suspended",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "suspendedAt": "2026-02-10T15:30:00.000Z",
  "reason": "Violation of terms of service",
  "suspendedBy": "admin-user-id"
}
```

---

### 6.4 Reinstate User

**URL**: `http://localhost:3000/api/v1/admin/users/{userId}/reinstate`  
**Method**: POST  
**Authentication**: JWT required (ADMIN role)

**Request Headers**:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response**:

```json
{
  "status": "active",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "reinstatedAt": "2026-02-10T15:35:00.000Z",
  "reinstatedBy": "admin-user-id"
}
```

---

## SUMMARY

**Total Endpoints**: 31  
**Base URL**: `http://localhost:3000/api/v1`

### Endpoints by Category:

- **Authentication**: 10 endpoints
- **Profile**: 6 endpoints
- **Driver**: 5 endpoints
- **Ride Requests**: 3 endpoints
- **Trips**: 2 endpoints
- **Admin**: 4 endpoints

### Authentication Notes:

- Public endpoints: Request OTP, Register (Rider/Driver), Verify OTP, Login
- Protected endpoints require: `Authorization: Bearer {access_token}`
- Role-specific endpoints require RIDER, DRIVER, or ADMIN role
- Refresh token endpoints require: `x-refresh-token-id` header

---

**Last Updated**: 2026-02-10  
**Server**: Backend (Port 3000)
