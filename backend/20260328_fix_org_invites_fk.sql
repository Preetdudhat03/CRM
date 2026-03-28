-- Migration: Fix org_invites Foreign Key to profiles
-- Description: Adds a direct foreign key from org_invites(inviter_id) to profiles(id)
--              to allow PostgREST to fetch the inviter's name using !inviter_id hint.
-- Date: 2026-03-28

-- 1. Add the explicit foreign key between org_invites and profiles
ALTER TABLE public.org_invites
ADD CONSTRAINT fk_org_invites_inviter_profile
FOREIGN KEY (inviter_id)
REFERENCES public.profiles(id)
ON DELETE SET NULL;
