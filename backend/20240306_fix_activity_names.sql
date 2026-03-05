-- Migration: Fix Activity Performer Names (Robust Version)
-- Description: Safely converts created_by to UUID by moving legacy string names to performer_name.

DO $$ 
BEGIN 
    -- 1. Add performer_name column if it doesn't exist to store legacy names
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='activities' AND column_name='performer_name') THEN
        ALTER TABLE activities ADD COLUMN performer_name TEXT;
    END IF;

    -- 2. Move non-UUID values to performer_name
    -- Use regex to identify strings that aren't valid UUIDs
    UPDATE activities 
    SET performer_name = created_by 
    WHERE created_by IS NOT NULL 
      AND created_by !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

    -- 3. Clear non-UUID values from created_by so the cast to UUID succeeds
    UPDATE activities 
    SET created_by = NULL 
    WHERE created_by IS NOT NULL 
      AND created_by !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

    -- 4. Alter created_by to UUID type
    -- Now it only contains valid UUID strings or NULL
    ALTER TABLE activities ALTER COLUMN created_by TYPE UUID USING created_by::UUID;
    
    -- 5. Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name='activities_created_by_fkey') THEN
        ALTER TABLE activities ADD CONSTRAINT activities_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);
    END IF;

    -- 6. Ensure indices exist for performance
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname='idx_activities_created_by') THEN
        CREATE INDEX idx_activities_created_by ON activities(created_by);
    END IF;
END $$;
