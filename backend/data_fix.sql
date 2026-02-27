-- We previously added is_customer BOOLEAN DEFAULT FALSE;
-- This marked all your preexisting contacts as "Leads" instead of "Customers"
-- Run this script to flip them all back to true (Customer mode) so your CRM organizes them correctly

UPDATE contacts
SET is_customer = TRUE
WHERE is_customer IS FALSE OR is_customer IS NULL;
