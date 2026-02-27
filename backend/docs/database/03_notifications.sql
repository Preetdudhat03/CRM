-- ==========================================
-- ENTERPRISE NOTIFICATION ENGINE SCHEMA
-- Run this in your Supabase SQL Editor
-- ==========================================

-- Drop existing to ensure a clean slate if they had failed/partial attempts
DROP TABLE IF EXISTS public.notification_preferences CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;

-- 1. Create the base Notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,            -- e.g., 'deal_won', 'task_overdue', 'lead_assigned'
    priority VARCHAR(20) DEFAULT 'MEDIUM',-- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_type VARCHAR(50),             -- e.g., 'deal', 'lead', 'task'
    related_id UUID,                      -- ID of the related entity
    is_read BOOLEAN DEFAULT FALSE,
    action_url VARCHAR(255),              -- Deep link or URL to redirect on click
    metadata JSONB,                       -- Any extra properties (e.g. performer_name)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast retrieval of unread notifications for a user
CREATE INDEX idx_notifications_user_id_read 
ON public.notifications(user_id, is_read);


-- 2. Create the Preferences table
CREATE TABLE public.notification_preferences (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- The specific event 'type' (e.g., 'deal_won')
    in_app_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT FALSE,    -- Often false by default to prevent spam
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, notification_type)
);

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- Enables users to securely fetch their own alerts
-- ==========================================

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Policies for Notifications
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications (e.g., mark as read)"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Depending on your backend, you may want to restrict INSERTs
-- to a Service Role or Backend API only, so clients can't spam themselves.
-- Example of Service Role only INSERT policy:
-- CREATE POLICY "Service role can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- Policies for Preferences
CREATE POLICY "Users can view their own preferences"
ON public.notification_preferences FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
ON public.notification_preferences FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences"
ON public.notification_preferences FOR INSERT
WITH CHECK (auth.uid() = user_id);
