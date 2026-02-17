-- =====================================================
-- 016_create_leaderboards.sql
-- Stores ranking information for contests, tournaments, or global leaderboards
-- Dependencies: users, tournaments (optional), matches (optional)
-- =====================================================

-- Create leaderboards table
CREATE TABLE leaderboards (
    -- Primary Key
    leaderboard_id SERIAL PRIMARY KEY,

    -- Associations
    user_id INTEGER NOT NULL,                -- FK to users
    tournament_id INTEGER DEFAULT NULL,       -- FK to tournaments (NULL for global leaderboard)
    match_id INTEGER DEFAULT NULL,            -- FK to matches (optional, for match-specific rankings)

    -- Ranking Data
    rank_position INTEGER NOT NULL,           -- 1 = top rank
    score DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- Total score/points
    problems_solved INTEGER DEFAULT 0,        -- Problems solved in scope
    matches_won INTEGER DEFAULT 0,            -- Matches won in scope
    time_penalty INTEGER DEFAULT 0,           -- Total penalty time in seconds

    -- Metadata
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_leaderboards_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_leaderboards_tournament FOREIGN KEY (tournament_id)
        REFERENCES tournaments(tournament_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_leaderboards_match FOREIGN KEY (match_id)
        REFERENCES matches(match_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Constraints
    CONSTRAINT chk_leaderboards_rank_positive 
        CHECK (rank_position > 0),
    CONSTRAINT chk_leaderboards_score_non_negative
        CHECK (score >= 0),
    CONSTRAINT chk_leaderboards_problems_solved_non_negative
        CHECK (problems_solved >= 0),
    CONSTRAINT chk_leaderboards_matches_won_non_negative
        CHECK (matches_won >= 0),
    CONSTRAINT chk_leaderboards_time_penalty_non_negative
        CHECK (time_penalty >= 0)
);

-- Indexes for performance
CREATE INDEX idx_leaderboards_user ON leaderboards(user_id);
CREATE INDEX idx_leaderboards_tournament ON leaderboards(tournament_id);
CREATE INDEX idx_leaderboards_match ON leaderboards(match_id);
CREATE INDEX idx_leaderboards_rank ON leaderboards(rank_position);
CREATE INDEX idx_leaderboards_score ON leaderboards(score DESC);

-- Composite indexes for common queries
CREATE INDEX idx_leaderboards_tournament_rank ON leaderboards(tournament_id, rank_position);
CREATE INDEX idx_leaderboards_match_rank ON leaderboards(match_id, rank_position);
CREATE INDEX idx_leaderboards_global_rank ON leaderboards(rank_position) WHERE tournament_id IS NULL AND match_id IS NULL;

-- Function to auto-update last_updated timestamp
CREATE OR REPLACE FUNCTION update_leaderboards_last_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_leaderboards_last_updated
    BEFORE UPDATE ON leaderboards
    FOR EACH ROW
    EXECUTE FUNCTION update_leaderboards_last_updated();

-- Comments
COMMENT ON TABLE leaderboards IS 'Stores ranking and score information for tournaments, matches, or global standings';
COMMENT ON COLUMN leaderboards.user_id IS 'User associated with the leaderboard entry';
COMMENT ON COLUMN leaderboards.tournament_id IS 'Tournament context (NULL for global leaderboard)';
COMMENT ON COLUMN leaderboards.match_id IS 'Match context (optional)';
COMMENT ON COLUMN leaderboards.rank_position IS 'Ranking position in the leaderboard';
COMMENT ON COLUMN leaderboards.score IS 'Score or points accumulated';
COMMENT ON COLUMN leaderboards.problems_solved IS 'Number of problems solved in this context';
COMMENT ON COLUMN leaderboards.matches_won IS 'Number of matches won in this context';
COMMENT ON COLUMN leaderboards.time_penalty IS 'Total penalty time in seconds';
COMMENT ON COLUMN leaderboards.last_updated IS 'Timestamp when leaderboard entry was last updated';
