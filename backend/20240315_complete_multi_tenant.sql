-- Migration: Complete Multi-Tenant SaaS Architecture
-- Description: Creates organizations + organization_members tables,
--              upgrades RLS policies to membership-based isolation,
--              adds performance indexes, and updates the signup trigger.
-- Date: 2024-03-15
-- IMPORTANT: Run this AFTER 20240305_multi_tenant_upgrade.sql

-- ============================================================
-- 1. ORGANIZATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  plan TEXT DEFAULT 'free',
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Org owners and members can view their org
CREATE POLICY "Members can view their organization"
  ON organizations FOR SELECT
  USING (
    id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

-- Only the owner can update the org
CREATE POLICY "Owner can update organization"
  ON organizations FOR UPDATE
  USING (owner_id = auth.uid());

-- Authenticated users can create organizations
CREATE POLICY "Authenticated users can create organizations"
  ON organizations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- 2. ORGANIZATION MEMBERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

-- Members can see other members in their org
CREATE POLICY "Members can view org members"
  ON organization_members FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members AS om
      WHERE om.user_id = auth.uid()
    )
  );

-- Org owners/admins can insert members
CREATE POLICY "Owners can add members"
  ON organization_members FOR INSERT
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM organization_members AS om
      WHERE om.user_id = auth.uid() AND om.role IN ('owner', 'admin')
    )
    -- Allow self-insert during signup (no existing membership)
    OR NOT EXISTS (
      SELECT 1 FROM organization_members WHERE user_id = auth.uid()
    )
  );

-- Owners can remove members
CREATE POLICY "Owners can remove members"
  ON organization_members FOR DELETE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members AS om
      WHERE om.user_id = auth.uid() AND om.role IN ('owner', 'admin')
    )
  );

-- Owners can update member roles
CREATE POLICY "Owners can update member roles"
  ON organization_members FOR UPDATE
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members AS om
      WHERE om.user_id = auth.uid() AND om.role IN ('owner', 'admin')
    )
  );

-- ============================================================
-- 3. UPGRADE RLS POLICIES ON ALL CRM TABLES
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

        -- Also drop any other common policy names
        EXECUTE format('DROP POLICY IF EXISTS "Allow viewed by authenticated users" ON %I', t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow all for authenticated" ON %I', t);

        -- Ensure RLS is enabled
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);

        -- SELECT: user sees rows matching their org membership, OR rows with NULL org_id (backward compat)
        policy_name := format('mt_select_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR SELECT USING (
                organization_id IN (
                    SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
                )
                OR organization_id IS NULL
            )', policy_name, t
        );

        -- INSERT: user can insert rows matching their org membership
        policy_name := format('mt_insert_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR INSERT WITH CHECK (
                organization_id IN (
                    SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
                )
                OR organization_id IS NULL
            )', policy_name, t
        );

        -- UPDATE: same tenant check
        policy_name := format('mt_update_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR UPDATE USING (
                organization_id IN (
                    SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
                )
                OR organization_id IS NULL
            )', policy_name, t
        );

        -- DELETE: same tenant check
        policy_name := format('mt_delete_%s', t);
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR DELETE USING (
                organization_id IN (
                    SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
                )
                OR organization_id IS NULL
            )', policy_name, t
        );
    END LOOP;
END $$;

-- ============================================================
-- 4. PERFORMANCE INDEXES
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
-- 5. HELPER FUNCTION: Create org + membership for a user
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_organization_for_user(
    org_name text,
    p_user_id uuid
)
RETURNS uuid AS $$
DECLARE
    new_org_id uuid;
BEGIN
    -- Create the organization
    INSERT INTO organizations (name, owner_id)
    VALUES (org_name, p_user_id)
    RETURNING id INTO new_org_id;

    -- Add user as owner member
    INSERT INTO organization_members (organization_id, user_id, role)
    VALUES (new_org_id, p_user_id, 'owner');

    -- Update profile with organization_id for backward compatibility
    UPDATE profiles
    SET organization_id = new_org_id
    WHERE id = p_user_id;

    RETURN new_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. UPDATE handle_new_user TRIGGER
--    Auto-create an organization for every new signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_org_id uuid;
    org_name text;
BEGIN
    -- Insert profile
    INSERT INTO public.profiles (id, name, email, role)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'name',
        new.email,
        COALESCE(new.raw_user_meta_data->>'role', 'viewer')
    );

    -- Determine org name from metadata, or use email domain
    org_name := COALESCE(
        new.raw_user_meta_data->>'organization_name',
        split_part(new.email, '@', 2) || ' Org'
    );

    -- Create organization and membership
    INSERT INTO organizations (name, owner_id)
    VALUES (org_name, new.id)
    RETURNING id INTO new_org_id;

    INSERT INTO organization_members (organization_id, user_id, role)
    VALUES (new_org_id, new.id, 'owner');

    -- Update profile with org id
    UPDATE profiles SET organization_id = new_org_id WHERE id = new.id;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. BACKFILL: Create orgs for existing users without one
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
