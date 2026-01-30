# Content Filling Strategy for Engineering Project Management System

**Goal:** Generate highly relatable, realistic demo data so potential users (engineering equipment manufacturing companies) see the dashboard and think: *"Yes, that's exactly how my firm works—that's what we need."*

**Focus:** Content-filling database for accounts—projects, equipment (with technical data), VDCR entries (30–40+ with full revision history), progress updates, and documents.

---

## 1. Target User Profile

**End users:** Engineering equipment manufacturing companies  
- Pressure vessels, heat exchangers, columns, reactors, tanks, separators  
- Industries: Oil & gas, petrochemical, refining, power, LNG, chemical, pharmaceutical  
- Typical workflow: PO → Design → Fabrication → Documentation → VDCR cycle → Delivery  

---

## 2. Data Structure Overview

| Entity | Key Tables | What to Populate |
|--------|------------|------------------|
| **Firms** | `firms` | Demo manufacturing companies |
| **Projects** | `projects` | Client projects with PO, client, location, manager |
| **Equipment** | `equipment` | Tag numbers, mfg serial, job numbers, technical specs |
| **Progress** | `equipment_progress_entries` | Text-based update entries |
| **VDCR** | `vdcr_records`, `vdcr_document_history`, `vdcr_revision_events` | 30–40 entries, 2–15 revisions each |
| **Documents** | `equipment_documents`, project docs | References (can be placeholder URLs) |

---

## 3. AI Prompts for Data Generation

### Prompt 1: Generate Projects (5–8 projects)

```
You are generating realistic project data for an engineering equipment manufacturing company dashboard.

Create 5–8 projects with:
- name: Client + project type (e.g., "Saudi Aramco - Ras Tanura Expansion", "ExxonMobil - Beaumont Refinery Vessels")
- client: Major oil & gas / petrochemical client names
- location: Realistic plant locations (e.g., "Ras Tanura, Saudi Arabia", "Beaumont, TX")
- manager: Full name (e.g., "Ahmed Al-Rashid", "John Martinez")
- deadline: Date 6–18 months from project start
- po_number: Format like "PO-2024-XXXX" or "SO-ARAMCO-XXXX"
- scope_of_work: 1–2 sentences on equipment scope
- status: "active" or "completed"
- sales_order_date: Project start date
- client_industry: "Oil & Gas", "Petrochemical", "Power", "LNG", "Chemical"
- services_included: design, manufacturing, testing, commissioning, documentation (mix of true/false)

Output as JSON array. Make it feel like real EPC/owner projects.
```

### Prompt 2: Generate Equipment (per project, 3–12 items)

```
You are generating equipment records for an engineering manufacturing project.

For each equipment item, provide:
- type: "Pressure Vessel", "Heat Exchanger", "Column", "Reactor", "Storage Tank", "Separator", "Drum", "Skid"
- tag_number: Format "V-101", "E-205", "C-301", "R-401" (prefix + number)
- job_number: Format "JOB-2024-XXXX" or project-specific
- manufacturing_serial: "MFG-XXXXX" or "SN-YYYYMM-XXXX"
- name: Descriptive (e.g., "Primary Separator", "Regenerator Feed Heater")
- size: "48\" x 20'", "DN1200", "10m x 3m"
- material: "SA-516 Gr.70", "SS316L", "CS + 3mm Clad"
- design_code: "ASME VIII Div.1", "ASME VIII Div.2", "EN 13445"
- status: "pending", "in-progress", "documentation", "fabrication", "testing", "completed"
- progress: 0–100
- progress_phase: "documentation", "design", "fabrication", "testing", "completed"
- priority: "high", "medium", "low"
- location: "Shop A", "Fabrication Bay 2", "Testing Yard"
- supervisor, welder, qc_inspector, project_manager: Realistic names
- custom_field_1_name to custom_field_5_name: e.g., "Design Pressure", "Design Temp", "MAWP", "Corrosion Allowance", "Hydro Test Pressure"
- custom_field_1_value to custom_field_5_value: Matching values
- notes: Short technical or schedule note

Output as JSON array. Technical data must be consistent (e.g., MAWP vs design pressure).
```

### Prompt 3: Generate VDCR Records (30–40 entries per project)

```
You are generating VDCR (Vendor Document Control / Document Control) records for an engineering project.

Each VDCR record has:
- sr_no: Sequential "1", "2", "3"...
- equipment_tag_numbers: Array of tags (e.g., ["V-101", "V-102"])
- mfg_serial_numbers: Array matching equipment
- job_numbers: Array matching equipment
- client_doc_no: Client's document number (e.g., "ARAMCO-DOC-12345")
- internal_doc_no: Internal ref (e.g., "VDCR-2024-001")
- document_name: One of: "P&ID", "Datasheet", "Fabrication Drawing", "General Arrangement", "MTR", "WPS/PQR", "Test Procedure", "Hydro Test Report", "Design Calculation", "Material Take-Off", "Weld Map", "NDT Report", "Final Dossier"
- revision: "Rev-00", "Rev-01", "Rev-02" ... up to "Rev-15" for complex docs
- code_status: "Code 1", "Code 2", "Code 3", "Code 4" (ASME-style: 1=approve, 2=review, 3=info, 4=as-built)
- status: "pending", "sent-for-approval", "received-for-comment", "approved", "rejected"
- department: "Mechanical", "Process", "Quality", "Documentation"
- remarks: Brief comment when status is received-for-comment or approved

Create 30–40 VDCR entries per project. Mix:
- 40% with 2–3 revisions (simple docs like MTR, info-only)
- 30% with 5–8 revisions (datasheets, GA drawings)
- 30% with 10–15 revisions (P&IDs, fabrication drawings, critical docs)

Ensure document names and code statuses are realistic for engineering manufacturing.
```

### Prompt 4: Generate VDCR Revision Events (per VDCR record)

```
For each VDCR record, generate revision events in vdcr_revision_events.

Each event is either:
- event_type: "submitted" (we sent to client)
- event_type: "received" (client returned with comments/approval)

Cycle: submitted → received → submitted → received ... until final approval.

For each event:
- revision_number: "Rev-00", "Rev-01", etc.
- event_date: Realistic dates (spread over weeks/months)
- estimated_return_date: For submitted events
- actual_return_date: For received events
- days_elapsed: Days between submitted and received
- notes: "Sent for approval", "Received with minor comments - update nozzle orientation", "Approved as-is", "Rejected - revise thickness calculation"

Create events to match the revision count. E.g., 15 revisions = ~15 submitted + ~14 received (last one approved).
Output as JSON array with vdcr_record_id reference.
```

### Prompt 5: Generate VDCR Document History (per VDCR record)

```
For each VDCR record, generate vdcr_document_history entries.

Each history entry tracks status changes:
- action: "created", "updated", "sent-for-review", "received-for-comment", "approved", "rejected", "pending-for-approval"
- previous_status, new_status: e.g., "pending" → "sent-for-approval" → "received-for-comment" → "approved"
- version_number: "Rev-00", "Rev-01", etc.
- remarks: Brief note

Create one history entry per status transition. Typical flow:
created → sent-for-review → received-for-comment → (repeat for each revision) → approved

Output as JSON array.
```

### Prompt 6: Generate Equipment Progress Entries (text-based updates)

```
Generate 3–8 progress entries per equipment item. These are text-based updates (equipment_progress_entries).

entry_type: "general", "milestone", "issue", "update"
entry_text examples:
- "Datasheet Rev-02 approved by client. Proceeding to fabrication."
- "Material received - SA-516 Gr.70 plates. MTR verified."
- "Shell rolling completed. Fit-up in progress."
- "Weld joint 3 under NDT. Results pending."
- "Hydro test scheduled for next week. Test procedure approved."
- "Client visit completed. Minor punch items noted."
- "Documentation package submitted for final review."

Make entries feel like real shop/project updates. Vary dates over equipment lifecycle.
Output as JSON array with equipment_id reference.
```

### Prompt 7: Generate Project-Level Context

```
Generate realistic context for engineering manufacturing:

- kickoff_meeting_notes: Bullet points from project kickoff (scope, schedule, client expectations)
- special_production_notes: Fabrication notes (material lead times, special NDT, client preferences)
- scope_of_work: 2–3 sentences
- client_focal_point: Name and role
- consultant: Third-party if applicable
- tpi_agency: "TÜV", "BV", "Lloyd's", "ABS" etc.

Output as JSON. Keep it concise and industry-authentic.
```

---

## 4. VDCR Revision Distribution (30–40 entries)

| Revision Count | % of Entries | Document Types |
|----------------|--------------|----------------|
| 2–3 revs | 40% | MTR, NDT Report, Simple datasheet, Info-only |
| 5–8 revs | 30% | Datasheet, GA, Test procedure, WPS/PQR |
| 10–15 revs | 30% | P&ID, Fabrication drawing, Design calc, Critical docs |

**Example VDCR mix per project:**
- 5–6 P&IDs / PFDs
- 8–10 Datasheets
- 6–8 Fabrication / GA drawings
- 4–5 MTRs, WPS/PQR
- 4–5 Test procedures, reports
- 3–4 Design calculations
- 2–3 Final dossier / as-built

---

## 5. Equipment Types & Technical Fields

| Type | Typical Custom Fields |
|------|------------------------|
| Pressure Vessel | Design Pressure, Design Temp, MAWP, Material, Hydro Test Pressure |
| Heat Exchanger | Design Pressure/Temp, Tube/Shell material, TEMA class |
| Column | Height, Diameter, Trays/Packing, Design Pressure |
| Reactor | Design Pressure/Temp, Catalyst, Lining |
| Tank | Capacity, Design Pressure, Roof type |
| Separator | Design Pressure, Retention time, Inlet/outlet |

---

## 6. Code Status (VDCR)

- **Code 1:** For approval (client must approve)
- **Code 2:** For review (client reviews, we incorporate)
- **Code 3:** For information (no formal approval)
- **Code 4:** As-built (final record)

---

## 7. Implementation Approach

1. **Create seed SQL script** – Use AI-generated JSON, convert to `INSERT` statements.
2. **Run in order** – firms → users → projects → equipment → vdcr_records → vdcr_revision_events → vdcr_document_history → equipment_progress_entries.
3. **Respect foreign keys** – Capture UUIDs from inserts for child records.
4. **Optional:** Build a small Node/Python script that reads JSON and outputs SQL, or uses Supabase client to insert via API.

---

## 8. Quick Reference: Table Columns

### projects (key)
`name, client, location, manager, deadline, po_number, firm_id, scope_of_work, status, sales_order_date, client_industry, kickoff_meeting_notes, special_production_notes, services_included`

### equipment (key)
`project_id, type, tag_number, job_number, manufacturing_serial, name, size, material, design_code, status, progress, progress_phase, supervisor, welder, qc_inspector, custom_field_1_name/value ... custom_field_5_name/value`

### vdcr_records (key)
`project_id, sr_no, equipment_tag_numbers, mfg_serial_numbers, job_numbers, client_doc_no, internal_doc_no, document_name, revision, code_status, status, department, remarks`

### vdcr_revision_events (key)
`vdcr_record_id, event_type, revision_number, event_date, estimated_return_date, actual_return_date, days_elapsed, notes`

### vdcr_document_history (key)
`vdcr_record_id, version_number, action, previous_status, new_status, changed_by, remarks`

### equipment_progress_entries (key)
`equipment_id, entry_text, entry_type, created_at`

---

## 9. Next Steps

1. Run **Prompt 1** to get projects JSON.
2. Run **Prompt 2** for each project to get equipment JSON.
3. Run **Prompt 3** to get 30–40 VDCR records per project.
4. Run **Prompt 4** and **Prompt 5** for each VDCR to get revision events and history.
5. Run **Prompt 6** for each equipment to get progress entries.
6. Convert to SQL or use API to insert into Supabase.
7. Optionally add placeholder document URLs in `equipment_documents` and project doc tables.

---

*This strategy is designed so engineering equipment manufacturing firms see familiar workflows, document types, revision cycles, and technical data—making the demo feel like their own operations.*
