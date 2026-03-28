-- Migration: Fix RLS for Organization Invitations
-- Description: Makes invitation checks case-insensitive and adds UPSERT support 
--              for joining organizations.
-- Date: 2026-03-28

-- 1. Enable Row-Level Security on organization_members
-- (Should already be enabled, but reinforcing it)
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing join policies to re-create them cleanly
DROP POLICY IF EXISTS "Users can join via invitation" ON public.organization_members;
DROP POLICY IF EXISTS "Users can join or update via invitation" ON public.organization_members;

-- 3. Create a robust policy for organization_members
-- Allows SELECT, INSERT, and UPDATE (for upsert) if:
--   - The user is already a member (user_id = auth.uid())
--   - The user has a pending invitation matching their email (CASE-INSENSITIVE)
CREATE POLICY "Users can join or update via invitation" ON public.organization_members
    FOR ALL 
    USING (
        (user_id = auth.uid()) 
        OR 
        EXISTS (
            SELECT 1 FROM public.org_invites
            WHERE organization_id = organization_members.organization_id
            AND LOWER(email) = LOWER(auth.jwt() ->> 'email')
            AND status = 'pending'
        )
    )
    WITH CHECK (
        (user_id = auth.uid())
        OR 
        EXISTS (
            SELECT 1 FROM public.org_invites
            WHERE organization_id = organization_members.organization_id
            AND LOWER(email) = LOWER(auth.jwt() ->> 'email')
            AND status = 'pending'
        )
    );

-- 4. Update the invitation update policy to be case-insensitive
DROP POLICY IF EXISTS "Invitees can update their invitation status" ON public.org_invites;
CREATE POLICY "Invitees can update their invitation status" ON public.org_invites
    FOR UPDATE 
    USING (
        LOWER(email) = LOWER(auth.jwt() ->> 'email')
    )
    WITH CHECK (
        LOWER(email) = LOWER(auth.jwt() ->> 'email')
    );

-- 5. Verify profiles SELECT policy (needed to see names/emails)
-- Make sure a user can see their own profile and profiles of fellow members.
DROP POLICY IF EXISTS "Profiles are viewable by fellow members" ON public.profiles;
CREATE POLICY "Profiles are viewable by fellow members" ON public.profiles
    FOR SELECT
    USING (
        id = auth.uid() -- Can see self
        OR
        EXISTS ( -- Can see members of organizations I belong to
            SELECT 1 FROM public.organization_members
            WHERE organization_id = profiles.organization_id
            AND user_id = auth.uid()
        )
    );

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
