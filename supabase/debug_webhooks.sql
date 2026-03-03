-- PUSH NOTIFICATIONS DEBUGGING SCRIPT
-- Run these one by one in your Supabase SQL Editor to find the "Missing Link"

-- 1. Check if the Webhook Trigger actually exists on the table
SELECT trigger_name, event_manipulation, event_object_table, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'notifications';

-- 2. Check for recent HTTP request errors (This requires the pg_net extension logs)
-- If this returns nothing, the trigger isn't even ATTEMPTING to call the Edge Function
SELECT * FROM net.http_requests ORDER BY created_at DESC LIMIT 10;

-- 3. Verify if the 'http' extension is enabled (Needed for raw SQL triggers)
SELECT * FROM pg_extension WHERE extname = 'http';

-- 4. Test the Edge Function directly from SQL (Replace with your keys)
-- This will tell us if the problem is the Webhook or the Function itself
SELECT
  extensions.http_post(
    url := 'https://iyylebbrcawebwsqxzup.supabase.co/functions/v1/send-fcm',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{"record": {"title": "Test SQL Push", "message": "Manual trigger test", "related_entity_type": "test||roles:Admin"}}'::jsonb
  );
