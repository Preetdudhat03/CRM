-- Migration: Invitation Acceptance Security
-- Description: Updates RLS policies to allow users to accept invitations
-- Date: 2026-03-19

-- 1. Allow users to join an organization for which they have a pending invite
DROP POLICY IF EXISTS "Users can join via invitation" ON public.organization_members;
CREATE POLICY "Users can join via invitation" ON public.organization_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.org_invites
            WHERE organization_id = organization_members.organization_id
            AND email = (auth.jwt() ->> 'email')
            AND status = 'pending'
        )
        OR NOT public.user_has_membership() -- Keep existing self-signup logic
    );

-- 2. Allow invitees to update their invitation status (e.g. to 'accepted')
DROP POLICY IF EXISTS "Invitees can update their invitation status" ON public.org_invites;
CREATE POLICY "Invitees can update their invitation status" ON public.org_invites
    FOR UPDATE USING (
        email = (auth.jwt() ->> 'email')
    );

-- 3. Verify organization_members SELECT allows viewing multi-orgs (already does via get_user_org_ids)
-- No changes needed there.
