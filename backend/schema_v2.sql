-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ROLES & PERMISSIONS
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  display_name TEXT
);

CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT
);

CREATE TABLE role_permissions (
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- USERS
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE user_roles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- PROFILES (Publicly accessible user data synced with Auth)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  email TEXT,
  role TEXT DEFAULT 'viewer',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- COMPANIES
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  website TEXT,
  industry TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CONTACTS
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name TEXT NOT NULL,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  company_id UUID REFERENCES companies(id),
  company_name TEXT,
  position TEXT,
  address TEXT,
  notes TEXT,
  assigned_to UUID REFERENCES users(id),
  is_customer BOOLEAN DEFAULT FALSE,
  created_from_lead BOOLEAN DEFAULT FALSE,
  source_lead_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_contacted TIMESTAMP WITH TIME ZONE,
  avatar_url TEXT,
  is_favorite BOOLEAN DEFAULT FALSE
);

-- LEADS
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name TEXT NOT NULL,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  lead_source TEXT,
  status TEXT DEFAULT 'new',
  assigned_to UUID REFERENCES users(id),
  notes TEXT,
  estimated_value NUMERIC(15, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  converted_at TIMESTAMP WITH TIME ZONE,
  converted_contact_id UUID REFERENCES contacts(id)
);

-- Add source lead FK
ALTER TABLE contacts ADD CONSTRAINT fk_contacts_source_lead FOREIGN KEY (source_lead_id) REFERENCES leads(id);

-- DEALS
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  contact_id UUID REFERENCES contacts(id),
  company_name TEXT,
  value NUMERIC(15, 2),
  stage TEXT DEFAULT 'prospecting',
  assigned_to UUID REFERENCES users(id),
  expected_close_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TASKS
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  assigned_to UUID REFERENCES users(id),
  related_entity_id UUID,
  related_entity_type TEXT, 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ACTIVITIES
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT,
  description TEXT,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  activity_type TEXT,
  related_entity_id UUID,
  related_entity_type TEXT,
  created_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- NOTIFICATIONS & TOKENS
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  message TEXT,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_read BOOLEAN DEFAULT FALSE,
  related_entity_id TEXT,
  related_entity_type TEXT,
  sender_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE fcm_tokens (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  token TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- LEAD CONVERSION RPC
CREATE OR REPLACE FUNCTION convert_lead(lead_uuid UUID)
RETURNS UUID AS $$
DECLARE
    v_lead record;
    v_contact_id UUID;
BEGIN
    SELECT * INTO v_lead FROM leads WHERE id = lead_uuid FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lead not found';
    END IF;

    IF v_lead.status = 'converted' THEN
        RAISE EXCEPTION 'Lead is already converted';
    END IF;

    INSERT INTO contacts (
        first_name, 
        last_name, 
        email, 
        phone, 
        assigned_to, 
        notes, 
        created_from_lead, 
        source_lead_id,
        is_customer
    ) VALUES (
        v_lead.first_name, 
        v_lead.last_name, 
        v_lead.email, 
        v_lead.phone, 
        v_lead.assigned_to, 
        v_lead.notes, 
        TRUE, 
        v_lead.id,
        FALSE
    ) RETURNING id INTO v_contact_id;

    UPDATE leads 
    SET status = 'converted', 
        converted_at = NOW(), 
        converted_contact_id = v_contact_id,
        updated_at = NOW()
    WHERE id = lead_uuid;

    RETURN v_contact_id;
END;
$$ LANGUAGE plpgsql;

-- INDEXING for Performance
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_assigned_to ON leads(assigned_to);
CREATE INDEX idx_contacts_assigned_to ON contacts(assigned_to);
CREATE INDEX idx_deals_stage ON deals(stage);

-- RLS Security (Example implementations) 
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Leads access policy"
  ON leads FOR ALL USING (
    auth.uid() IN (SELECT id FROM users WHERE users.id = leads.assigned_to) OR 
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Contacts access policy"
  ON contacts FOR ALL USING (
    auth.uid() IN (SELECT id FROM users WHERE users.id = contacts.assigned_to) OR 
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );
