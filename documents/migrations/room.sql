-- =====================================================
-- 013_create_rooms.sql
-- Rooms for hosting matches, chats, or collaborative coding
-- Dependencies: users, matches
-- =====================================================

-- Create rooms table
CREATE TABLE rooms (
    -- Primary Key
    room_id SERIAL PRIMARY KEY,

    -- Room Details
    room_name VARCHAR(255) NOT NULL,
    room_code VARCHAR(20) UNIQUE NOT NULL,                 -- Unique join code
    is_private BOOLEAN DEFAULT FALSE,
    max_participants INTEGER CHECK (max_participants > 0),

    -- Associations
    host_user_id INTEGER NOT NULL,                         -- FK to users
    match_id INTEGER,                                      -- FK to matches if tied to a match

    -- Status
    status VARCHAR(50) DEFAULT 'open',                     -- open, in_progress, closed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_rooms_host FOREIGN KEY (host_user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_rooms_match FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_host ON rooms(host_user_id);
CREATE INDEX idx_rooms_private ON rooms(is_private);
CREATE INDEX idx_rooms_created_at ON rooms(created_at DESC);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_rooms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before row changes
CREATE TRIGGER trigger_rooms_updated_at
    BEFORE UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_rooms_updated_at();

-- Validation: Ensure private rooms have a max_participants limit
CREATE OR REPLACE FUNCTION validate_private_room_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_private = TRUE AND NEW.max_participants IS NULL THEN
        RAISE EXCEPTION 'Private rooms must have a max_participants limit';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_private_room_limit
    BEFORE INSERT OR UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION validate_private_room_limit();

-- Comments for documentation
COMMENT ON TABLE rooms IS 'Rooms for hosting matches or collaborative sessions';
COMMENT ON COLUMN rooms.room_name IS 'Display name of the room';
COMMENT ON COLUMN rooms.room_code IS 'Unique join code for the room';
COMMENT ON COLUMN rooms.is_private IS 'Whether the room requires a code to join';
COMMENT ON COLUMN rooms.max_participants IS 'Maximum allowed participants in the room';
COMMENT ON COLUMN rooms.host_user_id IS 'User ID of the host/creator of the room';
COMMENT ON COLUMN rooms.match_id IS 'Match linked to the room, if applicable';
COMMENT ON COLUMN rooms.status IS 'Current status of the room (open, in_progress, closed)';
