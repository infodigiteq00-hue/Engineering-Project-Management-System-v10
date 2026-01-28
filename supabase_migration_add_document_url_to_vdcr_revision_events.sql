-- ============================================================================
-- MIGRATION: Add document_url field to vdcr_revision_events table
-- ============================================================================
-- This migration adds a document_url field to store the document file
-- that was sent/received for each revision event

-- Step 1: Add document_url column to vdcr_revision_events table
ALTER TABLE public.vdcr_revision_events 
ADD COLUMN IF NOT EXISTS document_url text;

-- Step 2: Add comment for documentation
COMMENT ON COLUMN public.vdcr_revision_events.document_url IS 'URL/path to the document file associated with this revision event (sent or received)';
