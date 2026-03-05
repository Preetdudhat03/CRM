-- Migration: Unified Multi-Tenancy Upgrade
-- Description: Adds organization_id to all CRM entities and establishes global RLS policies.

-- 1. Ensure organization_id exists in profiles
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='organization_id') THEN
        ALTER TABLE profiles ADD COLUMN organization_id UUID;
    END IF;
END $$;

-- 2. Add organization_id to all CRM tables
DO $$ 
DECLARE
    t text;
BEGIN 
    FOR t IN SELECT table_name 
             FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name IN ('contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies')
    LOOP
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t AND column_name = 'organization_id') THEN
            EXECUTE format('ALTER TABLE %I ADD COLUMN organization_id UUID', t);
        END IF;
    END LOOP;
END $$;

-- 3. Create or Update Files Table
CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid, 
  related_type text NOT NULL CHECK (related_type IN ('lead', 'contact', 'deal', 'company')),
  related_id uuid NOT NULL,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_size integer,
  mime_type text,
  uploaded_by uuid REFERENCES profiles(id),
  created_at timestamp with time zone DEFAULT now()
);

-- 4. Enable RLS and Create Global Policies
DO $$ 
DECLARE
    t text;
    policy_name text;
BEGIN 
    FOR t IN SELECT table_name 
             FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name IN ('contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies', 'files')
    LOOP
        -- Enable RLS
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);

        -- Selective View Policy
        policy_name := format('tenant_view_%s', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, t);
        EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid()) OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL)', policy_name, t);

        -- Selective Insert Policy
        policy_name := format('tenant_insert_%s', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, t);
        EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid()) OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL)', policy_name, t);

        -- Selective Update Policy
        policy_name := format('tenant_update_%s', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, t);
        EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE USING (organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid()) OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL)', policy_name, t);

        -- Selective Delete Policy
        policy_name := format('tenant_delete_%s', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, t);
        EXECUTE format('CREATE POLICY %I ON %I FOR DELETE USING (organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid()) OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL)', policy_name, t);
    END LOOP;
END $$;

-- 5. Storage Configuration
INSERT INTO storage.buckets (id, name, public)
VALUES ('crm-files', 'crm-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Allow tenant-based uploads" ON storage.objects;
    CREATE POLICY "Allow tenant-based uploads" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'crm-files' AND
        (
            (storage.foldername(name))[1] = (SELECT organization_id::text FROM profiles WHERE id = auth.uid())
            OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
        )
    );

    DROP POLICY IF EXISTS "Allow tenant-based downloads" ON storage.objects;
    CREATE POLICY "Allow tenant-based downloads" ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'crm-files' AND
        (
            (storage.foldername(name))[1] = (SELECT organization_id::text FROM profiles WHERE id = auth.uid())
            OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
        )
    );

    DROP POLICY IF EXISTS "Allow tenant-based deletion" ON storage.objects;
    CREATE POLICY "Allow tenant-based deletion" ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'crm-files' AND
        (
            (storage.foldername(name))[1] = (SELECT organization_id::text FROM profiles WHERE id = auth.uid())
            OR (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
        )
    );
END $$;
