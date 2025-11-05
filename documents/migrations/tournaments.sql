-- =====================================================
-- 010_create_tournaments.sql
-- Tournaments for competitive coding events
-- Dependencies: user_ranks, users
-- =====================================================

-- Create tournaments table
CREATE TABLE tournaments (
    -- Primary Key
    tournament_id SERIAL PRIMARY KEY,

    -- Tournament Info
    tournament_name VARCHAR(255) NOT NULL,
    tournament_type VARCHAR(50) NOT NULL,                        -- e.g., 'single_elimination', 'round_robin', 'league'
    description TEXT,                                            -- Detailed info about the event

    -- Eligibility & Requirements
    rank_requirement INTEGER,                                    -- FK to user_ranks (minimum required rank)
    max_participants INTEGER CHECK (max_participants > 0),       -- Max players allowed
    entry_fee INTEGER DEFAULT 0 CHECK (entry_fee >= 0),          -- Fee in platform currency/points
    prize_pool INTEGER DEFAULT 0 CHECK (prize_pool >= 0),        -- Prize in platform currency/points

    -- Schedule
    registration_start TIMESTAMP NOT NULL,
    registration_end TIMESTAMP NOT NULL,
    tournament_start TIMESTAMP NOT NULL,
    tournament_end TIMESTAMP NOT NULL,

    -- Status & Ownership
    status VARCHAR(50) NOT NULL DEFAULT 'upcoming',              -- e.g., 'upcoming', 'ongoing', 'completed', 'cancelled'
    created_by INTEGER NOT NULL,                                 -- FK to users

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_tournaments_rank_requirement FOREIGN KEY (rank_requirement) REFERENCES user_ranks(rank_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_tournaments_created_by FOREIGN KEY (created_by) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    -- Checks
    CONSTRAINT chk_tournaments_schedule_valid CHECK (
        registration_start < registration_end AND
        tournament_start < tournament_end AND
        registration_end <= tournament_start
    )
);

-- Indexes
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_type ON tournaments(tournament_type);
CREATE INDEX idx_tournaments_rank_requirement ON tournaments(rank_requirement);
CREATE INDEX idx_tournaments_created_by ON tournaments(created_by);
CREATE INDEX idx_tournaments_registration_start ON tournaments(registration_start DESC);
CREATE INDEX idx_tournaments_start_time ON tournaments(tournament_start DESC);

-- Composite indexes for common queries
CREATE INDEX idx_tournaments_status_type ON tournaments(status, tournament_type);
CREATE INDEX idx_tournaments_schedule ON tournaments(registration_start, tournament_start);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_tournaments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before row changes
CREATE TRIGGER trigger_tournaments_updated_at
    BEFORE UPDATE ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION update_tournaments_updated_at();

-- Validation: Ensure prize pool is >= entry fee * participants if specified
CREATE OR REPLACE FUNCTION validate_tournament_prizes()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.max_participants IS NOT NULL AND NEW.entry_fee IS NOT NULL THEN
        IF NEW.prize_pool < (NEW.entry_fee * NEW.max_participants) THEN
            RAISE NOTICE 'Tournament prize pool is less than potential entry fee total';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for validating prize logic
CREATE TRIGGER trigger_validate_tournament_prizes
    BEFORE INSERT OR UPDATE OF prize_pool, entry_fee, max_participants ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION validate_tournament_prizes();

-- Comments for documentation
COMMENT ON TABLE tournaments IS 'Stores competitive coding tournaments with schedule, eligibility, and rewards';
COMMENT ON COLUMN tournaments.tournament_name IS 'Official name of the tournament';
COMMENT ON COLUMN tournaments.tournament_type IS 'Format type (single_elimination, round_robin, etc.)';
COMMENT ON COLUMN tournaments.description IS 'Detailed description of the tournament';
COMMENT ON COLUMN tournaments.rank_requirement IS 'Minimum rank required to join';
COMMENT ON COLUMN tournaments.max_participants IS 'Maximum number of participants allowed';
COMMENT ON COLUMN tournaments.entry_fee IS 'Entry fee for participation (0 if free)';
COMMENT ON COLUMN tournaments.prize_pool IS 'Total prize pool for the tournament';
COMMENT ON COLUMN tournaments.registration_start IS 'Start time for participant registration';
COMMENT ON COLUMN tournaments.registration_end IS 'End time for participant registration';
COMMENT ON COLUMN tournaments.tournament_start IS 'Start time of the tournament';
COMMENT ON COLUMN tournaments.tournament_end IS 'End time of the tournament';
COMMENT ON COLUMN tournaments.status IS 'Current status (upcoming, ongoing, completed, cancelled)';
COMMENT ON COLUMN tournaments.created_by IS 'User ID of the tournament organizer';
