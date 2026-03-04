-- Update Contacts Table to explicitly support 'churned' status
-- Previously, only 'is_customer' boolean flag was used, which made it impossible
-- to distinguish between an active Customer and a Churned customer in the UI.

ALTER TABLE contacts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'lead';

-- Migrate existing data based on the 'is_customer' boolean
UPDATE contacts SET status = 'customer' WHERE is_customer = TRUE AND status = 'lead';
