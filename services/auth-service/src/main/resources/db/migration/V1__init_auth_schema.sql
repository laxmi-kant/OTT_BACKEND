-- auth_db schema - matches ott_network_complete_schema.sql

CREATE TABLE user_credentials (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255)    NOT NULL,
    username        VARCHAR(50)     NOT NULL,
    password_hash   VARCHAR(255),
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

-- Indexes
CREATE INDEX idx_user_credentials_email    ON user_credentials (email);
CREATE INDEX idx_user_credentials_username ON user_credentials (username);
CREATE INDEX idx_refresh_tokens_token      ON refresh_tokens (token);
CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens (user_id);
CREATE INDEX idx_oauth_providers_user_id                   ON oauth_providers (user_id);
CREATE INDEX idx_oauth_providers_provider_provider_user_id ON oauth_providers (provider, provider_user_id);
