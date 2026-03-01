-- Make password_hash nullable for OTP-based registration (no password required)
ALTER TABLE user_credentials ALTER COLUMN password_hash DROP NOT NULL;
