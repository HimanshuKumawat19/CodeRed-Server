-- =====================================================
-- 005_create_problems.sql
-- Coding Problems Structure for CodeForge
-- Dependencies: topics, users
-- =====================================================

-- Create problems table
CREATE TABLE problems (
    -- Primary Key
    problem_id SERIAL PRIMARY KEY,
    
    -- Problem Identification
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    
    -- Problem Classification
    difficulty_level VARCHAR(20) NOT NULL,                -- 'Easy', 'Medium', 'Hard', 'Expert'
    topic_id INTEGER NOT NULL,                            -- FK to topics
    
    -- Execution Constraints
    time_limit INTEGER NOT NULL DEFAULT 1000,            -- Time limit in milliseconds
    memory_limit INTEGER NOT NULL DEFAULT 256,           -- Memory limit in MB
    
    -- Scoring & Statistics
    points INTEGER NOT NULL DEFAULT 100,                 -- Points awarded for solving
    acceptance_rate DECIMAL(5,2) DEFAULT 0.00,          -- Success rate percentage
    total_submissions INTEGER DEFAULT 0,                 -- Total submission attempts
    successful_submissions INTEGER DEFAULT 0,            -- Successful solutions
    
    -- Problem Management
    created_by INTEGER NOT NULL,                         -- FK to users (problem setter)
    is_active BOOLEAN DEFAULT TRUE,                      -- Available for contests?
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_problems_topic 
        FOREIGN KEY (topic_id) 
        REFERENCES topics(topic_id)
        ON DELETE RESTRICT                               -- Cannot delete topic if problems exist
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_problems_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES users(user_id)
        ON DELETE RESTRICT                               -- Cannot delete user who created problems
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_problems_difficulty_valid 
        CHECK (difficulty_level IN ('Easy', 'Medium', 'Hard', 'Expert')),
    CONSTRAINT chk_problems_time_limit_positive 
        CHECK (time_limit > 0 AND time_limit <= 10000),  -- Max 10 seconds
    CONSTRAINT chk_problems_memory_limit_positive 
        CHECK (memory_limit > 0 AND memory_limit <= 1024), -- Max 1GB
    CONSTRAINT chk_problems_points_positive 
        CHECK (points > 0 AND points <= 1000),           -- Max 1000 points
    CONSTRAINT chk_problems_acceptance_rate_valid 
        CHECK (acceptance_rate >= 0 AND acceptance_rate <= 100),
    CONSTRAINT chk_problems_submissions_valid 
        CHECK (total_submissions >= 0 AND successful_submissions >= 0 
               AND successful_submissions <= total_submissions),
    CONSTRAINT chk_problems_title_not_empty 
        CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT chk_problems_description_not_empty 
        CHECK (LENGTH(TRIM(description)) > 10)           -- Minimum description length
);

-- Create indexes for performance
CREATE INDEX idx_problems_title ON problems(title);
CREATE INDEX idx_problems_difficulty ON problems(difficulty_level);
CREATE INDEX idx_problems_topic ON problems(topic_id);
CREATE INDEX idx_problems_created_by ON problems(created_by);
CREATE INDEX idx_problems_points ON problems(points DESC);
CREATE INDEX idx_problems_acceptance_rate ON problems(acceptance_rate DESC);
CREATE INDEX idx_problems_total_submissions ON problems(total_submissions DESC);
CREATE INDEX idx_problems_created_at ON problems(created_at DESC);

-- Composite indexes for common queries
CREATE INDEX idx_problems_active_difficulty ON problems(is_active, difficulty_level) 
WHERE is_active = TRUE;
CREATE INDEX idx_problems_topic_active ON problems(topic_id, is_active) 
WHERE is_active = TRUE;
CREATE INDEX idx_problems_difficulty_points ON problems(difficulty_level, points DESC) 
WHERE is_active = TRUE;
CREATE INDEX idx_problems_acceptance_difficulty ON problems(acceptance_rate DESC, difficulty_level) 
WHERE is_active = TRUE;

-- Full-text search index for problem titles and descriptions
CREATE INDEX idx_problems_title_search ON problems USING gin(to_tsvector('english', title));
CREATE INDEX idx_problems_description_search ON problems USING gin(to_tsvector('english', description));

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_problems_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_problems_updated_at
    BEFORE UPDATE ON problems
    FOR EACH ROW
    EXECUTE FUNCTION update_problems_updated_at();

-- Function to auto-calculate acceptance rate when submission stats change
CREATE OR REPLACE FUNCTION update_problems_acceptance_rate()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate acceptance rate percentage
    IF NEW.total_submissions > 0 THEN
        NEW.acceptance_rate = ROUND((NEW.successful_submissions::DECIMAL / NEW.total_submissions::DECIMAL) * 100, 2);
    ELSE
        NEW.acceptance_rate = 0.00;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate acceptance rate
CREATE TRIGGER trigger_problems_acceptance_rate
    BEFORE UPDATE OF total_submissions, successful_submissions ON problems
    FOR EACH ROW
    EXECUTE FUNCTION update_problems_acceptance_rate();

-- Function to validate difficulty vs points consistency
CREATE OR REPLACE FUNCTION validate_problems_difficulty_points()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate points are reasonable for difficulty level
    CASE NEW.difficulty_level
        WHEN 'Easy' THEN
            IF NEW.points NOT BETWEEN 50 AND 200 THEN
                RAISE EXCEPTION 'Easy problems should have 50-200 points, got %', NEW.points;
            END IF;
        WHEN 'Medium' THEN
            IF NEW.points NOT BETWEEN 150 AND 400 THEN
                RAISE EXCEPTION 'Medium problems should have 150-400 points, got %', NEW.points;
            END IF;
        WHEN 'Hard' THEN
            IF NEW.points NOT BETWEEN 300 AND 700 THEN
                RAISE EXCEPTION 'Hard problems should have 300-700 points, got %', NEW.points;
            END IF;
        WHEN 'Expert' THEN
            IF NEW.points NOT BETWEEN 600 AND 1000 THEN
                RAISE EXCEPTION 'Expert problems should have 600-1000 points, got %', NEW.points;
            END IF;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate difficulty vs points
CREATE TRIGGER trigger_problems_difficulty_points
    BEFORE INSERT OR UPDATE OF difficulty_level, points ON problems
    FOR EACH ROW
    EXECUTE FUNCTION validate_problems_difficulty_points();

-- Add documentation comments
COMMENT ON TABLE problems IS 'Coding problems for competitive programming contests and practice';
COMMENT ON COLUMN problems.title IS 'Problem title/name (e.g., "Two Sum", "Binary Search Tree")';
COMMENT ON COLUMN problems.description IS 'Full problem statement with examples and constraints';
COMMENT ON COLUMN problems.difficulty_level IS 'Problem difficulty: Easy, Medium, Hard, Expert';
COMMENT ON COLUMN problems.topic_id IS 'Problem category/topic (FK to topics)';
COMMENT ON COLUMN problems.time_limit IS 'Maximum execution time in milliseconds';
COMMENT ON COLUMN problems.memory_limit IS 'Maximum memory usage in megabytes';
COMMENT ON COLUMN problems.points IS 'Points awarded for solving (varies by difficulty)';
COMMENT ON COLUMN problems.acceptance_rate IS 'Percentage of successful submissions (auto-calculated)';
COMMENT ON COLUMN problems.total_submissions IS 'Total number of submission attempts';
COMMENT ON COLUMN problems.successful_submissions IS 'Number of accepted submissions';
COMMENT ON COLUMN problems.created_by IS 'User who created/added this problem (FK to users)';
COMMENT ON COLUMN problems.is_active IS 'Whether problem is available for contests and practice';