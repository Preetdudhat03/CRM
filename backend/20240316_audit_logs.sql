-- Migration: Complete Enterprise Audit Logging
-- Description: Creates audit_logs table, sets up RLS, and adds important indexes.
-- Date: 2024-03-16

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_email TEXT,
    
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    
    old_values JSONB,
    new_values JSONB,
    
    ip_address TEXT,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 2. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_id ON audit_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

-- ============================================================
-- 3. RLS POLICIES
-- ============================================================
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Deny all updates and deletes (logs are immutable)
DROP POLICY IF EXISTS "mt_update_audit_logs" ON audit_logs;
CREATE POLICY "mt_update_audit_logs" ON audit_logs FOR UPDATE USING (false);

DROP POLICY IF EXISTS "mt_delete_audit_logs" ON audit_logs;
CREATE POLICY "mt_delete_audit_logs" ON audit_logs FOR DELETE USING (false);

-- Insert allow for authenticated users (service controls logic)
DROP POLICY IF EXISTS "mt_insert_audit_logs" ON audit_logs;
CREATE POLICY "mt_insert_audit_logs" ON audit_logs FOR INSERT
    WITH CHECK (
        organization_id IN (SELECT public.get_user_org_ids())
        OR organization_id IS NULL
    );

-- Select restrict to admins only
DROP POLICY IF EXISTS "mt_select_audit_logs" ON audit_logs;
CREATE POLICY "mt_select_audit_logs" ON audit_logs FOR SELECT
    USING (
        organization_id IN (SELECT public.get_user_admin_org_ids())
    );
