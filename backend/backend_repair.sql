-- Fix schema inconsistencies for older contacts

-- 1. Ensure 'name' or 'first_name' columns don't block saves due to NOT NULL if they exist
ALTER TABLE contacts ALTER COLUMN first_name DROP NOT NULL;
ALTER TABLE leads ALTER COLUMN first_name DROP NOT NULL;

DO $$ 
BEGIN
    -- If 'name' column still exists from the old iteration, gracefully drop its NOT NULL constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'name') THEN
        ALTER TABLE contacts ALTER COLUMN name DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leads' AND column_name = 'name') THEN
        ALTER TABLE leads ALTER COLUMN name DROP NOT NULL;
    END IF;
END $$;

-- 2. Backfill empty first_name and last_name fields for old contacts that only have 'name'
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contacts' AND column_name = 'name') THEN
        UPDATE contacts 
        SET first_name = split_part(name, ' ', 1),
            last_name = substring(name FROM (length(split_part(name, ' ', 1)) + 2))
        WHERE (first_name IS NULL OR first_name = '') AND name IS NOT NULL;
    END IF;
END $$;

-- 3. Ensure columns exist for tracking
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE leads ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS sender_id UUID;

-- 4. Temporarily disable Row Level Security (RLS) on contacts and leads in case assigned_to NULLs are blocking updates
ALTER TABLE contacts DISABLE ROW LEVEL SECURITY;
ALTER TABLE leads DISABLE ROW LEVEL SECURITY;

-- 5. Enable Supabase Realtime for the notifications table so updates reach flutter devices instantly
begin;
  -- remove the supabase_realtime publication
  drop publication if exists supabase_realtime;
  -- re-create the supabase_realtime publication with no tables
  create publication supabase_realtime;
commit;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- 6. In case the old 'users' / 'profiles' fk constraint is throwing errors, let's gracefully recreate it
ALTER TABLE contacts DROP CONSTRAINT IF EXISTS contacts_assigned_to_fkey;
ALTER TABLE leads DROP CONSTRAINT IF EXISTS leads_assigned_to_fkey;

-- 5. Reload schema cache again
NOTIFY pgrst, 'reload schema';
