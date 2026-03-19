-- Migration: Invitation Notifications
-- Description: Adds receiver_id and sender_id to notifications, 
--              updates RLS, and sets up a trigger for org invites.
-- Date: 2026-03-19

-- ============================================================
-- 1. SCHEMA UPDATES
-- ============================================================

-- Add receiver_id and sender_id to notifications for targeted delivery
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='receiver_id') THEN
        ALTER TABLE public.notifications ADD COLUMN receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='sender_id') THEN
        ALTER TABLE public.notifications ADD COLUMN sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;

    -- Also ensure organization_id is nullable (already is, but for safety)
    ALTER TABLE public.notifications ALTER COLUMN organization_id DROP NOT NULL;
END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_id ON public.notifications(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_sender_id ON public.notifications(sender_id);

-- ============================================================
-- 2. REFINED RLS POLICIES
-- ============================================================

-- Allow users to see notifications if:
-- 1. They are in the organization
-- 2. They are the explicit receiver
-- 3. It's a global notification (both org and receiver are null)
DROP POLICY IF EXISTS mt_select_notifications ON public.notifications;
CREATE POLICY mt_select_notifications ON public.notifications
    FOR SELECT USING (
        organization_id IN (SELECT public.get_user_org_ids())
        OR receiver_id = auth.uid()
        OR (organization_id IS NULL AND receiver_id IS NULL)
    );

-- ============================================================
-- 3. TRIGGER FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_invite_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_target_user_id uuid;
    v_org_name text;
BEGIN
    -- 1. Find if a profile exists for this email
    SELECT id INTO v_target_user_id 
    FROM public.profiles 
    WHERE email = NEW.email 
    LIMIT 1;

    -- 2. If user exists, create notification
    IF v_target_user_id IS NOT NULL THEN
        SELECT name INTO v_org_name 
        FROM public.organizations 
        WHERE id = NEW.organization_id;

        INSERT INTO public.notifications (
            type,
            title,
            message,
            receiver_id,
            sender_id,
            organization_id, -- Keep as NULL if we want them to see it WITHOUT being in the org yet
            related_id,
            related_type
        ) VALUES (
            'invitation',
            'Organization Invitation',
            'You have been invited to join ' || COALESCE(v_org_name, 'an organization'),
            v_target_user_id,
            NEW.inviter_id,
            NULL, -- Target user isn't in the org yet, so NULL org ensures they can see it via RLS
            NEW.id,
            'invitation'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger
DROP TRIGGER IF EXISTS on_org_invite_created ON public.org_invites;
CREATE TRIGGER on_org_invite_created
    AFTER INSERT ON public.org_invites
    FOR EACH ROW EXECUTE PROCEDURE public.handle_invite_notification();
