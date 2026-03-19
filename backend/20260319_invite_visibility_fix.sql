-- Migration: Invitation Visibility Fix
-- Description: Adds a SELECT policy to allow users to see invitations sent to them.
-- Date: 2026-03-19

-- 4. Allow invitees to VIEW their pending invitations
DROP POLICY IF EXISTS "Invitees can view their own invitations" ON public.org_invites;
CREATE POLICY "Invitees can view their own invitations"
    ON public.org_invites FOR SELECT
    USING (
        email = (auth.jwt() ->> 'email')
    );

-- Also ensure the admin policy is robust
DROP POLICY IF EXISTS "Admins can view org invites" ON public.org_invites;
CREATE POLICY "Admins can view org invites"
    ON public.org_invites FOR SELECT
    USING (organization_id IN (SELECT public.get_user_admin_org_ids()));
