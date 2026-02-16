-- Add avatar_url column to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- We already have permissions for 'profiles' update via admin/self.
-- So no new policy needed for the column itself.
