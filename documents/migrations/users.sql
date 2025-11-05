-- =====================================================
-- 004_create_users.sql
-- Core User Management Structure for CodeForge
-- Dependencies: user_ranks, languages
-- =====================================================

-- Create users table
CREATE TABLE users (
    -- Primary Key
    user_id SERIAL PRIMARY KEY,
    
    -- Authentication & Identity
    
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
    current_rating INTEGER DEFAULT 1000,                   -- Starting ELO rating
    peak_rating INTEGER DEFAULT 1000,                      -- Highest rating ever achieved
    current_rank_id INTEGER NOT NULL DEFAULT 6,            -- FK to user_ranks (starts at Sixth)
    
    -- Match Performance Statistics
    total_matches INTEGER DEFAULT 0,
    matches_won INTEGER DEFAULT 0,
    win_rate DECIMAL(5,2) DEFAULT 0.00,                   -- Percentage (0.00 to 100.00)
    problems_solved INTEGER DEFAULT 0,
    
    -- User Preferences
    preferred_language_id INTEGER DEFAULT NULL,            -- FK to languages
    
    -- Account Status & Security
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP DEFAULT NULL,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_users_current_rank 
        FOREIGN KEY (current_rank_id) 
        REFERENCES user_ranks(rank_id)
        ON DELETE SET DEFAULT                              -- If rank deleted, set to default (6)
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_users_preferred_language 
        FOREIGN KEY (preferred_language_id) 
        REFERENCES languages(language_id)
        ON DELETE SET NULL                                 -- If language deleted, set to NULL
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_users_rating_positive 
        CHECK (current_rating >= 0 AND current_rating <= 5000),
    CONSTRAINT chk_users_peak_rating_valid 
        CHECK (peak_rating >= current_rating),
    CONSTRAINT chk_users_win_rate_valid 
        CHECK (win_rate >= 0 AND win_rate <= 100),
    CONSTRAINT chk_users_matches_valid 
        CHECK (total_matches >= 0 AND matches_won >= 0 AND matches_won <= total_matches),
    CONSTRAINT chk_users_problems_solved_positive 
        CHECK (problems_solved >= 0),
    CONSTRAINT chk_users_email_format 
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_username_format 
        CHECK (username ~ '^[a-zA-Z0-9_]{3,50}$'),        -- Alphanumeric + underscore, 3-50 chars
    CONSTRAINT chk_users_timezone_format 
        CHECK (LENGTH(TRIM(timezone)) > 0)
);

-- Create indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_current_rating ON users(current_rating DESC);
CREATE INDEX idx_users_current_rank ON users(current_rank_id);
CREATE INDEX idx_users_peak_rating ON users(peak_rating DESC);
CREATE INDEX idx_users_matches_won ON users(matches_won DESC);
CREATE INDEX idx_users_problems_solved ON users(problems_solved DESC);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_last_login ON users(last_login DESC) WHERE last_login IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_users_active_verified ON users(is_active, is_verified) 
WHERE is_active = TRUE;
CREATE INDEX idx_users_rating_rank ON users(current_rating DESC, current_rank_id);
CREATE INDEX idx_users_country_active ON users(country, is_active) 
WHERE is_active = TRUE AND country IS NOT NULL;

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_updated_at();

-- Function to auto-update peak rating when current rating changes
CREATE OR REPLACE FUNCTION update_users_peak_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- If current rating increased and is now higher than peak rating
    IF NEW.current_rating > OLD.peak_rating THEN
        NEW.peak_rating = NEW.current_rating;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update peak rating
CREATE TRIGGER trigger_users_peak_rating
    BEFORE UPDATE OF current_rating ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_peak_rating();

-- Function to auto-calculate win rate when match stats change
CREATE OR REPLACE FUNCTION update_users_win_rate()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate win rate percentage
    IF NEW.total_matches > 0 THEN
        NEW.win_rate = ROUND((NEW.matches_won::DECIMAL / NEW.total_matches::DECIMAL) * 100, 2);
    ELSE
        NEW.win_rate = 0.00;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate win rate
CREATE TRIGGER trigger_users_win_rate
    BEFORE UPDATE OF total_matches, matches_won ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_win_rate();

-- Add documentation comments
COMMENT ON TABLE users IS 'Core user accounts and profiles for CodeForge competitive programming platform';
COMMENT ON COLUMN users.current_rating IS 'Current ELO-style rating (starts at 1000, max ~5000)';
COMMENT ON COLUMN users.peak_rating IS 'Highest rating ever achieved (automatically updated)';
COMMENT ON COLUMN users.current_rank_id IS 'Current rank based on rating (FK to user_ranks, auto-updated)';
COMMENT ON COLUMN users.win_rate IS 'Percentage of matches won (automatically calculated)';
COMMENT ON COLUMN users.preferred_language_id IS 'Default programming language for contests (FK to languages)';
COMMENT ON COLUMN users.is_verified IS 'Email verification status for security';
COMMENT ON COLUMN users.timezone IS 'User timezone for match scheduling (default: UTC)';
COMMENT ON COLUMN users.profile_picture IS 'URL/path to user profile image';
COMMENT ON COLUMN users.last_login IS 'Timestamp of most recent login for analytics';