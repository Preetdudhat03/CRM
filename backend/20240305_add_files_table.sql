-- Ensure organization_id exists in profiles for multi-tenancy
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='organization_id') THEN
        ALTER TABLE profiles ADD COLUMN organization_id UUID;
    END IF;
END $$;

-- Create files table
CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  related_type text NOT NULL CHECK (related_type IN ('lead', 'contact', 'deal', 'company')),
  related_id uuid NOT NULL,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_size integer,
  mime_type text,
  uploaded_by uuid REFERENCES profiles(id),
  created_at timestamp with time zone DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_files_related_id ON files(related_id);
CREATE INDEX IF NOT EXISTS idx_files_related_type ON files(related_type);
CREATE INDEX IF NOT EXISTS idx_files_organization_id ON files(organization_id);

-- Enable RLS
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- RLS policy: Users can only see files in their organization
DROP POLICY IF EXISTS "Users can view files in their organization" ON files;
CREATE POLICY "Users can view files in their organization" ON files
  FOR SELECT USING (
    organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    OR 
    (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL -- Fallback for non-multi-tenant users
  );

-- RLS policy: Users can insert files in their organization
DROP POLICY IF EXISTS "Users can insert files in their organization" ON files;
CREATE POLICY "Users can insert files in their organization" ON files
  FOR INSERT WITH CHECK (
    organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    OR
    (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
  );

-- RLS policy: Users can delete files in their organization
DROP POLICY IF EXISTS "Users can delete files in their organization" ON files;
CREATE POLICY "Users can delete files in their organization" ON files
  FOR DELETE USING (
    organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    OR
    (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
  );

-- Storage Configuration
-- Create 'crm-files' bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('crm-files', 'crm-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies for 'crm-files' bucket
-- Allow authenticated users to upload files to their organization's folders
-- (Assuming folder structure: organization_id/...)
DROP POLICY IF EXISTS "Allow authenticated uploads to crm-files" ON storage.objects;
CREATE POLICY "Allow authenticated uploads to crm-files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'crm-files' AND
  (
    (storage.foldername(name))[1] = (SELECT organization_id::text FROM profiles WHERE id = auth.uid())
    OR
    (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
  )
);

DROP POLICY IF EXISTS "Allow authenticated downloads from crm-files" ON storage.objects;
CREATE POLICY "Allow authenticated downloads from crm-files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'crm-files' AND
  (
    (storage.foldername(name))[1] = (SELECT organization_id::text FROM profiles WHERE id = auth.uid())
    OR
    (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
  )
);

DROP POLICY IF EXISTS "Allow authenticated deletion from crm-files" ON storage.objects;
CREATE POLICY "Allow authenticated deletion from crm-files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'crm-files' AND
  (
    (storage.foldername(name))[1] = (SELECT organization_id::text FROM profiles WHERE id = auth.uid())
    OR
    (SELECT organization_id FROM profiles WHERE id = auth.uid()) IS NULL
  )
);
