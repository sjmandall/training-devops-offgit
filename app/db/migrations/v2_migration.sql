-- Day 25 v2.0.0 Migration Script
-- Adds created_at column and email index to trainingdb

-- Add created_at column to track when records were created
ALTER TABLE users ADD COLUMN IF NOT EXISTS
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email
  ON users(email);

-- Add a version tracking table
CREATE TABLE IF NOT EXISTS schema_version (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  version    VARCHAR(20) NOT NULL,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  description VARCHAR(255)
);

-- Record this migration
INSERT INTO schema_version (version, description)
VALUES ('2.0.0', 'Added created_at column and email index to users table');
