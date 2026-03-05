-- Migration: Fix Activity Performer Names
-- Description: Link activities.created_by to profiles table and ensure correct data types.

-- 1. Alter created_by to UUID and add foreign key
DO $$ 
BEGIN 
    -- Change column type to UUID
    ALTER TABLE activities ALTER COLUMN created_by TYPE UUID USING created_by::UUID;
    
    -- Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name='activities_created_by_fkey') THEN
        ALTER TABLE activities ADD CONSTRAINT activities_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);
    END IF;
END $$;
