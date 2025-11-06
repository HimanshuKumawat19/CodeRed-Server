-- =====================================================
-- 007_create_friends.sql
-- Friendship System Structure for CodeForge
-- Dependencies: users
-- =====================================================

-- Create friends table
CREATE TABLE friends (
    -- Primary Key
    friendship_id SERIAL PRIMARY KEY,
    
    -- Friendship Relationship
    user_id INTEGER NOT NULL,                            -- User who has the friend
    friend_id INTEGER NOT NULL,                          -- User who is the friend
    
    -- Friendship Status & Workflow
    status VARCHAR(20) NOT NULL DEFAULT 'pending',      -- 'pending', 'accepted', 'blocked'
    requested_by INTEGER NOT NULL,                       -- Who initiated the friendship
    
    -- Timestamps for Friendship Lifecycle
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,   -- When friendship was requested
    accepted_at TIMESTAMP DEFAULT NULL,                 -- When friendship was accepted
    blocked_at TIMESTAMP DEFAULT NULL,                  -- When friendship was blocked
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_friends_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id)
        ON DELETE CASCADE                                -- Delete friendships when user deleted
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_friends_friend 
        FOREIGN KEY (friend_id) 
        REFERENCES users(user_id)
        ON DELETE CASCADE                                -- Delete friendships when friend deleted
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_friends_requested_by 
        FOREIGN KEY (requested_by) 
        REFERENCES users(user_id)
        ON DELETE CASCADE                                -- Delete friendships when requester deleted
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_friends_status_valid 
        CHECK (status IN ('pending', 'accepted', 'blocked')),
    CONSTRAINT chk_friends_no_self_friend 
        CHECK (user_id != friend_id),                    -- Cannot be friends with yourself
    CONSTRAINT chk_friends_requested_by_valid 
        CHECK (requested_by = user_id OR requested_by = friend_id), -- Requester must be one of the users
    CONSTRAINT chk_friends_accepted_at_valid 
        CHECK ((status = 'accepted' AND accepted_at IS NOT NULL) OR 
               (status != 'accepted' AND accepted_at IS NULL)),
    CONSTRAINT chk_friends_blocked_at_valid 
        CHECK ((status = 'blocked' AND blocked_at IS NOT NULL) OR 
               (status != 'blocked' AND blocked_at IS NULL))
);

-- Unique constraint to prevent duplicate friendships (bidirectional)
CREATE UNIQUE INDEX idx_friends_unique_pair 
ON friends(LEAST(user_id, friend_id), GREATEST(user_id, friend_id));

-- Create indexes for performance
CREATE INDEX idx_friends_user ON friends(user_id);
CREATE INDEX idx_friends_friend ON friends(friend_id);
CREATE INDEX idx_friends_status ON friends(status);
CREATE INDEX idx_friends_requested_by ON friends(requested_by);
CREATE INDEX idx_friends_requested_at ON friends(requested_at DESC);
CREATE INDEX idx_friends_accepted_at ON friends(accepted_at DESC) WHERE accepted_at IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_friends_user_status ON friends(user_id, status);
CREATE INDEX idx_friends_friend_status ON friends(friend_id, status);
CREATE INDEX idx_friends_user_accepted ON friends(user_id, accepted_at DESC) 
WHERE status = 'accepted';

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_friends_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_friends_updated_at
    BEFORE UPDATE ON friends
    FOR EACH ROW
    EXECUTE FUNCTION update_friends_updated_at();

-- Function to auto-set timestamps based on status changes
CREATE OR REPLACE FUNCTION manage_friends_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- When status changes to 'accepted', set accepted_at
    IF NEW.status = 'accepted' AND OLD.status != 'accepted' THEN
        NEW.accepted_at = CURRENT_TIMESTAMP;
        NEW.blocked_at = NULL;  -- Clear blocked timestamp if previously blocked
    END IF;
    
    -- When status changes to 'blocked', set blocked_at
    IF NEW.status = 'blocked' AND OLD.status != 'blocked' THEN
        NEW.blocked_at = CURRENT_TIMESTAMP;
        NEW.accepted_at = NULL;  -- Clear accepted timestamp if previously accepted
    END IF;
    
    -- When status changes to 'pending', clear both timestamps
    IF NEW.status = 'pending' AND OLD.status != 'pending' THEN
        NEW.accepted_at = NULL;
        NEW.blocked_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to manage status timestamps
CREATE TRIGGER trigger_manage_friends_timestamps
    BEFORE UPDATE OF status ON friends
    FOR EACH ROW
    EXECUTE FUNCTION manage_friends_timestamps();

-- Function to prevent duplicate friendship relationships
CREATE OR REPLACE FUNCTION prevent_duplicate_friendships()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if reverse friendship already exists
    IF EXISTS (
        SELECT 1 FROM friends 
        WHERE user_id = NEW.friend_id 
        AND friend_id = NEW.user_id 
        AND friendship_id != COALESCE(NEW.friendship_id, -1)
    ) THEN
        RAISE EXCEPTION 'Friendship between users % and % already exists', 
            LEAST(NEW.user_id, NEW.friend_id), 
            GREATEST(NEW.user_id, NEW.friend_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to prevent duplicate friendships
CREATE TRIGGER trigger_prevent_duplicate_friendships
    BEFORE INSERT OR UPDATE ON friends
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_friendships();

-- Function to create reciprocal friendship entries
CREATE OR REPLACE FUNCTION create_reciprocal_friendship()
RETURNS TRIGGER AS $$
BEGIN
    -- When a friendship is accepted, ensure both users have the friendship record
    IF NEW.status = 'accepted' AND (OLD IS NULL OR OLD.status != 'accepted') THEN
        -- Insert reciprocal friendship if it doesn't exist
        INSERT INTO friends (user_id, friend_id, status, requested_by, requested_at, accepted_at)
        SELECT NEW.friend_id, NEW.user_id, 'accepted', NEW.requested_by, NEW.requested_at, NEW.accepted_at
        WHERE NOT EXISTS (
            SELECT 1 FROM friends 
            WHERE user_id = NEW.friend_id 
            AND friend_id = NEW.user_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for reciprocal friendships
CREATE TRIGGER trigger_create_reciprocal_friendship
    AFTER UPDATE OF status ON friends
    FOR EACH ROW
    EXECUTE FUNCTION create_reciprocal_friendship();

-- Add documentation comments
COMMENT ON TABLE friends IS 'Friendship relationships between users with status management';
COMMENT ON COLUMN friends.user_id IS 'User who has this friend relationship';
COMMENT ON COLUMN friends.friend_id IS 'User who is the friend in this relationship';
COMMENT ON COLUMN friends.status IS 'Friendship status: pending (requested), accepted, blocked';
COMMENT ON COLUMN friends.requested_by IS 'User who initiated the friendship request';
COMMENT ON COLUMN friends.requested_at IS 'When the friendship was first requested';
COMMENT ON COLUMN friends.accepted_at IS 'When the friendship was accepted (NULL if not accepted)';
COMMENT ON COLUMN friends.blocked_at IS 'When the friendship was blocked (NULL if not blocked)';