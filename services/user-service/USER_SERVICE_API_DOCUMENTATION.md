# User Service - API Documentation

**Staging Base URL:** `http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081`
**API Version:** v1
**Content-Type:** `application/json`
**Authentication:** Bearer JWT Token (required for all endpoints except public paths)

> **Environment URLs:**
> | Environment | Base URL |
> |-------------|----------|
> | Staging | `http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081` |
> | Production | TBD (behind AWS API Gateway) |

---

## Table of Contents

1. [Authentication](#authentication)
2. [Response Format](#response-format)
3. [Error Responses](#error-responses)
4. [User APIs](#user-apis)
   - [Get Current User](#1-get-current-user)
   - [Update Current User](#2-update-current-user)
   - [Get User by ID](#3-get-user-by-id)
   - [List All Users (Admin)](#4-list-all-users-admin)
   - [Deactivate Account](#5-deactivate-account)
5. [Profile APIs](#profile-apis)
   - [List Profiles](#6-list-profiles)
   - [Create Profile](#7-create-profile)
   - [Update Profile](#8-update-profile)
   - [Delete Profile](#9-delete-profile)
6. [Preference APIs](#preference-apis)
   - [Get Preferences](#10-get-preferences)
   - [Update Preferences](#11-update-preferences)
7. [Device APIs](#device-apis)
   - [List Devices](#12-list-devices)
   - [Register Device](#13-register-device)
   - [Remove Device](#14-remove-device)

---

## Authentication

All endpoints (except public paths) require a valid JWT token in the `Authorization` header.

```
Authorization: Bearer <jwt_access_token>
```

**Public Paths (no auth required):**
- `/actuator/**`
- `/swagger-ui/**`
- `/v3/api-docs/**`

**JWT Token Claims:**
| Claim | Type | Description |
|-------|------|-------------|
| `sub` | UUID | Auth user ID |
| `email` | String | User's email |
| `roles` | String[] | User roles (USER, ADMIN, CONTENT_CREATOR, SUBSCRIBER) |
| `type` | String | Token type (ACCESS) |
| `iat` | Timestamp | Issued at |
| `exp` | Timestamp | Expiration (15 min for access tokens) |

---

## Response Format

All responses are wrapped in a standard `ApiResponse<T>` envelope:

**Success Response:**
```json
{
  "success": true,
  "message": "Optional success message",
  "data": { },
  "timestamp": "2026-03-01T10:19:24.604167868"
}
```

**Paginated Response:**
```json
{
  "success": true,
  "data": {
    "content": [],
    "page": 0,
    "size": 20,
    "totalElements": 6,
    "totalPages": 1,
    "last": true
  },
  "timestamp": "2026-03-01T10:14:23.559514769"
}
```

---

## Error Responses

| HTTP Code | Scenario | Example |
|-----------|----------|---------|
| 400 | Validation error | Missing required fields, exceeds size limits |
| 401 | Unauthorized | Missing or invalid JWT token |
| 403 | Forbidden | Insufficient role (e.g., non-admin accessing admin endpoint) |
| 404 | Not found | User/profile/device not found |
| 409 | Conflict | Duplicate resource |
| 500 | Server error | Internal server error |

**Validation Error Response (400):**
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "deviceId": "must not be blank"
  },
  "timestamp": "2026-03-01T10:20:30.196657843"
}
```

**Not Found Error Response (404):**
```json
{
  "success": false,
  "message": "User not found with authUserId: 'd0b0caf4-029b-47a6-b5c4-34bbb371b47c'",
  "timestamp": "2026-03-01T10:11:29.410221162"
}
```

**Unauthorized Response (401):**
```json
{
  "success": false,
  "message": "Unauthorized",
  "timestamp": "2026-03-01T10:08:33.364000000"
}
```

---

## User APIs

### 1. Get Current User

Retrieves the authenticated user's full profile.

**Endpoint:** `GET /api/v1/users/me`
**Auth:** Required
**Role:** Any authenticated user

**Request:**
```bash
curl -X GET http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "authUserId": "d0b0caf4-029b-47a6-b5c4-34bbb371b47c",
    "email": "testuser@ottnetwork.com",
    "username": "testuser",
    "firstName": "Test",
    "lastName": "User",
    "displayName": "Test User",
    "avatarUrl": null,
    "phone": null,
    "dateOfBirth": null,
    "role": "USER",
    "subscriptionTier": "FREE",
    "active": true,
    "createdAt": "2026-03-01T10:12:53.533463",
    "updatedAt": "2026-03-01T10:12:53.533463"
  },
  "timestamp": "2026-03-01T10:19:24.604167868"
}
```

**Response Fields:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | UUID | No | Database user ID |
| authUserId | UUID | No | Auth service user ID (cross-service reference) |
| email | String | No | User's email address |
| username | String | No | Unique username |
| firstName | String | Yes | First name |
| lastName | String | Yes | Last name |
| displayName | String | Yes | Display name |
| avatarUrl | String | Yes | URL to avatar image |
| phone | String | Yes | Phone number |
| dateOfBirth | Date | Yes | Date of birth (YYYY-MM-DD) |
| role | String | No | User role: USER, ADMIN, CONTENT_CREATOR, SUBSCRIBER |
| subscriptionTier | String | No | Subscription tier: FREE, BASIC, STANDARD, PREMIUM |
| active | Boolean | No | Whether the account is active |
| createdAt | DateTime | No | Account creation timestamp |
| updatedAt | DateTime | No | Last update timestamp |

> **Note:** Null fields are omitted from the response (uses `@JsonInclude(NON_NULL)`).

---

### 2. Update Current User

Updates the authenticated user's profile information.

**Endpoint:** `PUT /api/v1/users/me`
**Auth:** Required
**Role:** Any authenticated user

**Request Body:**
```json
{
  "firstName": "TestUpdated",
  "lastName": "UserUpdated",
  "displayName": "Updated User",
  "avatarUrl": "/avatars/custom.png",
  "phone": "+919876543210",
  "dateOfBirth": "1995-06-15"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| firstName | String | No | max 100 chars | First name |
| lastName | String | No | max 100 chars | Last name |
| displayName | String | No | max 100 chars | Display name |
| avatarUrl | String | No | max 512 chars | Avatar image URL |
| phone | String | No | max 20 chars | Phone number |
| dateOfBirth | Date | No | ISO format (YYYY-MM-DD) | Date of birth |

> **Note:** All fields are optional. Only provided fields will be updated. Omitted fields remain unchanged.

```bash
curl -X PUT http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "TestUpdated",
    "lastName": "UserUpdated",
    "displayName": "Updated User",
    "phone": "+919876543210"
  }'
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "User updated successfully",
  "data": {
    "id": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "authUserId": "d0b0caf4-029b-47a6-b5c4-34bbb371b47c",
    "email": "testuser@ottnetwork.com",
    "username": "testuser",
    "firstName": "TestUpdated",
    "lastName": "UserUpdated",
    "displayName": "Updated User",
    "phone": "+919876543210",
    "role": "USER",
    "subscriptionTier": "FREE",
    "active": true,
    "createdAt": "2026-03-01T10:12:53.533463",
    "updatedAt": "2026-03-01T10:19:24.915004"
  },
  "timestamp": "2026-03-01T10:19:24.967514537"
}
```

> **Note:** This endpoint publishes a `ott.user.profile-updated` Kafka event upon successful update.

---

### 3. Get User by ID

Retrieves a user's details by their database UUID.

**Endpoint:** `GET /api/v1/users/{userId}`
**Auth:** Required
**Role:** Any authenticated user

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| userId | UUID | The user's database ID (not authUserId) |

```bash
curl -X GET http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/43fddf6f-a57f-4c8a-8c98-bbe71008e271 \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "authUserId": "d0b0caf4-029b-47a6-b5c4-34bbb371b47c",
    "email": "testuser@ottnetwork.com",
    "username": "testuser",
    "firstName": "TestUpdated",
    "lastName": "UserUpdated",
    "displayName": "Updated User",
    "phone": "+919876543210",
    "role": "USER",
    "subscriptionTier": "FREE",
    "active": true,
    "createdAt": "2026-03-01T10:12:53.533463",
    "updatedAt": "2026-03-01T10:19:24.915004"
  },
  "timestamp": "2026-03-01T10:19:25.121920151"
}
```

**Error Response (404 Not Found):**
```json
{
  "success": false,
  "message": "User not found with id: '00000000-0000-0000-0000-000000000000'",
  "timestamp": "2026-03-01T10:20:00.000000000"
}
```

---

### 4. List All Users (Admin)

Lists all active users with pagination. **Admin-only endpoint.**

**Endpoint:** `GET /api/v1/users`
**Auth:** Required
**Role:** ADMIN only (`@PreAuthorize("hasRole('ADMIN')")`)

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | Integer | 0 | Page number (zero-based) |
| size | Integer | 20 | Page size |
| sort | String | - | Sort field and direction (e.g., `createdAt,desc`) |

```bash
curl -X GET "http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users?page=0&size=5" \
  -H "Authorization: Bearer <admin_token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "b0000001-0000-0000-0000-000000000001",
        "authUserId": "a0000001-0000-0000-0000-000000000001",
        "email": "admin@ottnetwork.com",
        "username": "admin",
        "firstName": "System",
        "lastName": "Admin",
        "displayName": "Admin",
        "avatarUrl": "/avatars/admin.png",
        "phone": "+1-555-0001",
        "dateOfBirth": "1985-03-15",
        "role": "ADMIN",
        "subscriptionTier": "PREMIUM",
        "active": true,
        "createdAt": "2026-02-28T19:54:31.736455",
        "updatedAt": "2026-02-28T19:54:31.736455"
      },
      {
        "id": "b0000001-0000-0000-0000-000000000002",
        "authUserId": "a0000001-0000-0000-0000-000000000002",
        "email": "creator@ottnetwork.com",
        "username": "creator_john",
        "firstName": "John",
        "lastName": "Director",
        "displayName": "John D.",
        "avatarUrl": "/avatars/john.png",
        "phone": "+1-555-0002",
        "dateOfBirth": "1990-07-22",
        "role": "CONTENT_CREATOR",
        "subscriptionTier": "STANDARD",
        "active": true,
        "createdAt": "2026-02-28T19:54:31.736455",
        "updatedAt": "2026-02-28T19:54:31.736455"
      }
    ],
    "page": 0,
    "size": 5,
    "totalElements": 6,
    "totalPages": 2,
    "last": false
  },
  "timestamp": "2026-03-01T10:14:23.559514769"
}
```

**Error Response (403 Forbidden) — Non-admin user:**
```json
{
  "success": false,
  "message": "Access Denied",
  "timestamp": "2026-03-01T10:20:00.000000000"
}
```

---

### 5. Deactivate Account

Soft-deletes the authenticated user's account by marking it as inactive.

**Endpoint:** `DELETE /api/v1/users/me`
**Auth:** Required
**Role:** Any authenticated user

```bash
curl -X DELETE http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Account deactivated successfully",
  "timestamp": "2026-03-01T10:20:31.011138774"
}
```

> **Note:** This is a soft delete — the user record remains in the database with `active = false`. This endpoint publishes a `ott.user.deleted` Kafka event.

---

## Profile APIs

Each user can have multiple profiles (e.g., for family members or viewing preferences).

### 6. List Profiles

Retrieves all profiles belonging to the authenticated user.

**Endpoint:** `GET /api/v1/users/me/profiles`
**Auth:** Required
**Role:** Any authenticated user

```bash
curl -X GET http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/profiles \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK) — With profiles:**
```json
{
  "success": true,
  "data": [
    {
      "id": "d9ae440f-18b7-4286-83b8-6677cc7893ce",
      "userId": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
      "bio": "Movie enthusiast",
      "language": "en",
      "country": "India",
      "timezone": "Asia/Kolkata",
      "profileImageUrl": "/avatars/movie.png",
      "createdAt": "2026-03-01T10:16:01.800682",
      "updatedAt": "2026-03-01T10:16:01.800712"
    }
  ],
  "timestamp": "2026-03-01T10:19:58.938331052"
}
```

**Success Response (200 OK) — No profiles:**
```json
{
  "success": true,
  "data": [],
  "timestamp": "2026-03-01T10:16:01.414419313"
}
```

**Response Fields:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | UUID | No | Profile ID |
| userId | UUID | No | Owner user ID |
| bio | String | Yes | Profile bio |
| language | String | Yes | Preferred language code (e.g., en, hi) |
| country | String | Yes | Country name |
| timezone | String | Yes | Timezone identifier |
| profileImageUrl | String | Yes | Profile image URL |
| createdAt | DateTime | No | Creation timestamp |
| updatedAt | DateTime | No | Last update timestamp |

---

### 7. Create Profile

Creates a new profile for the authenticated user.

**Endpoint:** `POST /api/v1/users/me/profiles`
**Auth:** Required
**Role:** Any authenticated user

**Request Body:**
```json
{
  "bio": "Movie enthusiast and binge watcher",
  "language": "en",
  "country": "India",
  "timezone": "Asia/Kolkata",
  "profileImageUrl": "/avatars/movie.png"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| bio | String | No | max 500 chars | Profile biography |
| language | String | No | max 10 chars | Language code (e.g., en, hi, ta) |
| country | String | No | max 100 chars | Country name |
| timezone | String | No | max 50 chars | IANA timezone (e.g., Asia/Kolkata) |
| profileImageUrl | String | No | max 512 chars | Profile image URL |

```bash
curl -X POST http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/profiles \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "bio": "Movie enthusiast",
    "language": "en",
    "country": "India",
    "timezone": "Asia/Kolkata",
    "profileImageUrl": "/avatars/movie.png"
  }'
```

**Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Profile created successfully",
  "data": {
    "id": "562252d7-830a-4c51-96b2-62ada57f9ba4",
    "userId": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "language": "en",
    "createdAt": "2026-03-01T10:19:59.110169233",
    "updatedAt": "2026-03-01T10:19:59.110185177"
  },
  "timestamp": "2026-03-01T10:19:59.115496725"
}
```

---

### 8. Update Profile

Updates an existing profile.

**Endpoint:** `PUT /api/v1/users/me/profiles/{profileId}`
**Auth:** Required
**Role:** Any authenticated user (must own the profile)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| profileId | UUID | The profile's database ID |

**Request Body:**
```json
{
  "bio": "Updated bio",
  "language": "hi",
  "country": "India",
  "timezone": "Asia/Kolkata",
  "profileImageUrl": "/avatars/updated.png"
}
```

**Request Fields:** Same as [Create Profile](#7-create-profile). All fields are optional — only provided fields are updated.

```bash
curl -X PUT http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/profiles/562252d7-830a-4c51-96b2-62ada57f9ba4 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "hi",
    "bio": "Updated bio"
  }'
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "562252d7-830a-4c51-96b2-62ada57f9ba4",
    "userId": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "language": "hi",
    "createdAt": "2026-03-01T10:19:59.110169",
    "updatedAt": "2026-03-01T10:19:59.110185"
  },
  "timestamp": "2026-03-01T10:19:59.314948675"
}
```

**Error Response (404 Not Found):**
```json
{
  "success": false,
  "message": "Profile not found with id: '00000000-0000-0000-0000-000000000000'",
  "timestamp": "2026-03-01T10:20:00.000000000"
}
```

---

### 9. Delete Profile

Removes a profile.

**Endpoint:** `DELETE /api/v1/users/me/profiles/{profileId}`
**Auth:** Required
**Role:** Any authenticated user (must own the profile)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| profileId | UUID | The profile's database ID |

```bash
curl -X DELETE http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/profiles/562252d7-830a-4c51-96b2-62ada57f9ba4 \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile deleted successfully",
  "timestamp": "2026-03-01T10:20:29.769302342"
}
```

---

## Preference APIs

User preferences for content, streaming, and notifications.

### 10. Get Preferences

Retrieves the authenticated user's preferences.

**Endpoint:** `GET /api/v1/users/me/preferences`
**Auth:** Required
**Role:** Any authenticated user

```bash
curl -X GET http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/preferences \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "50b6cd0d-1075-4145-8fdd-0b6bc22519f7",
    "userId": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "emailNotifications": true,
    "pushNotifications": true,
    "autoplayEnabled": true,
    "defaultVideoQuality": "AUTO",
    "subtitlesEnabled": false,
    "preferredLanguage": "en",
    "parentalControlEnabled": false,
    "maturityRating": "ALL"
  },
  "timestamp": "2026-03-01T10:19:59.781286793"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Preference record ID |
| userId | UUID | Owner user ID |
| emailNotifications | Boolean | Email notifications enabled |
| pushNotifications | Boolean | Push notifications enabled |
| autoplayEnabled | Boolean | Auto-play next episode |
| defaultVideoQuality | String | Video quality: AUTO, SD, HD, FULL_HD, 4K |
| subtitlesEnabled | Boolean | Show subtitles by default |
| preferredLanguage | String | Preferred content language code |
| parentalControlEnabled | Boolean | Parental controls active |
| maturityRating | String | Content maturity filter: ALL, PG, PG13, R, NC17 |

**Error Response (404 Not Found) — Preferences not set yet:**
```json
{
  "success": false,
  "message": "Preference not found with userId: '43fddf6f-a57f-4c8a-8c98-bbe71008e271'",
  "timestamp": "2026-03-01T10:19:59.478215718"
}
```

---

### 11. Update Preferences

Creates or updates the authenticated user's preferences.

**Endpoint:** `PUT /api/v1/users/me/preferences`
**Auth:** Required
**Role:** Any authenticated user

**Request Body:**
```json
{
  "emailNotifications": true,
  "pushNotifications": true,
  "autoplayEnabled": true,
  "defaultVideoQuality": "HD",
  "subtitlesEnabled": true,
  "preferredLanguage": "hi",
  "parentalControlEnabled": false,
  "parentalControlPin": "1234",
  "maturityRating": "PG13"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| emailNotifications | Boolean | No | - | Enable email notifications |
| pushNotifications | Boolean | No | - | Enable push notifications |
| autoplayEnabled | Boolean | No | - | Enable auto-play |
| defaultVideoQuality | String | No | max 20 chars | Video quality: AUTO, SD, HD, FULL_HD, 4K |
| subtitlesEnabled | Boolean | No | - | Enable subtitles |
| preferredLanguage | String | No | max 10 chars | Language code (en, hi, ta, etc.) |
| parentalControlEnabled | Boolean | No | - | Enable parental controls |
| parentalControlPin | String | No | max 255 chars | Parental control PIN |
| maturityRating | String | No | max 10 chars | Maturity rating: ALL, PG, PG13, R, NC17 |

```bash
curl -X PUT http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/preferences \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "emailNotifications": true,
    "pushNotifications": true,
    "autoplayEnabled": true,
    "defaultVideoQuality": "HD",
    "subtitlesEnabled": true,
    "preferredLanguage": "hi",
    "parentalControlEnabled": false,
    "maturityRating": "PG13"
  }'
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Preferences updated successfully",
  "data": {
    "id": "50b6cd0d-1075-4145-8fdd-0b6bc22519f7",
    "userId": "43fddf6f-a57f-4c8a-8c98-bbe71008e271",
    "emailNotifications": true,
    "pushNotifications": true,
    "autoplayEnabled": true,
    "defaultVideoQuality": "AUTO",
    "subtitlesEnabled": false,
    "preferredLanguage": "en",
    "parentalControlEnabled": false,
    "maturityRating": "ALL"
  },
  "timestamp": "2026-03-01T10:19:59.781286793"
}
```

> **Note:** If preferences don't exist yet, this endpoint creates them. Subsequent calls update the existing record.

---

## Device APIs

Manage registered devices for the authenticated user. Used for push notifications and multi-device streaming control.

### 12. List Devices

Retrieves all devices registered to the authenticated user.

**Endpoint:** `GET /api/v1/users/me/devices`
**Auth:** Required
**Role:** Any authenticated user

```bash
curl -X GET http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/devices \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK) — With devices:**
```json
{
  "success": true,
  "data": [
    {
      "id": "79abfc0c-0917-4967-8cf9-787ba1bf8ead",
      "deviceId": "IPHONE15-ABC123-DEF456",
      "deviceName": "iPhone 15 Pro",
      "deviceType": "MOBILE",
      "platform": "IOS",
      "lastActiveAt": "2026-03-01T10:21:08.929041534",
      "pushToken": "fcm-token-abc123xyz",
      "createdAt": "2026-03-01T10:21:08.929853216"
    }
  ],
  "timestamp": "2026-03-01T10:21:09.000000000"
}
```

**Success Response (200 OK) — No devices:**
```json
{
  "success": true,
  "data": [],
  "timestamp": "2026-03-01T10:20:29.975640174"
}
```

**Response Fields:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | UUID | No | Database record ID |
| deviceId | String | No | Unique device identifier (client-provided) |
| deviceName | String | Yes | Human-readable device name |
| deviceType | String | Yes | Device type: MOBILE, TABLET, DESKTOP, TV, WEB |
| platform | String | Yes | Platform: IOS, ANDROID, WEB, SMART_TV, FIRE_TV |
| lastActiveAt | DateTime | No | Last activity timestamp |
| pushToken | String | Yes | FCM/APNs push notification token |
| createdAt | DateTime | No | Registration timestamp |

---

### 13. Register Device

Registers a new device for the authenticated user.

**Endpoint:** `POST /api/v1/users/me/devices`
**Auth:** Required
**Role:** Any authenticated user

**Request Body:**
```json
{
  "deviceId": "IPHONE15-ABC123-DEF456",
  "deviceName": "iPhone 15 Pro",
  "deviceType": "MOBILE",
  "platform": "IOS",
  "pushToken": "fcm-token-abc123xyz"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| deviceId | String | **Yes** | max 255 chars, not blank | Unique device identifier (e.g., hardware ID, UUID) |
| deviceName | String | No | max 255 chars | Human-readable device name |
| deviceType | String | No | max 50 chars | Device type: MOBILE, TABLET, DESKTOP, TV, WEB |
| platform | String | No | max 50 chars | Platform: IOS, ANDROID, WEB, SMART_TV, FIRE_TV |
| pushToken | String | No | max 512 chars | FCM or APNs push notification token |

```bash
curl -X POST http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/devices \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "IPHONE15-ABC123-DEF456",
    "deviceName": "iPhone 15 Pro",
    "deviceType": "MOBILE",
    "platform": "IOS",
    "pushToken": "fcm-token-abc123xyz"
  }'
```

**Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Device registered successfully",
  "data": {
    "id": "79abfc0c-0917-4967-8cf9-787ba1bf8ead",
    "deviceId": "IPHONE15-ABC123-DEF456",
    "deviceName": "iPhone 15 Pro",
    "deviceType": "MOBILE",
    "platform": "IOS",
    "lastActiveAt": "2026-03-01T10:21:08.929041534",
    "pushToken": "fcm-token-abc123xyz",
    "createdAt": "2026-03-01T10:21:08.929853216"
  },
  "timestamp": "2026-03-01T10:21:08.934957408"
}
```

**Validation Error Response (400):**
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "deviceId": "must not be blank"
  },
  "timestamp": "2026-03-01T10:20:30.196657843"
}
```

---

### 14. Remove Device

Unregisters a device from the authenticated user's account.

**Endpoint:** `DELETE /api/v1/users/me/devices/{deviceId}`
**Auth:** Required
**Role:** Any authenticated user (must own the device)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| deviceId | String | The client-provided device identifier (NOT the database UUID) |

```bash
curl -X DELETE http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/api/v1/users/me/devices/IPHONE15-ABC123-DEF456 \
  -H "Authorization: Bearer <token>"
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Device removed successfully",
  "timestamp": "2026-03-01T10:21:37.104861855"
}
```

**Error Response (404 Not Found):**
```json
{
  "success": false,
  "message": "Device not found with deviceId: 'UNKNOWN-DEVICE-ID'",
  "timestamp": "2026-03-01T10:21:09.162681724"
}
```

> **Important:** The path parameter uses the `deviceId` string (e.g., `IPHONE15-ABC123-DEF456`), **not** the database UUID (`id` field in the response).

---

## Kafka Events Published

The user-service publishes the following events to Kafka:

| Event | Topic | Trigger | Consumers |
|-------|-------|---------|-----------|
| UserProfileUpdated | `ott.user.profile-updated` | PUT /api/v1/users/me | recommendation-service |
| UserDeleted | `ott.user.deleted` | DELETE /api/v1/users/me | auth-service, subscription-service, notification-service, watchlist-service |

## Kafka Events Consumed

| Event | Topic | Producer | Action |
|-------|-------|----------|--------|
| UserRegistered | `ott.user.registered` | auth-service | Creates user record in user_db |

---

## Swagger / OpenAPI

Interactive API documentation is available at:
- **Swagger UI:** `http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/swagger-ui.html`
- **OpenAPI JSON:** `http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081/v3/api-docs`

---

## Staging Environment

**Staging URL:** `http://a09ca676fa2c248d5b1aa20450de331c-682520952.ap-south-1.elb.amazonaws.com:8081`
**Health Check:** `GET /actuator/health`
**Metrics:** `GET /actuator/prometheus`
