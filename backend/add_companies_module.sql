-- Migration: Add Companies Module
-- Description: Creates the companies table and establishes relationships with contacts, deals, and leads.

-- 1. Create Companies Table
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    industry TEXT,
    website TEXT,
    phone TEXT,
    address TEXT,
    revenue NUMERIC(15, 2) DEFAULT 0,
    employee_count INT,
    notes TEXT,
    status TEXT DEFAULT 'active', -- active, inactive, churned
    assigned_to UUID REFERENCES profiles(id),
    organization_id UUID, -- placeholder for multi-tenancy
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure columns exist if table was already created
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='assigned_to') THEN
        ALTER TABLE companies ADD COLUMN assigned_to UUID REFERENCES profiles(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='status') THEN
        ALTER TABLE companies ADD COLUMN status TEXT DEFAULT 'active';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='organization_id') THEN
        ALTER TABLE companies ADD COLUMN organization_id UUID;
    END IF;
END $$;

-- Enable RLS for companies
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Policy: Enable all for authenticated users (matching existing context)
CREATE POLICY "Enable all for users" ON companies FOR ALL USING (auth.role() = 'authenticated');

-- 2. Update Contacts table to link to companies
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contacts' AND column_name='company_id') THEN
        ALTER TABLE contacts ADD COLUMN company_id UUID REFERENCES companies(id);
    END IF;
END $$;

-- 3. Update Deals table to link to companies
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='deals' AND column_name='company_id') THEN
        ALTER TABLE deals ADD COLUMN company_id UUID REFERENCES companies(id);
    END IF;
END $$;

-- 4. Update Leads table to link to companies
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='leads' AND column_name='company_id') THEN
        ALTER TABLE leads ADD COLUMN company_id UUID REFERENCES companies(id);
    END IF;
END $$;

-- 5. Revenue Aggregation Logic
CREATE OR REPLACE FUNCTION update_company_revenue_from_deal()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle Insert or Update
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        -- Re-calculate revenue for NEW company if it's a closed_won deal
        IF (NEW.company_id IS NOT NULL) THEN
            UPDATE companies
            SET revenue = (
                SELECT COALESCE(SUM(value), 0)
                FROM deals
                WHERE company_id = NEW.company_id AND stage = 'closed_won'
            )
            WHERE id = NEW.company_id;
        END IF;
        
        -- Handle case where deal moved from one company to another or company was removed
        IF (TG_OP = 'UPDATE' AND OLD.company_id IS NOT NULL AND (OLD.company_id != NEW.company_id OR NEW.company_id IS NULL)) THEN
            UPDATE companies
            SET revenue = (
                SELECT COALESCE(SUM(value), 0)
                FROM deals
                WHERE company_id = OLD.company_id AND stage = 'closed_won'
            )
            WHERE id = OLD.company_id;
        END IF;

    -- Handle Delete
    ELSIF (TG_OP = 'DELETE') THEN
        IF (OLD.company_id IS NOT NULL) THEN
             UPDATE companies
            SET revenue = (
                SELECT COALESCE(SUM(value), 0)
                FROM deals
                WHERE company_id = OLD.company_id AND stage = 'closed_won'
            )
            WHERE id = OLD.company_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update revenue on deal changes
DROP TRIGGER IF EXISTS trigger_update_company_revenue ON deals;
CREATE TRIGGER trigger_update_company_revenue
AFTER INSERT OR UPDATE OR DELETE ON deals
FOR EACH ROW EXECUTE FUNCTION update_company_revenue_from_deal();

-- 10. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_companies_assigned_to ON companies(assigned_to);
CREATE INDEX IF NOT EXISTS idx_contacts_company_id ON contacts(company_id);
CREATE INDEX IF NOT EXISTS idx_deals_company_id ON deals(company_id);

-- 11. Advanced Aggregation Function
CREATE OR REPLACE FUNCTION get_company_stats(company_uuid UUID)
RETURNS TABLE (
    won_revenue NUMERIC,
    open_deal_value NUMERIC,
    total_deals BIGINT,
    total_contacts BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN d.stage = 'won' THEN d.value ELSE 0 END), 0)::NUMERIC as won_revenue,
        COALESCE(SUM(CASE WHEN d.stage NOT IN ('won', 'lost') THEN d.value ELSE 0 END), 0)::NUMERIC as open_deal_value,
        COUNT(DISTINCT d.id) as total_deals,
        COUNT(DISTINCT c.id) as total_contacts
    FROM companies comp
    LEFT JOIN deals d ON d.company_id = comp.id
    LEFT JOIN contacts c ON c.company_id = comp.id
    WHERE comp.id = company_uuid;
END;
$$ LANGUAGE plpgsql;

-- 12. RLS Policies
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all companies (placeholder for org check)
CREATE POLICY "Users can view all companies" ON companies
    FOR SELECT USING (true);

CREATE POLICY "Users can update their assigned companies" ON companies
    FOR UPDATE USING (auth.uid() = assigned_to OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('Admin', 'SuperAdmin')
    ));

CREATE POLICY "Admins can delete companies" ON companies
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('Admin', 'SuperAdmin')
    ));
