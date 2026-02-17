-- =====================================================
-- 009_create_match_participants.sql
-- Participants in matches with performance & rating changes
-- Dependencies: matches, users
-- =====================================================

-- Create match_participants table
CREATE TABLE match_participants (
    -- Primary Key
    participant_id SERIAL PRIMARY KEY,

    -- Associations
    match_id INTEGER NOT NULL,                                -- FK to matches
    user_id INTEGER NOT NULL,                                 -- FK to users

    -- Performance Metrics
    score INTEGER NOT NULL DEFAULT 0 CHECK (score >= 0),      -- Total points earned in match
    problems_solved INTEGER NOT NULL DEFAULT 0 CHECK (problems_solved >= 0),
    time_taken INTEGER CHECK (time_taken >= 0),               -- Total time taken in seconds

    -- Rating Changes
    rating_before INTEGER CHECK (rating_before >= 0),
    rating_after INTEGER CHECK (rating_after >= 0),
    rating_change INTEGER,                                    -- Can be negative, positive, or zero

    -- Placement & Outcome
    placement INTEGER CHECK (placement >= 1),                 -- 1 = first place, etc.
    is_winner BOOLEAN DEFAULT FALSE,

    -- Timestamps
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    CONSTRAINT fk_match_participants_match FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_match_participants_user FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_match_participants_match ON match_participants(match_id);
CREATE INDEX idx_match_participants_user ON match_participants(user_id);
CREATE INDEX idx_match_participants_winner ON match_participants(is_winner);
CREATE INDEX idx_match_participants_placement ON match_participants(placement);
CREATE INDEX idx_match_participants_rating_change ON match_participants(rating_change);
CREATE INDEX idx_match_participants_joined ON match_participants(joined_at DESC);

-- Composite indexes for common queries
CREATE INDEX idx_match_participants_match_user ON match_participants(match_id, user_id);
CREATE INDEX idx_match_participants_match_winner ON match_participants(match_id, is_winner);
CREATE INDEX idx_match_participants_match_placement ON match_participants(match_id, placement);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_match_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before row changes
CREATE TRIGGER trigger_match_participants_updated_at
    BEFORE UPDATE ON match_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_match_participants_updated_at();

-- Validation: Ensure rating_after matches rating_before + rating_change
CREATE OR REPLACE FUNCTION validate_rating_consistency()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.rating_before IS NOT NULL AND NEW.rating_after IS NOT NULL AND NEW.rating_change IS NOT NULL THEN
        IF NEW.rating_after <> NEW.rating_before + NEW.rating_change THEN
            RAISE EXCEPTION 'rating_after must equal rating_before + rating_change';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for rating consistency
CREATE TRIGGER trigger_validate_rating_consistency
    BEFORE INSERT OR UPDATE OF rating_before, rating_after, rating_change ON match_participants
    FOR EACH ROW
    EXECUTE FUNCTION validate_rating_consistency();

-- Comments for documentation
COMMENT ON TABLE match_participants IS 'Links users to matches with performance metrics and rating adjustments';
COMMENT ON COLUMN match_participants.match_id IS 'Associated match ID';
COMMENT ON COLUMN match_participants.user_id IS 'User participating in the match';
COMMENT ON COLUMN match_participants.score IS 'Points earned by the participant';
COMMENT ON COLUMN match_participants.problems_solved IS 'Number of problems solved by the participant';
COMMENT ON COLUMN match_participants.time_taken IS 'Total time taken by participant in seconds';
COMMENT ON COLUMN match_participants.rating_before IS 'User rating before match';
COMMENT ON COLUMN match_participants.rating_after IS 'User rating after match';
COMMENT ON COLUMN match_participants.rating_change IS 'Change in rating after match';
COMMENT ON COLUMN match_participants.placement IS 'Final placement in match (1 = first place)';
COMMENT ON COLUMN match_participants.is_winner IS 'Whether this participant is a winner';
COMMENT ON COLUMN match_participants.joined_at IS 'Timestamp when participant joined the match';
COMMENT ON COLUMN match_participants.finished_at IS 'Timestamp when participant finished the match';
