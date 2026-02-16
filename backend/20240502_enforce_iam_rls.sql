-- =====================================================================================
-- PHASE 8: REAL IAM SECURITY via ROW LEVEL SECURITY (RLS)
-- =====================================================================================

-- 1. ENABLE ROW LEVEL SECURITY ON ALL TRANSATIONAL TABLES
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- 2. CREATE HELPER FUNCTION TO CHECK ROLES
-- This function simplifies RLS policies by checking if the current user has one of the allowed roles.
-- MOVED TO PUBLIC SCHEMA to avoid permission issues with 'auth' schema.
CREATE OR REPLACE FUNCTION public.check_role(allowed_roles TEXT[])
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = ANY(allowed_roles)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. DEFINE POLICIES

-- ==================== CONTACTS POLICIES ====================
-- VIEW: All authenticated users can view contacts (Viewer, Employee, Manager, Admin, SuperAdmin)
CREATE POLICY "All users can view contacts" ON contacts
  FOR SELECT USING (auth.role() = 'authenticated');

-- INSERT: Only Employee, Manager, Admin, SuperAdmin can create
CREATE POLICY "Employees and above can create contacts" ON contacts
  FOR INSERT WITH CHECK (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- UPDATE: Employee, Manager, Admin, SuperAdmin can edit
CREATE POLICY "Employees and above can update contacts" ON contacts
  FOR UPDATE USING (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- DELETE: Only Admin and SuperAdmin
CREATE POLICY "Only admins can delete contacts" ON contacts
  FOR DELETE USING (public.check_role(ARRAY['admin', 'superAdmin']));


-- ==================== LEADS POLICIES ====================
-- VIEW: All authenticated users
CREATE POLICY "All users can view leads" ON leads
  FOR SELECT USING (auth.role() = 'authenticated');

-- INSERT: Employee, Manager, Admin, SuperAdmin
CREATE POLICY "Employees and above can create leads" ON leads
  FOR INSERT WITH CHECK (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- UPDATE: Employee, Manager, Admin, SuperAdmin
CREATE POLICY "Employees and above can update leads" ON leads
  FOR UPDATE USING (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- DELETE: Only Admin and SuperAdmin
CREATE POLICY "Only admins can delete leads" ON leads
  FOR DELETE USING (public.check_role(ARRAY['admin', 'superAdmin']));


-- ==================== DEALS POLICIES ====================
-- VIEW: All authenticated users
CREATE POLICY "All users can view deals" ON deals
  FOR SELECT USING (auth.role() = 'authenticated');

-- INSERT: Employee, Manager, Admin, SuperAdmin
CREATE POLICY "Employees and above can create deals" ON deals
  FOR INSERT WITH CHECK (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- UPDATE: Employee, Manager, Admin, SuperAdmin
CREATE POLICY "Employees and above can update deals" ON deals
  FOR UPDATE USING (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- DELETE: Only Manager, Admin, SuperAdmin (Managers can delete deals usually)
-- Based on Role.dart, Manager CANNOT delete deals. Only Admin/SuperAdmin.
CREATE POLICY "Only admins can delete deals" ON deals
  FOR DELETE USING (public.check_role(ARRAY['admin', 'superAdmin']));


-- ==================== TASKS POLICIES ====================
-- VIEW: All authenticated users
CREATE POLICY "All users can view tasks" ON tasks
  FOR SELECT USING (auth.role() = 'authenticated');

-- INSERT: Employee, Manager, Admin, SuperAdmin
CREATE POLICY "Employees and above can create tasks" ON tasks
  FOR INSERT WITH CHECK (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- UPDATE: Employee, Manager, Admin, SuperAdmin
CREATE POLICY "Employees and above can update tasks" ON tasks
  FOR UPDATE USING (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));

-- DELETE: Manager, Admin, SuperAdmin (Managers CAN delete tasks based on Role.dart)
-- Role.dart says Manager has Permission.deleteTasks.
CREATE POLICY "Managers and above can delete tasks" ON tasks
  FOR DELETE USING (public.check_role(ARRAY['manager', 'admin', 'superAdmin']));


-- ==================== ACTIVITIES POLICIES ====================
-- Typically same as Tasks
CREATE POLICY "All users can view activities" ON activities
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Employees and above can manage activities" ON activities
  FOR ALL USING (public.check_role(ARRAY['employee', 'manager', 'admin', 'superAdmin']));


-- ==================== PROFILES POLICIES (Refinement) ====================
-- Ensure we don't lock ourselves out.
-- Profiles policies were partially defined in schema.sql. Let's refine them.
DROP POLICY IF EXISTS "Allow viewed by authenticated users" ON profiles;
DROP POLICY IF EXISTS "Allow update own profile" ON profiles;

-- VIEW: Everyone can view profiles (needed for assigning users to tasks/leads)
CREATE POLICY "All users can view profiles" ON profiles
  FOR SELECT USING (auth.role() = 'authenticated');

-- UPDATE: Self OR Admin/SuperAdmin
CREATE POLICY "Users update self or admins update any" ON profiles
  FOR UPDATE USING (
    id = auth.uid() OR public.check_role(ARRAY['admin', 'superAdmin'])
  );
