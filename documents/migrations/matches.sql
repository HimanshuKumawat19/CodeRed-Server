-- =====================================================
-- 008_create_matches.sql
-- Matches table: stores competitive coding match metadata
-- Dependencies: tournaments, rooms, problems, languages, users
-- =====================================================

-- Create matches table
CREATE TABLE matches (
    -- Primary Key
    match_id SERIAL PRIMARY KEY,

    -- Match Details
    match_type VARCHAR(50) NOT NULL,                     -- e.g., '1v1', 'battle_royale', 'practice'
    match_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- e.g., 'pending', 'active', 'completed', 'cancelled'
    is_ranked BOOLEAN NOT NULL DEFAULT FALSE,            -- Affects rating?

    -- Associations
    tournament_id INTEGER,                               -- FK to tournaments (nullable for non-tournament matches)
    room_id INTEGER,                                     -- FK to rooms
    problem_id INTEGER NOT NULL,                         -- FK to problems
    language_id INTEGER NOT NULL,                        -- FK to languages
    winner_id INTEGER,                                   -- FK to users (nullable if draw/no winner)

    -- Timing & Duration
    duration_minutes INTEGER CHECK (duration_minutes > 0 AND duration_minutes <= 1440), -- Max 24h
    start_time TIMESTAMP,
    end_time TIMESTAMP,

    -- Audit Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_matches_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_matches_room FOREIGN KEY (room_id) REFERENCES rooms(room_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_matches_problem FOREIGN KEY (problem_id) REFERENCES problems(problem_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_matches_language FOREIGN KEY (language_id) REFERENCES languages(language_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_matches_winner FOREIGN KEY (winner_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_matches_status ON matches(match_status);
CREATE INDEX idx_matches_is_ranked ON matches(is_ranked);
CREATE INDEX idx_matches_problem ON matches(problem_id);
CREATE INDEX idx_matches_language ON matches(language_id);
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_room ON matches(room_id);
CREATE INDEX idx_matches_winner ON matches(winner_id);
CREATE INDEX idx_matches_start_time ON matches(start_time DESC);
CREATE INDEX idx_matches_end_time ON matches(end_time DESC);

-- Composite indexes for common queries
CREATE INDEX idx_matches_tournament_status ON matches(tournament_id, match_status);
CREATE INDEX idx_matches_problem_language ON matches(problem_id, language_id);
CREATE INDEX idx_matches_ranked_status ON matches(is_ranked, match_status);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_matches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before row changes
CREATE TRIGGER trigger_matches_updated_at
    BEFORE UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION update_matches_updated_at();

-- Validation: Ensure start_time < end_time if both are set
CREATE OR REPLACE FUNCTION validate_match_times()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_time IS NOT NULL AND NEW.end_time IS NOT NULL 
       AND NEW.start_time >= NEW.end_time THEN
        RAISE EXCEPTION 'Match start_time must be before end_time';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for validating match times
CREATE TRIGGER trigger_validate_match_times
    BEFORE INSERT OR UPDATE OF start_time, end_time ON matches
    FOR EACH ROW
    EXECUTE FUNCTION validate_match_times();

-- Comments for documentation
COMMENT ON TABLE matches IS 'Stores information about coding competition matches';
COMMENT ON COLUMN matches.match_type IS 'Type of match (e.g., 1v1, battle_royale, practice)';
COMMENT ON COLUMN matches.match_status IS 'Current status of the match (pending, active, completed, cancelled)';
COMMENT ON COLUMN matches.is_ranked IS 'Whether the match affects player ratings';
COMMENT ON COLUMN matches.tournament_id IS 'Associated tournament (nullable)';
COMMENT ON COLUMN matches.room_id IS 'Associated room (nullable)';
COMMENT ON COLUMN matches.problem_id IS 'The problem solved during the match';
COMMENT ON COLUMN matches.language_id IS 'Programming language used for the match';
COMMENT ON COLUMN matches.winner_id IS 'User ID of the winner (nullable for draw/no winner)';
COMMENT ON COLUMN matches.duration_minutes IS 'Match duration in minutes (max 1440)';
COMMENT ON COLUMN matches.start_time IS 'When the match started';
COMMENT ON COLUMN matches.end_time IS 'When the match ended';
