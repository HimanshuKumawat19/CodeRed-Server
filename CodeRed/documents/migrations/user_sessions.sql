-- =====================================================
-- create_user_sessions.sql
-- Tracks active and historical user sessions in CodeForge
-- Dependencies: users
-- =====================================================

CREATE TABLE user_sessions (
    -- Primary Key
    session_id SERIAL PRIMARY KEY,
    
    -- User Association
    user_id INTEGER NOT NULL, -- FK to users
    
    -- Session Details
    session_token TEXT NOT NULL UNIQUE, -- Secure token for authentication
    ip_address VARCHAR(45) NOT NULL, -- IPv4 or IPv6
    user_agent TEXT, -- Browser / device agent string
    device_type VARCHAR(50), -- e.g., desktop, mobile, tablet
    
    -- Session Timings
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP DEFAULT NULL,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Status & Expiry
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP NOT NULL,
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Foreign Key Constraints
ALTER TABLE user_sessions
ADD CONSTRAINT fk_user_sessions_user
FOREIGN KEY (user_id) REFERENCES users(user_id)
ON DELETE CASCADE ON UPDATE CASCADE;

-- Indexes
CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_expiry ON user_sessions(expires_at);
CREATE INDEX idx_user_sessions_last_activity ON user_sessions(last_activity DESC);

-- Function to auto-update last_activity
CREATE OR REPLACE FUNCTION update_last_activity()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_activity = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating last_activity on any row update
CREATE TRIGGER trigger_update_last_activity
BEFORE UPDATE ON user_sessions
FOR EACH ROW
EXECUTE FUNCTION update_last_activity();

COMMENT ON TABLE user_sessions IS 'Tracks each login session for users, including token, device, and timing data';
