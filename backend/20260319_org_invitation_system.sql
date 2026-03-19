-- Migration: Organization Invitation System
-- Description: Adds org_invites table and updates handle_new_user trigger 
--              to support invite-based onboarding vs fresh org creation.
-- Date: 2026-03-19

-- ============================================================
-- 1. CREATE INVITATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.org_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    inviter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    token UUID DEFAULT gen_random_uuid(),
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'manager', 'employee', 'viewer')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    UNIQUE(organization_id, email, status) -- Prevent duplicate pending invites for same user to same org
);

-- Index for lookup by token
CREATE INDEX IF NOT EXISTS idx_org_invites_token ON public.org_invites(token);
CREATE INDEX IF NOT EXISTS idx_org_invites_email ON public.org_invites(email);

-- ============================================================
-- 2. ENABLE RLS ON INVITATIONS
-- ============================================================
ALTER TABLE public.org_invites ENABLE ROW LEVEL SECURITY;

-- Admins can view/manage invites for their orgs
CREATE POLICY "Admins can view org invites"
    ON public.org_invites FOR SELECT
    USING (organization_id IN (SELECT public.get_user_admin_org_ids()));

CREATE POLICY "Admins can create org invites"
    ON public.org_invites FOR INSERT
    WITH CHECK (organization_id IN (SELECT public.get_user_admin_org_ids()));

CREATE POLICY "Admins can delete org invites"
    ON public.org_invites FOR DELETE
    USING (organization_id IN (SELECT public.get_user_admin_org_ids()));

-- ============================================================
-- 3. UPDATE handle_new_user TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_org_id uuid;
    org_name text;
    invite_token uuid;
    found_invite_id uuid;
    found_org_id uuid;
    found_role text;
BEGIN
    -- Create initial profile
    INSERT INTO public.profiles (id, name, email, role)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'name',
        new.email,
        COALESCE(new.raw_user_meta_data->>'role', 'viewer')
    );

    -- Check for invitation token in metadata
    invite_token := (new.raw_user_meta_data->>'invite_token')::uuid;

    IF invite_token IS NOT NULL THEN
        -- Find pending invite
        SELECT id, organization_id, role INTO found_invite_id, found_org_id, found_role
        FROM public.org_invites
        WHERE token = invite_token AND status = 'pending' AND expires_at > NOW()
        LIMIT 1;

        IF found_invite_id IS NOT NULL THEN
            -- Join existing organization
            INSERT INTO public.organization_members (organization_id, user_id, role)
            VALUES (found_org_id, new.id, found_role);

            -- Mark invite as accepted
            UPDATE public.org_invites SET status = 'accepted' WHERE id = found_invite_id;

            -- Set as active organization
            UPDATE public.profiles SET organization_id = found_org_id WHERE id = new.id;
            
            RETURN new;
        END IF;
    END IF;

    -- Default: Create NEW organization (Primary SaaS Flow)
    org_name := COALESCE(
        new.raw_user_meta_data->>'organization_name',
        split_part(new.email, '@', 2) || ' Org'
    );

    INSERT INTO public.organizations (name, owner_id)
    VALUES (org_name, new.id)
    RETURNING id INTO new_org_id;

    INSERT INTO public.organization_members (organization_id, user_id, role)
    VALUES (new_org_id, new.id, 'owner');

    UPDATE public.profiles SET organization_id = new_org_id WHERE id = new.id;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. UTILITY FUNCTIONS
-- ============================================================

-- Function to switch active organization
CREATE OR REPLACE FUNCTION public.switch_active_organization(p_org_id uuid)
RETURNS void AS $$
BEGIN
    -- Verify user is actually a member
    IF EXISTS (
        SELECT 1 FROM public.organization_members 
        WHERE user_id = auth.uid() AND organization_id = p_org_id
    ) THEN
        UPDATE public.profiles SET organization_id = p_org_id WHERE id = auth.uid();
    ELSE
        RAISE EXCEPTION 'User is not a member of this organization';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
