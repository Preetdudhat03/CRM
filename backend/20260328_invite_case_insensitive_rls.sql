-- Migration: Case-Insensitive Invitation Visibility
-- Description: Updates RLS policies for org_invites to be case-insensitive for emails.
-- Date: 2026-03-28

-- 1. Update the Invitee SELECT policy to be case-insensitive
DROP POLICY IF EXISTS "Invitees can view their own invitations" ON public.org_invites;
CREATE POLICY "Invitees can view their own invitations"
    ON public.org_invites FOR SELECT
    USING (
        lower(email) = lower(auth.jwt() ->> 'email')
    );

-- 2. Update the Invitee UPDATE policy (for status changes if any) to be case-insensitive
DROP POLICY IF EXISTS "Invitees can update their invitation status" ON public.org_invites;
CREATE POLICY "Invitees can update their invitation status"
    ON public.org_invites FOR UPDATE
    USING (
        lower(email) = lower(auth.jwt() ->> 'email')
    );
