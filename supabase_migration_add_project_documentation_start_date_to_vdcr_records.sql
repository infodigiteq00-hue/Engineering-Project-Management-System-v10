-- ============================================================================
-- MIGRATION: Add project_documentation_start_date field to vdcr_records table
-- ============================================================================
-- This migration adds a project_documentation_start_date field to store the
-- custom documentation start date for each VDCR entry. If NULL, it will
-- default to the project's sales_order_date (PO date).

-- Step 1: Add project_documentation_start_date column to vdcr_records table
ALTER TABLE public.vdcr_records 
ADD COLUMN IF NOT EXISTS project_documentation_start_date date;

-- Step 2: Add comment for documentation
COMMENT ON COLUMN public.vdcr_records.project_documentation_start_date IS 'Custom project documentation start date for this VDCR entry. If NULL, defaults to project sales_order_date (PO date). Used to calculate "Days with Us" for Rev-00.';

