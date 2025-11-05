/* This is the user table */
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Profile Information
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    profile_picture VARCHAR(255) DEFAULT NULL,
    country VARCHAR(100) DEFAULT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Rating & Ranking System
    current_rating INTEGER DEFAULT 1000,
    peak_rating INTEGER DEFAULT 1000,
    current_rank VARCHAR(20) DEFAULT 'Bronze',  -- Simple string for now
    
    -- Match Performance Statistics
    total_matches INTEGER DEFAULT 0,
    matches_won INTEGER DEFAULT 0,
    win_rate DECIMAL(5,2) DEFAULT 0.00,
    problems_solved INTEGER DEFAULT 0,
    
    -- User Preferences
    preferred_language VARCHAR(20) DEFAULT 'python',  -- Simple string for now
    
    -- Account Status & Security
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    auth_provider VARCHAR(20) DEFAULT 'local', -- 'local', 'google'
    google_id VARCHAR(100) UNIQUE DEFAULT NULL, -- For Google OAuth
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP DEFAULT NULL
);

-- Basic indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_current_rating ON users(current_rating DESC);
CREATE INDEX idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;
CREATE INDEX idx_users_auth_provider ON users(auth_provider);