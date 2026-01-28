-- ============================================================================
-- MIGRATION: Add target_submission_date field to vdcr_revision_events table
-- ============================================================================
-- This migration adds a target_submission_date field to store the target date
-- for next submission when a document is received/commented

-- Step 1: Add target_submission_date column to vdcr_revision_events table
ALTER TABLE public.vdcr_revision_events 
ADD COLUMN IF NOT EXISTS target_submission_date timestamp with time zone;

-- Step 2: Add comment for documentation
COMMENT ON COLUMN public.vdcr_revision_events.target_submission_date IS 'Target date for next submission when document is received/commented (for received events)';

