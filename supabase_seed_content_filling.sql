-- ============================================================================
-- CONTENT FILLING SEED SCRIPT - Run directly in Supabase SQL Editor
-- ============================================================================
-- Creates: 1 demo firm, 1 user, 2 projects, 8 equipment, 35 VDCR records,
--          VDCR revision events (2-15 per record), VDCR document history,
--          equipment progress entries
--
-- PREREQUISITES: Run these migrations first if not already applied:
--   - supabase_migration_add_department_to_vdcr_records.sql
--   - supabase_migration_add_document_url_to_vdcr_revision_events.sql
--   - supabase_migration_add_target_submission_date_to_vdcr_revision_events.sql
--
-- USAGE: Copy entire script → Supabase Dashboard → SQL Editor → Run
-- ============================================================================

DO $$
DECLARE
  v_firm_id uuid;
  v_user_id uuid;
  v_project1_id uuid;
  v_project2_id uuid;
  v_i int;
  v_vdcr_id uuid;
  v_equip_id uuid;
BEGIN
  -- ========== 1. FIRM ==========
  INSERT INTO public.firms (name, admin_name, admin_email, subscription_plan, is_active, max_users)
  VALUES ('Demo Fabrication Co', 'John Smith', 'demo-seed-content@demofab.com', 'professional', true, 20)
  ON CONFLICT (name) DO UPDATE SET admin_email = EXCLUDED.admin_email
  RETURNING id INTO v_firm_id;
  
  IF v_firm_id IS NULL THEN
    SELECT id INTO v_firm_id FROM public.firms WHERE name = 'Demo Fabrication Co' LIMIT 1;
  END IF;

  -- ========== 2. USER ==========
  INSERT INTO public.users (email, full_name, role, firm_id, is_active)
  VALUES ('demo-manager@demofab.com', 'Demo Project Manager', 'firm_admin', v_firm_id, true)
  ON CONFLICT (email) DO UPDATE SET firm_id = EXCLUDED.firm_id
  RETURNING id INTO v_user_id;
  
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.users WHERE email = 'demo-manager@demofab.com' LIMIT 1;
  END IF;

  -- ========== 3. PROJECTS ==========
  INSERT INTO public.projects (
    name, client, location, manager, deadline, po_number, firm_id, created_by,
    project_manager_id, vdcr_manager_id, scope_of_work, status, sales_order_date,
    client_industry, client_focal_point, tpi_agency, kickoff_meeting_notes,
    special_production_notes, services_included, equipment_count, active_equipment, progress
  ) VALUES (
    'Saudi Aramco - Ras Tanura Vessels',
    'Saudi Aramco',
    'Ras Tanura, Saudi Arabia',
    'Ahmed Al-Rashid',
    CURRENT_DATE + INTERVAL '12 months',
    'PO-ARAMCO-2024-1087',
    v_firm_id,
    v_user_id,
    v_user_id,
    v_user_id,
    'Supply of 4 pressure vessels and 2 heat exchangers for crude distillation unit. ASME VIII Div.1, full documentation and VDCR.',
    'active',
    CURRENT_DATE - INTERVAL '2 months',
    'Oil & Gas',
    'Khalid Al-Mutairi - Project Engineer',
    'TÜV SÜD',
    '- Kickoff completed. Client expects Rev-00 submission within 6 weeks.
- All datasheets Code 1. Fabrication drawings Code 2.
- TPI witness for hydro test and NDT.',
    '- SA-516 Gr.70 material. Lead time 8 weeks for plates.
- Client prefers 3mm corrosion allowance on shell.',
    '{"design": true, "testing": true, "commissioning": false, "documentation": true, "manufacturing": true, "installationSupport": false}'::jsonb,
    6, 6, 25
  )
  RETURNING id INTO v_project1_id;

  INSERT INTO public.projects (
    name, client, location, manager, deadline, po_number, firm_id, created_by,
    project_manager_id, vdcr_manager_id, scope_of_work, status, sales_order_date,
    client_industry, client_focal_point, tpi_agency, kickoff_meeting_notes,
    special_production_notes, services_included, equipment_count, active_equipment, progress
  ) VALUES (
    'ExxonMobil - Beaumont Refinery Expansion',
    'ExxonMobil',
    'Beaumont, TX',
    'John Martinez',
    CURRENT_DATE + INTERVAL '9 months',
    'SO-EM-2024-4521',
    v_firm_id,
    v_user_id,
    v_user_id,
    v_user_id,
    '2 separators and 3 drums for hydrocracker unit. Full VDCR cycle, MTR and test reports.',
    'active',
    CURRENT_DATE - INTERVAL '1 month',
    'Petrochemical',
    'Sarah Chen - Documentation Lead',
    'BV',
    '- Documentation start date aligned with PO.
- Code 1 for all critical documents.',
    '- Expedited delivery requested. Prioritize V-201 and V-202.',
    '{"design": true, "testing": true, "commissioning": false, "documentation": true, "manufacturing": true, "installationSupport": true}'::jsonb,
    5, 5, 15
  )
  RETURNING id INTO v_project2_id;

  -- ========== 4. EQUIPMENT ==========
  INSERT INTO public.equipment (
    project_id, type, tag_number, job_number, manufacturing_serial, name, size, material,
    design_code, status, progress, progress_phase, supervisor, welder, qc_inspector,
    project_manager, location, priority, custom_field_1_name, custom_field_1_value,
    custom_field_2_name, custom_field_2_value, custom_field_3_name, custom_field_3_value,
    custom_field_4_name, custom_field_4_value, custom_field_5_name, custom_field_5_value, notes
  ) VALUES
  (v_project1_id, 'Pressure Vessel', 'V-101', 'JOB-2024-1087-01', 'MFG-2024-001', 'Primary Separator', '48" x 20''', 'SA-516 Gr.70', 'ASME VIII Div.1', 'in-progress', 45, 'fabrication', 'Mike Johnson', 'Carlos Rodriguez', 'David Kim', 'Ahmed Al-Rashid', 'Shop A', 'high', 'Design Pressure', '150 psig', 'Design Temp', '850°F', 'MAWP', '165 psig', 'Corrosion Allowance', '3mm', 'Hydro Test', '225 psig', 'Shell rolling complete. Fit-up in progress.'),
  (v_project1_id, 'Pressure Vessel', 'V-102', 'JOB-2024-1087-02', 'MFG-2024-002', 'Secondary Separator', '36" x 15''', 'SA-516 Gr.70', 'ASME VIII Div.1', 'documentation', 30, 'documentation', 'Mike Johnson', 'James Wilson', 'David Kim', 'Ahmed Al-Rashid', 'Documentation', 'high', 'Design Pressure', '120 psig', 'Design Temp', '750°F', 'MAWP', '135 psig', 'Corrosion Allowance', '3mm', 'Hydro Test', '180 psig', 'Datasheet Rev-02 under client review.'),
  (v_project1_id, 'Heat Exchanger', 'E-201', 'JOB-2024-1087-03', 'MFG-2024-003', 'Crude Preheat Exchanger', '24" x 12''', 'Shell: SA-516 Gr.70, Tubes: SA-179', 'ASME VIII Div.1', 'pending', 10, 'documentation', 'Mike Johnson', NULL, 'David Kim', 'Ahmed Al-Rashid', 'Pending', 'medium', 'Design Pressure Shell', '150 psig', 'Design Pressure Tube', '200 psig', 'Design Temp', '650°F', 'TEMA Class', 'B', 'Hydro Test', '225 psig', 'Awaiting material.'),
  (v_project1_id, 'Heat Exchanger', 'E-202', 'JOB-2024-1087-04', 'MFG-2024-004', 'Overhead Condenser', '20" x 10''', 'Shell: SA-516 Gr.70, Tubes: SA-179', 'ASME VIII Div.1', 'pending', 5, 'documentation', 'Mike Johnson', NULL, 'David Kim', 'Ahmed Al-Rashid', 'Pending', 'medium', 'Design Pressure Shell', '100 psig', 'Design Pressure Tube', '150 psig', 'Design Temp', '450°F', 'TEMA Class', 'B', 'Hydro Test', '150 psig', 'Design in progress.'),
  (v_project1_id, 'Drum', 'D-301', 'JOB-2024-1087-05', 'MFG-2024-005', 'Flash Drum', '18" x 8''', 'SA-516 Gr.70', 'ASME VIII Div.1', 'completed', 100, 'completed', 'Mike Johnson', 'Carlos Rodriguez', 'David Kim', 'Ahmed Al-Rashid', 'Shipped', 'low', 'Design Pressure', '80 psig', 'Design Temp', '400°F', 'MAWP', '88 psig', 'Corrosion Allowance', '3mm', 'Hydro Test', '120 psig', 'Shipped to site. Final dossier submitted.'),
  (v_project1_id, 'Column', 'C-401', 'JOB-2024-1087-06', 'MFG-2024-006', 'Stripping Column', '60" x 35''', 'SA-516 Gr.70', 'ASME VIII Div.1', 'documentation', 20, 'documentation', 'Mike Johnson', NULL, 'David Kim', 'Ahmed Al-Rashid', 'Documentation', 'high', 'Design Pressure', '50 psig', 'Design Temp', '600°F', 'Trays', '20', 'Corrosion Allowance', '3mm', 'Hydro Test', '75 psig', 'P&ID Rev-05 approved. Datasheet in progress.'),
  (v_project2_id, 'Separator', 'V-201', 'JOB-2024-4521-01', 'MFG-2024-007', 'HP Separator', '42" x 18''', 'SA-516 Gr.70', 'ASME VIII Div.1', 'in-progress', 60, 'fabrication', 'Tom Baker', 'Robert Lee', 'Lisa Park', 'John Martinez', 'Fabrication Bay 2', 'high', 'Design Pressure', '350 psig', 'Design Temp', '900°F', 'MAWP', '385 psig', 'Corrosion Allowance', '3mm', 'Hydro Test', '525 psig', 'Weld joint 4 under NDT.'),
  (v_project2_id, 'Separator', 'V-202', 'JOB-2024-4521-02', 'MFG-2024-008', 'LP Separator', '36" x 14''', 'SA-516 Gr.70', 'ASME VIII Div.1', 'documentation', 35, 'documentation', 'Tom Baker', NULL, 'Lisa Park', 'John Martinez', 'Documentation', 'high', 'Design Pressure', '150 psig', 'Design Temp', '650°F', 'MAWP', '165 psig', 'Corrosion Allowance', '3mm', 'Hydro Test', '225 psig', 'GA drawing Rev-03 received with comments.');

  -- Equipment IDs are queried via subqueries when inserting progress entries

  -- ========== 5. VDCR RECORDS (35 entries) ==========
  -- Project 1 VDCR (20 entries)
  INSERT INTO public.vdcr_records (project_id, firm_id, sr_no, equipment_tag_numbers, mfg_serial_numbers, job_numbers, client_doc_no, internal_doc_no, document_name, revision, code_status, status, department, remarks)
  VALUES
  (v_project1_id, v_firm_id, '1', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-101', 'VDCR-2024-001', 'Datasheet', 'Rev-08', 'Code 1', 'approved', 'Mechanical', 'Approved as per Rev-08.'),
  (v_project1_id, v_firm_id, '2', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-102', 'VDCR-2024-002', 'General Arrangement', 'Rev-05', 'Code 2', 'approved', 'Mechanical', 'Approved with as-built notes.'),
  (v_project1_id, v_firm_id, '3', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-103', 'VDCR-2024-003', 'Fabrication Drawing', 'Rev-12', 'Code 1', 'sent-for-approval', 'Mechanical', NULL),
  (v_project1_id, v_firm_id, '4', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-104', 'VDCR-2024-004', 'MTR', 'Rev-00', 'Code 3', 'approved', 'Quality', 'For information only.'),
  (v_project1_id, v_firm_id, '5', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-105', 'VDCR-2024-005', 'WPS/PQR', 'Rev-02', 'Code 2', 'approved', 'Quality', 'Approved.'),
  (v_project1_id, v_firm_id, '6', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-106', 'VDCR-2024-006', 'Hydro Test Report', 'Rev-00', 'Code 3', 'pending', 'Quality', NULL),
  (v_project1_id, v_firm_id, '7', ARRAY['V-102'], ARRAY['MFG-2024-002'], ARRAY['JOB-2024-1087-02'], 'ARAMCO-DOC-107', 'VDCR-2024-007', 'Datasheet', 'Rev-04', 'Code 1', 'received-for-comment', 'Mechanical', 'Minor comments on nozzle schedule.'),
  (v_project1_id, v_firm_id, '8', ARRAY['V-102'], ARRAY['MFG-2024-002'], ARRAY['JOB-2024-1087-02'], 'ARAMCO-DOC-108', 'VDCR-2024-008', 'P&ID', 'Rev-11', 'Code 1', 'approved', 'Process', 'Approved Rev-11.'),
  (v_project1_id, v_firm_id, '9', ARRAY['V-102'], ARRAY['MFG-2024-002'], ARRAY['JOB-2024-1087-02'], 'ARAMCO-DOC-109', 'VDCR-2024-009', 'General Arrangement', 'Rev-03', 'Code 2', 'approved', 'Mechanical', NULL),
  (v_project1_id, v_firm_id, '10', ARRAY['E-201'], ARRAY['MFG-2024-003'], ARRAY['JOB-2024-1087-03'], 'ARAMCO-DOC-110', 'VDCR-2024-010', 'Datasheet', 'Rev-02', 'Code 1', 'sent-for-approval', 'Mechanical', NULL),
  (v_project1_id, v_firm_id, '11', ARRAY['E-201'], ARRAY['MFG-2024-003'], ARRAY['JOB-2024-1087-03'], 'ARAMCO-DOC-111', 'VDCR-2024-011', 'Design Calculation', 'Rev-06', 'Code 2', 'approved', 'Mechanical', 'Approved.'),
  (v_project1_id, v_firm_id, '12', ARRAY['E-202'], ARRAY['MFG-2024-004'], ARRAY['JOB-2024-1087-04'], 'ARAMCO-DOC-112', 'VDCR-2024-012', 'Datasheet', 'Rev-00', 'Code 1', 'pending', 'Mechanical', NULL),
  (v_project1_id, v_firm_id, '13', ARRAY['D-301'], ARRAY['MFG-2024-005'], ARRAY['JOB-2024-1087-05'], 'ARAMCO-DOC-113', 'VDCR-2024-013', 'Final Dossier', 'Rev-02', 'Code 4', 'approved', 'Documentation', 'As-built submitted.'),
  (v_project1_id, v_firm_id, '14', ARRAY['D-301'], ARRAY['MFG-2024-005'], ARRAY['JOB-2024-1087-05'], 'ARAMCO-DOC-114', 'VDCR-2024-014', 'NDT Report', 'Rev-00', 'Code 3', 'approved', 'Quality', NULL),
  (v_project1_id, v_firm_id, '15', ARRAY['C-401'], ARRAY['MFG-2024-006'], ARRAY['JOB-2024-1087-06'], 'ARAMCO-DOC-115', 'VDCR-2024-015', 'P&ID', 'Rev-05', 'Code 1', 'approved', 'Process', 'Approved.'),
  (v_project1_id, v_firm_id, '16', ARRAY['C-401'], ARRAY['MFG-2024-006'], ARRAY['JOB-2024-1087-06'], 'ARAMCO-DOC-116', 'VDCR-2024-016', 'Datasheet', 'Rev-03', 'Code 1', 'received-for-comment', 'Mechanical', 'Update tray spacing per client comment.'),
  (v_project1_id, v_firm_id, '17', ARRAY['C-401'], ARRAY['MFG-2024-006'], ARRAY['JOB-2024-1087-06'], 'ARAMCO-DOC-117', 'VDCR-2024-017', 'Material Take-Off', 'Rev-01', 'Code 2', 'approved', 'Mechanical', NULL),
  (v_project1_id, v_firm_id, '18', ARRAY['V-101','V-102'], ARRAY['MFG-2024-001','MFG-2024-002'], ARRAY['JOB-2024-1087-01','JOB-2024-1087-02'], 'ARAMCO-DOC-118', 'VDCR-2024-018', 'Test Procedure', 'Rev-04', 'Code 2', 'approved', 'Quality', NULL),
  (v_project1_id, v_firm_id, '19', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-119', 'VDCR-2024-019', 'Weld Map', 'Rev-02', 'Code 2', 'approved', 'Quality', NULL),
  (v_project1_id, v_firm_id, '20', ARRAY['V-101'], ARRAY['MFG-2024-001'], ARRAY['JOB-2024-1087-01'], 'ARAMCO-DOC-120', 'VDCR-2024-020', 'Design Calculation', 'Rev-09', 'Code 2', 'approved', 'Mechanical', 'Thickness calc approved.');

  -- Project 2 VDCR (15 entries)
  INSERT INTO public.vdcr_records (project_id, firm_id, sr_no, equipment_tag_numbers, mfg_serial_numbers, job_numbers, client_doc_no, internal_doc_no, document_name, revision, code_status, status, department, remarks)
  VALUES
  (v_project2_id, v_firm_id, '1', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-201', 'VDCR-2024-021', 'Datasheet', 'Rev-07', 'Code 1', 'approved', 'Mechanical', 'Approved.'),
  (v_project2_id, v_firm_id, '2', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-202', 'VDCR-2024-022', 'Fabrication Drawing', 'Rev-14', 'Code 1', 'received-for-comment', 'Mechanical', 'Revise nozzle N3 orientation per comment.'),
  (v_project2_id, v_firm_id, '3', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-203', 'VDCR-2024-023', 'MTR', 'Rev-00', 'Code 3', 'approved', 'Quality', NULL),
  (v_project2_id, v_firm_id, '4', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-204', 'VDCR-2024-024', 'NDT Report', 'Rev-00', 'Code 3', 'pending', 'Quality', NULL),
  (v_project2_id, v_firm_id, '5', ARRAY['V-202'], ARRAY['MFG-2024-008'], ARRAY['JOB-2024-4521-02'], 'EM-DOC-205', 'VDCR-2024-025', 'Datasheet', 'Rev-04', 'Code 1', 'approved', 'Mechanical', NULL),
  (v_project2_id, v_firm_id, '6', ARRAY['V-202'], ARRAY['MFG-2024-008'], ARRAY['JOB-2024-4521-02'], 'EM-DOC-206', 'VDCR-2024-026', 'General Arrangement', 'Rev-05', 'Code 2', 'received-for-comment', 'Mechanical', 'Update support details.'),
  (v_project2_id, v_firm_id, '7', ARRAY['V-202'], ARRAY['MFG-2024-008'], ARRAY['JOB-2024-4521-02'], 'EM-DOC-207', 'VDCR-2024-027', 'P&ID', 'Rev-08', 'Code 1', 'approved', 'Process', NULL),
  (v_project2_id, v_firm_id, '8', ARRAY['V-201','V-202'], ARRAY['MFG-2024-007','MFG-2024-008'], ARRAY['JOB-2024-4521-01','JOB-2024-4521-02'], 'EM-DOC-208', 'VDCR-2024-028', 'Test Procedure', 'Rev-02', 'Code 2', 'approved', 'Quality', NULL),
  (v_project2_id, v_firm_id, '9', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-209', 'VDCR-2024-029', 'WPS/PQR', 'Rev-01', 'Code 2', 'approved', 'Quality', NULL),
  (v_project2_id, v_firm_id, '10', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-210', 'VDCR-2024-030', 'Design Calculation', 'Rev-05', 'Code 2', 'approved', 'Mechanical', NULL),
  (v_project2_id, v_firm_id, '11', ARRAY['V-202'], ARRAY['MFG-2024-008'], ARRAY['JOB-2024-4521-02'], 'EM-DOC-211', 'VDCR-2024-031', 'Fabrication Drawing', 'Rev-06', 'Code 1', 'sent-for-approval', 'Mechanical', NULL),
  (v_project2_id, v_firm_id, '12', ARRAY['V-202'], ARRAY['MFG-2024-008'], ARRAY['JOB-2024-4521-02'], 'EM-DOC-212', 'VDCR-2024-032', 'Material Take-Off', 'Rev-00', 'Code 2', 'approved', 'Mechanical', NULL),
  (v_project2_id, v_firm_id, '13', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-213', 'VDCR-2024-033', 'Weld Map', 'Rev-01', 'Code 2', 'approved', 'Quality', NULL),
  (v_project2_id, v_firm_id, '14', ARRAY['V-201'], ARRAY['MFG-2024-007'], ARRAY['JOB-2024-4521-01'], 'EM-DOC-214', 'VDCR-2024-034', 'Hydro Test Report', 'Rev-00', 'Code 3', 'pending', 'Quality', NULL),
  (v_project2_id, v_firm_id, '15', ARRAY['V-202'], ARRAY['MFG-2024-008'], ARRAY['JOB-2024-4521-02'], 'EM-DOC-215', 'VDCR-2024-035', 'Design Calculation', 'Rev-03', 'Code 2', 'approved', 'Mechanical', NULL);

  -- ========== 6. VDCR REVISION EVENTS (sample: add for first 5 VDCR records) ==========
  FOR v_vdcr_id IN SELECT id FROM public.vdcr_records WHERE project_id = v_project1_id ORDER BY sr_no LIMIT 5
  LOOP
    -- VDCR 1: 8 revisions (Rev-00 to Rev-08)
    IF (SELECT sr_no FROM public.vdcr_records WHERE id = v_vdcr_id) = '1' THEN
      INSERT INTO public.vdcr_revision_events (vdcr_record_id, event_type, revision_number, event_date, estimated_return_date, actual_return_date, days_elapsed, notes, created_by)
      VALUES
      (v_vdcr_id, 'submitted', 'Rev-00', CURRENT_TIMESTAMP - INTERVAL '90 days', CURRENT_TIMESTAMP - INTERVAL '83 days', NULL, 'Initial submission.', v_user_id),
      (v_vdcr_id, 'received', 'Rev-01', CURRENT_TIMESTAMP - INTERVAL '83 days', NULL, 7, 'Received with comments - update design pressure.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-01', CURRENT_TIMESTAMP - INTERVAL '76 days', CURRENT_TIMESTAMP - INTERVAL '69 days', NULL, 'Resubmitted per comments.', v_user_id),
      (v_vdcr_id, 'received', 'Rev-02', CURRENT_TIMESTAMP - INTERVAL '69 days', NULL, 7, 'Minor nozzle schedule comments.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-02', CURRENT_TIMESTAMP - INTERVAL '62 days', CURRENT_TIMESTAMP - INTERVAL '55 days', NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-03', CURRENT_TIMESTAMP - INTERVAL '55 days', NULL, 7, 'Approved with minor edits.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-03', CURRENT_TIMESTAMP - INTERVAL '48 days', CURRENT_TIMESTAMP - INTERVAL '41 days', NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-04', CURRENT_TIMESTAMP - INTERVAL '41 days', NULL, 7, 'Comments on material spec.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-04', CURRENT_TIMESTAMP - INTERVAL '34 days', CURRENT_TIMESTAMP - INTERVAL '27 days', NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-05', CURRENT_TIMESTAMP - INTERVAL '27 days', NULL, 7, 'Approved.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-05', CURRENT_TIMESTAMP - INTERVAL '20 days', CURRENT_TIMESTAMP - INTERVAL '13 days', NULL, 'Final revision.', v_user_id),
      (v_vdcr_id, 'received', 'Rev-06', CURRENT_TIMESTAMP - INTERVAL '13 days', NULL, 7, 'Approved as-is.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-06', CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 days', NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-07', CURRENT_TIMESTAMP - INTERVAL '2 days', NULL, 4, 'Approved.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-07', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL, NULL, 'Rev-08 submitted.', v_user_id),
      (v_vdcr_id, 'received', 'Rev-08', CURRENT_TIMESTAMP, NULL, 1, 'Approved as per Rev-08.', v_user_id);
    END IF;
    -- VDCR 3: 12 revisions (Fabrication Drawing)
    IF (SELECT sr_no FROM public.vdcr_records WHERE id = v_vdcr_id) = '3' THEN
      FOR v_i IN 0..11 LOOP
        INSERT INTO public.vdcr_revision_events (vdcr_record_id, event_type, revision_number, event_date, estimated_return_date, actual_return_date, days_elapsed, notes, created_by)
        VALUES
        (v_vdcr_id, 'submitted', 'Rev-' || LPAD((v_i)::text, 2, '0'), CURRENT_TIMESTAMP - INTERVAL '1 day' * (90 - v_i * 7), CURRENT_TIMESTAMP - INTERVAL '1 day' * (83 - v_i * 7), NULL, 'Submitted Rev-' || LPAD((v_i)::text, 2, '0'), v_user_id),
        (v_vdcr_id, 'received', 'Rev-' || LPAD((v_i + 1)::text, 2, '0'), CURRENT_TIMESTAMP - INTERVAL '1 day' * (83 - v_i * 7), NULL, 7, CASE WHEN v_i < 11 THEN 'Received with comments.' ELSE 'Approved.' END, v_user_id);
      END LOOP;
    END IF;
    -- VDCR 4: 2 revisions (MTR - simple)
    IF (SELECT sr_no FROM public.vdcr_records WHERE id = v_vdcr_id) = '4' THEN
      INSERT INTO public.vdcr_revision_events (vdcr_record_id, event_type, revision_number, event_date, estimated_return_date, actual_return_date, days_elapsed, notes, created_by)
      VALUES
      (v_vdcr_id, 'submitted', 'Rev-00', CURRENT_TIMESTAMP - INTERVAL '14 days', CURRENT_TIMESTAMP - INTERVAL '10 days', NULL, 'For information.', v_user_id),
      (v_vdcr_id, 'received', 'Rev-00', CURRENT_TIMESTAMP - INTERVAL '10 days', NULL, 4, 'Acknowledged.', v_user_id);
    END IF;
  END LOOP;

  -- Add revision events for Project 2 VDCR (first 3)
  FOR v_vdcr_id IN SELECT id FROM public.vdcr_records WHERE project_id = v_project2_id ORDER BY sr_no LIMIT 3
  LOOP
    IF (SELECT sr_no FROM public.vdcr_records WHERE id = v_vdcr_id) = '1' THEN
      INSERT INTO public.vdcr_revision_events (vdcr_record_id, event_type, revision_number, event_date, estimated_return_date, actual_return_date, days_elapsed, notes, created_by)
      VALUES
      (v_vdcr_id, 'submitted', 'Rev-00', CURRENT_TIMESTAMP - INTERVAL '45 days', NULL, NULL, 'Initial.', v_user_id),
      (v_vdcr_id, 'received', 'Rev-01', CURRENT_TIMESTAMP - INTERVAL '38 days', NULL, 7, 'Comments.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-01', CURRENT_TIMESTAMP - INTERVAL '31 days', NULL, NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-02', CURRENT_TIMESTAMP - INTERVAL '24 days', NULL, 7, NULL, v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-02', CURRENT_TIMESTAMP - INTERVAL '17 days', NULL, NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-03', CURRENT_TIMESTAMP - INTERVAL '10 days', NULL, 7, 'Approved.', v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-03', CURRENT_TIMESTAMP - INTERVAL '5 days', NULL, NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-04', CURRENT_TIMESTAMP - INTERVAL '2 days', NULL, 3, NULL, v_user_id),
      (v_vdcr_id, 'submitted', 'Rev-04', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL, NULL, NULL, v_user_id),
      (v_vdcr_id, 'received', 'Rev-05', CURRENT_TIMESTAMP, NULL, 1, 'Approved.', v_user_id);
    END IF;
    IF (SELECT sr_no FROM public.vdcr_records WHERE id = v_vdcr_id) = '2' THEN
      FOR v_i IN 0..13 LOOP
        INSERT INTO public.vdcr_revision_events (vdcr_record_id, event_type, revision_number, event_date, estimated_return_date, actual_return_date, days_elapsed, notes, created_by)
        VALUES
        (v_vdcr_id, 'submitted', 'Rev-' || LPAD((v_i)::text, 2, '0'), CURRENT_TIMESTAMP - INTERVAL '1 day' * (105 - v_i * 7), NULL, NULL, 'Submitted.', v_user_id),
        (v_vdcr_id, 'received', 'Rev-' || LPAD((v_i + 1)::text, 2, '0'), CURRENT_TIMESTAMP - INTERVAL '1 day' * (98 - v_i * 7), NULL, 7, CASE WHEN v_i < 13 THEN 'Comments.' ELSE 'Approved.' END, v_user_id);
      END LOOP;
    END IF;
  END LOOP;

  -- ========== 7. VDCR DOCUMENT HISTORY (sample for first 3 VDCR) ==========
  FOR v_vdcr_id IN SELECT id FROM public.vdcr_records WHERE project_id = v_project1_id ORDER BY sr_no LIMIT 3
  LOOP
    INSERT INTO public.vdcr_document_history (vdcr_record_id, version_number, action, previous_status, new_status, changed_by, remarks)
    VALUES
    (v_vdcr_id, 'Rev-00', 'created', NULL, 'pending', v_user_id, 'Document created.'),
    (v_vdcr_id, 'Rev-00', 'sent-for-review', 'pending', 'sent-for-approval', v_user_id, 'Submitted to client.'),
    (v_vdcr_id, 'Rev-01', 'received-for-comment', 'sent-for-approval', 'received-for-comment', v_user_id, 'Client comments received.'),
    (v_vdcr_id, 'Rev-01', 'updated', 'received-for-comment', 'pending', v_user_id, 'Incorporated comments.'),
    (v_vdcr_id, 'Rev-01', 'sent-for-review', 'pending', 'sent-for-approval', v_user_id, 'Resubmitted.'),
    (v_vdcr_id, 'Rev-02', 'received-for-comment', 'sent-for-approval', 'received-for-comment', v_user_id, 'Minor comments.'),
    (v_vdcr_id, 'Rev-02', 'updated', 'received-for-comment', 'pending', v_user_id, NULL),
    (v_vdcr_id, 'Rev-02', 'sent-for-review', 'pending', 'sent-for-approval', v_user_id, NULL),
    (v_vdcr_id, 'Rev-03', 'approved', 'sent-for-approval', 'approved', v_user_id, 'Approved by client.');
  END LOOP;

  -- ========== 8. EQUIPMENT PROGRESS ENTRIES ==========
  FOR v_equip_id IN SELECT id FROM public.equipment WHERE project_id = v_project1_id
  LOOP
    INSERT INTO public.equipment_progress_entries (equipment_id, entry_text, entry_type)
    VALUES
    (v_equip_id, 'Datasheet Rev-02 approved by client. Proceeding to fabrication.', 'milestone'),
    (v_equip_id, 'Material received - SA-516 Gr.70 plates. MTR verified.', 'update'),
    (v_equip_id, 'Shell rolling completed. Fit-up in progress.', 'update');
  END LOOP;

  FOR v_equip_id IN SELECT id FROM public.equipment WHERE project_id = v_project2_id
  LOOP
    INSERT INTO public.equipment_progress_entries (equipment_id, entry_text, entry_type)
    VALUES
    (v_equip_id, 'Client visit completed. Minor punch items noted.', 'update'),
    (v_equip_id, 'Documentation package submitted for final review.', 'milestone');
  END LOOP;

  -- ========== 9. PROJECT MEMBERS ==========
  INSERT INTO public.project_members (project_id, name, email, position, role, status, user_id)
  VALUES
  (v_project1_id, 'Ahmed Al-Rashid', 'ahmed@demofab.com', 'Project Manager', 'project_manager', 'active', v_user_id),
  (v_project1_id, 'Mike Johnson', 'mike@demofab.com', 'Supervisor', 'editor', 'active', v_user_id),
  (v_project2_id, 'John Martinez', 'john@demofab.com', 'Project Manager', 'project_manager', 'active', v_user_id),
  (v_project2_id, 'Tom Baker', 'tom@demofab.com', 'Supervisor', 'editor', 'active', v_user_id);

  -- Update project equipment counts
  UPDATE public.projects SET equipment_count = 6, active_equipment = 6 WHERE id = v_project1_id;
  UPDATE public.projects SET equipment_count = 5, active_equipment = 5 WHERE id = v_project2_id;

  RAISE NOTICE 'Content filling complete. Firm: %, Projects: 2, Equipment: 8, VDCR: 35', v_firm_id;
END $$;
