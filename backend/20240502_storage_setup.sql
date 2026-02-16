-- =====================================================================================
-- PHASE 9: SUPABASE STORAGE SETUP (AVATARS)
-- =====================================================================================

-- 1. Create the 'avatars' bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Set up RLS Policies for Storage

-- Allow public access to view avatars
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload their own avatar
-- We'll use a folder structure: avatars/{user_id}/filename
-- Or just random filenames.
-- For simplicity, let's allow authenticated users to upload to 'avatars' bucket.
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.role() = 'authenticated'
);

-- Allow users to update/delete their own avatars
-- This requires checking that the owner matches auth.uid()
-- Supabase storage stores owner_id which matches auth.users.id
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' AND
  auth.uid() = owner
);

CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' AND
  auth.uid() = owner
);
