-- Migration: Organization Exit Features (Leave & Delete)
-- Description: Adds RPC functions to safely leave or delete an organization.
-- Date: 2026-03-19

-- ============================================================
-- 1. FUNCTION: delete_organization
--    Safely purges all data related to an organization and 
--    the organization record itself.
-- ============================================================
CREATE OR REPLACE FUNCTION public.delete_organization(p_org_id uuid)
RETURNS void AS $$
DECLARE
    v_member_record RECORD;
BEGIN
    -- 1. Check if current user is owner (Auth Check)
    IF NOT EXISTS (
        SELECT 1 FROM public.organizations 
        WHERE id = p_org_id AND owner_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Only the owner can delete the organization';
    END IF;

    -- 2. Delete data from all CRM tables (Manual cleanup for tables without CASCADE)
    DELETE FROM public.contacts WHERE organization_id = p_org_id;
    DELETE FROM public.leads WHERE organization_id = p_org_id;
    DELETE FROM public.deals WHERE organization_id = p_org_id;
    DELETE FROM public.tasks WHERE organization_id = p_org_id;
    DELETE FROM public.activities WHERE organization_id = p_org_id;
    DELETE FROM public.notifications WHERE organization_id = p_org_id;
    DELETE FROM public.companies WHERE organization_id = p_org_id;
    DELETE FROM public.files WHERE organization_id = p_org_id;
    DELETE FROM public.org_invites WHERE organization_id = p_org_id;

    -- 3. Update profiles for all members before they lose access
    --    This ensures their next login/session doesn't point to a dead org.
    FOR v_member_record IN (SELECT user_id FROM public.organization_members WHERE organization_id = p_org_id)
    LOOP
        UPDATE public.profiles 
        SET organization_id = (
            SELECT organization_id 
            FROM public.organization_members 
            WHERE user_id = v_member_record.user_id 
              AND organization_id != p_org_id
            LIMIT 1
        )
        WHERE id = v_member_record.user_id;
    END LOOP;

    -- 4. Delete the organization (cascades to organization_members)
    DELETE FROM public.organizations WHERE id = p_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. FUNCTION: leave_organization
--    Allows a user to remove their own membership safely.
-- ============================================================
CREATE OR REPLACE FUNCTION public.leave_organization(p_org_id uuid)
RETURNS void AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_role text;
    v_owner_count int;
    v_next_org_id uuid;
BEGIN
    -- 1. Get current user's role in the org
    SELECT role INTO v_role 
    FROM public.organization_members 
    WHERE organization_id = p_org_id AND user_id = v_user_id;

    IF v_role IS NULL THEN
        RAISE EXCEPTION 'Not a member of this organization';
    END IF;

    -- 2. If user is owner, ensure they aren't the ONLY owner
    IF v_role = 'owner' THEN
        SELECT count(*) INTO v_owner_count 
        FROM public.organization_members 
        WHERE organization_id = p_org_id AND role = 'owner';

        IF v_owner_count <= 1 THEN
            RAISE EXCEPTION 'You are the only owner. You must transfer ownership or delete the organization instead.';
        END IF;
    END IF;

    -- 3. Remove membership
    DELETE FROM public.organization_members 
    WHERE organization_id = p_org_id AND user_id = v_user_id;

    -- 4. Find another organization to set as active in profile
    SELECT organization_id INTO v_next_org_id
    FROM public.organization_members 
    WHERE user_id = v_user_id 
    LIMIT 1;

    UPDATE public.profiles 
    SET organization_id = v_next_org_id
    WHERE id = v_user_id AND (organization_id = p_org_id OR organization_id IS NULL);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
