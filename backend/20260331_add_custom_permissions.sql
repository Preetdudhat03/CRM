-- =====================================================================================
-- PHASE 10: CUSTOM PERMISSIONS & SECURE ADMIN UPDATES
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
-- This uses SECURITY DEFINER to allow admins to update other users' metadata.
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
        custom_permissions = new_custom_permissions, -- NULL means reset to role defaults
        updated_at = NOW()
    WHERE id = target_user_id
    RETURNING to_jsonb(public.profiles.*) INTO v_updated_profile;

    IF v_updated_profile IS NULL THEN
        RAISE EXCEPTION 'User profile not found.';
    END IF;

    RETURN v_updated_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. UPDATE RLS POLICIES TO USE GRANULAR PERMISSIONS
-- We drop old role-based policies and replace them with permission-based ones.

-- CONTACTS
DROP POLICY IF EXISTS "Employees and above can create contacts" ON contacts;
DROP POLICY IF EXISTS "Employees and above can update contacts" ON contacts;
DROP POLICY IF EXISTS "Only admins can delete contacts" ON contacts;

CREATE POLICY "Permission-based creation of contacts" ON contacts
  FOR INSERT WITH CHECK (public.has_permission('createContacts'));

CREATE POLICY "Permission-based update of contacts" ON contacts
  FOR UPDATE USING (public.has_permission('editContacts'));

CREATE POLICY "Permission-based deletion of contacts" ON contacts
  FOR DELETE USING (public.has_permission('deleteContacts'));

-- LEADS
DROP POLICY IF EXISTS "Employees and above can create leads" ON leads;
DROP POLICY IF EXISTS "Employees and above can update leads" ON leads;
DROP POLICY IF EXISTS "Only admins can delete leads" ON leads;

CREATE POLICY "Permission-based creation of leads" ON leads
  FOR INSERT WITH CHECK (public.has_permission('createLeads'));

CREATE POLICY "Permission-based update of leads" ON leads
  FOR UPDATE USING (public.has_permission('editLeads'));

CREATE POLICY "Permission-based deletion of leads" ON leads
  FOR DELETE USING (public.has_permission('deleteLeads'));

-- DEALS
DROP POLICY IF EXISTS "Employees and above can create deals" ON deals;
DROP POLICY IF EXISTS "Employees and above can update deals" ON deals;
DROP POLICY IF EXISTS "Only admins can delete deals" ON deals;

CREATE POLICY "Permission-based creation of deals" ON deals
  FOR INSERT WITH CHECK (public.has_permission('createDeals'));

CREATE POLICY "Permission-based update of deals" ON deals
  FOR UPDATE USING (public.has_permission('editDeals'));

CREATE POLICY "Permission-based deletion of deals" ON deals
  FOR DELETE USING (public.has_permission('deleteDeals'));

-- TASKS
DROP POLICY IF EXISTS "Employees and above can create tasks" ON tasks;
DROP POLICY IF EXISTS "Employees and above can update tasks" ON tasks;
DROP POLICY IF EXISTS "Managers and above can delete tasks" ON tasks;

CREATE POLICY "Permission-based creation of tasks" ON tasks
  FOR INSERT WITH CHECK (public.has_permission('createTasks'));

CREATE POLICY "Permission-based update of tasks" ON tasks
  FOR UPDATE USING (public.has_permission('editTasks'));

CREATE POLICY "Permission-based deletion of tasks" ON tasks
  FOR DELETE USING (public.has_permission('deleteTasks'));

-- ACTIVITIES
DROP POLICY IF EXISTS "Employees and above can manage activities" ON activities;

CREATE POLICY "Permission-based management of activities" ON activities
  FOR ALL USING (public.has_permission('editTasks') OR public.has_permission('createTasks')); 
  -- Activities often follow Task/Contact permissions. Given the system, we simplify to 'editTasks' or 'createTasks' for basic management.

-- ==================== PROFILES POLICIES (Refinement) ====================
-- Ensure we don't lock ourselves out.
DROP POLICY IF EXISTS "Users update self or admins update any" ON profiles;

-- VIEW: Everyone can view profiles (needed for assigning users to tasks/leads)
-- (Already defined in 20240502_enforce_iam_rls.sql, but we ensure it remains for SELECT)

-- UPDATE: Self OR Admin/SuperAdmin (using manageUsers permission)
CREATE POLICY "Users update self or admins manage others" ON profiles
  FOR UPDATE USING (
    id = auth.uid() OR public.has_permission('manageUsers')
  );

-- Ensure schema cache is refreshed
NOTIFY pgrst, 'reload schema';


