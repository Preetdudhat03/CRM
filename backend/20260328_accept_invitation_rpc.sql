-- Migration: Secure Invitation Acceptance RPC
-- Description: Creates a secure RPC for accepting invitations atomically
-- Date: 2026-03-28

CREATE OR REPLACE FUNCTION public.accept_invitation(p_invite_id UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with privileges of the creator (postgres) to bypass RLS for this specific controlled operation
AS $$
DECLARE
    v_invite RECORD;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. Fetch the invitation, ensuring it matches the user's email and is pending
    SELECT * INTO v_invite
    FROM public.org_invites
    WHERE id = p_invite_id
      AND lower(email) = lower(auth.jwt() ->> 'email')
      AND status = 'pending';

    IF v_invite IS NULL THEN
        RAISE EXCEPTION 'Invitation not found or no longer pending for this user';
    END IF;

    -- 2. Insert the user into organization_members
    -- We use ON CONFLICT DO NOTHING to prevent errors if they are already a member
    INSERT INTO public.organization_members (organization_id, user_id, role)
    VALUES (v_invite.organization_id, v_user_id, v_invite.role)
    ON CONFLICT (organization_id, user_id) DO NOTHING;

    -- 3. Update the user's profile to set their active organization
    UPDATE public.profiles
    SET organization_id = v_invite.organization_id
    WHERE id = v_user_id;

    -- 4. Mark the invitation as accepted
    UPDATE public.org_invites
    SET status = 'accepted'
    WHERE id = p_invite_id;

    RETURN true;
END;
$$;
