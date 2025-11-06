-- =====================================================
-- create_problem_stats.sql
-- Aggregated statistics for problems in CodeForge
-- Dependencies: problems, languages
-- =====================================================

CREATE TABLE problem_stats (
    -- Primary Key
    stat_id SERIAL PRIMARY KEY,
    
    -- Problem Association
    problem_id INTEGER NOT NULL, -- FK to problems
    
    -- Performance Metrics
    total_attempts INTEGER DEFAULT 0,
    successful_submissions INTEGER DEFAULT 0,
    average_solve_time INTEGER, -- seconds
    fastest_solve_time INTEGER, -- seconds
    slowest_solve_time INTEGER, -- seconds
    
    -- Rates & Ratings
    acceptance_rate DECIMAL(5,2), -- %
    difficulty_rating DECIMAL(4,2),
    
    -- Latest Solve Data
    last_solved_at TIMESTAMP,
    most_used_language_id INTEGER, -- FK to languages
    
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Foreign Key Constraints
ALTER TABLE problem_stats
ADD CONSTRAINT fk_problem_stats_problem
FOREIGN KEY (problem_id) REFERENCES problems(problem_id)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE problem_stats
ADD CONSTRAINT fk_problem_stats_language
FOREIGN KEY (most_used_language_id) REFERENCES languages(language_id)
ON DELETE SET NULL ON UPDATE CASCADE;

-- Indexes
CREATE INDEX idx_problem_stats_problem ON problem_stats(problem_id);
CREATE INDEX idx_problem_stats_acceptance ON problem_stats(acceptance_rate DESC);
CREATE INDEX idx_problem_stats_difficulty ON problem_stats(difficulty_rating DESC);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_problem_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_problem_stats_updated_at
BEFORE UPDATE ON problem_stats
FOR EACH ROW
EXECUTE FUNCTION update_problem_stats_updated_at();

COMMENT ON TABLE problem_stats IS 'Aggregated performance metrics for each problem';
COMMENT ON COLUMN problem_stats.average_solve_time IS 'Average time in seconds for correct solves';
COMMENT ON COLUMN problem_stats.difficulty_rating IS 'System-assigned difficulty score for problem';
