-- Migration: Complete Multi-Tenant SaaS Architecture
-- Description: Creates organizations + organization_members tables,
--              upgrades RLS policies to membership-based isolation,
--              adds performance indexes, and updates the signup trigger.
-- Date: 2024-03-15
-- IMPORTANT: Run this AFTER 20240305_multi_tenant_upgrade.sql
--
-- NOTE: Uses a SECURITY DEFINER function to avoid infinite recursion
--       when RLS policies on organization_members reference itself.

-- ============================================================
-- 1. CREATE TABLES (no policies yet)
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'free',
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

-- ============================================================
-- 2. SECURITY DEFINER HELPER FUNCTION
--    This bypasses RLS so policies can safely look up memberships
--    without triggering infinite recursion.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_user_org_ids()
RETURNS SETOF uuid AS $$
  SELECT organization_id
  FROM public.organization_members
  WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper to check if user is owner/admin in any of their orgs
CREATE OR REPLACE FUNCTION public.get_user_admin_org_ids()
RETURNS SETOF uuid AS $$
  SELECT organization_id
  FROM public.organization_members
  WHERE user_id = auth.uid()
    AND role IN ('owner', 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper to check if user has any membership at all
CREATE OR REPLACE FUNCTION public.user_has_membership()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- 3. RLS ON ORGANIZATIONS
-- ============================================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view their organization" ON organizations;
CREATE POLICY "Members can view their organization"
  ON organizations FOR SELECT
  USING (id IN (SELECT public.get_user_org_ids()));

DROP POLICY IF EXISTS "Owner can update organization" ON organizations;
CREATE POLICY "Owner can update organization"
  ON organizations FOR UPDATE
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Authenticated users can create organizations" ON organizations;
CREATE POLICY "Authenticated users can create organizations"
  ON organizations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- 4. RLS ON ORGANIZATION MEMBERS
-- ============================================================
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view org members" ON organization_members;
CREATE POLICY "Members can view org members"
  ON organization_members FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

DROP POLICY IF EXISTS "Owners can add members" ON organization_members;
CREATE POLICY "Owners can add members"
  ON organization_members FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_admin_org_ids())
    -- Allow self-insert during signup (user has no memberships yet)
    OR NOT public.user_has_membership()
  );

DROP POLICY IF EXISTS "Owners can remove members" ON organization_members;
CREATE POLICY "Owners can remove members"
  ON organization_members FOR DELETE
  USING (organization_id IN (SELECT public.get_user_admin_org_ids()));

DROP POLICY IF EXISTS "Owners can update member roles" ON organization_members;
CREATE POLICY "Owners can update member roles"
  ON organization_members FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_admin_org_ids()));

-- ============================================================
-- 5. UPGRADE RLS POLICIES ON ALL CRM TABLES
--    Replace weak profile-based policies with membership-based
-- ============================================================
DO $$
DECLARE
    t text;
    policy_name text;
BEGIN
    FOR t IN SELECT unnest(ARRAY['contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies', 'files'])
    LOOP
        -- Drop old weak policies from previous migration
        EXECUTE format('DROP POLICY IF EXISTS tenant_view_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_insert_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_update_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_delete_%s ON %I', t, t);

        -- Drop policies from this migration (in case re-running)
        EXECUTE format('DROP POLICY IF EXISTS mt_select_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS mt_insert_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS mt_update_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS mt_delete_%s ON %I', t, t);

        -- Also drop any other common policy names
        EXECUTE format('DROP POLICY IF EXISTS "Allow viewed by authenticated users" ON %I', t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow all for authenticated" ON %I', t);

        -- Ensure RLS is enabled
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);

        -- SELECT
        policy_name := format('mt_select_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR SELECT USING (
                organization_id IN (SELECT public.get_user_org_ids())
                OR organization_id IS NULL
            )', policy_name, t
        );

        -- INSERT
        policy_name := format('mt_insert_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR INSERT WITH CHECK (
                organization_id IN (SELECT public.get_user_org_ids())
                OR organization_id IS NULL
            )', policy_name, t
        );

        -- UPDATE
        policy_name := format('mt_update_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR UPDATE USING (
                organization_id IN (SELECT public.get_user_org_ids())
                OR organization_id IS NULL
            )', policy_name, t
        );

        -- DELETE
        policy_name := format('mt_delete_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR DELETE USING (
                organization_id IN (SELECT public.get_user_org_ids())
                OR organization_id IS NULL
            )', policy_name, t
        );
    END LOOP;
END $$;

-- ============================================================
-- 6. PERFORMANCE INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_leads_org_id ON leads(organization_id);
CREATE INDEX IF NOT EXISTS idx_contacts_org_id ON contacts(organization_id);
CREATE INDEX IF NOT EXISTS idx_deals_org_id ON deals(organization_id);
CREATE INDEX IF NOT EXISTS idx_tasks_org_id ON tasks(organization_id);
CREATE INDEX IF NOT EXISTS idx_activities_org_id ON activities(organization_id);
CREATE INDEX IF NOT EXISTS idx_notifications_org_id ON notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_companies_org_id ON companies(organization_id);
CREATE INDEX IF NOT EXISTS idx_files_org_id ON files(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON organization_members(user_id);

-- ============================================================
-- 7. HELPER FUNCTION: Create org + membership for a user
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_organization_for_user(
    org_name text,
    p_user_id uuid
)
RETURNS uuid AS $$
DECLARE
    new_org_id uuid;
BEGIN
    INSERT INTO organizations (name, owner_id)
    VALUES (org_name, p_user_id)
    RETURNING id INTO new_org_id;

    INSERT INTO organization_members (organization_id, user_id, role)
    VALUES (new_org_id, p_user_id, 'owner');

    UPDATE profiles
    SET organization_id = new_org_id
    WHERE id = p_user_id;

    RETURN new_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. UPDATE handle_new_user TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_org_id uuid;
    org_name text;
BEGIN
    INSERT INTO public.profiles (id, name, email, role)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'name',
        new.email,
        COALESCE(new.raw_user_meta_data->>'role', 'viewer')
    );

    org_name := COALESCE(
        new.raw_user_meta_data->>'organization_name',
        split_part(new.email, '@', 2) || ' Org'
    );

    INSERT INTO organizations (name, owner_id)
    VALUES (org_name, new.id)
    RETURNING id INTO new_org_id;

    INSERT INTO organization_members (organization_id, user_id, role)
    VALUES (new_org_id, new.id, 'owner');

    UPDATE profiles SET organization_id = new_org_id WHERE id = new.id;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 9. BACKFILL: Create orgs for existing users without one
-- ============================================================
DO $$
DECLARE
    r RECORD;
    new_org_id uuid;
BEGIN
    FOR r IN
        SELECT id, name, email
        FROM profiles
        WHERE organization_id IS NULL
    LOOP
        INSERT INTO organizations (name, owner_id)
        VALUES (COALESCE(r.name, split_part(r.email, '@', 2)) || '''s Organization', r.id)
        RETURNING id INTO new_org_id;

        INSERT INTO organization_members (organization_id, user_id, role)
        VALUES (new_org_id, r.id, 'owner');

        UPDATE profiles SET organization_id = new_org_id WHERE id = r.id;
    END LOOP;
END $$;
