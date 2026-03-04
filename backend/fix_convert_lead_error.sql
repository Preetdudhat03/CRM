-- Fix for the "column assigned_to is of type uuid but expression is of type text" error
-- This happens because the "assigned_to" column in your "leads" table is stored as TEXT (containing empty strings like ""), 
-- while the "contacts" table expects a strict UUID format.

CREATE OR REPLACE FUNCTION convert_lead(lead_uuid UUID)
RETURNS UUID AS $$
DECLARE
    v_lead record;
    v_contact_id UUID;
    v_assigned_to_uuid UUID;
BEGIN
    SELECT * INTO v_lead FROM leads WHERE id = lead_uuid FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lead not found';
    END IF;

    IF v_lead.status = 'converted' THEN
        RAISE EXCEPTION 'Lead is already converted';
    END IF;

    -- Safely parse the text field into a UUID. 
    -- If it's an empty string or invalid, it gracefully becomes NULL rather than crashing.
    BEGIN
        v_assigned_to_uuid := NULLIF(TRIM(v_lead.assigned_to::TEXT), '')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_assigned_to_uuid := NULL;
    END;

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
        v_assigned_to_uuid, 
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
