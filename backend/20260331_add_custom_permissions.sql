-- =====================================================================================
-- PHASE 11: GLOBAL SECURITY PURGE & GRANULAR LOCKDOWN
-- =====================================================================================

-- 1. ADD CUSTOM PERMISSIONS COLUMN TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_permissions TEXT[];

-- 2. CREATE HELPER FUNCTION TO CHECK GRANULAR PERMISSIONS
CREATE OR REPLACE FUNCTION public.has_permission(requested_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_custom_perms TEXT[];
    v_role_perms TEXT[];
BEGIN
    -- Get user's role and custom permissions
    SELECT LOWER(role), custom_permissions INTO v_user_role, v_custom_perms
    FROM public.profiles
    WHERE id = auth.uid();

    -- If no user profile found, deny access
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Case 1: Custom Permissions are set (Not NULL)
    -- This means they OVERRIDE the role defaults.
    IF v_custom_perms IS NOT NULL THEN
        RETURN requested_permission = ANY(v_custom_perms);
    END IF;

    -- Case 2: No custom permissions, fallback to Role Defaults
    CASE v_user_role
        WHEN 'superadmin' THEN 
            RETURN TRUE; -- All access
        WHEN 'admin' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'createContacts', 'editContacts', 'deleteContacts',
                'viewLeads', 'createLeads', 'editLeads', 'deleteLeads',
                'viewDeals', 'createDeals', 'editDeals', 'deleteDeals',
                'viewTasks', 'createTasks', 'editTasks', 'deleteTasks',
                'viewAnalytics', 'manageUsers'
            ];
        WHEN 'manager' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'createContacts', 'editContacts',
                'viewLeads', 'createLeads', 'editLeads',
                'viewDeals', 'createDeals', 'editDeals',
                'viewTasks', 'createTasks', 'editTasks', 'deleteTasks',
                'viewAnalytics'
            ];
        WHEN 'employee' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'createContacts', 'editContacts',
                'viewLeads', 'createLeads', 'editLeads',
                'viewDeals', 'createDeals', 'editDeals',
                'viewTasks', 'createTasks', 'editTasks'
            ];
        WHEN 'viewer' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'viewLeads', 'viewDeals', 'viewTasks'
            ];
        ELSE
            v_role_perms := ARRAY[]::TEXT[];
    END CASE;

    RETURN requested_permission = ANY(v_role_perms);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CREATE SECURE ADMIN RPC FOR UPDATING PROFILES
CREATE OR REPLACE FUNCTION public.admin_update_profile(
    target_user_id UUID,
    new_name TEXT,
    new_role TEXT,
    new_custom_permissions TEXT[]
)
RETURNS JSONB AS $$
DECLARE
    v_is_authorized BOOLEAN;
    v_updated_profile JSONB;
BEGIN
    -- Check if the caller is an admin or superAdmin
    SELECT (LOWER(role) = 'admin' OR LOWER(role) = 'superadmin') INTO v_is_authorized
    FROM public.profiles
    WHERE id = auth.uid();

    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'Unauthorized: Only admins can update user profiles.';
    END IF;

    -- Update the profile
    UPDATE public.profiles
    SET 
        name = COALESCE(new_name, name),
        role = COALESCE(new_role, role),
        custom_permissions = new_custom_permissions,
        updated_at = NOW()
    WHERE id = target_user_id
    RETURNING to_jsonb(public.profiles.*) INTO v_updated_profile;

    IF v_updated_profile IS NULL THEN
        RAISE EXCEPTION 'User profile not found.';
    END IF;

    RETURN v_updated_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. AGGRESSIVE DYNAMIC POLICY PURGE
-- This queries the database for EVERY policy on the target tables and DROPS them.
DO $$
DECLARE
    r record;
    tables_to_purge text[] := ARRAY['contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies', 'files'];
    t text;
BEGIN
    FOREACH t IN ARRAY tables_to_purge
    LOOP
        -- Find all policies for the table and drop them
        FOR r IN (
            SELECT policyname 
            FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = t
        ) LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, t);
        END LOOP;
        
        -- Disable and then Re-Enable RLS to clear the "dirty" state
        EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- 5. IMPLEMENT NEW ORG + PERMISSION POLICIES (THE LOCKDOWN)

-- CONTACTS
CREATE POLICY "SECURE_SELECT_contacts" ON contacts FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewContacts'));
CREATE POLICY "SECURE_INSERT_contacts" ON contacts FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createContacts'));
CREATE POLICY "SECURE_UPDATE_contacts" ON contacts FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editContacts'));
CREATE POLICY "SECURE_DELETE_contacts" ON contacts FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteContacts'));

-- LEADS
CREATE POLICY "SECURE_SELECT_leads" ON leads FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewLeads'));
CREATE POLICY "SECURE_INSERT_leads" ON leads FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createLeads'));
CREATE POLICY "SECURE_UPDATE_leads" ON leads FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editLeads'));
CREATE POLICY "SECURE_DELETE_leads" ON leads FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteLeads'));

-- DEALS
CREATE POLICY "SECURE_SELECT_deals" ON deals FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewDeals'));
CREATE POLICY "SECURE_INSERT_deals" ON deals FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createDeals'));
CREATE POLICY "SECURE_UPDATE_deals" ON deals FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editDeals'));
CREATE POLICY "SECURE_DELETE_deals" ON deals FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteDeals'));

-- TASKS
CREATE POLICY "SECURE_SELECT_tasks" ON tasks FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewTasks'));
CREATE POLICY "SECURE_INSERT_tasks" ON tasks FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createTasks'));
CREATE POLICY "SECURE_UPDATE_tasks" ON tasks FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editTasks'));
CREATE POLICY "SECURE_DELETE_tasks" ON tasks FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteTasks'));

-- COMPANIES
CREATE POLICY "SECURE_SELECT_companies" ON companies FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewContacts'));
CREATE POLICY "SECURE_INSERT_companies" ON companies FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createContacts'));
CREATE POLICY "SECURE_UPDATE_companies" ON companies FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editContacts'));
CREATE POLICY "SECURE_DELETE_companies" ON companies FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteContacts'));

-- ACTIVITIES
CREATE POLICY "SECURE_SELECT_activities" ON activities FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "SECURE_INSERT_activities" ON activities FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND (public.has_permission('createLeads') OR public.has_permission('createContacts') OR public.has_permission('createTasks')));

-- FILES (Using Contacts Permissions as Proxy)
CREATE POLICY "SECURE_SELECT_files" ON files FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewContacts'));
CREATE POLICY "SECURE_INSERT_files" ON files FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createContacts'));
CREATE POLICY "SECURE_DELETE_files" ON files FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteContacts'));

-- 6. PROFILES TABLE REFINEMENT
-- Purge existing profiles policies
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname);
    END LOOP;
END $$;

CREATE POLICY "SECURE_SELECT_profiles" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "SECURE_UPDATE_profiles_self_or_admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Security check
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

-- 7. DEBUGGING TOOL
-- Run `SELECT * FROM public.check_my_security_status();`
CREATE OR REPLACE FUNCTION public.check_my_security_status()
RETURNS TABLE (
    table_name text,
    rls_enabled boolean,
    policies_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::text,
        t.relrowsecurity,
        (SELECT count(*) FROM pg_policies p WHERE p.tablename = t.tablename AND p.schemaname = 'public')
    FROM pg_tables t
    JOIN pg_class c ON c.relname = t.tablename
    WHERE t.schemaname = 'public' 
    AND t.tablename IN ('contacts', 'leads', 'deals', 'tasks', 'activities', 'companies', 'profiles');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';
