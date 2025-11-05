-- =====================================================
-- 012_create_match_queue.sql
-- Match queue for matchmaking system
-- Dependencies: users, languages, topics, matches
-- =====================================================

-- Create match_queue table
CREATE TABLE match_queue (
    -- Primary Key
    queue_id SERIAL PRIMARY KEY,

    -- User & Preferences
    user_id INTEGER NOT NULL,                                         -- FK to users
    queue_type VARCHAR(50) NOT NULL,                                  -- e.g., 'ranked', 'casual', 'tournament'
    preferred_language_id INTEGER,                                    -- FK to languages
    preferred_difficulty VARCHAR(50),                                 -- e.g., 'easy', 'medium', 'hard'
    preferred_topic_id INTEGER,                                       -- FK to topics
    is_ranked BOOLEAN DEFAULT FALSE,

    -- Rating Constraints
    rating_range_min INTEGER CHECK (rating_range_min IS NULL OR rating_range_min >= 0),
    rating_range_max INTEGER CHECK (rating_range_max IS NULL OR rating_range_max >= 0),
    
    -- Queue Status
    queue_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'waiting',                             -- e.g., 'waiting', 'matched', 'cancelled'
    match_id INTEGER,                                                 -- FK to matches if matched

    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_match_queue_user FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_match_queue_language FOREIGN KEY (preferred_language_id) REFERENCES languages(language_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_match_queue_topic FOREIGN KEY (preferred_topic_id) REFERENCES topics(topic_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_match_queue_match FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    -- Checks
    CONSTRAINT chk_match_queue_rating_range_valid CHECK (
        rating_range_min IS NULL OR rating_range_max IS NULL OR rating_range_min <= rating_range_max
    )
);

-- Indexes
CREATE INDEX idx_match_queue_user ON match_queue(user_id);
CREATE INDEX idx_match_queue_status ON match_queue(status);
CREATE INDEX idx_match_queue_is_ranked ON match_queue(is_ranked);
CREATE INDEX idx_match_queue_queue_time ON match_queue(queue_time DESC);

-- Composite indexes for matching logic
CREATE INDEX idx_match_queue_preferences ON match_queue(is_ranked, preferred_difficulty, preferred_topic_id);
CREATE INDEX idx_match_queue_rating_range ON match_queue(rating_range_min, rating_range_max);
CREATE INDEX idx_match_queue_status_time ON match_queue(status, queue_time);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_match_queue_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before row changes
CREATE TRIGGER trigger_match_queue_updated_at
    BEFORE UPDATE ON match_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_match_queue_updated_at();

-- Validation: Ensure ranked queue type matches is_ranked
CREATE OR REPLACE FUNCTION validate_queue_rank_consistency()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_ranked = TRUE AND LOWER(NEW.queue_type) <> 'ranked' THEN
        RAISE NOTICE 'Queue type adjusted to ranked to match is_ranked flag';
        NEW.queue_type = 'ranked';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for queue rank consistency
CREATE TRIGGER trigger_validate_queue_rank_consistency
    BEFORE INSERT OR UPDATE OF is_ranked, queue_type ON match_queue
    FOR EACH ROW
    EXECUTE FUNCTION validate_queue_rank_consistency();

-- Comments for documentation
COMMENT ON TABLE match_queue IS 'Queue of users waiting for matchmaking, with preferences and constraints';
COMMENT ON COLUMN match_queue.user_id IS 'User waiting in the queue';
COMMENT ON COLUMN match_queue.queue_type IS 'Type of queue (ranked, casual, tournament)';
COMMENT ON COLUMN match_queue.preferred_language_id IS 'Preferred programming language for the match';
COMMENT ON COLUMN match_queue.preferred_difficulty IS 'Preferred difficulty level for the match';
COMMENT ON COLUMN match_queue.preferred_topic_id IS 'Preferred problem topic';
COMMENT ON COLUMN match_queue.is_ranked IS 'Whether the queued match should affect ratings';
COMMENT ON COLUMN match_queue.rating_range_min IS 'Minimum rating constraint for opponent matching';
COMMENT ON COLUMN match_queue.rating_range_max IS 'Maximum rating constraint for opponent matching';
COMMENT ON COLUMN match_queue.queue_time IS 'When the user joined the queue';
COMMENT ON COLUMN match_queue.status IS 'Current queue status (waiting, matched, cancelled)';
COMMENT ON COLUMN match_queue.match_id IS 'Match ID if the user has been matched';
