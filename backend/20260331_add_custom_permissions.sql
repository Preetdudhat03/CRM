-- =====================================================================================
-- PHASE 14: IDEMPOTENT SECURITY LOCKDOWN (RE-RUNNABLE FIX)
-- =====================================================================================

-- 1. ADD CUSTOM PERMISSIONS COLUMN TO PROFILES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_permissions TEXT[];

-- 2. ENHANCED HELPER FUNCTION TO CHECK GRANULAR PERMISSIONS
CREATE OR REPLACE FUNCTION public.has_permission(requested_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_custom_perms TEXT[];
    v_role_perms TEXT[];
BEGIN
    SELECT LOWER(role), custom_permissions INTO v_user_role, v_custom_perms
    FROM public.profiles
    WHERE id = auth.uid();

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_custom_perms IS NOT NULL THEN
        RETURN requested_permission = ANY(v_custom_perms);
    END IF;

    CASE v_user_role
        WHEN 'owner', 'superadmin', 'superAdmin' THEN 
            RETURN TRUE; 
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
        WHEN 'employee', 'staff', 'member' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'createContacts', 'editContacts',
                'viewLeads', 'createLeads', 'editLeads',
                'viewDeals', 'createDeals', 'editDeals',
                'viewTasks', 'createTasks', 'editTasks'
            ];
        WHEN 'viewer', 'guest', 'user' THEN
            v_role_perms := ARRAY[
                'viewContacts', 'viewLeads', 'viewDeals', 'viewTasks'
            ];
        ELSE
            v_role_perms := ARRAY['viewContacts', 'viewLeads', 'viewDeals', 'viewTasks'];
    END CASE;

    RETURN requested_permission = ANY(v_role_perms);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. DYNAMIC POLICY PURGE (THE RESET)
-- This loop clears ALL policies on CRM tables to ensure no naming conflicts.
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN (
        SELECT policyname, tablename 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename IN ('contacts', 'leads', 'deals', 'tasks', 'activities', 'notifications', 'companies', 'files', 'profiles')
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- 4. RE-IMPLEMENT POLICIES (Idempotent: DROP then CREATE)

-- CONTACTS
DROP POLICY IF EXISTS "Contacts Select" ON contacts;
CREATE POLICY "Contacts Select" ON contacts FOR SELECT USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('viewContacts'));
DROP POLICY IF EXISTS "Contacts Insert" ON contacts;
CREATE POLICY "Contacts Insert" ON contacts FOR INSERT WITH CHECK ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('createContacts'));
DROP POLICY IF EXISTS "Contacts Update" ON contacts;
CREATE POLICY "Contacts Update" ON contacts FOR UPDATE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('editContacts'));
DROP POLICY IF EXISTS "Contacts Delete" ON contacts;
CREATE POLICY "Contacts Delete" ON contacts FOR DELETE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('deleteContacts'));

-- LEADS
DROP POLICY IF EXISTS "Leads Select" ON leads;
CREATE POLICY "Leads Select" ON leads FOR SELECT USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('viewLeads'));
DROP POLICY IF EXISTS "Leads Insert" ON leads;
CREATE POLICY "Leads Insert" ON leads FOR INSERT WITH CHECK ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('createLeads'));
DROP POLICY IF EXISTS "Leads Update" ON leads;
CREATE POLICY "Leads Update" ON leads FOR UPDATE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('editLeads'));
DROP POLICY IF EXISTS "Leads Delete" ON leads;
CREATE POLICY "Leads Delete" ON leads FOR DELETE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('deleteLeads'));

-- DEALS
DROP POLICY IF EXISTS "Deals Select" ON deals;
CREATE POLICY "Deals Select" ON deals FOR SELECT USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('viewDeals'));
DROP POLICY IF EXISTS "Deals Insert" ON deals;
CREATE POLICY "Deals Insert" ON deals FOR INSERT WITH CHECK ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('createDeals'));
DROP POLICY IF EXISTS "Deals Update" ON deals;
CREATE POLICY "Deals Update" ON deals FOR UPDATE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('editDeals'));
DROP POLICY IF EXISTS "Deals Delete" ON deals;
CREATE POLICY "Deals Delete" ON deals FOR DELETE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('deleteDeals'));

-- TASKS
DROP POLICY IF EXISTS "Tasks Select" ON tasks;
CREATE POLICY "Tasks Select" ON tasks FOR SELECT USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('viewTasks'));
DROP POLICY IF EXISTS "Tasks Insert" ON tasks;
CREATE POLICY "Tasks Insert" ON tasks FOR INSERT WITH CHECK ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('createTasks'));
DROP POLICY IF EXISTS "Tasks Update" ON tasks;
CREATE POLICY "Tasks Update" ON tasks FOR UPDATE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('editTasks'));
DROP POLICY IF EXISTS "Tasks Delete" ON tasks;
CREATE POLICY "Tasks Delete" ON tasks FOR DELETE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('deleteTasks'));

-- COMPANIES
DROP POLICY IF EXISTS "Companies Select" ON companies;
CREATE POLICY "Companies Select" ON companies FOR SELECT USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('viewContacts'));
DROP POLICY IF EXISTS "Companies Insert" ON companies;
CREATE POLICY "Companies Insert" ON companies FOR INSERT WITH CHECK ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('createContacts'));
DROP POLICY IF EXISTS "Companies Update" ON companies;
CREATE POLICY "Companies Update" ON companies FOR UPDATE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('editContacts'));
DROP POLICY IF EXISTS "Companies Delete" ON companies;
CREATE POLICY "Companies Delete" ON companies FOR DELETE USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('deleteContacts'));

-- ACTIVITIES
DROP POLICY IF EXISTS "Activities Select" ON activities;
CREATE POLICY "Activities Select" ON activities FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL);
DROP POLICY IF EXISTS "Activities Insert" ON activities;
CREATE POLICY "Activities Insert" ON activities FOR INSERT WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL);

-- FILES
DROP POLICY IF EXISTS "Files Select" ON files;
CREATE POLICY "Files Select" ON files FOR SELECT USING ((organization_id IN (SELECT public.get_user_org_ids()) OR organization_id IS NULL) AND public.has_permission('viewContacts'));

-- PROFILES
DROP POLICY IF EXISTS "Profiles Select" ON profiles;
CREATE POLICY "Profiles Select" ON profiles FOR SELECT USING (organization_id IN (SELECT public.get_user_org_ids()) OR id = auth.uid());
DROP POLICY IF EXISTS "Profiles Update" ON profiles;
CREATE POLICY "Profiles Update" ON profiles FOR UPDATE USING (id = auth.uid() OR public.has_permission('manageUsers'));

-- Final Check
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;

-- Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';
