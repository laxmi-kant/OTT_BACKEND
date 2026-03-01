# OTT Platform — Frontend API Integration Guide

> **Version:** 1.0
> **Last Updated:** 2026-03-01
> **Environment:** Staging
> **Tested Against:** Live staging deployment on AWS EKS

---

## Table of Contents

1. [Base URLs](#base-urls)
2. [Authentication Flow](#authentication-flow)
3. [Common Response Format](#common-response-format)
4. [Error Handling](#error-handling)
5. [Auth Service APIs](#auth-service-apis)
6. [User Service APIs](#user-service-apis)
7. [Integration Recipes](#integration-recipes)
8. [HTTP Status Codes Reference](#http-status-codes-reference)

---

## Base URLs

| Service | Staging URL | Port | Health Check |
|---------|-------------|------|--------------|
| auth-service | `http://<AUTH_LB_HOST>` | 8082 | `GET /actuator/health` |
| user-service | `http://<USER_LB_HOST>` | 8081 | `GET /actuator/health` |

> **Note:** In production, both services sit behind AWS API Gateway. The frontend will use a single base URL (e.g., `https://api.ottnetwork.com`) with path-based routing. The API Gateway handles JWT validation via Lambda Authorizer before forwarding requests.

---

## Authentication Flow

OTT Platform uses **OTP-based authentication** (no passwords). The flow is:

### Registration Flow
```
┌─────────┐         ┌──────────────┐         ┌──────────────┐
│ Frontend │         │ auth-service │         │  OTP Delivery │
└────┬─────┘         └──────┬───────┘         └──────┬───────┘
     │  POST /register      │                        │
     │─────────────────────>│                        │
     │  201 (OTP sent)      │  Kafka event           │
     │<─────────────────────│───────────────────────>│
     │                      │           Email/SMS OTP │
     │                      │                        │
     │  POST /verify-otp    │                        │
     │─────────────────────>│                        │
     │  200 + JWT tokens    │                        │
     │<─────────────────────│                        │
```

### Login Flow
```
┌─────────┐         ┌──────────────┐
│ Frontend │         │ auth-service │
└────┬─────┘         └──────┬───────┘
     │  POST /login         │
     │─────────────────────>│
     │  200 (OTP sent)      │
     │<─────────────────────│
     │                      │
     │  POST /verify-otp    │
     │─────────────────────>│
     │  200 + JWT tokens    │
     │<─────────────────────│
```

### Token Lifecycle
```
┌─────────┐         ┌──────────────┐
│ Frontend │         │ auth-service │
└────┬─────┘         └──────┬───────┘
     │                      │
     │  (access token expires after 15 min)
     │                      │
     │  POST /refresh       │
     │─────────────────────>│
     │  200 + new tokens    │
     │<─────────────────────│
     │                      │
     │  POST /logout        │
     │─────────────────────>│
     │  200 (tokens revoked)│
     │<─────────────────────│
```

### Token Storage Recommendations
- **Access Token:** Store in memory (React state/context). Never in localStorage.
- **Refresh Token:** Store in httpOnly cookie (preferred) or secure storage.
- **Token Type:** Always `Bearer`
- **Access Token TTL:** 15 minutes (900 seconds)
- **Refresh Token TTL:** 7 days

### Authenticated Request Header
```
Authorization: Bearer <accessToken>
```

---

## Common Response Format

All APIs return a consistent `ApiResponse<T>` wrapper:

### Success Response
```json
{
  "success": true,
  "message": "Optional success message",
  "data": { ... },
  "timestamp": "2026-03-01T13:13:30.013892495"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Human-readable error description",
  "data": null,
  "timestamp": "2026-03-01T13:16:37.816249911"
}
```

### Validation Error Response (400)
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "fieldName": "Error message for this field",
    "anotherField": "Error message"
  },
  "timestamp": "2026-03-01T13:16:38.840895464"
}
```

### Paginated Response
```json
{
  "success": true,
  "data": {
    "content": [ ... ],
    "page": 0,
    "size": 20,
    "totalElements": 42,
    "totalPages": 3,
    "last": false
  },
  "timestamp": "2026-03-01T13:13:46.76940704"
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | When |
|------|---------|------|
| 200 | OK | Successful GET, PUT, DELETE, or action |
| 201 | Created | Successful POST (resource created) |
| 400 | Bad Request | Validation error, invalid OTP, malformed request |
| 401 | Unauthorized | Missing or expired access token |
| 403 | Forbidden | Token blacklisted, insufficient permissions |
| 404 | Not Found | Resource doesn't exist (user, profile, etc.) |
| 409 | Conflict | Duplicate resource (email already registered) |
| 429 | Too Many Requests | OTP rate limit exceeded (max 3 per 15 min) |
| 500 | Internal Server Error | Unexpected server error |

### Frontend Error Handling Strategy

```javascript
async function apiCall(url, options) {
  const response = await fetch(url, options);
  const data = await response.json();

  if (response.status === 401) {
    // Token expired — attempt refresh
    const refreshed = await refreshToken();
    if (refreshed) return apiCall(url, options); // retry
    else redirectToLogin();
  }

  if (response.status === 403) {
    // Token blacklisted (logged out) or insufficient role
    redirectToLogin();
  }

  if (!data.success) {
    // Handle application-level errors
    if (data.data && typeof data.data === 'object') {
      // Validation errors — show field-specific messages
      return { error: 'validation', fields: data.data };
    }
    return { error: data.message };
  }

  return data;
}
```

---

## Auth Service APIs

**Base Path:** `/api/v1/auth`

### API 1: Register User

Initiates OTP-based registration. Creates an unverified user record and sends OTP.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/auth/register` |
| **Auth Required** | No |
| **Content-Type** | `application/json` |
| **Success Status** | `201 Created` |

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "johndoe",
  "phone": "+919876543210"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| email | string | Yes | Valid email format |
| username | string | Yes | Not blank |
| phone | string | No | Phone number format |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Registration initiated. Please verify OTP.",
  "data": {
    "message": "OTP sent to user@example.com",
    "otpExpiresInSeconds": 300,
    "retryAfterSeconds": 300
  },
  "timestamp": "2026-03-01T13:12:07.257836008"
}
```

**Error Responses:**

| Status | Condition | Example Message |
|--------|-----------|-----------------|
| 400 | Missing required field | `{"username": "Username is required"}` |
| 409 | Email already registered | `"User already exists with email: 'user@example.com'"` |
| 429 | OTP rate limit (3/15min) | `"Too many OTP requests. Try again later."` |

---

### API 2: Login

Sends OTP to existing user's email for authentication.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/auth/login` |
| **Auth Required** | No |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

| Field | Type | Required |
|-------|------|----------|
| email | string | Yes |

**Success Response (200):**
```json
{
  "success": true,
  "message": "OTP sent. Please verify to login.",
  "data": {
    "message": "OTP sent to user@example.com",
    "otpExpiresInSeconds": 300,
    "retryAfterSeconds": 300
  },
  "timestamp": "2026-03-01T13:12:56.059814779"
}
```

**Error Responses:**

| Status | Condition | Example Message |
|--------|-----------|-----------------|
| 404 | Email not registered | `"User not found with email: 'nonexistent@example.com'"` |
| 429 | OTP rate limit | `"Too many OTP requests. Try again later."` |

---

### API 3: Verify OTP

Validates OTP and issues JWT access + refresh tokens. Used for both registration and login flows.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/auth/verify-otp` |
| **Auth Required** | No |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "883410"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| email | string | Yes | Email used in register/login |
| otp | string | Yes | 6-digit OTP code |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Authentication successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzUxMiJ9...",
    "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "userId": "ec1b87d3-4011-45d9-a79c-8743e1d9b7c7",
    "email": "user@example.com",
    "role": "SUBSCRIBER"
  },
  "timestamp": "2026-03-01T13:12:26.301007314"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| accessToken | string | JWT for API authentication (15 min TTL) |
| refreshToken | string | JWT for obtaining new access tokens (7 day TTL) |
| tokenType | string | Always `"Bearer"` |
| expiresIn | integer | Access token TTL in seconds (900 = 15 min) |
| userId | UUID | User's auth ID (use for cross-referencing) |
| email | string | User's email |
| role | string | `ADMIN`, `SUBSCRIBER`, `CONTENT_CREATOR`, or `USER` |

**Error Responses:**

| Status | Condition | Example Message |
|--------|-----------|-----------------|
| 400 | Wrong OTP or expired | `"OTP has expired or was not requested"` |
| 400 | Invalid OTP format | `"Invalid OTP"` |
| 400 | Max attempts exceeded | `"Maximum verification attempts reached"` |

> **Important:** OTP expires after **5 minutes**. Maximum **5 verification attempts** per OTP.

---

### API 4: Resend OTP

Resends OTP to the user's email. Requires an active OTP session (after login/register).

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/auth/resend-otp` |
| **Auth Required** | No |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Request Body:**
```json
{
  "email": "user@example.com",
  "purpose": "LOGIN"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| email | string | Yes | Email used in register/login |
| purpose | string | Yes | `"LOGIN"` or `"REGISTER"` |

**Success Response (200):**
```json
{
  "success": true,
  "message": "OTP resent",
  "data": {
    "message": "OTP resent to user@example.com",
    "otpExpiresInSeconds": 300,
    "retryAfterSeconds": 300
  },
  "timestamp": "2026-03-01T13:13:06.079187548"
}
```

**Error Responses:**

| Status | Condition | Example Message |
|--------|-----------|-----------------|
| 429 | Rate limit (max 3 per 15 min) | `"Too many OTP requests. Try again later."` |

---

### API 5: Refresh Token

Exchanges a valid refresh token for new access + refresh token pair.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/auth/refresh` |
| **Auth Required** | No (uses refresh token in body) |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzUxMiJ9..."
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "accessToken": "eyJhbGciOiJIUzUxMiJ9...",
    "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "userId": "a0000001-0000-0000-0000-000000000001",
    "email": "admin@ottnetwork.com",
    "role": "ADMIN"
  },
  "timestamp": "2026-03-01T13:13:16.294650002"
}
```

> **Important:** The old refresh token is invalidated after use. Always store the **new** refresh token from the response.

**Error Responses:**

| Status | Condition | Example Message |
|--------|-----------|-----------------|
| 400 | Invalid/expired refresh token | `"Invalid refresh token"` |
| 400 | Refresh token already used | `"Refresh token has been revoked"` |

---

### API 6: Logout

Blacklists the current access token and revokes all refresh tokens for the user.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/auth/logout` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Request Headers:**
```
Authorization: Bearer <accessToken>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "timestamp": "2026-03-01T13:15:44.316035437"
}
```

> After logout, the access token is blacklisted in Redis. Any API call with the same token returns `403 Forbidden`.

---

## User Service APIs

**Base Path:** `/api/v1/users`
**Authentication:** All endpoints require `Authorization: Bearer <accessToken>` header.

### User Object Schema

```typescript
interface User {
  id: string;              // UUID — user-service internal ID
  authUserId: string;      // UUID — auth-service ID (from JWT)
  email: string;
  username: string;
  firstName: string | null;
  lastName: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  phone: string | null;
  dateOfBirth: string | null;  // "YYYY-MM-DD"
  role: "ADMIN" | "SUBSCRIBER" | "CONTENT_CREATOR" | "USER";
  subscriptionTier: "FREE" | "BASIC" | "STANDARD" | "PREMIUM";
  active: boolean;
  createdAt: string;       // ISO 8601 datetime
  updatedAt: string;       // ISO 8601 datetime
}
```

---

### API 7: Get Current User

Returns the authenticated user's profile.

| | |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/users/me` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "b0000001-0000-0000-0000-000000000001",
    "authUserId": "a0000001-0000-0000-0000-000000000001",
    "email": "admin@ottnetwork.com",
    "username": "admin",
    "firstName": "System",
    "lastName": "Admin",
    "displayName": "OTT Admin",
    "avatarUrl": "/avatars/admin.png",
    "phone": "+1-555-0001",
    "dateOfBirth": "1985-03-15",
    "role": "ADMIN",
    "subscriptionTier": "PREMIUM",
    "active": true,
    "createdAt": "2026-02-28T19:54:31.736455",
    "updatedAt": "2026-03-01T13:13:46.178476"
  },
  "timestamp": "2026-03-01T13:13:30.013892495"
}
```

---

### API 8: Update Current User

Updates the authenticated user's profile fields.

| | |
|---|---|
| **Method** | `PUT` |
| **Path** | `/api/v1/users/me` |
| **Auth Required** | Yes |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Request Body (all fields optional):**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "displayName": "Johnny",
  "avatarUrl": "https://cdn.example.com/avatar.jpg",
  "phone": "+919876543210",
  "dateOfBirth": "1990-05-15"
}
```

| Field | Type | Max Length | Notes |
|-------|------|-----------|-------|
| firstName | string | 100 | |
| lastName | string | 100 | |
| displayName | string | 100 | |
| avatarUrl | string | 512 | URL to avatar image |
| phone | string | 20 | |
| dateOfBirth | string | — | ISO format `YYYY-MM-DD` |

**Response (200):**
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "id": "b0000001-0000-0000-0000-000000000001",
    "authUserId": "a0000001-0000-0000-0000-000000000001",
    "email": "admin@ottnetwork.com",
    "username": "admin",
    "firstName": "John",
    "lastName": "Doe",
    "displayName": "Johnny",
    "avatarUrl": "https://cdn.example.com/avatar.jpg",
    "phone": "+919876543210",
    "dateOfBirth": "1990-05-15",
    "role": "ADMIN",
    "subscriptionTier": "PREMIUM",
    "active": true,
    "createdAt": "2026-02-28T19:54:31.736455",
    "updatedAt": "2026-03-01T13:13:46.203835306"
  },
  "timestamp": "2026-03-01T13:13:46.203835306"
}
```

---

### API 9: Get User by ID

Returns a specific user's profile by their user-service ID.

| | |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/users/{userId}` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| userId | UUID | User's ID (user-service `id`, not `authUserId`) |

**Response (200):** Same as [Get Current User](#api-7-get-current-user).

**Error Responses:**

| Status | Condition | Example Message |
|--------|-----------|-----------------|
| 404 | User not found | `"User not found with id: '99999999-...'"` |

---

### API 10: List All Users (Admin Only)

Returns a paginated list of all users. Requires ADMIN role.

| | |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/users` |
| **Auth Required** | Yes (ADMIN) |
| **Success Status** | `200 OK` |

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 0 | Page number (0-indexed) |
| size | integer | 20 | Items per page |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "b0000001-0000-0000-0000-000000000002",
        "email": "creator@ottnetwork.com",
        "username": "creator_john",
        "firstName": "John",
        "lastName": "Director",
        "displayName": "John D.",
        "role": "CONTENT_CREATOR",
        "subscriptionTier": "STANDARD",
        "active": true,
        "createdAt": "2026-02-28T19:54:31.736455",
        "updatedAt": "2026-02-28T19:54:31.736455"
      }
    ],
    "page": 0,
    "size": 5,
    "totalElements": 7,
    "totalPages": 2,
    "last": false
  },
  "timestamp": "2026-03-01T13:13:46.76940704"
}
```

---

### API 11: Deactivate Account

Soft-deletes the current user's account (sets `active = false`). Publishes `ott.user.deleted` Kafka event.

| | |
|---|---|
| **Method** | `DELETE` |
| **Path** | `/api/v1/users/me` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Response (200):**
```json
{
  "success": true,
  "message": "Account deactivated successfully",
  "timestamp": "2026-03-01T13:15:34.798984646"
}
```

> **Warning:** This deactivates the account. The user won't be able to log in until reactivated by an admin.

---

### API 12: List Profiles

Returns all profiles for the current user. Each user can have multiple profiles (like Netflix profiles).

| | |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/users/me/profiles` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Profile Object Schema:**
```typescript
interface Profile {
  id: string;              // UUID
  userId: string;          // UUID — parent user ID
  bio: string | null;
  language: string | null; // e.g., "en", "hi"
  country: string | null;  // e.g., "India", "US"
  timezone: string | null; // e.g., "Asia/Kolkata"
  profileImageUrl: string | null;
  createdAt: string;
  updatedAt: string;
}
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "b1000001-0000-0000-0000-000000000001",
      "userId": "b0000001-0000-0000-0000-000000000001",
      "bio": "Platform administrator",
      "language": "en",
      "country": "US",
      "timezone": "America/New_York",
      "profileImageUrl": "/profiles/admin.png",
      "createdAt": "2026-02-28T19:54:31.779162",
      "updatedAt": "2026-02-28T19:54:31.779162"
    }
  ],
  "timestamp": "2026-03-01T13:14:01.888498804"
}
```

---

### API 13: Create Profile

Creates a new profile for the current user.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/users/me/profiles` |
| **Auth Required** | Yes |
| **Content-Type** | `application/json` |
| **Success Status** | `201 Created` |

**Request Body (all fields optional):**
```json
{
  "bio": "Movie enthusiast",
  "language": "en",
  "country": "India",
  "timezone": "Asia/Kolkata",
  "profileImageUrl": "/avatars/profile2.png"
}
```

| Field | Type | Max Length |
|-------|------|-----------|
| bio | string | 500 |
| language | string | 10 |
| country | string | 100 |
| timezone | string | 50 |
| profileImageUrl | string | 512 |

**Response (201):**
```json
{
  "success": true,
  "message": "Profile created successfully",
  "data": {
    "id": "ba1d4ffa-73e9-4d38-9c99-879cfc7ae2bf",
    "userId": "b0000001-0000-0000-0000-000000000001",
    "bio": "Movie enthusiast",
    "language": "en",
    "country": "India",
    "timezone": "Asia/Kolkata",
    "profileImageUrl": "/avatars/profile2.png",
    "createdAt": "2026-03-01T13:14:02.586577115",
    "updatedAt": "2026-03-01T13:14:02.586605181"
  },
  "timestamp": "2026-03-01T13:14:02.701425264"
}
```

---

### API 14: Update Profile

Updates an existing profile.

| | |
|---|---|
| **Method** | `PUT` |
| **Path** | `/api/v1/users/me/profiles/{profileId}` |
| **Auth Required** | Yes |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| profileId | UUID | Profile ID from List/Create response |

**Request Body (all fields optional):**
```json
{
  "bio": "Updated bio text",
  "country": "India",
  "timezone": "Asia/Kolkata"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "ba1d4ffa-73e9-4d38-9c99-879cfc7ae2bf",
    "userId": "b0000001-0000-0000-0000-000000000001",
    "bio": "Updated bio text",
    "language": "en",
    "country": "India",
    "timezone": "Asia/Kolkata",
    "profileImageUrl": "/avatars/profile2.png",
    "createdAt": "2026-03-01T13:14:02.586577",
    "updatedAt": "2026-03-01T13:14:02.586605"
  },
  "timestamp": "2026-03-01T13:14:03.074760738"
}
```

---

### API 15: Delete Profile

Deletes a profile. Users must have at least one profile remaining.

| | |
|---|---|
| **Method** | `DELETE` |
| **Path** | `/api/v1/users/me/profiles/{profileId}` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Response (200):**
```json
{
  "success": true,
  "message": "Profile deleted successfully",
  "timestamp": "2026-03-01T13:14:41.381600672"
}
```

---

### API 16: Get Preferences

Returns the current user's viewing/notification preferences.

| | |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/users/me/preferences` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Preferences Object Schema:**
```typescript
interface Preferences {
  id: string;
  userId: string;
  emailNotifications: boolean;
  pushNotifications: boolean;
  autoplayEnabled: boolean;
  defaultVideoQuality: "AUTO" | "SD" | "HD" | "FULL_HD" | "4K";
  subtitlesEnabled: boolean;
  preferredLanguage: string;
  parentalControlEnabled: boolean;
  maturityRating: "ALL" | "PG" | "PG13" | "R" | "NC17";
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "b2000001-0000-0000-0000-000000000001",
    "userId": "b0000001-0000-0000-0000-000000000001",
    "emailNotifications": true,
    "pushNotifications": true,
    "autoplayEnabled": true,
    "defaultVideoQuality": "HD",
    "subtitlesEnabled": false,
    "preferredLanguage": "en",
    "parentalControlEnabled": false,
    "maturityRating": "R"
  },
  "timestamp": "2026-03-01T13:14:26.597325997"
}
```

---

### API 17: Update Preferences

Updates the current user's preferences. Only send fields you want to change.

| | |
|---|---|
| **Method** | `PUT` |
| **Path** | `/api/v1/users/me/preferences` |
| **Auth Required** | Yes |
| **Content-Type** | `application/json` |
| **Success Status** | `200 OK` |

**Request Body (all fields optional):**
```json
{
  "emailNotifications": true,
  "pushNotifications": true,
  "autoplayEnabled": true,
  "defaultVideoQuality": "HD",
  "subtitlesEnabled": false,
  "preferredLanguage": "en",
  "parentalControlEnabled": false,
  "parentalControlPin": "1234",
  "maturityRating": "R"
}
```

| Field | Type | Values |
|-------|------|--------|
| emailNotifications | boolean | |
| pushNotifications | boolean | |
| autoplayEnabled | boolean | |
| defaultVideoQuality | string | `AUTO`, `SD`, `HD`, `FULL_HD`, `4K` |
| subtitlesEnabled | boolean | |
| preferredLanguage | string | ISO 639-1 code (e.g., `en`, `hi`, `es`) |
| parentalControlEnabled | boolean | |
| parentalControlPin | string | PIN for parental control |
| maturityRating | string | `ALL`, `PG`, `PG13`, `R`, `NC17` |

**Response (200):**
```json
{
  "success": true,
  "message": "Preferences updated successfully",
  "data": {
    "id": "b2000001-0000-0000-0000-000000000001",
    "userId": "b0000001-0000-0000-0000-000000000001",
    "emailNotifications": true,
    "pushNotifications": true,
    "autoplayEnabled": true,
    "defaultVideoQuality": "HD",
    "subtitlesEnabled": false,
    "preferredLanguage": "en",
    "parentalControlEnabled": false,
    "maturityRating": "R"
  },
  "timestamp": "2026-03-01T13:14:26.805832833"
}
```

---

### API 18: List Devices

Returns all registered devices for the current user.

| | |
|---|---|
| **Method** | `GET` |
| **Path** | `/api/v1/users/me/devices` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Device Object Schema:**
```typescript
interface Device {
  id: string;              // UUID — database ID
  deviceId: string;        // Client-generated device identifier
  deviceName: string | null;
  deviceType: "MOBILE" | "TABLET" | "DESKTOP" | "TV" | "WEB" | "LAPTOP" | null;
  platform: "IOS" | "ANDROID" | "WEB" | "SMART_TV" | "FIRE_TV" | "MACOS" | null;
  lastActiveAt: string;    // ISO 8601 datetime
  pushToken: string | null;
  createdAt: string;
}
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "b3000001-0000-0000-0000-000000000001",
      "deviceId": "dev-admin-macbook",
      "deviceName": "Admin MacBook Pro",
      "deviceType": "LAPTOP",
      "platform": "MACOS",
      "lastActiveAt": "2026-02-28T18:54:31.852117",
      "pushToken": "push-token-admin-001",
      "createdAt": "2026-02-28T19:54:31.852117"
    }
  ],
  "timestamp": "2026-03-01T13:14:27.064046857"
}
```

---

### API 19: Register Device

Registers a new device for the current user. If a device with the same `deviceId` already exists, it updates it.

| | |
|---|---|
| **Method** | `POST` |
| **Path** | `/api/v1/users/me/devices` |
| **Auth Required** | Yes |
| **Content-Type** | `application/json` |
| **Success Status** | `201 Created` |

**Request Body:**
```json
{
  "deviceId": "iphone-15-pro-max-001",
  "deviceName": "iPhone 15 Pro Max",
  "deviceType": "MOBILE",
  "platform": "IOS",
  "pushToken": "fcm-token-abc123"
}
```

| Field | Type | Required | Max Length | Notes |
|-------|------|----------|-----------|-------|
| deviceId | string | Yes | 255 | Unique client-generated identifier |
| deviceName | string | No | 255 | Human-readable name |
| deviceType | string | No | 50 | `MOBILE`, `TABLET`, `DESKTOP`, `TV`, `WEB` |
| platform | string | No | 50 | `IOS`, `ANDROID`, `WEB`, `SMART_TV`, `FIRE_TV` |
| pushToken | string | No | 512 | FCM/APNs push notification token |

**Response (201):**
```json
{
  "success": true,
  "message": "Device registered successfully",
  "data": {
    "id": "14887ba7-26d1-4011-9df8-3d20fa40d567",
    "deviceId": "iphone-15-pro-max-001",
    "deviceName": "iPhone 15 Pro Max",
    "deviceType": "MOBILE",
    "platform": "IOS",
    "lastActiveAt": "2026-03-01T13:14:27.276480402",
    "pushToken": "fcm-token-abc123",
    "createdAt": "2026-03-01T13:14:27.277350464"
  },
  "timestamp": "2026-03-01T13:14:27.287678439"
}
```

---

### API 20: Remove Device

Removes a registered device by its client-generated `deviceId` (not the database UUID).

| | |
|---|---|
| **Method** | `DELETE` |
| **Path** | `/api/v1/users/me/devices/{deviceId}` |
| **Auth Required** | Yes |
| **Success Status** | `200 OK` |

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| deviceId | string | Client-generated device identifier (not UUID) |

**Response (200):**
```json
{
  "success": true,
  "message": "Device removed successfully",
  "timestamp": "2026-03-01T13:14:40.470265364"
}
```

---

## Integration Recipes

### Recipe 1: Complete Registration Flow

```javascript
// Step 1: Register
const registerResponse = await fetch('/api/v1/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    username: 'johndoe',
    phone: '+919876543210'
  })
});
// 201 → show OTP input screen, start 5-min countdown

// Step 2: User enters OTP
const verifyResponse = await fetch('/api/v1/auth/verify-otp', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    otp: '883410'
  })
});
const { accessToken, refreshToken, userId, role } = verifyResponse.data;
// Store tokens, redirect to home/onboarding

// Step 3: Fetch user profile
const userResponse = await fetch('/api/v1/users/me', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});
const user = userResponse.data;
```

### Recipe 2: Complete Login Flow

```javascript
// Step 1: Request OTP
await fetch('/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'user@example.com' })
});
// 200 → show OTP input screen

// Step 2: Verify OTP
const { data } = await fetch('/api/v1/auth/verify-otp', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'user@example.com', otp: '123456' })
});
// Store data.accessToken and data.refreshToken
// Redirect to home
```

### Recipe 3: Auto-Refresh Token (Axios Interceptor)

```javascript
import axios from 'axios';

const api = axios.create({ baseURL: '/api/v1' });
let isRefreshing = false;
let failedQueue = [];

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then(token => {
          originalRequest.headers['Authorization'] = `Bearer ${token}`;
          return api(originalRequest);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const { data } = await axios.post('/api/v1/auth/refresh', {
          refreshToken: getStoredRefreshToken()
        });

        storeTokens(data.data.accessToken, data.data.refreshToken);

        failedQueue.forEach(({ resolve }) => resolve(data.data.accessToken));
        failedQueue = [];

        originalRequest.headers['Authorization'] = `Bearer ${data.data.accessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        failedQueue.forEach(({ reject }) => reject(refreshError));
        failedQueue = [];
        redirectToLogin();
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);
```

### Recipe 4: Profile Switcher (like Netflix)

```javascript
// Load all profiles on app start
const profiles = await api.get('/users/me/profiles');
// Show profile selection UI

// After user selects a profile, store profileId in state
// Use profile's language/timezone for content localization

// Create new profile
const newProfile = await api.post('/users/me/profiles', {
  bio: 'Kids profile',
  language: 'en',
  country: 'India'
});
```

### Recipe 5: Device Registration on App Launch

```javascript
// Generate a stable device ID (persisted in device storage)
const deviceId = await getOrCreateDeviceId();

// Register/update device on every app launch
await api.post('/users/me/devices', {
  deviceId: deviceId,
  deviceName: getDeviceName(),       // e.g., "iPhone 15 Pro"
  deviceType: getDeviceType(),       // "MOBILE", "WEB", "TV"
  platform: getPlatform(),           // "IOS", "ANDROID", "WEB"
  pushToken: await getFCMToken()     // Firebase push token
});
```

### Recipe 6: Settings Page

```javascript
// Load preferences
const prefs = await api.get('/users/me/preferences');

// Update single preference (e.g., toggle dark mode autoplay)
await api.put('/users/me/preferences', {
  autoplayEnabled: false
});

// Update parental controls
await api.put('/users/me/preferences', {
  parentalControlEnabled: true,
  parentalControlPin: '1234',
  maturityRating: 'PG13'
});
```

---

## HTTP Status Codes Reference

| Code | Auth Service | User Service |
|------|-------------|--------------|
| **200** | Login OTP sent, OTP verified, Token refreshed, Logged out | User fetched, User updated, Profile updated, Preferences updated, Device removed, Account deactivated |
| **201** | Registration initiated | Profile created, Device registered |
| **400** | Invalid/expired OTP, Validation error, Max attempts | Validation error |
| **401** | — | Missing/expired access token |
| **403** | — | Blacklisted token, insufficient role |
| **404** | User not found (login) | User/Profile/Device not found |
| **409** | Email already registered | — |
| **429** | OTP rate limit exceeded | — |
| **500** | Server error | Server error |

---

## API Quick Reference Card

### Auth Service (`/api/v1/auth`)

| # | Method | Path | Auth | Status | Description |
|---|--------|------|------|--------|-------------|
| 1 | POST | `/register` | No | 201 | Start registration, send OTP |
| 2 | POST | `/login` | No | 200 | Send login OTP |
| 3 | POST | `/verify-otp` | No | 200 | Verify OTP, get JWT tokens |
| 4 | POST | `/resend-otp` | No | 200 | Resend OTP |
| 5 | POST | `/refresh` | No | 200 | Refresh JWT tokens |
| 6 | POST | `/logout` | Yes | 200 | Invalidate tokens |

### User Service (`/api/v1/users`)

| # | Method | Path | Auth | Status | Description |
|---|--------|------|------|--------|-------------|
| 7 | GET | `/me` | Yes | 200 | Get current user |
| 8 | PUT | `/me` | Yes | 200 | Update current user |
| 9 | GET | `/{userId}` | Yes | 200 | Get user by ID |
| 10 | GET | `/` | Yes (Admin) | 200 | List all users (paginated) |
| 11 | DELETE | `/me` | Yes | 200 | Deactivate account |
| 12 | GET | `/me/profiles` | Yes | 200 | List profiles |
| 13 | POST | `/me/profiles` | Yes | 201 | Create profile |
| 14 | PUT | `/me/profiles/{profileId}` | Yes | 200 | Update profile |
| 15 | DELETE | `/me/profiles/{profileId}` | Yes | 200 | Delete profile |
| 16 | GET | `/me/preferences` | Yes | 200 | Get preferences |
| 17 | PUT | `/me/preferences` | Yes | 200 | Update preferences |
| 18 | GET | `/me/devices` | Yes | 200 | List devices |
| 19 | POST | `/me/devices` | Yes | 201 | Register device |
| 20 | DELETE | `/me/devices/{deviceId}` | Yes | 200 | Remove device |

---

## Notes for Frontend Team

1. **IDs:** There are two user IDs:
   - `authUserId` (from auth-service) — returned in JWT token as `userId`
   - `id` (from user-service) — the user-service internal ID
   - The JWT `sub` claim contains the `authUserId`. user-service maps it internally.
   - Frontend should primarily use the JWT `userId` for display/routing.

2. **Timestamps:** All timestamps are in ISO 8601 format (UTC). Convert to user's timezone for display.

3. **Pagination:** List endpoints use 0-indexed pages. Default page size is 20.

4. **OTP Timing:**
   - OTP expires in 5 minutes (300 seconds)
   - Max 3 OTP requests per email per 15 minutes
   - Max 5 verification attempts per OTP
   - Show a countdown timer on the OTP input screen using `otpExpiresInSeconds`

5. **Token Handling:**
   - Access token expires in 15 minutes
   - Implement auto-refresh using the refresh token (see Recipe 3)
   - On 403 after logout, clear all stored tokens and redirect to login

6. **Device ID:**
   - Use `deviceId` (client-generated string) for DELETE, not the database UUID `id`
   - Generate a stable device identifier per device installation
   - Re-register device on every app launch to update `pushToken` and `lastActiveAt`
