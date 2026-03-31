-- =====================================================================================
-- PHASE 12: ROLE RECOVERY & ACCESSIBILITY FIX
-- =====================================================================================

-- 1. ADD CUSTOM PERMISSIONS COLUMN TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_permissions TEXT[];

-- 2. CREATE ROBUST HELPER FUNCTION TO CHECK GRANULAR PERMISSIONS
-- This function handles 'owner', 'admin', 'superadmin' and more.
CREATE OR REPLACE FUNCTION public.has_permission(requested_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_custom_perms TEXT[];
    v_role_perms TEXT[];
BEGIN
    -- Get user's role and custom permissions
    -- Using SECURITY DEFINER function to bypass any recursive RLS on profiles
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

    -- Case 2: Mapping roles to permissions
    -- Standardizing across CRM versions (Support for 'owner', 'admin', 'superadmin', etc.)
    CASE v_user_role
        WHEN 'owner', 'superadmin', 'superAdmin' THEN 
            RETURN TRUE; -- Full system access
        WHEN 'admin', 'administrator' THEN
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
        WHEN 'employee', 'staff' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'createContacts', 'editContacts',
                'viewLeads', 'createLeads', 'editLeads',
                'viewDeals', 'createDeals', 'editDeals',
                'viewTasks', 'createTasks', 'editTasks'
            ];
        WHEN 'viewer', 'guest' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'viewLeads', 'viewDeals', 'viewTasks'
            ];
        ELSE
            -- Fallback: If role is unrecognized, allow only viewing basics for safety
            v_role_perms := ARRAY['viewContacts', 'viewLeads', 'viewDeals', 'viewTasks'];
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
    -- Check if the caller is an admin or owner
    SELECT (LOWER(role) IN ('admin', 'owner', 'superadmin')) INTO v_is_authorized
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

-- 4. DYNAMIC POLICY PURGE (THE RESET)
DO $$
DECLARE
    r record;
    tables_to_purge text[] := ARRAY['contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies', 'files'];
    t text;
BEGIN
    FOREACH t IN ARRAY tables_to_purge
    LOOP
        FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = t) LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, t);
        END LOOP;
        
        -- Force re-enable RLS
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- 5. RE-IMPLEMENT COMPREHENSIVE ORG + PERMISSION POLICIES
-- Using the fixed has_permission() which now understands 'owner' role.

-- CONTACTS
CREATE POLICY "Contacts Select" ON contacts FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewContacts'));
CREATE POLICY "Contacts Insert" ON contacts FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createContacts'));
CREATE POLICY "Contacts Update" ON contacts FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editContacts'));
CREATE POLICY "Contacts Delete" ON contacts FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteContacts'));

-- LEADS
CREATE POLICY "Leads Select" ON leads FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewLeads'));
CREATE POLICY "Leads Insert" ON leads FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createLeads'));
CREATE POLICY "Leads Update" ON leads FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editLeads'));
CREATE POLICY "Leads Delete" ON leads FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteLeads'));

-- DEALS
CREATE POLICY "Deals Select" ON deals FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewDeals'));
CREATE POLICY "Deals Insert" ON deals FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createDeals'));
CREATE POLICY "Deals Update" ON deals FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editDeals'));
CREATE POLICY "Deals Delete" ON deals FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteDeals'));

-- TASKS
CREATE POLICY "Tasks Select" ON tasks FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewTasks'));
CREATE POLICY "Tasks Insert" ON tasks FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createTasks'));
CREATE POLICY "Tasks Update" ON tasks FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editTasks'));
CREATE POLICY "Tasks Delete" ON tasks FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteTasks'));

-- COMPANIES
CREATE POLICY "Companies Select" ON companies FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewContacts'));
CREATE POLICY "Companies Insert" ON companies FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createContacts'));
CREATE POLICY "Companies Update" ON companies FOR UPDATE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('editContacts'));
CREATE POLICY "Companies Delete" ON companies FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteContacts'));

-- ACTIVITIES
CREATE POLICY "Activities Select" ON activities FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Activities Insert" ON activities FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND (public.has_permission('createLeads') OR public.has_permission('createContacts') OR public.has_permission('createTasks')));

-- FILES (Using Contacts Permissions as Proxy)
CREATE POLICY "Files Select" ON files FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('viewContacts'));
CREATE POLICY "Files Insert" ON files FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('createContacts'));
CREATE POLICY "Files Delete" ON files FOR DELETE USING (organization_id IN (SELECT public.get_user_org_ids()) AND public.has_permission('deleteContacts'));

-- 6. PROFILES TABLE RESET
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname);
    END LOOP;
END $$;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

-- 7. RECOVERY CHECK FUNCTION
CREATE OR REPLACE FUNCTION public.check_my_security_status()
RETURNS TABLE (
    table_name text,
    rls_enabled boolean,
    policies_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tab.tablename::text,
        tab.relrowsecurity,
        (SELECT count(*) FROM pg_policies p WHERE p.tablename = tab.tablename AND p.schemaname = 'public')
    FROM pg_tables tab
    JOIN pg_class c ON c.relname = tab.tablename
    WHERE tab.schemaname = 'public' 
    AND tab.tablename IN ('contacts', 'leads', 'deals', 'tasks', 'activities', 'companies', 'profiles');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';
