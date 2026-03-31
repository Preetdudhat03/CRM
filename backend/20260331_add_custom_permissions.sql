-- =====================================================================================
-- PHASE 10: FULL SECURITY LOCKDOWN (GRANULAR PERMISSIONS + ORG ISOLATION)
-- =====================================================================================

-- 1. ADD CUSTOM PERMISSIONS COLUMN TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_permissions TEXT[];

-- 2. CREATE HELPER FUNCTION TO CHECK GRANULAR PERMISSIONS
-- This function checks if a user has a permission based on:
-- a) Their custom_permissions (if set)
-- b) Their default role permissions (if custom_permissions is NULL)
CREATE OR REPLACE FUNCTION public.has_permission(requested_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_custom_perms TEXT[];
    v_role_perms TEXT[];
BEGIN
    -- Get user's role and custom permissions
    SELECT role, custom_permissions INTO v_user_role, v_custom_perms
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
    -- Mapping roles to permissions (Matching Dart RoleExtension logic)
    CASE v_user_role
        WHEN 'superAdmin' THEN 
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
    SELECT (role = 'admin' OR role = 'superAdmin') INTO v_is_authorized
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

-- 4. SYSTEMATICALLY DROP ALL LEGACY CRM POLICIES
-- This ensures no "leaky" policies remain that bypass our new checks.
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT unnest(ARRAY['contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies', 'files'])
    LOOP
        -- Drop old name patterns (mt_*, Leads access policy, tenant_*, etc.)
        EXECUTE format('DROP POLICY IF EXISTS "Leads access policy" ON %I', t);
        EXECUTE format('DROP POLICY IF EXISTS "Contacts access policy" ON %I', t);
        EXECUTE format('DROP POLICY IF EXISTS mt_select_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS mt_insert_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS mt_update_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS mt_delete_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_view_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_insert_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_update_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS tenant_delete_%s ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Permission-based creation of %s" ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Permission-based update of %s" ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Permission-based deletion of %s" ON %I', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Permission-based management of %s" ON %I', t, t);
        
        -- Enable RLS
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- 5. IMPLEMENT NEW ORG + PERMISSION POLICIES

-- Helper to check Org Isolation AND Permission
-- Standardize mapping for tables that don't have explicit Permissions (like Companies)
-- Using 'viewContacts' as proxy for 'companies' and 'files'.

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

-- COMPANIES (Using Contacts Permissions as Proxy)
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

-- 6. PROFILES TABLE REFINEMENT
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;
DROP POLICY IF EXISTS "Users update self or admins manage others" ON profiles;
DROP POLICY IF EXISTS "All users can view profiles" ON profiles;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check for RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';































-- 6. PROFILES TABLE REFINEMENT
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;
DROP POLICY IF EXISTS "Users update self or admins manage others" ON profiles;
DROP POLICY IF EXISTS "All users can view profiles" ON profiles;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check for RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';



-- 6. PROFILES TABLE REFINEMENT
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;
DROP POLICY IF EXISTS "Users update self or admins manage others" ON profiles;
DROP POLICY IF EXISTS "All users can view profiles" ON profiles;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check for RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';


-- 6. PROFILES TABLE REFINEMENT
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;
DROP POLICY IF EXISTS "Users update self or admins manage others" ON profiles;
DROP POLICY IF EXISTS "All users can view profiles" ON profiles;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check for RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';

-- 6. PROFILES TABLE REFINEMENT
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;
DROP POLICY IF EXISTS "Users update self or admins manage others" ON profiles;
DROP POLICY IF EXISTS "All users can view profiles" ON profiles;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check for RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';-- 6. PROFILES TABLE REFINEMENT
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;
DROP POLICY IF EXISTS "Users update self or admins manage others" ON profiles;
DROP POLICY IF EXISTS "All users can view profiles" ON profiles;

CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()));
CREATE POLICY "Profiles Update Self or Admin" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check for RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';

