-- ============================================================================
-- MIGRATION: Add department field to vdcr_records table
-- ============================================================================
-- This migration adds a department field to store the department name
-- for each VDCR record. This allows documents to be segregated by department.

-- Step 1: Add department column to vdcr_records table
ALTER TABLE public.vdcr_records 
ADD COLUMN IF NOT EXISTS department character varying;

-- Step 2: Add comment for documentation
COMMENT ON COLUMN public.vdcr_records.department IS 'Department name for this VDCR record. Used to segregate documents by department. Optional field.';

