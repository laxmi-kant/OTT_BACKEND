# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OTT Network Platform — a microservices-based video streaming platform. Each service is an **independent Maven project** (not a multi-module monorepo), deployable and manageable separately by individual developers.

**Tech Stack:** Java 17, Spring Boot 3.3.5, PostgreSQL 16, Apache Kafka, Redis 7, Elasticsearch 8, Flyway, MapStruct, Lombok

**Deployment:** AWS EKS (Kubernetes) with AWS API Gateway for external routing. Bunny CDN for video storage and streaming.

## Architecture

### Independent Service Design

Each microservice is a standalone Maven project with its own `pom.xml`, Dockerfile, Flyway migrations, Kubernetes manifests, and CI/CD pipeline. Services share code via published Maven artifacts (`ott-common`, `ott-security`, `ott-kafka`, `ott-test-utils`) hosted on a private Maven repository.

There is **no parent POM** binding services together. Each service independently declares its Spring Boot parent and pulls shared libraries as regular Maven dependencies.

### Services and Databases

Each service owns its own PostgreSQL database (database-per-service pattern). Schema is defined in `ott_network_complete_schema.sql`.

| Service | Port | Database | Key Tables |
|---------|------|----------|------------|
| auth-service | 8082 | auth_db | user_credentials, refresh_tokens, oauth_providers |
| user-service | 8081 | user_db | users, profiles, preferences, devices |
| content-service | 8083 | content_db | contents, categories, tags, seasons, episodes, content_categories, content_tags |
| video-streaming-service | 8084 | video_db | transcode_jobs, video_assets, playback_sessions |
| subscription-service | 8085 | subscription_db | plans, subscriptions, payments, invoices, coupons |
| recommendation-service | 8087 | recommendation_db | user_interactions, content_similarities |
| watchlist-service | 8086 | watchlist_db | watchlist_items, watch_history, playback_progress |
| notification-service | 8088 | notification_db | notifications, notification_templates, user_notification_preferences |
| analytics-service | 8091 | analytics_db | view_events, daily_aggregates, revenue_metrics |
| ad-service | 8092 | ad_db | campaigns, ads, ad_placements, impressions |
| social-service | 8093 | social_db | comments, ratings, reviews |
| multi-tenant-service | 8094 | tenant_db | tenants, tenant_configs, branding |
| discovery-server | 8761 | — | Eureka service registry |
| config-server | 8888 | — | Centralized configuration |

### Shared Libraries

Published as Maven artifacts. All services depend on these:

- **ott-common** — Base entities (UUID PKs, audit fields), ApiResponse wrapper, PagedResponse, shared DTOs, enums (ContentType, PlanType, SubscriptionStatus, UserRole, etc.), custom exceptions (ResourceNotFoundException, DuplicateResourceException), GlobalExceptionHandler
- **ott-security** — JWT token generation/validation (JwtUtil), SecurityHeaderFilter (reads X-User-Id/X-User-Role headers), UserContext (ThreadLocal holder), FeignConfig (propagates auth headers between services)
- **ott-kafka** — Kafka event base class (BaseEvent with eventId, eventType, timestamp, source, correlationId), domain event classes, producer/consumer configuration, KafkaTopics constants
- **ott-test-utils** — Test helpers, TestContainers base configs for PostgreSQL/Kafka/Redis

### Communication Patterns

**Synchronous (REST via OpenFeign):**
- auth-service → user-service (create user on register, validate user)
- video-streaming-service → content-service (get content metadata), subscription-service (verify subscription)
- recommendation-service → content-service (content details), user-service (preferences)
- content-service → AWS S3 (image uploads for thumbnails, banners, icons)
- ad-service → content-service (ad placement targets), subscription-service (check if user has ad-free plan), user-service (demographics for targeting)
- social-service → content-service (validate content exists), user-service (user display info)

**Asynchronous (Kafka events):**

| Topic | Producer | Consumers |
|-------|----------|-----------|
| ott.user.registered | user-service | notification-service, recommendation-service, analytics-service |
| ott.user.profile-updated | user-service | recommendation-service |
| ott.user.deleted | user-service | auth-service, subscription-service, notification-service, watchlist-service |
| ott.auth.otp-requested | auth-service | notification-service (sends OTP via SMS/email) |
| ott.auth.login | auth-service | analytics-service |
| ott.content.published | content-service | recommendation-service, notification-service, analytics-service |
| ott.content.updated | content-service | recommendation-service |
| ott.content.deleted | content-service | video-streaming-service, recommendation-service, watchlist-service |
| ott.stream.started | video-streaming-service | analytics-service, recommendation-service |
| ott.stream.ended | video-streaming-service | analytics-service, recommendation-service |
| ott.stream.progress | video-streaming-service | watchlist-service (playback_progress), analytics-service |
| ott.subscription.created | subscription-service | user-service, notification-service, analytics-service |
| ott.subscription.cancelled | subscription-service | user-service, notification-service, analytics-service |
| ott.payment.processed | subscription-service | notification-service, analytics-service |
| ott.payment.failed | subscription-service | notification-service |
| ott.watchlist.added | watchlist-service | recommendation-service |
| ott.social.rating-added | social-service | content-service (update average_rating), recommendation-service |
| ott.ad.impression | ad-service | analytics-service |
| ott.ad.complete | ad-service | analytics-service, subscription-service |
| ott.content.image-uploaded | content-service | analytics-service |

### Security Architecture

External traffic flows: **Client → AWS API Gateway (WAF, throttling, API keys) → ALB/NLB → Service Pods on EKS**

**OTP-based Registration and Login:**
- Registration and login are OTP-based (no password). The `password_hash` column in `auth_db.user_credentials` is unused for OTP flow (retained for future OAuth2/password fallback).
- **Registration flow**:
  1. `POST /api/v1/auth/register` — client sends email/phone + username. auth-service creates an unverified user record, generates a 6-digit OTP (TTL 5 min), stores it in Redis (`otp:{email}` → hashed OTP + attempt count), and sends OTP via notification-service (Kafka event `ott.auth.otp-requested`)
  2. `POST /api/v1/auth/verify-otp` — client sends email + OTP. auth-service validates against Redis, marks `email_verified = true`, creates the user in user-service via Feign, issues JWT access + refresh tokens
- **Login flow**:
  1. `POST /api/v1/auth/login` — client sends email/phone. auth-service looks up user, generates OTP, stores in Redis, sends via notification-service
  2. `POST /api/v1/auth/verify-otp` — client sends email + OTP. auth-service validates, issues JWT tokens, updates `last_login_at`
- **OTP delivery**: notification-service consumes `ott.auth.otp-requested` event and sends OTP via SMS (AWS SNS) or email (AWS SES) based on the identifier type
- **Rate limiting**: Max 3 OTP requests per email/phone per 15 minutes (tracked in Redis). Max 5 verification attempts per OTP before invalidation.
- **OTP storage**: OTPs are stored hashed (BCrypt) in Redis with a 5-minute TTL. Never stored in the database.
- **Configuration**: `OTP_LENGTH=6`, `OTP_TTL_SECONDS=300`, `OTP_MAX_REQUESTS_PER_WINDOW=3`, `OTP_MAX_VERIFY_ATTEMPTS=5`, `OTP_RATE_LIMIT_WINDOW_SECONDS=900`

**JWT token issuance (after OTP verification):**
- auth-service issues access tokens (15 min) and refresh tokens (7 days, stored in auth_db.refresh_tokens)
- AWS API Gateway or a lightweight JWT validation Lambda authorizer validates tokens before forwarding
- Services receive `X-User-Id`, `X-User-Role`, `X-User-Plan` headers (injected by the authorizer or gateway)
- SecurityHeaderFilter (from ott-security) reads these headers and populates UserContext ThreadLocal
- Internal service-to-service calls (Feign) propagate these headers via FeignConfig request interceptor

Eureka is used for **internal service discovery only** (services find each other within the EKS cluster).

### CMS Image Storage (AWS S3)

content-service handles image uploads (thumbnails, banners, avatars, category icons) via CMS backend APIs:
- **Upload flow**: CMS admin uploads image → content-service receives multipart file → uploads to AWS S3 bucket → stores the S3 URL (thumbnail_url, banner_url, icon_url) in the database
- **S3 bucket structure**: `s3://ott-media-assets/{tenant-id}/{content|category|profile}/{uuid}/{filename}`
- **Presigned URLs**: For large uploads, content-service generates S3 presigned PUT URLs so clients upload directly to S3, bypassing the service
- **Image processing**: Optionally resize/compress via AWS Lambda triggered on S3 put events (thumbnails at 320px, banners at 1920px)
- **Configuration**: `AWS_S3_BUCKET_NAME`, `AWS_S3_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (or IAM role on EKS via IRSA)
- **SDK**: `software.amazon.awssdk:s3` (AWS SDK v2)

### Video Streaming (Bunny CDN)

video-streaming-service integrates with Bunny.net:
- **Upload**: CMS uploads video files to Bunny Storage via Bunny Storage API. video-streaming-service tracks the upload in `transcode_jobs` table.
- **Transcoding**: Bunny Stream handles transcoding to multiple resolutions. Webhook callbacks update `video_assets` table.
- **Playback**: video-streaming-service generates signed Bunny CDN URLs for HLS streaming. `playback_sessions` tracks active sessions.
- **Configuration**: Bunny API key, Storage Zone name, CDN hostname, and Pull Zone ID stored as environment variables (not in code).

### Ad Management (VAST Integration)

ad-service supports the IAB VAST (Video Ad Serving Template) standard for ad delivery:
- **VAST endpoint**: `GET /api/v1/ads/vast/{contentId}` returns a VAST 4.2 XML response containing ad creatives, tracking URLs, and media files for the video player to consume
- **Ad decision flow**: Client player requests VAST XML before/during playback → ad-service selects ads based on campaign targeting (content category, user demographics, geo, subscription tier) → returns VAST XML → player renders ad and fires tracking pixels
- **Ad types**: Pre-roll, mid-roll, post-roll (configured per content via `ad_placements` table with `placement_type` and `position_seconds`)
- **Third-party ad server support**: ad-service can act as a VAST wrapper, redirecting to external ad servers (Google Ad Manager, SpotX, etc.) via VAST wrapper tags in the response
- **Tracking**: Impression, start, firstQuartile, midpoint, thirdQuartile, complete events tracked via `impressions` table. VAST tracking URLs fire back to `POST /api/v1/ads/track/{event}`
- **Ad-free logic**: ad-service checks subscription tier via Feign to subscription-service. PREMIUM users skip ads (return empty VAST response)
- **Configuration**: `VAST_DEFAULT_TIMEOUT_MS`, `VAST_MAX_WRAPPER_DEPTH`, `AD_DECISION_CACHE_TTL_SECONDS`

## Build and Run Commands

### Single Service (from service root directory)

```bash
# Build
mvn clean package -DskipTests

# Run locally
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Run tests
mvn test

# Run a single test class
mvn test -Dtest=UserServiceImplTest

# Run a single test method
mvn test -Dtest=UserServiceImplTest#shouldCreateUser

# Build Docker image
docker build -t ott-<service-name>:latest .

# Generate OpenAPI spec
mvn spring-boot:run  # then visit http://localhost:<port>/swagger-ui.html
```

### Local Development (Docker Compose)

```bash
# Start infrastructure only (PostgreSQL, Kafka, Redis, Elasticsearch, Zookeeper)
docker-compose -f infrastructure/docker/docker-compose.yml up -d

# Initialize all 12 databases
psql -U postgres -f ott_network_complete_schema.sql

# Start a specific service (from its directory)
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### Flyway Migrations

Each service manages its own migrations in `src/main/resources/db/migration/`:
```
V1__init_<domain>_schema.sql     # Initial schema (matches ott_network_complete_schema.sql)
V2__add_<feature>.sql            # Subsequent migrations
```

## Package Structure (per service)

```
com.ottnetwork.<servicename>/
├── <ServiceName>Application.java
├── config/          # Spring @Configuration classes, SecurityConfig, SwaggerConfig
├── controller/      # REST @RestController endpoints
├── service/         # Business logic interfaces and implementations
├── repository/      # Spring Data JPA @Repository interfaces
├── model/
│   ├── entity/      # JPA @Entity classes
│   └── enums/       # Service-specific enums
├── dto/
│   ├── request/     # Incoming request DTOs
│   └── response/    # Outgoing response DTOs
├── mapper/          # MapStruct @Mapper interfaces
├── event/
│   ├── producer/    # Kafka event publishers
│   └── consumer/    # Kafka event listeners
├── client/          # @FeignClient interfaces for calling other services
└── exception/       # Service-specific exceptions
```

## Entity Conventions

All entities use UUID primary keys and include audit fields, matching the schema:
```java
@Id @GeneratedValue(strategy = GenerationType.UUID)
private UUID id;

@Column(name = "created_at", nullable = false, updatable = false)
private LocalDateTime createdAt;

@Column(name = "updated_at", nullable = false)
private LocalDateTime updatedAt;

@Version
private Long version;  // Optimistic locking
```

Cross-service references store the foreign entity's UUID but have **no database-level foreign key** (since databases are separate). For example, `user_interactions.user_id` in recommendation_db references `users.id` in user_db by value only.

## AWS Deployment Architecture

```
Internet → AWS API Gateway (REST API + Lambda Authorizer for JWT)
                ↓
         AWS ALB (internal)
                ↓
         EKS Cluster
           ├── Namespace: ott-platform
           │   ├── auth-service (Deployment + Service + HPA)
           │   ├── user-service
           │   ├── content-service
           │   ├── video-streaming-service
           │   ├── subscription-service
           │   ├── recommendation-service
           │   ├── watchlist-service
           │   ├── notification-service
           │   ├── analytics-service
           │   ├── ad-service
           │   ├── social-service
           │   ├── multi-tenant-service
           │   ├── discovery-server (Eureka)
           │   └── config-server
           └── Namespace: ott-infra
               ├── Kafka (or Amazon MSK)
               ├── Redis (or Amazon ElastiCache)
               └── Elasticsearch (or Amazon OpenSearch)

External Services:
  - PostgreSQL → Amazon RDS (one instance per service or shared cluster with separate databases)
  - Image Storage → AWS S3 (ott-media-assets bucket, accessed by content-service via AWS SDK v2)
  - Video CDN → Bunny.net (Storage + Stream + CDN)
  - Ad Serving → VAST 4.2 standard (ad-service generates VAST XML, supports third-party ad server wrappers)
  - Email → AWS SES
  - Push Notifications → Firebase Cloud Messaging
```

Each service has its own Kubernetes manifests in a `k8s/` directory:
```
k8s/
├── deployment.yaml
├── service.yaml
├── hpa.yaml           # HorizontalPodAutoscaler
├── configmap.yaml
├── secret.yaml
└── ingress.yaml       # (optional, for services exposed via ALB)
```

## Key Configuration Properties

Services connect to infrastructure via environment variables (12-factor app):

```
SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD
SPRING_KAFKA_BOOTSTRAP_SERVERS
SPRING_DATA_REDIS_HOST, SPRING_DATA_REDIS_PASSWORD
SPRING_ELASTICSEARCH_URIS
EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
SPRING_CLOUD_CONFIG_URI
JWT_SECRET, JWT_EXPIRATION_MS, JWT_REFRESH_EXPIRATION_MS
BUNNY_API_KEY, BUNNY_STORAGE_ZONE, BUNNY_CDN_HOSTNAME, BUNNY_PULL_ZONE_ID
AWS_S3_BUCKET_NAME, AWS_S3_REGION
VAST_DEFAULT_TIMEOUT_MS, VAST_MAX_WRAPPER_DEPTH, AD_DECISION_CACHE_TTL_SECONDS
OTP_LENGTH, OTP_TTL_SECONDS, OTP_MAX_REQUESTS_PER_WINDOW, OTP_MAX_VERIFY_ATTEMPTS, OTP_RATE_LIMIT_WINDOW_SECONDS
```

## API Path Conventions

All endpoints follow: `/api/v1/<resource>`

| Service | Base Path | Example Endpoints |
|---------|-----------|-------------------|
| auth-service | /api/v1/auth | POST /register (send OTP), POST /login (send OTP), POST /verify-otp (validate & issue JWT), POST /resend-otp, POST /refresh, POST /logout |
| user-service | /api/v1/users | GET /me, PUT /me, GET /{id}, GET /me/preferences |
| content-service | /api/v1/content | GET /, GET /{id}, POST / (admin), GET /categories, GET /series/{id}/seasons, POST /{id}/upload-image, POST /{id}/presigned-url |
| video-streaming-service | /api/v1/stream | POST /{contentId}/start, PUT /{contentId}/progress, GET /{contentId}/url |
| subscription-service | /api/v1/subscriptions | GET /plans, POST /subscribe, GET /my-subscription, POST /cancel |
| recommendation-service | /api/v1/recommendations | GET /for-you, GET /trending, GET /similar/{contentId} |
| watchlist-service | /api/v1/watchlist | GET /, POST /{contentId}, DELETE /{contentId}, GET /history |
| notification-service | /api/v1/notifications | GET /, PUT /{id}/read, GET /preferences, PUT /preferences |
| analytics-service | /api/v1/analytics | GET /views, GET /revenue, GET /popular, GET /user-growth |
| ad-service | /api/v1/ads | GET /vast/{contentId} (VAST XML), GET /placement/{contentId}, POST /track/{event}, POST /impression, GET /campaigns (admin) |
| social-service | /api/v1/social | POST /comments, GET /comments/{contentId}, POST /ratings, GET /reviews/{contentId} |
| multi-tenant-service | /api/v1/tenants | POST /, GET /{id}, PUT /{id}/config, PUT /{id}/branding |
