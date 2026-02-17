-- =====================================================
-- 015_create_submissions.sql
-- Stores all code submissions for problems and matches
-- Dependencies: users, problems, matches, languages
-- =====================================================

-- Create submissions table
CREATE TABLE submissions (
    -- Primary Key
    submission_id SERIAL PRIMARY KEY,

    -- Associations
    user_id INTEGER NOT NULL,            -- FK to users
    problem_id INTEGER NOT NULL,         -- FK to problems
    match_id INTEGER DEFAULT NULL,       -- FK to matches (optional if submission outside match)
    language_id INTEGER NOT NULL,        -- FK to languages

    -- Submission Data
    source_code TEXT NOT NULL,           -- Submitted code
    verdict VARCHAR(50) NOT NULL,        -- e.g. Accepted, Wrong Answer, TLE, MLE, Compilation Error
    execution_time INTEGER DEFAULT NULL, -- ms taken
    memory_used INTEGER DEFAULT NULL,    -- KB used
    test_cases_passed INTEGER DEFAULT 0, -- Number of test cases passed
    total_test_cases INTEGER DEFAULT 0,  -- Total test cases for problem/match
    error_message TEXT DEFAULT NULL,     -- Error or compilation message
    is_final_submission BOOLEAN DEFAULT FALSE, -- Final answer in match?

    -- Timestamps
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    judged_at TIMESTAMP DEFAULT NULL,

    -- Foreign Keys
    CONSTRAINT fk_submissions_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_submissions_problem FOREIGN KEY (problem_id)
        REFERENCES problems(problem_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_submissions_match FOREIGN KEY (match_id)
        REFERENCES matches(match_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_submissions_language FOREIGN KEY (language_id)
        REFERENCES languages(language_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Constraints
    CONSTRAINT chk_submissions_time_positive 
        CHECK (execution_time IS NULL OR execution_time >= 0),
    CONSTRAINT chk_submissions_memory_positive 
        CHECK (memory_used IS NULL OR memory_used >= 0),
    CONSTRAINT chk_submissions_test_case_counts 
        CHECK (test_cases_passed >= 0 AND total_test_cases >= 0 AND test_cases_passed <= total_test_cases),
    CONSTRAINT chk_submissions_source_not_empty 
        CHECK (LENGTH(TRIM(source_code)) > 0)
);

-- Indexes for performance
CREATE INDEX idx_submissions_user ON submissions(user_id);
CREATE INDEX idx_submissions_problem ON submissions(problem_id);
CREATE INDEX idx_submissions_match ON submissions(match_id);
CREATE INDEX idx_submissions_language ON submissions(language_id);
CREATE INDEX idx_submissions_verdict ON submissions(verdict);
CREATE INDEX idx_submissions_submitted_at ON submissions(submitted_at DESC);
CREATE INDEX idx_submissions_is_final ON submissions(is_final_submission);

-- Composite indexes for frequent queries
CREATE INDEX idx_submissions_user_problem ON submissions(user_id, problem_id);
CREATE INDEX idx_submissions_problem_verdict ON submissions(problem_id, verdict);
CREATE INDEX idx_submissions_match_user ON submissions(match_id, user_id);

-- Function to auto-update judged_at if verdict changes
CREATE OR REPLACE FUNCTION update_judged_at_on_verdict()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.verdict IS DISTINCT FROM OLD.verdict THEN
        NEW.judged_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update judged_at timestamp
CREATE TRIGGER trigger_update_judged_at_on_verdict
    BEFORE UPDATE OF verdict ON submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_judged_at_on_verdict();

-- Comments for documentation
COMMENT ON TABLE submissions IS 'Stores all code submissions by users for problems/matches';
COMMENT ON COLUMN submissions.user_id IS 'User who submitted the code';
COMMENT ON COLUMN submissions.problem_id IS 'Problem being solved';
COMMENT ON COLUMN submissions.match_id IS 'Match in which submission was made (NULL if not in match)';
COMMENT ON COLUMN submissions.language_id IS 'Programming language used for submission';
COMMENT ON COLUMN submissions.source_code IS 'Source code submitted by the user';
COMMENT ON COLUMN submissions.verdict IS 'Judging result (e.g., Accepted, Wrong Answer)';
COMMENT ON COLUMN submissions.execution_time IS 'Time taken to execute in ms';
COMMENT ON COLUMN submissions.memory_used IS 'Memory used in KB';
COMMENT ON COLUMN submissions.test_cases_passed IS 'Number of test cases passed';
COMMENT ON COLUMN submissions.total_test_cases IS 'Total test cases run';
COMMENT ON COLUMN submissions.error_message IS 'Error message if compilation/runtime error';
COMMENT ON COLUMN submissions.is_final_submission IS 'Whether submission is final in match context';
COMMENT ON COLUMN submissions.submitted_at IS 'When submission was made';
COMMENT ON COLUMN submissions.judged_at IS 'When submission was judged';
