-- Migration: Allow all users to read their firm's data (for company name display in header)
-- Previously only super_admin and firm_admin could SELECT from firms table.
-- This policy allows project_manager, editor, viewer, vdcr_manager to read their firm's name/logo.
-- Run RLS_FIX_USERS_TABLE.sql first (for get_user_firm_id function).

-- Add policy: Users can view their own firm (for header company name display)
CREATE POLICY "Users can view their own firm"
ON public.firms FOR SELECT
TO authenticated
USING (id = public.get_user_firm_id());
