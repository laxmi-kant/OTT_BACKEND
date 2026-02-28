-- ============================================================================================
--
--  OTT NETWORK PLATFORM - COMPLETE DATABASE SCHEMA
--
--  Description : Master SQL file containing all database schemas for the OTT Network
--                microservices platform. Creates 13 databases with all tables, indexes,
--                constraints, and seed data.
--
--  Target      : PostgreSQL 16+
--  Date        : 2026-02-23
--  Version     : 1.0.0
--
--  Usage       : Execute against a PostgreSQL server using psql:
--                  psql -U postgres -f ott_network_complete_schema.sql
--
--  Databases   :  1. auth_db            - Authentication & credentials
--                 2. user_db            - User profiles & preferences
--                 3. content_db         - Content catalog & metadata
--                 4. video_db           - Video streaming & transcoding
--                 5. subscription_db    - Plans, subscriptions & payments
--                 6. recommendation_db  - Recommendations & content similarity
--                 7. watchlist_db       - Watchlists & playback progress
--                 8. notification_db    - Notifications & templates
--                 9. analytics_db       - View events & revenue metrics
--                10. ad_db             - Ad campaigns & impressions
--                11. live_db           - Live streaming & chat
--                12. social_db         - Comments, ratings & reviews
--                13. tenant_db         - Multi-tenancy configuration
--
-- ============================================================================================


-- ============================================================================================
-- SECTION 0: DATABASE CREATION
-- ============================================================================================
-- Drop existing databases if they exist (CAUTION: destructive in production)
-- Uncomment the DROP statements below only for fresh installations.
-- --------------------------------------------------------------------------------------------

-- DROP DATABASE IF EXISTS auth_db;
-- DROP DATABASE IF EXISTS user_db;
-- DROP DATABASE IF EXISTS content_db;
-- DROP DATABASE IF EXISTS video_db;
-- DROP DATABASE IF EXISTS subscription_db;
-- DROP DATABASE IF EXISTS recommendation_db;
-- DROP DATABASE IF EXISTS watchlist_db;
-- DROP DATABASE IF EXISTS notification_db;
-- DROP DATABASE IF EXISTS analytics_db;
-- DROP DATABASE IF EXISTS ad_db;
-- DROP DATABASE IF EXISTS live_db;
-- DROP DATABASE IF EXISTS social_db;
-- DROP DATABASE IF EXISTS tenant_db;

CREATE DATABASE auth_db;
CREATE DATABASE user_db;
CREATE DATABASE content_db;
CREATE DATABASE video_db;
CREATE DATABASE subscription_db;
CREATE DATABASE recommendation_db;
CREATE DATABASE watchlist_db;
CREATE DATABASE notification_db;
CREATE DATABASE analytics_db;
CREATE DATABASE ad_db;
CREATE DATABASE live_db;
CREATE DATABASE social_db;
CREATE DATABASE tenant_db;


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 1: auth_db
--
--  Service     : auth-service
--  Description : Manages user authentication credentials, refresh tokens for JWT-based
--                session management, and OAuth2 social login provider integrations.
--
-- ============================================================================================
-- ============================================================================================

\c auth_db

-- ------------------------------------------------------------
-- Table: user_credentials
-- Description: Core authentication credentials for all users.
--              Each row represents a unique login identity.
-- ------------------------------------------------------------
CREATE TABLE user_credentials (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255)    NOT NULL,
    username        VARCHAR(50)     NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    role            VARCHAR(50)     NOT NULL DEFAULT 'SUBSCRIBER',
    enabled         BOOLEAN         NOT NULL DEFAULT TRUE,
    email_verified  BOOLEAN         NOT NULL DEFAULT FALSE,
    last_login_at   TIMESTAMP,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0,

    CONSTRAINT uk_user_credentials_email    UNIQUE (email),
    CONSTRAINT uk_user_credentials_username UNIQUE (username)
);

-- ------------------------------------------------------------
-- Table: refresh_tokens
-- Description: JWT refresh tokens for maintaining user sessions.
--              Tokens are rotated on each refresh and can be revoked.
-- Cross-ref  : user_id references user_credentials.id (same database)
-- ------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL,
    token       VARCHAR(500)    NOT NULL,
    expires_at  TIMESTAMP       NOT NULL,
    revoked     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    version     BIGINT          DEFAULT 0,

    CONSTRAINT uk_refresh_tokens_token UNIQUE (token)
);

-- ------------------------------------------------------------
-- Table: oauth_providers
-- Description: OAuth2/social login provider linkages (Google, GitHub, etc.).
--              Links external provider identities to local user accounts.
-- Cross-ref  : user_id references user_credentials.id (same database)
-- ------------------------------------------------------------
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

-- ============================================================
-- Indexes: auth_db
-- ============================================================

-- User Credentials indexes
CREATE INDEX idx_user_credentials_email    ON user_credentials (email);
CREATE INDEX idx_user_credentials_username ON user_credentials (username);

-- Refresh Tokens indexes
CREATE INDEX idx_refresh_tokens_token      ON refresh_tokens (token);
CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens (user_id);

-- OAuth Providers indexes
CREATE INDEX idx_oauth_providers_user_id                   ON oauth_providers (user_id);
CREATE INDEX idx_oauth_providers_provider_provider_user_id ON oauth_providers (provider, provider_user_id);

-- ============================================================
-- Seed Data: auth_db
-- Password hash is BCrypt of 'password123'
-- ============================================================

INSERT INTO user_credentials (id, email, username, password_hash, role, enabled, email_verified, last_login_at) VALUES
    ('a0000001-0000-0000-0000-000000000001', 'admin@ottnetwork.com',   'admin',        '$2a$10$EqKcp1WFKAr1fMNfGE5LIe8knVsYAypSHqaB4gLqx5hPTgCQ/kmYO', 'ADMIN',           true, true,  NOW() - INTERVAL '1 hour'),
    ('a0000001-0000-0000-0000-000000000002', 'creator@ottnetwork.com', 'creator_john', '$2a$10$EqKcp1WFKAr1fMNfGE5LIe8knVsYAypSHqaB4gLqx5hPTgCQ/kmYO', 'CONTENT_CREATOR', true, true,  NOW() - INTERVAL '2 hours'),
    ('a0000001-0000-0000-0000-000000000003', 'premium@ottnetwork.com', 'premium_jane', '$2a$10$EqKcp1WFKAr1fMNfGE5LIe8knVsYAypSHqaB4gLqx5hPTgCQ/kmYO', 'SUBSCRIBER',      true, true,  NOW() - INTERVAL '30 minutes'),
    ('a0000001-0000-0000-0000-000000000004', 'basic@ottnetwork.com',   'basic_bob',    '$2a$10$EqKcp1WFKAr1fMNfGE5LIe8knVsYAypSHqaB4gLqx5hPTgCQ/kmYO', 'SUBSCRIBER',      true, true,  NOW() - INTERVAL '3 hours'),
    ('a0000001-0000-0000-0000-000000000005', 'free@ottnetwork.com',    'free_alice',   '$2a$10$EqKcp1WFKAr1fMNfGE5LIe8knVsYAypSHqaB4gLqx5hPTgCQ/kmYO', 'SUBSCRIBER',      true, false, NULL);

INSERT INTO refresh_tokens (id, user_id, token, expires_at, revoked) VALUES
    ('11000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000001', 'rt-admin-token-2024-a1b2c3d4e5f6', NOW() + INTERVAL '7 days', false),
    ('11000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000003', 'rt-premium-token-2024-g7h8i9j0k1',  NOW() + INTERVAL '7 days', false),
    ('11000001-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000004', 'rt-basic-token-2024-l2m3n4o5p6',    NOW() + INTERVAL '7 days', false);

INSERT INTO oauth_providers (id, user_id, provider, provider_user_id, access_token) VALUES
    ('12000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000003', 'GOOGLE', '117234567890123456789', 'ya29.google-access-token-sample'),
    ('12000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000005', 'GITHUB', 'gh-user-12345',         'gho_github-access-token-sample');


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 2: user_db
--
--  Service     : user-service
--  Description : User profiles, extended information, viewing preferences, and registered
--                devices. Separated from auth_db to follow single-responsibility principle.
--
-- ============================================================================================
-- ============================================================================================

\c user_db

-- ------------------------------------------------------------
-- Table: users
-- Description: Core user profile information. Each user has a 1:1 link
--              to an authentication record in auth_db.
-- Cross-ref  : auth_user_id references auth_db.user_credentials.id
-- ------------------------------------------------------------
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id    UUID            NOT NULL UNIQUE,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    username        VARCHAR(100)    NOT NULL UNIQUE,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    display_name    VARCHAR(100),
    avatar_url      VARCHAR(512),
    phone           VARCHAR(20),
    date_of_birth   DATE,
    role            VARCHAR(50),
    subscription_tier VARCHAR(50)   NOT NULL DEFAULT 'FREE',
    active          BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          NOT NULL DEFAULT 0
);

CREATE INDEX idx_users_auth_user_id ON users (auth_user_id);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);
CREATE INDEX idx_users_active ON users (active);

-- ------------------------------------------------------------
-- Table: profiles
-- Description: Extended user profile with bio, locale, and avatar.
--              One-to-many relationship with users (supports multi-profile).
-- ------------------------------------------------------------
CREATE TABLE profiles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bio                 VARCHAR(500),
    language            VARCHAR(10)     DEFAULT 'en',
    country             VARCHAR(100),
    timezone            VARCHAR(50),
    profile_image_url   VARCHAR(512),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          NOT NULL DEFAULT 0
);

CREATE INDEX idx_profiles_user_id ON profiles (user_id);

-- ------------------------------------------------------------
-- Table: preferences
-- Description: User viewing and notification preferences. Includes
--              parental controls and content quality settings.
-- ------------------------------------------------------------
CREATE TABLE preferences (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID            NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    email_notifications         BOOLEAN         NOT NULL DEFAULT TRUE,
    push_notifications          BOOLEAN         NOT NULL DEFAULT TRUE,
    autoplay_enabled            BOOLEAN         NOT NULL DEFAULT TRUE,
    default_video_quality       VARCHAR(20)     NOT NULL DEFAULT 'AUTO',
    subtitles_enabled           BOOLEAN         NOT NULL DEFAULT FALSE,
    preferred_language          VARCHAR(10)     NOT NULL DEFAULT 'en',
    parental_control_enabled    BOOLEAN         NOT NULL DEFAULT FALSE,
    parental_control_pin        VARCHAR(255),
    maturity_rating             VARCHAR(10)     NOT NULL DEFAULT 'ALL',
    created_at                  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT NOW(),
    version                     BIGINT          NOT NULL DEFAULT 0
);

CREATE INDEX idx_preferences_user_id ON preferences (user_id);

-- ------------------------------------------------------------
-- Table: devices
-- Description: Registered user devices for push notifications and
--              concurrent stream management.
-- ------------------------------------------------------------
CREATE TABLE devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id       VARCHAR(255)    NOT NULL,
    device_name     VARCHAR(255),
    device_type     VARCHAR(50),
    platform        VARCHAR(50),
    last_active_at  TIMESTAMP,
    push_token      VARCHAR(512),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          NOT NULL DEFAULT 0
);

CREATE INDEX idx_devices_user_id ON devices (user_id);
CREATE UNIQUE INDEX idx_devices_user_device ON devices (user_id, device_id);

-- ============================================================
-- Seed Data: user_db
-- ============================================================

INSERT INTO users (id, auth_user_id, email, username, first_name, last_name, display_name, avatar_url, phone, date_of_birth, role, subscription_tier, active) VALUES
    ('b0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000001', 'admin@ottnetwork.com',   'admin',        'System',  'Admin',    'Admin',        '/avatars/admin.png',   '+1-555-0001', '1985-03-15', 'ADMIN',           'PREMIUM', true),
    ('b0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000002', 'creator@ottnetwork.com', 'creator_john', 'John',    'Director', 'John D.',      '/avatars/john.png',    '+1-555-0002', '1990-07-22', 'CONTENT_CREATOR', 'STANDARD', true),
    ('b0000001-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000003', 'premium@ottnetwork.com', 'premium_jane', 'Jane',    'Smith',    'Jane S.',      '/avatars/jane.png',    '+1-555-0003', '1992-11-08', 'SUBSCRIBER',      'PREMIUM', true),
    ('b0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000004', 'basic@ottnetwork.com',   'basic_bob',    'Bob',     'Wilson',   'Bob W.',       '/avatars/bob.png',     '+1-555-0004', '1988-05-30', 'SUBSCRIBER',      'BASIC',   true),
    ('b0000001-0000-0000-0000-000000000005', 'a0000001-0000-0000-0000-000000000005', 'free@ottnetwork.com',    'free_alice',   'Alice',   'Johnson',  'Alice J.',     '/avatars/alice.png',   '+1-555-0005', '1995-09-12', 'SUBSCRIBER',      'FREE',    true);

INSERT INTO profiles (id, user_id, bio, language, country, timezone, profile_image_url) VALUES
    ('b1000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Platform administrator',                      'en', 'US', 'America/New_York',    '/profiles/admin.png'),
    ('b1000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', 'Independent filmmaker and content creator',    'en', 'US', 'America/Los_Angeles', '/profiles/john.png'),
    ('b1000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 'Movie enthusiast and binge watcher',           'en', 'UK', 'Europe/London',       '/profiles/jane.png'),
    ('b1000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 'Casual viewer, loves documentaries',           'en', 'CA', 'America/Toronto',     '/profiles/bob.png'),
    ('b1000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', 'Just exploring the platform',                  'es', 'MX', 'America/Mexico_City', '/profiles/alice.png');

INSERT INTO preferences (id, user_id, email_notifications, push_notifications, autoplay_enabled, default_video_quality, subtitles_enabled, preferred_language, parental_control_enabled, maturity_rating) VALUES
    ('b2000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', true,  true,  true,  'AUTO',  false, 'en', false, 'ALL'),
    ('b2000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', true,  true,  true,  '1080P', false, 'en', false, 'ALL'),
    ('b2000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', true,  true,  true,  '4K',    true,  'en', false, 'ALL'),
    ('b2000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', false, true,  false, '720P',  false, 'en', true,  'PG13'),
    ('b2000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', true,  false, true,  'AUTO',  true,  'es', false, 'ALL');

INSERT INTO devices (id, user_id, device_id, device_name, device_type, platform, last_active_at, push_token) VALUES
    ('b3000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'dev-admin-macbook',  'Admin MacBook Pro',  'LAPTOP',  'MACOS',   NOW() - INTERVAL '1 hour',  'push-token-admin-001'),
    ('b3000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'dev-jane-iphone',    'Jane iPhone 15',     'MOBILE',  'IOS',     NOW() - INTERVAL '30 minutes', 'push-token-jane-001'),
    ('b3000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 'dev-jane-smarttv',   'Jane Samsung TV',    'TV',      'TIZEN',   NOW() - INTERVAL '2 hours', 'push-token-jane-002'),
    ('b3000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 'dev-bob-android',    'Bob Pixel 8',        'MOBILE',  'ANDROID', NOW() - INTERVAL '5 hours', 'push-token-bob-001'),
    ('b3000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', 'dev-alice-browser',  'Alice Chrome',       'BROWSER', 'WEB',     NOW() - INTERVAL '1 day',   NULL);


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 3: content_db
--
--  Service     : content-service
--  Description : Content catalog including movies, series, seasons, and episodes.
--                Supports categorization via categories and tags with many-to-many
--                join tables.
--
-- ============================================================================================
-- ============================================================================================

\c content_db

-- ------------------------------------------------------------
-- Table: contents
-- Description: Primary content catalog. Represents movies, series,
--              documentaries, and other media types.
-- Cross-ref  : created_by references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE contents (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    title               VARCHAR(255)    NOT NULL,
    slug                VARCHAR(300)    NOT NULL,
    description         VARCHAR(2000),
    content_type        VARCHAR(50),
    status              VARCHAR(50)     NOT NULL DEFAULT 'DRAFT',
    release_year        INTEGER,
    duration            INTEGER,
    maturity_rating     VARCHAR(50),
    language            VARCHAR(50),
    thumbnail_url       VARCHAR(500),
    banner_url          VARCHAR(500),
    trailer_url         VARCHAR(500),
    video_asset_path    VARCHAR(500),
    hls_manifest_url    VARCHAR(500),
    average_rating      DOUBLE PRECISION DEFAULT 0.0,
    rating_count        INTEGER         DEFAULT 0,
    view_count          BIGINT          DEFAULT 0,
    featured            BOOLEAN         NOT NULL DEFAULT FALSE,
    published_at        TIMESTAMP,
    created_by          UUID,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_contents_slug UNIQUE (slug)
);

-- ------------------------------------------------------------
-- Table: categories
-- Description: Hierarchical content categories (e.g., Action, Drama).
--              Supports parent-child relationships via self-referencing FK.
-- ------------------------------------------------------------
CREATE TABLE categories (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(100)    NOT NULL,
    slug                VARCHAR(150)    NOT NULL,
    description         VARCHAR(500),
    icon_url            VARCHAR(500),
    parent_category_id  UUID,
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    display_order       INTEGER         DEFAULT 0,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_categories_name UNIQUE (name),
    CONSTRAINT uk_categories_slug UNIQUE (slug),
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id)
        REFERENCES categories (id) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- Table: tags
-- Description: Free-form tags for content discovery and filtering.
-- ------------------------------------------------------------
CREATE TABLE tags (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL,
    slug            VARCHAR(150)    NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0,

    CONSTRAINT uk_tags_name UNIQUE (name),
    CONSTRAINT uk_tags_slug UNIQUE (slug)
);

-- ------------------------------------------------------------
-- Table: seasons
-- Description: Seasons belonging to a series-type content.
-- ------------------------------------------------------------
CREATE TABLE seasons (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id      UUID            NOT NULL,
    season_number   INTEGER         NOT NULL,
    title           VARCHAR(255),
    description     VARCHAR(2000),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0,

    CONSTRAINT fk_seasons_content FOREIGN KEY (content_id)
        REFERENCES contents (id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Table: episodes
-- Description: Individual episodes within a season.
-- ------------------------------------------------------------
CREATE TABLE episodes (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    season_id           UUID            NOT NULL,
    episode_number      INTEGER         NOT NULL,
    title               VARCHAR(255)    NOT NULL,
    description         VARCHAR(2000),
    duration            INTEGER,
    thumbnail_url       VARCHAR(500),
    video_asset_path    VARCHAR(500),
    hls_manifest_url    VARCHAR(500),
    status              VARCHAR(50)     NOT NULL DEFAULT 'DRAFT',
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT fk_episodes_season FOREIGN KEY (season_id)
        REFERENCES seasons (id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Table: content_categories (Join Table)
-- Description: Many-to-many relationship between contents and categories.
-- ------------------------------------------------------------
CREATE TABLE content_categories (
    content_id      UUID            NOT NULL,
    category_id     UUID            NOT NULL,

    CONSTRAINT pk_content_categories PRIMARY KEY (content_id, category_id),
    CONSTRAINT fk_cc_content FOREIGN KEY (content_id)
        REFERENCES contents (id) ON DELETE CASCADE,
    CONSTRAINT fk_cc_category FOREIGN KEY (category_id)
        REFERENCES categories (id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Table: content_tags (Join Table)
-- Description: Many-to-many relationship between contents and tags.
-- ------------------------------------------------------------
CREATE TABLE content_tags (
    content_id      UUID            NOT NULL,
    tag_id          UUID            NOT NULL,

    CONSTRAINT pk_content_tags PRIMARY KEY (content_id, tag_id),
    CONSTRAINT fk_ct_content FOREIGN KEY (content_id)
        REFERENCES contents (id) ON DELETE CASCADE,
    CONSTRAINT fk_ct_tag FOREIGN KEY (tag_id)
        REFERENCES tags (id) ON DELETE CASCADE
);

-- ============================================================
-- Indexes: content_db
-- ============================================================

-- Contents indexes
CREATE INDEX idx_contents_slug              ON contents (slug);
CREATE INDEX idx_contents_status            ON contents (status);
CREATE INDEX idx_contents_content_type      ON contents (content_type);
CREATE INDEX idx_contents_featured          ON contents (featured) WHERE featured = TRUE;     -- Partial index: only featured content
CREATE INDEX idx_contents_created_by        ON contents (created_by);
CREATE INDEX idx_contents_published_at      ON contents (published_at);
CREATE INDEX idx_contents_title_lower       ON contents (LOWER(title));                       -- Functional index: case-insensitive title search

-- Categories indexes
CREATE INDEX idx_categories_slug            ON categories (slug);
CREATE INDEX idx_categories_parent          ON categories (parent_category_id);
CREATE INDEX idx_categories_active          ON categories (active) WHERE active = TRUE;       -- Partial index: only active categories

-- Tags indexes
CREATE INDEX idx_tags_slug                  ON tags (slug);
CREATE INDEX idx_tags_name_lower            ON tags (LOWER(name));                            -- Functional index: case-insensitive tag search

-- Seasons indexes
CREATE INDEX idx_seasons_content_id         ON seasons (content_id);
CREATE INDEX idx_seasons_content_number     ON seasons (content_id, season_number);           -- Composite: lookup season by content + number

-- Episodes indexes
CREATE INDEX idx_episodes_season_id         ON episodes (season_id);
CREATE INDEX idx_episodes_season_number     ON episodes (season_id, episode_number);          -- Composite: lookup episode by season + number

-- Join table indexes (reverse-side lookups)
CREATE INDEX idx_content_categories_category ON content_categories (category_id);
CREATE INDEX idx_content_tags_tag           ON content_tags (tag_id);

-- ============================================================
-- Seed Data: content_db
-- ============================================================

INSERT INTO contents (id, title, slug, description, content_type, status, release_year, duration, maturity_rating, language, thumbnail_url, banner_url, trailer_url, video_asset_path, hls_manifest_url, average_rating, rating_count, view_count, featured, published_at, created_by) VALUES
    ('c0000001-0000-0000-0000-000000000001', 'Inception',        'inception',        'A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea into the mind of a C.E.O.', 'MOVIE',       'PUBLISHED', 2010, 148, 'PG13', 'en', '/thumbs/inception.jpg',       '/banners/inception.jpg',       '/trailers/inception.mp4',       '/videos/inception/',       '/hls/inception/master.m3u8',       4.8, 2500, 150000, true,  NOW() - INTERVAL '30 days', 'b0000001-0000-0000-0000-000000000002'),
    ('c0000001-0000-0000-0000-000000000002', 'Interstellar',     'interstellar',     'A team of explorers travel through a wormhole in space in an attempt to ensure humanitys survival.',                                     'MOVIE',       'PUBLISHED', 2014, 169, 'PG13', 'en', '/thumbs/interstellar.jpg',    '/banners/interstellar.jpg',    '/trailers/interstellar.mp4',    '/videos/interstellar/',    '/hls/interstellar/master.m3u8',    4.7, 2100, 130000, true,  NOW() - INTERVAL '25 days', 'b0000001-0000-0000-0000-000000000002'),
    ('c0000001-0000-0000-0000-000000000003', 'Breaking Bad',     'breaking-bad',     'A chemistry teacher diagnosed with terminal lung cancer teams up with a former student to manufacture crystal meth.',                   'SERIES',      'PUBLISHED', 2008, NULL,'R',    'en', '/thumbs/breaking-bad.jpg',    '/banners/breaking-bad.jpg',    '/trailers/breaking-bad.mp4',    NULL,                       NULL,                               4.9, 3200, 200000, true,  NOW() - INTERVAL '60 days', 'b0000001-0000-0000-0000-000000000002'),
    ('c0000001-0000-0000-0000-000000000004', 'Planet Earth III',  'planet-earth-iii', 'A breathtaking exploration of the natural wonders of our planet, filmed over four years across every continent.',                       'DOCUMENTARY', 'PUBLISHED', 2023, 300, 'G',    'en', '/thumbs/planet-earth-3.jpg',  '/banners/planet-earth-3.jpg',  '/trailers/planet-earth-3.mp4',  '/videos/planet-earth-3/',  '/hls/planet-earth-3/master.m3u8',  4.6, 800,  45000,  false, NOW() - INTERVAL '15 days', 'b0000001-0000-0000-0000-000000000002'),
    ('c0000001-0000-0000-0000-000000000005', 'The Matrix',       'the-matrix',       'A computer programmer discovers that reality as he knows it is a simulation created by machines, and joins a rebellion to break free.', 'MOVIE',       'PUBLISHED', 1999, 136, 'R',    'en', '/thumbs/the-matrix.jpg',      '/banners/the-matrix.jpg',      '/trailers/the-matrix.mp4',      '/videos/the-matrix/',      '/hls/the-matrix/master.m3u8',      4.5, 1800, 95000,  false, NOW() - INTERVAL '90 days', 'b0000001-0000-0000-0000-000000000002'),
    ('c0000001-0000-0000-0000-000000000006', 'Stranger Things',  'stranger-things',  'When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces, and one strange little girl.', 'SERIES', 'PUBLISHED', 2016, NULL,'PG13', 'en', '/thumbs/stranger-things.jpg', '/banners/stranger-things.jpg', '/trailers/stranger-things.mp4', NULL,                       NULL,                               4.4, 2800, 180000, true,  NOW() - INTERVAL '45 days', 'b0000001-0000-0000-0000-000000000002');

INSERT INTO categories (id, name, slug, description, icon_url, parent_category_id, active, display_order) VALUES
    ('e0000001-0000-0000-0000-000000000001', 'Action',      'action',      'High-energy movies and shows with stunts and fights',    '/icons/action.svg',      NULL, true, 1),
    ('e0000001-0000-0000-0000-000000000002', 'Drama',       'drama',       'Character-driven stories with emotional themes',         '/icons/drama.svg',       NULL, true, 2),
    ('e0000001-0000-0000-0000-000000000003', 'Sci-Fi',      'sci-fi',      'Science fiction exploring futuristic concepts',           '/icons/sci-fi.svg',      NULL, true, 3),
    ('e0000001-0000-0000-0000-000000000004', 'Documentary', 'documentary', 'Non-fiction films about real events and topics',          '/icons/documentary.svg', NULL, true, 4),
    ('e0000001-0000-0000-0000-000000000005', 'Thriller',    'thriller',    'Suspenseful stories that keep you on the edge',          '/icons/thriller.svg',    NULL, true, 5),
    ('e0000001-0000-0000-0000-000000000006', 'Crime',       'crime',       'Stories involving criminal activity and investigations',  '/icons/crime.svg',       NULL, true, 6);

INSERT INTO tags (id, name, slug) VALUES
    ('f0000001-0000-0000-0000-000000000001', 'Mind-Bending', 'mind-bending'),
    ('f0000001-0000-0000-0000-000000000002', 'Space',        'space'),
    ('f0000001-0000-0000-0000-000000000003', 'Crime',        'crime'),
    ('f0000001-0000-0000-0000-000000000004', 'Nature',       'nature'),
    ('f0000001-0000-0000-0000-000000000005', 'Classic',      'classic'),
    ('f0000001-0000-0000-0000-000000000006', 'Award-Winner', 'award-winner'),
    ('f0000001-0000-0000-0000-000000000007', 'Supernatural', 'supernatural'),
    ('f0000001-0000-0000-0000-000000000008', 'Cyberpunk',    'cyberpunk');

-- Breaking Bad: Season 1
INSERT INTO seasons (id, content_id, season_number, title, description) VALUES
    ('5e000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000003', 1, 'Season 1', 'The beginning of Walter Whites transformation from teacher to drug lord.'),
    ('5e000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000006', 1, 'Season 1', 'The disappearance of Will Byers and the appearance of Eleven.');

INSERT INTO episodes (id, season_id, episode_number, title, description, duration, thumbnail_url, video_asset_path, hls_manifest_url, status) VALUES
    ('e1000001-0000-0000-0000-000000000001', '5e000001-0000-0000-0000-000000000001', 1, 'Pilot',                  'Walter White, a high school chemistry teacher, learns he has terminal cancer.',                58, '/thumbs/bb-s1e1.jpg', '/videos/bb/s1/e1/', '/hls/bb/s1/e1/master.m3u8', 'PUBLISHED'),
    ('e1000001-0000-0000-0000-000000000002', '5e000001-0000-0000-0000-000000000001', 2, 'Cat''s in the Bag...',    'Walt and Jesse attempt to dispose of the evidence of their first cook.',                       48, '/thumbs/bb-s1e2.jpg', '/videos/bb/s1/e2/', '/hls/bb/s1/e2/master.m3u8', 'PUBLISHED'),
    ('e1000001-0000-0000-0000-000000000003', '5e000001-0000-0000-0000-000000000001', 3, '...And the Bag''s in the River', 'Walt must deal with the aftermath of a violent confrontation.',                          48, '/thumbs/bb-s1e3.jpg', '/videos/bb/s1/e3/', '/hls/bb/s1/e3/master.m3u8', 'PUBLISHED'),
    ('e1000001-0000-0000-0000-000000000004', '5e000001-0000-0000-0000-000000000002', 1, 'The Vanishing of Will Byers', 'Will Byers vanishes on his way home, and a strange girl appears in the woods.',              49, '/thumbs/st-s1e1.jpg', '/videos/st/s1/e1/', '/hls/st/s1/e1/master.m3u8', 'PUBLISHED'),
    ('e1000001-0000-0000-0000-000000000005', '5e000001-0000-0000-0000-000000000002', 2, 'The Weirdo on Maple Street', 'Lucas, Mike, and Dustin try to talk to Eleven and learn about her past.',                     56, '/thumbs/st-s1e2.jpg', '/videos/st/s1/e2/', '/hls/st/s1/e2/master.m3u8', 'PUBLISHED');

-- Content-Category associations
INSERT INTO content_categories (content_id, category_id) VALUES
    ('c0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001'),  -- Inception -> Action
    ('c0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000003'),  -- Inception -> Sci-Fi
    ('c0000001-0000-0000-0000-000000000002', 'e0000001-0000-0000-0000-000000000003'),  -- Interstellar -> Sci-Fi
    ('c0000001-0000-0000-0000-000000000002', 'e0000001-0000-0000-0000-000000000002'),  -- Interstellar -> Drama
    ('c0000001-0000-0000-0000-000000000003', 'e0000001-0000-0000-0000-000000000002'),  -- Breaking Bad -> Drama
    ('c0000001-0000-0000-0000-000000000003', 'e0000001-0000-0000-0000-000000000006'),  -- Breaking Bad -> Crime
    ('c0000001-0000-0000-0000-000000000004', 'e0000001-0000-0000-0000-000000000004'),  -- Planet Earth III -> Documentary
    ('c0000001-0000-0000-0000-000000000005', 'e0000001-0000-0000-0000-000000000001'),  -- The Matrix -> Action
    ('c0000001-0000-0000-0000-000000000005', 'e0000001-0000-0000-0000-000000000003'),  -- The Matrix -> Sci-Fi
    ('c0000001-0000-0000-0000-000000000006', 'e0000001-0000-0000-0000-000000000005'),  -- Stranger Things -> Thriller
    ('c0000001-0000-0000-0000-000000000006', 'e0000001-0000-0000-0000-000000000003');  -- Stranger Things -> Sci-Fi

-- Content-Tag associations
INSERT INTO content_tags (content_id, tag_id) VALUES
    ('c0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001'),  -- Inception -> Mind-Bending
    ('c0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000006'),  -- Inception -> Award-Winner
    ('c0000001-0000-0000-0000-000000000002', 'f0000001-0000-0000-0000-000000000002'),  -- Interstellar -> Space
    ('c0000001-0000-0000-0000-000000000002', 'f0000001-0000-0000-0000-000000000006'),  -- Interstellar -> Award-Winner
    ('c0000001-0000-0000-0000-000000000003', 'f0000001-0000-0000-0000-000000000003'),  -- Breaking Bad -> Crime
    ('c0000001-0000-0000-0000-000000000003', 'f0000001-0000-0000-0000-000000000006'),  -- Breaking Bad -> Award-Winner
    ('c0000001-0000-0000-0000-000000000004', 'f0000001-0000-0000-0000-000000000004'),  -- Planet Earth III -> Nature
    ('c0000001-0000-0000-0000-000000000005', 'f0000001-0000-0000-0000-000000000008'),  -- The Matrix -> Cyberpunk
    ('c0000001-0000-0000-0000-000000000005', 'f0000001-0000-0000-0000-000000000005'),  -- The Matrix -> Classic
    ('c0000001-0000-0000-0000-000000000006', 'f0000001-0000-0000-0000-000000000007');  -- Stranger Things -> Supernatural


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 4: video_db
--
--  Service     : video-streaming-service
--  Description : Manages video transcoding jobs, multi-resolution video assets,
--                and active playback sessions for adaptive bitrate streaming.
--
-- ============================================================================================
-- ============================================================================================

\c video_db

-- ------------------------------------------------------------
-- Table: transcode_jobs
-- Description: Tracks video transcoding pipeline jobs. Each job converts
--              a source video into multiple resolutions/bitrates.
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE transcode_jobs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id      UUID            NOT NULL,
    input_path      VARCHAR(1000)   NOT NULL,
    status          VARCHAR(50)     NOT NULL DEFAULT 'PENDING',
    output_path     VARCHAR(1000),
    resolutions     VARCHAR(255),
    progress        INTEGER         DEFAULT 0,
    error_message   VARCHAR(2000),
    started_at      TIMESTAMP,
    completed_at    TIMESTAMP,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: video_assets
-- Description: Individual video renditions at specific resolutions.
--              Each content item can have multiple assets (360p, 720p, 1080p, 4K).
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE video_assets (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id      UUID            NOT NULL,
    resolution      VARCHAR(20),
    file_path       VARCHAR(1000),
    manifest_path   VARCHAR(1000),
    file_size       BIGINT,
    bitrate         INTEGER,
    codec           VARCHAR(50)     DEFAULT 'h264',
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: playback_sessions
-- Description: Active and historical playback sessions. Used for
--              resume-watching, concurrent stream limits, and analytics.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE playback_sessions (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    session_id          VARCHAR(255)    NOT NULL,
    current_position    BIGINT          DEFAULT 0,
    duration            BIGINT,
    quality             VARCHAR(20)     DEFAULT 'AUTO',
    started_at          TIMESTAMP,
    last_updated_at     TIMESTAMP,
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_playback_sessions_session_id UNIQUE (session_id)
);

-- ============================================================
-- Indexes: video_db
-- ============================================================

-- Transcode Jobs indexes
CREATE INDEX idx_transcode_jobs_content_id          ON transcode_jobs (content_id);
CREATE INDEX idx_transcode_jobs_status              ON transcode_jobs (status);
CREATE INDEX idx_transcode_jobs_content_id_status   ON transcode_jobs (content_id, status);    -- Composite: find jobs by content + status

-- Video Assets indexes
CREATE INDEX idx_video_assets_content_id            ON video_assets (content_id);
CREATE INDEX idx_video_assets_content_id_resolution ON video_assets (content_id, resolution);  -- Composite: find asset by content + resolution

-- Playback Sessions indexes
CREATE INDEX idx_playback_sessions_session_id                       ON playback_sessions (session_id);
CREATE INDEX idx_playback_sessions_user_id_content_id_active        ON playback_sessions (user_id, content_id, active);  -- Composite: find active session
CREATE INDEX idx_playback_sessions_user_id_active                   ON playback_sessions (user_id, active);              -- Composite: all active sessions for user

-- ============================================================
-- Seed Data: video_db
-- ============================================================

INSERT INTO transcode_jobs (id, content_id, input_path, status, output_path, resolutions, progress, started_at, completed_at) VALUES
    ('70000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', '/uploads/inception.mp4',       'COMPLETED', '/videos/inception/',       '360p,720p,1080p,4k', 100, NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days' + INTERVAL '45 minutes'),
    ('70000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000002', '/uploads/interstellar.mp4',    'COMPLETED', '/videos/interstellar/',    '360p,720p,1080p,4k', 100, NOW() - INTERVAL '24 days', NOW() - INTERVAL '24 days' + INTERVAL '50 minutes'),
    ('70000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000004', '/uploads/planet-earth-3.mp4',  'COMPLETED', '/videos/planet-earth-3/',  '360p,720p,1080p',    100, NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days' + INTERVAL '60 minutes'),
    ('70000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', '/uploads/the-matrix.mp4',      'COMPLETED', '/videos/the-matrix/',      '360p,720p,1080p,4k', 100, NOW() - INTERVAL '89 days', NOW() - INTERVAL '89 days' + INTERVAL '40 minutes');

INSERT INTO video_assets (id, content_id, resolution, file_path, manifest_path, file_size, bitrate, codec) VALUES
    ('71000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', '360p',  '/videos/inception/360p/',  '/hls/inception/360p/index.m3u8',  524288000,  800,  'h264'),
    ('71000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000001', '720p',  '/videos/inception/720p/',  '/hls/inception/720p/index.m3u8',  1572864000, 2500, 'h264'),
    ('71000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', '1080p', '/videos/inception/1080p/', '/hls/inception/1080p/index.m3u8', 3145728000, 5000, 'h264'),
    ('71000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000002', '720p',  '/videos/interstellar/720p/',  '/hls/interstellar/720p/index.m3u8',  1677721600, 2500, 'h264'),
    ('71000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000002', '1080p', '/videos/interstellar/1080p/', '/hls/interstellar/1080p/index.m3u8', 3355443200, 5000, 'h264'),
    ('71000001-0000-0000-0000-000000000006', 'c0000001-0000-0000-0000-000000000005', '1080p', '/videos/the-matrix/1080p/',   '/hls/the-matrix/1080p/index.m3u8',   2621440000, 5000, 'h264');

INSERT INTO playback_sessions (id, user_id, content_id, session_id, current_position, duration, quality, started_at, last_updated_at, active) VALUES
    ('72000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'sess-jane-inception-001',   5400, 8880, '1080P', NOW() - INTERVAL '2 hours',  NOW() - INTERVAL '30 minutes', false),
    ('72000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'sess-jane-interstellar-001', 3200, 10140, '4K',   NOW() - INTERVAL '1 hour',   NOW() - INTERVAL '10 minutes', true),
    ('72000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'sess-bob-matrix-001',        7800, 8160, '720P',  NOW() - INTERVAL '3 hours',  NOW() - INTERVAL '1 hour',     false),
    ('72000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'sess-alice-inception-001',   1200, 8880, 'AUTO',  NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '5 minutes', true);


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 5: subscription_db
--
--  Service     : subscription-service
--  Description : Subscription plan management, user subscriptions, payment processing
--                (Stripe integration), invoicing, and promotional coupons.
--
-- ============================================================================================
-- ============================================================================================

\c subscription_db

-- ------------------------------------------------------------
-- Table: plans
-- Description: Available subscription tiers (Free, Basic, Standard, Premium).
--              Each plan defines pricing, feature flags, and device limits.
-- ------------------------------------------------------------
CREATE TABLE plans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    tier            VARCHAR(20) NOT NULL,
    price           DECIMAL(10,2) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'USD',
    duration_days   INTEGER NOT NULL,
    max_devices     INTEGER DEFAULT 1,
    max_profiles    INTEGER DEFAULT 1,
    hd_enabled      BOOLEAN DEFAULT FALSE,
    uhd_enabled     BOOLEAN DEFAULT FALSE,
    ads_enabled     BOOLEAN DEFAULT TRUE,
    active          BOOLEAN DEFAULT TRUE,
    stripe_price_id VARCHAR(255),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    version         BIGINT DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: subscriptions
-- Description: Active and historical user subscriptions.
--              Links a user to a plan with start/end dates.
-- Cross-ref  : user_id references user_db.users.id (via auth_user_id)
-- ------------------------------------------------------------
CREATE TABLE subscriptions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL,
    plan_id                 UUID NOT NULL REFERENCES plans(id),
    status                  VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    start_date              TIMESTAMP NOT NULL,
    end_date                TIMESTAMP NOT NULL,
    auto_renew              BOOLEAN DEFAULT TRUE,
    stripe_subscription_id  VARCHAR(255),
    cancelled_at            TIMESTAMP,
    cancel_reason           TEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    version                 BIGINT DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: payments
-- Description: Payment transactions linked to subscriptions.
--              Integrates with Stripe for payment processing.
-- Cross-ref  : user_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE payments (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  UUID NOT NULL,
    subscription_id          UUID REFERENCES subscriptions(id),
    amount                   DECIMAL(10,2) NOT NULL,
    currency                 VARCHAR(3) NOT NULL DEFAULT 'USD',
    status                   VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method           VARCHAR(20),
    stripe_payment_intent_id VARCHAR(255),
    stripe_charge_id         VARCHAR(255),
    paid_at                  TIMESTAMP,
    created_at               TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMP NOT NULL DEFAULT NOW(),
    version                  BIGINT DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: invoices
-- Description: Invoice records generated for each payment.
--              Includes tax calculation and due date tracking.
-- Cross-ref  : user_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE invoices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    payment_id      UUID UNIQUE REFERENCES payments(id),
    subscription_id UUID REFERENCES subscriptions(id),
    invoice_number  VARCHAR(50) NOT NULL UNIQUE,
    amount          DECIMAL(10,2),
    tax             DECIMAL(10,2) DEFAULT 0,
    total_amount    DECIMAL(10,2),
    status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    issued_at       TIMESTAMP,
    due_date        TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    version         BIGINT DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: coupons
-- Description: Promotional discount codes. Supports percentage and
--              fixed-amount discounts with usage limits and expiry.
-- ------------------------------------------------------------
CREATE TABLE coupons (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code             VARCHAR(50) NOT NULL UNIQUE,
    discount_type    VARCHAR(20) NOT NULL,
    discount_value   DECIMAL(10,2) NOT NULL,
    max_uses         INTEGER,
    current_uses     INTEGER DEFAULT 0,
    valid_from       TIMESTAMP,
    valid_until      TIMESTAMP,
    applicable_plans TEXT DEFAULT 'ALL',
    active           BOOLEAN DEFAULT TRUE,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    version          BIGINT DEFAULT 0
);

-- ============================================================
-- Indexes: subscription_db
-- ============================================================

-- Subscriptions indexes
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);               -- Composite: find user's active subscription
CREATE INDEX idx_subscriptions_end_date ON subscriptions(end_date);                         -- For expiration batch jobs
CREATE INDEX idx_subscriptions_stripe_sub_id ON subscriptions(stripe_subscription_id);      -- Stripe webhook lookups

-- Payments indexes
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_subscription_id ON payments(subscription_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_stripe_pi_id ON payments(stripe_payment_intent_id);               -- Stripe webhook lookups

-- Invoices indexes
CREATE INDEX idx_invoices_user_id ON invoices(user_id);
CREATE INDEX idx_invoices_payment_id ON invoices(payment_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);

-- Coupons indexes
CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_active ON coupons(active);

-- ============================================================
-- Seed Data: Default Subscription Plans
-- ============================================================

INSERT INTO plans (id, name, description, tier, price, currency, duration_days, max_devices, max_profiles, hd_enabled, uhd_enabled, ads_enabled, active)
VALUES
    ('d0000001-0000-0000-0000-000000000001', 'Free', 'Free plan with ads', 'FREE', 0.00, 'USD', 365, 1, 1, false, false, true, true),
    ('d0000001-0000-0000-0000-000000000002', 'Basic Monthly', 'Basic plan - HD, no ads', 'BASIC', 8.99, 'USD', 30, 1, 2, true, false, false, true),
    ('d0000001-0000-0000-0000-000000000003', 'Basic Yearly', 'Basic plan - HD, no ads (annual)', 'BASIC', 89.99, 'USD', 365, 1, 2, true, false, false, true),
    ('d0000001-0000-0000-0000-000000000004', 'Standard Monthly', 'Standard plan - HD, 3 devices', 'STANDARD', 13.99, 'USD', 30, 3, 4, true, false, false, true),
    ('d0000001-0000-0000-0000-000000000005', 'Standard Yearly', 'Standard plan - HD, 3 devices (annual)', 'STANDARD', 139.99, 'USD', 365, 3, 4, true, false, false, true),
    ('d0000001-0000-0000-0000-000000000006', 'Premium Monthly', 'Premium plan - UHD, 5 devices', 'PREMIUM', 17.99, 'USD', 30, 5, 6, true, true, false, true),
    ('d0000001-0000-0000-0000-000000000007', 'Premium Yearly', 'Premium plan - UHD, 5 devices (annual)', 'PREMIUM', 179.99, 'USD', 365, 5, 6, true, true, false, true);

INSERT INTO subscriptions (id, user_id, plan_id, status, start_date, end_date, auto_renew, stripe_subscription_id) VALUES
    ('80000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000006', 'ACTIVE',    NOW() - INTERVAL '15 days', NOW() + INTERVAL '15 days', true,  'sub_stripe_premium_jane_001'),
    ('80000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000002', 'ACTIVE',    NOW() - INTERVAL '10 days', NOW() + INTERVAL '20 days', true,  'sub_stripe_basic_bob_001'),
    ('80000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000001', 'ACTIVE',    NOW() - INTERVAL '60 days', NOW() + INTERVAL '305 days', false, NULL),
    ('80000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000007', 'ACTIVE',    NOW() - INTERVAL '100 days', NOW() + INTERVAL '265 days', true, 'sub_stripe_premium_admin_001');

INSERT INTO payments (id, user_id, subscription_id, amount, currency, status, payment_method, stripe_payment_intent_id, stripe_charge_id, paid_at) VALUES
    ('81000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', '80000001-0000-0000-0000-000000000001', 17.99, 'USD', 'COMPLETED', 'CARD', 'pi_stripe_premium_jane_001', 'ch_stripe_premium_jane_001', NOW() - INTERVAL '15 days'),
    ('81000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', '80000001-0000-0000-0000-000000000002', 8.99,  'USD', 'COMPLETED', 'CARD', 'pi_stripe_basic_bob_001',    'ch_stripe_basic_bob_001',    NOW() - INTERVAL '10 days'),
    ('81000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', '80000001-0000-0000-0000-000000000004', 179.99,'USD', 'COMPLETED', 'CARD', 'pi_stripe_premium_admin_001','ch_stripe_premium_admin_001',NOW() - INTERVAL '100 days');

INSERT INTO invoices (id, user_id, payment_id, subscription_id, invoice_number, amount, tax, total_amount, status, issued_at, due_date) VALUES
    ('82000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', '81000001-0000-0000-0000-000000000001', '80000001-0000-0000-0000-000000000001', 'INV-2026-0001', 17.99, 1.80, 19.79, 'PAID', NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days' + INTERVAL '30 days'),
    ('82000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', '81000001-0000-0000-0000-000000000002', '80000001-0000-0000-0000-000000000002', 'INV-2026-0002', 8.99,  0.90, 9.89,  'PAID', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days' + INTERVAL '30 days'),
    ('82000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', '81000001-0000-0000-0000-000000000003', '80000001-0000-0000-0000-000000000004', 'INV-2025-0100', 179.99,18.00,197.99,'PAID', NOW() - INTERVAL '100 days', NOW() - INTERVAL '100 days' + INTERVAL '30 days');

INSERT INTO coupons (id, code, discount_type, discount_value, max_uses, current_uses, valid_from, valid_until, applicable_plans, active) VALUES
    ('83000001-0000-0000-0000-000000000001', 'WELCOME50',    'PERCENTAGE', 50.00, 1000, 150, NOW() - INTERVAL '30 days', NOW() + INTERVAL '60 days',  'ALL',     true),
    ('83000001-0000-0000-0000-000000000002', 'PREMIUM10OFF', 'FIXED',      10.00, 500,  42,  NOW() - INTERVAL '15 days', NOW() + INTERVAL '45 days',  'PREMIUM', true),
    ('83000001-0000-0000-0000-000000000003', 'SUMMER2026',   'PERCENTAGE', 25.00, 2000, 0,   NOW() + INTERVAL '90 days', NOW() + INTERVAL '180 days', 'ALL',     false);


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 6: recommendation_db
--
--  Service     : recommendation-service
--  Description : Powers the recommendation engine by tracking user interactions
--                (views, ratings, searches) and pre-computed content similarity scores
--                using content-based and collaborative filtering algorithms.
--
-- ============================================================================================
-- ============================================================================================

\c recommendation_db

-- ------------------------------------------------------------
-- Table: user_interactions
-- Description: Records every user interaction with content for
--              building recommendation models.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE user_interactions (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    interaction_type    VARCHAR(50)     NOT NULL,
    rating              INTEGER,
    watch_duration      BIGINT,
    interacted_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT chk_interaction_type
        CHECK (interaction_type IN ('VIEW', 'RATE', 'WATCHLIST_ADD', 'SEARCH', 'COMPLETE'))
);

-- ------------------------------------------------------------
-- Table: content_similarities
-- Description: Pre-computed pairwise similarity scores between content items.
--              Used for "more like this" and collaborative filtering recommendations.
-- Cross-ref  : content_id_1, content_id_2 reference content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE content_similarities (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id_1        UUID            NOT NULL,
    content_id_2        UUID            NOT NULL,
    similarity_score    DOUBLE PRECISION NOT NULL,
    algorithm_type      VARCHAR(50)     NOT NULL,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_content_similarity_pair_algo
        UNIQUE (content_id_1, content_id_2, algorithm_type),
    CONSTRAINT chk_similarity_score
        CHECK (similarity_score >= 0.0 AND similarity_score <= 1.0),
    CONSTRAINT chk_algorithm_type
        CHECK (algorithm_type IN ('CONTENT_BASED', 'COLLABORATIVE'))
);

-- ============================================================
-- Indexes: recommendation_db
-- ============================================================

-- User interactions indexes
CREATE INDEX idx_user_interactions_user_id          ON user_interactions (user_id);
CREATE INDEX idx_user_interactions_content_id        ON user_interactions (content_id);
CREATE INDEX idx_user_interactions_type              ON user_interactions (interaction_type);
CREATE INDEX idx_user_interactions_user_content      ON user_interactions (user_id, content_id);      -- Composite: check if user interacted with content
CREATE INDEX idx_user_interactions_interacted_at     ON user_interactions (interacted_at);
CREATE INDEX idx_user_interactions_user_time         ON user_interactions (user_id, interacted_at DESC);  -- Composite: recent interactions for user

-- Content similarities indexes
CREATE INDEX idx_content_sim_content1               ON content_similarities (content_id_1);
CREATE INDEX idx_content_sim_content2               ON content_similarities (content_id_2);
CREATE INDEX idx_content_sim_score                  ON content_similarities (similarity_score DESC);    -- For top-N similar content queries
CREATE INDEX idx_content_sim_algorithm              ON content_similarities (algorithm_type);

-- ============================================================
-- Seed Data: recommendation_db
-- ============================================================

INSERT INTO user_interactions (id, user_id, content_id, interaction_type, rating, watch_duration, interacted_at) VALUES
    ('90000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'VIEW',          NULL, 8880,  NOW() - INTERVAL '5 days'),
    ('90000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'RATE',          5,    NULL,  NOW() - INTERVAL '5 days'),
    ('90000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'VIEW',          NULL, 5200,  NOW() - INTERVAL '3 days'),
    ('90000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'VIEW',          NULL, 7800,  NOW() - INTERVAL '2 days'),
    ('90000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'RATE',          4,    NULL,  NOW() - INTERVAL '2 days'),
    ('90000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'VIEW',          NULL, 1200,  NOW() - INTERVAL '1 day'),
    ('90000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 'WATCHLIST_ADD', NULL, NULL,  NOW() - INTERVAL '7 days'),
    ('90000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'VIEW',          NULL, 18000, NOW() - INTERVAL '4 days'),
    ('90000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'COMPLETE',      NULL, 18000, NOW() - INTERVAL '4 days'),
    ('90000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000006', 'SEARCH',        NULL, NULL,  NOW() - INTERVAL '6 hours');

INSERT INTO content_similarities (id, content_id_1, content_id_2, similarity_score, algorithm_type) VALUES
    ('91000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000002', 0.85, 'CONTENT_BASED'),
    ('91000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000005', 0.78, 'CONTENT_BASED'),
    ('91000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000005', 0.72, 'CONTENT_BASED'),
    ('91000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000006', 0.65, 'COLLABORATIVE'),
    ('91000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000006', 0.55, 'COLLABORATIVE');


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 7: watchlist_db
--
--  Service     : watchlist-service
--  Description : Manages user watchlists (save-for-later), complete watch history,
--                and per-content playback progress for resume-watching functionality.
--
-- ============================================================================================
-- ============================================================================================

\c watchlist_db

-- ------------------------------------------------------------
-- Table: watchlist_items
-- Description: User's "My List" / "Watch Later" bookmarks.
--              Each user can add a content item to their watchlist once.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE watchlist_items (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    added_at            TIMESTAMP       NOT NULL DEFAULT NOW(),
    note                VARCHAR(500),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_watchlist_user_content UNIQUE (user_id, content_id)
);

-- ------------------------------------------------------------
-- Table: watch_history
-- Description: Complete viewing history. Records each watch session
--              including duration and completion percentage.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE watch_history (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID            NOT NULL,
    content_id              UUID            NOT NULL,
    watched_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    watch_duration          BIGINT,
    completion_percentage   DOUBLE PRECISION,
    created_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    version                 BIGINT          DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: playback_progress
-- Description: Per-user, per-content playback position for "continue watching".
--              Only one progress record per user-content pair.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE playback_progress (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    position_seconds    BIGINT          NOT NULL DEFAULT 0,
    duration_seconds    BIGINT,
    last_updated_at     TIMESTAMP,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_playback_user_content UNIQUE (user_id, content_id)
);

-- ============================================================
-- Indexes: watchlist_db
-- ============================================================

-- Watchlist items indexes
CREATE INDEX idx_watchlist_user_id           ON watchlist_items (user_id);
CREATE INDEX idx_watchlist_content_id        ON watchlist_items (content_id);
CREATE INDEX idx_watchlist_user_added_at     ON watchlist_items (user_id, added_at DESC);    -- Composite: recent watchlist entries

-- Watch history indexes
CREATE INDEX idx_watch_history_user_id       ON watch_history (user_id);
CREATE INDEX idx_watch_history_content_id    ON watch_history (content_id);
CREATE INDEX idx_watch_history_user_watched  ON watch_history (user_id, watched_at DESC);   -- Composite: recent watch history
CREATE INDEX idx_watch_history_user_content  ON watch_history (user_id, content_id);         -- Composite: check if user watched content

-- Playback progress indexes
CREATE INDEX idx_playback_user_id            ON playback_progress (user_id);
CREATE INDEX idx_playback_content_id         ON playback_progress (content_id);
CREATE INDEX idx_playback_user_last_updated  ON playback_progress (user_id, last_updated_at DESC);  -- Composite: recently updated progress

-- ============================================================
-- Seed Data: watchlist_db
-- ============================================================

INSERT INTO watchlist_items (id, user_id, content_id, added_at, note) VALUES
    ('a1000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', NOW() - INTERVAL '7 days',  'Must watch - highly recommended'),
    ('a1000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000004', NOW() - INTERVAL '3 days',  NULL),
    ('a1000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days',  'Weekend watch'),
    ('a1000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000006', NOW() - INTERVAL '1 day',   NULL),
    ('a1000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000002', NOW() - INTERVAL '2 days',  'Looks amazing');

INSERT INTO watch_history (id, user_id, content_id, watched_at, watch_duration, completion_percentage) VALUES
    ('a2000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days',  8880,  100.0),
    ('a2000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', NOW() - INTERVAL '3 days',  5200,  51.3),
    ('a2000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', NOW() - INTERVAL '2 days',  7800,  95.6),
    ('a2000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', NOW() - INTERVAL '4 days',  18000, 100.0),
    ('a2000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day',   1200,  13.5);

INSERT INTO playback_progress (id, user_id, content_id, position_seconds, duration_seconds, last_updated_at) VALUES
    ('a3000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 5200,  10140, NOW() - INTERVAL '10 minutes'),
    ('a3000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 1200,  8880,  NOW() - INTERVAL '5 minutes'),
    ('a3000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000003', 3480,  3480,  NOW() - INTERVAL '1 day');


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 8: notification_db
--
--  Service     : notification-service
--  Description : Multi-channel notification system supporting email, push, and in-app
--                notifications. Includes template management and per-user preferences.
--
-- ============================================================================================
-- ============================================================================================

\c notification_db

-- ------------------------------------------------------------
-- Table: notifications
-- Description: Individual notification records delivered to users.
--              Tracks delivery status and read state.
-- Cross-ref  : user_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE notifications (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    type                VARCHAR(50)     NOT NULL,
    channel             VARCHAR(50)     NOT NULL,
    title               VARCHAR(255)    NOT NULL,
    message             VARCHAR(2000)   NOT NULL,
    data                TEXT,
    link                VARCHAR(500),
    read                BOOLEAN         NOT NULL DEFAULT FALSE,
    sent                BOOLEAN         NOT NULL DEFAULT FALSE,
    sent_at             TIMESTAMP,
    read_at             TIMESTAMP,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT chk_notification_type
        CHECK (type IN ('EMAIL', 'PUSH', 'IN_APP')),
    CONSTRAINT chk_notification_channel
        CHECK (channel IN ('EMAIL', 'PUSH', 'IN_APP'))
);

-- ------------------------------------------------------------
-- Table: notification_templates
-- Description: Reusable notification templates with placeholder support.
--              Templates define subject and body with {{variable}} syntax.
-- ------------------------------------------------------------
CREATE TABLE notification_templates (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255)    NOT NULL,
    type                VARCHAR(50)     NOT NULL,
    subject             VARCHAR(500),
    body                VARCHAR(5000),
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_notification_templates_name UNIQUE (name),
    CONSTRAINT chk_template_type
        CHECK (type IN ('EMAIL', 'PUSH', 'IN_APP'))
);

-- ------------------------------------------------------------
-- Table: user_notification_preferences
-- Description: Per-user opt-in/opt-out settings for each notification
--              channel and category.
-- Cross-ref  : user_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE user_notification_preferences (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID            NOT NULL,
    email_enabled           BOOLEAN         NOT NULL DEFAULT TRUE,
    push_enabled            BOOLEAN         NOT NULL DEFAULT TRUE,
    in_app_enabled          BOOLEAN         NOT NULL DEFAULT TRUE,
    new_content_alerts      BOOLEAN         NOT NULL DEFAULT TRUE,
    subscription_alerts     BOOLEAN         NOT NULL DEFAULT TRUE,
    promotional_alerts      BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    version                 BIGINT          DEFAULT 0,

    CONSTRAINT uk_user_notification_prefs_user_id UNIQUE (user_id)
);

-- ============================================================
-- Indexes: notification_db
-- ============================================================

-- Notifications indexes
CREATE INDEX idx_notifications_user_id              ON notifications (user_id);
CREATE INDEX idx_notifications_user_read            ON notifications (user_id, read);                -- Composite: unread notifications for user
CREATE INDEX idx_notifications_user_created         ON notifications (user_id, created_at DESC);     -- Composite: recent notifications for user
CREATE INDEX idx_notifications_type                 ON notifications (type);
CREATE INDEX idx_notifications_channel              ON notifications (channel);
CREATE INDEX idx_notifications_sent                 ON notifications (sent);                         -- For retry/delivery queue processing
CREATE INDEX idx_notifications_created_at           ON notifications (created_at);

-- Notification templates indexes
CREATE INDEX idx_notification_templates_name        ON notification_templates (name);
CREATE INDEX idx_notification_templates_type        ON notification_templates (type);
CREATE INDEX idx_notification_templates_active      ON notification_templates (active) WHERE active = TRUE;  -- Partial: only active templates

-- User notification preferences indexes
CREATE INDEX idx_user_notif_prefs_user_id           ON user_notification_preferences (user_id);

-- ============================================================
-- Seed Data: Default Notification Templates
-- ============================================================

INSERT INTO notification_templates (id, name, type, subject, body, active) VALUES
    (gen_random_uuid(), 'WELCOME', 'EMAIL',
     'Welcome to OTT Network, {{username}}!',
     'Hi {{username}}, Welcome to OTT Network! We are excited to have you on board. Start exploring thousands of movies, shows, and live streams. Enjoy your experience!',
     TRUE),

    (gen_random_uuid(), 'SUBSCRIPTION_CONFIRMED', 'EMAIL',
     'Subscription Confirmed - {{planName}}',
     'Your subscription to the {{planName}} plan has been confirmed. You now have access to all {{tier}} tier content. Enjoy unlimited streaming!',
     TRUE),

    (gen_random_uuid(), 'SUBSCRIPTION_EXPIRED', 'EMAIL',
     'Your Subscription Has Expired',
     'Your OTT Network subscription has expired. Renew now to continue enjoying unlimited access to our content library.',
     TRUE),

    (gen_random_uuid(), 'PAYMENT_RECEIPT', 'EMAIL',
     'Payment Receipt - {{amount}} {{currency}}',
     'We have received your payment of {{amount}} {{currency}}. Payment ID: {{paymentId}}. Thank you for your continued subscription!',
     TRUE),

    (gen_random_uuid(), 'NEW_CONTENT', 'IN_APP',
     'New Content Available: {{title}}',
     'A new title "{{title}}" has been added to our library. Check it out now!',
     TRUE),

    (gen_random_uuid(), 'LIVE_STREAM_STARTING', 'PUSH',
     'Live Stream Starting: {{title}}',
     '{{title}} is going live now! Tap to watch.',
     TRUE);

-- Seed Data: Notifications
INSERT INTO notifications (id, user_id, type, channel, title, message, data, link, read, sent, sent_at, read_at) VALUES
    ('a4000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'EMAIL',  'EMAIL',  'Welcome to OTT Network, premium_jane!',          'Hi premium_jane, Welcome to OTT Network! Start exploring thousands of movies.', NULL,                          '/home',             true,  true, NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
    ('a4000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'EMAIL',  'EMAIL',  'Subscription Confirmed - Premium Monthly',        'Your subscription to the Premium Monthly plan has been confirmed.',               '{"planId":"d0000001-0000-0000-0000-000000000006"}', '/account/subscription', true,  true, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
    ('a4000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000004', 'IN_APP', 'IN_APP', 'New Content Available: Planet Earth III',          'A new title "Planet Earth III" has been added to our library. Check it out now!', '{"contentId":"c0000001-0000-0000-0000-000000000004"}', '/content/planet-earth-iii', false, true, NOW() - INTERVAL '15 days', NULL),
    ('a4000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000005', 'IN_APP', 'IN_APP', 'New Content Available: Stranger Things',           'A new title "Stranger Things" has been added!',                                   '{"contentId":"c0000001-0000-0000-0000-000000000006"}', '/content/stranger-things', false, true, NOW() - INTERVAL '45 days', NULL),
    ('a4000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000003', 'PUSH',   'PUSH',   'Continue Watching: Interstellar',                  'You left off at 51% - pick up where you stopped!',                               '{"contentId":"c0000001-0000-0000-0000-000000000002","position":5200}', '/watch/interstellar', false, true, NOW() - INTERVAL '1 day', NULL);

-- Seed Data: User Notification Preferences
INSERT INTO user_notification_preferences (id, user_id, email_enabled, push_enabled, in_app_enabled, new_content_alerts, subscription_alerts, promotional_alerts) VALUES
    ('a5000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', true,  true,  true,  true,  true,  false),
    ('a5000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', true,  true,  true,  true,  true,  false),
    ('a5000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', true,  true,  true,  true,  true,  true),
    ('a5000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', false, true,  true,  true,  true,  false),
    ('a5000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000005', true,  false, true,  false, true,  false);


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 9: analytics_db
--
--  Service     : analytics-service
--  Description : Platform-wide analytics including raw view events, pre-aggregated
--                daily metrics per content, and daily revenue/subscription metrics.
--
-- ============================================================================================
-- ============================================================================================

\c analytics_db

-- ------------------------------------------------------------
-- Table: view_events
-- Description: Raw playback and interaction events. High-volume table
--              used for real-time analytics and later aggregation.
-- Cross-ref  : user_id references user_db.users.id (nullable for anonymous views)
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE view_events (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID,
    content_id          UUID NOT NULL,
    session_id          VARCHAR(255),
    event_type          VARCHAR(50),
    position_seconds    BIGINT,
    duration_seconds    BIGINT,
    device_type         VARCHAR(50),
    platform            VARCHAR(50),
    country             VARCHAR(10),
    timestamp           TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    version             BIGINT DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: daily_aggregates
-- Description: Pre-computed daily content performance metrics.
--              Populated by scheduled aggregation jobs from view_events.
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE daily_aggregates (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date                        DATE NOT NULL,
    content_id                  UUID,
    total_views                 BIGINT DEFAULT 0,
    unique_viewers              BIGINT DEFAULT 0,
    total_watch_time_seconds    BIGINT DEFAULT 0,
    average_watch_time_seconds  DOUBLE PRECISION DEFAULT 0.0,
    completion_rate             DOUBLE PRECISION DEFAULT 0.0,
    created_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    version                     BIGINT DEFAULT 0,
    CONSTRAINT uq_daily_aggregates_date_content UNIQUE (date, content_id)
);

-- ------------------------------------------------------------
-- Table: revenue_metrics
-- Description: Daily platform-wide revenue and subscription metrics.
--              One row per day with subscription and ad revenue totals.
-- ------------------------------------------------------------
CREATE TABLE revenue_metrics (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date                        DATE NOT NULL,
    subscription_revenue        DECIMAL(12,2) DEFAULT 0,
    ad_revenue                  DECIMAL(12,2) DEFAULT 0,
    total_revenue               DECIMAL(12,2) DEFAULT 0,
    new_subscriptions           INTEGER DEFAULT 0,
    cancelled_subscriptions     INTEGER DEFAULT 0,
    active_subscriptions        INTEGER DEFAULT 0,
    created_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP NOT NULL DEFAULT NOW(),
    version                     BIGINT DEFAULT 0,
    CONSTRAINT uq_revenue_metrics_date UNIQUE (date)
);

-- ============================================================
-- Indexes: analytics_db
-- ============================================================

-- View events indexes
CREATE INDEX idx_view_events_content_id ON view_events(content_id);
CREATE INDEX idx_view_events_user_id ON view_events(user_id);
CREATE INDEX idx_view_events_timestamp ON view_events(timestamp);
CREATE INDEX idx_view_events_event_type ON view_events(event_type);
CREATE INDEX idx_view_events_user_content ON view_events(user_id, content_id);              -- Composite: user's events for specific content
CREATE INDEX idx_view_events_type_timestamp ON view_events(event_type, timestamp);          -- Composite: events by type in time range

-- Daily aggregates indexes
CREATE INDEX idx_daily_aggregates_date ON daily_aggregates(date);
CREATE INDEX idx_daily_aggregates_content_id ON daily_aggregates(content_id);
CREATE INDEX idx_daily_aggregates_date_range ON daily_aggregates(date, content_id);         -- Composite: content metrics in date range
CREATE INDEX idx_daily_aggregates_views ON daily_aggregates(total_views DESC);              -- For top-content leaderboards

-- Revenue metrics indexes
CREATE INDEX idx_revenue_metrics_date ON revenue_metrics(date);
CREATE INDEX idx_revenue_metrics_date_range ON revenue_metrics(date);

-- ============================================================
-- Seed Data: analytics_db
-- ============================================================

INSERT INTO view_events (id, user_id, content_id, session_id, event_type, position_seconds, duration_seconds, device_type, platform, country, timestamp) VALUES
    ('a6000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'sess-jane-inception-001',    'PLAY',     0,    8880, 'MOBILE',  'IOS',     'GB', NOW() - INTERVAL '5 days'),
    ('a6000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'sess-jane-inception-001',    'COMPLETE', 8880, 8880, 'MOBILE',  'IOS',     'GB', NOW() - INTERVAL '5 days' + INTERVAL '148 minutes'),
    ('a6000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'sess-jane-interstellar-001', 'PLAY',     0,    10140,'TV',      'TIZEN',   'GB', NOW() - INTERVAL '3 days'),
    ('a6000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'sess-jane-interstellar-001', 'PAUSE',    5200, 10140,'TV',      'TIZEN',   'GB', NOW() - INTERVAL '3 days' + INTERVAL '87 minutes'),
    ('a6000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'sess-bob-matrix-001',        'PLAY',     0,    8160, 'MOBILE',  'ANDROID', 'CA', NOW() - INTERVAL '2 days'),
    ('a6000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'sess-bob-matrix-001',        'COMPLETE', 7800, 8160, 'MOBILE',  'ANDROID', 'CA', NOW() - INTERVAL '2 days' + INTERVAL '130 minutes'),
    ('a6000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'sess-bob-planet-001',        'PLAY',     0,    18000,'BROWSER', 'WEB',     'CA', NOW() - INTERVAL '4 days'),
    ('a6000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'sess-bob-planet-001',        'COMPLETE', 18000,18000,'BROWSER', 'WEB',     'CA', NOW() - INTERVAL '4 days' + INTERVAL '300 minutes'),
    ('a6000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'sess-alice-inception-001',   'PLAY',     0,    8880, 'BROWSER', 'WEB',     'MX', NOW() - INTERVAL '1 day'),
    ('a6000001-0000-0000-0000-000000000010', NULL,                                   'c0000001-0000-0000-0000-000000000001', 'sess-anon-001',              'PLAY',     0,    8880, 'BROWSER', 'WEB',     'US', NOW() - INTERVAL '6 hours');

INSERT INTO daily_aggregates (id, date, content_id, total_views, unique_viewers, total_watch_time_seconds, average_watch_time_seconds, completion_rate) VALUES
    ('a7000001-0000-0000-0000-000000000001', CURRENT_DATE - INTERVAL '1 day',  'c0000001-0000-0000-0000-000000000001', 320,  280,  2841600,  8880.0,  92.5),
    ('a7000001-0000-0000-0000-000000000002', CURRENT_DATE - INTERVAL '1 day',  'c0000001-0000-0000-0000-000000000002', 210,  195,  2129400,  10140.0, 78.3),
    ('a7000001-0000-0000-0000-000000000003', CURRENT_DATE - INTERVAL '1 day',  'c0000001-0000-0000-0000-000000000003', 450,  410,  1566000,  3480.0,  88.1),
    ('a7000001-0000-0000-0000-000000000004', CURRENT_DATE - INTERVAL '1 day',  'c0000001-0000-0000-0000-000000000005', 180,  165,  1468800,  8160.0,  85.0),
    ('a7000001-0000-0000-0000-000000000005', CURRENT_DATE - INTERVAL '2 days', 'c0000001-0000-0000-0000-000000000001', 295,  260,  2619600,  8880.0,  90.1),
    ('a7000001-0000-0000-0000-000000000006', CURRENT_DATE - INTERVAL '2 days', 'c0000001-0000-0000-0000-000000000006', 380,  350,  1064400,  2800.0,  72.5);

INSERT INTO revenue_metrics (id, date, subscription_revenue, ad_revenue, total_revenue, new_subscriptions, cancelled_subscriptions, active_subscriptions) VALUES
    ('a8000001-0000-0000-0000-000000000001', CURRENT_DATE - INTERVAL '1 day',  4520.75,  890.50,  5411.25, 15, 3,  1250),
    ('a8000001-0000-0000-0000-000000000002', CURRENT_DATE - INTERVAL '2 days', 3890.00,  1020.25, 4910.25, 12, 5,  1238),
    ('a8000001-0000-0000-0000-000000000003', CURRENT_DATE - INTERVAL '3 days', 5100.50,  750.00,  5850.50, 22, 2,  1231),
    ('a8000001-0000-0000-0000-000000000004', CURRENT_DATE - INTERVAL '7 days', 4200.00,  980.00,  5180.00, 18, 4,  1215);


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 10: ad_db
--
--  Service     : ad-service
--  Description : Advertising system managing campaigns, individual ads, placement rules,
--                and impression/click tracking for monetization of free-tier users.
--
-- ============================================================================================
-- ============================================================================================

\c ad_db

-- ------------------------------------------------------------
-- Table: campaigns
-- Description: Advertising campaigns with budget, targeting, and scheduling.
--              Supports demographic and category-based targeting.
-- ------------------------------------------------------------
CREATE TABLE campaigns (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255)    NOT NULL,
    advertiser_name     VARCHAR(255),
    budget              DECIMAL(12, 2),
    spent_amount        DECIMAL(12, 2)  DEFAULT 0,
    start_date          TIMESTAMP,
    end_date            TIMESTAMP,
    status              VARCHAR(50)     NOT NULL DEFAULT 'DRAFT',
    target_age_min      INTEGER,
    target_age_max      INTEGER,
    target_categories   VARCHAR(1000),
    target_regions      VARCHAR(500),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: ads
-- Description: Individual ad creatives within a campaign.
--              Each ad has media, click-through URL, and weight for rotation.
-- ------------------------------------------------------------
CREATE TABLE ads (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id         UUID            NOT NULL,
    title               VARCHAR(255)    NOT NULL,
    description         VARCHAR(1000),
    type                VARCHAR(50)     NOT NULL,
    media_url           VARCHAR(500),
    click_through_url   VARCHAR(500),
    duration            INTEGER,
    weight              INTEGER         DEFAULT 1,
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT fk_ads_campaign FOREIGN KEY (campaign_id)
        REFERENCES campaigns (id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Table: ad_placements
-- Description: Rules for where and when ads appear within content.
--              Supports pre-roll, mid-roll, and post-roll positions.
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE ad_placements (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    ad_id                   UUID            NOT NULL,
    content_id              UUID,
    position                VARCHAR(50)     NOT NULL,
    trigger_time_seconds    INTEGER,
    frequency               INTEGER         DEFAULT 1,
    created_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    version                 BIGINT          DEFAULT 0,

    CONSTRAINT fk_placements_ad FOREIGN KEY (ad_id)
        REFERENCES ads (id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Table: impressions
-- Description: Tracks ad views (impressions) and clicks for billing
--              and campaign performance reporting.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE impressions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    ad_id           UUID            NOT NULL,
    campaign_id     UUID            NOT NULL,
    user_id         UUID,
    content_id      UUID,
    type            VARCHAR(50)     NOT NULL,
    user_agent      VARCHAR(500),
    ip_address      VARCHAR(50),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    version         BIGINT          DEFAULT 0,

    CONSTRAINT fk_impressions_ad FOREIGN KEY (ad_id)
        REFERENCES ads (id) ON DELETE CASCADE,
    CONSTRAINT fk_impressions_campaign FOREIGN KEY (campaign_id)
        REFERENCES campaigns (id) ON DELETE CASCADE
);

-- ============================================================
-- Indexes: ad_db
-- ============================================================

-- Campaigns indexes
CREATE INDEX idx_campaigns_status           ON campaigns (status);
CREATE INDEX idx_campaigns_advertiser       ON campaigns (advertiser_name);
CREATE INDEX idx_campaigns_start_date       ON campaigns (start_date);
CREATE INDEX idx_campaigns_end_date         ON campaigns (end_date);
CREATE INDEX idx_campaigns_active_budget    ON campaigns (status, start_date, end_date, spent_amount, budget)
    WHERE status = 'ACTIVE';                                                                -- Partial: budget check for active campaigns

-- Ads indexes
CREATE INDEX idx_ads_campaign_id            ON ads (campaign_id);
CREATE INDEX idx_ads_type                   ON ads (type);
CREATE INDEX idx_ads_active                 ON ads (active) WHERE active = TRUE;             -- Partial: only active ads
CREATE INDEX idx_ads_campaign_active        ON ads (campaign_id, active) WHERE active = TRUE;-- Partial: active ads per campaign

-- Ad placements indexes
CREATE INDEX idx_placements_ad_id           ON ad_placements (ad_id);
CREATE INDEX idx_placements_content_id      ON ad_placements (content_id);
CREATE INDEX idx_placements_position        ON ad_placements (position);
CREATE INDEX idx_placements_content_pos     ON ad_placements (content_id, position);         -- Composite: find placements for content at position

-- Impressions indexes
CREATE INDEX idx_impressions_ad_id          ON impressions (ad_id);
CREATE INDEX idx_impressions_campaign_id    ON impressions (campaign_id);
CREATE INDEX idx_impressions_user_id        ON impressions (user_id);
CREATE INDEX idx_impressions_type           ON impressions (type);
CREATE INDEX idx_impressions_campaign_type  ON impressions (campaign_id, type);              -- Composite: impressions/clicks per campaign
CREATE INDEX idx_impressions_created_at     ON impressions (created_at);

-- ============================================================
-- Seed Data: ad_db
-- ============================================================

INSERT INTO campaigns (id, name, advertiser_name, budget, spent_amount, start_date, end_date, status, target_age_min, target_age_max, target_categories, target_regions) VALUES
    ('ca000001-0000-0000-0000-000000000001', 'Summer Blockbuster Sale',  'MovieMart Inc.',     50000.00, 12500.00, NOW() - INTERVAL '15 days', NOW() + INTERVAL '45 days', 'ACTIVE', 18, 45, 'Action,Sci-Fi,Thriller',    'US,CA,GB'),
    ('ca000001-0000-0000-0000-000000000002', 'New Year Promo 2026',      'StreamGear Co.',     25000.00, 0.00,     NOW() + INTERVAL '30 days', NOW() + INTERVAL '60 days', 'DRAFT',  16, 60, 'ALL',                       'US,CA'),
    ('ca000001-0000-0000-0000-000000000003', 'Documentary Awareness',    'NatureFirst NGO',    10000.00, 3200.00,  NOW() - INTERVAL '30 days', NOW() + INTERVAL '30 days', 'ACTIVE', 25, 55, 'Documentary',               'US,GB,AU');

INSERT INTO ads (id, campaign_id, title, description, type, media_url, click_through_url, duration, weight, active) VALUES
    ('ad000001-0000-0000-0000-000000000001', 'ca000001-0000-0000-0000-000000000001', 'Summer Sale - 30s Pre-roll',  'Get 50% off on Premium subscription this summer!',   'VIDEO_PRE_ROLL',  '/ads/media/summer-sale-30s.mp4',  'https://ottnetwork.com/subscribe?promo=summer',  30, 3, true),
    ('ad000001-0000-0000-0000-000000000002', 'ca000001-0000-0000-0000-000000000001', 'Summer Sale - Banner',        'Upgrade to Premium today!',                           'BANNER',          '/ads/media/summer-sale-banner.jpg','https://ottnetwork.com/subscribe?promo=summer',  NULL, 2, true),
    ('ad000001-0000-0000-0000-000000000003', 'ca000001-0000-0000-0000-000000000003', 'Watch Planet Earth III',       'Stream the award-winning documentary now.',           'VIDEO_PRE_ROLL',  '/ads/media/planet-earth-ad.mp4',  'https://ottnetwork.com/content/planet-earth-iii', 15, 1, true);

INSERT INTO ad_placements (id, ad_id, content_id, position, trigger_time_seconds, frequency) VALUES
    ('ae000001-0000-0000-0000-000000000001', 'ad000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'PRE_ROLL',  0,    1),
    ('ae000001-0000-0000-0000-000000000002', 'ad000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000005', 'PRE_ROLL',  0,    1),
    ('ae000001-0000-0000-0000-000000000003', 'ad000001-0000-0000-0000-000000000002', NULL,                                   'BANNER',    NULL, 3),
    ('ae000001-0000-0000-0000-000000000004', 'ad000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000004', 'PRE_ROLL',  0,    1);

INSERT INTO impressions (id, ad_id, campaign_id, user_id, content_id, type, user_agent, ip_address) VALUES
    ('af000001-0000-0000-0000-000000000001', 'ad000001-0000-0000-0000-000000000001', 'ca000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'VIEW',  'Mozilla/5.0 Chrome/120', '203.0.113.1'),
    ('af000001-0000-0000-0000-000000000002', 'ad000001-0000-0000-0000-000000000001', 'ca000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'CLICK', 'Mozilla/5.0 Chrome/120', '203.0.113.1'),
    ('af000001-0000-0000-0000-000000000003', 'ad000001-0000-0000-0000-000000000002', 'ca000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000004', NULL,                                  'VIEW',  'Android/14 OTTApp/2.0', '198.51.100.5'),
    ('af000001-0000-0000-0000-000000000004', 'ad000001-0000-0000-0000-000000000003', 'ca000001-0000-0000-0000-000000000003', NULL,                                   'c0000001-0000-0000-0000-000000000004', 'VIEW',  'Mozilla/5.0 Safari/17',  '192.0.2.10'),
    ('af000001-0000-0000-0000-000000000005', 'ad000001-0000-0000-0000-000000000003', 'ca000001-0000-0000-0000-000000000003', NULL,                                   'c0000001-0000-0000-0000-000000000004', 'CLICK', 'Mozilla/5.0 Safari/17',  '192.0.2.10');


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 11: live_db
--
--  Service     : live-streaming-service
--  Description : Real-time live streaming infrastructure including stream management,
--                RTMP ingest keys, HLS playback, viewer counts, and live chat messaging.
--
-- ============================================================================================
-- ============================================================================================

\c live_db

-- ------------------------------------------------------------
-- Table: live_streams
-- Description: Live stream sessions with scheduling, status tracking,
--              viewer counts, and optional recording.
-- Cross-ref  : streamer_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE live_streams (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    streamer_id         UUID            NOT NULL,
    title               VARCHAR(255)    NOT NULL,
    description         VARCHAR(1000),
    status              VARCHAR(20)     NOT NULL DEFAULT 'SCHEDULED',
    stream_key          VARCHAR(255)    NOT NULL,
    rtmp_ingest_url     VARCHAR(500),
    hls_playback_url    VARCHAR(500),
    thumbnail_url       VARCHAR(500),
    category            VARCHAR(100),
    viewer_count        INTEGER         NOT NULL DEFAULT 0,
    peak_viewer_count   INTEGER         NOT NULL DEFAULT 0,
    scheduled_at        TIMESTAMP,
    started_at          TIMESTAMP,
    ended_at            TIMESTAMP,
    chat_enabled        BOOLEAN         NOT NULL DEFAULT TRUE,
    recording_enabled   BOOLEAN         NOT NULL DEFAULT TRUE,
    recording_url       VARCHAR(500),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_live_streams_stream_key UNIQUE (stream_key),
    CONSTRAINT chk_live_stream_status
        CHECK (status IN ('SCHEDULED', 'LIVE', 'ENDED', 'CANCELLED'))
);

-- ------------------------------------------------------------
-- Table: stream_keys
-- Description: Persistent RTMP stream keys assigned to users.
--              Users can have multiple keys with labels (Primary, Backup, etc.).
-- Cross-ref  : user_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE stream_keys (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    stream_key          VARCHAR(255)    NOT NULL,
    label               VARCHAR(100)    DEFAULT 'Primary',
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    last_used_at        TIMESTAMP,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_stream_keys_stream_key UNIQUE (stream_key)
);

-- ------------------------------------------------------------
-- Table: chat_messages
-- Description: Real-time chat messages within a live stream.
--              Supports text, system messages, and donation notifications.
-- Cross-ref  : stream_id references live_streams.id (same database)
-- Cross-ref  : user_id references user_db.users.id
-- ------------------------------------------------------------
CREATE TABLE chat_messages (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_id           UUID            NOT NULL,
    user_id             UUID            NOT NULL,
    message             VARCHAR(500)    NOT NULL,
    type                VARCHAR(20)     NOT NULL DEFAULT 'TEXT',
    deleted             BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT chk_chat_message_type
        CHECK (type IN ('TEXT', 'SYSTEM', 'DONATION'))
);

-- ============================================================
-- Indexes: live_db
-- ============================================================

-- Live streams indexes
CREATE INDEX idx_live_streams_streamer_id       ON live_streams (streamer_id);
CREATE INDEX idx_live_streams_status            ON live_streams (status);
CREATE INDEX idx_live_streams_stream_key        ON live_streams (stream_key);
CREATE INDEX idx_live_streams_category          ON live_streams (category);
CREATE INDEX idx_live_streams_scheduled_at      ON live_streams (scheduled_at);
CREATE INDEX idx_live_streams_status_scheduled  ON live_streams (status, scheduled_at)
    WHERE status = 'SCHEDULED';                                                             -- Partial: upcoming scheduled streams
CREATE INDEX idx_live_streams_created_at        ON live_streams (created_at DESC);

-- Stream keys indexes
CREATE INDEX idx_stream_keys_user_id            ON stream_keys (user_id);
CREATE INDEX idx_stream_keys_stream_key         ON stream_keys (stream_key);
CREATE INDEX idx_stream_keys_active             ON stream_keys (active) WHERE active = TRUE;-- Partial: only active keys

-- Chat messages indexes
CREATE INDEX idx_chat_messages_stream_id        ON chat_messages (stream_id);
CREATE INDEX idx_chat_messages_user_id          ON chat_messages (user_id);
CREATE INDEX idx_chat_messages_stream_deleted   ON chat_messages (stream_id, deleted)
    WHERE deleted = FALSE;                                                                  -- Partial: non-deleted messages per stream
CREATE INDEX idx_chat_messages_created_at       ON chat_messages (created_at DESC);

-- ============================================================
-- Seed Data: live_db
-- ============================================================

INSERT INTO live_streams (id, streamer_id, title, description, status, stream_key, rtmp_ingest_url, hls_playback_url, thumbnail_url, category, viewer_count, peak_viewer_count, scheduled_at, started_at, ended_at, chat_enabled, recording_enabled) VALUES
    ('11000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002', 'Behind the Scenes: Film Making 101', 'Live session on how modern movies are made.',  'ENDED',     'sk-live-john-001-abc123',    'rtmp://live.ottnetwork.com/ingest/sk-live-john-001-abc123',    '/hls/live/john-001/master.m3u8',   '/thumbs/live/filmmaking.jpg',   'Education',     0,    1250, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '2 hours', true, true),
    ('11000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', 'Movie Premiere Watch Party',         'Watch the premiere of Inception together!',    'SCHEDULED', 'sk-live-john-002-def456',    'rtmp://live.ottnetwork.com/ingest/sk-live-john-002-def456',    NULL,                               '/thumbs/live/watchparty.jpg',   'Entertainment', 0,    0,    NOW() + INTERVAL '3 days', NULL,                       NULL, true, true),
    ('11000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', 'Platform Q&A with Admin',            'Ask anything about the OTT Network platform.', 'LIVE',      'sk-live-admin-001-ghi789',   'rtmp://live.ottnetwork.com/ingest/sk-live-admin-001-ghi789',   '/hls/live/admin-001/master.m3u8',  '/thumbs/live/qa-session.jpg',   'Tech',          45,   78,   NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes', NULL, true, false);

INSERT INTO stream_keys (id, user_id, stream_key, label, active, last_used_at) VALUES
    ('12000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002', 'sk-persistent-john-primary-xyz789',  'Primary',  true,  NOW() - INTERVAL '3 days'),
    ('12000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', 'sk-persistent-john-backup-abc123',   'Backup',   true,  NULL),
    ('12000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', 'sk-persistent-admin-primary-def456', 'Primary',  true,  NOW() - INTERVAL '30 minutes');

INSERT INTO chat_messages (id, stream_id, user_id, message, type, deleted) VALUES
    ('13000001-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'Great content! Love this stream.',               'TEXT',   false),
    ('13000001-0000-0000-0000-000000000002', '11000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000004', 'Can you explain more about camera angles?',      'TEXT',   false),
    ('13000001-0000-0000-0000-000000000003', '11000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002', 'Sure! Let me demonstrate with some examples.',   'TEXT',   false),
    ('13000001-0000-0000-0000-000000000004', '11000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000005', 'This is spam content!',                           'TEXT',   true),
    ('13000001-0000-0000-0000-000000000005', '11000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 'How do I upgrade my subscription?',               'TEXT',   false),
    ('13000001-0000-0000-0000-000000000006', '11000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', 'Go to Settings > Subscription > Upgrade.',        'TEXT',   false);


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 12: social_db
--
--  Service     : social-service
--  Description : User-generated content including threaded comments, star ratings,
--                and detailed reviews with helpfulness voting.
--
-- ============================================================================================
-- ============================================================================================

\c social_db

-- ------------------------------------------------------------
-- Table: comments
-- Description: Threaded comment system with self-referencing parent for replies.
--              Supports soft-deletion via status field.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE comments (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    text                VARCHAR(1000)   NOT NULL,
    parent_comment_id   UUID,
    status              VARCHAR(50)     NOT NULL DEFAULT 'ACTIVE',
    likes_count         INTEGER         NOT NULL DEFAULT 0,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT fk_comment_parent FOREIGN KEY (parent_comment_id)
        REFERENCES comments (id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- Table: ratings
-- Description: Simple 1-5 star ratings. Each user can rate a content
--              item exactly once.
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE ratings (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    rating              INTEGER         NOT NULL CHECK (rating >= 1 AND rating <= 5),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_rating_user_content UNIQUE (user_id, content_id)
);

-- ------------------------------------------------------------
-- Table: reviews
-- Description: Detailed user reviews with title, body, rating, and
--              helpfulness voting (helpful / not_helpful counters).
-- Cross-ref  : user_id references user_db.users.id
-- Cross-ref  : content_id references content_db.contents.id
-- ------------------------------------------------------------
CREATE TABLE reviews (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    content_id          UUID            NOT NULL,
    title               VARCHAR(200),
    body                VARCHAR(2000)   NOT NULL,
    rating              INTEGER         CHECK (rating >= 1 AND rating <= 5),
    helpful             INTEGER         NOT NULL DEFAULT 0,
    not_helpful         INTEGER         NOT NULL DEFAULT 0,
    status              VARCHAR(50)     NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT uk_review_user_content UNIQUE (user_id, content_id)
);

-- ============================================================
-- Indexes: social_db
-- ============================================================

-- Comments indexes
CREATE INDEX idx_comments_content_id         ON comments (content_id);
CREATE INDEX idx_comments_user_id            ON comments (user_id);
CREATE INDEX idx_comments_parent_id          ON comments (parent_comment_id);
CREATE INDEX idx_comments_status             ON comments (status);
CREATE INDEX idx_comments_content_status     ON comments (content_id, status, created_at DESC);  -- Composite: active comments for content, newest first

-- Ratings indexes
CREATE INDEX idx_ratings_content_id          ON ratings (content_id);
CREATE INDEX idx_ratings_user_id             ON ratings (user_id);
CREATE INDEX idx_ratings_content_rating      ON ratings (content_id, rating);                    -- Composite: rating distribution per content

-- Reviews indexes
CREATE INDEX idx_reviews_content_id          ON reviews (content_id);
CREATE INDEX idx_reviews_user_id             ON reviews (user_id);
CREATE INDEX idx_reviews_status              ON reviews (status);
CREATE INDEX idx_reviews_content_status      ON reviews (content_id, status, created_at DESC);   -- Composite: active reviews for content, newest first
CREATE INDEX idx_reviews_content_helpful     ON reviews (content_id, helpful DESC);              -- Composite: most helpful reviews per content

-- ============================================================
-- Seed Data: social_db
-- ============================================================

INSERT INTO comments (id, user_id, content_id, text, parent_comment_id, status, likes_count) VALUES
    ('14000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'Inception is an absolute masterpiece! The layers of dreams within dreams is mind-blowing.',                           NULL,                                  'ACTIVE', 45),
    ('14000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000001', 'I agree! Christopher Nolan is a genius. The ending still makes me think.',                                            '14000001-0000-0000-0000-000000000001', 'ACTIVE', 12),
    ('14000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 'I found it confusing at first, but the second watch made everything click.',                                           '14000001-0000-0000-0000-000000000001', 'ACTIVE', 8),
    ('14000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 'Breaking Bad has the best character development I have ever seen in a TV series.',                                     NULL,                                  'ACTIVE', 67),
    ('14000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'The Matrix was way ahead of its time. The visual effects still hold up.',                                               NULL,                                  'ACTIVE', 33),
    ('14000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000006', 'Stranger Things season 1 is pure nostalgia!',                                                                          NULL,                                  'ACTIVE', 21);

INSERT INTO ratings (id, user_id, content_id, rating) VALUES
    ('15000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 5),
    ('15000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000001', 4),
    ('15000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000001', 5),
    ('15000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 5),
    ('15000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 5),
    ('15000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 4),
    ('15000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000006', 4),
    ('15000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 5);

INSERT INTO reviews (id, user_id, content_id, title, body, rating, helpful, not_helpful, status) VALUES
    ('16000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'A cinematic revolution',    'Inception redefined what is possible in filmmaking. The practical effects, the rotating hallway fight, the emotional core of Cobb''s journey - everything works perfectly. A must-watch for any film lover.',                                              5, 89, 3, 'ACTIVE'),
    ('16000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000005', 'Red pill or blue pill?',     'The Matrix is a genre-defining film. The action sequences were revolutionary, and the philosophical questions it raises about reality are still relevant today. Keanu Reeves was born for this role.',                                                        4, 56, 5, 'ACTIVE'),
    ('16000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 'The greatest TV show ever',  'Breaking Bad is not just great television - it is a masterclass in storytelling. Every episode builds on the last. Bryan Cranston delivers the performance of a lifetime. The writing is flawless.',                                                         5, 124, 2, 'ACTIVE'),
    ('16000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'Breathtaking visuals',       'Planet Earth III continues the tradition of stunning nature photography. The dedication of the crew to capture these moments is incredible. The narration is informative without being overbearing.',                                                        5, 45, 1, 'ACTIVE');


-- ============================================================================================
-- ============================================================================================
--
--  DATABASE 13: tenant_db
--
--  Service     : multi-tenant-service
--  Description : Multi-tenancy support allowing white-label deployments. Manages
--                tenant registration, per-tenant configuration, and branding customization.
--
-- ============================================================================================
-- ============================================================================================

\c tenant_db

-- ------------------------------------------------------------
-- Table: tenants
-- Description: Registered tenants (organizations) with plan and status.
--              Each tenant gets an isolated white-label experience.
-- ------------------------------------------------------------
CREATE TABLE tenants (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255)    NOT NULL UNIQUE,
    slug                VARCHAR(255)    NOT NULL UNIQUE,
    domain              VARCHAR(255)    UNIQUE,
    status              VARCHAR(50)     NOT NULL DEFAULT 'TRIAL',
    owner_email         VARCHAR(255)    NOT NULL,
    owner_name          VARCHAR(255),
    plan                VARCHAR(50)     NOT NULL DEFAULT 'BASIC',
    max_users           INTEGER         DEFAULT 100,
    trial_ends_at       TIMESTAMP,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0
);

-- ------------------------------------------------------------
-- Table: tenant_configs
-- Description: Key-value configuration store per tenant. Organized
--              by category for feature flags, limits, and settings.
-- ------------------------------------------------------------
CREATE TABLE tenant_configs (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID            NOT NULL,
    config_key          VARCHAR(255)    NOT NULL,
    config_value        VARCHAR(2000),
    category            VARCHAR(50),
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    version             BIGINT          DEFAULT 0,

    CONSTRAINT fk_tenant_config_tenant FOREIGN KEY (tenant_id)
        REFERENCES tenants (id) ON DELETE CASCADE,
    CONSTRAINT uk_tenant_config_key UNIQUE (tenant_id, config_key)
);

-- ------------------------------------------------------------
-- Table: branding
-- Description: Visual branding customization per tenant including
--              logos, colors, custom CSS, and login page assets.
-- ------------------------------------------------------------
CREATE TABLE branding (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID            NOT NULL UNIQUE,
    logo_url                VARCHAR(500),
    favicon_url             VARCHAR(500),
    primary_color           VARCHAR(20)     DEFAULT '#1a73e8',
    secondary_color         VARCHAR(20)     DEFAULT '#ffffff',
    accent_color            VARCHAR(20),
    app_name                VARCHAR(255),
    tagline                 VARCHAR(500),
    custom_css              TEXT,
    login_background_url    VARCHAR(500),
    created_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
    version                 BIGINT          DEFAULT 0,

    CONSTRAINT fk_branding_tenant FOREIGN KEY (tenant_id)
        REFERENCES tenants (id) ON DELETE CASCADE
);

-- ============================================================
-- Indexes: tenant_db
-- ============================================================

-- Tenants indexes
CREATE INDEX idx_tenants_slug            ON tenants (slug);
CREATE INDEX idx_tenants_domain          ON tenants (domain);
CREATE INDEX idx_tenants_status          ON tenants (status);
CREATE INDEX idx_tenants_plan            ON tenants (plan);
CREATE INDEX idx_tenants_owner_email     ON tenants (owner_email);
CREATE INDEX idx_tenants_created_at      ON tenants (created_at DESC);

-- Tenant configs indexes
CREATE INDEX idx_tenant_configs_tenant   ON tenant_configs (tenant_id);
CREATE INDEX idx_tenant_configs_category ON tenant_configs (tenant_id, category);            -- Composite: configs by tenant + category
CREATE INDEX idx_tenant_configs_key      ON tenant_configs (config_key);

-- Branding indexes
CREATE INDEX idx_branding_tenant         ON branding (tenant_id);

-- ============================================================
-- Seed Data: tenant_db
-- ============================================================

INSERT INTO tenants (id, name, slug, domain, status, owner_email, owner_name, plan, max_users, trial_ends_at) VALUES
    ('10000001-0000-0000-0000-000000000001', 'OTT Network',   'ott-network',   'ottnetwork.com',        'ACTIVE', 'admin@ottnetwork.com',    'System Admin',     'ENTERPRISE', 10000, NULL),
    ('10000001-0000-0000-0000-000000000002', 'StreamFlix',    'streamflix',     'streamflix.example.com', 'ACTIVE', 'owner@streamflix.com',    'Alex StreamFlix',  'PREMIUM',    5000,  NULL),
    ('10000001-0000-0000-0000-000000000003', 'EduStream',     'edustream',      'edustream.example.com', 'TRIAL',  'owner@edustream.com',    'Maria EduStream',  'BASIC',      100,   NOW() + INTERVAL '14 days');

INSERT INTO tenant_configs (id, tenant_id, config_key, config_value, category) VALUES
    ('17000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000001', 'max_concurrent_streams',   '5',     'LIMITS'),
    ('17000001-0000-0000-0000-000000000002', '10000001-0000-0000-0000-000000000001', 'enable_live_streaming',    'true',  'FEATURES'),
    ('17000001-0000-0000-0000-000000000003', '10000001-0000-0000-0000-000000000001', 'enable_ads',               'true',  'FEATURES'),
    ('17000001-0000-0000-0000-000000000004', '10000001-0000-0000-0000-000000000001', 'default_video_quality',    '1080p', 'SETTINGS'),
    ('17000001-0000-0000-0000-000000000005', '10000001-0000-0000-0000-000000000002', 'max_concurrent_streams',   '3',     'LIMITS'),
    ('17000001-0000-0000-0000-000000000006', '10000001-0000-0000-0000-000000000002', 'enable_live_streaming',    'true',  'FEATURES'),
    ('17000001-0000-0000-0000-000000000007', '10000001-0000-0000-0000-000000000002', 'enable_ads',               'false', 'FEATURES'),
    ('17000001-0000-0000-0000-000000000008', '10000001-0000-0000-0000-000000000003', 'max_concurrent_streams',   '1',     'LIMITS'),
    ('17000001-0000-0000-0000-000000000009', '10000001-0000-0000-0000-000000000003', 'enable_live_streaming',    'false', 'FEATURES'),
    ('17000001-0000-0000-0000-000000000010', '10000001-0000-0000-0000-000000000003', 'enable_ads',               'true',  'FEATURES');

INSERT INTO branding (id, tenant_id, logo_url, favicon_url, primary_color, secondary_color, accent_color, app_name, tagline, custom_css, login_background_url) VALUES
    ('18000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000001', '/branding/ott-network/logo.svg',  '/branding/ott-network/favicon.ico',  '#1a73e8', '#ffffff', '#ff6b35', 'OTT Network',  'Stream Without Limits',           NULL,                                     '/branding/ott-network/login-bg.jpg'),
    ('18000001-0000-0000-0000-000000000002', '10000001-0000-0000-0000-000000000002', '/branding/streamflix/logo.svg',   '/branding/streamflix/favicon.ico',   '#e50914', '#141414', '#b81d24', 'StreamFlix',   'Entertainment at Your Fingertips', '.navbar { background: #141414; }',       '/branding/streamflix/login-bg.jpg'),
    ('18000001-0000-0000-0000-000000000003', '10000001-0000-0000-0000-000000000003', '/branding/edustream/logo.svg',   '/branding/edustream/favicon.ico',   '#4caf50', '#ffffff', '#2e7d32', 'EduStream',    'Learn Through Video',              '.navbar { background: #4caf50; }',       '/branding/edustream/login-bg.jpg');


-- ============================================================================================
--
--  END OF SCHEMA
--
--  Summary:
--    Databases created  : 13
--    Total tables       : 46
--    Total indexes      : 120+
--    Seed data          : Sample data in all 46 tables across 13 databases
--                         5 users, 6 content items, 7 plans, 3 tenants, etc.
--    Default password   : password123 (BCrypt hashed)
--
--  Cross-Service Reference Map:
--    auth_db.user_credentials.id  -->  user_db.users.auth_user_id
--    user_db.users.id             -->  subscription_db.subscriptions.user_id
--    user_db.users.id             -->  watchlist_db.watchlist_items.user_id
--    user_db.users.id             -->  recommendation_db.user_interactions.user_id
--    user_db.users.id             -->  notification_db.notifications.user_id
--    user_db.users.id             -->  analytics_db.view_events.user_id
--    user_db.users.id             -->  ad_db.impressions.user_id
--    user_db.users.id             -->  live_db.live_streams.streamer_id
--    user_db.users.id             -->  social_db.comments.user_id
--    content_db.contents.id       -->  video_db.transcode_jobs.content_id
--    content_db.contents.id       -->  video_db.video_assets.content_id
--    content_db.contents.id       -->  watchlist_db.watchlist_items.content_id
--    content_db.contents.id       -->  recommendation_db.user_interactions.content_id
--    content_db.contents.id       -->  recommendation_db.content_similarities.content_id_1/2
--    content_db.contents.id       -->  analytics_db.view_events.content_id
--    content_db.contents.id       -->  analytics_db.daily_aggregates.content_id
--    content_db.contents.id       -->  ad_db.ad_placements.content_id
--    content_db.contents.id       -->  social_db.comments.content_id
--    content_db.contents.id       -->  social_db.ratings.content_id
--    content_db.contents.id       -->  social_db.reviews.content_id
--
-- ============================================================================================
