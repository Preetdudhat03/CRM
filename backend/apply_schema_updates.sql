-- Create roles and permissions if they don't exist
CREATE TABLE IF NOT EXISTS roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  display_name TEXT
);

CREATE TABLE IF NOT EXISTS permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT
);

-- Users (if missing)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Safely add missing columns to Contacts
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES profiles(id);
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS created_from_lead BOOLEAN DEFAULT FALSE;
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS source_lead_id UUID;

-- Safely add missing columns to Leads
ALTER TABLE leads ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES profiles(id);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS estimated_value NUMERIC(15, 2);
ALTER TABLE leads ADD COLUMN IF NOT EXISTS converted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS converted_contact_id UUID REFERENCES contacts(id);

-- Safely add missing columns to Deals
ALTER TABLE deals ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES profiles(id);

-- Safely add missing columns to Tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES profiles(id);

-- Safely add missing columns to Activities
ALTER TABLE activities ADD COLUMN IF NOT EXISTS related_entity_id UUID;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS related_entity_type TEXT;

-- Safely replace the convert_lead RPC function
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

-- RELOAD POSTGREST CACHE TO FIX "COULD NOT FIND COLUMN IN SCHEMA CACHE" ERROR!
NOTIFY pgrst, 'reload schema';
