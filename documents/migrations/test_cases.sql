-- =====================================================
-- 006_create_test_cases.sql
-- Test Cases for Problem Evaluation in CodeForge
-- Dependencies: problems
-- =====================================================

-- Create test_cases table
CREATE TABLE test_cases (
    -- Primary Key
    test_case_id SERIAL PRIMARY KEY,
    
    -- Problem Association
    problem_id INTEGER NOT NULL,                          -- FK to problems
    
    -- Test Case Data
    input_data TEXT NOT NULL,                            -- Input for the test case
    expected_output TEXT NOT NULL,                       -- Expected output
    
    -- Test Case Classification
    is_sample BOOLEAN DEFAULT FALSE,                     -- Visible to users as example?
    is_hidden BOOLEAN DEFAULT TRUE,                      -- Hidden from users during contest?
    weight DECIMAL(4,2) DEFAULT 1.00,                   -- Importance weight (0.01 to 10.00)
    
    -- Execution Constraints (can override problem defaults)
    time_limit INTEGER DEFAULT NULL,                     -- Time limit in ms (NULL = use problem default)
    memory_limit INTEGER DEFAULT NULL,                   -- Memory limit in MB (NULL = use problem default)
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_test_cases_problem 
        FOREIGN KEY (problem_id) 
        REFERENCES problems(problem_id)
        ON DELETE CASCADE                                -- Delete test cases when problem deleted
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_test_cases_weight_valid 
        CHECK (weight > 0 AND weight <= 10.00),
    CONSTRAINT chk_test_cases_time_limit_positive 
        CHECK (time_limit IS NULL OR (time_limit > 0 AND time_limit <= 20000)), -- Max 20s override
    CONSTRAINT chk_test_cases_memory_limit_positive 
        CHECK (memory_limit IS NULL OR (memory_limit > 0 AND memory_limit <= 2048)), -- Max 2GB override
    CONSTRAINT chk_test_cases_input_not_empty 
        CHECK (LENGTH(TRIM(input_data)) > 0),
    CONSTRAINT chk_test_cases_output_not_empty 
        CHECK (LENGTH(TRIM(expected_output)) > 0),
    CONSTRAINT chk_test_cases_sample_not_hidden 
        CHECK (NOT (is_sample = TRUE AND is_hidden = TRUE)) -- Sample cases cannot be hidden
);

-- Create indexes for performance
CREATE INDEX idx_test_cases_problem ON test_cases(problem_id);
CREATE INDEX idx_test_cases_sample ON test_cases(is_sample) WHERE is_sample = TRUE;
CREATE INDEX idx_test_cases_hidden ON test_cases(is_hidden);
CREATE INDEX idx_test_cases_weight ON test_cases(weight DESC);
CREATE INDEX idx_test_cases_created_at ON test_cases(created_at DESC);

-- Composite indexes for common queries
CREATE INDEX idx_test_cases_problem_sample ON test_cases(problem_id, is_sample);
CREATE INDEX idx_test_cases_problem_hidden ON test_cases(problem_id, is_hidden);
CREATE INDEX idx_test_cases_problem_weight ON test_cases(problem_id, weight DESC);

-- Partial indexes for specific use cases
CREATE INDEX idx_test_cases_sample_visible ON test_cases(problem_id) 
WHERE is_sample = TRUE AND is_hidden = FALSE;
CREATE INDEX idx_test_cases_hidden_weighted ON test_cases(problem_id, weight DESC) 
WHERE is_hidden = TRUE;

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_test_cases_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_test_cases_updated_at
    BEFORE UPDATE ON test_cases
    FOR EACH ROW
    EXECUTE FUNCTION update_test_cases_updated_at();

-- Function to validate test case data integrity
CREATE OR REPLACE FUNCTION validate_test_case_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure input and output don't exceed reasonable limits
    IF LENGTH(NEW.input_data) > 1048576 THEN  -- 1MB limit
        RAISE EXCEPTION 'Input data too large (max 1MB)';
    END IF;
    
    IF LENGTH(NEW.expected_output) > 1048576 THEN  -- 1MB limit
        RAISE EXCEPTION 'Expected output too large (max 1MB)';
    END IF;
    
    -- Clean up whitespace in expected output (normalize line endings)
    NEW.expected_output = TRIM(TRAILING FROM REGEXP_REPLACE(NEW.expected_output, '\r\n|\r', E'\n', 'g'));
    NEW.input_data = TRIM(TRAILING FROM REGEXP_REPLACE(NEW.input_data, '\r\n|\r', E'\n', 'g'));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate and normalize test case data
CREATE TRIGGER trigger_validate_test_case_data
    BEFORE INSERT OR UPDATE OF input_data, expected_output ON test_cases
    FOR EACH ROW
    EXECUTE FUNCTION validate_test_case_data();

-- Function to ensure at least one sample test case per problem
CREATE OR REPLACE FUNCTION check_sample_test_cases()
RETURNS TRIGGER AS $$
DECLARE
    sample_count INTEGER;
BEGIN
    -- Count sample test cases for this problem
    SELECT COUNT(*) INTO sample_count
    FROM test_cases 
    WHERE problem_id = NEW.problem_id AND is_sample = TRUE;
    
    -- If this is the first test case and it's not a sample, warn (but don't prevent)
    IF sample_count = 0 AND NEW.is_sample = FALSE THEN
        RAISE NOTICE 'Problem % has no sample test cases. Consider adding at least one sample case.', NEW.problem_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check sample test case availability
CREATE TRIGGER trigger_check_sample_test_cases
    AFTER INSERT ON test_cases
    FOR EACH ROW
    EXECUTE FUNCTION check_sample_test_cases();

-- Function to automatically set reasonable weights based on test case type
CREATE OR REPLACE FUNCTION auto_set_test_case_weight()
RETURNS TRIGGER AS $$
BEGIN
    -- If weight not explicitly set, use smart defaults
    IF NEW.weight = 1.00 THEN  -- Default weight, auto-adjust
        IF NEW.is_sample = TRUE THEN
            NEW.weight = 0.50;  -- Sample cases worth less
        ELSIF NEW.is_hidden = TRUE THEN
            NEW.weight = 1.00;  -- Hidden cases normal weight
        ELSE
            NEW.weight = 1.00;  -- Public cases normal weight
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-set test case weights
CREATE TRIGGER trigger_auto_set_test_case_weight
    BEFORE INSERT ON test_cases
    FOR EACH ROW
    EXECUTE FUNCTION auto_set_test_case_weight();

-- Add documentation comments
COMMENT ON TABLE test_cases IS 'Test cases for evaluating code submissions against problems';
COMMENT ON COLUMN test_cases.problem_id IS 'Associated problem (FK to problems)';
COMMENT ON COLUMN test_cases.input_data IS 'Input data for the test case (stdin)';
COMMENT ON COLUMN test_cases.expected_output IS 'Expected output for correct solution (stdout)';
COMMENT ON COLUMN test_cases.is_sample IS 'Whether test case is visible to users as example';
COMMENT ON COLUMN test_cases.is_hidden IS 'Whether test case is hidden during contest (for final evaluation)';
COMMENT ON COLUMN test_cases.weight IS 'Relative importance of this test case (0.01-10.00)';
COMMENT ON COLUMN test_cases.time_limit IS 'Override time limit for this specific test case (NULL = use problem default)';
COMMENT ON COLUMN test_cases.memory_limit IS 'Override memory limit for this specific test case (NULL = use problem default)';