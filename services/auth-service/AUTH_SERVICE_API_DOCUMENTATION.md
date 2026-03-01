# Auth Service - API Documentation

**Staging Base URL:** `http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082`
**API Version:** v1
**Content-Type:** `application/json`
**Authentication:** All auth endpoints are **public** (no JWT required). The auth service issues JWT tokens.

> **Environment URLs:**
> | Environment | Base URL |
> |-------------|----------|
> | Staging | `http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082` |
> | Production | TBD (behind AWS API Gateway) |

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication Flow](#authentication-flow)
3. [Response Format](#response-format)
4. [Error Responses](#error-responses)
5. [APIs](#apis)
   - [Register](#1-register)
   - [Login](#2-login)
   - [Verify OTP](#3-verify-otp)
   - [Resend OTP](#4-resend-otp)
   - [Refresh Token](#5-refresh-token)
   - [Logout](#6-logout)
6. [OTP Configuration](#otp-configuration)
7. [JWT Token Details](#jwt-token-details)
8. [Redis Keys](#redis-keys)
9. [Kafka Events](#kafka-events)
10. [Database Schema](#database-schema)

---

## Overview

The auth-service provides OTP-based (passwordless) authentication for the OTT platform. Users register and login using their email address — a 6-digit OTP is sent for verification. Upon successful OTP verification, JWT access and refresh tokens are issued.

**Key Features:**
- OTP-based registration and login (no passwords)
- 6-digit OTP with 5-minute expiry
- Rate limiting: max 3 OTP requests per 15-minute window
- Max 5 OTP verification attempts before invalidation
- JWT access token (15 min) + refresh token (7 days)
- Token blacklisting on logout via Redis
- BCrypt-hashed OTP storage in Redis

---

## Authentication Flow

### Registration Flow
```
Client                          Auth Service                    Notification Service
  |                                  |                                  |
  |-- POST /register (email) -----→ |                                  |
  |                                  |-- Create unverified user         |
  |                                  |-- Generate OTP → Redis           |
  |                                  |-- Kafka: ott.auth.otp-requested →|
  |                                  |                                  |-- Send OTP via Email/SMS
  |←---- 201: OTP sent -------------|                                  |
  |                                  |                                  |
  |-- POST /verify-otp (email,otp) →|                                  |
  |                                  |-- Validate OTP from Redis        |
  |                                  |-- Mark email_verified = true     |
  |                                  |-- Generate JWT tokens            |
  |                                  |-- Kafka: ott.user.registered ---→|
  |←---- 200: JWT tokens -----------|                                  |
```

### Login Flow
```
Client                          Auth Service                    Notification Service
  |                                  |                                  |
  |-- POST /login (email) --------→ |                                  |
  |                                  |-- Verify user exists & enabled   |
  |                                  |-- Generate OTP → Redis           |
  |                                  |-- Kafka: ott.auth.otp-requested →|
  |←---- 200: OTP sent -------------|                                  |
  |                                  |                                  |
  |-- POST /verify-otp (email,otp) →|                                  |
  |                                  |-- Validate OTP from Redis        |
  |                                  |-- Generate JWT tokens            |
  |                                  |-- Kafka: ott.auth.login --------→|
  |←---- 200: JWT tokens -----------|                                  |
```

---

## Response Format

All responses use the standard `ApiResponse<T>` wrapper:

**Success Response:**
```json
{
  "success": true,
  "message": "Descriptive message",
  "data": { },
  "timestamp": "2026-03-01T10:59:59.773107919"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2026-03-01T10:58:22.318870905"
}
```

---

## Error Responses

| HTTP Code | Scenario | Example Message |
|-----------|----------|-----------------|
| 400 | Validation error | `"Validation failed"` with field-level errors |
| 400 | Invalid/expired OTP | `"Invalid OTP. 4 attempt(s) remaining."` |
| 401 | Invalid token / disabled account | `"Invalid refresh token"` |
| 404 | User not found | `"User not found with email: 'x@test.com'"` |
| 409 | Duplicate registration | `"User already exists with email: 'x@test.com'"` |
| 429 | Rate limited | `"Too many OTP requests. Try again in 899 seconds."` |
| 500 | Internal error | `"An unexpected error occurred"` |

**Validation Error (400):**
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "username": "Username is required",
    "email": "Email must be valid"
  },
  "timestamp": "2026-03-01T10:58:22.318870905"
}
```

**Duplicate Registration (409):**
```json
{
  "success": false,
  "message": "User already exists with email: 'admin@ottnetwork.com'",
  "timestamp": "2026-03-01T10:58:21.996337118"
}
```

**Rate Limit (429):**
```json
{
  "success": false,
  "message": "Too many OTP requests. Try again in 899 seconds.",
  "timestamp": "2026-03-01T10:58:23.478177788"
}
```

**Invalid OTP (400):**
```json
{
  "success": false,
  "message": "Invalid OTP. 4 attempt(s) remaining.",
  "timestamp": "2026-03-01T10:58:23.346596072"
}
```

---

## APIs

### 1. Register

Registers a new user and sends a 6-digit OTP to the provided email for verification.

**Endpoint:** `POST /api/v1/auth/register`
**Auth:** Not required (public)

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "username": "newuser123",
  "phone": "+919876543210"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| email | String | **Yes** | Valid email format | User's email address |
| username | String | **Yes** | 3-50 characters | Unique username |
| phone | String | No | - | Phone number (optional, for SMS OTP) |

```bash
curl -X POST http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "username": "newuser123"
  }'
```

**Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Registration initiated. Please verify OTP.",
  "data": {
    "message": "OTP sent to newuser@example.com",
    "otpExpiresInSeconds": 300,
    "retryAfterSeconds": 300
  },
  "timestamp": "2026-03-01T10:58:21.710743853"
}
```

**Error Response (409 Conflict) — Duplicate email:**
```json
{
  "success": false,
  "message": "User already exists with email: 'admin@ottnetwork.com'",
  "timestamp": "2026-03-01T10:58:21.996337118"
}
```

**Error Response (400 Bad Request) — Validation error:**
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "username": "Username is required"
  },
  "timestamp": "2026-03-01T10:58:22.318870905"
}
```

**What happens internally:**
1. Validates email and username are not already registered
2. Creates an unverified user record in `user_credentials` table (`email_verified = false`)
3. Generates a 6-digit OTP, hashes it with BCrypt, stores in Redis with 5-minute TTL
4. Publishes `ott.auth.otp-requested` Kafka event for notification-service to deliver OTP
5. Returns OTP expiration info

> **Note:** The user is not fully registered until OTP is verified via `/verify-otp`.

---

### 2. Login

Sends a 6-digit OTP to the registered email for login verification.

**Endpoint:** `POST /api/v1/auth/login`
**Auth:** Not required (public)

**Request Body:**
```json
{
  "email": "admin@ottnetwork.com"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| email | String | **Yes** | Not blank | Registered email address |

```bash
curl -X POST http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@ottnetwork.com"
  }'
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent. Please verify to login.",
  "data": {
    "message": "OTP sent to admin@ottnetwork.com",
    "otpExpiresInSeconds": 300,
    "retryAfterSeconds": 300
  },
  "timestamp": "2026-03-01T10:58:22.831302785"
}
```

**Error Response (404 Not Found) — Email not registered:**
```json
{
  "success": false,
  "message": "User not found with email: 'nonexistent@test.com'",
  "timestamp": "2026-03-01T10:58:22.992783189"
}
```

**Error Response (429 Too Many Requests) — Rate limited:**
```json
{
  "success": false,
  "message": "Too many OTP requests. Try again in 899 seconds.",
  "timestamp": "2026-03-01T10:58:23.478177788"
}
```

**What happens internally:**
1. Looks up user by email in `user_credentials` table
2. Validates the account is enabled
3. Generates OTP, stores hashed in Redis, publishes `ott.auth.otp-requested` event
4. Returns OTP expiration info

---

### 3. Verify OTP

Validates the OTP and issues JWT access and refresh tokens upon successful verification.

**Endpoint:** `POST /api/v1/auth/verify-otp`
**Auth:** Not required (public)

**Request Body:**
```json
{
  "email": "admin@ottnetwork.com",
  "otp": "291105"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| email | String | **Yes** | Not blank | Email used during register/login |
| otp | String | **Yes** | Exactly 6 digits | The 6-digit OTP received via email/SMS |

```bash
curl -X POST http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@ottnetwork.com",
    "otp": "291105"
  }'
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Authentication successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhMDAwMDAwMS0wMD...",
    "refreshToken": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhMDAwMDAwMS0wMD...",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "userId": "a0000001-0000-0000-0000-000000000001",
    "email": "admin@ottnetwork.com",
    "role": "ADMIN"
  },
  "timestamp": "2026-03-01T10:59:59.773107919"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| accessToken | String | JWT access token for API authentication (15 min expiry) |
| refreshToken | String | JWT refresh token for obtaining new access tokens (7 day expiry) |
| tokenType | String | Always `"Bearer"` |
| expiresIn | Long | Access token expiry in seconds (900 = 15 minutes) |
| userId | UUID | The user's auth ID (used as `sub` claim in JWT) |
| email | String | User's email address |
| role | String | User role: `SUBSCRIBER`, `ADMIN`, `CONTENT_CREATOR` |

**Error Response (400 Bad Request) — Invalid OTP:**
```json
{
  "success": false,
  "message": "Invalid OTP. 4 attempt(s) remaining.",
  "timestamp": "2026-03-01T10:58:23.346596072"
}
```

**Error Response (400 Bad Request) — OTP expired:**
```json
{
  "success": false,
  "message": "OTP has expired. Please request a new one.",
  "timestamp": "2026-03-01T10:58:23.000000000"
}
```

**Error Response (400 Bad Request) — Max attempts exceeded:**
```json
{
  "success": false,
  "message": "Maximum OTP verification attempts exceeded. Please request a new OTP.",
  "timestamp": "2026-03-01T10:58:23.000000000"
}
```

**What happens internally:**
1. Retrieves the hashed OTP from Redis (`otp:{email}`)
2. Tracks verification attempts (`otp_attempts:{email}`, max 5)
3. Compares provided OTP against BCrypt hash
4. On success:
   - Marks `email_verified = true` (if first-time registration)
   - Updates `last_login_at` timestamp
   - Generates JWT access token (15 min) and refresh token (7 days)
   - Persists refresh token in `refresh_tokens` table
   - Publishes `ott.user.registered` event (if new user)
   - Publishes `ott.auth.login` event (every login)
   - Cleans up Redis OTP keys
5. Returns JWT tokens

> **Important:** The OTP is single-use. After successful verification, it is deleted from Redis. After 5 failed attempts, the OTP is invalidated.

---

### 4. Resend OTP

Generates and sends a new OTP to the specified email. The previous OTP is invalidated.

**Endpoint:** `POST /api/v1/auth/resend-otp`
**Auth:** Not required (public)

**Request Body:**
```json
{
  "email": "admin@ottnetwork.com",
  "purpose": "LOGIN"
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| email | String | **Yes** | Not blank | Email address to resend OTP to |
| purpose | String | **Yes** | `REGISTER` or `LOGIN` | Purpose of the OTP |

```bash
curl -X POST http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/api/v1/auth/resend-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@ottnetwork.com",
    "purpose": "LOGIN"
  }'
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP resent",
  "data": {
    "message": "OTP resent to admin@ottnetwork.com",
    "otpExpiresInSeconds": 300,
    "retryAfterSeconds": 300
  },
  "timestamp": "2026-03-01T10:58:23.000000000"
}
```

**Error Response (429 Too Many Requests) — Rate limited:**
```json
{
  "success": false,
  "message": "Too many OTP requests. Try again in 899 seconds.",
  "timestamp": "2026-03-01T10:58:23.478177788"
}
```

**What happens internally:**
1. Validates the user exists and is enabled
2. Checks rate limit (max 3 OTP requests per 15-minute window)
3. Generates a new OTP, replaces the previous one in Redis
4. Resets the verification attempt counter
5. Publishes `ott.auth.otp-requested` Kafka event

> **Note:** Subject to the same rate limiting as register/login. Max 3 OTP requests (across register, login, and resend) per email per 15-minute window.

---

### 5. Refresh Token

Issues a new access token and refresh token pair using a valid refresh token. The old refresh token is revoked.

**Endpoint:** `POST /api/v1/auth/refresh`
**Auth:** Not required (uses refresh token in body)

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhMDAwMDAwMS0w..."
}
```

**Request Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| refreshToken | String | **Yes** | Not blank | Valid, non-revoked refresh token |

```bash
curl -X POST http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "eyJhbGciOiJIUzUxMiJ9..."
  }'
```

**Success Response (200 OK):**
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
  "timestamp": "2026-03-01T11:00:00.000000000"
}
```

**Response Fields:** Same as [Verify OTP response](#3-verify-otp).

**Error Response (401 Unauthorized) — Invalid token:**
```json
{
  "success": false,
  "message": "Invalid refresh token",
  "timestamp": "2026-03-01T10:58:23.63871823"
}
```

**Error Response (401 Unauthorized) — Revoked token:**
```json
{
  "success": false,
  "message": "Refresh token has been revoked",
  "timestamp": "2026-03-01T10:58:23.000000000"
}
```

**Error Response (401 Unauthorized) — Expired token:**
```json
{
  "success": false,
  "message": "Refresh token has expired",
  "timestamp": "2026-03-01T10:58:23.000000000"
}
```

**What happens internally:**
1. Looks up the refresh token in `refresh_tokens` table
2. Validates the token is not revoked and not expired
3. Revokes the old refresh token (`revoked = true`)
4. Generates new access and refresh tokens
5. Persists the new refresh token in the database
6. Returns the new token pair

> **Note:** Each refresh token is single-use. After refresh, the old token is revoked and a new one is issued. This implements **refresh token rotation** for security.

---

### 6. Logout

Invalidates the current access token and revokes all refresh tokens for the user.

**Endpoint:** `POST /api/v1/auth/logout`
**Auth:** Required (Bearer token in Authorization header)

**Request Headers:**
```
Authorization: Bearer <accessToken>
```

```bash
curl -X POST http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/api/v1/auth/logout \
  -H "Authorization: Bearer eyJhbGciOiJIUzUxMiJ9..."
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "timestamp": "2026-03-01T11:00:02.367763709"
}
```

**What happens internally:**
1. Extracts the JWT access token from the `Authorization` header
2. Validates the token signature
3. Blacklists the access token in Redis with TTL until its expiration time
4. Revokes **all** refresh tokens for the user in the `refresh_tokens` table
5. Returns success

> **Note:** After logout, the access token is immediately blacklisted. Any subsequent API calls with the same token will be rejected with 401. All refresh tokens for the user are also revoked, requiring a fresh login.

---

## OTP Configuration

| Property | Default | Description |
|----------|---------|-------------|
| `otp.length` | 6 | Number of digits in OTP |
| `otp.ttl-seconds` | 300 | OTP validity period (5 minutes) |
| `otp.max-requests-per-window` | 3 | Max OTP requests per rate limit window |
| `otp.max-verify-attempts` | 5 | Max verification attempts per OTP |
| `otp.rate-limit-window-seconds` | 900 | Rate limit window (15 minutes) |

**OTP Security:**
- OTPs are **BCrypt-hashed** before storage in Redis (never stored in plaintext)
- OTPs are **never stored in the database** — only in Redis with TTL
- OTPs are **single-use** — deleted from Redis after successful verification
- Rate limiting tracks requests across register, login, and resend endpoints combined

---

## JWT Token Details

### Access Token

| Property | Value |
|----------|-------|
| Algorithm | HS512 (HMAC-SHA512) |
| Expiry | 15 minutes (900,000 ms) |
| Library | jjwt 0.12.6 |

**Claims:**

| Claim | Type | Description |
|-------|------|-------------|
| `sub` | UUID | User's auth ID (`user_credentials.id`) |
| `email` | String | User's email address |
| `roles` | String[] | User roles (e.g., `["ADMIN"]`, `["SUBSCRIBER"]`) |
| `type` | String | Always `"ACCESS"` |
| `iat` | Timestamp | Issued at (epoch seconds) |
| `exp` | Timestamp | Expiration (epoch seconds) |

**Example decoded payload:**
```json
{
  "sub": "a0000001-0000-0000-0000-000000000001",
  "email": "admin@ottnetwork.com",
  "roles": ["ADMIN"],
  "type": "ACCESS",
  "iat": 1772362799,
  "exp": 1772363699
}
```

### Refresh Token

| Property | Value |
|----------|-------|
| Algorithm | HS512 |
| Expiry | 7 days (604,800,000 ms) |

**Claims:**

| Claim | Type | Description |
|-------|------|-------------|
| `sub` | UUID | User's auth ID |
| `type` | String | Always `"REFRESH"` |
| `iat` | Timestamp | Issued at |
| `exp` | Timestamp | Expiration |

### Using the Access Token

Include the access token in the `Authorization` header for all authenticated API calls:

```
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

The `ott-security` library's `JwtAuthenticationFilter` validates the token and populates the Spring Security context with the user's ID, email, and roles.

---

## Redis Keys

| Key Pattern | Value | TTL | Description |
|-------------|-------|-----|-------------|
| `otp:{email}` | BCrypt-hashed OTP | 5 min | Active OTP for verification |
| `otp_attempts:{email}` | Integer (attempt count) | 5 min | Verification attempt counter |
| `otp_rate:{email}` | Integer (request count) | 15 min | Rate limit counter |
| `blacklist:{token}` | `"blacklisted"` | Until token expiry | Blacklisted access tokens |

---

## Kafka Events

### Events Published

#### 1. OTP Requested Event
**Topic:** `ott.auth.otp-requested`
**Triggered by:** Register, Login, Resend OTP
**Consumed by:** notification-service (sends OTP via Email/SMS)

```json
{
  "eventId": "550e8400-e29b-41d4-a716-446655440000",
  "eventType": "OTP_REQUESTED",
  "source": "auth-service",
  "timestamp": "2026-03-01T10:30:00Z",
  "email": "user@example.com",
  "phone": "+919876543210",
  "otp": "291105",
  "channel": "EMAIL",
  "purpose": "LOGIN"
}
```

| Field | Type | Description |
|-------|------|-------------|
| email | String | Recipient email |
| phone | String | Recipient phone (if provided) |
| otp | String | Plaintext OTP (for notification-service to deliver) |
| channel | String | `EMAIL` or `SMS` |
| purpose | String | `REGISTER` or `LOGIN` |

#### 2. User Registered Event
**Topic:** `ott.user.registered`
**Triggered by:** First successful OTP verification after registration
**Consumed by:** user-service, notification-service, recommendation-service, analytics-service

```json
{
  "eventId": "550e8400-e29b-41d4-a716-446655440000",
  "eventType": "USER_REGISTERED",
  "source": "auth-service",
  "timestamp": "2026-03-01T10:30:00Z",
  "userId": "a0000001-0000-0000-0000-000000000001",
  "email": "user@example.com",
  "username": "newuser123",
  "role": "SUBSCRIBER"
}
```

| Field | Type | Description |
|-------|------|-------------|
| userId | UUID | Auth user ID |
| email | String | User's email |
| username | String | Username |
| role | String | Assigned role |

#### 3. Login Event
**Topic:** `ott.auth.login`
**Triggered by:** Every successful OTP verification (login)
**Consumed by:** analytics-service

```json
{
  "eventId": "550e8400-e29b-41d4-a716-446655440000",
  "eventType": "USER_LOGIN",
  "source": "auth-service",
  "timestamp": "2026-03-01T10:30:00Z"
}
```

### Events Consumed

None — auth-service does not consume any Kafka events.

---

## Database Schema

### user_credentials (auth_db)

```sql
CREATE TABLE user_credentials (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255)    NOT NULL UNIQUE,
    username        VARCHAR(50)     NOT NULL UNIQUE,
    password_hash   VARCHAR(255),       -- Nullable (unused for OTP flow)
    role            VARCHAR(50)     NOT NULL DEFAULT 'SUBSCRIBER',
    enabled         BOOLEAN         NOT NULL DEFAULT TRUE,
    email_verified  BOOLEAN         NOT NULL DEFAULT FALSE,
    last_login_at   TIMESTAMP,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0
);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key (auto-generated) |
| email | VARCHAR(255) | Unique email address |
| username | VARCHAR(50) | Unique username |
| password_hash | VARCHAR(255) | Unused for OTP flow (nullable, retained for future OAuth2/password fallback) |
| role | VARCHAR(50) | User role: `SUBSCRIBER`, `ADMIN`, `CONTENT_CREATOR` |
| enabled | BOOLEAN | Whether account is active |
| email_verified | BOOLEAN | Whether email has been verified via OTP |
| last_login_at | TIMESTAMP | Last successful login timestamp |
| created_at | TIMESTAMP | Account creation time |
| updated_at | TIMESTAMP | Last modification time |
| version | BIGINT | Optimistic locking version |

### refresh_tokens (auth_db)

```sql
CREATE TABLE refresh_tokens (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL,
    token       VARCHAR(500)    NOT NULL UNIQUE,
    expires_at  TIMESTAMP       NOT NULL,
    revoked     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    version     BIGINT          DEFAULT 0
);
```

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Reference to `user_credentials.id` |
| token | VARCHAR(500) | JWT refresh token string (unique) |
| expires_at | TIMESTAMP | Token expiration time |
| revoked | BOOLEAN | Whether token has been revoked |

### oauth_providers (auth_db)

```sql
CREATE TABLE oauth_providers (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    provider            VARCHAR(50)     NOT NULL,
    provider_user_id    VARCHAR(255)    NOT NULL,
    access_token        VARCHAR(1000),
    refresh_token       VARCHAR(1000),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_provider_provider_user_id UNIQUE (provider, provider_user_id)
);
```

> **Note:** The `oauth_providers` table is reserved for future OAuth2 integration (Google, Facebook, etc.). Not currently used.

---

## API Summary

| # | Method | Endpoint | Auth | HTTP Status | Description |
|---|--------|----------|------|-------------|-------------|
| 1 | POST | `/api/v1/auth/register` | No | 201 | Register new user, send OTP |
| 2 | POST | `/api/v1/auth/login` | No | 200 | Send login OTP to existing user |
| 3 | POST | `/api/v1/auth/verify-otp` | No | 200 | Verify OTP, issue JWT tokens |
| 4 | POST | `/api/v1/auth/resend-otp` | No | 200 | Resend OTP |
| 5 | POST | `/api/v1/auth/refresh` | No | 200 | Refresh access token |
| 6 | POST | `/api/v1/auth/logout` | **Yes** | 200 | Blacklist token, revoke refresh tokens |

---

## Swagger / OpenAPI

Interactive API documentation is available at:
- **Swagger UI:** `http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/swagger-ui.html`
- **OpenAPI JSON:** `http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082/v3/api-docs`

---

## Staging Environment

**Staging URL:** `http://a822255142ee3453d9d3f5b5f5c93c55-1473685919.ap-south-1.elb.amazonaws.com:8082`
**Health Check:** `GET /actuator/health`
**Metrics:** `GET /actuator/prometheus`
