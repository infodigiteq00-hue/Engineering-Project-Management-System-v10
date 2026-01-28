-- ============================================================================
-- MIGRATION: Add targeted_finish_date field to vdcr_records table
-- ============================================================================
-- This migration adds a targeted_finish_date field to store the target
-- completion date for each VDCR document. This is used to calculate and
-- display "Days to Go" until the document should be completed.

-- Step 1: Add targeted_finish_date column to vdcr_records table
ALTER TABLE public.vdcr_records 
ADD COLUMN IF NOT EXISTS targeted_finish_date date;

-- Step 2: Add comment for documentation
COMMENT ON COLUMN public.vdcr_records.targeted_finish_date IS 'Target completion date for this VDCR document. Used to calculate and display "Days to Go" counter. NULL if no target date is set.';

