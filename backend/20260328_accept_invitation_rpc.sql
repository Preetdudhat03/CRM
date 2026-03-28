-- Migration: Atomic Invitation Acceptance (v2 - Self-Cleaning)
-- Description: Handles organization membership, profile updates, and invitation cleanup.
--              Specifically resolves the 23505 Unique Constraint violation by 
--              deleting redundant pending invitations once one is accepted.
-- Date: 2026-03-28

CREATE OR REPLACE FUNCTION accept_invitation(p_invite_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
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
        -- If already accepted or doesn't exist, we treat as success to avoid UI errors
        RETURN true; 
    END IF;

    -- 2. Join the organization (if not already a member)
    INSERT INTO public.organization_members (organization_id, user_id, role)
    VALUES (v_invite.organization_id, v_user_id, v_invite.role)
    ON CONFLICT (organization_id, user_id) DO NOTHING;

    -- 3. Set as active organization in the user's profile
    UPDATE public.profiles
    SET organization_id = v_invite.organization_id
    WHERE id = v_user_id;

    -- 4. Mark THIS specific invitation as accepted
    -- We use a BEGIN/EXCEPTION block to handle cases where another invitation
    -- for the same email/org was already marked as 'accepted'
    BEGIN
        UPDATE public.org_invites
        SET status = 'accepted'
        WHERE id = p_invite_id;
    EXCEPTION WHEN unique_violation THEN
        -- If an 'accepted' record already exists, this one is redundant
        DELETE FROM public.org_invites WHERE id = p_invite_id;
    END;

    -- 5. DELETE all other redundant pending invitations for this user and organization
    DELETE FROM public.org_invites
    WHERE lower(email) = lower(v_invite.email)
      AND organization_id = v_invite.organization_id
      AND status = 'pending'
      AND id != p_invite_id;

    RETURN true;
END;
$$;
