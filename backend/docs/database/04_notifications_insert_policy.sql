-- ==========================================
-- ADD INSERT POLICY FOR NOTIFICATIONS
-- Run this in your Supabase SQL Editor
-- ==========================================

-- Allow authenticated users to insert notifications
-- (they need to be able to create notifications for themselves and others)
CREATE POLICY "Authenticated users can insert notifications"
ON public.notifications FOR INSERT
WITH CHECK (true);
