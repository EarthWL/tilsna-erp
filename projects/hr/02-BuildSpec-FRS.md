# Build Spec / FRS สำหรับ Agent — โมดูลทรัพยากรบุคคล (HR) · TILSNA ERP (Nocoly)

> คู่กับ `01-BRD.md` — BRD บอก "ทำอะไร" · ไฟล์นี้บอก "ทำกับ object ไหน ด้วย ID อะไร เสร็จแล้ววัดอย่างไร"
> **สถานะโมดูล: Greenfield ในแอป Brownfield** — แอปมีโมดูลบัญชี 34 ตารางทำงานอยู่แล้ว แต่ **ยังไม่มี object ของ HR แม้แต่ชิ้นเดียว** (ยืนยันด้วย `get_app_info` · `get_optionset_list` · `get_role_list` เมื่อ 26 ส.ค. 2569)
> ⇒ **ID ของ HR ทุกตัวเป็น `<TBD>`** ต้องเติมทันทีหลังสร้าง object จริง · **ID ของโมดูลบัญชีทุกตัวในไฟล์นี้ดึงจากเซิร์ฟเวอร์จริงแล้ว ใช้ได้เลย ห้ามแก้**
> อัปเดต: 28 สิงหาคม 2569 (ต่อเนื่อง 5 — ✅ **Gap G-02 ปิดแล้ว: ฝ่ายบัญชีสร้างบัญชีใหม่ 3 รายการในผังบัญชีจริง (`530102`/`210402`/`210304`) + เพิ่ม `event_code`=PAYROLL_ACCRUAL/PAYROLL_PAYMENT — HR ผูก `hr_pay_component.biz_coa_account` ครบ 6/6 (P5-4 ปิดเต็ม) — WF-HR-10 source-of-truth ยืนยันแล้ว: `ac_posting_rule` หลัก / `hr_pay_component` fallback — G-05 (อัตรา SSO/ภาษี/เลขทะเบียนบริษัท) ยังเปิดอยู่ ห้ามเดา** — ก่อนหน้านั้น: ต่อเนื่อง 4 — 🟢 **WF-HR-05/WF-HR-06 สร้าง+publish สำเร็จผ่าน MCP ทั้งคู่** (main+inner ทั้ง 4 process, validate สะอาด 0 error) ยืนยัน D-16 fix ใช้ได้กับ build จริง — WF-HR-06 v1 ครอบคลุมเฉพาะ `hr_leave_request` (ดู D-18: `hr_ot_request` ไม่มีฟิลด์ `submitted_at`) — ⚠️ **live-fire test ของทั้งคู่ยังทำไม่ได้เพราะ D-17: worksheet_event workflow ทั้งหมดไม่ยิงเลยตอนนี้** เป็นปัญหาระดับ session/environment/platform ไม่ใช่ WF-HR-01 เจาะจง (re-verify WF-HR-01 + sanity-check WF-HR-04 ทั้งคู่ไม่ยิง แม้โครงสร้าง published สมบูรณ์) — บล็อกการพิสูจน์ Test recipe ที่ต้องยิงจริงของทุก workflow จนกว่าจะคลี่คลาย ส่วนการสร้าง/publish โครงสร้างยังทำต่อได้ปกติ — ก่อนหน้านั้น: ต่อเนื่อง 3 — 🟢 D-16: D-13 คลี่คลายแล้ว! root cause คือต้อง publish inner sub_process ก่อน outer เสมอ — ดู Known Issues ใน `04-CLAUDE-memory.md`)

---

## §0. กฎปฏิบัติของ Agent (DO / DON'T) — อ่านก่อนทำทุกครั้ง

### 🗺️ แผนที่ไฟล์ — เปิดไฟล์ไหนเมื่อไร (แยกไฟล์ 31 ส.ค. 2569)

| จะทำอะไร | เปิดไฟล์ไหน |
|---|---|
| เริ่มงานทุกครั้ง · กฎ DO/DON'T · ID Registry · NFR · วิธี verify · Data Model | **ไฟล์นี้** (`02-BuildSpec-FRS.md`) |
| สร้าง/แก้ field · optionset · relation · form rule · DoD ของ FR ตัวหนึ่ง | `21-FRS-Modules-HR.md` (เดิม §2) |
| สร้าง/แก้ workflow ตัวหนึ่ง (node-by-node · Test recipe) | `22-Workflow-Catalog-HR.md` (เดิม §3) |
| หา ID จริงของ worksheet / view / workflow ที่สร้างแล้ว | `17-ID-Registry-HR.md` |
| P3-1 (3 ตารางใบลา) — ค่าที่ **override** ไฟล์นี้ | `02b-BuildSpec-Addendum-P3-1.md` |

> ทั้ง 3 ไฟล์อ่านจบใน 1 call ทุกไฟล์ · `tools/sizecheck.sh` เฝ้าขนาดให้อยู่แล้ว


**Special operator ใน log:** `user-workflow` = workflow ยิงเอง · `user-api` = เขียนผ่าน API (เขียนมือ ไม่นับ) · `user-self` = ผู้ใช้กดเอง
⇒ **พิสูจน์ว่า workflow ทำงาน = ต้องเห็น `user-workflow` ใน `_updatedBy` จาก `get_record_details(includeSystemFields:true)`**

### DO
1. เปิด **§1 ID Registry** ก่อนพิมพ์ ID ใด ๆ — ห้ามพิมพ์จากความจำ
2. `get_app_info` ยืนยันว่าเป็นแอป **ERP - TILSNA** `deca7391-1761-424b-9af3-c8d043004ad3` ก่อน write แรกของทุก session (มี connector อื่นชี้เซิร์ฟเวอร์เดียวกัน)
3. **Verify ก่อน claim** — ผลว่างจาก tool ≠ ไม่มีของ
4. หลัง `create_*` ทุกครั้ง **อ่าน ID กลับแล้วเติมแทน `<TBD>` ใน §1 ทันที**
5. ทำ workflow ทีละ node สั้น ๆ แล้ว `validate_process` หลัง batch ทุกครั้ง
6. seed ข้อมูลด้วย `batch_create_records` + `triggerWorkflow:false`
7. เขียน DateTime ผ่าน API แบบระบุโซนเสมอ `"2569-08-26 08:00:00+07:00"` → ใช้รูปแบบ ค.ศ. `"2026-08-26 08:00:00+07:00"`
8. `update_worksheet` ส่ง `name` + `alias` **คู่กันเสมอ** และ **ห้ามส่ง `name` ระดับตารางพร้อม `editFields` ในคอลเดียว** · 🔴 **worksheet มีชื่อ 3 field แยกกัน: `alias`(อังกฤษ) / `entityName`("Data Name" — MCP `update_worksheet.name` แก้ตัวนี้) / `name`(ชื่อจริงที่ breadcrumb หัวตาราง — แก้ได้เฉพาะ hap CLI `worksheet update --name` เท่านั้น)** — สร้างตารางใหม่ต้องตรวจทั้ง 3 ให้ตรงกันเป็นไทย ไม่ใช่แค่ 2 (ยืนยัน 27 ส.ค. 2569)
9. ฟิลด์ธง (flag) ทุกตัว **ตั้ง `defaultValue = 0`** และส่งค่านี้กลับทุกครั้งที่แก้ฟิลด์ · workflow เช็กด้วย `not equal to 1`
10. Approval: ตารางหลักต้องมีฟิลด์ Collaborator + node **Update Record เขียนผู้อนุมัติก่อน** Initiate Approval · ใช้ **Data Update tab** แทน Branch ผลอนุมัติ · ตั้ง empty-approver policy = **Delegate by the workflow owner**
11. ทดสอบตามชนิด trigger — worksheet trigger ใช้ `create_record`/`update_record` (`triggerWorkflow:true`) **ไม่ใช่** `trigger_workflow`
12. ชื่อตารางและฟิลด์ **เป็นภาษาไทย** ให้เข้าชุดกับโมดูลบัญชี · alias เป็นอังกฤษ snake_case ขึ้นต้น `hr_`

### DON'T
| ห้าม | เพราะ | ทำแทน |
|---|---|---|
| `get_workflow_list` ว่าง → สรุปว่า "ไม่มี workflow" | คืนเฉพาะ PBP (ยืนยันแล้วในแอปนี้) | ดูหน้า Automated Workflow หรือ `get_workflow_structure` ด้วย processId ที่รู้ |
| ใส่ `filter` ใน trigger ของ `worksheet_event` | 🔴 workflow **ไม่ทำงานเลยและไม่มี error** (ยิงจริงในแอปนี้) | ใส่ `triggerFields` อย่างเดียว แล้วเอาเงื่อนไขไปไว้ใน branch node แรก |
| ใส่ฟิลด์ **Rollup** ลง `update_worksheet.editFields` | 🔴 กลายเป็น "จำนวนบันทึก" และหยุดคำนวณ ซ่อมได้เฉพาะผ่านหน้าจอ | แก้ฟิลด์ Rollup **ผ่านหน้าจอเท่านั้น** |
| ใส่ฟิลด์ **Dropdown ที่ผูก optionset ส่วนกลาง** ลง `editFields` | 🔴 การผูกหลุด **ถาวร** ผูกกลับไม่ได้ทั้ง API และหน้าจอ | แก้ผ่านหน้าจอ · ถ้าหลุดแล้วต้องลบฟิลด์แล้วสร้างใหม่ |
| ผูก shared optionset เข้ากับ Dropdown ผ่าน `addFields`/`create_worksheet` | 🔴 **ทำไม่ได้เลยในทุกกรณี** (ยืนยันซ้ำหลายรอบใน HR — ต่างจากที่เคยเข้าใจผิดว่าโมดูลบัญชีทำได้) `addFields` รับได้แค่ `options[]` inline เท่านั้น | สร้างเป็น **inline options** (label อังกฤษให้ตรงกับ optionset กลาง) แล้วไปผูกจริงใน **Browser UI** ภายหลัง |
| ส่ง `subType` กับฟิลด์ **Number** | รั่วลง `unit` เป็นขยะท้ายตัวเลข | ไม่ส่ง `subType` |
| ส่ง `type` กับฟิลด์ **OrgRole** | ไม่อยู่ใน enum ของ API | ไม่ส่ง `type` |
| ใช้ `subType` ทำ Text หลายบรรทัด | ผิดช่อง | `config:{textMode:"multiLine"}` |
| ใช้ค่า before-update ในเงื่อนไข | เข้าถึงไม่ได้ | ฟิลด์ธง |
| ใช้ `ne` กับฟิลด์ที่ค่าอาจว่าง | 🔴 เงื่อนไขไม่ผ่าน | ตั้ง default 0 + backfill record เดิม |
| ใช้ Formula field ใหม่ | dialog ไม่เสถียร สูตรหาย | Number + node `Function calculation` / `Numerical operations` / `Duration` |
| เชื่อ `isUnique` กันซ้ำ | API bypass ได้ | **Unique index** (Index Acceleration) |
| ล็อก record หลังอนุมัติด้วย role/workflow | ผิดเครื่องมือ | **Business Rule → Lock / Set all read-only** |
| `update_record` คัดลอกค่าฟิลด์ **OrgRole** | 🔴 เขียนค่าว่างเงียบ ๆ → approval abort | `get_single` หากฎ **ภายในสายอนุมัติ** แล้ว `approve.approvers` อ้าง `{kind:"field", node:<get_single>, fieldId:<approver_role_n>}` ตรง ๆ |
| อ้าง start node ของ approval_block ด้วย alias `approval_start` | ไม่มี alias (`找不到节点别名`) | `get_workflow_structure(<inner processId>)` แล้วอ้างด้วย `nodeId` |
| วาง branch `approval_result` นอกสายอนุมัติ | error `只能接在 approve 节点后` | วางต่อจาก approve node ในสายอนุมัติ |
| แก้ node ที่สร้างแล้ว | `nodeId` ถูกเมิน | `delete_process_node` แล้วสร้างใหม่ |
| สร้าง worksheet/optionset/role ซ้ำกับของบัญชี | ของมีแล้ว | เช็ก §1.2 "ของเดิมที่ต้องใช้ร่วม" ก่อน |
| ปิดงาน ✅ ทั้งที่ approval ยัง pending | ยังไม่พิสูจน์ | ใช้ ⚠️ จนกว่าผู้อนุมัติกดจริงใน To-do |
| ใช้ org-auth API กดอนุมัติแทนคน | ข้อสมมติ A-HR-15 ผู้ใช้ยังไม่อนุญาต | ให้คนกดใน To-do |
| ลบ record ที่อนุมัติแล้ว | NFR-HR-08 | ยกเลิก/กลับรายการ |

---

## §1. ID Registry (Master)

### §1.1 ระบบ

| รายการ | ค่า |
|---|---|
| Application | `deca7391-1761-424b-9af3-c8d043004ad3` (**ERP - TILSNA**) |
| Organization | `9680d433-5b6d-45d7-b6df-d05d3095f82f` |
| **MCP connector (ชื่อที่ใช้เรียก)** | **`ERP_-_TILSNA`** ⚠️ session นี้มี connector อื่นชี้เซิร์ฟเวอร์เดียวกัน (`API-Lab`, `MCP-ASM`, `-_WFA_System`, `hap-mcp-Demo_-`) — `get_app_info` ยืนยันก่อน write แรก |
| Host | `https://www.nocoly.com` |
| Surface R (org-auth API — กดอนุมัติแทนคน) | ❌ **ไม่ใช้** (A-HR-15) |
| เขตเวลา | UTC+07:00 (Asia/Bangkok) |

> ✅ **workflow สร้างผ่าน MCP ได้แล้ว** — `create_process` → `batch_create_process_nodes` → `validate_process` → `publish_process` และ **publish = เปิดใช้งานทันที ไม่มีขั้น Enable** (พิสูจน์แล้วในแอปนี้กับ WF-AC-01/02)
> ⚠️ **view / custom action / chart มี tool แต่ยังไม่เคยเรียกสำเร็จในแอปนี้** — Surface เขียนเป็น `MCP (unverified)` และ **DoD ต้องมีขั้นเปิดหน้าจอดูว่าโผล่จริงเสมอ**

### §1.2 กลุ่มในแอป (App Sections) — ต้องสร้างใหม่

| ลำดับ | ชื่อกลุ่ม | Section ID | หมายเหตุ |
|---|---|---|---|
| 1 | **Human Resources (HR)** (กลุ่มแม่) | **`6a8ee668e56d2e6eb7bd6cb3`** ✅ | สร้างแล้ว 26 ส.ค. 2569 — คู่ขนานกับ `Accounting (AC)` `6a841cbc3970d3f694ee96f3` |
| 2 | HR-00 Configuration | **`6a8ee66ce56d2e6eb7bd6cb4`** ✅ | สร้างแล้ว |
| 3 | HR-01 Master Data | **`6a8ee66ce56d2e6eb7bd6cb5`** ✅ | สร้างแล้ว |
| 4 | HR-02 Time and Attendance | **`6a8ee66ce56d2e6eb7bd6cb6`** ✅ | สร้างแล้ว |
| 5 | HR-03 Leave | **`6a8ee66ce56d2e6eb7bd6cb7`** ✅ | สร้างแล้ว |
| 6 | HR-04 Payroll | **`6a8ee66ce56d2e6eb7bd6cb8`** ✅ | สร้างแล้ว |
| 7 | HR-05 Talent (Recruitment · Performance · Training) | **`6a8ee66ce56d2e6eb7bd6cb9`** ✅ | สร้างแล้ว |
| 8 | HR-06 Welfare and Claims | **`6a8ee66ce56d2e6eb7bd6cba`** ✅ | สร้างแล้ว |

> ✅ **ยืนยันด้วย `get_app_info` เมื่อ 26 ส.ค. 2569** — กลุ่มทั้ง 8 ปรากฏจริงใต้แอป ERP - TILSNA ถัดจากกลุ่ม Accounting (AC)

### §1.3 Worksheets ของ HR

> ✅ **10 ตาราง HR-00 สร้างจริงแล้ว 26 ส.ค. 2569** ผ่านทางเลือกสำรอง `create_app_items`→`removeFields`→`addFields` (ดู §0/§2 หัวข้อ create_worksheet bug) · ✅ **seed ข้อมูลตั้งค่า P1-4 เสร็จแล้ว 26 ส.ค. 2569** สำหรับ 9/10 ตาราง (ยกเว้น `hr_approval_rule` ที่รอสร้าง role ก่อน — ดู FR-HR-01B) รวม 55 record ยืนยันด้วย `get_record_pivot_data` COUNT ทุกตาราง — รายละเอียดค่าที่ seed อยู่ในแต่ละ FR ด้านล่าง
> ✅ **P2-1/P2-2 เสร็จแล้ว 26 ส.ค. 2569** — `hr_position` (7 ฟิลด์) · `hr_job_level` (7 ฟิลด์) · `hr_employee` (36 ฟิลด์ รวม `supervisor` self-relation ที่เพิ่มทีหลังตามลำดับที่กำหนดใน §6) สร้างครบด้วยวิธีเดียวกับ HR-00 · ยืนยันด้วย `get_worksheet_structure` — field ID ครบใน §2 FR-HR-03/04 · ⚠️ ค้าง: (1) `gender`/`marital_status`/`employment_type`/`emp_status` บน `hr_employee` ยังเป็น **inline options** ไม่ได้ผูกกับ shared optionset `OS_HR_*` (ต้องลบแล้วสร้างใหม่ผ่าน Browser แบบเดียวกับที่บัญชีทำไปแล้ว 20 ฟิลด์ — ดู §0 กับดัก) (2) unique index จริง (Index Acceleration) ของ `emp_code`/`national_id`/`position_code`/`level_code` ยังไม่ได้ตั้ง — `isUnique` ที่ส่งใน `addFields` เป็นแค่ soft hint (ตรงกับ P2-5)
> ✅ **P4-1/P4-2 เสร็จแล้ว 27 ส.ค. 2569** — `hr_ot_request` · `hr_attendance` สร้างครบ (ดู §2 FR-HR-10/11B)
> ✅ **P5-1 เสร็จแล้ว 27 ส.ค. 2569** — `hr_pay_component` · `hr_pay_period` · `hr_salary_structure` สร้างครบด้วยวิธีเดียวกัน (ดู §2 FR-HR-12 12A/12B/12C) — Dropdown ทั้งหมด (`component_type` · `calc_method` · `period_status`) เป็น **inline options** เช่นเดิม (label อังกฤษตรงกับ `OS_HR_COMPONENT_TYPE`/`OS_HR_COMPONENT_CALC`/`OS_HR_PAY_PERIOD_STATUS` แต่ key/GUID คนละชุด — ยังไม่ bind จริง) · Relation ทั้งหมดผูกสำเร็จ (`hr_pay_component.coa_account`→`ac_coa` · `hr_pay_period.ac_period_ref`→`ac_period` · `hr_pay_period.voucher_ref`→`ac_voucher` · `hr_salary_structure.employee`→`hr_employee` · `hr_salary_structure.pay_component`→`hr_pay_component`) · Data Name ไทยตั้งแล้วทั้ง 3 ตารางผ่าน `addRecordButtonName`

| # | Worksheet (ไทย) | alias | Worksheet ID | View "ทั้งหมด" | กลุ่ม |
|---|---|---|---|---|---|
| 1 | การตั้งค่าโมดูลบุคคล | `hr_setting` | `6a8eebbd353e1b0e4a507477` | `6a8eebbd353e1b0e4a50747b` | HR-00  ✅ |
| 2 | วันหยุดประจำปี | `hr_holiday` | `6a8eebf7353e1b0e4a5074b5` | `6a8eebf7353e1b0e4a5074b9` | HR-00  ✅ |
| 3 | กะการทำงาน | `hr_shift` | `6a8eebf79762533b5b7184c5` | `6a8eebf79762533b5b7184c9` | HR-00  ✅ |
| 4 | ประเภทการลา | `hr_leave_type` | `6a8eebf89762533b5b7184cf` | `6a8eebf89762533b5b7184d3` | HR-00  ✅ |
| 5 | นโยบายสิทธิการลา | `hr_leave_policy` | `6a8eebf88b6633ef76f129e1` | `6a8eebf88b6633ef76f129e5` | HR-00  ✅ |
| 6 | อัตราค่าล่วงเวลา | `hr_ot_rate` | `6a8eebf88b6633ef76f129d6` | `6a8eebf88b6633ef76f129da` | HR-00  ✅ |
| 7 | อัตราเงินสมทบประกันสังคม | `hr_sso_rate` | `6a8eebf8353e1b0e4a5074c1` | `6a8eebf8353e1b0e4a5074c5` | HR-00  ✅ |
| 8 | ขั้นบันไดภาษีเงินได้บุคคลธรรมดา | `hr_tax_bracket` | `6a8eebf8ae2a0e3743a0bcec` | `6a8eebf8ae2a0e3743a0bcf0` | HR-00  ✅ |
| 9 | ค่าลดหย่อนภาษี | `hr_tax_allowance` | `6a8eebf8353e1b0e4a5074cb` | `6a8eebf8353e1b0e4a5074cf` | HR-00  ✅ |
| 10 | กฎการอนุมัติของโมดูลบุคคล | `hr_approval_rule` | `6a8eebf81378964f998499f8` | `6a8eebf81378964f998499fc` | HR-00  ✅ |
| 11 | ตำแหน่งงาน | `hr_position` | `6a8ef9901378964f99849a6d` | `6a8ef9901378964f99849a71` | HR-01  ✅ |
| 12 | ระดับพนักงาน | `hr_job_level` | `6a8ef9909762533b5b71859a` | `6a8ef9909762533b5b71859e` | HR-01  ✅ |
| 13 | **ทะเบียนพนักงาน** | `hr_employee` | `6a8efa5e9762533b5b7185c1` | `6a8efa5e9762533b5b7185c5` | HR-01  ✅ |
| 14 | สัญญาจ้าง | `hr_employment_contract` | `6a8efd1e9762533b5b718618` | `6a8efd1e9762533b5b71861c` | HR-01  ✅ |
| 15 | เหตุการณ์การจ้าง | `hr_employment_event` | `6a8efd1e8b6633ef76f12ad4` | `6a8efd1e8b6633ef76f12ad8` | HR-01  ✅ |
| 16 | ผู้ติดตามและผู้ใช้สิทธิลดหย่อน | `hr_dependent` | `6a8efd1eae2a0e3743a0bd93` | `6a8efd1eae2a0e3743a0bd97` | HR-01  ✅ |
| 17 | บัญชีธนาคารพนักงาน | `hr_bank_account` | `6a8efd1fae2a0e3743a0bd9d` | `6a8efd1fae2a0e3743a0bda1` | HR-01  ✅ |
| 18 | บันทึกลงเวลา | `hr_attendance` | `6a8fcd67353e1b0e4a507d32` ✅ | `6a8fcd67353e1b0e4a507d36` | HR-02  ✅ |
| 19 | ใบขออนุมัติล่วงเวลา | `hr_ot_request` | `6a8fcca48b6633ef76f13033` ✅ | `6a8fcca48b6633ef76f13037` | HR-02  ✅ |
| 20 | **ใบลา** | `hr_leave_request` | `6a8f2dbaae2a0e3743a0beaa` ✅ | `<TBD-V-20>` | HR-03  ✅ |
| 21 | สิทธิและยอดคงเหลือการลา | `hr_leave_balance` | `6a8f2dba353e1b0e4a507757` ✅ | `<TBD-V-21>` | HR-03  ✅ |
| 22 | รายการเคลื่อนไหวสิทธิลา | `hr_leave_ledger` | `6a8f2dba9762533b5b718675` ✅ | `<TBD-V-22>` | HR-03  ✅ |
| 23 | งวดจ่ายเงินเดือน | `hr_pay_period` | `6a8ff2878b6633ef76f1387b` ✅ | `6a8ff2878b6633ef76f1387f` | HR-04  ✅ |
| 24 | องค์ประกอบค่าจ้าง | `hr_pay_component` | `6a8ff2868b6633ef76f13871` ✅ | `6a8ff2868b6633ef76f13875` | HR-04  ✅ |
| 25 | โครงสร้างเงินเดือน | `hr_salary_structure` | `6a8ff287353e1b0e4a508550` ✅ | `6a8ff287353e1b0e4a508554` | HR-04  ✅ |
| 26 | **สลิปเงินเดือน** | `hr_payslip` | `6a904c85353e1b0e4a50ba05` ✅ | `6a904c85353e1b0e4a50ba09` | HR-04 |
| 27 | รายการในสลิปเงินเดือน | `hr_payslip_line` | `6a904c858b6633ef76f16a0b` ✅ | `6a904c858b6633ef76f16a0f` | HR-04 |
| 28 | การยื่นภาษีเงินได้หัก ณ ที่จ่าย (เงินเดือน) | `hr_pnd1_filing` | `6a904e72ae2a0e3743a0fd06` ✅ | `6a904e72ae2a0e3743a0fd0a` | HR-04 |
| 29 | หนังสือรับรองการหักภาษี ณ ที่จ่าย (พนักงาน) | `hr_wht_cert` | `6a904e73353e1b0e4a50ba83` ✅ | `6a904e73353e1b0e4a50ba87` | HR-04 |
| 30 | ใบขออัตรากำลัง | `hr_job_requisition` | `<TBD-WS-30>` | `<TBD-V-30>` | HR-05 |
| 31 | ผู้สมัคร | `hr_candidate` | `<TBD-WS-31>` | `<TBD-V-31>` | HR-05 |
| 32 | การสัมภาษณ์ | `hr_interview` | `<TBD-WS-32>` | `<TBD-V-32>` | HR-05 |
| 33 | รอบประเมินผล | `hr_appraisal_cycle` | `<TBD-WS-33>` | `<TBD-V-33>` | HR-05 |
| 34 | แบบประเมินผล | `hr_appraisal` | `<TBD-WS-34>` | `<TBD-V-34>` | HR-05 |
| 35 | รายการประเมิน | `hr_appraisal_item` | `<TBD-WS-35>` | `<TBD-V-35>` | HR-05 |
| 36 | หลักสูตรฝึกอบรม | `hr_course` | `<TBD-WS-36>` | `<TBD-V-36>` | HR-05 |
| 37 | การเข้าอบรม | `hr_training` | `<TBD-WS-37>` | `<TBD-V-37>` | HR-05 |
| 38 | สวัสดิการ | `hr_welfare_scheme` | `<TBD-WS-38>` | `<TBD-V-38>` | HR-06 |
| 39 | วงเงินสวัสดิการคงเหลือ | `hr_welfare_balance` | `<TBD-WS-39>` | `<TBD-V-39>` | HR-06 |
| 40 | **ใบเบิกสวัสดิการและค่าใช้จ่าย** | `hr_claim` | `<TBD-WS-40>` | `<TBD-V-40>` | HR-06 |
| 41 | รายการค่าใช้จ่าย | `hr_claim_line` | `<TBD-WS-41>` | `<TBD-V-41>` | HR-06 |

### §1.4 ของเดิมในโมดูลบัญชีที่ต้องใช้ร่วม — 🔴 **ห้ามสร้างซ้ำ · ห้ามแก้โครงสร้าง** (ID ดึงจากเซิร์ฟเวอร์จริงแล้ว)

| ตาราง (ไทย) | alias | Worksheet ID | HR ใช้ทำอะไร |
|---|---|---|---|
| หน่วยงาน / ศูนย์ต้นทุน | `ac_cost_center` | `6a85452b9b6999a714d26720` | ปลายทาง relation "หน่วยงาน" ของทะเบียนพนักงาน · มีฟิลด์ `hrms_unit_id` `6a85452b055f2288c5b741bc` เตรียมไว้แล้ว |
| ผังบัญชี | `ac_coa` | `6a85516e1049edca1eecd9b7` | ปลายทาง relation "ผังบัญชี" ขององค์ประกอบค่าจ้าง (79 record) |
| กฎการผ่านรายการ | `ac_posting_rule` | `6a85518c33560633b8cd6a15` | 🔴 คู่บัญชีของเงินเดือน — **ห้าม hard-code รหัสบัญชีใน workflow** |
| งวดบัญชี | `ac_period` | `6a8434d5055f2288c5b6d4b8` | ผูกงวดจ่ายเงินเดือนเข้างวดบัญชี · 🔴 **ห้ามลบสร้างใหม่** (ใบสำคัญมี Lookup ผูกอยู่) |
| ใบสำคัญ | `ac_voucher` | `6a85fb2e9b6999a714d2a53d` | ปลายทางที่ WF-HR-10 สร้างใบสำคัญเงินเดือน |
| รายการในใบสำคัญ | `ac_voucher_line` | `6a85fb3933560633b8cd9f40` | บรรทัดเดบิต/เครดิตของใบสำคัญเงินเดือน |
| ใบขออนุมัติเบิกจ่าย | `ac_pay_req` | `6a8677b19b6999a714d2aa83` | ปลายทางที่ WF-HR-12 ส่งใบเบิกสวัสดิการเข้าไปจ่าย |
| ประเภทเอกสาร | `ac_doc_type` | `6a8434dd9b6999a714d22e3d` | ประเภทเอกสารของใบขออนุมัติเบิกจ่ายที่ HR สร้าง |
| กฎการออกเลขที่เอกสาร | `ac_doc_number_rule` | `6a8434ea8b36df988c16ed84` | ใช้ซ้ำสำหรับเลขที่เอกสารของ HR (ไม่ต้องสร้างตารางใหม่) |
| กฎการอนุมัติตามวงเงิน | `ac_approval_rule` | `6a8434f18b36df988c16ed8e` | **อ้างอิงรูปแบบ** เท่านั้น — HR มีตารางกฎของตนเอง (`hr_approval_rule`) เพราะเกณฑ์เป็นจำนวนวัน/ชั่วโมง ไม่ใช่วงเงินอย่างเดียว |
| สมุดรายวัน | `ac_journal` | `6a8434da33560633b8cd2efd` | สมุดรายวันของใบสำคัญเงินเดือน |
| สกุลเงิน | `ac_currency` | `6a8545261049edca1eecd818` | required บนใบสำคัญ ⇒ WF-HR-10 ต้องส่งค่า |

**Field ID ของบัญชีที่ WF-HR-10 / WF-HR-12 ต้องเขียน (ดึงจริงแล้ว — ใช้ได้ทันที)**

| ตาราง | ฟิลด์ (ไทย) | alias | **field ID** | required |
|---|---|---|---|---|
| `ac_voucher` | คำอธิบายรายการ | `description` | `6a85fb2e055f2288c5b77753` | ✅ |
| `ac_voucher` | วันที่ใบสำคัญ | `voucher_date` | `6a85fb2e055f2288c5b77754` | ✅ |
| `ac_voucher` | สมุดรายวัน | `journal` | `6a85fb2e055f2288c5b77755` | ✅ (Relation → `ac_journal`) |
| `ac_voucher` | ประเภทเอกสาร | `voucher_type` | `6a85fb2e055f2288c5b77757` | ✅ (Relation → `ac_doc_type`) |
| `ac_voucher` | งวดบัญชี | `period` | `6a85fb2e055f2288c5b77759` | ✅ (Relation → `ac_period`) |
| `ac_voucher` | สกุลเงิน | `currency` | `6a85fb2e055f2288c5b7775b` | ✅ (Relation → `ac_currency`) |
| `ac_voucher` | เลขที่เอกสารต้นทาง | `source_doc_id` | `6a85fb2e055f2288c5b7775e` | — ใส่เลขงวดจ่าย |
| `ac_voucher` | เลขที่ใบสำคัญ | `voucher_no` | `6a85ff5933560633b8cd9f83` | isTitle |
| `ac_voucher` | สถานะ | `voucher_status` | `6a86016b1049edca1eed028a` | Dropdown ผูก optionset `a6c8a839-cd22-4459-b76f-7b35de24551e` |
| `ac_voucher` | **ระบบต้นทาง** | `source_module` | `6a86021833560633b8cd9fb1` | 🔴 ต้องเขียน key **`914f5226-dc4c-4572-bd4d-18bb278414b5`** (= Payroll) |
| `ac_voucher` | ประเภทเอกสารต้นทาง | `source_doc_type` | `6a85fb7033560633b8cd9f56` | ⚠️ **ไม่มี option สำหรับ HR** — ดู Gap G-01 |
| `ac_voucher` | (ระบบ) ผ่านรายการแล้ว | `posted_flag` | `6a85fb2e055f2288c5b7775f` | ธง |
| `ac_voucher_line` | ใบสำคัญ | `voucher` | `6a85fb399b6999a714d2a557` | ✅ (Relation ย้อนกลับ = `6a85fb399b6999a714d2a558`) |
| `ac_voucher_line` | บรรทัดที่ | `line_no` | `6a85fb399b6999a714d2a556` | ✅ |
| `ac_voucher_line` | คำอธิบายรายการ | `line_description` | `6a85fb399b6999a714d2a555` | isTitle |
| `ac_voucher_line` | รหัสบัญชี | `account` | `6a85fb399b6999a714d2a559` | ✅ (Relation → `ac_coa`) |
| `ac_voucher_line` | เดบิต | `debit` | `6a85fb399b6999a714d2a55b` | — |
| `ac_voucher_line` | เครดิต | `credit` | `6a85fb399b6999a714d2a55c` | — |
| `ac_voucher_line` | หน่วยงาน | `cost_center` | `6a85fb399b6999a714d2a55d` | Relation → `ac_cost_center` |
| `ac_pay_req` | เลขที่ใบขออนุมัติเบิกจ่าย | `req_no` | `6a8677b18b36df988c176cb1` | isTitle |
| `ac_pay_req` | เหตุผลการขอเบิก | `request_reason` | `6a8677b18b36df988c176cb2` | ✅ |
| `ac_pay_req` | ผู้ขอเบิก | `requester` | `6a8677b18b36df988c176cb3` | Collaborator |
| `ac_pay_req` | วันที่ต้องการให้จ่าย | `required_pay_date` | `6a8677b18b36df988c176cb7` | Date |
| `ac_pay_req` | จำนวนเงินที่ขอเบิก | `biz_preq_amount` | `6a8ead839762533b5b717036` | Number |
| `ac_pay_req` | สถานะเอกสาร | `biz_preq_status` | `6a8ec5be353e1b0e4a506d75` | Dropdown ผูก `4ab44bf7-1c5f-48c1-9669-8ac180dc4fc0` · key ร่าง = `08092993-906a-4956-b0ff-6f91f766fe61` |
| `ac_pay_req` | ประเภทเอกสาร | `biz_preq_doc_type` | `6a8ead839762533b5b71703b` | Relation → `ac_doc_type` |
| `ac_period` | สถานะงวดบัญชี | `period_status` | `6a851f70055f2288c5b73edf` | key เปิด = `f662571c-3de0-4e4c-9828-9172e337d223` |
| `ac_period` | วันที่เริ่มงวด / สิ้นงวด | `date_from` / `date_to` | `6a8434d58b36df988c16ed68` / `6a8434d58b36df988c16ed69` | Date |
| `ac_posting_rule` | รหัสเหตุการณ์ | `event_code` | `6a85518c055f2288c5b7430b` | SingleSelect (inline, ไม่ใช่ shared optionset) — ✅ **28 ส.ค. 2569 (ต่อเนื่อง 6): เพิ่ม `PAYROLL_ACCRUAL`(key `ad4850c4-f1c1-4a65-adbb-fb0054a6e0c8`)/`PAYROLL_PAYMENT`(key `04a14b13-73c2-408b-a5fb-bb81ff630a06`) แล้วโดยฝ่ายบัญชีผ่าน MCP `editFields` — Gap G-02 ปิดแล้ว** |
| `ac_posting_rule` | บัญชีเดบิต / เครดิต | `debit_account` / `credit_account` | `6a85518c055f2288c5b7430d` / `6a85518c055f2288c5b7430f` | Relation → `ac_coa` |
| `ac_posting_rule` | เปิดใช้งาน | `is_active` | `6a85e6b09b6999a714d2a409` | Checkbox |
| `ac_cost_center` | รหัสหน่วยงานใน HRMS | `hrms_unit_id` | `6a85452b055f2288c5b741bc` | Text — จุดเชื่อมที่เตรียมไว้แล้ว |

### §1.5 Optionsets ที่ **ใช้ซ้ำของเดิม** (🔴 ห้ามสร้างใหม่)

| Optionset | ID | option (value → key) ที่ HR ใช้ |
|---|---|---|
| `OS_SOURCE_MODULE` | `098ff000-5d07-4c73-9622-c37e691f9f75` | **Payroll → `914f5226-dc4c-4572-bd4d-18bb278414b5`** |
| `OS_PAYMENT_METHOD` | `32bfb7c2-a519-4aa0-820a-f777b533e719` | Cash → `90bb0b39-e86d-42a5-90c9-a0f7fad884ab` · Bank transfer → `4bb5ba34-48da-45f6-8a39-03abbcc4107d` · Cheque → `2c443ee1-d84e-4141-94d7-31f76528c5d8` |
| `OS_COMPLETION_MODE` | `7eb8ad24-65e2-411e-ab58-a7f030f21876` | All must approve → `0605fa6b-13ff-4063-b41f-ae690e450e23` · Any one may approve → `fe6a0464-36ce-4553-9ad8-bfb2cfb431ab` |
| `OS_LEGAL_FORM` | `b97a1a08-78ab-4683-8472-837c48af4423` | Individual → `1aeb1a04-1957-4905-92d9-c506d8bbdccc` (ใช้บนหนังสือรับรองหักภาษีของพนักงาน) |
| `OS_FORM_TYPE` | `7b605ddd-bf7f-4837-9fa7-e6ae2153b2f8` | ⚠️ **ไม่มี ภ.ง.ด.1** (มีแค่ P.P.30 / P.P.36 / P.N.D.3 / 53 / 54) ดู Gap G-03 |
| `OS_PERIOD_STATUS` | `e9ae2c06-eb06-45ee-a2ee-4eb1757f1116` | Open → `f662571c-3de0-4e4c-9828-9172e337d223` (ใช้ตรวจงวดบัญชีก่อนผ่านรายการเงินเดือน) |

### §1.6 Optionsets ที่ต้องสร้างใหม่ — ✅ **สร้างครบ 24 ชุดแล้ว 26 ส.ค. 2569** (ยืนยันด้วย `get_optionset_list`) — 🔴 ผูกกับฟิลด์ได้เฉพาะใน Browser UI เท่านั้น (ยืนยันซ้ำหลายรอบ — ดู §0)

| # | Optionset | ID | options (label ที่ใช้บนเซิร์ฟเวอร์เป็นอังกฤษ ตามแบบโมดูลบัญชี) | ผูกกับฟิลด์ |
|---|---|---|---|---|
| 1 | `OS_HR_EMP_STATUS` | `280d4f69-366d-4564-ae72-800f42fc42d9` ✅ | Probation · Active · On leave · Suspended · Resigned · Terminated · Retired | `hr_employee.emp_status` |
| 2 | `OS_HR_EMPLOYMENT_TYPE` | `65390c18-4ecb-4243-9098-12e6b91730e5` ✅ | Monthly · Daily · Hourly · Contract · Outsourced | `hr_employee.employment_type` · `hr_employment_contract.contract_type` |
| 3 | `OS_HR_GENDER` | `24979ca6-a3c6-4407-b1c6-ac98e6bdac99` ✅ | Male · Female · Unspecified | `hr_employee.gender` |
| 4 | `OS_HR_MARITAL_STATUS` | `0da6dd2f-0cdb-4618-8491-237bbb3ec4de` ✅ | Single · Married · Divorced · Widowed | `hr_employee.marital_status` |
| 5 | `OS_HR_LEAVE_UNIT` | `b91afbda-b1d3-4f35-b68b-9d800acc9aff` ✅ | Full day · Half day (morning) · Half day (afternoon) · Hourly | `hr_leave_request.leave_unit` |
| 6 | `OS_HR_REQUEST_STATUS` | `8ea16e5f-c099-45e2-9734-b553ea40b8d0` ✅ | **Draft · Pending supervisor · Pending HR · Approved · Rejected · Cancelled** | `hr_leave_request.leave_status` · `hr_ot_request.ot_status` · `hr_claim.claim_status` · `hr_job_requisition.req_status` (ชุดเดียวใช้ 4 ตาราง — ต้องเป็น shared optionset) |
| 7 | `OS_HR_ATT_STATUS` | `da2f6870-acda-4ef2-a70e-e641193f76a5` ✅ | Present · Late · Absent · On leave · Holiday · Weekly holiday · Half day | `hr_attendance.att_status` |
| 8 | `OS_HR_ATT_SOURCE` | `23176ae6-97b8-45b8-87c3-43f911ea053c` ✅ | Device import · Manual entry · Self check-in · System generated | `hr_attendance.att_source` |
| 9 | `OS_HR_OT_DAY_TYPE` | `b433253c-70e2-4f15-8392-56b875f1cd76` ✅ | Working day · Holiday within hours · Holiday outside hours | `hr_ot_rate.day_type` · `hr_ot_request.day_type` |
| 10 | `OS_HR_LEDGER_TYPE` | `5b546b65-5050-4e7b-a02e-34fb55388a4b` ✅ | Annual grant · Carry forward · Leave taken · Leave returned · Manual adjustment · Expiry | `hr_leave_ledger.ledger_type` |
| 11 | `OS_HR_CARRY_POLICY` | `52b15a75-76fc-457b-a72d-e6b7f2136243` ✅ | No carry forward · Carry all · Carry up to cap | `hr_leave_type.carry_policy` |
| 12 | `OS_HR_PAY_PERIOD_STATUS` | `59c18869-25bb-490e-b650-751b77dc0087` ✅ | **Open · Calculating · Pending approval · Approved · Posted · Closed · Cancelled** | `hr_pay_period.period_status` |
| 13 | `OS_HR_PAYSLIP_STATUS` | `f77b582b-187e-4df0-8578-69b2078d9045` ✅ | Draft · Calculated · Approved · Published · Cancelled | `hr_payslip.payslip_status` |
| 14 | `OS_HR_COMPONENT_TYPE` | `01087816-2f10-4e49-9f9d-18c1bb1c136e` ✅ | Earning · Deduction · Employer contribution · Informational | `hr_pay_component.component_type` |
| 15 | `OS_HR_COMPONENT_CALC` | `dabc60c9-a6bc-43ea-889b-b5c9cff516b6` ✅ | Fixed amount · Rate per hour · Percentage of base · From attendance · From OT request · Statutory formula · Manual entry | `hr_pay_component.calc_method` |
| 16 | `OS_HR_CANDIDATE_STAGE` | `be9704bf-478e-41b0-9e34-aa9911ca71d2` ✅ | Applied · Screening · Interview 1 · Interview 2 · Offered · Hired · Rejected · Withdrawn | `hr_candidate.stage` |
| 17 | `OS_HR_APPRAISAL_STATUS` | `f53f261b-7c2e-4c36-a9d8-b20d4230321a` ✅ | Not started · Self assessment · Supervisor review · HR review · Completed · Cancelled | `hr_appraisal.appraisal_status` |
| 18 | `OS_HR_TRAINING_STATUS` | `738a7d5c-1c93-4cd2-b79c-468d389949a9` ✅ | Planned · Enrolled · Attended · Passed · Failed · Absent · Cancelled | `hr_training.training_status` |
| 19 | `OS_HR_CONTRACT_STATUS` | `b12f8396-0910-4b10-aeba-6cd464470d4c` ✅ | Draft · Active · Expiring soon · Expired · Terminated | `hr_employment_contract.contract_status` |
| 20 | `OS_HR_EVENT_TYPE` | `915e4009-f8a5-4b0f-8ca5-f8425b8af038` ✅ | Hired · Confirmed · Promoted · Transferred · Salary adjusted · Suspended · Resigned · Terminated · Retired | `hr_employment_event.event_type` |
| 21 | `OS_HR_FILING_STATUS` | `dc455e42-cd18-4dd3-9275-45d904046b04` ✅ | Draft · Approved · Filed · Paid · Amended | `hr_pnd1_filing.filing_status` |
| 22 | `OS_HR_FILING_FORM` | `9e8dac8a-3989-419a-b88d-d6bd5311c008` ✅ | P.N.D.1 · P.N.D.1 Kor | `hr_pnd1_filing.form_type` (แยกจาก `OS_FORM_TYPE` เดิม ดู Gap G-03) |
| 23 | `OS_HR_WELFARE_CYCLE` | `bd2ad40f-1165-4080-bcc6-ebb143db8d27` ✅ | Per calendar year · Per employment year · Per occurrence · Lifetime | `hr_welfare_scheme.entitlement_cycle` |
| 24 | `OS_HR_CERT_STATUS` | `bd2d8da7-0c15-436e-931e-429c5ba6440b` ✅ | Issued · Printed · Included in filing · Cancelled | `hr_wht_cert.cert_status` |

> 🔴 **`OS_HR_REQUEST_STATUS` ใช้ร่วม 4 ตาราง** — ต้องเป็น shared optionset และ **ผูกได้เฉพาะใน Browser UI** ถ้าพลาดจะผูกกลับไม่ได้เลย (บทเรียนจากโมดูลบัญชีที่ต้องลบสร้างใหม่ 20 ฟิลด์)
> ⚠️ label บนเซิร์ฟเวอร์เป็นอังกฤษ (เข้าชุดกับโมดูลบัญชี) — **workflow และ filter ต้องอ้าง `key` เสมอ ห้ามอ้าง label**


#### §1.6.1 Option-key GUID mapping (ยืนยันจาก `get_optionset_list` 26 ส.ค. 2569) — 🔴 workflow/filter ต้องอ้าง key นี้เท่านั้น ห้ามอ้าง label

- **`OS_HR_EMP_STATUS`** (`280d4f69-366d-4564-ae72-800f42fc42d9`): Probation=`4607ffb2-3bd4-451b-bf35-99d3d9ece4aa` · Active=`824312ff-2a61-4395-9f08-bd1b5460da55` · On leave=`f8ca5312-c3c2-4a8a-bd79-6f031755c27e` · Suspended=`12d14f9c-76a6-4548-96f7-a7ca4cc4be3d` · Resigned=`98a25758-c52e-412a-9399-c08958468c44` · Terminated=`c2a1420c-c2fb-4999-8ace-a897a1c98bb5` · Retired=`79781856-d64a-426d-aada-b5cb308aff2f`
- **`OS_HR_EMPLOYMENT_TYPE`** (`65390c18-4ecb-4243-9098-12e6b91730e5`): Monthly=`98f27b36-ea3a-4d8c-8ead-6aa23833eb55` · Daily=`f7782bdf-365c-48d0-81b7-e56f3457eda4` · Hourly=`640f4bd7-3583-41e8-92f2-1a07da569e83` · Contract=`cb82c44e-0e60-4afc-bd2c-642a90971497` · Outsourced=`f97e6a10-5bbd-4aef-9784-86b45f315063`
- **`OS_HR_GENDER`** (`24979ca6-a3c6-4407-b1c6-ac98e6bdac99`): Male=`6bd71276-50f1-441f-993b-abc64e6f6db6` · Female=`136bb4f0-23c0-4340-b2c0-bcbba42d562d` · Unspecified=`4285b89f-ed36-4c82-8916-cd1d6be2e8b6`
- **`OS_HR_MARITAL_STATUS`** (`0da6dd2f-0cdb-4618-8491-237bbb3ec4de`): Single=`da84b1c4-4695-4e6c-ba44-6c1e7f9298a6` · Married=`c2cef43e-66fb-4a74-b078-932d93f864ce` · Divorced=`7fa66468-748d-42b4-9b79-f50359dc4e1b` · Widowed=`cf642938-3b54-437c-b830-e6bf6a62dc29`
- **`OS_HR_LEAVE_UNIT`** (`b91afbda-b1d3-4f35-b68b-9d800acc9aff`): Full day=`a5bea71a-b343-4d2a-9724-b303d253f085` · Half day (morning)=`11b2e266-1534-49f9-b940-a01194107f7c` · Half day (afternoon)=`3f308677-088b-4e7d-a5fb-67dd506050fd` · Hourly=`a61caf9e-51b5-45f2-ab0a-25144f9ce35d`
- **`OS_HR_REQUEST_STATUS`** (`8ea16e5f-c099-45e2-9734-b553ea40b8d0`): Draft=`ca82b995-8ffb-47cf-be35-7682116aa9ae` · Pending supervisor=`690993aa-8066-484d-85e3-3164907c218e` · Pending HR=`82f9ba8f-a91f-4c4b-9899-a24aae48270b` · Approved=`e67879dc-ce19-44fa-97f1-86810f4bdeb0` · Rejected=`a7835570-21de-44ab-8904-efd010b6b3f6` · Cancelled=`88a25f78-ef14-419e-910a-ff63f997faa8`
- **`OS_HR_ATT_STATUS`** (`da2f6870-acda-4ef2-a70e-e641193f76a5`): Present=`dfa84ec5-fb8c-405e-87d2-5c2d1b08ee59` · Late=`11b371bb-f869-4c4d-9952-c2c8c0eae8b3` · Absent=`a891551d-ba1f-475f-84d3-6d3dc5b93691` · On leave=`261582f6-cc0a-4a42-bac5-a1671c220572` · Holiday=`367040ef-8b8a-4223-bb6b-f84ebdaf58c0` · Weekly holiday=`303acf90-e7db-49ea-9090-ebf98d8141a3` · Half day=`aa93864e-9d67-4333-bece-2cbc8f2a63d9`
- **`OS_HR_ATT_SOURCE`** (`23176ae6-97b8-45b8-87c3-43f911ea053c`): Device import=`15586ff6-96e4-439d-9660-0e7334bc92f6` · Manual entry=`c4d2f95b-9a0f-4b20-a463-23f5ee34687e` · Self check-in=`9888fc3c-737d-43ca-aade-ab3918a8c5c4` · System generated=`b6080a7f-eef0-42ff-b7b3-c916661d73a5`
- **`OS_HR_OT_DAY_TYPE`** (`b433253c-70e2-4f15-8392-56b875f1cd76`): Working day=`8d93cd34-15d2-4cec-a7f0-7039a24d9641` · Holiday within hours=`16eda329-b1a8-46cc-b7af-e0a5cf47633e` · Holiday outside hours=`045b2d8a-2558-4752-b941-032547caf959`
- **`OS_HR_LEDGER_TYPE`** (`5b546b65-5050-4e7b-a02e-34fb55388a4b`): Annual grant=`163359c8-5e34-4459-9061-84e85bf38908` · Carry forward=`fb87618a-75c6-43ef-8467-a001139d963d` · Leave taken=`2de0869e-94e5-4697-86df-aa63ff52c047` · Leave returned=`d2309c9a-852a-4d39-8480-4a5d90b882d2` · Manual adjustment=`2caff002-ee64-4212-aebc-a223e67ddede` · Expiry=`42cc5ef6-56a5-45a9-badf-a19cd57c9707`
- **`OS_HR_CARRY_POLICY`** (`52b15a75-76fc-457b-a72d-e6b7f2136243`): No carry forward=`ab196d39-589b-47af-bc43-edd13598bb4b` · Carry all=`9313c1ff-5ec2-4701-8d34-ec1698f51145` · Carry up to cap=`03ac713d-2acf-4ca2-866c-b08f573c84a0`
- **`OS_HR_PAY_PERIOD_STATUS`** (`59c18869-25bb-490e-b650-751b77dc0087`): Open=`401451a6-fc14-4fac-8e02-ff455e7192ed` · Calculating=`3843b4ee-9d52-4071-9778-82bd8857c800` · Pending approval=`403ebc3c-b54c-47ab-8672-7b93d18699b5` · Approved=`d1b41d8d-08ae-45b5-b810-854dd6037281` · Posted=`cc197709-b4cf-4599-8c4e-4e9b7203d20e` · Closed=`6a00b4b2-4b3c-46f1-ac8a-bbfecda9639a` · Cancelled=`b8983658-144b-409c-a2ab-46d5deae6ff7`
- **`OS_HR_PAYSLIP_STATUS`** (`f77b582b-187e-4df0-8578-69b2078d9045`): Draft=`b86d8f83-854d-4172-992e-5dd75242a13a` · Calculated=`fb741659-73df-4c3f-80c0-cc810adfc6d2` · Approved=`58078020-443e-4ef4-aa7c-fe165d34a22b` · Published=`aa136c58-176b-407c-906b-45e14f4ae62a` · Cancelled=`bd73d04b-ac14-40bd-ba5f-d85fdc03a320`
- **`OS_HR_COMPONENT_TYPE`** (`01087816-2f10-4e49-9f9d-18c1bb1c136e`): Earning=`27341aaf-abf7-49ac-a297-f0deb857d4d6` · Deduction=`e8e34472-2a41-44fa-8604-aefaba24e340` · Employer contribution=`c5b19067-889f-494a-98ce-4214cebdf7fb` · Informational=`27cb7261-807b-4642-8618-80f076e663b6`
- **`OS_HR_COMPONENT_CALC`** (`dabc60c9-a6bc-43ea-889b-b5c9cff516b6`): Fixed amount=`32d4e4a8-7a70-4bbf-952e-f08387a8f814` · Rate per hour=`9667eef9-a397-4877-96ea-e616bd25c371` · Percentage of base=`9866bffb-78c6-49e8-8fd9-3975f595d678` · From attendance=`7a816217-e5f9-44ea-8163-47aa99e36107` · From OT request=`c89bdc90-665c-440e-b6e8-ef97e3792d5a` · Statutory formula=`d7ee7059-0525-4e02-8a75-3049f4d2ec31` · Manual entry=`81a58dcd-83da-40d1-8dc0-35a431cd09b5`
- **`OS_HR_CANDIDATE_STAGE`** (`be9704bf-478e-41b0-9e34-aa9911ca71d2`): Applied=`5ba63ce6-7d22-4687-a75c-d1cd18898f98` · Screening=`18c2201c-2705-4c1e-b003-6085291b55fe` · Interview 1=`1c24b021-5907-4d3e-9f72-6196873d944a` · Interview 2=`2b0a3803-5bc0-413a-a659-00eacb2afd2b` · Offered=`afb5480c-1675-48df-b0e8-3e91906268bb` · Hired=`740a63c4-78a3-427a-ab73-9a17cb5ae172` · Rejected=`9f815fcd-778d-49e7-a85e-85f0f7b44ff4` · Withdrawn=`f222e008-c709-45ec-94eb-5cdef1a67c35`
- **`OS_HR_APPRAISAL_STATUS`** (`f53f261b-7c2e-4c36-a9d8-b20d4230321a`): Not started=`66564c28-5c6a-447f-9852-0e872fd92476` · Self assessment=`0454456a-6207-4850-bb40-3963993a3853` · Supervisor review=`954b34f9-246b-45d5-998a-14310536b189` · HR review=`e5a2f23e-c50e-490c-953d-046488ded01a` · Completed=`f654f2bf-cf6a-438e-be52-8ced6029fbdb` · Cancelled=`bc0c51a8-7315-456f-b08e-2a7bf9ad469f`
- **`OS_HR_TRAINING_STATUS`** (`738a7d5c-1c93-4cd2-b79c-468d389949a9`): Planned=`98455eb4-239e-44c8-baf1-b74ea266df03` · Enrolled=`55b6627f-81f9-4d27-bb35-88203a82d768` · Attended=`00d640f2-342e-4dec-9e37-c22fc142d73c` · Passed=`8c92f9b5-d4f9-40ac-9155-cb1b6261b51b` · Failed=`65921a32-b3e1-4328-bfd4-ff0af4d033ea` · Absent=`d4cc797d-d899-40df-823f-f76fd36fd1bd` · Cancelled=`98c157d1-3ddc-4ac8-ae1a-b406f7427833`
- **`OS_HR_CONTRACT_STATUS`** (`b12f8396-0910-4b10-aeba-6cd464470d4c`): Draft=`46ace816-4e00-4549-b7a3-b8e6df62fc62` · Active=`aa26eb17-c9d3-4fda-b48f-f39fc5f31009` · Expiring soon=`3f53a87f-70db-4bce-8194-693d0d22e220` · Expired=`776c6394-e3df-44b5-a8e3-f028f68f728f` · Terminated=`7180f61d-bae5-45ce-838d-14d40fadaf9f`
- **`OS_HR_EVENT_TYPE`** (`915e4009-f8a5-4b0f-8ca5-f8425b8af038`): Hired=`f96ddfc1-08bb-4f2c-bd24-65d1748b711d` · Confirmed=`edd00fe4-b51e-4987-b384-3d55f3383a57` · Promoted=`4e3a0ac1-ba61-4b19-9fd2-52484beb50e8` · Transferred=`1b692c54-934f-4c03-aa42-6d8367e3d38a` · Salary adjusted=`bb85a632-bb87-4950-a420-81bf6bd6b8e5` · Suspended=`b8f852bc-ac8b-4082-9bfd-c69e8e404eab` · Resigned=`434c5dd3-04e8-4722-a675-4e6d51831a1c` · Terminated=`4705c8bb-0e63-4830-aea4-898416e44fdc` · Retired=`075969da-15f2-4a07-8054-f32490e4ab29`
- **`OS_HR_FILING_STATUS`** (`dc455e42-cd18-4dd3-9275-45d904046b04`): Draft=`92cf9c6b-7eeb-4ba6-abb4-3637136dc024` · Approved=`2912053d-1ab9-44d0-8a29-0752859c99dc` · Filed=`20840c21-ed61-4d6d-9a48-c008fe374f47` · Paid=`336b2526-4cf2-412a-b5da-630b15fe2a42` · Amended=`f2add76d-cbea-47f7-a3fd-bca2ba951386`
- **`OS_HR_FILING_FORM`** (`9e8dac8a-3989-419a-b88d-d6bd5311c008`): P.N.D.1=`3c6e80f3-c96d-4955-b756-b0bcb993f0cb` · P.N.D.1 Kor=`3fed0f94-d453-48cb-a2eb-6588e3ad3810`
- **`OS_HR_WELFARE_CYCLE`** (`bd2ad40f-1165-4080-bcc6-ebb143db8d27`): Per calendar year=`e1acab69-709d-4b8b-a88c-bbcdc3e28295` · Per employment year=`57282394-40a3-475b-8f79-d913ccca21e2` · Per occurrence=`4cbce2e6-ddea-4dcb-9865-53b62494a470` · Lifetime=`8b8e40a7-f058-4fc6-acfe-58914e194f04`
- **`OS_HR_CERT_STATUS`** (`bd2d8da7-0c15-436e-931e-429c5ba6440b`): Issued=`e708d3d3-39f4-4935-8145-15c58e8a8e12` · Printed=`3de84cbc-93b3-4cf9-8cd8-8e64b0f34293` · Included in filing=`7f94f414-71b7-4c70-967a-7c960daec2e0` · Cancelled=`b313fbf6-90ea-41a9-b056-7900455248c8`

### §1.7 Roles (custom) — ทั้งหมด `<TBD>`

| Role | ID | permissionScope | ขอบเขตหลัก |
|---|---|---|---|
| HR-R1 Employee (พนักงาน) | `<TBD-R1>` | `"0"` fine-grained | เห็นเฉพาะของตนเอง |
| HR-R2 Line Manager (หัวหน้างาน) | `<TBD-R2>` | `"0"` | ตนเอง + ผู้ใต้บังคับบัญชา |
| HR-R3 HR Officer (เจ้าหน้าที่บุคคล) | `<TBD-R3>` | `"0"` | ทั้งองค์กร ยกเว้นเงินเดือนรายบุคคล |
| HR-R4 HR Manager (ผู้จัดการฝ่ายบุคคล) | `<TBD-R4>` | `"0"` | ทั้งองค์กร รวมเงินเดือน · อนุมัติงวดจ่าย |
| HR-R5 Payroll Officer (เจ้าหน้าที่เงินเดือน) | `<TBD-R5>` | `"0"` | 🔴 SoD — แก้ทะเบียนพนักงานไม่ได้ · อนุมัติไม่ได้ |
| HR-R6 Executive (ผู้บริหาร) | `<TBD-R6>` | `"0"` | รายงาน/แดชบอร์ดเท่านั้น · ปิดบังข้อมูลอ่อนไหว |
| HR-R7 Internal Auditor (ผู้ตรวจสอบภายใน) | `<TBD-R7>` | `"0"` | อ่านทั้งหมด แก้ไม่ได้เลย |
| HR-R8 HR System Admin (ผู้ดูแลระบบบุคคล) | `<TBD-R8>` | `"0"` | 🔴 NFR-HR-12 — **ห้ามมีสิทธิ์อนุมัติเด็ดขาด** |

> ✅ **`get_role_list` บน tenant นี้คืน custom role ครบ** (ต่างจากที่ playbook เตือน — พิสูจน์แล้วกับ 8 role ของบัญชี) ⇒ ใช้ยืนยันการสร้าง role ได้

**Permission matrix (ใช้กรอก `create_role.worksheetPermissions[]` — ทุก sub-object ต้องครบ)**
> recordDataScope: `0` = ไม่เห็น · `20` = ของตนเอง · `30` = ตนเอง+ผู้ใต้บังคับบัญชา · `100` = ทั้งหมด

| Worksheet | R1 พนักงาน | R2 หัวหน้า | R3 HR | R4 HR Mgr | R5 Payroll | R6 ผู้บริหาร | R7 Auditor | R8 Admin |
|---|---|---|---|---|---|---|---|---|
| `hr_employee` | read 20 · edit 0 (เฉพาะฟิลด์ติดต่อ) | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | **read 100 · edit 0** | read 100 (ปิดบัง) · edit 0 | read 100 · edit 0 | read 100 · edit 100 |
| `hr_salary_structure` | **0** | **0** | **0** | read 100 · edit 100 | read 100 · edit 0 | **0** | read 100 · edit 0 | **0** |
| `hr_dependent` / `hr_bank_account` | read 20 · edit 20 | **0** | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | **0** | read 100 · edit 0 | read 100 · edit 0 |
| `hr_leave_request` | read 20 · edit 20 · delete 0 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_leave_balance` / `hr_leave_ledger` | read 20 · edit 0 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_attendance` | read 20 · edit 0 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_ot_request` | read 20 · edit 20 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_payslip` / `hr_payslip_line` | **read 20 · edit 0** | **0** | **0** | read 100 · edit 0 | read 100 · edit 100 | **0** | read 100 · edit 0 | **0** |
| `hr_pay_period` | 0 | 0 | read 100 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_pay_component` / `hr_sso_rate` / `hr_tax_bracket` / `hr_tax_allowance` | 0 | 0 | read 100 · edit 0 | read 100 · edit 100 | read 100 · edit 0 | 0 | read 100 · edit 0 | read 100 · edit 100 |
| `hr_pnd1_filing` / `hr_wht_cert` | read 20 (เฉพาะของตน) | 0 | 0 | read 100 · edit 0 | read 100 · edit 100 | 0 | read 100 · edit 0 | 0 |
| `hr_claim` / `hr_claim_line` | read 20 · edit 20 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_welfare_balance` | read 20 · edit 0 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_candidate` / `hr_interview` | 0 | read 100 · edit 0 (เฉพาะที่เป็นกรรมการ) | read 100 · edit 100 | read 100 · edit 100 | 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_appraisal` / `hr_appraisal_item` | read 20 · edit 20 | read 30 · edit 30 | read 100 · edit 100 | read 100 · edit 100 | 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| `hr_training` / `hr_course` | read 20 · edit 0 | read 30 · edit 0 | read 100 · edit 100 | read 100 · edit 100 | 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 |
| ตารางตั้งค่า HR-00 ที่เหลือ | 0 | 0 | read 100 · edit 0 | read 100 · edit 100 | read 100 · edit 0 | 0 | read 100 · edit 0 | read 100 · edit 100 |
| **สิทธิ์อนุมัติ (เห็น To-do)** | ❌ | ✅ ขั้น 1 | ✅ ขั้น 2 | ✅ งวดจ่าย/อัตรากำลัง | ❌ | ❌ | ❌ | ❌ |

**ฟิลด์ที่ต้องซ่อน/ปิดบังเป็นการเฉพาะ (NFR-HR-02) — ตั้งใน UI**

| ฟิลด์ | ซ่อนจาก | เหตุผล |
|---|---|---|
| `hr_employee.national_id` | R1 (ยกเว้นของตนเอง) · R2 · R6 | PDPA |
| `hr_employee.base_salary_display` (ถ้ามี) | R1 · R2 · R3 · R6 | ค่าจ้างเป็นความลับ |
| `hr_bank_account.account_no` | R2 · R6 | PDPA + ป้องกันการโอนผิด |
| `hr_leave_request.attachments` (ใบรับรองแพทย์) | R2 (ดูได้เฉพาะว่าแนบแล้ว) · R6 | ข้อมูลสุขภาพเป็นข้อมูลอ่อนไหวชั้นสูง |
| `hr_dependent.*` | R2 · R6 | PDPA บุคคลที่สาม |

> ⚠️ **scope ของ API เป็น ownership/hierarchy เท่านั้น** — การกรองตามค่าฟิลด์ (เช่น "หัวหน้าเห็นเฉพาะหน่วยงานตัวเอง") ต้องใช้ **View filter + `recordPermissionInViews`** ไม่ใช่ `recordDataScope`
> ⚠️ **multi-role = สิทธิ์รวมแบบกว้างสุด** — ห้ามใส่บัญชีเดียวไว้ทั้ง R5 และ R4 ไม่งั้น SoD พัง

### §1.8 Workflows

| Workflow | ชนิด | **Surface** | ID | สถานะ |
|---|---|---|---|---|
| WF-HR-01 อนุมัติใบลา 2 ระดับ | `worksheet_event` (update) | **MCP** | `<TBD-WF-01>` | ⬜ |
| WF-HR-02 ตัดสิทธิลาเมื่ออนุมัติ | `worksheet_event` (update) | **MCP** | `<TBD-WF-02>` | ⬜ |
| WF-HR-03 คืนสิทธิลาเมื่อยกเลิก | `worksheet_event` (update) | **MCP** | `<TBD-WF-03>` | ⬜ |
| WF-HR-04 อนุมัติใบขอล่วงเวลา 2 ระดับ | `worksheet_event` (update) | **MCP** | `<TBD-WF-04>` | ⬜ |
| WF-HR-05 สรุปเวลาทำงานรายวัน | `schedule` (รายวัน 01:00 +07:00) | **MCP** | main `6a910184730d20c5b7710fa8` v1 · inner `6a910197730d20c5b7711028` v1 | 🟢 **สร้าง+publish สำเร็จ 28 ส.ค. 2569 (ต่อเนื่อง 4)** — โครงสร้างสมบูรณ์ validate สะอาด แต่ live-fire test ยังทำไม่ได้ (D-17) |
| WF-HR-06 เตือนคำขอค้างอนุมัติเกิน SLA | `schedule` (รายวัน 09:00 +07:00) | **MCP** | main `6a910222730d20c5b77115e5` v1 · inner `6a9102345f8564a68c449ee7` v1 | 🟢 **สร้าง+publish สำเร็จ 28 ส.ค. 2569 (ต่อเนื่อง 4) — v1 ครอบคลุมเฉพาะ `hr_leave_request`** (`hr_ot_request`/`hr_claim` ยังไม่มีฟิลด์ `submitted_at` — ดู D-18) — live-fire test ยังทำไม่ได้ (D-17) |
| WF-HR-07 สร้างสลิปทั้งงวด | `worksheet_event` (update `period_status`) | **MCP** (`sub_process` โหมด `sequential_each`) | `<TBD-WF-07>` | ⬜ |
| WF-HR-08 คำนวณสลิปรายบุคคล | `worksheet_event` (update `recalc_flag`) | **MCP** | `<TBD-WF-08>` | ⬜ |
| WF-HR-09 อนุมัติงวดจ่ายเงินเดือน | `worksheet_event` (update) | **MCP** | `<TBD-WF-09>` | ⬜ |
| WF-HR-10 ผ่านรายการเงินเดือนเข้าบัญชี | `worksheet_event` (update) | **MCP** | `<TBD-WF-10>` | ⬜ |
| WF-HR-11 อนุมัติใบเบิกสวัสดิการ 2 ระดับ + ตัดวงเงิน | `worksheet_event` (update) | **MCP** | `<TBD-WF-11>` | ⬜ |
| WF-HR-12 ส่งใบเบิกเข้าใบขออนุมัติเบิกจ่าย | `worksheet_event` (update) | **MCP** | `<TBD-WF-12>` | ⬜ |
| WF-HR-13 เตือนสัญญาจ้าง/ทดลองงานใกล้ครบกำหนด | `date_field` | **MCP** | `<TBD-WF-13>` | ⬜ |
| WF-HR-14 ยกยอดสิทธิลาต้นปี | `schedule` (1 ม.ค. 00:30 +07:00) | **MCP** | `<TBD-WF-14>` | ⬜ |
| WF-HR-15 อนุมัติใบขออัตรากำลัง | `worksheet_event` (update) | **MCP** | `<TBD-WF-15>` | ⬜ |
| WF-HR-16 เลื่อนสถานะผู้สมัครและแจ้งนัดสัมภาษณ์ | `worksheet_event` (update) | **MCP** | `<TBD-WF-16>` | ⬜ |
| WF-HR-17 สร้างทะเบียนพนักงานจากผู้สมัครที่ถูกจ้าง | `worksheet_event` (update) | **MCP** | `<TBD-WF-17>` | ⬜ |
| WF-HR-18 เปิดรอบประเมิน — สร้างแบบประเมินทุกคน | `worksheet_event` (update) | **MCP** (`sub_process` `sequential_each`) | `<TBD-WF-18>` | ⬜ |
| WF-HR-19 เดินสถานะแบบประเมิน 3 ขั้น | `worksheet_event` (update) | **MCP** | `<TBD-WF-19>` | ⬜ |
| WF-HR-20 ออกหนังสือรับรองการหักภาษีประจำปี | `worksheet_event` (update) | **MCP** (`sub_process`) | `<TBD-WF-20>` | ⬜ |

> Surface default = **MCP** ทุกตัว — trigger ทั้งหมดอยู่ใน 4 ชนิดที่ MCP สร้างได้ (`worksheet_event` / `schedule` / `date_field` / `webhook`) และไม่มี node นอก 17 ชนิดที่ MCP รองรับ
> ✅ **`sub_process` โหมด `sequential_each` ใช้แทน node Loop ได้** — พิสูจน์แล้วกับ WF-AC-02 ในแอปนี้ ⇒ งานวนทีละ record (สร้างสลิปทุกคน · ยกยอดสิทธิลาทุกคน) ทำบน MCP ได้ ไม่ต้องเข้า Browser

### §1.9 Custom Actions (ปุ่มบน record)

| ปุ่ม | Worksheet · View | ชนิด | ทำอะไร | เปิดใช้เมื่อ (`enableWhen`) | Role ที่เห็น | ยืนยัน | ID | Surface |
|---|---|---|---|---|---|---|---|---|
| ส่งคำขอ | `hr_leave_request` · ทุก view ของพนักงาน | `updateCurrentRecord` | `leave_status` = Pending supervisor → WF-HR-01 รับช่วง | `leave_status equals Draft` | R1 R2 R3 | ✓ | `<TBD-CA-01>` | MCP (unverified) |
| ยกเลิกใบลา | `hr_leave_request` | `updateCurrentRecord` (pop-up ถามเหตุผล) | `leave_status` = Cancelled + `cancel_reason` | `leave_status in (Draft, Pending supervisor, Pending HR, Approved)` | R1 R3 | ✓ | `<TBD-CA-02>` | MCP (unverified) |
| ส่งขอล่วงเวลา | `hr_ot_request` | `updateCurrentRecord` | `ot_status` = Pending supervisor | `ot_status equals Draft` | R1 R2 | ✓ | `6a8fde0aae2a0e3743a0c62f` ✅ | MCP ✅ (ยิงจริง — แก้ Scope bug แล้ว) |
| ส่งใบเบิก | `hr_claim` | `updateCurrentRecord` | `claim_status` = Pending supervisor | `claim_status equals Draft` | R1 | ✓ | `<TBD-CA-04>` | MCP (unverified) |
| เพิ่มรายการค่าใช้จ่าย | `hr_claim` | `createRelatedRecord` | สร้าง `hr_claim_line` ผูก relation | `claim_status equals Draft` | R1 | — | `<TBD-CA-05>` | MCP (unverified) |
| **สร้างสลิปทั้งงวด** | `hr_pay_period` | `updateCurrentRecord` | `period_status` = Calculating → WF-HR-07 รับช่วง | `period_status equals Open` | R5 | ✓ | `<TBD-CA-06>` | MCP (unverified) |
| คำนวณสลิปใหม่ | `hr_payslip` · view "สลิปในงวดที่เปิด" | `updateCurrentRecord` | `recalc_flag` = 1 → WF-HR-08 รับช่วง | `payslip_status in (Draft, Calculated)` | R5 | ✓ | `<TBD-CA-07>` | MCP (unverified) |
| ส่งงวดจ่ายให้อนุมัติ | `hr_pay_period` | `updateCurrentRecord` | `period_status` = Pending approval → WF-HR-09 | `period_status equals Calculating` | R5 | ✓ | `<TBD-CA-08>` | MCP (unverified) |
| **ผ่านรายการเข้าบัญชี** | `hr_pay_period` | `updateCurrentRecord` | `post_flag` = 1 → WF-HR-10 | `period_status equals Approved AND post_flag not equal to 1` | R4 | ✓ | `<TBD-CA-09>` | MCP (unverified) |
| ปิดงวดจ่าย | `hr_pay_period` | `updateCurrentRecord` | `period_status` = Closed | `period_status equals Posted` | R4 | ✓ | `<TBD-CA-10>` | MCP (unverified) |
| เลื่อนสถานะผู้สมัคร | `hr_candidate` | `triggerWorkflow` (pop-up เลือกขั้นถัดไป) | ยิง WF-HR-16 | `stage not in (Hired, Rejected, Withdrawn)` | R3 R4 | — | `<TBD-CA-11>` | MCP (unverified) |
| จ้างผู้สมัครคนนี้ | `hr_candidate` | `updateCurrentRecord` | `stage` = Hired → WF-HR-17 สร้างทะเบียนพนักงาน | `stage equals Offered` | R4 | ✓ | `<TBD-CA-12>` | MCP (unverified) |
| เปิดรอบประเมิน | `hr_appraisal_cycle` | `updateCurrentRecord` | `cycle_open_flag` = 1 → WF-HR-18 | `cycle_open_flag not equal to 1` | R4 | ✓ | `<TBD-CA-13>` | MCP (unverified) |
| ส่งแบบประเมิน | `hr_appraisal` | `updateCurrentRecord` | เลื่อน `appraisal_status` ขั้นถัดไป → WF-HR-19 | `appraisal_status not in (Completed, Cancelled)` | R1 R2 R3 | ✓ | `<TBD-CA-14>` | MCP (unverified) |
| ออกหนังสือรับรองหักภาษีทั้งปี | `hr_pnd1_filing` | `updateCurrentRecord` | `issue_cert_flag` = 1 → WF-HR-20 | `form_type equals P.N.D.1 Kor AND filing_status equals Filed` | R5 | ✓ | `<TBD-CA-15>` | MCP (unverified) |

> 🔴 **สร้างปุ่มก่อน `create_view`** แล้วอ้าง `actionId` ที่คืนมาใน view config
> 🔴 **ไม่มี update tool** — แก้ปุ่มหลังสร้างต้องเข้า Browser
> ⚠️ **DoD ทุกปุ่มต้องมีขั้น verify**: เปิด worksheet ด้วยบัญชีของ role นั้น แล้วดูว่าปุ่มโผล่/ซ่อนตาม `enableWhen` จริง
> ✅ **P4-5 (27 ส.ค. 2569): `create_custom_actions` ยิงจริงสำเร็จครั้งแรก** — แต่พบกับดักใหม่: ปุ่มที่สร้างมี **Scope = "Unassigned View"** โดย default ทำให้ไม่ขึ้นบนฟอร์มจนกว่าจะเข้า Browser → เปิด record → "..." → Edit Custom Action → Form Settings → Custom Action → คลิก Scope → เลือก "All Records" (auto-save) — **ต้องทำขั้นนี้ทุกปุ่มที่สร้างผ่าน MCP**
> เหตุผลที่ใช้ `updateCurrentRecord` แทน `triggerWorkflow` เกือบทุกปุ่ม: แยก "การกระทำของผู้ใช้" (`user-self`) ออกจาก "ตรรกะระบบ" (`user-workflow`) ทำให้ log พิสูจน์ได้ชัด

### §1.10 Views ที่ต้องสร้าง (ตัวอย่างที่จำเป็นต่อการทำงานและการทดสอบสิทธิ์)

| ชนิด | ชื่อ | บน worksheet | filter | ID | Surface |
|---|---|---|---|---|---|
| Grid | ใบลาของฉัน | `hr_leave_request` | `_createdBy` = ผู้ใช้ปัจจุบัน | `<TBD>` | MCP (unverified) |
| Grid | รออนุมัติ (หัวหน้างาน) | `hr_leave_request` | `leave_status` = Pending supervisor | `<TBD>` | MCP (unverified) |
| Grid | รออนุมัติ (HR) | `hr_leave_request` | `leave_status` = Pending HR | `<TBD>` | MCP (unverified) |
| Calendar | ปฏิทินการลาของทีม | `hr_leave_request` | `leave_status` = Approved | `<TBD>` | MCP (unverified) |
| Grid | บันทึกลงเวลาที่ผิดปกติ | `hr_attendance` | `att_status` in (Late, Absent) | `6a8fde0c1378964f9984a42c` ✅ | MCP ✅ (ยิงจริง P4-5) |
| Grid | OT รออนุมัติ | `hr_ot_request` | `ot_status` in (Pending supervisor, Pending HR) | `6a8fde0b353e1b0e4a50803e` ✅ | MCP ✅ (ยิงจริง P4-5) |
| Grid | สลิปในงวดที่เปิด | `hr_payslip` | `payslip_status` in (Draft, Calculated) | `<TBD>` | MCP (unverified) |
| Grid | สลิปของฉัน | `hr_payslip` | `payslip_status` = Published AND พนักงาน = ผู้ใช้ปัจจุบัน | `<TBD>` | MCP (unverified) |
| Grid | ใบเบิกรออนุมัติ | `hr_claim` | `claim_status` in (Pending supervisor, Pending HR) | `<TBD>` | MCP (unverified) |
| Kanban | ผู้สมัครตามขั้นตอน | `hr_candidate` | จัดกลุ่มตาม `stage` | `<TBD>` | MCP (unverified) |
| Grid | สัญญาใกล้ครบกำหนด | `hr_employment_contract` | `contract_status` = Expiring soon | `<TBD>` | MCP (unverified) |
| Grid | พนักงานที่ยังทำงานอยู่ | `hr_employee` | `emp_status` in (Probation, Active, On leave) | `<TBD>` | MCP (unverified) |

### §1.11 System fields (มีทุก worksheet — ไม่ต้องสร้าง)
`rowid` · `_owner` · `_createdBy` / `_createdAt` · `_updatedBy` / `_updatedAt` · `_processName` · `_processStatus` · `_initiatedBy` · `_approvalCompletedAt`

### §1.12 Gap ที่ต้องตัดสินใจก่อนสร้าง (🔴 อ่านก่อนเริ่ม)

| รหัส | Gap | ทางเลือก | **ค่าที่แนะนำ (default)** |
|---|---|---|---|
| **G-01** | `ac_voucher.source_doc_type` `6a85fb7033560633b8cd9f56` เป็น SingleSelect ที่มี option แค่ AC_AP / AC_AR / AC_PAY / AC_DEPR / AC_CLOSE / Manual — **ไม่มีค่าสำหรับเงินเดือน** | (ก) เพิ่ม option `HR_PAYSLIP` (ข) ใช้ `Manual` แล้วอาศัย `source_module` แยกแทน | **(ก) เพิ่ม option ผ่านหน้าจอเท่านั้น** — ห้ามยิง `editFields` เพราะจะรีเซ็ต attribute อื่น · ถ้ายังไม่ได้เพิ่ม ให้ใช้ (ข) ชั่วคราว โดย `source_module` = Payroll key `914f5226-…` เป็นตัวแยกหลัก |
| **G-02** | `ac_posting_rule.event_code` ไม่มีค่า `PAYROLL_*` (มีแค่ AP/AR/DEPR/DISPOSAL/VAT/WHT/FX/CLOSING) | เพิ่ม option `PAYROLL_ACCRUAL` และ `PAYROLL_PAYMENT` | **เพิ่ม 2 option ผ่านหน้าจอ** แล้วให้ HR สร้าง record กฎการผ่านรายการของเงินเดือน (เดบิตค่าใช้จ่ายเงินเดือน / เครดิตเจ้าหนี้เงินเดือน–ประกันสังคมค้างจ่าย–ภาษีหัก ณ ที่จ่ายค้างจ่าย) · 🔴 **ห้าม hard-code รหัสบัญชีใน WF-HR-10** |
| **G-03** | `OS_FORM_TYPE` `7b605ddd-…` ไม่มี ภ.ง.ด.1 / 1ก | (ก) เพิ่ม 2 option เข้า optionset เดิม (ข) สร้าง `OS_HR_FILING_FORM` แยก | **(ข) สร้างแยก** — optionset เดิมผูกอยู่กับ 4 ตารางของบัญชี การแก้มีความเสี่ยงสูงกว่าประโยชน์ |
| **G-04** | โครงสร้างการบังคับบัญชา — ใช้ฟิลด์บนทะเบียนพนักงาน หรือ department tree ของแพลตฟอร์ม | ฟิลด์ `supervisor` (Relation → `hr_employee`) + `supervisor_user` (Collaborator) | **ฟิลด์บนทะเบียน** (A-HR-17) เพราะ Approve node เลือกผู้อนุมัติได้เฉพาะฟิลด์ Collaborator บนตารางหลัก |
| **G-05** | เพดานฐานประกันสังคมและขั้นบันไดภาษี | — | 🔴 **ต้องยืนยันตัวเลขที่บังคับใช้จริงกับผู้ใช้/ฝ่ายบัญชีก่อน go-live** · ระบบเก็บเป็น record ในตารางแบบมีวันที่มีผล ⇒ เปลี่ยนภายหลังได้โดยไม่แก้ workflow (AC-19) |
| **G-06** | จำนวนบัญชีผู้ใช้ในองค์กรตอนนี้มีเพียง 2 บัญชี (`Kunlasatri.c`, `Wanadtapong.l`) | — | 🔴 **ทดสอบสิทธิ์ 8 บทบาทและการอนุมัติ 2 ระดับไม่ได้จนกว่าจะมีบัญชีทดสอบเพิ่ม** — ต้องมีอย่างน้อย 4 บัญชี (พนักงาน · หัวหน้า · HR · Payroll) |

---

## §2. สเปกรายโมดูล (FR-HR-xx)

📄 **ย้ายไป `21-FRS-Modules-HR.md` แล้ว (31 ส.ค. 2569)** — เนื้อหาครบเหมือนเดิม ไม่ได้ตัดทิ้ง · เดิมกิน **126,721 bytes = 45%** ของไฟล์นี้

**เปิดไฟล์นั้นเมื่อ:** จะสร้าง/แก้ field · optionset · relation · state machine · form rule · DoD ของ FR ตัวใดตัวหนึ่ง (FR-HR-01 … FR-HR-27)

## §3. Workflow Catalog

📄 **ย้ายไป `22-Workflow-Catalog-HR.md` แล้ว (31 ส.ค. 2569)** — เนื้อหาครบเหมือนเดิม ไม่ได้ตัดทิ้ง · เดิมกิน **63,079 bytes = 22%** ของไฟล์นี้

**เปิดไฟล์นั้นเมื่อ:** จะสร้าง/แก้ workflow ตัวใดตัวหนึ่ง (WF-HR-01 … WF-HR-20) — node-by-node · Surface · Test recipe

🔴 **ID จริงของ workflow ที่ publish แล้ว อยู่ที่ `17-ID-Registry-HR.md`** (ไฟล์ `22-` ยังมี `<TBD-WF-xx>` สำหรับตัวที่ยังไม่สร้าง)

## §4. Non-functional (NFR)

| รหัส | สถานะ | ทำอย่างไรบน Nocoly / Gap | วิธี verify |
|---|---|---|---|
| NFR-HR-01 สิทธิ์และขอบเขตข้อมูล | ⬜ | `create_role` + `worksheetPermissions[]` ตาม §1.7 · scope "ของตนเอง" ผูกกับ `_owner` / `_createdBy` · "ผู้ใต้บังคับบัญชา" ใช้ scope 30 หรือ View filter | `get_role_details` + **เข้าระบบด้วยบัญชีทดสอบจริงของแต่ละบทบาท** (Gap G-06) |
| NFR-HR-02 ปิดบังข้อมูลอ่อนไหว | ⬜ | ตั้ง field-level visibility ใน role (🔴 **UI เท่านั้น**) ตามตารางใน §1.7 | Role Debugging → เปิดฟอร์ม → ฟิลด์ต้องไม่ปรากฏ · ทดสอบการส่งออกด้วย |
| NFR-HR-03 audit trail | ⬜ | `get_record_logs` + `_updatedBy` มีทุก worksheet โดยอัตโนมัติ · **Application Logs** ใน org console สำหรับ "ใครดู/พิมพ์/ดาวน์โหลด" — ไม่ต้องสร้างตาราง log เอง | `get_record_logs(hr_salary_structure, rowid)` เห็นค่าก่อน-หลัง (**AC-18**) |
| NFR-HR-04 SLA | ⬜ | WF-HR-06 · ค่า SLA อ่านจาก `hr_setting.approval_sla_days` | **AC-14** |
| NFR-HR-05 PDPA | 🔶 | ฟิลด์ `pdpa_consent_date` และ `data_retention_until` บน `hr_candidate` · **workflow ลบข้อมูลผู้สมัครที่หมดอายุยังไม่มีในเฟสนี้** — ⚠️ Gap | ตรวจว่าทุก record ผู้สมัครมีวันที่ยินยอม |
| NFR-HR-06 ความถูกต้องการคำนวณ | ⬜ | ชุดทดสอบ 3 เคสใน WF-HR-08 Test recipe | **AC-06** — เทียบกับกระดาษคำนวณทุกบรรทัด |
| NFR-HR-07 ความสมบูรณ์ของข้อมูล | ⬜ | **Unique index** 15 ตัว (IX-03.1/2 · IX-09.1 · IX-10.1 · IX-12.1/2/3/4/5/6 · IX-18.1 · IX-22.1/2 · IX-23.1) 🔴 ไม่ใช่ `isUnique` | **AC-15** — `create_record` ซ้ำผ่าน API ต้องถูกปฏิเสธ |
| NFR-HR-08 ห้ามลบเอกสารที่อนุมัติแล้ว | ⬜ | role `recordDataScope` delete = 0 ทุกบทบาท ยกเว้น R4 · + Business Rule lock | ทดสอบลบด้วยบัญชี R1 R3 → ต้องทำไม่ได้ |
| NFR-HR-09 ทุก logic บน Nocoly | ✅ | ทุก FR ในสเปกนี้ใช้เฉพาะ worksheet · workflow · business rule · role — ไม่มีสคริปต์ภายนอก | ตรวจสอบสเปกไม่มีการอ้างระบบภายนอก |
| NFR-HR-10 เขตเวลาและปฏิทิน | ⬜ | DateTime ทุกค่าเขียนพร้อม `+07:00` · schedule ทุกตัวตั้ง +07:00 · พุทธศักราชทำใน print template | อ่านค่ากลับต้องแสดงเวลาไทยถูกต้อง |
| NFR-HR-11 การใช้งาน | ⬜ | View "ใบลาของฉัน" + ปุ่ม "ส่งคำขอ" บนหน้า record · Custom page หน้าแรกของพนักงาน (Browser) | จับเวลาการยื่นใบลาจริง ≤ 3 คลิก |
| NFR-HR-12 SoD | ⬜ | R5 Payroll และ R8 Admin **ไม่มี To-do อนุมัติ** และไม่ปรากฏใน `hr_approval_rule` · R5 edit `hr_employee` = 0 | **AC-13** — เข้าระบบด้วยบัญชี R5 → ต้องไม่มีปุ่มหรือรายการงานอนุมัติ |
| NFR-HR-13 การกู้คืน | ⬜ | **Backup & Restore ก่อนสร้าง/ลบฟิลด์ทุกครั้ง** · **App Lock หลัง go-live** | ตรวจว่ามี backup ล่าสุดก่อนงานที่แตะโครงสร้าง |

---

## §5. Verification Cookbook

| ต้องตรวจ | เรียก | ผลที่คาด |
|---|---|---|
| ยืนยันแอปถูกตัว | `get_app_info` | `appId` = `deca7391-1761-424b-9af3-c8d043004ad3` · ชื่อ **ERP - TILSNA** |
| worksheet ที่สร้างแล้ว | `get_app_worksheets_list(responseFormat:"md")` | 🔴 ใช้ tool นี้ตรวจ **ชื่อตาราง** — `get_worksheet_structure` คืนชื่อตารางเป็นค่าเก่าเสมอ |
| field / option / relation | `get_worksheet_structure(ws, responseFormat:"md")` | ตารางฟิลด์พร้อม `id` `alias` `type` `subType` `options` `dataSource` |
| optionset + option key | `get_optionset_list` | 🔴 คัดลอก `key` (GUID) มาใส่ registry — **workflow อ้าง key ไม่ใช่ label** |
| role ที่สร้างแล้ว | `get_role_list` · `get_role_details` | ✅ tenant นี้คืน custom role ครบ (ต่างจากที่ playbook เตือน) |
| นับ record | `get_record_pivot_data(ws, viewId, COUNT, includeSummary:true)` | 🔴 ต้องมี `viewId` หรือ `rows` dimension ไม่งั้น error |
| **workflow ยิงจริง** | `get_record_details(ws, rowid, includeSystemFields:true)` | 🔴 `_updatedBy` = **`user-workflow`** ← หลักฐานที่เชื่อถือได้ที่สุด |
| ประวัติการแก้ | `get_record_logs(ws, rowid)` | ⚠️ operator แสดงตามผู้จุดชนวน (อาจเป็น `user-api`) แม้ workflow เป็นคนเขียน — ใช้ควบคู่กับ `_updatedBy` |
| approval instance | `get_approval_list_by_row(ws, rowid)` · `get_approval_detail` | process + ผู้รับผิดชอบ + สถานะ |
| โครงสร้าง workflow | `get_workflow_structure(processId)` | 🔴 ใช้หา `nodeId` ของ start node ใน approval_block (ไม่มี alias) |
| **มี workflow อยู่จริงไหม** | ❌ **ไม่ใช่** `get_workflow_list` | 🔴 คืนเฉพาะ PBP · ยืนยันที่หน้า **Automated Workflow** หรือ `get_workflow_structure` ด้วย processId ที่รู้ |
| ทดสอบ worksheet trigger | `create_record` / `update_record` (`triggerWorkflow:true`) | 🔴 **ห้ามใช้ `trigger_workflow`** (คนละกลไก) |
| ทดสอบ schedule / date trigger | กด **"Execute now"** ใน Browser หรือรอรอบ | Workflow History tab + `_updatedBy` = `user-workflow` |
| ทดสอบ Custom Action | กดปุ่มใน Browser ด้วยบัญชีของ role นั้น | log แสดง `user-self` (การกด) ตามด้วย `user-workflow` (WF ที่รับช่วง) |
| ทดสอบกฎฟอร์ม / สิทธิ์ | **Role Debugging** (สลับเป็น role เป้าหมายแล้วเปิดฟอร์ม) | 🔴 ไม่ใช่ `get_record_logs` |
| ทดสอบ unique index | `create_record` ค่าซ้ำ | ต้องถูกปฏิเสธ (⚠️ การบังคับฝั่ง API เป็นข้อสรุปจาก docs — **ต้องทดสอบจริง**) |
| ตรวจใบสำคัญดุล | `get_record_details(ac_voucher, rowid)` | `total_debit` `6a8603f4055f2288c5b777d2` = `total_credit` `6a8604c08b36df988c176286` · `balance_diff` `6a860ae8055f2288c5b777f1` = 0 |

**Record ทดสอบที่ต้องเตรียม (ก่อนเริ่มเฟส 2)**

| ชุด | เนื้อหา | ใช้ทดสอบ |
|---|---|---|
| EMP-T1 | พนักงานทั่วไป · มี `supervisor` = EMP-T2 · `emp_user` = บัญชีทดสอบ 1 | ใบลา · OT · ใบเบิก · สิทธิ์ R1 |
| EMP-T2 | หัวหน้างาน · `emp_user` = บัญชีทดสอบ 2 | อนุมัติขั้น 1 · สิทธิ์ R2 |
| EMP-T3 | เจ้าหน้าที่ HR · `emp_user` = บัญชีทดสอบ 3 | อนุมัติขั้น 2 · สิทธิ์ R3 |
| EMP-T4 | เจ้าหน้าที่ Payroll · `emp_user` = บัญชีทดสอบ 4 | SoD (**AC-13**) · คำนวณสลิป |
| LEAVE-T1 | ใบลาพักผ่อน 2 วัน สถานะ Draft | WF-HR-01 เส้นทางปกติ |
| LEAVE-T2 | ใบลาที่ทับซ้อนกับ LEAVE-T1 | WF-HR-01 node 6 |
| LEAVE-T3 | ใบลาเกินสิทธิคงเหลือ | BR-08.2 + WF-HR-01 node 9 |
| PERIOD-T1 | งวดจ่ายทดสอบผูกกับงวดบัญชีที่ยังเปิด | WF-HR-07 → 08 → 09 → 10 |
| CLAIM-T1 / T2 | ใบเบิกที่พอดีวงเงิน / เกินวงเงิน | WF-HR-11 · WF-HR-12 |

> 🔴 **วิธี reset:** ลบ record ทดสอบตามลำดับย้อนกลับ (line → header) · คืนค่าธงทุกตัวเป็น 0 · คืน `hr_leave_balance` / `hr_welfare_balance` เป็นค่าตั้งต้น · ลบ `ac_voucher_line` ก่อน `ac_voucher` เสมอ

---

## §6. Data Model

```
                                    ┌──────────────────────┐
        ac_cost_center ────────────<│    hr_employee       │>──── hr_position
        (โมดูลบัญชี ✅)              │  (ทะเบียนพนักงาน)    │>──── hr_job_level
                                    │  supervisor ─┐        │>──── hr_shift
                                    └──────┬───────┘ (self) │
                                           │ └──────────────┘
        ┌──────────────────────────────────┼──────────────────────────────────┐
        │                 │                │              │                  │
        ▼                 ▼                ▼              ▼                  ▼
 hr_employment_    hr_dependent      hr_bank_       hr_attendance      hr_leave_request
   contract                          account              │                  │
        │                                                 └───────┬──────────┘
        ▼                                                         ▼
 hr_employment_event                                       hr_leave_balance ──< hr_leave_ledger
                                                                  ▲
                                                    hr_leave_type ─┴─< hr_leave_policy

        hr_ot_rate >──── hr_ot_request ────┐
                                            │
 hr_pay_period ──< hr_payslip ──< hr_payslip_line >──── hr_pay_component >──── ac_coa ✅
      │  │              ▲                                        ▲
      │  │              └──── hr_salary_structure ───────────────┘
      │  │
      │  └──> ac_voucher ✅ ──< ac_voucher_line ✅   (WF-HR-10 · อ้าง ac_posting_rule ✅)
      │
      └──> ac_period ✅

 hr_pnd1_filing ──< hr_wht_cert >──── hr_employee

 hr_welfare_scheme ──< hr_welfare_balance >──── hr_employee
 hr_claim ──< hr_claim_line          hr_claim ──> ac_pay_req ✅   (WF-HR-12)

 hr_job_requisition ──< hr_candidate ──< hr_interview
                              └──(WF-HR-17)──> hr_employee

 hr_appraisal_cycle ──< hr_appraisal ──< hr_appraisal_item
 hr_course ──< hr_training >──── hr_employee

 hr_setting (singleton) · hr_holiday · hr_sso_rate · hr_tax_bracket
 hr_tax_allowance · hr_approval_rule            (ตารางตั้งค่า — ไม่มี relation ขาเข้า)

 ✅ = ตารางเดิมของโมดูลบัญชี ห้ามสร้างซ้ำ
```

**ลำดับการสร้างที่ปลอดภัย (relation ต้องมีปลายทางก่อน):**
1. ตารางตั้งค่า HR-00 ทั้ง 10 ตาราง (ไม่มี relation ขาออกไปหา HR ตารางอื่น ยกเว้น `hr_leave_type.pay_component` → สร้างทีหลัง)
2. `hr_position` · `hr_job_level` → `hr_employee` (relation ไปตัวเองสร้างทีหลังด้วย `update_worksheet.addFields`)
3. `hr_employment_contract` · `hr_employment_event` · `hr_dependent` · `hr_bank_account`
4. `hr_pay_component` → ย้อนกลับไปเพิ่ม `hr_leave_type.pay_component`
5. `hr_leave_balance` → `hr_leave_request` → `hr_leave_ledger`
6. `hr_attendance` · `hr_ot_request`
7. `hr_pay_period` → `hr_salary_structure` → `hr_payslip` → `hr_payslip_line`
8. `hr_pnd1_filing` → `hr_wht_cert`
9. `hr_welfare_scheme` → `hr_welfare_balance` → `hr_claim` → `hr_claim_line`
10. `hr_job_requisition` → `hr_candidate` → `hr_interview`
11. `hr_appraisal_cycle` → `hr_appraisal` → `hr_appraisal_item` · `hr_course` → `hr_training`

> 🔴 **relation ที่ชี้กลับตัวเอง** (`hr_employee.supervisor`) และ **relation ที่ชี้ไปตารางที่ยังไม่มี** ต้องเพิ่มภายหลังด้วย `update_worksheet.addFields` — ⚠️ **ห้ามใช้ `editFields` แตะฟิลด์เดิมพร้อมกัน**

---
*แก้ object เมื่อไร อัปเดต §1 และ §3 ทันที เพื่อให้ยังเป็นแหล่งอ้างอิงที่เชื่อถือได้*
