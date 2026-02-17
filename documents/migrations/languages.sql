-- =====================================================
-- 002_create_languages.sql
-- Programming Languages Configuration for CodeForge
-- Dependencies: None (Foundation table)
-- =====================================================

-- Create languages table
CREATE TABLE languages (
    -- Primary Key
    language_id SERIAL PRIMARY KEY,
    
    -- Language Identification
    language_name VARCHAR(50) NOT NULL UNIQUE,             -- e.g., "Python", "JavaScript"
    language_code VARCHAR(10) NOT NULL UNIQUE,             -- e.g., "py", "js", "cpp"
    version VARCHAR(20) NOT NULL DEFAULT '1.0',            -- e.g., "3.11", "ES2023"
    
    -- File Handling
    file_extension VARCHAR(10) NOT NULL,                   -- e.g., ".py", ".js", ".cpp"
    
    -- Compilation & Execution Commands
    compile_command TEXT DEFAULT NULL,                     -- e.g., "g++ -o {output} {input}"
    execute_command TEXT NOT NULL,                         -- e.g., "python3 {file}", "./{output}"
    
    -- Performance Multipliers (for fair comparison across languages)
    time_multiplier DECIMAL(3,2) DEFAULT 1.00,           -- e.g., 1.5 for Python (slower)
    memory_multiplier DECIMAL(3,2) DEFAULT 1.00,         -- e.g., 1.2 for Java (more memory)
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,                        -- Can users select this language?
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_language_code_format 
        CHECK (language_code ~ '^[a-z0-9_]+$'),           -- Only lowercase, numbers, underscore
    CONSTRAINT chk_file_extension_format 
        CHECK (file_extension ~ '^\.[a-z0-9]+$'),         -- Must start with dot
    CONSTRAINT chk_multipliers_positive 
        CHECK (time_multiplier > 0 AND memory_multiplier > 0),
    CONSTRAINT chk_multipliers_reasonable 
        CHECK (time_multiplier <= 5.0 AND memory_multiplier <= 5.0)
);

-- Create indexes for performance
CREATE INDEX idx_languages_code ON languages(language_code);
CREATE INDEX idx_languages_active ON languages(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_languages_name ON languages(language_name);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_languages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_languages_updated_at
    BEFORE UPDATE ON languages
    FOR EACH ROW
    EXECUTE FUNCTION update_languages_updated_at();

-- Add documentation comments
COMMENT ON TABLE languages IS 'Supported programming languages and their execution configurations';
COMMENT ON COLUMN languages.language_code IS 'Short code used in URLs and file naming (e.g., py, cpp, js)';
COMMENT ON COLUMN languages.compile_command IS 'Command to compile code (NULL if interpreted language)';
COMMENT ON COLUMN languages.execute_command IS 'Command to run the code or compiled binary';
COMMENT ON COLUMN languages.time_multiplier IS 'Factor to adjust time limits (1.0 = baseline, >1.0 = more time)';
COMMENT ON COLUMN languages.memory_multiplier IS 'Factor to adjust memory limits (1.0 = baseline, >1.0 = more memory)';
COMMENT ON COLUMN languages.file_extension IS 'File extension for source code files (including the dot)';
COMMENT ON COLUMN languages.version IS 'Language version or standard being used';