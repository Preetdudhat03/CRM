-- SUPABASE SQL TO ENABLE FCM NOTIFICATIONS
-- Run this in your Supabase SQL Editor

-- 1. Enable HTTP extension for Webhooks
CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "extensions";

-- 2. Create a Webhook to trigger the 'send-fcm' Edge Function when a notification is inserted
-- Replace 'YOUR_EDGE_FUNCTION_PROJECT_URL' with your actual project URL (e.g. project-ref.supabase.co)
-- Replace 'YOUR_SERVICE_ROLE_KEY' with your Supabase service_role key

-- 2. Create a Trigger Function to handle the HTTP request
-- This avoids syntax errors with concatenation and is more robust.
CREATE OR REPLACE FUNCTION public.handle_notification_inserted()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://iyylebbrcawebwsqxzup.supabase.co/functions/v1/send-fcm',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eWxlYmJyY2F3ZWJ3c3F4enVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMzMwMzksImV4cCI6MjA4NjcwOTAzOX0.KvcQj5CYblv708lgKzBQPbnd6oDiiH4AC1cMhwMnRjY'
      ),
      body := jsonb_build_object('record', row_to_json(NEW)::jsonb),
      timeout_milliseconds := 5000
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the Trigger calling the above function
DROP TRIGGER IF EXISTS on_notification_inserted ON public.notifications;
CREATE TRIGGER on_notification_inserted
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.handle_notification_inserted();

-- IMPORTANT NOTES:
-- 1. You MUST add the SERVICE_ACCOUNT_JSON secret to your Supabase Edge Functions.
--    Run this in your terminal:
--    supabase secrets set SERVICE_ACCOUNT_JSON='{...your service account json contents...}'
--
-- 2. Ensure your Firebase project allows the Service Account to send FCM messages.
