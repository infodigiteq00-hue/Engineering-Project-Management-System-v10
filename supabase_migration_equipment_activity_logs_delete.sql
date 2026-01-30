-- Migration: Add DELETE policies for equipment_activity_logs and standalone_equipment_activity_logs
-- Fix: Equipment deletion was failing with foreign key violation (23503) because RLS blocked
--      the cascade delete of activity logs. Super admins and firm admins can delete equipment
--      but weren't allowed to delete activity logs (is_assigned_to_project returns false for them).
-- Run this migration in Supabase SQL Editor to fix equipment deletion.

-- ============================================================================
-- PART 1: Add ON DELETE CASCADE to foreign keys (database-level cascade)
-- This ensures activity logs are automatically deleted when equipment is deleted.
-- ============================================================================

-- equipment_activity_logs: Cascade delete when equipment is deleted
ALTER TABLE public.equipment_activity_logs
DROP CONSTRAINT IF EXISTS equipment_activity_logs_equipment_id_fkey;

ALTER TABLE public.equipment_activity_logs
ADD CONSTRAINT equipment_activity_logs_equipment_id_fkey
FOREIGN KEY (equipment_id) REFERENCES public.equipment(id) ON DELETE CASCADE;

-- standalone_equipment_activity_logs: Cascade delete when standalone equipment is deleted
ALTER TABLE public.standalone_equipment_activity_logs
DROP CONSTRAINT IF EXISTS standalone_equipment_activity_logs_equipment_id_fkey;

ALTER TABLE public.standalone_equipment_activity_logs
ADD CONSTRAINT standalone_equipment_activity_logs_equipment_id_fkey
FOREIGN KEY (equipment_id) REFERENCES public.standalone_equipment(id) ON DELETE CASCADE;

-- ============================================================================
-- PART 2: Add DELETE policies (for app-level cascade - API deletes activity logs before equipment)
-- Super admin and firm admin can delete equipment but may not pass is_assigned_to_project.
-- ============================================================================

-- 1. equipment_activity_logs: Super admin can delete all; users can delete for assigned projects
DROP POLICY IF EXISTS "Users can delete equipment activity logs" ON public.equipment_activity_logs;
DROP POLICY IF EXISTS "Authenticated users can delete equipment activity logs" ON public.equipment_activity_logs;
DROP POLICY IF EXISTS "Super admin can delete equipment activity logs" ON public.equipment_activity_logs;

CREATE POLICY "Super admin can delete equipment activity logs"
ON public.equipment_activity_logs FOR DELETE
TO authenticated
USING (public.is_super_admin());

CREATE POLICY "Users can delete equipment activity logs"
ON public.equipment_activity_logs FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_activity_logs.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
  OR public.is_assigned_to_project(project_id)
);

-- 2. standalone_equipment_activity_logs: Super admin can delete all; users can delete for assigned equipment
DROP POLICY IF EXISTS "Users can delete standalone equipment activity logs" ON public.standalone_equipment_activity_logs;
DROP POLICY IF EXISTS "Authenticated users can delete standalone equipment activity logs" ON public.standalone_equipment_activity_logs;
DROP POLICY IF EXISTS "Super admin can delete standalone equipment activity logs" ON public.standalone_equipment_activity_logs;

CREATE POLICY "Super admin can delete standalone equipment activity logs"
ON public.standalone_equipment_activity_logs FOR DELETE
TO authenticated
USING (public.is_super_admin());

CREATE POLICY "Users can delete standalone equipment activity logs"
ON public.standalone_equipment_activity_logs FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_activity_logs.equipment_id
    AND (
      EXISTS (
        SELECT 1 FROM public.standalone_equipment_team_positions tp
        JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
        WHERE tp.equipment_id = se.id
        AND u.id = auth.uid()
      )
      OR se.created_by = auth.uid()
    )
  )
);
