-- ==========================================
-- FIX NOTIFICATIONS TABLE
-- Run this in your Supabase SQL Editor
-- ==========================================

-- 1. Add sender_id column to track who created the notification
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES public.profiles(id);

-- 2. Disable RLS entirely (all users can see all notifications)
-- Self-filtering is done in the Flutter app via sender_id
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;

-- 3. Make user_id optional (notifications are broadcast, not per-user)
ALTER TABLE public.notifications ALTER COLUMN user_id DROP NOT NULL;
