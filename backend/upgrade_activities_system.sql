
-- Migration: Upgrade Activities System to Unified B2B Contextual Timeline
-- Description: Standardizes activity logging with metadata and contextual linking.

-- 1. Upgrade activities table structure
DO $$ 
BEGIN 
    -- Ensure columns exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='activities' AND column_name='related_type') THEN
        ALTER TABLE activities RENAME COLUMN related_entity_type TO related_type;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='activities' AND column_name='related_id') THEN
        ALTER TABLE activities RENAME COLUMN related_entity_id TO related_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='activities' AND column_name='activity_type') THEN
        ALTER TABLE activities ADD COLUMN activity_type TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='activities' AND column_name='metadata') THEN
        ALTER TABLE activities ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='activities' AND column_name='organization_id') THEN
        ALTER TABLE activities ADD COLUMN organization_id UUID;
    END IF;
    
    -- Sync existing 'type' to 'activity_type' if needed
    UPDATE activities SET activity_type = type WHERE activity_type IS NULL;
END $$;

-- 2. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_activities_related ON activities(related_type, related_id);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_org ON activities(organization_id);

-- 3. RLS Policies
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view activities for entities they have access to
-- Simplification for now: View all activities if authenticated (matching previous context)
-- Real production would join on the related entity's assigned_to/org_id.
DROP POLICY IF EXISTS "Users can view relevant activities" ON activities;
CREATE POLICY "Users can view relevant activities" ON activities
    FOR SELECT USING (auth.role() = 'authenticated');

-- 4. Audit Trigger Helper (Optional but recommended for auto-updates)
-- For now we rely on the Service Layer as requested.

-- 5. Helper Function for aggregated counts (useful for overview screens)
CREATE OR REPLACE FUNCTION get_entity_activity_count(r_type TEXT, r_id UUID)
RETURNS BIGINT AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM activities WHERE related_type = r_type AND related_id = r_id);
END;
$$ LANGUAGE plpgsql;
