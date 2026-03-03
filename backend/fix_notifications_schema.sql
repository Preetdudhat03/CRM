-- FIX: Notifications table mismatch with Flutter model

-- 1. Add missing columns
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'general';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS sender_id UUID;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS related_id TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS related_type TEXT;

-- 2. Migrate data from old column names (if they exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'related_entity_id') THEN
        UPDATE notifications SET related_id = related_entity_id WHERE related_id IS NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'related_entity_type') THEN
        UPDATE notifications SET related_type = related_entity_type WHERE related_type IS NULL;
    END IF;
END $$;

-- 3. (Optional but recommended) Drop old columns once migration is verified
-- ALTER TABLE notifications DROP COLUMN IF EXISTS related_entity_id;
-- ALTER TABLE notifications DROP COLUMN IF EXISTS related_entity_type;

-- 4. Enable Realtime if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
END $$;

-- 5. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
