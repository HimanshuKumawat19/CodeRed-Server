-- =====================================================
-- 003_create_topics.sql
-- Problem Topics/Categories Structure for CodeForge
-- Dependencies: None (Foundation table)
-- =====================================================

-- Create topics table
CREATE TABLE topics (
    -- Primary Key
    topic_id SERIAL PRIMARY KEY,
    
    -- Topic Information
    topic_name VARCHAR(100) NOT NULL UNIQUE,              -- e.g., "Dynamic Programming", "Graph Theory"
    topic_description TEXT DEFAULT NULL,                  -- Detailed explanation of the topic
    category VARCHAR(50) NOT NULL,                        -- e.g., "Algorithms", "Data Structures"
    
    -- Difficulty & Learning
    difficulty_weight DECIMAL(3,2) DEFAULT 1.00,         -- Multiplier for problem difficulty
    
    -- Hierarchical Structure (Self-referencing)
    parent_topic_id INTEGER DEFAULT NULL,                 -- For subtopics (e.g., "BFS" under "Graph Theory")
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,                       -- Can problems use this topic?
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_topics_parent 
        FOREIGN KEY (parent_topic_id) 
        REFERENCES topics(topic_id)
        ON DELETE SET NULL,                               -- If parent deleted, set to NULL
    
    -- Check Constraints
    CONSTRAINT chk_difficulty_weight_valid 
        CHECK (difficulty_weight > 0 AND difficulty_weight <= 3.0),
    CONSTRAINT chk_no_self_reference 
        CHECK (parent_topic_id != topic_id),             -- Topic can't be its own parent
    CONSTRAINT chk_category_not_empty 
        CHECK (LENGTH(TRIM(category)) > 0),
    CONSTRAINT chk_topic_name_not_empty 
        CHECK (LENGTH(TRIM(topic_name)) > 0)
);

-- Create indexes for performance
CREATE INDEX idx_topics_name ON topics(topic_name);
CREATE INDEX idx_topics_category ON topics(category);
CREATE INDEX idx_topics_parent ON topics(parent_topic_id);
CREATE INDEX idx_topics_active ON topics(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_topics_difficulty ON topics(difficulty_weight);

-- Composite index for category + active filtering
CREATE INDEX idx_topics_category_active ON topics(category, is_active) 
WHERE is_active = TRUE;

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_topics_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_topics_updated_at
    BEFORE UPDATE ON topics
    FOR EACH ROW
    EXECUTE FUNCTION update_topics_updated_at();

-- Function to prevent circular references in topic hierarchy
CREATE OR REPLACE FUNCTION check_topic_hierarchy()
RETURNS TRIGGER AS $$
DECLARE
    current_parent INTEGER;
    max_depth INTEGER := 10; -- Prevent infinite loops
    depth_counter INTEGER := 0;
BEGIN
    -- Only check if parent_topic_id is being set
    IF NEW.parent_topic_id IS NOT NULL THEN
        current_parent := NEW.parent_topic_id;
        
        -- Walk up the hierarchy to check for circular reference
        WHILE current_parent IS NOT NULL AND depth_counter < max_depth LOOP
            -- If we find ourselves in the hierarchy, it's circular
            IF current_parent = NEW.topic_id THEN
                RAISE EXCEPTION 'Circular reference detected: Topic % cannot be a descendant of itself', NEW.topic_id;
            END IF;
            
            -- Get the next parent
            SELECT parent_topic_id INTO current_parent 
            FROM topics 
            WHERE topic_id = current_parent;
            
            depth_counter := depth_counter + 1;
        END LOOP;
        
        -- Check if we hit max depth (potential infinite loop)
        IF depth_counter >= max_depth THEN
            RAISE EXCEPTION 'Topic hierarchy too deep (max % levels)', max_depth;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to prevent circular references
CREATE TRIGGER trigger_check_topic_hierarchy
    BEFORE INSERT OR UPDATE OF parent_topic_id ON topics
    FOR EACH ROW
    EXECUTE FUNCTION check_topic_hierarchy();

-- Add documentation comments
COMMENT ON TABLE topics IS 'Problem topics and categories with hierarchical structure support';
COMMENT ON COLUMN topics.topic_name IS 'Name of the topic (e.g., Dynamic Programming, Binary Search)';
COMMENT ON COLUMN topics.category IS 'Broad category (e.g., Algorithms, Data Structures, Mathematics)';
COMMENT ON COLUMN topics.difficulty_weight IS 'Multiplier for problem difficulty (1.0 = normal, >1.0 = harder)';
COMMENT ON COLUMN topics.parent_topic_id IS 'Parent topic for hierarchical organization (NULL = top level)';
COMMENT ON COLUMN topics.topic_description IS 'Detailed description of what this topic covers';
COMMENT ON COLUMN topics.is_active IS 'Whether this topic can be assigned to new problems';