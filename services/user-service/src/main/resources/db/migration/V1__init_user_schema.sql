-- ============================================================
-- user_db schema — managed by Flyway
-- ============================================================

CREATE TABLE users (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id      UUID            NOT NULL UNIQUE,
    email             VARCHAR(255)    NOT NULL UNIQUE,
    username          VARCHAR(100)    NOT NULL UNIQUE,
    first_name        VARCHAR(100),
    last_name         VARCHAR(100),
    display_name      VARCHAR(100),
    avatar_url        VARCHAR(512),
    phone             VARCHAR(20),
    date_of_birth     DATE,
    role              VARCHAR(50),
    subscription_tier VARCHAR(50)     NOT NULL DEFAULT 'FREE',
    active            BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP       NOT NULL DEFAULT NOW(),
    version           BIGINT          NOT NULL DEFAULT 0
);

CREATE INDEX idx_users_auth_user_id ON users (auth_user_id);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);
CREATE INDEX idx_users_active ON users (active);

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
