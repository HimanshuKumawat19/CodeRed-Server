-- =====================================================
-- 011_create_tournament_participants.sql
-- Links users to tournaments with results, scores, and status
-- Dependencies: tournaments, users
-- =====================================================

-- Create tournament_participants table
CREATE TABLE tournament_participants (
    -- Primary Key
    tournament_participant_id SERIAL PRIMARY KEY,

    -- Associations
    tournament_id INTEGER NOT NULL,                                -- FK to tournaments
    user_id INTEGER NOT NULL,                                      -- FK to users

    -- Participation Data
    registration_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,         -- When participant registered
    final_rank INTEGER CHECK (final_rank IS NULL OR final_rank >= 1),
    total_score INTEGER DEFAULT 0 CHECK (total_score >= 0),
    prize_won INTEGER DEFAULT 0 CHECK (prize_won >= 0),

    -- Disqualification Info
    is_disqualified BOOLEAN DEFAULT FALSE,
    disqualified_reason TEXT,

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_tournament_participants_tournament FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tournament_participants_user FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    -- Constraints
    CONSTRAINT chk_disqualified_reason_required CHECK (
        (is_disqualified = TRUE AND disqualified_reason IS NOT NULL)
        OR (is_disqualified = FALSE)
    )
);

-- Indexes
CREATE INDEX idx_tournament_participants_tournament ON tournament_participants(tournament_id);
CREATE INDEX idx_tournament_participants_user ON tournament_participants(user_id);
CREATE INDEX idx_tournament_participants_disqualified ON tournament_participants(is_disqualified);
CREATE INDEX idx_tournament_participants_final_rank ON tournament_participants(final_rank);
CREATE INDEX idx_tournament_participants_total_score ON tournament_participants(total_score DESC);

-- Composite indexes for common queries
CREATE INDEX idx_tournament_participants_tournament_rank ON tournament_participants(tournament_id, final_rank);
CREATE INDEX idx_tournament_participants_tournament_score ON tournament_participants(tournament_id, total_score DESC);
CREATE INDEX idx_tournament_participants_tournament_user ON tournament_participants(tournament_id, user_id);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_tournament_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before row changes
CREATE TRIGGER trigger_tournament_participants_updated_at
    BEFORE UPDATE ON tournament_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_tournament_participants_updated_at();

-- Validation: Ensure prize_won > 0 only if not disqualified
CREATE OR REPLACE FUNCTION validate_tournament_prize_disqualification()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_disqualified = TRUE AND NEW.prize_won > 0 THEN
        RAISE EXCEPTION 'Disqualified participants cannot win prizes';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for prize vs disqualification validation
CREATE TRIGGER trigger_validate_tournament_prize_disqualification
    BEFORE INSERT OR UPDATE OF is_disqualified, prize_won ON tournament_participants
    FOR EACH ROW
    EXECUTE FUNCTION validate_tournament_prize_disqualification();

-- Comments for documentation
COMMENT ON TABLE tournament_participants IS 'Links users to tournaments with performance results and disqualification status';
COMMENT ON COLUMN tournament_participants.tournament_id IS 'Associated tournament ID';
COMMENT ON COLUMN tournament_participants.user_id IS 'User participating in the tournament';
COMMENT ON COLUMN tournament_participants.registration_time IS 'Time the participant registered for the tournament';
COMMENT ON COLUMN tournament_participants.final_rank IS 'Final standing position in the tournament (1 = winner)';
COMMENT ON COLUMN tournament_participants.total_score IS 'Total score accumulated in the tournament';
COMMENT ON COLUMN tournament_participants.prize_won IS 'Prize awarded to participant (0 if none)';
COMMENT ON COLUMN tournament_participants.is_disqualified IS 'Whether participant was disqualified';
COMMENT ON COLUMN tournament_participants.disqualified_reason IS 'Reason for disqualification (required if disqualified)';
