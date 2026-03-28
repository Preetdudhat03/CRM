-- Migration: Fix Organization Members Relationship & Backfill Profiles
-- Description: Ensures all users have profiles and adds a direct foreign key 
--              from organization_members(user_id) to profiles(id).
-- Date: 2026-03-28

-- 1. Ensure all users have profiles (Data Repair)
-- This backfills missing profiles for existing users in auth.users
-- This is necessary to prevent Foreign Key violations if an "old" user 
-- (created before the profile trigger was active) joins an organization.
INSERT INTO public.profiles (id, name, email, role)
SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'name', split_part(email, '@', 1)), 
    email, 
    COALESCE(raw_user_meta_data->>'role', 'viewer')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 2. Add foreign key from organization_members to profiles
--    Note: user_id currently references auth.users(id), which is correct for 
--    data integrity but PostgREST needs a direct link to public profiles 
--    to allow joining them in a single query.
ALTER TABLE public.organization_members
DROP CONSTRAINT IF EXISTS organization_members_user_id_fkey,
ADD CONSTRAINT organization_members_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. Notify PostgREST to reload the schema cache so it picks up the new relationship
NOTIFY pgrst, 'reload schema';
