# Build Spec / FRS สำหรับ Agent — โมดูลทรัพยากรบุคคล (HR) · TILSNA ERP (Nocoly)

> คู่กับ `01-BRD.md` — BRD บอก "ทำอะไร" · ไฟล์นี้บอก "ทำกับ object ไหน ด้วย ID อะไร เสร็จแล้ววัดอย่างไร"
> **สถานะโมดูล: Greenfield ในแอป Brownfield** — แอปมีโมดูลบัญชี 34 ตารางทำงานอยู่แล้ว แต่ **ยังไม่มี object ของ HR แม้แต่ชิ้นเดียว** (ยืนยันด้วย `get_app_info` · `get_optionset_list` · `get_role_list` เมื่อ 26 ส.ค. 2569)
> ⇒ **ID ของ HR ทุกตัวเป็น `<TBD>`** ต้องเติมทันทีหลังสร้าง object จริง · **ID ของโมดูลบัญชีทุกตัวในไฟล์นี้ดึงจากเซิร์ฟเวอร์จริงแล้ว ใช้ได้เลย ห้ามแก้**
> อัปเดต: 28 สิงหาคม 2569 (ต่อเนื่อง 5 — ✅ **Gap G-02 ปิดแล้ว: ฝ่ายบัญชีสร้างบัญชีใหม่ 3 รายการในผังบัญชีจริง (`530102`/`210402`/`210304`) + เพิ่ม `event_code`=PAYROLL_ACCRUAL/PAYROLL_PAYMENT — HR ผูก `hr_pay_component.biz_coa_account` ครบ 6/6 (P5-4 ปิดเต็ม) — WF-HR-10 source-of-truth ยืนยันแล้ว: `ac_posting_rule` หลัก / `hr_pay_component` fallback — G-05 (อัตรา SSO/ภาษี/เลขทะเบียนบริษัท) ยังเปิดอยู่ ห้ามเดา** — ก่อนหน้านั้น: ต่อเนื่อง 4 — 🟢 **WF-HR-05/WF-HR-06 สร้าง+publish สำเร็จผ่าน MCP ทั้งคู่** (main+inner ทั้ง 4 process, validate สะอาด 0 error) ยืนยัน D-16 fix ใช้ได้กับ build จริง — WF-HR-06 v1 ครอบคลุมเฉพาะ `hr_leave_request` (ดู D-18: `hr_ot_request` ไม่มีฟิลด์ `submitted_at`) — ⚠️ **live-fire test ของทั้งคู่ยังทำไม่ได้เพราะ D-17: worksheet_event workflow ทั้งหมดไม่ยิงเลยตอนนี้** เป็นปัญหาระดับ session/environment/platform ไม่ใช่ WF-HR-01 เจาะจง (re-verify WF-HR-01 + sanity-check WF-HR-04 ทั้งคู่ไม่ยิง แม้โครงสร้าง published สมบูรณ์) — บล็อกการพิสูจน์ Test recipe ที่ต้องยิงจริงของทุก workflow จนกว่าจะคลี่คลาย ส่วนการสร้าง/publish โครงสร้างยังทำต่อได้ปกติ — ก่อนหน้านั้น: ต่อเนื่อง 3 — 🟢 D-16: D-13 คลี่คลายแล้ว! root cause คือต้อง publish inner sub_process ก่อน outer เสมอ — ดู Known Issues ใน `04-CLAUDE-memory.md`)

---

## §0. กฎปฏิบัติของ Agent (DO / DON'T) — อ่านก่อนทำทุกครั้ง

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

> 🔴🔴 **`create_worksheet` (สร้างตารางใหม่) พังทั้งระบบตั้งแต่ 26 ส.ค. 2569** — ทุกครั้ง (ทดสอบ 6 payload ต่างกัน ข้าม connector/แอป) คืน error `Validation failed: structuredContent does not match tool outputSchema... required property 'appId' not found` และไม่สร้างตารางเลย · **วิธีแก้ที่ยืนยันแล้วว่าใช้ได้:** (1) `create_app_items` (`type:"worksheet"`) → ได้ worksheet เปล่าพร้อม field default 3 ตัว (名称/描述/附件 = wsid+1/+2/+3 ในเลขฐาน 16) (2) `get_worksheet_structure` ยืนยัน ID field default (3) `update_worksheet.removeFields` ลบ field default ทั้ง 3 (4) `update_worksheet.addFields` เติมฟิลด์จริงทั้งหมด (5) `get_worksheet_structure` verify — **ใช้วิธีนี้สร้างครบทั้ง 10 ตาราง HR-00 + hr_ot_request/hr_attendance + hr_pay_component/hr_pay_period/hr_salary_structure สำเร็จแล้ว** ดู Known Issues ในนี้และ CLAUDE-memory
> **type ต้องเป็น enum ที่ `addFields` รับจริง**: `Text` `Number` `SingleSelect` `MultipleSelect` `Date` `DateTime` `Collaborator` `Relation` `Checkbox` `Role` (+ `Attachment` `Rating` `Time` best-effort) — **ยืนยันแล้วว่า `Checkbox`/`Role` สร้างผ่าน `addFields` ได้จริง** (แก้ไขจากที่เข้าใจผิดก่อนหน้านี้ว่าต้อง Browser)
> ชนิดอื่น (`Department` `SubTable` `Formula` `AutoNumber` `Location` `Rollup`) 🔴 ยังไม่ทดสอบ/ยังต้อง **สร้างใน Browser** แล้วอ่าน ID กลับด้วย `get_worksheet_structure`
> 🔴 **`Dropdown` ที่ผูก shared optionset (เช่น 24 ชุด OS_HR_* ใน §1.6) ผูกผ่าน API ไม่ได้เลย** ทั้ง `create_worksheet` และ `addFields` — `addFields` ให้แค่ `options[]` inline (สร้าง option ใหม่เฉพาะฟิลด์ ไม่ใช่ผูกกับ optionset ที่มีอยู่) — **การผูก shared optionset ทำได้แค่ตอนสร้างฟิลด์ใหม่ใน Browser UI เท่านั้น** ยืนยันซ้ำหลายรอบล่าสุดถึง P5-1 (27 ส.ค. 2569)
> `subType` ที่ใช้บ่อย: Relation `1` = เดี่ยว · `2` = หลายรายการ/ย้อนกลับ · Date `3` = Y-M-D · DateTime `1` = Y-M-D h:m · Text `1` = หลายบรรทัด (ใช้ `config:{textMode:"multiLine"}`)

---

### FR-HR-01 การตั้งค่าโมดูลบุคคล
**Worksheet:** การตั้งค่าโมดูลบุคคล `hr_setting` `6a8eebbd353e1b0e4a507477` · **มี record เดียว** (singleton)

✅ **สร้างจริงแล้ว 26 ส.ค. 2569** (ยืนยันด้วย `get_worksheet_structure`) — alias จริงบนเซิร์ฟเวอร์ใช้ prefix `hr_` แทนชื่อในสเปกเดิม (บันทึกคอลัมน์ alias ด้านล่างเป็นค่าจริง)

| ฟิลด์ (ไทย) | alias (จริง) | ID | type | subType / props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อการตั้งค่า | `hr_setting_name` | `6a8eebdf353e1b0e4a507481` | `Text` | — | isTitle · default "การตั้งค่าโมดูลบุคคล" |
| ชั่วโมงทำงานมาตรฐานต่อวัน | `hr_std_hours_per_day` | `6a8eebdf353e1b0e4a507482` | `Number` | precision 2 · default 8 | A-HR-03 |
| วันทำงานมาตรฐานต่อสัปดาห์ | `hr_std_days_per_week` | `6a8eebdf353e1b0e4a507483` | `Number` | precision 0 · default 5 | |
| นาทีผ่อนผันการมาสาย | `hr_late_grace_minutes` | `6a8eebdf353e1b0e4a507484` | `Number` | precision 0 · default 15 | A-HR-04 |
| นาทีที่นับเป็นลาครึ่งวัน | `hr_late_to_halfday_minutes` | `6a8eebdf353e1b0e4a507485` | `Number` | precision 0 · default 240 | A-HR-04 |
| รอบปีสิทธิลา | `hr_leave_year_basis` | `6a8eebdf353e1b0e4a507486` | `SingleSelect` | Calendar year (key `59431263-a67f-4b07-9038-c54b52952646`) / Employment year (key `4666bf66-01a9-4dfc-8448-7ff0181b2443`) | default Calendar year (A-HR-01) |
| วันตัดรอบเวลาของงวดเงินเดือน | `hr_payroll_cutoff_day` | `6a8eebdf353e1b0e4a507487` | `Number` | precision 0 · default 25 | A-HR-02 |
| จำนวนวันลาที่ต้องเพิ่มขั้นผู้บริหาร | `hr_exec_approval_days` | `6a8eebdf353e1b0e4a507488` | `Number` | precision 0 · default 5 | A-HR-08 · WF-HR-01 อ่านค่านี้ |
| SLA อนุมัติต่อขั้น (วันทำการ) | `hr_approval_sla_days` | `6a8eebdf353e1b0e4a507489` | `Number` | precision 0 · default 1 | WF-HR-06 อ่านค่านี้ |
| ชื่อบริษัท (ไทย) | `hr_company_name_th` | `6a8eebdf353e1b0e4a50748a` | `Text` | — | ใช้บนเอกสารที่พิมพ์ |
| ชื่อบริษัท (อังกฤษ) | `hr_company_name_en` | `6a8eebdf353e1b0e4a50748b` | `Text` | — | ใช้บนเอกสารที่พิมพ์ |
| เลขประจำตัวผู้เสียภาษีของบริษัท | `hr_company_tax_id` | `6a8eebdf353e1b0e4a50748c` | `Text` | — | ใช้บน ภ.ง.ด.1 |
| เลขที่บัญชีนายจ้างประกันสังคม | `hr_sso_employer_no` | `6a8eebdf353e1b0e4a50748d` | `Text` | — | ใช้บน สปส.1-10 |

**⚠️ หมายเหตุ:** ไม่ได้ตั้ง `defaultValue`/`required` ผ่าน field-level default บนเซิร์ฟเวอร์ตามที่ตั้งใจทั้งหมด (บาง field ส่ง defaultValue ตอน `addFields` แล้ว แต่ readback ด้วย `responseFormat:md` ไม่แสดงค่า default กลับมา — ต้อง verify ด้วยการเปิด record จริงใน Browser หรือ `get_record_details` หลัง seed record แรกใน Task #9) · Unique index บน `hr_setting_name` (IX-01.1) ยังไม่ได้ตั้ง — `isUnique` ผ่าน API ใช้ยืนยันตัวตนไม่ได้ ต้องตั้ง **Index Acceleration** ใน Browser ก่อน seed

**Form rules:** IX-01.1 Unique index บน `setting_name` (กันสร้าง record ที่ 2)
**DoD:** มี record เดียว · ทุก workflow ที่ต้องใช้ค่าคงที่อ่านจากตารางนี้ ไม่มีตัวเลขฝังใน node
**วิธี verify:** `get_record_list(hr_setting)` ได้ 1 record · ค้นคำว่าตัวเลขคงที่ในสเปก workflow ต้องไม่พบ

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — record ID `e1eed08e-7832-49b9-9571-0e2965bc76a8` ยืนยันด้วย `get_record_details` (SingleSelect เขียนด้วย option **key** GUID แล้วอ่านกลับถูกต้อง — ยืนยันรูปแบบการเขียนค่า select field ผ่าน `create_record`/`batch_create_records`) · `hr_company_tax_id` และ `hr_sso_employer_no` เป็น **placeholder ยังไม่ยืนยัน** (รอ P0-5) — ห้ามใช้พิมพ์เอกสารจริงจนกว่าจะแก้ไข

---

### FR-HR-01B กฎการอนุมัติของโมดูลบุคคล (เพิ่มระหว่างสร้างจริง — เดิมไม่มี field table ในสเปกฉบับแรก)
**Worksheet:** กฎการอนุมัติของโมดูลบุคคล `hr_approval_rule` `6a8eebf81378964f998499f8` — ตารางตั้งค่าที่ workflow ทุกสายอนุมัติ (WF-HR-01/04/06/09/12/17…) ใช้ `get_single` ค้นหา **ภายในสายอนุมัติ** (ห้าม `update_record` คัดลอกค่า Role ออกมา — ดู DO/DON'T §0)

✅ **สร้างจริงแล้ว 26 ส.ค. 2569** — `Role` และ `Checkbox` สร้างผ่าน `update_worksheet.addFields` **สำเร็จทั้งคู่** (ทดสอบแยกและ verify ด้วย `get_worksheet_structure` แล้ว) — ⚠️ **แก้ CLAUDE-memory เดิม**: บทเรียนที่ว่า Checkbox สร้างผ่าน API ไม่ได้ ใช้ได้กับ `create_worksheet` เท่านั้น (ซึ่งพังทั้งระบบตอนนี้ ดู Known Issues) **ไม่ใช่กับ `addFields`**

| ฟิลด์ (ไทย) | alias (จริง) | ID | type | props | option / relation | หมายเหตุ |
|---|---|---|---|---|---|---|
| ชื่อกฎ | `hr_rule_name` | `6a8eec558b6633ef76f12a3c` | `Text` | isTitle · required | — | เช่น "อนุมัติใบลา ขั้น HR" |
| ประเภทเอกสาร | `hr_doc_kind` | `6a8eec558b6633ef76f12a3d` | `SingleSelect` | required | Leave request=`f5987850-969f-45d6-add7-9cbe2e6a6a2e` · OT request=`402a261b-ba3f-4e76-941a-0791d5ceea84` · Payroll period=`0f03c028-ef9c-4eee-9611-bd3d62d0c831` · Job requisition=`37fb0e1f-ce0c-4f41-bdf5-64af2aacd96a` · Welfare claim=`cf66e7eb-d740-48e8-aeaa-f11df24575cb` | 🔴 workflow filter ต้องอ้าง key ข้างต้น ไม่ใช่ label |
| ระดับการอนุมัติ | `hr_approval_level` | `6a8eec558b6633ef76f12a3e` | `Number` | precision 0 · required | — | 1 = หัวหน้างาน/หัวหน้าหน่วยงาน · 2 = HR · 3 = ผู้บริหาร (A-HR-08) |
| หน่วยงานที่ใช้กฎนี้ | `hr_rule_cost_center` | `6a8eec558b6633ef76f12a3f` | `Relation` | subType 1 · dataSource → `ac_cost_center` `6a85452b9b6999a714d26720` ✅ | — | ว่าง = ทุกหน่วยงาน (กฎ default) |
| หมายเหตุ | `hr_rule_remark` | `6a8eec558b6633ef76f12a41` | `Text` | multiLine | — | |
| ผู้อนุมัติ (ตามบทบาท) | `hr_approver_role` | `6a8eec6e8b6633ef76f12a56` | `Role` | ✅ สร้างผ่าน API สำเร็จ | — | ผูกกับ custom role HR-R3 (HR) หรือ HR-R6 (ผู้บริหาร) แล้วแต่ระดับ — ใช้ใน Approve node ผ่าน `get_single` ตรง ๆ (ห้าม `update_record` คัดลอก) — ยังไม่ได้ผูก role จริง (role ยังไม่สร้าง §1.7) |
| เปิดใช้งาน | `hr_rule_is_active` | `6a8eec6e8b6633ef76f12a57` | `Checkbox` | ✅ สร้างผ่าน API สำเร็จ | — | |

**Form rules:** IX-01B.1 Unique index (`doc_kind`, `approval_level`, `cost_center`) — กันสร้างกฎซ้ำหน่วยงานเดียวกัน
**DoD:** seed อย่างน้อย 1 กฎต่อ `doc_kind` ที่มี workflow ใช้งานจริงในเฟสนั้น (เริ่มจาก Leave request 2 แถว: level 1 = ว่าง (ใช้ `hr_employee.supervisor` แทน) — จริง ๆ level 1 ของใบลาไม่ผ่านตารางนี้ (ดู WF-HR-01 หมายเหตุ) มีแค่ level 2 = HR)

⬜ **ยังไม่ seed (26 ส.ค. 2569)** — รอสร้าง role จริง (§1.7) ก่อน เพราะ `hr_approver_role` ต้องผูกกับ role ที่มีอยู่จริงในระบบ · ยกไปทำพร้อม P8-1 (สร้าง role 8 บทบาท) ไม่ใช่ P1-4
**Pitfall:** 🔴 **ห้าม `update_record` คัดลอกค่าฟิลด์ `approver_role`** (ชนิด Role/OrgRole) — ใช้ node `get_single` ค้นตารางนี้ **ภายในสายอนุมัติ** แล้วให้ `approve.approvers` อ้าง `{kind:"field", node:<get_single nodeId>, fieldId:<approver_role>}` ตรง ๆ

---

### FR-HR-02 ปฏิทินวันหยุดและกะทำงาน

**2A. วันหยุดประจำปี** `hr_holiday` `6a8eebf7353e1b0e4a5074b5` ✅ สร้างจริงแล้ว 26 ส.ค. 2569

| ฟิลด์ | alias (จริง) | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อวันหยุด | `hr_holiday_name` | `6a8eec258b6633ef76f129eb` | `Text` | isTitle | |
| วันที่ | `hr_holiday_date` | `6a8eec258b6633ef76f129ec` | `Date` | subType 3 · required · isUnique ส่งแล้ว | ⚠️ true uniqueness ต้องตั้ง Index Acceleration ใน Browser เพิ่ม |
| ปี | `hr_holiday_year` | `6a8eec258b6633ef76f129ed` | `Number` | precision 0 · required | ใช้กรอง view |
| ประเภทวันหยุด | `hr_holiday_kind` | `6a8eec258b6633ef76f129ee` | `SingleSelect` | Public=`363b670f-a0e3-48e5-9c91-705efda57ab7` · Traditional=`70372de4-623e-493d-b322-fc4eddc46e3a` · Company=`eb006158-cb67-4e14-845a-b86885682acb` · Substitution=`34dcbb19-b642-433e-804a-6b9ce974fb81` | |
| หมายเหตุ | `hr_holiday_note` | `6a8eec258b6633ef76f129ef` | `Text` | multiLine | |

**Form rules:** IX-02.1 Unique index บน (`hr_holiday_date`) — ⚠️ ยังไม่ได้ตั้ง Index Acceleration จริง (isUnique flag เป็นแค่ soft hint) ต้องทำใน Browser ก่อน seed
**Test:** `create_record` วันที่ซ้ำ ต้องถูกปฏิเสธ (ยังไม่ verify — รอ Index Acceleration)

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — 21 วันหยุดราชการปี 2569 (พ.ศ.) ผ่าน `batch_create_records` · ยืนยันจำนวนด้วย `get_record_pivot_data` COUNT = 21 · ที่มา: [ofm.co.th](https://www.ofm.co.th/blog/calendar-holidays-thailand-2569/) (ปฏิทินวันหยุดราชการ ครม. ปี 2569) — รวมวันหยุดพิเศษ 2 ม.ค. และวันหยุดชดเชย 7 ธ.ค. (⚠️ ยังไม่ตรวจสอบกับประกาศ ครม. ฉบับทางการ — ทำก่อน go-live)

**2B. กะการทำงาน** `hr_shift` `6a8eebf79762533b5b7184c5` ✅ สร้างจริงแล้ว 26 ส.ค. 2569

| ฟิลด์ | alias (จริง) | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อกะ | `hr_shift_name` | `6a8eec2d353e1b0e4a5074d6` | `Text` | isTitle | เช่น "กะปกติ 08:30–17:30" |
| รหัสกะ | `hr_shift_code` | `6a8eec2d353e1b0e4a5074d7` | `Text` | required | |
| เวลาเข้างาน | `hr_start_time` | `6a8eec2d353e1b0e4a5074d8` | `Text` | รูปแบบ `HH:mm` | 🔴 เก็บเป็น Text เพื่อเลี่ยงกับดัก timezone ของ Time/DateTime |
| เวลาออกงาน | `hr_end_time` | `6a8eec2d353e1b0e4a5074d9` | `Text` | รูปแบบ `HH:mm` | |
| นาทีพัก | `hr_break_minutes` | `6a8eec2d353e1b0e4a5074da` | `Number` | precision 0 · default 60 | |
| ชั่วโมงทำงานมาตรฐาน | `hr_shift_hours` | `6a8eec2d353e1b0e4a5074db` | `Number` | precision 2 · default 8 | |
| วันทำงานในสัปดาห์ | `hr_work_days` | `6a8eec2d353e1b0e4a5074dc` | `MultipleSelect` | Mon=`0282e409-b5c6-46ed-a1df-09a501d3bdc0` · Tue=`741637da-7a4c-46b7-a411-38de20aeca8a` · Wed=`87eb2643-18d0-40ed-a413-bffcae6d321b` · Thu=`98cfc776-2c93-4d96-9c5d-7e6ec2a2788d` · Fri=`6abcf92b-089d-444a-bcac-afd7309fd711` · Sat=`0eb78774-1a07-447b-98ed-e8dfa61612ab` · Sun=`91cdef16-8679-402b-8494-66bc5ec0ff31` | |
| เปิดใช้งาน | `hr_is_active` | `6a8eec60ae2a0e3743a0bd0a` | `Checkbox` | ✅ สร้างผ่าน `addFields` สำเร็จ (ไม่ต้อง Browser แล้ว) | |

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — 1 กะมาตรฐาน "กะปกติ (เช้า)" 08:30–17:30 จันทร์–ศุกร์ · record ID `106f4366-beef-4252-99db-78379929507b` · ยืนยันด้วย `get_record_pivot_data` COUNT = 1

---

**Definition of Done (FR-HR-02):** seed วันหยุดครบทั้งปีปัจจุบัน (≥ 13 วัน) และกะอย่างน้อย 1 กะที่ `is_active` = จริง · unique index บน `holiday_date` ทดสอบด้วย `create_record` ซ้ำแล้วถูกปฏิเสธ · WF-HR-05 หาวันหยุดเจอจริง (ทดสอบด้วยบันทึกลงเวลาของวันหยุด → `att_status` = Holiday)
**วิธี verify:** `get_record_pivot_data(hr_holiday, viewId, COUNT, includeSummary:true)` ได้จำนวนตรงกับที่ seed

### FR-HR-03 ทะเบียนพนักงาน (แกนกลางของโมดูล)
**Worksheet:** ทะเบียนพนักงาน `hr_employee` `6a8efa5e9762533b5b7185c1` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 (view "ทั้งหมด" `6a8efa5e9762533b5b7185c5`)

> ⚠️ **gender/marital_status/employment_type/emp_status สร้างเป็น inline options ชั่วคราว** (ค่าเดียวกับ shared optionset แต่เป็น option ใหม่แยกต่างหาก ไม่ใช่ตัวเดียวกับ `OS_HR_*` ใน §1.6) เพราะ `addFields` ผูก shared optionset ให้ Dropdown ไม่ได้เลย (ยืนยันซ้ำอีกครั้งตอนสร้างตารางนี้) — ต้องลบ 4 ฟิลด์นี้แล้วสร้างใหม่ผ่าน Browser (เลือก "ใช้ชุดตัวเลือกที่มีอยู่") แบบเดียวกับที่โมดูลบัญชีทำไปแล้ว 20 ฟิลด์ (ดู `tilsna-accounting/08-Naming-Rollout-Report.md` §3.4) — งานค้างใน Roadmap Tracker

| ฟิลด์ (ไทย) | alias | ID | **type** | subType / props | option / relation | หมายเหตุ |
|---|---|---|---|---|---|---|
| รหัสพนักงาน | `emp_code` | `6a8efa78353e1b0e4a5075c6` | `Text` | required · isUnique ส่งแล้ว | — | 🔴 isTitle · **true unique index ยังไม่ตั้ง** (P2-5) |
| คำนำหน้า | `title_th` | `6a8efa78353e1b0e4a5075c7` | `SingleSelect` | นาย/นาง/นางสาว/อื่น ๆ | — | |
| ชื่อ (ไทย) | `first_name_th` | `6a8efa78353e1b0e4a5075c8` | `Text` | required | — | |
| นามสกุล (ไทย) | `last_name_th` | `6a8efa78353e1b0e4a5075c9` | `Text` | required | — | |
| ชื่อ-นามสกุล (อังกฤษ) | `full_name_en` | `6a8efa78353e1b0e4a5075ca` | `Text` | — | — | ใช้บนเอกสารภาษาอังกฤษ |
| ชื่อเล่น | `nickname` | `6a8efa78353e1b0e4a5075cb` | `Text` | — | — | |
| **เลขประจำตัวประชาชน** | `national_id` | `6a8efa78353e1b0e4a5075cc` | `Text` | required · isUnique ส่งแล้ว | — | 🔴 PDPA · **true unique index ยังไม่ตั้ง** (P2-5) · ซ่อนจาก R2 R6 |
| วันเกิด | `birth_date` | `6a8efa78353e1b0e4a5075cd` | `Date` | subType 3 | — | 🔴 PDPA |
| เพศ | `gender` | `6a8efa78353e1b0e4a5075ce` | `Dropdown` | — | inline: Male/Female/Unspecified — ⚠️ ยังไม่ผูก `OS_HR_GENDER` `24979ca6-a3c6-4407-b1c6-ac98e6bdac99` | ต้องลบสร้างใหม่ใน Browser |
| สถานภาพสมรส | `marital_status` | `6a8efa78353e1b0e4a5075cf` | `Dropdown` | — | inline: Single/Married/Divorced/Widowed — ⚠️ ยังไม่ผูก `OS_HR_MARITAL_STATUS` `0da6dd2f-0cdb-4618-8491-237bbb3ec4de` | ต้องลบสร้างใหม่ใน Browser |
| สัญชาติ | `nationality` | `6a8efa78353e1b0e4a5075d0` | `Text` | default "ไทย" ส่งแล้ว | — | |
| ที่อยู่ตามทะเบียนบ้าน | `address_registered` | `6a8efa78353e1b0e4a5075d1` | `Text` | multiLine | — | 🔴 PDPA |
| ที่อยู่ปัจจุบัน | `address_current` | `6a8efa78353e1b0e4a5075d2` | `Text` | multiLine | — | 🔴 PDPA |
| โทรศัพท์มือถือ | `mobile` | `6a8efa78353e1b0e4a5075d3` | `Text` | — | — | |
| อีเมล | `email` | `6a8efa78353e1b0e4a5075d4` | `Text` | — | — | |
| ผู้ติดต่อกรณีฉุกเฉิน | `emergency_contact` | `6a8efa78353e1b0e4a5075d5` | `Text` | — | — | |
| **บัญชีผู้ใช้ในระบบ** | `emp_user` | `6a8efa78353e1b0e4a5075d6` | `Collaborator` | subType 0 · required | — | 🔴 หัวใจของสิทธิ์ — ใช้ผูก record scope "ของตนเอง" และเป็นผู้รับแจ้งเตือน |
| **ผู้บังคับบัญชา** | `supervisor` | `6a8efa7e9762533b5b7185cc` | `Relation` | subType 1 · dataSource `6a8efa5e9762533b5b7185c1` (ตัวเอง) — เพิ่มทีหลังผ่าน `addFields` สำเร็จ 26 ส.ค. 2569 | → `hr_employee` (ตัวเอง) · reverse field auto-created `6a8efa7e9762533b5b7185cd` (ยังไม่ตั้งชื่อใหม่ — แสดงเป็น "ทะเบียนพนักงาน") | G-04 |
| **บัญชีผู้ใช้ของผู้บังคับบัญชา** | `supervisor_user` | `6a8efa78353e1b0e4a5075d7` | `Collaborator` | subType 0 | — | 🔴 **จำเป็นสำหรับ Approve node** — เขียนโดย workflow จากทะเบียนของหัวหน้า (Approve node เลือกผู้อนุมัติได้เฉพาะฟิลด์ Collaborator บนตารางหลักของ approval) |
| หน่วยงาน | `cost_center` | `6a8efa78353e1b0e4a5075d8` | `Relation` | subType 1 · dataSource `6a85452b9b6999a714d26720` | → `ac_cost_center` (ของบัญชี) | ✅ ใช้ตารางเดิม |
| ตำแหน่งงาน | `position` | `6a8efa78353e1b0e4a5075da` | `Relation` | subType 1 · dataSource `6a8ef9901378964f99849a6d` | → `hr_position` | |
| ระดับพนักงาน | `job_level` | `6a8efa78353e1b0e4a5075dc` | `Relation` | subType 1 · dataSource `6a8ef9909762533b5b71859a` | → `hr_job_level` | ใช้กำหนดสิทธิลาและวงเงินสวัสดิการ |
| กะการทำงาน | `shift` | `6a8efa78353e1b0e4a5075de` | `Relation` | subType 1 · dataSource `6a8eebf79762533b5b7184c5` | → `hr_shift` | |
| ประเภทการจ้าง | `employment_type` | `6a8efa78353e1b0e4a5075e0` | `Dropdown` | — | inline: Monthly/Daily/Hourly/Contract/Outsourced — ⚠️ ยังไม่ผูก `OS_HR_EMPLOYMENT_TYPE` `65390c18-4ecb-4243-9098-12e6b91730e5` | ต้องลบสร้างใหม่ใน Browser |
| **สถานะพนักงาน** | `emp_status` | `6a8efa78353e1b0e4a5075e1` | `Dropdown` | default Probation ส่งแล้ว | inline: Probation/Active/On leave/Suspended/Resigned/Terminated/Retired — ⚠️ ยังไม่ผูก `OS_HR_EMP_STATUS` `280d4f69-366d-4564-ae72-800f42fc42d9` | ต้องลบสร้างใหม่ใน Browser · **Trigger Field ของ WF-HR-13** |
| วันเริ่มงาน | `hire_date` | `6a8efa78353e1b0e4a5075e2` | `Date` | subType 3 · required | — | ใช้คำนวณอายุงานและสิทธิลา |
| วันครบทดลองงาน | `probation_end_date` | `6a8efa78353e1b0e4a5075e3` | `Date` | subType 3 | — | **Date field trigger ของ WF-HR-13** |
| วันบรรจุเป็นพนักงานประจำ | `confirm_date` | `6a8efa78353e1b0e4a5075e4` | `Date` | subType 3 | — | |
| วันสิ้นสุดการจ้าง | `termination_date` | `6a8efa78353e1b0e4a5075e5` | `Date` | subType 3 | — | |
| เหตุผลการสิ้นสุดการจ้าง | `termination_reason` | `6a8efa78353e1b0e4a5075e6` | `Text` | multiLine | — | |
| เลขที่ประกันสังคม | `sso_no` | `6a8efa78353e1b0e4a5075e7` | `Text` | — | — | 🔴 PDPA |
| เลขประจำตัวผู้เสียภาษี | `tax_id` | `6a8efa78353e1b0e4a5075e8` | `Text` | — | — | ปกติ = เลขบัตรประชาชน |
| (ระบบ) อายุงาน (ปี) | `service_years` | `6a8efa78353e1b0e4a5075e9` | `Number` | precision 2 | — | 🔴 เขียนโดย workflow ด้วย node `Duration` — **ห้ามใช้ Formula field** |
| รูปถ่าย | `photo` | `6a8efa78353e1b0e4a5075ea` | `Attachment` | — | — | |
| เอกสารประจำตัว | `id_documents` | `6a8efa78353e1b0e4a5075eb` | `Attachment` | — | — | 🔴 PDPA |
| (ระบบ) แจ้งเตือนทดลองงานแล้ว | `probation_alert_flag` | `6a8efa78353e1b0e4a5075ec` | `Number` | precision 0 · **default 0 ส่งแล้ว** | — | กันแจ้งซ้ำ · WF ใช้ `not equal to 1` |

**Relations:** `supervisor` → `hr_employee` (self) · `cost_center` → `ac_cost_center` · `position` → `hr_position` · `job_level` → `hr_job_level` · `shift` → `hr_shift`

**Form rules (Browser · ไม่ใช่ workflow):**
| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-03.1 | Business Rule · interaction | `emp_status` in (Resigned, Terminated, Retired) | required `termination_date` และ `termination_reason` |
| BR-03.2 | Business Rule · validation | `termination_date` < `hire_date` | Block save "วันสิ้นสุดการจ้างต้องไม่ก่อนวันเริ่มงาน" |
| BR-03.3 | Business Rule · interaction | `employment_type` = Outsourced | ซ่อน `sso_no` และกลุ่มฟิลด์เงินเดือน |
| BR-03.4 | Business Rule · interaction | `emp_status` in (Resigned, Terminated, Retired) | Set all read-only (ยกเว้นสำหรับ R4) |
| DV-03.1 | Dynamic default · Query worksheet | เมื่อเลือก `supervisor` | เติม `supervisor_user` จาก `supervisor.emp_user` — ⚠️ **ถ้า dynamic default ทำไม่ได้กับ Collaborator ให้ใช้ WF สั้น ๆ เขียนแทน** |
| IX-03.1 | Unique index | (`emp_code`) | ทั้งฟิลด์ต้อง required · ล้าง recycle bin ก่อนสร้าง |
| IX-03.2 | Unique index | (`national_id`) | ต้อง required — ถ้าอนุญาตให้ว่างได้ index จะรับค่าว่างได้แค่ 1 แถวทั้งตาราง |

**Verify form rules:** Role Debugging → role HR-R2 → เปิดฟอร์มพนักงานคนอื่น → ต้องไม่เห็น `national_id` และ `address_*`
**State machine (`emp_status`):**
| จาก | ไป | ขับด้วย | ผู้มีสิทธิ์ |
|---|---|---|---|
| — | Probation | สร้าง record (หรือ WF-HR-17 จากผู้สมัคร) | R3 R4 |
| Probation | Active | ผู้ใช้แก้ + สร้าง `hr_employment_event` (Confirmed) | R3 R4 |
| Active | On leave / Suspended | ผู้ใช้แก้ | R3 R4 |
| Active | Resigned / Terminated / Retired | ผู้ใช้แก้ + required วันที่และเหตุผล | R4 |

**Definition of Done:** สร้างพนักงานทดสอบ 4 คนที่มีสายบังคับบัญชาจริง · `supervisor_user` มีค่าทุกคนที่มีหัวหน้า · unique index ทั้ง 2 ตัวทำงาน (ทดสอบด้วย `create_record` ซ้ำ)
**Pitfall:** 🔴 ถ้า `supervisor_user` ว่าง → WF-HR-01 จะสร้าง approval ที่ไม่มีผู้อนุมัติ ⇒ ต้องมี branch ตรวจก่อน และตั้ง empty-approver policy = Delegate by the workflow owner

---

### FR-HR-04 ตำแหน่งงานและระดับพนักงาน — ✅ สร้างจริงแล้ว 26 ส.ค. 2569

**4A. ตำแหน่งงาน** `hr_position` `6a8ef9901378964f99849a6d` ✅ (view `6a8ef9901378964f99849a71`)

| ฟิลด์ | alias | ID | type | props |
|---|---|---|---|---|
| รหัสตำแหน่ง | `position_code` | `6a8ef9e29762533b5b7185a4` | `Text` | isTitle · required · isUnique ส่งแล้ว (true unique index ยังไม่ตั้ง) |
| ชื่อตำแหน่ง (ไทย) | `position_name_th` | `6a8ef9e29762533b5b7185a5` | `Text` | required |
| ชื่อตำแหน่ง (อังกฤษ) | `position_name_en` | `6a8ef9e29762533b5b7185a6` | `Text` | — |
| กลุ่มงาน | `job_family` | `6a8ef9e29762533b5b7185a7` | `SingleSelect` | inline options (สายงานบริหาร/ปฏิบัติการ/สนับสนุน/ขาย-การตลาด/เทคนิค-วิศวกรรม) — placeholder ยังไม่ยืนยันกับผู้ใช้ |
| ระดับตำแหน่งเริ่มต้น | `default_job_level` | `6a8ef9e29762533b5b7185a8` | `Relation` | subType 1 → `hr_job_level` `6a8ef9909762533b5b71859a` |
| รายละเอียดงาน | `job_description` | `6a8ef9e29762533b5b7185aa` | `Text` | multiLine |
| ใช้งานอยู่ | `is_active` | `6a8ef9e29762533b5b7185ab` | `Checkbox` | ✅ addFields ใช้ได้ |

**4B. ระดับพนักงาน** `hr_job_level` `6a8ef9909762533b5b71859a` ✅ (view `6a8ef9909762533b5b71859e`)

| ฟิลด์ | alias | ID | type | props |
|---|---|---|---|---|
| รหัสระดับ | `level_code` | `6a8ef9d6ae2a0e3743a0bd74` | `Text` | isTitle · required · isUnique ส่งแล้ว (true unique index ยังไม่ตั้ง) |
| ชื่อระดับ | `level_name` | `6a8ef9d6ae2a0e3743a0bd75` | `Text` | required |
| ลำดับระดับ | `level_order` | `6a8ef9d6ae2a0e3743a0bd76` | `Number` | precision 0 · required |
| เงินเดือนขั้นต่ำ | `min_salary` | `6a8ef9d6ae2a0e3743a0bd77` | `Number` | precision 2 |
| เงินเดือนขั้นสูง | `max_salary` | `6a8ef9d6ae2a0e3743a0bd78` | `Number` | precision 2 |
| เป็นระดับบริหาร | `is_management` | `6a8ef9d6ae2a0e3743a0bd79` | `Checkbox` | ✅ addFields ใช้ได้ |
| ใช้งานอยู่ | `is_active` | `6a8ef9d6ae2a0e3743a0bd7a` | `Checkbox` | ✅ addFields ใช้ได้ |
| (ระบบ) ตำแหน่งงาน | — | `6a8ef9e29762533b5b7185a9` | `Relation` | reverse field auto-created จาก `hr_position.default_job_level` (ยังไม่ตั้งชื่อ/alias ใหม่) |

✅ **Seed แล้ว 26 ส.ค. 2569** — `hr_job_level` 6 record (L1–L6: พนักงานปฏิบัติการ / เจ้าหน้าที่อาวุโส / หัวหน้างาน / ผู้จัดการ / ผู้จัดการอาวุโส / ผู้บริหารระดับสูง) · `hr_position` 8 record (POS-HR01/02, POS-ACC01/02, POS-SALE01/02, POS-OPS01, POS-MD01 ครอบคลุม HR/บัญชี/ขาย/ปฏิบัติการ/บริหาร) — ยืนยันจำนวนด้วย `get_record_pivot_data` COUNT

**DoD:** ทุกพนักงานทดสอบมีทั้ง `position` และ `job_level` · `level_order` ไม่ซ้ำ

---

### FR-HR-05 สัญญาจ้างและเหตุการณ์การจ้าง

**5A. สัญญาจ้าง** `hr_employment_contract` `6a8efd1e9762533b5b718618` ✅ สร้างจริงแล้ว 26 ส.ค. 2569

| ฟิลด์ | alias | type | props | หมายเหตุ |
|---|---|---|---|---|
| เลขที่สัญญา | `contract_no` | `Text` | isTitle · required | unique index (ID `6a8efd39353e1b0e4a50764e`) |
| พนักงาน | `employee` | `Relation` | subType 1 → `hr_employee` · required | (ID `6a8efd39353e1b0e4a50764f`) |
| ประเภทสัญญา | `contract_type` | `Dropdown` | → `OS_HR_EMPLOYMENT_TYPE` | (ID `6a8efd39353e1b0e4a507651`) |
| วันเริ่มสัญญา | `contract_from` | `Date` | subType 3 · required | (ID `6a8efd39353e1b0e4a507652`) |
| **วันสิ้นสุดสัญญา** | `contract_to` | `Date` | subType 3 | 🔴 **Date field trigger ของ WF-HR-13** (แจ้งล่วงหน้า 30 วัน) (ID `6a8efd39353e1b0e4a507653`) |
| สถานะสัญญา | `contract_status` | `Dropdown` | → `OS_HR_CONTRACT_STATUS` | default Draft (ID `6a8efd39353e1b0e4a507654`) |
| อัตราค่าจ้างตามสัญญา | `contract_salary` | `Number` | precision 2 | 🔴 ซ่อนจาก R1 R2 R3 R6 (ID `6a8efd39353e1b0e4a507655`) |
| ไฟล์สัญญา | `contract_file` | `Attachment` | subType 3 | (ID `6a8efd39353e1b0e4a507656`) |
| (ระบบ) แจ้งเตือนแล้ว | `expiry_alert_flag` | `Number` | precision 0 · **default 0** | กันแจ้งซ้ำ (ID `6a8efd39353e1b0e4a507657`) |

**Form rules:** BR-05.1 validation `contract_to` < `contract_from` → Block · BR-05.2 interaction `contract_status` = Active → ล็อก `contract_from`/`contract_to`

**5B. เหตุการณ์การจ้าง** `hr_employment_event` `6a8efd1e8b6633ef76f12ad4` ✅ สร้างจริงแล้ว 26 ส.ค. 2569
`event_no` (`6a8efd421378964f99849ae3`) Text isTitle · `employee` (`6a8efd421378964f99849ae4`) Relation→`hr_employee` required · `event_type` (`6a8efd421378964f99849ae6`) Dropdown→`OS_HR_EVENT_TYPE` · `effective_date` (`6a8efd421378964f99849ae7`) Date subType 3 required · `from_position` (`6a8efd421378964f99849ae8`)/`to_position` (`6a8efd421378964f99849aea`) Relation→`hr_position` · `from_level` (`6a8efd421378964f99849aec`)/`to_level` (`6a8efd421378964f99849aee`) Relation→`hr_job_level` · `from_cost_center` (`6a8efd421378964f99849af0`)/`to_cost_center` (`6a8efd421378964f99849af2`) Relation→`ac_cost_center` `6a85452b9b6999a714d26720` · `event_note` (`6a8efd421378964f99849af4`) Text multiLine · `approved_by` (`6a8efd421378964f99849af5`) Collaborator · `documents` (`6a8efd421378964f99849af6`) Attachment

**DoD:** ทุกการเปลี่ยนตำแหน่ง/ระดับ/หน่วยงานของพนักงานทดสอบมี record เหตุการณ์คู่กัน (พิสูจน์ NFR-HR-03)

---

### FR-HR-06 ผู้ติดตามและบัญชีธนาคาร

**6A. ผู้ติดตามและผู้ใช้สิทธิลดหย่อน** `hr_dependent` `6a8efd1eae2a0e3743a0bd93` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 — 🔴 PDPA ข้อมูลบุคคลที่สาม
`dependent_name` (`6a8efd488b6633ef76f12ade`) Text isTitle required · `employee` (`6a8efd488b6633ef76f12adf`) Relation→`hr_employee` required · `relationship` (`6a8efd488b6633ef76f12ae1`) SingleSelect (คู่สมรส/บุตร/บิดา/มารดา/อื่น ๆ) · `dependent_national_id` (`6a8efd488b6633ef76f12ae2`) Text · `dependent_birth_date` (`6a8efd488b6633ef76f12ae3`) Date subType 3 · `is_tax_allowance` (`6a8efd488b6633ef76f12ae4`) Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser) (ใช้สิทธิลดหย่อนหรือไม่) · `is_welfare_eligible` (`6a8efd488b6633ef76f12ae5`) Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser) · `study_status` (`6a8efd488b6633ef76f12ae6`) SingleSelect (ใช้สิทธิค่าเล่าเรียนบุตร) · `documents` (`6a8efd488b6633ef76f12ae7`) Attachment

**6B. บัญชีธนาคารพนักงาน** `hr_bank_account` `6a8efd1fae2a0e3743a0bd9d` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 — 🔴 PDPA
`account_name` (`6a8efd4fae2a0e3743a0bda7`) Text isTitle · `employee` (`6a8efd4fae2a0e3743a0bda8`) Relation→`hr_employee` required · `bank_name` (`6a8efd4fae2a0e3743a0bdaa`) SingleSelect · `branch_name` (`6a8efd4fae2a0e3743a0bdab`) Text · `account_no` (`6a8efd4fae2a0e3743a0bdac`) Text required (🔴 ซ่อนจาก R2 R6 · isUnique ส่งแล้วเป็น soft hint เท่านั้น ยังต้องตั้ง Index Acceleration จริงใน Browser) · `account_type` (`6a8efd4fae2a0e3743a0bdad`) SingleSelect (ออมทรัพย์/กระแสรายวัน) · `is_primary` (`6a8efd4fae2a0e3743a0bdae`) Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser) · `is_active` (`6a8efd4fae2a0e3743a0bdaf`) Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser) · `book_bank_file` (`6a8efd4fae2a0e3743a0bdb0`) Attachment

**Form rules:** IX-06.1 Unique index บน (`employee`, `account_no`)
**Pitfall:** ⚠️ ห้ามให้ `is_primary` เป็นจริงมากกว่า 1 บัญชีต่อพนักงาน — ใช้ Business Rule validation + workflow ปิดบัญชีหลักเดิมเมื่อตั้งใหม่

---

**Definition of Done (FR-HR-06):** พนักงานทดสอบทุกคนมีบัญชีธนาคารหลัก 1 บัญชี (`is_primary` = จริง) · unique index IX-06.1 ทดสอบด้วย `create_record` เลขบัญชีซ้ำแล้วถูกปฏิเสธ · Role Debugging ด้วย HR-R2 ยืนยันว่ามองไม่เห็น `account_no` และตาราง `hr_dependent` (NFR-HR-02)
**วิธี verify:** `get_worksheet_structure` ยืนยันฟิลด์ครบ · เข้าระบบด้วยบัญชีหัวหน้างานทดสอบแล้วเปิดฟอร์ม

### FR-HR-07 ประเภทการลาและนโยบายสิทธิ

**7A. ประเภทการลา** `hr_leave_type` `6a8eebf89762533b5b7184cf` ✅ สร้างจริงแล้ว 26 ส.ค. 2569

| ฟิลด์ | alias (จริง) | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อประเภทการลา | `hr_leave_type_name` | `6a8eec36353e1b0e4a5074f2` | `Text` | isTitle · required | ลาป่วย · ลากิจ · ลาพักผ่อน · ลาคลอด · ลาบวช · ลาไม่รับค่าจ้าง |
| รหัส | `hr_leave_type_code` | `6a8eec36353e1b0e4a5074f3` | `Text` | required · isUnique ส่งแล้ว (⚠️ ยังไม่ตั้ง Index Acceleration) | |
| จำนวนวันที่เริ่มบังคับให้แนบเอกสาร | `hr_document_threshold_days` | `6a8eec36353e1b0e4a5074f4` | `Number` | precision 1 · default 3 | A-HR-07 |
| ต้องยื่นล่วงหน้า (วันทำการ) | `hr_advance_notice_days` | `6a8eec36353e1b0e4a5074f5` | `Number` | precision 0 · default 0 | A-HR-06 |
| ยื่นย้อนหลังได้ (วัน) | `hr_backdate_allowed_days` | `6a8eec36353e1b0e4a5074f6` | `Number` | precision 0 · default 0 | |
| ยกยอดได้ไม่เกิน (วัน) | `hr_carry_cap_days` | `6a8eec36353e1b0e4a5074f7` | `Number` | precision 1 · default 0 | WF-HR-14 อ่านค่านี้ |
| ลำดับแสดงผล | `hr_display_order` | `6a8eec36353e1b0e4a5074f8` | `Number` | precision 0 | |
| ได้รับค่าจ้าง | `hr_is_paid` | `6a8eec80353e1b0e4a507545` | `Checkbox` | ✅ สร้างผ่าน `addFields` สำเร็จ | 🔴 ถ้าไม่ติ๊ก → WF-HR-08 นำไปหักเงิน |
| ต้องแนบเอกสาร | `hr_require_document` | `6a8eec80353e1b0e4a507546` | `Checkbox` | ✅ | |
| ลาครึ่งวันได้ | `hr_allow_half_day` | `6a8eec80353e1b0e4a507547` | `Checkbox` | ✅ | |
| นับวันหยุดรวมด้วย | `hr_count_holidays` | `6a8eec80353e1b0e4a507548` | `Checkbox` | ✅ | ลาคลอดนับวันหยุดรวม · ลาพักผ่อนไม่นับ |
| เปิดใช้งาน | `hr_leave_type_is_active` | `6a8eec80353e1b0e4a507549` | `Checkbox` | ✅ | |
| นโยบายการยกยอด | `carry_policy` | `<TBD>` | `Dropdown` | → `OS_HR_CARRY_POLICY` `52b15a75-76fc-457b-a72d-e6b7f2136243` | 🔴 **ยังไม่ได้สร้าง** — shared optionset bind ทำได้แค่ Browser เท่านั้น (ยืนยันจาก anti-drift-playbook §11 — `addFields` ให้แค่ inline options ไม่ผูก shared optionset ได้) ต้องสร้างใน Browser แล้วอ่าน ID กลับ |
| องค์ประกอบค่าจ้างที่ผูก | `pay_component` | `6a8ff2868b6633ef76f13871` | `Relation` | subType 1 → `hr_pay_component` | ✅ ตารางปลายทางสร้างแล้ว (P5-1) — ยังไม่ได้เพิ่มฟิลด์นี้บน `hr_leave_type` เอง (ค้างเพิ่มด้วย `addFields`) |

**7B. นโยบายสิทธิการลา** `hr_leave_policy` `6a8eebf88b6633ef76f129e1` ✅ สร้างจริงแล้ว 26 ส.ค. 2569

| ฟิลด์ | alias (จริง) | ID | type | props |
|---|---|---|---|---|
| ชื่อนโยบาย | `hr_policy_name` | `6a8eec5b353e1b0e4a50752a` | `Text` | isTitle · required |
| ประเภทการลา | `hr_policy_leave_type` | `6a8eec5b353e1b0e4a50752b` | `Relation` | subType 1 → `hr_leave_type` `6a8eebf89762533b5b7184cf` · required |
| อายุงานขั้นต่ำ (เดือน) | `hr_min_service_months` | `6a8eec5b353e1b0e4a50752d` | `Number` | precision 0 · required · default 0 |
| อายุงานขั้นสูงสุด (เดือน) | `hr_max_service_months` | `6a8eec5b353e1b0e4a50752e` | `Number` | precision 0 (ว่าง = ไม่จำกัด) |
| สิทธิการลา (วัน) | `hr_entitlement_days` | `6a8eec5b353e1b0e4a50752f` | `Number` | precision 1 · required |
| มีผลตั้งแต่วันที่ | `hr_policy_effective_from` | `6a8eec5b353e1b0e4a507530` | `Date` | subType 3 · required |
| เปิดใช้งาน | `hr_policy_is_active` | `6a8eec851378964f99849a0c` | `Checkbox` | ✅ สร้างผ่าน `addFields` สำเร็จ |
| ระดับตำแหน่ง | `job_level` | `6a8ef9909762533b5b71859a` | `Relation` | ✅ ตาราง `hr_job_level` มีอยู่แล้ว (P2-2) — ยังไม่ได้เพิ่มฟิลด์นี้บน `hr_leave_policy` เอง (ค้างเพิ่มด้วย `addFields`) ตอนนี้ถือว่า "ว่าง = ทุกระดับ" โดย default |

**Form rules:** BR-07.1 validation `max_service_months` < `min_service_months` → Block · IX-07.1 Unique index (`leave_type`, `job_level`, `min_service_months`, `effective_from`)
**DoD:** seed ประเภทการลาอย่างน้อย 6 ประเภทและนโยบายที่ครอบคลุมทุกระดับ · WF-HR-14 หาสิทธิได้ครบทุกพนักงานทดสอบโดยไม่มีคนตกหล่น
**Pitfall:** 🔴 ถ้ามีช่วง `min/max_service_months` ซ้อนทับกัน WF-HR-14 จะได้หลายนโยบาย ⇒ node ค้นหาต้องเรียงตาม `min_service_months` มาก→น้อย แล้วเอาแถวแรก

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — ครบ 6 ประเภทการลาตามข้อกำหนด BRD + นโยบายพื้นฐาน 1 รายการต่อประเภท (อิงขั้นต่ำตาม พ.ร.บ.คุ้มครองแรงงาน — ยังไม่ยืนยันกับผู้ใช้ ดู A-HR-05…08):

| `hr_leave_type_code` | record ID (`hr_leave_type`) | นโยบาย: `min_service_months` / `entitlement_days` |
|---|---|---|
| ANNUAL (ลาพักร้อน) | `8539e444-1040-4da5-85f1-fee8d8ea7b50` | 12 / 6 |
| SICK (ลาป่วย) | `d01ef4fa-3dd2-4e06-b885-42ed6c18c7fe` | 0 / 30 |
| PERSONAL (ลากิจ) | `88812f32-6273-4395-86a3-c5edfc2905c9` | 0 / 3 |
| MATERNITY (ลาคลอด) | `e5f5d0df-e8f8-413e-b97f-6153c83dac01` | 0 / 98 |
| ORDINATION (ลาบวช) | `6f7d058c-7e0b-432a-aa46-d6fb0525a25e` | 12 / 15 |
| UNPAID (ลาไม่รับค่าจ้าง) | `ae2d927d-207e-4ffb-b53a-2f316fef1944` | 0 / 30 |

ยืนยันจำนวนด้วย `get_record_pivot_data` COUNT: `hr_leave_type` = 6 · `hr_leave_policy` = 6 · `carry_policy`/`pay_component`/`job_level` (3 ฟิลด์ค้าง) ยังไม่ seed เพราะฟิลด์ยังไม่มี

---

### FR-HR-08 ใบลา (โมดูลที่ผู้ใช้แตะบ่อยที่สุด)
**Worksheet:** ใบลา `hr_leave_request` `6a8f2dbaae2a0e3743a0beaa` ✅ สร้างจริงแล้ว

| ฟิลด์ (ไทย) | alias | ID | **type** | subType / props | option / relation | หมายเหตุ |
|---|---|---|---|---|---|---|
| เลขที่ใบลา | `leave_no` | `<TBD>` | `Text` | — | — | isTitle · เขียนโดย workflow จากกฎการออกเลขที่ (`ac_doc_number_rule`) |
| **พนักงาน** | `employee` | `<TBD>` | `Relation` | subType 1 · dataSource `6a8efa5e9762533b5b7185c1` · required | → `hr_employee` | |
| ประเภทการลา | `leave_type` | `<TBD>` | `Relation` | subType 1 · dataSource `6a8eebf89762533b5b7184cf` · required | → `hr_leave_type` | |
| วันที่เริ่มลา | `leave_from` | `<TBD>` | `Date` | subType 3 · required | — | |
| วันที่สิ้นสุดการลา | `leave_to` | `<TBD>` | `Date` | subType 3 · required | — | |
| หน่วยการลา | `leave_unit` | `<TBD>` | `Dropdown` | — | → `OS_HR_LEAVE_UNIT` `b91afbda-b1d3-4f35-b68b-9d800acc9aff` | default Full day |
| **จำนวนวันลา** | `leave_days` | `<TBD>` | `Number` | precision 1 | — | 🔴 **เขียนโดย workflow** ด้วย node `Function calculation` (หักวันหยุดและวันหยุดประจำสัปดาห์) — **ห้ามใช้ Formula field** · read-only บนฟอร์ม |
| จำนวนชั่วโมง (กรณีลาเป็นชั่วโมง) | `leave_hours` | `<TBD>` | `Number` | precision 2 | — | |
| เหตุผลการลา | `leave_reason` | `<TBD>` | `Text` | multiLine · required | — | |
| ผู้ปฏิบัติงานแทน | `backup_person` | `<TBD>` | `Relation` | subType 1 → `hr_employee` | — | |
| เอกสารประกอบ | `attachments` | `<TBD>` | `Attachment` | subType 3 | — | 🔴 ใบรับรองแพทย์ = ข้อมูลสุขภาพ ซ่อนจาก R2 R6 |
| **สถานะใบลา** | `leave_status` | `<TBD>` | `Dropdown` | — | → `OS_HR_REQUEST_STATUS` `8ea16e5f-c099-45e2-9734-b553ea40b8d0` | 🔴 default Draft · **read-only บนฟอร์ม** · **Trigger Field ของ WF-HR-01 และ WF-HR-02/03** |
| **ผู้อนุมัติที่ระบบกำหนด** | `approver_user` | `<TBD>` | `Collaborator` | subType 0 | — | 🔴 **จำเป็นสำหรับ Approve node** — WF เขียนก่อน Initiate Approval |
| (ระบบ) ขั้นการอนุมัติปัจจุบัน | `approval_step` | `<TBD>` | `Number` | precision 0 · **default 0** | — | 1 = หัวหน้า · 2 = HR · 3 = ผู้บริหาร |
| วันที่ส่งคำขอ | `submitted_at` | `<TBD>` | `DateTime` | subType 1 | — | เขียนโดย workflow |
| วันที่อนุมัติขั้นสุดท้าย | `approved_at` | `<TBD>` | `DateTime` | subType 1 | — | เขียนโดย Approve node (Data Update tab) |
| ผู้อนุมัติขั้นที่ 1 | `approver1_user` | `<TBD>` | `Collaborator` | subType 0 | — | บันทึกไว้เพื่อ audit |
| ผู้อนุมัติขั้นที่ 2 | `approver2_user` | `<TBD>` | `Collaborator` | subType 0 | — | |
| เหตุผลที่ไม่อนุมัติ | `reject_reason` | `<TBD>` | `Text` | multiLine | — | |
| เหตุผลการยกเลิก | `cancel_reason` | `<TBD>` | `Text` | multiLine | — | |
| (ระบบ) ส่งอนุมัติแล้ว | `submitted_flag` | `<TBD>` | `Number` | precision 0 · **default 0** | — | 🔴 กันยิงซ้ำ WF-HR-01 |
| (ระบบ) ตัดสิทธิแล้ว | `deducted_flag` | `<TBD>` | `Number` | precision 0 · **default 0** | — | 🔴 กันตัดสิทธิซ้ำ WF-HR-02 |
| (ระบบ) คืนสิทธิแล้ว | `returned_flag` | `<TBD>` | `Number` | precision 0 · **default 0** | — | 🔴 กันคืนสิทธิซ้ำ WF-HR-03 |
| (ระบบ) สิทธิคงเหลือขณะยื่น | `balance_snapshot` | `<TBD>` | `Number` | precision 1 | — | เขียนโดย workflow เพื่อ audit |
| ปีสิทธิ | `leave_year` | `<TBD>` | `Number` | precision 0 | — | เขียนโดย workflow จาก `leave_from` |

> ⚠️ **field ID ของ `hr_leave_request` ในตารางข้างต้นยังเป็น `<TBD>` แม้ worksheet จะสร้างแล้ว** (`6a8f2dbaae2a0e3743a0beaa`) — ต้องรัน `get_worksheet_structure` เพื่ออ่าน field ID จริงกลับมาเติมก่อนสร้าง workflow WF-HR-01/02/03 (งานค้าง)

**Form rules (Browser):**
| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-08.1 | validation | `leave_to` < `leave_from` | Block "วันสิ้นสุดการลาต้องไม่ก่อนวันเริ่มลา" |
| BR-08.2 | validation (re-validate on server) | `leave_days` > สิทธิคงเหลือของ (`employee`, `leave_type`, `leave_year`) | Block "จำนวนวันลาเกินสิทธิคงเหลือ" — **AC-02** |
| BR-08.3 | interaction | `leave_type.require_document` = จริง และ `leave_days` ≥ `document_threshold_days` | required `attachments` |
| BR-08.4 | interaction | `leave_status` ≠ Draft | Set all fields read-only (ปุ่มและ workflow ยังเขียนได้) |
| BR-08.5 | interaction | `leave_unit` ≠ Full day | ซ่อน `leave_to` · แสดง `leave_hours` |
| DV-08.1 | Dynamic default · Query worksheet | เมื่อเลือก `employee` | เติม `approver_user` จาก `employee.supervisor_user` และเติม `balance_snapshot` |
| IX-08.1 | Unique index | (`leave_no`) | required |

> ⚠️ **การกันวันซ้อนทับ (BR-05 ของ BRD) ทำด้วย Business Rule validation ไม่ได้** เพราะต้องค้นข้ามแถว ⇒ **ทำใน WF-HR-01 node แรก**: `Query worksheet` หาใบลาของพนักงานคนเดียวกันที่ `leave_status` in (Pending supervisor, Pending HR, Approved) และช่วงวันซ้อนทับ → ถ้าพบ → Update Record คืนเป็น Draft + เขียน `reject_reason` + Send Notification + จบ flow

**Verify form rules:** Role Debugging → HR-R1 → สร้างใบลาเกินสิทธิ → ต้องถูกบล็อกพร้อมข้อความ

**State machine (`leave_status`) — ทุก transition ระบุผู้ขับ:**
| จาก | ไป | **ขับด้วย** | เงื่อนไข / ผู้มีสิทธิ์ |
|---|---|---|---|
| — | Draft | สร้าง record | R1 (ตนเอง) · R3 (แทนพนักงาน) |
| Draft | Pending supervisor | **ปุ่ม "ส่งคำขอ"** (`<TBD-CA-01>`) → WF-HR-01 รับช่วง | R1 · กฎฟอร์มต้องผ่านทั้งหมด |
| Pending supervisor | Pending HR | **Approve node Data Update** ใน WF-HR-01 (สายที่ 1) | หัวหน้างานกดใน To-do |
| Pending supervisor | Rejected | **Approve node Data Update (when rejects)** | หัวหน้างาน |
| Pending HR | Approved | **Approve node Data Update** ใน WF-HR-01 (สายที่ 2) | HR กดใน To-do |
| Pending HR | Rejected | **Approve node Data Update (when rejects)** | HR |
| Approved | Cancelled | **ปุ่ม "ยกเลิกใบลา"** (`<TBD-CA-02>`) → WF-HR-03 คืนสิทธิ | R1 (ก่อนวันลา) · R3 R4 (ทุกกรณี) |
| Draft / Pending * | Cancelled | ปุ่ม "ยกเลิกใบลา" | R1 R3 |

> 🔴 `leave_status` **ต้อง read-only บนฟอร์ม** — ทุก transition ขับด้วยปุ่มหรือ workflow ทั้งหมด

**Custom Actions ที่ผูก:** `<TBD-CA-01>` ส่งคำขอ · `<TBD-CA-02>` ยกเลิกใบลา (§1.9)
**Workflow ที่ผูก:** WF-HR-01 (อนุมัติ) · WF-HR-02 (ตัดสิทธิ) · WF-HR-03 (คืนสิทธิ) · WF-HR-05 (เชื่อมกับบันทึกลงเวลา) · WF-HR-06 (เตือน SLA)
**Definition of Done:** AC-01 AC-02 AC-03 ผ่านครบ · `get_record_logs` แสดง `user-self` (กดปุ่ม) ตามด้วย `user-workflow` (WF เขียน) · `get_approval_list_by_row` มี instance ทั้ง 2 ขั้น
**Pitfall:** 🔴 อย่าใส่ `filter` ใน trigger ของ WF-HR-01 — ใช้ `triggerFields = [leave_status]` แล้วเช็กเงื่อนไขใน branch node แรก

---

### FR-HR-09 สิทธิและยอดคงเหลือการลา

**9A. สิทธิและยอดคงเหลือ** `hr_leave_balance` `6a8f2dba353e1b0e4a507757` ✅ สร้างจริงแล้ว — 1 record ต่อ (พนักงาน × ประเภทการลา × ปีสิทธิ)

| ฟิลด์ | alias | type | props | หมายเหตุ |
|---|---|---|---|---|
| ชื่อรายการ | `balance_name` | `Text` | isTitle | เขียนโดย workflow "รหัสพนักงาน–ประเภท–ปี" |
| พนักงาน | `employee` | `Relation` | subType 1 → `hr_employee` · required | |
| ประเภทการลา | `leave_type` | `Relation` | subType 1 → `hr_leave_type` · required | |
| ปีสิทธิ | `leave_year` | `Number` | precision 0 · required | |
| สิทธิที่ได้รับปีนี้ | `entitled_days` | `Number` | precision 1 · default 0 | เขียนโดย WF-HR-14 |
| ยอดยกมาจากปีก่อน | `carried_days` | `Number` | precision 1 · default 0 | เขียนโดย WF-HR-14 |
| **สิทธิรวม** | `total_days` | `Number` | precision 1 · default 0 | 🔴 เขียนโดย workflow (`Numerical operations`) — ห้าม Formula |
| ใช้ไปแล้ว | `used_days` | `Number` | precision 1 · default 0 | เขียนโดย WF-HR-02 / WF-HR-03 |
| **คงเหลือ** | `remaining_days` | `Number` | precision 1 · default 0 | 🔴 เขียนโดย workflow · BR-08.2 อ่านค่านี้ |
| ปรับปรุงด้วยมือ | `adjustment_days` | `Number` | precision 1 · default 0 | ต้องมี record ใน ledger คู่กันเสมอ |
| หมายเหตุ | `balance_note` | `Text` | multiLine | |

**Form rules:** BR-09.1 interaction — Set all read-only สำหรับทุก role ยกเว้น R3 R4 (แก้ได้เฉพาะ `adjustment_days`) · IX-09.1 Unique index (`employee`, `leave_type`, `leave_year`) — 🔴 ทั้ง 3 ฟิลด์ต้อง required

> ⚠️ **field ID ของ `hr_leave_balance` ในตารางข้างต้นยังเป็นชื่อ alias จากสเปกเดิม** — ต้องรัน `get_worksheet_structure(6a8f2dba353e1b0e4a507757)` เพื่ออ่าน field ID จริงกลับมาเติมก่อนสร้าง workflow (งานค้าง)

**9B. รายการเคลื่อนไหวสิทธิลา** `hr_leave_ledger` `6a8f2dba9762533b5b718675` ✅ สร้างจริงแล้ว — **append-only · ห้ามแก้ ห้ามลบ**

| ฟิลด์ | alias | type | props | หมายเหตุ |
|---|---|---|---|---|
| เลขที่รายการ | `ledger_no` | `AutoNumber` | 🔴 **Browser** | ⚠️ หลัง save ให้สร้าง record ทดสอบดูเลขจริง (ลำดับกฎอาจสลับ) |
| ยอดคงเหลือที่อ้างถึง | `balance` | `Relation` | subType 1 → `hr_leave_balance` · required | |
| พนักงาน | `employee` | `Relation` | subType 1 → `hr_employee` · required | ซ้ำไว้เพื่อกรองง่าย |
| ประเภทรายการ | `ledger_type` | `Dropdown` | → `OS_HR_LEDGER_TYPE` `5b546b65-5050-4e7b-a02e-34fb55388a4b` | |
| จำนวนวัน (+ เพิ่ม / − ลด) | `ledger_days` | `Number` | precision 1 · required | |
| ใบลาที่อ้างถึง | `leave_request` | `Relation` | subType 1 → `hr_leave_request` | ว่างได้กรณีให้สิทธิต้นปี |
| วันที่มีผล | `effective_date` | `Date` | subType 3 · required | |
| ยอดคงเหลือหลังรายการนี้ | `balance_after` | `Number` | precision 1 | เขียนโดย workflow |
| คำอธิบาย | `ledger_note` | `Text` | multiLine | |

**Form rules:** BR-09.2 interaction — เมื่อ record ถูกสร้างแล้ว Set all fields read-only ทุก role (append-only)
**DoD:** ทุกครั้งที่ `hr_leave_balance.used_days` เปลี่ยน ต้องมี record ledger คู่กัน 1 แถวเสมอ (พิสูจน์ด้วยการนับ)
**Pitfall:** ⚠️ `AutoNumber` สร้างผ่าน API ไม่ได้ → สร้างใน Browser แล้ว `get_worksheet_structure` อ่าน ID กลับมาเติม

---

### FR-HR-10 บันทึกลงเวลา
**Worksheet:** บันทึกลงเวลา `hr_attendance` `<TBD-WS-18>` — 1 record ต่อ (พนักงาน × วันที่)

| ฟิลด์ | alias | type | props | หมายเหตุ |
|---|---|---|---|---|
| ชื่อรายการ | `att_name` | `Text` | isTitle | "รหัสพนักงาน–YYYY-MM-DD" เขียนโดย workflow |
| พนักงาน | `employee` | `Relation` | subType 1 → `hr_employee` · required | |
| **วันที่ทำงาน** | `work_date` | `Date` | subType 3 · required | |
| กะที่ใช้ | `shift` | `Relation` | subType 1 → `hr_shift` | เติมจากทะเบียนพนักงาน |
| เวลาเข้า | `check_in` | `DateTime` | subType 1 | 🔴 เขียนผ่าน API ต้องระบุ `+07:00` |
| เวลาออก | `check_out` | `DateTime` | subType 1 | |
| **สถานะรายวัน** | `att_status` | `Dropdown` | → `OS_HR_ATT_STATUS` `da2f6870-acda-4ef2-a70e-e641193f76a5` | 🔴 เขียนโดย WF-HR-05 · read-only |
| ที่มาของข้อมูล | `att_source` | `Dropdown` | → `OS_HR_ATT_SOURCE` `23176ae6-97b8-45b8-87c3-43f911ea053c` | |
| นาทีที่สาย | `late_minutes` | `Number` | precision 0 · default 0 | เขียนโดย WF-HR-05 (node `Duration`) |
| นาทีที่ออกก่อนเวลา | `early_leave_minutes` | `Number` | precision 0 · default 0 | |
| ชั่วโมงทำงานจริง | `worked_hours` | `Number` | precision 2 · default 0 | 🔴 node `Duration` — ไม่มีปัญหา timezone เพราะลบเวลาสองค่าในระบบเดียวกัน |
| ใบลาที่ครอบวันนี้ | `leave_request` | `Relation` | subType 1 → `hr_leave_request` | เขียนโดย WF-HR-05 |
| ใบขอ OT ที่ครอบวันนี้ | `ot_request` | `Relation` | subType 1 → `hr_ot_request` | |
| เป็นวันหยุด | `is_holiday` | `Checkbox` | ✅addFields (ไม่ต้อง Browser — แก้ 26 ส.ค. 2569) | เขียนโดย WF-HR-05 |
| หมายเหตุ | `att_note` | `Text` | multiLine | |
| (ระบบ) สรุปแล้ว | `summarised_flag` | `Number` | precision 0 · **default 0** | กัน WF-HR-05 ทำซ้ำ |

**Form rules:** IX-10.1 **Unique index (`employee`, `work_date`)** — 🔴 ทั้งสองฟิลด์ต้อง required · ล้าง recycle bin ก่อนสร้าง index · **Test: `create_record` ซ้ำต้องถูกปฏิเสธ (AC-15)**
BR-10.1 interaction `att_status` = On leave → ซ่อน `late_minutes` · BR-10.2 interaction — Set read-only สำหรับ R1 R2 (แก้ได้เฉพาะ R3 R4)

**DoD:** AC-04 ผ่าน — วันที่มีใบลาอนุมัติแล้วต้องแสดง On leave ไม่ใช่ Absent · unique index ทำงานแม้เรียกผ่าน API
**Pitfall:** 🔴 การนำเข้าไฟล์เวลาจำนวนมากต้องใช้ `batch_create_records` + `triggerWorkflow:false` แล้วค่อยให้ WF-HR-05 สรุปตามรอบ ไม่งั้น workflow จะยิงรัว

---

### FR-HR-11 ใบขออนุมัติล่วงเวลา

**11A. อัตราค่าล่วงเวลา** `hr_ot_rate` `6a8eebf88b6633ef76f129d6` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 (บางฟิลด์ยังไม่ครบ ดูด้านล่าง)
`hr_rate_name` (`6a8eec39ae2a0e3743a0bcfa`) Text isTitle required · `hr_multiplier` (`6a8eec39ae2a0e3743a0bcfb`) Number precision 2 required (1.5 / 1.0 / 3.0 ตาม A-HR-09) · `hr_effective_from` (`6a8eec39ae2a0e3743a0bcfc`) Date subType 3 required · `hr_ot_rate_is_active` (`6a8eec818b6633ef76f12a5e`) Checkbox ✅
🔴 **ยังไม่ได้สร้าง:** `day_type` Dropdown→`OS_HR_OT_DAY_TYPE` `b433253c-70e2-4f15-8392-56b875f1cd76` · `employment_type` Dropdown→`OS_HR_EMPLOYMENT_TYPE` `65390c18-4ecb-4243-9098-12e6b91730e5` — ทั้งสองผูก shared optionset ได้แค่ผ่าน Browser (ดูหมายเหตุ 7A) ต้องเพิ่มก่อนใช้งาน WF-HR-08 จริง
> 🔴 **ห้าม hard-code ตัวคูณใน workflow** — WF-HR-08 ต้องอ่านจากตารางนี้ (BR-14 · AC-19)

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — 3 อัตราตาม A-HR-09 (ยังไม่มี `day_type`/`employment_type` ให้ระบุ เพราะฟิลด์ยังไม่มี — WF-HR-08 จะ query ไม่ตรงจนกว่าจะเพิ่มฟิลด์ 2 ตัวนี้ใน Browser แล้ว seed ใหม่):

| record ID | ชื่ออัตรา | ตัวคูณ |
|---|---|---|
| `1fcde6d1-f3b9-4b80-9f38-593cae8b9143` | OT วันทำงาน | 1.5 |
| `f72c4e62-e111-471b-97dc-f01aaf613263` | OT วันหยุดในเวลางาน | 1.0 |
| `5278d9ca-2ecd-4f36-807e-70d01f5e4c58` | OT วันหยุดนอกเวลางาน | 3.0 |

ยืนยันจำนวนด้วย `get_record_pivot_data` COUNT = 3

**11B. ใบขออนุมัติล่วงเวลา** `hr_ot_request` `<TBD-WS-19>`

| ฟิลด์ | alias | type | props | หมายเหตุ |
|---|---|---|---|---|
| เลขที่ใบขอ OT | `ot_no` | `Text` | isTitle | เขียนโดย workflow |
| พนักงาน | `employee` | `Relation` | subType 1 → `hr_employee` · required | |
| วันที่ทำงานล่วงเวลา | `ot_date` | `Date` | subType 3 · required | |
| เวลาเริ่ม / สิ้นสุด | `ot_from` / `ot_to` | `DateTime` | subType 1 · required | 🔴 API ต้องระบุ `+07:00` |
| ประเภทวัน | `day_type` | `Dropdown` | → `OS_HR_OT_DAY_TYPE` | เขียนโดย workflow จากปฏิทินวันหยุด |
| **จำนวนชั่วโมง** | `ot_hours` | `Number` | precision 2 | 🔴 node `Duration` · read-only |
| ตัวคูณที่ใช้ | `applied_multiplier` | `Number` | precision 2 | เขียนโดย workflow จาก `hr_ot_rate` |
| เหตุผล / งานที่ทำ | `ot_reason` | `Text` | multiLine · required | |
| **สถานะ** | `ot_status` | `Dropdown` | → `OS_HR_REQUEST_STATUS` `8ea16e5f-c099-45e2-9734-b553ea40b8d0` | default Draft · read-only · Trigger Field ของ WF-HR-04 |
| ผู้อนุมัติที่ระบบกำหนด | `approver_user` | `Collaborator` | subType 0 | 🔴 สำหรับ Approve node |
| (ระบบ) ขั้นการอนุมัติ | `approval_step` | `Number` | precision 0 · default 0 | |
| วันที่อนุมัติ | `approved_at` | `DateTime` | subType 1 | Data Update tab |
| เหตุผลที่ไม่อนุมัติ | `reject_reason` | `Text` | multiLine | |
| (ระบบ) ส่งอนุมัติแล้ว | `ot_submitted_flag` | `Number` | precision 0 · **default 0** | |
| (ระบบ) นำไปคิดค่าจ้างแล้ว | `paid_flag` | `Number` | precision 0 · **default 0** | 🔴 กัน WF-HR-08 คิดซ้ำข้ามงวด |
| งวดจ่ายที่นำไปคิด | `pay_period` | `Relation` | subType 1 → `hr_pay_period` `6a8ff2878b6633ef76f1387b` | เขียนโดย WF-HR-08 |

**Form rules:** BR-11.1 validation `ot_to` ≤ `ot_from` → Block · BR-11.2 validation `ot_hours` > 4 และ `day_type` = Working day → Warning (เตือนเพดานชั่วโมงตามกฎหมาย) · BR-11.3 interaction `ot_status` ≠ Draft → read-only ทั้งฟอร์ม · IX-11.1 Unique index (`employee`, `ot_date`, `ot_from`)

**State machine:** เหมือนใบลา (Draft → Pending supervisor → Pending HR → Approved / Rejected / Cancelled) ขับด้วยปุ่ม `<TBD-CA-03>` + WF-HR-04
**DoD:** **AC-05** — OT ที่ `ot_status` ≠ Approved ต้องไม่ปรากฏในสลิป (พิสูจน์ด้วยการสร้าง OT 2 ใบ อนุมัติ 1 ใบ แล้วคำนวณสลิป)

---

### FR-HR-12 ถึง FR-HR-17 · กลุ่มเงินเดือน

**12A. งวดจ่ายเงินเดือน** `hr_pay_period` `6a8ff2878b6633ef76f1387b` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-1) · Data Name ไทย = "งวดจ่ายเงินเดือน" (✅ แก้จริงแล้ว 27 ส.ค. 2569 — เดิมค้างเป็น `hr_pay_period` ในเมนู ทั้งที่เอกสารเคยระบุว่าแก้แล้ว ดู Known Issues) · view `6a8ff2878b6633ef76f1387f` ✅ rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI `worksheet view update`)

| ฟิลด์ (ไทย) | alias | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่องวด | `biz_period_name` | `6a8ff311ae2a0e3743a0cca9` | `Text` | isTitle · required | "เงินเดือน สิงหาคม 2569" |
| ปี | `biz_period_year` | `6a8ff311ae2a0e3743a0ccaa` | `Number` | precision 0 · required | |
| เดือน | `biz_period_month` | `6a8ff311ae2a0e3743a0ccab` | `Number` | precision 0 · required | |
| วันที่เริ่มงวด | `biz_period_from` | `6a8ff311ae2a0e3743a0ccac` | `Date` | subType 3 · required | |
| วันที่สิ้นงวด | `biz_period_to` | `6a8ff311ae2a0e3743a0ccad` | `Date` | subType 3 · required | |
| วันตัดรอบเวลา | `biz_cutoff_date` | `6a8ff311ae2a0e3743a0ccae` | `Date` | subType 3 · required | |
| วันจ่ายเงิน | `biz_pay_date` | `6a8ff311ae2a0e3743a0ccaf` | `Date` | subType 3 · required | |
| **งวดบัญชีที่ผูก** | `biz_ac_period_ref` | `6a8ff311ae2a0e3743a0ccb0` | `Relation` | subType 1 · dataSource `6a8434d5055f2288c5b6d4b8` | → `ac_period` ✅ ตารางเดิม — ผูกสำเร็จ |
| **สถานะงวด** | `biz_period_status` | `6a8ff311ae2a0e3743a0ccb2` | `Dropdown` | isReadOnly · default Open | inline options: Open`f10e686c-9381-4a5a-9406-bead7012bf51` · Calculating`d4c51a3a-2c41-4959-bd97-cac24ae9db48` · Pending approval`4b772a20-1b19-4f49-b635-f4b809e97b1b` · Approved`3c7aa8cd-6a7c-446a-9d9e-b123dbc1cbd9` · Posted`a40f98e5-d1a8-408c-a0a5-03c4eeafe5e8` · Closed`c227fad9-0a9f-4869-90e6-b1b2a15db991` · Cancelled`30fb7cad-9653-4ce3-a230-6a8b57bd9725` — ⚠️ **inline ไม่ได้ผูก** `OS_HR_PAY_PERIOD_STATUS` `59c18869-…` (ต้องลบสร้างใหม่ผ่าน Browser) · **Trigger Field ของ WF-HR-07 / 09 / 10** |
| จำนวนพนักงานในงวด | `biz_headcount` | `6a8ff311ae2a0e3743a0ccb3` | `Number` | precision 0 · default 0 | เขียนโดย WF-HR-07 |
| รวมรายได้ | `biz_total_earning` | `6a8ff311ae2a0e3743a0ccb4` | `Number` | precision 2 · default 0 | 🔴 เขียนโดย workflow |
| รวมรายหัก | `biz_total_deduction` | `6a8ff311ae2a0e3743a0ccb5` | `Number` | precision 2 · default 0 | 🔴 เขียนโดย workflow |
| รวมสุทธิ | `biz_total_net` | `6a8ff311ae2a0e3743a0ccb6` | `Number` | precision 2 · default 0 | 🔴 เขียนโดย workflow — **ห้ามใช้ Rollup ถ้าต้องกรองตามสถานะสลิป** |
| รวมประกันสังคมพนักงาน | `biz_total_sso_ee` | `6a8ff311ae2a0e3743a0ccb7` | `Number` | precision 2 · default 0 | |
| รวมประกันสังคมนายจ้าง | `biz_total_sso_er` | `6a8ff311ae2a0e3743a0ccb8` | `Number` | precision 2 · default 0 | |
| รวมภาษีหัก ณ ที่จ่าย | `biz_total_wht` | `6a8ff311ae2a0e3743a0ccb9` | `Number` | precision 2 · default 0 | |
| **ใบสำคัญที่สร้าง** | `biz_voucher_ref` | `6a8ff311ae2a0e3743a0ccba` | `Relation` | subType 1 · dataSource `6a85fb2e9b6999a714d2a53d` | → `ac_voucher` ✅ · เขียนโดย WF-HR-10 — ผูกสำเร็จ |
| ผู้อนุมัติที่ระบบกำหนด | `biz_approver_user` | `6a8ff311ae2a0e3743a0ccbc` | `Collaborator` | subType 0 | สำหรับ Approve node |
| วันที่อนุมัติ | `biz_approved_at` | `6a8ff311ae2a0e3743a0ccbd` | `DateTime` | subType 1 | |
| (ระบบ) สร้างสลิปแล้ว | `biz_generated_flag` | `6a8ff311ae2a0e3743a0ccbe` | `Number` | precision 0 · **default 0** | กัน WF-HR-07 ทำซ้ำ |
| (ระบบ) ส่งอนุมัติแล้ว | `biz_pp_submitted_flag` | `6a8ff311ae2a0e3743a0ccbf` | `Number` | precision 0 · **default 0** | |
| **(ระบบ) ผ่านรายการแล้ว** | `biz_post_flag` | `6a8ff311ae2a0e3743a0ccc0` | `Number` | precision 0 · **default 0** | 🔴 **AC-08** กันสร้างใบสำคัญซ้ำ |

**Form rules:** IX-12.1 Unique index (`period_year`, `period_month`) — ⚠️ ยังไม่ได้ตั้ง Index Acceleration จริง · BR-12.1 interaction `period_status` in (Posted, Closed) → Set all read-only · BR-12.2 validation `period_to` < `period_from` → Block

**12B. องค์ประกอบค่าจ้าง** `hr_pay_component` `6a8ff2868b6633ef76f13871` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-1) · Data Name ไทย = "องค์ประกอบค่าจ้าง" (✅ แก้จริงแล้ว 27 ส.ค. 2569 — เดิมค้างเป็น `hr_pay_component` ในเมนู ดู Known Issues) · view `6a8ff2868b6633ef76f13875` ✅ rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI `worksheet view update`)

| ฟิลด์ (ไทย) | alias | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อองค์ประกอบ | `biz_component_name` | `6a8ff3049762533b5b71939c` | `Text` | isTitle · required | เงินเดือน · ค่าล่วงเวลา · เงินสมทบประกันสังคม · ภาษีหัก ณ ที่จ่าย · หักขาดงาน |
| รหัส | `biz_component_code` | `6a8ff3049762533b5b71939d` | `Text` | required · isUnique ส่งแล้ว | ⚠️ true unique index ยังไม่ตั้ง |
| ประเภท | `biz_component_type` | `6a8ff3049762533b5b71939e` | `Dropdown` | required | inline options: Earning`3d7c0516-9963-401f-94d5-af77b411ddb0` · Deduction`b2f76390-5726-49d6-b9c1-2df381b605e8` · Employer contribution`c0fa8294-f4f1-43dc-8033-71560716d14a` · Informational`a50efeb5-a2e7-41f9-9184-7b121f6918ba` — ⚠️ **inline ไม่ได้ผูก** `OS_HR_COMPONENT_TYPE` `01087816-…` |
| วิธีคำนวณ | `biz_calc_method` | `6a8ff3049762533b5b71939f` | `Dropdown` | required | inline options: Fixed amount`724201e8-803e-4893-92be-7150e37f7914` · Rate per hour`725f50b1-117d-4f1a-b351-5e5edfdc8070` · Percentage of base`fa64c691-f09e-4fa2-920b-9d507055d374` · From attendance`51c68d98-3919-41c1-9e28-031a69a34d2a` · From OT request`c34616c5-4b86-442c-84db-af854545ce51` · Statutory formula`8fbf312d-9b87-4369-adb7-387591166d37` · Manual entry`09e72e45-c496-498e-b189-640a6be1fc2c` — ⚠️ **inline ไม่ได้ผูก** `OS_HR_COMPONENT_CALC` `dabc60c9-…` |
| จำนวนเงินคงที่ | `biz_fixed_amount` | `6a8ff3049762533b5b7193a0` | `Number` | precision 2 | ใช้เมื่อ calc = Fixed amount |
| อัตราร้อยละ | `biz_percentage` | `6a8ff3049762533b5b7193a1` | `Number` | precision 4 | ใช้เมื่อ calc = Percentage of base |
| **ผังบัญชีที่ผูก** | `biz_coa_account` | `6a8ff3049762533b5b7193a2` | `Relation` | subType 1 · dataSource `6a85516e1049edca1eecd9b7` | → `ac_coa` ✅ **ผูกสำเร็จครบ 6/6 record (P5-4 ปิดเต็ม 28 ส.ค. 2569 ต่อเนื่อง 6)** — ✅ **source of truth ยืนยันแล้วโดยฝ่ายบัญชี:** WF-HR-10 อ่านรหัสบัญชีหลักจาก `ac_posting_rule` (event-based mapping) — ฟิลด์นี้เป็น **fallback** เมื่อไม่พบกฎที่ตรงเงื่อนไขเท่านั้น (ตรงกับที่ HR เสนอไว้ในเอกสาร handoff) ไม่ใช่ตรงกันข้าม |
| นำไปคิดฐานภาษี | `biz_is_taxable` | `6a8ff3049762533b5b7193a5` | `Checkbox` | ✅ สร้างผ่าน `addFields` สำเร็จ | |
| นำไปคิดฐานประกันสังคม | `biz_is_sso_base` | `6a8ff3049762533b5b7193a6` | `Checkbox` | ✅ สร้างผ่าน `addFields` สำเร็จ | |
| ลำดับแสดงบนสลิป | `biz_display_order` | `6a8ff3049762533b5b7193a4` | `Number` | precision 0 | |
| เปิดใช้งาน | `biz_is_active` | `6a8ff3049762533b5b7193a7` | `Checkbox` | ✅ default true | |
| (ระบบ) reverse relation จาก `hr_salary_structure.pay_component` | — | `6a8ff3149762533b5b7193cb` | `Relation` | auto-created (bidirectional) | ไม่ต้องแตะ |

**Seed data (P5-4, 28 ส.ค. 2569 — ปิดครบ 6/6 ต่อเนื่อง 6):** ✅ seed ครบ 6 record ผ่าน `batch_create_records`(`triggerWorkflow:false`) — `SALARY`(`4f6e08db-9316-4d22-88ac-a3656c29a182`) · `OT`(`485f15df-1467-4af6-b072-43c027237e7a`) · `SSO_ER`(`68d66b6b-cfcb-404b-a7c6-35d324c7ca7d`) · `SSO_EE`(`b8e92933-ba55-488b-b6fa-bd2e0c0044f7`) · `WHT`(`ad802ca3-fcb4-4aba-909c-a6f2ae786835`) · `ABSENCE_DEDUCT`(`63ed6dd9-9d2b-435f-a823-28935b0dff8a`) — verify ด้วย `get_record_list`/`get_record_details` ผ่านครบทุกฟิลด์ · `biz_coa_account` ผูกกับ `ac_coa` ครบ **6/6**: `SALARY`/`OT`/`ABSENCE_DEDUCT`→`530101 เงินเดือน`(rowId `43ee2889-b2e5-4620-85b7-53f6db1c8e5b`, 26-27 ส.ค.) · **28 ส.ค. 2569 (ต่อเนื่อง 6) — ฝ่ายบัญชีสร้างบัญชีใหม่ 3 รายการให้แล้ว ผูกต่อสำเร็จ:** `SSO_ER`→`530102`(rowId `233626b4-d272-4cb5-8f77-9d8d2ddef804`) · `SSO_EE`→`210402`(rowId `c6386fe7-1b3c-44db-ab80-9dfd3308a6a5`) · `WHT`→`210304`(rowId `777ea001-5300-4f5c-857a-71a45db2076b`, ภ.ง.ด.1 โดยเฉพาะ แยกจากบัญชี WHT เดิมที่เป็น ภ.ง.ด.3/53/54) — ✅ **AC-P5-4 ("ทุก component มี `coa_account`") ผ่านเต็ม 100% แล้ว**

**12C. โครงสร้างเงินเดือน** `hr_salary_structure` `6a8ff287353e1b0e4a508550` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-1) · Data Name ไทย = "โครงสร้างเงินเดือน" (✅ แก้จริงแล้ว 27 ส.ค. 2569 — เดิมค้างเป็น `hr_salary_structure` ในเมนู ดู Known Issues) · view `6a8ff287353e1b0e4a508554` ✅ rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI `worksheet view update`) — 🔴 **ข้อมูลลับสูงสุด** เห็นได้เฉพาะ R4 R5 R7

| ฟิลด์ (ไทย) | alias | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อโครงสร้าง | `biz_structure_name` | `6a8ff3149762533b5b7193c7` | `Text` | isTitle · required | |
| พนักงาน | `biz_employee` | `6a8ff3149762533b5b7193c8` | `Relation` | subType 1 · dataSource `6a8efa5e9762533b5b7185c1` · required | → `hr_employee` ✅ ผูกสำเร็จ |
| องค์ประกอบค่าจ้าง | `biz_pay_component` | `6a8ff3149762533b5b7193ca` | `Relation` | subType 1 · dataSource `6a8ff2868b6633ef76f13871` · required | → `hr_pay_component` ✅ ผูกสำเร็จ |
| จำนวนเงิน | `biz_amount` | `6a8ff3149762533b5b7193cc` | `Number` | precision 2 · required | |
| มีผลตั้งแต่ | `biz_effective_from` | `6a8ff3149762533b5b7193cd` | `Date` | subType 3 · required | |
| มีผลถึง | `biz_effective_to` | `6a8ff3149762533b5b7193ce` | `Date` | subType 3 | ว่าง = ยังมีผล |
| เหตุผลการเปลี่ยนแปลง | `biz_change_reason` | `6a8ff3149762533b5b7193cf` | `Text` | multiLine | |
| ผู้อนุมัติ | `biz_approved_by` | `6a8ff3149762533b5b7193d0` | `Collaborator` | subType 0 | |
| เปิดใช้งาน | `biz_is_active` | `6a8ff3149762533b5b7193d1` | `Checkbox` | ✅ default true | |

**Form rules:** IX-12.2 Unique index (`employee`, `pay_component`, `effective_from`) · BR-12.3 interaction — record ที่ `effective_to` มีค่าแล้ว → Set all read-only (ประวัติห้ามแก้ · NFR-HR-03)
**DoD:** **AC-18** — เปิด Application Logs หรือ record log แล้วเห็นผู้แก้ เวลา และค่าก่อน-หลังของทุกการเปลี่ยนอัตรา

**12D. สลิปเงินเดือน** `hr_payslip` `6a904c85353e1b0e4a50ba05` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-2) ครบทุกฟิลด์ · Data Name ไทย ถูกต้องตั้งแต่สร้าง (ระบุชื่อไทยตรงใน `create_app_items`) — ✅ view `6a904c85353e1b0e4a50ba09` rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI)

| ฟิลด์ | alias | field ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| เลขที่สลิป | `biz_payslip_no` | `6a904d67353e1b0e4a50ba0f` | `AutoNumber` | isTitle · rule "PS-" + yyyyMM + sequence(4, reset monthly) | เขียนอัตโนมัติตอนสร้าง record — ไม่ใช่ Text ตามสเปกเดิม (AutoNumber เหมาะกว่าและรองรับ isTitle) |
| **พนักงาน** | `biz_employee` | `6a904d67353e1b0e4a50ba10` | `Relation` | subType 1 → `hr_employee` `6a8efa5e9762533b5b7185c1` · required · bidirectional (reverse field `6a904d67353e1b0e4a50ba11`) | |
| **งวดจ่าย** | `biz_pay_period` | `6a904d67353e1b0e4a50ba12` | `Relation` | subType 1 → `hr_pay_period` `6a8ff2878b6633ef76f1387b` · required · bidirectional (reverse `6a904d67353e1b0e4a50ba13`) | |
| หน่วยงาน (ณ วันจ่าย) | `biz_cost_center` | `6a904d67353e1b0e4a50ba14` | `Relation` | subType 1 → `ac_cost_center` `6a85452b9b6999a714d26720` · bidirectional (reverse `6a904d67353e1b0e4a50ba15`) | 🔴 ยังไม่ได้ตั้ง Dynamic default → Other field value (snapshot) — ค้างเป็น gap ของ WF-HR-07 |
| ค่าจ้างพื้นฐานของงวด | `biz_base_salary` | `6a904d67353e1b0e4a50ba16` | `Currency` (THB) | precision 2 · default 0 | จาก `hr_salary_structure` ที่มีผล ณ วันจ่าย — สร้างเป็น Currency แทน Number ตามสเปกเดิม (แสดงหน่วยเงินชัดเจนกว่า) |
| วันทำงานจริง | `biz_worked_days` | `6a904d67353e1b0e4a50ba17` | `Number` | precision 2 · default 0 | จาก `hr_attendance` |
| วันขาดงาน | `biz_absent_days` | `6a904d67353e1b0e4a50ba18` | `Number` | precision 2 · default 0 | จาก `hr_attendance` |
| วันลาไม่รับค่าจ้าง | `biz_unpaid_leave_days` | `6a904d67353e1b0e4a50ba19` | `Number` | precision 2 · default 0 | จาก `hr_leave_request` |
| ชั่วโมง OT x1.5 | `biz_ot_hours_15` | `6a904d67353e1b0e4a50ba1a` | `Number` | precision 2 · default 0 | จาก `hr_ot_request` ที่อนุมัติแล้วเท่านั้น |
| ชั่วโมง OT x1.0 | `biz_ot_hours_10` | `6a904d67353e1b0e4a50ba1b` | `Number` | precision 2 · default 0 | |
| ชั่วโมง OT x3.0 | `biz_ot_hours_30` | `6a904d67353e1b0e4a50ba1c` | `Number` | precision 2 · default 0 | |
| **รวมรายได้** | `biz_total_earning` | `6a904d67353e1b0e4a50ba1d` | `Currency` (THB) | precision 2 · default 0 | 🔴 เขียนโดย WF-HR-08 (`Function calculation` SUM) |
| **รวมรายหัก** | `biz_total_deduction` | `6a904d67353e1b0e4a50ba1e` | `Currency` (THB) | precision 2 · default 0 | 🔴 เขียนโดย WF-HR-08 |
| **เงินได้สุทธิ** | `biz_net_pay` | `6a904d67353e1b0e4a50ba1f` | `Currency` (THB) | precision 2 · default 0 | 🔴 เขียนโดย WF-HR-08 (`Numerical operations`) |
| ประกันสังคม (ลูกจ้าง) | `biz_sso_ee` | `6a904d67353e1b0e4a50ba20` | `Currency` (THB) | precision 2 · default 0 | |
| ประกันสังคม (นายจ้าง) | `biz_sso_er` | `6a904d67353e1b0e4a50ba21` | `Currency` (THB) | precision 2 · default 0 | |
| ภาษีหัก ณ ที่จ่าย | `biz_wht_amount` | `6a904d67353e1b0e4a50ba22` | `Currency` (THB) | precision 2 · default 0 | |
| รายได้สะสมทั้งปี | `biz_ytd_income` | `6a904d67353e1b0e4a50ba23` | `Currency` (THB) | precision 2 · default 0 | ใช้ออก 50 ทวิ |
| ภาษีหักสะสมทั้งปี | `biz_ytd_wht` | `6a904d67353e1b0e4a50ba24` | `Currency` (THB) | precision 2 · default 0 | ใช้ออก 50 ทวิ |
| บัญชีธนาคารที่โอน | `biz_bank_account` | `6a904d67353e1b0e4a50ba25` | `Relation` | subType 1 → `hr_bank_account` `6a8efd1fae2a0e3743a0bd9d` · bidirectional (reverse `6a904d67353e1b0e4a50ba26`) | |
| **สถานะสลิป** | `biz_payslip_status` | `6a904d67353e1b0e4a50ba27` | `Dropdown` (inline) | default Draft · options: Draft `73dcdbaf-283c-4182-9072-3f59b4336f79` · Calculated `740b4fba-e506-4e23-853f-10b17b3d7210` · Approved `325b8942-70b4-4ffa-9e78-ce8d65937156` · Paid `f1ed2aa6-f2d8-4e8b-804e-118625af0d72` · Cancelled `a846cbb5-75a1-4515-bc96-908d5ce7d8cf` | 🔴 **inline options เท่านั้น** ยังไม่ได้ผูก `OS_HR_PAYSLIP_STATUS` `f77b582b-187e-4df0-8578-69b2078d9045` ที่มีอยู่แล้ว (ต้องผูกผ่าน Browser UI — ค่า option ต่างกันเล็กน้อย "Published"→"Paid" ต้องปรับให้ตรงก่อนผูก) |
| (ระบบ) สั่งคำนวณใหม่ | `biz_recalc_flag` | `6a904d67353e1b0e4a50ba28` | `Number` | precision 0 · **default 0** | 🔴 **Trigger Field ของ WF-HR-08** (ยังไม่ได้สร้าง workflow) |
| (ระบบ) คำนวณแล้ว | `biz_calculated_flag` | `6a904d67353e1b0e4a50ba29` | `Number` | precision 0 · **default 0** | |
| วันที่คำนวณ | `biz_calculated_at` | `6a904d67353e1b0e4a50ba2a` | `DateTime` | | |
| หมายเหตุ | `biz_payslip_note` | `6a904d67353e1b0e4a50ba2b` | `Text` | multiLine | |
| (ระบบ) รายการในสลิปเงินเดือน — reverse relation | *(ไม่มี alias)* | `6a904d6d9762533b5b71c4e2` | `Relation` (auto) | subType 2 (multi) | สร้างอัตโนมัติจาก bidirectional ของ `hr_payslip_line.biz_payslip` |

**Form rules:** IX-12.3 **Unique index (`biz_employee`, `biz_pay_period`)** — **AC-15** · ⚠️ ยังไม่ได้ตั้ง Index Acceleration จริง · BR-12.4 interaction `pay_period.period_status` in (Posted, Closed) → Set all read-only — **AC-09** · BR-12.5 interaction — R1 เห็นเฉพาะสลิปที่ `payslip_status` = Published/Paid — ⚠️ ทั้งหมดนี้ยังไม่ได้ตั้งค่าจริง (ต้องทำผ่าน Browser)

**12E. รายการในสลิปเงินเดือน** `hr_payslip_line` `6a904c858b6633ef76f16a0b` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-2) ครบทุกฟิลด์ · Data Name ไทย ถูกต้องตั้งแต่สร้าง — ✅ view `6a904c858b6633ef76f16a0f` rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI)

| ฟิลด์ | alias | field ID | type | props |
|---|---|---|---|---|
| รายละเอียดรายการ | `biz_line_description` | `6a904d6d9762533b5b71c4e0` | `Text` | isTitle · required |
| **สลิปเงินเดือน** | `biz_payslip` | `6a904d6d9762533b5b71c4e1` | `Relation` | subType 1 → `hr_payslip` `6a904c85353e1b0e4a50ba05` · required · bidirectional (reverse `6a904d6d9762533b5b71c4e2`) |
| **องค์ประกอบค่าจ้าง** | `biz_pay_component` | `6a904d6d9762533b5b71c4e3` | `Relation` | subType 1 → `hr_pay_component` `6a8ff2868b6633ef76f13871` · required · bidirectional (reverse `6a904d6d9762533b5b71c4e4`) |
| ลำดับรายการ | `biz_line_no` | `6a904d6d9762533b5b71c4e5` | `Number` | precision 0 · default 0 |
| จำนวน | `biz_quantity` | `6a904d6d9762533b5b71c4e6` | `Number` | precision 2 · default 0 |
| อัตรา | `biz_rate` | `6a904d6d9762533b5b71c4e7` | `Currency` (THB) | precision 2 · default 0 — Currency แทน Number ตามสเปกเดิม |
| จำนวนเงิน | `biz_amount` | `6a904d6d9762533b5b71c4e8` | `Currency` (THB) | precision 2 · default 0 — Currency แทน Number ตามสเปกเดิม |
| หมายเหตุการคำนวณ | `biz_calc_note` | `6a904d6d9762533b5b71c4e9` | `Text` | multiLine — 🔴 **เก็บที่มาของตัวเลขทุกบรรทัด** เพื่อให้ตรวจสอบย้อนหลังได้ — BO-4 |

> **ส่วนที่ยังไม่เสร็จจาก P5-2:** unique index IX-12.3 · BR-12.4/12.5 (Business Rules) · การผูก `payslip_status` เข้า `OS_HR_PAYSLIP_STATUS` · Dynamic default ของ `cost_center` snapshot — ทั้งหมดต้องทำผ่าน Browser UI ในเซสชันถัดไป

> ⚠️ ถ้าจะทำ `hr_payslip.total_earning` ด้วย **Rollup** ต้องแน่ใจว่า filter คงที่ (เช่น `pay_component.component_type` = Earning) ทำได้ · ถ้าเงื่อนไขต้องอ้าง "วันนี้" หรือค่าที่เปลี่ยน ⇒ **ใช้ Number + workflow เขียนแทน** และ 🔴 **ห้ามใส่ฟิลด์ Rollup ลง `editFields` เด็ดขาด**

**12F. อัตราประกันสังคม** `hr_sso_rate` `6a8eebf8353e1b0e4a5074c1` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 ครบทุกฟิลด์
`hr_sso_rate_name` (`6a8eec428b6633ef76f12a01`) Text isTitle · `hr_employee_rate_pct` (`6a8eec428b6633ef76f12a02`) Number precision 4 required · `hr_employer_rate_pct` (`6a8eec428b6633ef76f12a03`) Number precision 4 required · `hr_min_wage_base` (`6a8eec428b6633ef76f12a04`) Number precision 2 required · `hr_max_wage_base` (`6a8eec428b6633ef76f12a05`) Number precision 2 required · `hr_sso_effective_from` (`6a8eec428b6633ef76f12a06`) Date subType 3 required · `hr_sso_effective_to` (`6a8eec428b6633ef76f12a07`) Date subType 3 · `hr_legal_reference` (`6a8eec428b6633ef76f12a08`) Text · `hr_sso_rate_is_active` (`6a8eec821378964f99849a07`) Checkbox ✅
> 🔴 **G-05** — ตัวเลขต้องยืนยันกับฝ่ายบัญชีก่อน go-live · ระบบอ่านจาก record ที่ `effective_from` ≤ วันจ่าย และมากที่สุด ⇒ เปลี่ยนอัตราได้โดยไม่แก้ workflow (**AC-19**)

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — 1 record `81acf446-8d03-4190-8f1a-9b5e8a600a40` "อัตราประกันสังคม ม.33 เฟส 1 (2569-2571)": อัตรา 5%/5% · ฐานค่าจ้าง 1,650–**17,500** (เพดานใหม่เฟส 1 มีผล 1 ม.ค. 2569 ตามมติ ครม.) · `effective_from` 2026-01-01 · `effective_to` 2028-12-31 · ที่มา: [krungsri.com](https://www.krungsri.com/th/krungsri-the-coach/life/good-life/sso-section-33-rate-increase) — ⚠️ ยังถือเป็น **G-05 unconfirmed** จนกว่าฝ่ายบัญชียืนยันตัวเลขอย่างเป็นทางการ

**12G. ขั้นบันไดภาษี** `hr_tax_bracket` `6a8eebf8ae2a0e3743a0bcec` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 ครบทุกฟิลด์
`hr_bracket_name` (`6a8eec478b6633ef76f12a20`) Text isTitle · `hr_tax_year` (`6a8eec478b6633ef76f12a21`) Number precision 0 required · `hr_income_from` (`6a8eec478b6633ef76f12a22`) / `hr_income_to` (`6a8eec478b6633ef76f12a23`) Number precision 2 required · `hr_tax_rate_pct` (`6a8eec478b6633ef76f12a24`) Number precision 4 required · `hr_bracket_order` (`6a8eec478b6633ef76f12a25`) Number precision 0 required · `hr_bracket_effective_from` (`6a8eec478b6633ef76f12a26`) Date subType 3 required
**Form rules:** IX-12.4 Unique index (`tax_year`, `bracket_order`) — ⚠️ ยังไม่ได้ตั้ง Index Acceleration จริง

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — 8 ขั้นบันไดภาษีเงินได้บุคคลธรรมดามาตรฐาน ปีภาษี 2569 (ยกเว้น–5–10–15–20–25–30–35%) ที่มา: [krungsri.com](https://www.krungsri.com/th/krungsri-the-coach/taxes/tax-knowledge/how-to-calculate-personal-income-tax) · ยืนยันจำนวนด้วย `get_record_pivot_data` COUNT = 8

**12H. ค่าลดหย่อนภาษี** `hr_tax_allowance` `6a8eebf8353e1b0e4a5074cb` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 ครบทุกฟิลด์
`hr_allowance_name` (`6a8eec4e353e1b0e4a50750e`) Text isTitle · `hr_allowance_code` (`6a8eec4e353e1b0e4a50750f`) Text required · `hr_allowance_tax_year` (`6a8eec4e353e1b0e4a507510`) Number precision 0 required · `hr_amount_per_unit` (`6a8eec4e353e1b0e4a507511`) Number precision 2 required · `hr_max_units` (`6a8eec4e353e1b0e4a507512`) Number precision 0 · `hr_max_amount` (`6a8eec4e353e1b0e4a507513`) Number precision 2 · `hr_allowance_effective_from` (`6a8eec4e353e1b0e4a507514`) Date subType 3 required · `hr_requires_dependent` (`6a8eec84ae2a0e3743a0bd11`) Checkbox ✅

✅ **Seed แล้ว 26 ส.ค. 2569 (P1-4)** — 8 ค่าลดหย่อนมาตรฐาน ปีภาษี 2569: ส่วนตัว 60,000 · คู่สมรส 60,000 · บุตรคนแรก 30,000 · บุตรคนที่สองขึ้นไป (เกิด ≥2561) 60,000/คน · บิดามารดา 30,000/คน (สูงสุด 4) · ประกันชีวิต/สุขภาพ 100,000 · เงินสมทบประกันสังคม 10,500 (ปรับตามเพดานใหม่) · กองทุนสำรองเลี้ยงชีพ/RMF 500,000 — ที่มา: [prudential.co.th](https://www.prudential.co.th/th/knowledge-corner/growing-wealth/tips-to-reduce-personal-income-tax/) · ยืนยันจำนวนด้วย `get_record_pivot_data` COUNT = 8

**12I. การยื่น ภ.ง.ด.1** `hr_pnd1_filing` `6a904e72ae2a0e3743a0fd06` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-3) ครบทุกฟิลด์ · Data Name ไทย ถูกต้องตั้งแต่สร้าง — ✅ view `6a904e72ae2a0e3743a0fd0a` rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI)

| ฟิลด์ | alias | field ID | type | props |
|---|---|---|---|---|
| ชื่อการยื่น | `biz_filing_name` | `6a904e96353e1b0e4a50ba8e` | `Text` | isTitle · required |
| ประเภทแบบ | `biz_form_type` | `6a904e96353e1b0e4a50ba8f` | `Dropdown` (inline) | required · options: P.N.D.1 `f0137674-d149-44df-8212-672ccfaefd7f` · P.N.D.1 Kor `46f4de50-4f07-4e4d-a3c7-69e464c5093b` — 🔴 inline เท่านั้น ยังไม่ผูก `OS_HR_FILING_FORM` `9e8dac8a-3989-419a-b88d-d6bd5311c008` |
| ปีภาษี | `biz_tax_year` | `6a904e96353e1b0e4a50ba90` | `Number` | precision 0 · required |
| เดือนภาษี | `biz_tax_month` | `6a904e96353e1b0e4a50ba91` | `Number` | precision 0 (ว่างสำหรับ P.N.D.1 Kor) |
| งวดจ่ายที่เกี่ยวข้อง | `biz_pay_periods` | `6a904e96353e1b0e4a50ba92` | `Relation` | subType 2 (multi) → `hr_pay_period` `6a8ff2878b6633ef76f1387b` · bidirectional (reverse `6a904e96353e1b0e4a50ba93`) |
| จำนวนพนักงานรวม | `biz_total_employees` | `6a904e96353e1b0e4a50ba94` | `Number` | precision 0 · default 0 |
| รวมรายได้ | `biz_total_income` | `6a904e96353e1b0e4a50ba95` | `Currency` (THB) | precision 2 · default 0 — Currency แทน Number ตามสเปกเดิม |
| รวมภาษีหัก | `biz_total_wht` | `6a904e96353e1b0e4a50ba96` | `Currency` (THB) | precision 2 · default 0 — Currency แทน Number ตามสเปกเดิม |
| สถานะการยื่น | `biz_filing_status` | `6a904e96353e1b0e4a50ba97` | `Dropdown` (inline) | default Draft · options: Draft `9cfae3d7-8705-413f-b406-a0d538aaf406` · Approved `e1aa329d-b0b2-4576-b23c-29f0740e0d7d` · Filed `b214da57-0f11-4165-acba-139be95bf93a` · Paid `a16148b3-68f1-4032-892a-bfb1a688bf91` · Amended `260f4c54-e005-4c62-8118-2a5be8b92483` — 🔴 inline เท่านั้น ยังไม่ผูก `OS_HR_FILING_STATUS` `dc455e42-cd18-4dd3-9275-45d904046b04` |
| วันที่ยื่น | `biz_filed_date` | `6a904e96353e1b0e4a50ba98` | `Date` | subType 3 |
| เลขที่ใบเสร็จรับ | `biz_receipt_no` | `6a904e96353e1b0e4a50ba99` | `Text` | |
| ไฟล์แบบยื่น | `biz_filing_file` | `6a904e96353e1b0e4a50ba9a` | `Attachment` | |
| (ระบบ) สถานะออกหนังสือรับรอง | `biz_issue_cert_flag` | `6a904e96353e1b0e4a50ba9b` | `Number` | precision 0 · default 0 — 🔴 Trigger Field ของ WF-HR-20 (ยังไม่ได้สร้าง) |
| (ระบบ) หนังสือรับรองที่เกี่ยวข้อง — reverse relation | *(ไม่มี alias)* | `6a904ea1353e1b0e4a50bac3` | `Relation` (auto) | subType 2 (multi) | สร้างอัตโนมัติจาก bidirectional ของ `hr_wht_cert.biz_pnd1_filing` |

**Form rules:** IX-12.5 **Unique index (`biz_form_type`, `biz_tax_year`, `biz_tax_month`)** — ⚠️ ยังไม่ได้ตั้ง Index Acceleration จริง (Browser-only)

**12J. หนังสือรับรองการหักภาษี (50 ทวิ)** `hr_wht_cert` `6a904e73353e1b0e4a50ba83` ✅ สร้างจริงแล้ว 27 ส.ค. 2569 (P5-3) ครบทุกฟิลด์ · Data Name ไทย ถูกต้องตั้งแต่สร้าง — ✅ view `6a904e73353e1b0e4a50ba87` rename เป็น "ทั้งหมด" แล้ว 27 ส.ค. 2569 (ผ่าน hap CLI)

| ฟิลด์ | alias | field ID | type | props |
|---|---|---|---|---|
| เลขที่หนังสือรับรอง | `biz_cert_no` | `6a904ea1353e1b0e4a50babe` | `Text` | isTitle · required |
| **พนักงาน** | `biz_employee` | `6a904ea1353e1b0e4a50babf` | `Relation` | subType 1 → `hr_employee` `6a8efa5e9762533b5b7185c1` · required · bidirectional (reverse `6a904ea1353e1b0e4a50bac0`) |
| ปีภาษี | `biz_tax_year` | `6a904ea1353e1b0e4a50bac1` | `Number` | precision 0 · required |
| การยื่น ภ.ง.ด.1 ที่เกี่ยวข้อง | `biz_pnd1_filing` | `6a904ea1353e1b0e4a50bac2` | `Relation` | subType 1 → `hr_pnd1_filing` `6a904e72ae2a0e3743a0fd06` · bidirectional (reverse `6a904ea1353e1b0e4a50bac3`) |
| สถานะบุคคลของผู้มีเงินได้ | `biz_payee_legal_form` | `6a904ea1353e1b0e4a50bac4` | `Dropdown` (inline) | options: Individual `08216df9-8694-4a85-a961-a61c7f1646f6` — 🔴 inline เท่านั้น ยังไม่ผูก `OS_LEGAL_FORM` `b97a1a08-78ab-4683-8472-837c48af4423` (key ต่างจาก `1aeb1a04-1957-4905-92d9-c506d8bbdccc` ของโมดูลบัญชี) |
| รวมรายได้ | `biz_total_income` | `6a904ea1353e1b0e4a50bac5` | `Currency` (THB) | precision 2 · required — Currency แทน Number ตามสเปกเดิม |
| รวมภาษีหัก | `biz_total_wht` | `6a904ea1353e1b0e4a50bac6` | `Currency` (THB) | precision 2 · required — Currency แทน Number ตามสเปกเดิม |
| วันที่ออก | `biz_issue_date` | `6a904ea1353e1b0e4a50bac7` | `Date` | subType 3 |
| สถานะหนังสือรับรอง | `biz_cert_status` | `6a904ea1353e1b0e4a50bac8` | `Dropdown` (inline) | default Issued · options: Issued `48242102-ee8a-44a4-bec5-482b16b8729e` · Printed `27a8ee8a-f6e2-4bfa-aa2a-da709d93ada6` · Included in filing `e608e791-438d-40fa-acb3-fb339ef41eee` · Cancelled `8b45923b-7541-4417-9cec-295d4c37e962` — 🔴 inline เท่านั้น ยังไม่ผูก `OS_HR_CERT_STATUS` `bd2d8da7-0c15-436e-931e-429c5ba6440b` |
| ไฟล์หนังสือรับรอง | `biz_cert_file` | `6a904ea1353e1b0e4a50bac9` | `Attachment` | |

**Form rules:** IX-12.6 **Unique index (`biz_employee`, `biz_tax_year`)** — ⚠️ ยังไม่ได้ตั้ง Index Acceleration จริง (Browser-only)

> **ส่วนที่ยังไม่เสร็จจาก P5-3:** unique index IX-12.5/IX-12.6 · ผูก dropdown ทั้ง 4 ฟิลด์เข้า shared optionset จริง (`form_type`/`filing_status`/`payee_legal_form`/`cert_status`) — ทั้งหมดต้องทำผ่าน Browser UI ในเซสชันถัดไป

**DoD ของกลุ่มเงินเดือน:** AC-06 AC-07 AC-08 AC-09 AC-15 AC-19 ผ่านครบ
**Pitfall:** 🔴 การคำนวณภาษีต้องอ่านทั้ง `hr_tax_bracket` และ `hr_tax_allowance` ตามปีภาษี — อย่ารวมสองตารางเข้าด้วยกันเพราะขั้นบันไดกับค่าลดหย่อนเปลี่ยนคนละจังหวะ

---

### FR-HR-18 / FR-HR-19 · กลุ่มสวัสดิการและใบเบิก

**18A. สวัสดิการ** `hr_welfare_scheme` `<TBD-WS-38>`
`scheme_name` Text isTitle required · `scheme_code` Text required (unique index) · `job_level` Relation→`hr_job_level` (ว่าง = ทุกระดับ) · `entitlement_amount` Number precision 2 required · `entitlement_cycle` Dropdown→`OS_HR_WELFARE_CYCLE` `bd2ad40f-1165-4080-bcc6-ebb143db8d27` · `max_per_claim` Number precision 2 · `require_receipt` Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser — แก้ 26 ส.ค. 2569) · `covers_dependent` Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser — แก้ 26 ส.ค. 2569) · `coa_account` Relation→`ac_coa` `6a85516e1049edca1eecd9b7` ✅ · `effective_from` Date subType 3 required · `is_active` Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser — แก้ 26 ส.ค. 2569)

**18B. วงเงินสวัสดิการคงเหลือ** `hr_welfare_balance` `<TBD-WS-39>`
`wb_name` Text isTitle · `employee` Relation→`hr_employee` required · `welfare_scheme` Relation→`hr_welfare_scheme` required · `benefit_year` Number precision 0 required · `entitled_amount` Number precision 2 default 0 · `used_amount` Number precision 2 default 0 · `remaining_amount` Number precision 2 default 0 (🔴 เขียนโดย workflow) · `wb_note` Text multiLine
**Form rules:** IX-18.1 Unique index (`employee`, `welfare_scheme`, `benefit_year`) · BR-18.1 Set all read-only ยกเว้น R3 R4

**19A. ใบเบิกสวัสดิการและค่าใช้จ่าย** `hr_claim` `<TBD-WS-40>`

| ฟิลด์ | alias | type | props | หมายเหตุ |
|---|---|---|---|---|
| เลขที่ใบเบิก | `claim_no` | `Text` | isTitle | เขียนโดย workflow |
| พนักงาน | `employee` | `Relation` | subType 1 → `hr_employee` · required | |
| สวัสดิการ | `welfare_scheme` | `Relation` | subType 1 → `hr_welfare_scheme` · required | |
| ผู้ใช้สิทธิ (ตนเอง/ผู้ติดตาม) | `beneficiary` | `Relation` | subType 1 → `hr_dependent` | ว่าง = ตนเอง |
| วันที่เกิดค่าใช้จ่าย | `expense_date` | `Date` | subType 3 · required | |
| **จำนวนเงินที่ขอเบิก** | `claim_amount` | `Number` | precision 2 · default 0 | 🔴 **Rollup** จาก `hr_claim_line.line_amount` (filter คงที่ได้ ⇒ ใช้ Rollup ได้) · 🔴 **ห้ามใส่ลง `editFields`** |
| วงเงินคงเหลือขณะยื่น | `balance_snapshot` | `Number` | precision 2 | Dynamic default · Query worksheet |
| **สถานะใบเบิก** | `claim_status` | `Dropdown` | → `OS_HR_REQUEST_STATUS` `8ea16e5f-c099-45e2-9734-b553ea40b8d0` | default Draft · read-only |
| ผู้อนุมัติที่ระบบกำหนด | `approver_user` | `Collaborator` | subType 0 | |
| (ระบบ) ขั้นการอนุมัติ | `approval_step` | `Number` | precision 0 · default 0 | |
| วันที่อนุมัติ | `approved_at` | `DateTime` | subType 1 | |
| เหตุผลที่ไม่อนุมัติ | `reject_reason` | `Text` | multiLine | |
| หลักฐานประกอบ | `receipts` | `Attachment` | subType 3 | |
| (ระบบ) ส่งอนุมัติแล้ว | `claim_submitted_flag` | `Number` | precision 0 · **default 0** | |
| (ระบบ) ตัดวงเงินแล้ว | `deducted_flag` | `Number` | precision 0 · **default 0** | 🔴 กันตัดซ้ำ |
| **(ระบบ) ส่งเข้าบัญชีแล้ว** | `sent_to_ac_flag` | `Number` | precision 0 · **default 0** | 🔴 กัน WF-HR-12 สร้างใบขออนุมัติเบิกจ่ายซ้ำ |
| **ใบขออนุมัติเบิกจ่ายที่สร้าง** | `pay_req_ref` | `Relation` | subType 1 · dataSource `6a8677b19b6999a714d2aa83` | → `ac_pay_req` ✅ · เขียนโดย WF-HR-12 |

**19B. รายการค่าใช้จ่าย** `hr_claim_line` `<TBD-WS-41>`
`line_description` Text isTitle required · `claim` Relation subType 1 → `hr_claim` required · `line_no` Number precision 0 required · `expense_type` SingleSelect · `line_amount` Number precision 2 required · `receipt_no` Text · `vendor_name` Text · `line_receipt` Attachment

**Form rules ของ `hr_claim`:**
| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-19.1 | validation (re-validate on server) | `claim_amount` > วงเงินคงเหลือของ (`employee`, `welfare_scheme`, `benefit_year`) | Block "จำนวนเงินเกินวงเงินคงเหลือ" — **AC-10** |
| BR-19.2 | validation | `claim_amount` > `welfare_scheme.max_per_claim` (เมื่อมีค่า) | Block |
| BR-19.3 | interaction | `welfare_scheme.require_receipt` = จริง | required `receipts` |
| BR-19.4 | interaction | `claim_status` ≠ Draft | Set all read-only |
| RU-19.1 | Rollup | `hr_claim_line` → Sum(`line_amount`) → `claim_amount` | filter คงที่ |
| DV-19.1 | Dynamic default · Query worksheet | เมื่อเลือก `welfare_scheme` | เติม `balance_snapshot` และ `approver_user` |

**DoD:** **AC-10** ผ่านครบ — บล็อกเมื่อเกินวงเงิน · อนุมัติแล้ววงเงินลด · เกิด `ac_pay_req` 1 ใบ (ยิงซ้ำต้องไม่เกิดใบที่สอง)

---

### FR-HR-20 ถึง FR-HR-23 · กลุ่มสรรหา ประเมิน อบรม

**20A. ใบขออัตรากำลัง** `hr_job_requisition` `<TBD-WS-30>`
`req_no` Text isTitle · `position` Relation→`hr_position` required · `cost_center` Relation→`ac_cost_center` `6a85452b9b6999a714d26720` ✅ required · `job_level` Relation→`hr_job_level` · `headcount` Number precision 0 required · `reason` Text multiLine required · `budget_amount` Number precision 2 · `target_start_date` Date subType 3 · `req_status` Dropdown→`OS_HR_REQUEST_STATUS` `8ea16e5f-c099-45e2-9734-b553ea40b8d0` · `approver_user` Collaborator · `approved_at` DateTime subType 1 · `req_submitted_flag` Number default 0 · `filled_count` Number precision 0 default 0

**21A. ผู้สมัคร** `hr_candidate` `<TBD-WS-31>` — 🔴 PDPA · A-HR-18 เก็บ 1 ปี
`candidate_name` Text isTitle required · `job_requisition` Relation→`hr_job_requisition` · `applied_position` Relation→`hr_position` · `email` / `mobile` Text · `candidate_national_id` Text (🔴 PDPA) · `birth_date` Date subType 3 · `education` Text multiLine · `experience_years` Number precision 1 · `expected_salary` Number precision 2 · `stage` Dropdown→`OS_HR_CANDIDATE_STAGE` `be9704bf-478e-41b0-9e34-aa9911ca71d2` default Applied · `source_channel` SingleSelect · `resume` Attachment · `stage_changed_at` DateTime subType 1 · `hired_employee` Relation subType 1 → `hr_employee` (เขียนโดย WF-HR-17) · `hire_flag` Number precision 0 default 0 · `pdpa_consent_date` Date subType 3 · `data_retention_until` Date subType 3 (🔴 A-HR-18 · **Date field trigger** สำหรับ workflow ลบข้อมูลในเฟสถัดไป)

**21B. การสัมภาษณ์** `hr_interview` `<TBD-WS-32>`
`interview_name` Text isTitle · `candidate` Relation→`hr_candidate` required · `interview_round` Number precision 0 required · `interview_at` DateTime subType 1 required (🔴 `+07:00`) · `interviewers` Collaborator subType 1 (หลายคน) · `location` Text · `score` Number precision 2 · `result` SingleSelect (ผ่าน/ไม่ผ่าน/รอพิจารณา) · `comments` Text multiLine · `notified_flag` Number precision 0 default 0

**22A. รอบประเมินผล** `hr_appraisal_cycle` `<TBD-WS-33>`
`cycle_name` Text isTitle required · `cycle_year` Number precision 0 required · `cycle_no` Number precision 0 required (1 หรือ 2 ตาม A-HR-16) · `period_from` / `period_to` Date subType 3 required · `self_due_date` / `supervisor_due_date` / `hr_due_date` Date subType 3 · `cycle_open_flag` Number precision 0 default 0 (🔴 Trigger Field ของ WF-HR-18) · `generated_count` Number precision 0 default 0
**Form rules:** IX-22.1 Unique index (`cycle_year`, `cycle_no`)

**22B. แบบประเมินผล** `hr_appraisal` `<TBD-WS-34>`
`appraisal_name` Text isTitle · `cycle` Relation→`hr_appraisal_cycle` required · `employee` Relation→`hr_employee` required · `supervisor_user` Collaborator subType 0 (🔴 สำหรับ Approve node) · `appraisal_status` Dropdown→`OS_HR_APPRAISAL_STATUS` `f53f261b-7c2e-4c36-a9d8-b20d4230321a` default Not started · `self_score` / `supervisor_score` / `final_score` Number precision 2 · `grade` SingleSelect (A/B/C/D/E) · `self_comment` / `supervisor_comment` / `hr_comment` Text multiLine · `submitted_at` DateTime subType 1 · `completed_at` DateTime subType 1 · `apr_step_flag` Number precision 0 default 0
**Form rules:** IX-22.2 Unique index (`cycle`, `employee`) · BR-22.1 interaction `appraisal_status` = Completed → Set all read-only

**22C. รายการประเมิน** `hr_appraisal_item` `<TBD-WS-35>`
`item_name` Text isTitle required · `appraisal` Relation subType 1 → `hr_appraisal` required · `item_category` SingleSelect (KPI / สมรรถนะ / พฤติกรรม) · `weight_pct` Number precision 2 required · `target_value` Text · `actual_value` Text · `self_rating` / `supervisor_rating` Number precision 2 · `item_comment` Text multiLine

**23A. หลักสูตรฝึกอบรม** `hr_course` `<TBD-WS-36>`
`course_name` Text isTitle required · `course_code` Text required (unique index) · `course_category` SingleSelect · `provider` Text · `is_internal` Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser — แก้ 26 ส.ค. 2569) · `duration_hours` Number precision 2 · `cost_per_head` Number precision 2 · `validity_months` Number precision 0 (สำหรับใบรับรองที่หมดอายุ) · `course_outline` Text multiLine · `is_active` Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser — แก้ 26 ส.ค. 2569)

**23B. การเข้าอบรม** `hr_training` `<TBD-WS-37>`
`training_name` Text isTitle · `course` Relation→`hr_course` required · `employee` Relation→`hr_employee` required · `planned_date` Date subType 3 · `attended_date` Date subType 3 · `training_status` Dropdown→`OS_HR_TRAINING_STATUS` `738a7d5c-1c93-4cd2-b79c-468d389949a9` default Planned · `score` Number precision 2 · `passed` Checkbox (✅addFields ใช้ได้ ไม่ต้อง Browser — แก้ 26 ส.ค. 2569) · `certificate_no` Text · `certificate_expiry` Date subType 3 (🔴 **Date field trigger** สำหรับเตือนต่ออายุ) · `certificate_file` Attachment · `actual_cost` Number precision 2 · `training_note` Text multiLine
**Form rules:** IX-23.1 Unique index (`course`, `employee`, `planned_date`)

---

**Definition of Done (FR-HR-20 ถึง FR-HR-23):**
- **AC-17** ผ่าน — เปลี่ยน `stage` ของผู้สมัครทดสอบเป็น Hired แล้วเกิด `hr_employee` 1 record ที่ข้อมูลตรงกับผู้สมัคร · ยิงซ้ำไม่เกิด record ที่สอง
- ใบขออัตรากำลังผ่านการอนุมัติ 2 ขั้นโดยคนจริง (`get_approval_list_by_row` มี 2 instance)
- เปิดรอบประเมินแล้วเกิด `hr_appraisal` เท่ากับจำนวนพนักงาน active พอดี · unique index IX-22.2 กันซ้ำเป็นด่านที่สอง
- แบบประเมินเดินครบ 3 ขั้นด้วยบัญชีคนละบทบาท และ `final_score` = ค่าเฉลี่ยถ่วงน้ำหนักตาม `weight_pct` ที่คำนวณด้วยมือแล้วตรงกัน
- ประวัติอบรมของพนักงานทดสอบเปิดดูจากหน้าทะเบียนพนักงานได้ (BR-20)
**วิธี verify:** `_updatedBy` = `user-workflow` ในทุก record ที่ workflow สร้าง · `get_record_pivot_data` นับจำนวนแบบประเมินเทียบกับจำนวนพนักงาน
**Pitfall:** 🔴 `hr_employee.emp_user` ที่ WF-HR-17 สร้างจะว่างเสมอ (หา userId จากชื่อไม่ได้) — พนักงานใหม่ยื่นใบลาไม่ได้จนกว่า HR จะกรอกด้วยมือ

### FR-HR-24 บทบาทและการควบคุมสิทธิ์
ดู **§1.7 Permission matrix** — ทั้งหมดต้องตั้งผ่าน `create_role` แล้ว **ยืนยันด้วย `get_role_details`** และ **ทดสอบด้วยบัญชีจริงของแต่ละบทบาท**
**DoD:** AC-11 AC-12 AC-13 ผ่าน — 🔴 ทำไม่ได้จนกว่าจะมีบัญชีทดสอบเพิ่ม (Gap G-06)

### FR-HR-25 รายงานและแดชบอร์ด
| รายงาน | แหล่งข้อมูล | ชนิด | Surface |
|---|---|---|---|
| กำลังคนตามหน่วยงาน | `hr_employee` (filter `emp_status` in Probation/Active/On leave) | Chart แท่ง | MCP (unverified) → Browser |
| อัตราการเข้า-ออก | `hr_employment_event` | Chart เส้น | MCP (unverified) |
| สถิติการลาตามประเภท | `hr_leave_request` (Approved) | Chart วงกลม | MCP (unverified) |
| ชั่วโมง OT ตามหน่วยงาน | `hr_ot_request` (Approved) | Chart แท่ง | MCP (unverified) |
| ต้นทุนเงินเดือนตามศูนย์ต้นทุน | `hr_payslip` group by `cost_center` | Chart แท่ง | MCP (unverified) |
| คำขอค้างอนุมัติเกิน SLA | `hr_leave_request` + `hr_ot_request` + `hr_claim` | View + Chart | MCP (unverified) |
| วงเงินสวัสดิการที่ใช้ไป | `hr_welfare_balance` | Chart แท่งซ้อน | MCP (unverified) |
**Definition of Done (FR-HR-25):** ทั้ง 7 รายงานสร้างแล้วและ **เปิดหน้าจอเห็นจริง** (G-07 — `create_chart` ยังไม่เคยเรียกสำเร็จในแอปนี้) · ตัวเลขบนรายงานตรงกับ `get_record_pivot_data` ของแหล่งข้อมูลเดียวกัน · ผู้บริหาร (HR-R6) เปิดดูได้โดยไม่เห็นข้อมูลรายบุคคลที่อ่อนไหว
**Pitfall:** ⚠️ Rollup ใช้เงื่อนไข "วันนี้" ไม่ได้ ⇒ รายงานที่ต้องเทียบกับวันปัจจุบันให้ใช้ **Chart หรือ Aggregated Table** ไม่ใช่ฟิลด์ Rollup

### FR-HR-26 การแจ้งเตือน
รวมอยู่ในแต่ละ workflow (§3) — ทุก node `Send Internal Notification` ต้องระบุผู้รับจาก node `Get associated records` ไม่ใช่พิมพ์ชื่อ · **ปิด "Notify when approved/rejected" ใน Approve node ถ้ามี Send Internal Notification ใน flow นอกอยู่แล้ว** (กันแจ้งซ้ำ)
**Definition of Done (FR-HR-26):** เดินเส้นทางใบลา 1 ใบตั้งแต่ส่งจนอนุมัติ แล้วนับการแจ้งเตือนที่ผู้อนุมัติและพนักงานได้รับ — **ต้องได้ขั้นละ 1 ครั้ง ไม่ซ้ำ** · **AC-14** ผ่าน (WF-HR-06) · ทุก node แจ้งเตือนระบุผู้รับจาก node `Get associated records` ไม่มีการพิมพ์ชื่อคนลงไปตรง ๆ
**วิธี verify:** เปิดกล่องแจ้งเตือนของบัญชีทดสอบแต่ละบทบาทหลังจบเส้นทาง

### FR-HR-27 เอกสารรูปแบบราชการ
| เอกสาร | แหล่งข้อมูล | Surface |
|---|---|---|
| แบบฟอร์มใบลา | `hr_leave_request` | 🔴 **Browser** — Print Template (MCP ไม่มี tool) |
| หนังสือรับรองเงินเดือน | `hr_employee` + `hr_salary_structure` | 🔴 Browser |
| หนังสือรับรองการทำงาน | `hr_employee` + `hr_employment_event` | 🔴 Browser |
| หนังสือรับรองการหักภาษี (50 ทวิ) | `hr_wht_cert` | 🔴 Browser |
**ข้อกำหนดรูปแบบ:** ฟอนต์ TH Sarabun New · เลขไทยในเอกสารราชการ · พุทธศักราช · ระยะขอบตามระเบียบงานสารบรรณ
**Definition of Done (FR-HR-27):** **AC-16** ผ่าน — พิมพ์ใบลาและหนังสือรับรองเงินเดือนออกมาเป็นไฟล์จริง แล้วผู้ใช้ตรวจรับรูปแบบ · ค่าทุกช่องดึงจาก record ไม่มีการพิมพ์ด้วยมือ · หนังสือรับรองเงินเดือนต้องออกได้เฉพาะบทบาทที่มีสิทธิ์เห็นเงินเดือน (HR-R4)
**วิธี verify:** สั่งพิมพ์จากหน้า record ด้วยบัญชีของแต่ละบทบาท แล้วเทียบกับตัวอย่างเอกสารที่ผู้ใช้ให้มา

---

## §3. Workflow Catalog

> **Surface = MCP ทุกตัว** — `create_process` → `batch_create_process_nodes` → `validate_process` → `publish_process` · **publish = เปิดใช้งานทันที**
> ระบุ `fieldId` จริง 24 หลัก (ห้าม alias) · `nodeType` ตามชื่อ MCP · ตัวดำเนินการตามพจนานุกรม workflow (`gte` ไม่ใช่ `ge`) · `branch.paths[].result` = `pass` / `overrule`
> 🔴 **ห้ามใส่ `filter` ใน trigger ของ `worksheet_event`** — ใส่ `triggerFields` อย่างเดียว แล้วเอาเงื่อนไขไปไว้ใน branch node แรก
> 🔴 **แก้ node ที่สร้างแล้วไม่ได้** — `delete_process_node` แล้วสร้างใหม่ · `validate_process` ทุกครั้งหลัง batch

---

### WF-HR-01 อนุมัติใบลา 2 ระดับ `<TBD-WF-01>`

> 🔴🆕 **28 ส.ค. 2569 (D-15) — สถานะ "tested and working" เดิม (27 ส.ค.) ต้องตรวจสอบซ้ำก่อนเชื่อ:** พยายามเพิ่ม BR-08.3 เข้า workflow นี้จริง (publish v4) แล้วพบว่าหยุดยิงบน trigger ใหม่ทั้งหมด revert คืนโครงสร้างเดิม (publish v5, = v3 เดิมทุกจุด) แต่อาการไม่ยิงยังคงอยู่แม้หลัง revert — สาเหตุยังไม่ทราบ ไม่ยืนยันว่าเกี่ยวกับการแก้ไข ยืนยันแล้วว่า approval instance จริงที่ pending อยู่ก่อนหน้า (TEST-LR-0001) ไม่ถูกกระทบ **ห้ามแก้ node ของ workflow นี้เพิ่มจนกว่าจะเข้าใจสาเหตุ และต้องยิง test record ใหม่ยืนยันซ้ำก่อนเชื่อว่ายังทำงานปกติ** — รายละเอียดเต็มใน `04-CLAUDE-memory.md` Known Issues D-15 และ `05-Roadmap-Tracker.md`

- **ชนิด / Surface:** `worksheet_event` (create + update) · **MCP**
- **Trigger:** worksheet `hr_leave_request` `6a8f2dbaae2a0e3743a0beaa` · **`triggerFields = [leave_status]`** (🔴 ห้ามใส่ filter)
- **กันยิงซ้ำ:** `submitted_flag` **not equal to** 1 → เซ็ต 1 ทันทีใน Update Record แรก
- **Nodes (ลำดับจริง):**
  1. **Trigger by worksheet** — `hr_leave_request`, "When creating and updating records", Trigger Field = `leave_status`
  2. **Branch** — `leave_status` equals key ของ **Pending supervisor** AND `submitted_flag` **not equal to** 1 · path `overrule` → จบ
  3. **Get associated records** — ตาม relation `employee` → ได้ record `hr_employee`
  4. **Branch (ตรวจผู้อนุมัติ)** — node 3 › `supervisor_user` **is not empty** · path `overrule` → Update Record คืน `leave_status` = Draft + `reject_reason` = "ไม่พบผู้บังคับบัญชาในทะเบียนพนักงาน" → Send Internal Notification ถึงผู้สร้าง → จบ
  5. **Query worksheet (ตรวจวันซ้อนทับ)** — `hr_leave_request` · เงื่อนไข: `employee` = trigger › `employee` AND `rowid` ≠ trigger › `rowid` AND `leave_status` **in** (Pending supervisor, Pending HR, Approved) AND `leave_from` **lte** trigger › `leave_to` AND `leave_to` **gte** trigger › `leave_from`
  6. **Branch** — จำนวน record ที่ได้จาก node 5 **gt** 0 · path `pass` → Update Record: `leave_status` = Draft · `reject_reason` = "มีใบลาที่ทับซ้อนช่วงวันเดียวกันอยู่แล้ว" → Send Internal Notification → **จบ flow**
  7. **Get associated records** — ตาม relation `leave_type` → ได้ `hr_leave_type`
  8. **Query worksheet (ตรวจสิทธิคงเหลือ)** — `hr_leave_balance` · `employee` = trigger › `employee` AND `leave_type` = trigger › `leave_type` AND `leave_year` = trigger › `leave_year`
  9. **Branch** — node 8 › `remaining_days` **gte** trigger › `leave_days` · path `overrule` → Update Record คืน Draft + `reject_reason` = "จำนวนวันลาเกินสิทธิคงเหลือ" → แจ้งเตือน → จบ
  10. **Update Record** (trigger record) — `submitted_flag` = 1 · `submitted_at` = System › Current time · `approval_step` = 1 · `approver_user` = node 3 › `supervisor_user` · `balance_snapshot` = node 8 › `remaining_days`
  11. **Initiate Approval Flow** — data object = trigger record · Initiator = Trigger · To-do title = "ใบลา {leave_no} ของ {employee} รออนุมัติ (ขั้นหัวหน้างาน)"
  12. **Approve (ขั้นที่ 1 — หัวหน้างาน)** — Approver: Custom → Initiate Approval › [Personnel] `approver_user`
      · **When the approver is empty → Delegate by the workflow owner** (🔴 ไม่เลือก = flow ค้าง)
      · Notify when approved/rejected = **ปิด** (มี Send Internal Notification ใน flow นอกแล้ว)
      · **Data Update › after approves:** `leave_status` = **Pending HR** · `approver1_user` = System › Current user · `approval_step` = 2
      · **Data Update › when rejects:** `leave_status` = **Rejected** · `approved_at` = System › Current time · `approver1_user` = System › Current user
  13. **Branch `approval_result`** (🔴 ต้องอยู่ในสายอนุมัติ ต่อจาก approve node) — `pass` → ไป node 14 · `overrule` → Send Internal Notification ถึงผู้สร้าง "ใบลาไม่ได้รับอนุมัติ" → จบ
  14. **Update Record** — `approver_user` = **บัญชีของ HR** (จาก `hr_approval_rule` — ดูหมายเหตุด้านล่าง)
  15. **Approve (ขั้นที่ 2 — HR)** — Approver: Custom → `approver_user` · empty policy = Delegate by the workflow owner
      · **Data Update › after approves:** `leave_status` = **Approved** · `approved_at` = System › Current time · `approver2_user` = System › Current user · `approval_step` = 3
      · **Data Update › when rejects:** `leave_status` = **Rejected** · `approved_at` = System › Current time
  16. **Send Internal Notification** — Content: "ใบลา {leave_no} วันที่ {leave_from} ถึง {leave_to} ผลการพิจารณา: {leave_status}" · Notifier: node 3 › `emp_user`

> 🔴 **การหาผู้อนุมัติขั้น HR:** `update_record` **คัดลอกค่าฟิลด์ชนิด OrgRole ไม่ได้** (เขียนค่าว่างเงียบ ๆ → approval abort ทันที)
> **ทางแก้ที่พิสูจน์แล้วในแอปนี้:** ใช้ node **`get_single`** ค้น `hr_approval_rule` **ภายในสายอนุมัติ** แล้วให้ `approve.approvers` อ้าง `{kind:"field", node:<get_single nodeId>, fieldId:<approver_role_hr>}` **ตรง ๆ** ไม่ต้องคัดลอกลงตารางหลัก
> 🔴 **start node ของ approval_block ไม่มี alias** — `approval_start` ใช้ไม่ได้ · ต้อง `get_workflow_structure(<inner processId>)` แล้วอ้างด้วย `nodeId`

- **ขั้นผู้บริหาร (เงื่อนไข A-HR-08):** ถ้า `leave_days` **gte** `hr_setting.exec_approval_days` ให้แทรก Approve node เพิ่มระหว่าง node 13 กับ 14 โดยผู้อนุมัติมาจาก `hr_approval_rule` ระดับที่ 3
- **Output:** `leave_status` · `submitted_flag` · `submitted_at` · `approval_step` · `approver_user` · `approver1_user` · `approver2_user` · `approved_at` · `balance_snapshot` · `reject_reason`
- **Test recipe:**
  - **seed:** `create_record(hr_leave_request, {employee: <emp ทดสอบที่มี supervisor_user>, leave_type: ลาพักผ่อน, leave_from: "2026-09-07", leave_to: "2026-09-08", leave_days: 2, leave_reason: "ทดสอบ", leave_status: Draft}, triggerWorkflow:false)`
  - **ยิง:** `update_record(rowid, {leave_status: <key Pending supervisor>}, triggerWorkflow:true)` (จำลองการกดปุ่ม)
  - **ผู้กด approve:** หัวหน้างานทดสอบ → กดใน To-do · จากนั้น HR ทดสอบ → กดใน To-do
  - **คาดว่าจะเห็น:** `get_record_details(includeSystemFields:true)` แสดง `_updatedBy` = **`user-workflow`** · `get_approval_list_by_row` มี instance ผู้รับ = หัวหน้างาน · หลังกดขั้น 1 → `leave_status` = Pending HR · หลังกดขั้น 2 → `leave_status` = Approved และ `approved_at` มีค่า
  - **ทดสอบทางลบ:** สร้างใบลาที่ทับซ้อน → ต้องถูกคืนเป็น Draft พร้อม `reject_reason` (node 6) · สร้างใบลาเกินสิทธิ → ถูกคืนเป็น Draft (node 9)
  - **reset:** `delete_record` ใบลาทดสอบ · คืน `hr_leave_balance.used_days` เป็นค่าเดิม
- **Pitfall:** 🔴 ถ้า `submitted_flag` ยังว่าง (ไม่ได้ตั้ง default 0) เงื่อนไข `not equal to 1` จะไม่ผ่าน — **ต้องตั้ง default 0 และ backfill record เดิมก่อน**

---

### WF-HR-02 ตัดสิทธิลาเมื่ออนุมัติ `<TBD-WF-02>`

- **ชนิด / Surface:** `worksheet_event` (update) · **MCP**
- **Trigger:** `hr_leave_request` · `triggerFields = [leave_status]`
- **กันยิงซ้ำ:** `deducted_flag` **not equal to** 1
- **Nodes:**
  1. **Trigger by worksheet** — Trigger Field = `leave_status`
  2. **Branch** — `leave_status` equals **Approved** AND `deducted_flag` **not equal to** 1 · `overrule` → จบ
  3. **Update Record** (trigger) — `deducted_flag` = 1 (🔴 เซ็ตทันทีก่อนทำอย่างอื่น)
  4. **Get associated records** — `leave_type` → ได้ `hr_leave_type`
  5. **Branch** — node 4 › `is_paid` … (ไม่ว่าจะรับค่าจ้างหรือไม่ ก็ตัดสิทธิเหมือนกัน — branch นี้ใช้เพื่อเขียน `ledger_note` ให้ต่างกันเท่านั้น)
  6. **Query worksheet** — `hr_leave_balance` · `employee` = trigger › `employee` AND `leave_type` = trigger › `leave_type` AND `leave_year` = trigger › `leave_year`
  7. **Branch** — พบ record · `overrule` → **Create Record** `hr_leave_balance` ใหม่ (entitled 0) แล้วไปต่อ
  8. **Numerical operations** — `new_used` = node 6 › `used_days` + trigger › `leave_days` · `new_remaining` = node 6 › `total_days` − `new_used`
  9. **Update Record** (`hr_leave_balance` จาก node 6) — `used_days` = `new_used` · `remaining_days` = `new_remaining`
  10. **Create Record** — `hr_leave_ledger`: `balance` = node 6 › rowid · `employee` = trigger › `employee` · `ledger_type` = **Leave taken** · `ledger_days` = trigger › `leave_days` × (−1) · `leave_request` = trigger › rowid · `effective_date` = trigger › `leave_from` · `balance_after` = `new_remaining` · `ledger_note` = "ตัดสิทธิจากใบลา {leave_no}"
  11. **Query worksheet** — `hr_attendance` ของ `employee` ที่ `work_date` อยู่ระหว่าง `leave_from` และ `leave_to`
  12. **Sub-process (`sequential_each` บนผล node 11)** → **Update Record** `hr_attendance`: `att_status` = **On leave** · `leave_request` = trigger › rowid
  13. **Send Internal Notification** — ถึงพนักงาน "ใบลา {leave_no} ได้รับอนุมัติแล้ว สิทธิคงเหลือ {new_remaining} วัน"
- **Test recipe:** อนุมัติใบลาใน WF-HR-01 → ตรวจ `hr_leave_balance.remaining_days` ลดลงเท่ากับ `leave_days` · `hr_leave_ledger` มี record ใหม่ 1 แถวที่ `ledger_days` เป็นลบ · `hr_attendance` ของวันนั้นเปลี่ยนเป็น On leave (**AC-01 · AC-04**) · `_updatedBy` = `user-workflow`
  · **ยิงซ้ำ:** `update_record(leave_status = Approved)` อีกครั้ง → `used_days` **ต้องไม่เพิ่ม** และไม่มี ledger แถวที่สอง
- **Pitfall:** 🔴 node 3 ต้องอยู่**ก่อน** node 6–10 ทั้งหมด ไม่งั้นการยิงซ้ำระหว่างที่ flow ยังทำงานอยู่จะตัดสิทธิสองครั้ง

---

### WF-HR-03 คืนสิทธิลาเมื่อยกเลิก `<TBD-WF-03>`

- **ชนิด:** `worksheet_event` (update) · `triggerFields = [leave_status]` · **MCP**
- **Nodes:**
  1. Trigger — Trigger Field = `leave_status`
  2. **Branch** — `leave_status` equals **Cancelled** AND `deducted_flag` equals 1 AND `returned_flag` **not equal to** 1 · `overrule` → จบ
  3. **Update Record** — `returned_flag` = 1 (ทันที)
  4. **Query worksheet** — `hr_leave_balance` (เหมือน WF-HR-02 node 6)
  5. **Numerical operations** — `new_used` = `used_days` − trigger › `leave_days` · `new_remaining` = `total_days` − `new_used`
  6. **Update Record** `hr_leave_balance` — `used_days` / `remaining_days`
  7. **Create Record** `hr_leave_ledger` — `ledger_type` = **Leave returned** · `ledger_days` = `+leave_days` · `ledger_note` = "คืนสิทธิจากการยกเลิกใบลา {leave_no}"
  8. **Query worksheet** `hr_attendance` ที่ `leave_request` = trigger › rowid → **Sub-process `sequential_each`** → Update Record: `att_status` = ล้างค่า (ให้ WF-HR-05 สรุปใหม่) · `leave_request` = ล้าง · `summarised_flag` = 0
  9. **Send Internal Notification** — ถึงพนักงานและหัวหน้างาน
- **Test recipe (AC-03):** ยกเลิกใบลาที่อนุมัติแล้ว → `remaining_days` กลับเป็นค่าก่อนตัด · ledger มี 2 แถวคู่กัน (ตัด −N และคืน +N) · `hr_attendance` กลับไปรอสรุปใหม่

---

### WF-HR-04 อนุมัติใบขอล่วงเวลา 2 ระดับ `<TBD-WF-04>`

- **ชนิด:** `worksheet_event` (create + update) · `triggerFields = [ot_status]` · **MCP**
- **โครงสร้างเหมือน WF-HR-01** ทุกประการ ยกเว้น:
  - ตาราง = `hr_ot_request` · ธง = `ot_submitted_flag` · สถานะ = `ot_status`
  - **ไม่มีขั้นตรวจสิทธิคงเหลือและวันซ้อนทับ** แต่มี node เพิ่ม:
    - **Duration** — `ot_hours` = `ot_to` − `ot_from` (🔴 ใช้ node Duration ไม่มีปัญหา timezone)
    - **Query worksheet** `hr_holiday` ที่ `holiday_date` = `ot_date` → **Branch** → เขียน `day_type` เป็น Holiday within/outside hours หรือ Working day
    - **Query worksheet** `hr_ot_rate` ที่ `day_type` ตรงกัน AND `effective_from` **lte** `ot_date` AND `is_active` = จริง · **เรียง `effective_from` มาก→น้อย เอาแถวแรก** → เขียน `applied_multiplier`
  - ไม่มีขั้นผู้บริหาร
- **Test recipe:** สร้างใบขอ OT วันเสาร์ → `day_type` ต้องเป็น Holiday · `applied_multiplier` = ค่าจากตาราง `hr_ot_rate` **ไม่ใช่ค่าที่ฝังใน node** (พิสูจน์โดยแก้ตัวคูณในตารางแล้วสร้างใบใหม่ ผลต้องเปลี่ยน — **AC-19**)

---

### WF-HR-05 สรุปเวลาทำงานรายวัน — main `6a910184730d20c5b7710fa8` v1 · inner `6a910197730d20c5b7711028` v1

> 🟢🆕 **28 ส.ค. 2569 (ต่อเนื่อง 4) — สร้าง+publish จริงสำเร็จผ่าน MCP ทั้งหมด** ยืนยันการทำงานของ D-16 fix (publish inner ก่อน outer) กับ build จริงที่ไม่ใช่ minimal test — `validate_process` ทั้ง inner/outer สะอาด (issueCount:0) publish สำเร็จทั้งคู่ v1 ไม่มี error — ⚠️ **live-fire test ยังทำไม่ได้เพราะ D-17** (ดู `04-CLAUDE-memory.md`) — เมื่อ D-17 คลี่คลายแล้วให้กลับมารัน Test recipe ด้านล่างจริง
>
> **โครงสร้างจริงที่ต่างจากดราฟต์เดิม (เพราะข้อจำกัดของฟิลด์จริงที่สร้างไว้แล้ว):**
> - `hr_shift.hr_start_time`/`hr_end_time` เป็น **Text "HH:mm"** ไม่ใช่ Time/Number field ⇒ ใช้ node ชนิด **`code`** (JavaScript) แทน node `Function calculation`/`Duration` ตามดราฟต์เดิม เพื่อ parse เวลาและคำนวณ `late_minutes`/`early_leave_minutes`/`worked_hours`/`att_status` (key ของ dropdown) ในที่เดียว — ลด node ที่ต้องพึ่ง compute/branch หลายตัวซึ่งเคยมีประวัติ silent-fail (D-14) — ยังไม่ผ่าน live-test จึงมีความเสี่ยงเรื่อง timezone ที่ต้องตรวจซ้ำ (แก้ด้วยการคำนวณผ่าน epoch ms + offset +7h เอง ไม่พึ่ง runtime timezone)
> - "Get associated records employee→shift" (ขั้น a เดิม) **ตัดออก** เพราะ `hr_attendance.hr_att_shift` (กะที่ใช้) มีอยู่แล้วบนตัว record เอง — ใช้ query `hr_shift` โดยตรงผ่าน reverse-relation field (`บันทึกลงเวลา` id `6a8fcd7f353e1b0e4a507d41`) + `contains` (pattern เดียวกับที่ WF-HR-01 เคยพิสูจน์ว่าใช้ได้ — rowid+in เทียบ relation field ล้มเหลวเงียบ)
> - `hr_setting.hr_late_grace_minutes`/`hr_late_to_halfday_minutes` **query ครั้งเดียวที่ outer flow** แล้วส่งเข้า sub_process ผ่าน subprocess parameter (`process.start.inputFields` + `config.input`) แทนการ query ซ้ำทุก record — ประหยัด node/performance
> - node 2 "work_date lte วันที่เมื่อวาน" ใช้ `compute`(dateOffset, `-1d` จาก `nowTime`) มาเทียบ แทนการเขียน literal
>
> **Node alias จริง (outer):** `trigger`(schedule) → `calc_yesterday`(compute dateOffset) → `qry_setting`(get_single hr_setting) → `qry_att`(get_multiple hr_attendance) → `summarize_each`(sub_process sequential_each)
> **Node alias จริง (inner, ต่อ 1 record):** `sub_trigger` → `qry_holiday`(get_single) → `qry_leave`(get_single) → `br_holiday`(branch: `is_holiday`/`not_holiday`) → [is_holiday] `upd_holiday`(update_record) · [not_holiday] `br_leave`(branch: `on_leave`/`not_leave`) → [on_leave] `upd_leave` · [not_leave] `br_checkin`(branch: `no_checkin`/`has_checkin`) → [no_checkin] `upd_absent` · [has_checkin] `qry_shift`(get_single) → `calc_att`(code) → `upd_present`(update_record)

- **ชนิด:** `schedule` — ทุกวัน **01:00 +07:00** · **MCP** ✅ สร้างแล้ว
- **Test recipe:** seed `hr_attendance` 5 แถว (ปกติ / สาย 20 นาที / ไม่มีเวลาเข้า / วันหยุด / วันที่มีใบลาอนุมัติ) ด้วย `triggerWorkflow:false` → กด **"Execute now"** ใน Browser (หรือรอรอบ 01:00) → ตรวจว่าทั้ง 5 แถวได้ `att_status` ถูกต้องและ `_updatedBy` = `user-workflow` (**AC-04**) — **ยังไม่ได้รันเพราะ D-17**
- **Pitfall:** ⚠️ workflow แบบ `schedule` **ไม่โผล่ใน `get_workflow_list`** — ยืนยันที่หน้า Automated Workflow หรือ `get_workflow_structure(<processId>)` · ⚠️ ยังไม่ยืนยันความถูกต้องของ timezone offset ใน `calc_att` code node ด้วยข้อมูลจริง (รอ live-test)

---

### WF-HR-06 เตือนคำขอค้างอนุมัติเกิน SLA — main `6a910222730d20c5b77115e5` v1 · inner `6a9102345f8564a68c449ee7` v1

> 🟢🆕 **28 ส.ค. 2569 (ต่อเนื่อง 4) — สร้าง+publish จริงสำเร็จผ่าน MCP** validate สะอาดทั้ง inner/outer ⚠️ **live-fire test ยังทำไม่ได้เพราะ D-17**
>
> **ขอบเขต v1 — ครอบคลุมเฉพาะ `hr_leave_request`** ตัด `hr_ot_request`/`hr_claim` ออกจากรอบนี้เพราะ **`hr_ot_request` ไม่มีฟิลด์ `submitted_at`** (มีแค่ `hr_approved_at`) จึงไม่มีข้อมูลตั้งต้นที่แม่นยำพอสำหรับคำนวณ SLA ค้างอนุมัติ (`_createdAt` ระบบเป็นตัวแทนคร่าว ๆ ได้แต่ไม่ตรงความหมาย "วันที่ส่งคำขอ" เป๊ะ ถ้า Draft ค้างไว้นาน) — บันทึกเป็น **D-18** ใน `04-CLAUDE-memory.md`/`05-Roadmap-Tracker.md` ต้องตัดสินใจ (เพิ่มฟิลด์ `submitted_at` จริงใน `hr_ot_request` หรือยอมรับ `_createdAt` เป็นตัวแทน) ก่อนขยายขอบเขต — `hr_claim` ยังไม่มีตารางเลย (P6) ตัดออกเป็นธรรมชาติ
>
> **Node alias จริง (outer):** `trigger`(schedule) → `qry_setting`(get_single hr_setting) → `calc_deadline`(code: คำนวณ deadline = now − sla_days วัน) → `qry_overdue_leave`(get_multiple hr_leave_request, `leave_status in [Pending supervisor, Pending HR]` AND `submitted_at lte deadline`) → `notify_each`(sub_process sequential_each)
> **Node alias จริง (inner):** `sub_trigger` → `br_has_approver`(branch: `has_approver`/`no_approver`) → [has_approver] `notify_approver`(send_internal_notice ถึง `approver_user`, ข้อความ template อ้าง `leave_no`+`sla_days`) · [no_approver] ไม่มี node (no-op ป้องกัน error กรณี `approver_user` ว่าง)

- **ชนิด:** `schedule` — ทุกวัน **09:00 +07:00** · **MCP** ✅ สร้างแล้ว (v1 เฉพาะใบลา)
- **Test recipe (AC-14):** ตั้ง `submitted_at` ของใบลาทดสอบให้ย้อนหลังเกิน SLA → กด Execute now → ผู้อนุมัติต้องได้รับการแจ้งเตือน (ตรวจใน Workflow History + กล่องแจ้งเตือน) — **ยังไม่ได้รันเพราะ D-17**

- **ชนิด:** `schedule` — ทุกวัน **09:00 +07:00** · **MCP**
- **Nodes:**
  1. Trigger by schedule
  2. **Query worksheet** `hr_setting` → อ่าน `approval_sla_days`
  3. **Query worksheet** `hr_leave_request` ที่ `leave_status` **in** (Pending supervisor, Pending HR) AND `submitted_at` **lte** (วันนี้ − `approval_sla_days`)
  4. **Sub-process `sequential_each`** → **Send Internal Notification** ถึง `approver_user` "ใบลา {leave_no} รอการอนุมัติของท่านเกิน {approval_sla_days} วันทำการแล้ว"
  5. ทำซ้ำ node 3–4 สำหรับ `hr_ot_request` (`ot_status`) และ `hr_claim` (`claim_status`)
- **Test recipe (AC-14):** ตั้ง `submitted_at` ของใบลาทดสอบให้ย้อนหลัง 3 วัน → กด Execute now → ผู้อนุมัติต้องได้รับการแจ้งเตือน (ตรวจใน Workflow History + กล่องแจ้งเตือนของบัญชีนั้น)

---

### WF-HR-07 สร้างสลิปทั้งงวด `<TBD-WF-07>`

- **ชนิด:** `worksheet_event` (update) · `triggerFields = [period_status]` · **MCP**
- **กันยิงซ้ำ:** `generated_flag` **not equal to** 1
- **Nodes:**
  1. Trigger — `hr_pay_period` `6a8ff2878b6633ef76f1387b` · Trigger Field = `biz_period_status`
  2. **Branch** — `biz_period_status` equals **Calculating** (`d4c51a3a-2c41-4959-bd97-cac24ae9db48`) AND `biz_generated_flag` **not equal to** 1 · `overrule` → จบ
  3. **Update Record** — `biz_generated_flag` = 1 (ทันที)
  4. **Query worksheet** — `hr_employee` ที่ `emp_status` **in** (Probation, Active, On leave) AND `hire_date` **lte** trigger › `biz_period_to` AND (`termination_date` **is empty** OR `termination_date` **gte** trigger › `biz_period_from`)
  5. **Sub-process (`sequential_each`)** บนผล node 4 — ต่อพนักงาน:
     a. **Create Record** `hr_payslip` — `employee` · `pay_period` = trigger › rowid · `cost_center` = พนักงาน › `cost_center` · `payslip_status` = **Draft** · `recalc_flag` = **1** (🔴 จุดนี้จะไปยิง WF-HR-08 ต่อโดยอัตโนมัติ)
  6. **Function calculation** — นับจำนวน record จาก node 4
  7. **Update Record** — `biz_headcount` = ผลนับ
  8. **Send Internal Notification** — ถึงผู้กดปุ่ม "สร้างสลิปงวด {biz_period_name} จำนวน {biz_headcount} รายการแล้ว"
- **Test recipe:** สร้างงวดทดสอบ → กดปุ่ม "สร้างสลิปทั้งงวด" (หรือ `update_record(period_status = Calculating, triggerWorkflow:true)`) → ตรวจว่ามี `hr_payslip` เท่ากับจำนวนพนักงาน active · **ยิงซ้ำ → ต้องไม่เกิดสลิปเพิ่ม** (unique index IX-12.3 เป็นด่านที่สอง)
- **Pitfall:** ⚠️ `sub_process` โหมด `sequential_each` พิสูจน์แล้วในแอปนี้ (WF-AC-02) ⇒ ไม่ต้องใช้ node Loop และไม่ต้องเข้า Browser · ✅ ตาราง `hr_payslip` `6a904c85353e1b0e4a50ba05` สร้างครบแล้ว (P5-2, 27 ส.ค. 2569) — พร้อมประกอบ workflow นี้ได้

---

### WF-HR-08 คำนวณสลิปรายบุคคล `<TBD-WF-08>` (workflow ที่ซับซ้อนที่สุด)

- **ชนิด:** `worksheet_event` (create + update) · `triggerFields = [recalc_flag]` · **MCP**
- **Nodes:**
  1. Trigger — `hr_payslip` · Trigger Field = `recalc_flag`
  2. **Branch** — `recalc_flag` equals 1 · `overrule` → จบ
  3. **Update Record** — `recalc_flag` = 0 (รีเซ็ตทันที กันวนซ้ำ)
  4. **Get associated records** — `pay_period` → `hr_pay_period` · `employee` → `hr_employee`
  5. **ลบบรรทัดเดิม** — Query `hr_payslip_line` ที่ `payslip` = trigger › rowid → Sub-process `sequential_each` → **Delete Record** (คำนวณใหม่ = สร้างบรรทัดใหม่ทั้งหมด)
  6. **รายได้ประจำ** — Query `hr_salary_structure` `6a8ff287353e1b0e4a508550` ที่ `biz_employee` ตรงกัน AND `biz_effective_from` **lte** งวด › `biz_pay_date` AND (`biz_effective_to` **is empty** OR `biz_effective_to` **gte** งวด › `biz_pay_date`) AND `biz_is_active` = จริง → Sub-process `sequential_each` → **Create Record** `hr_payslip_line` (`pay_component` = node › `biz_pay_component` · `amount` = node › `biz_amount` · `calc_note` = "จากโครงสร้างเงินเดือนที่มีผล {biz_effective_from}")
  7. **ค่าล่วงเวลา** — Query `hr_ot_request` ที่ `employee` ตรงกัน AND `ot_status` = **Approved** AND `paid_flag` **not equal to** 1 AND `ot_date` **between** งวด › `biz_period_from` และ `biz_period_to`
     → Sub-process `sequential_each` → **Numerical operations**: `ot_amount` = (`base_salary` ÷ 30 ÷ `hr_setting.std_hours_per_day`) × `ot_hours` × `applied_multiplier`
     → **Create Record** `hr_payslip_line` (component = ค่าล่วงเวลา · `quantity` = `ot_hours` · `rate` = ตัวคูณ · `calc_note` = "จากใบขอ OT {ot_no}")
     → **Update Record** `hr_ot_request`: `paid_flag` = 1 · `pay_period` = งวด (🔴 กันคิดซ้ำข้ามงวด)
  8. **หักขาดงานและลาไม่รับค่าจ้าง** — Query `hr_attendance` ที่ `employee` ตรงกัน AND `work_date` between งวด AND `att_status` = **Absent** → นับ → `absent_days`
     · Query `hr_leave_request` ที่ Approved AND `leave_type.is_paid` = เท็จ AND ช่วงวันอยู่ในงวด → รวม `leave_days` → `unpaid_leave_days`
     · **Numerical operations** — `deduct_amount` = (`base_salary` ÷ 30) × (`absent_days` + `unpaid_leave_days`) → **Create Record** `hr_payslip_line` (component = หักขาดงาน · type = Deduction)
  9. **รวมรายได้** — Query `hr_payslip_line` ที่ `payslip` = trigger AND `pay_component.component_type` = **Earning** → **Function calculation** SUM → เขียน `total_earning`
  10. **ประกันสังคม** — Query `hr_sso_rate` ที่ `effective_from` **lte** งวด › `biz_pay_date` **เรียงมาก→น้อย เอาแถวแรก**
      · **Numerical operations** — `sso_base` = MIN(MAX(ฐานค่าจ้างที่ `is_sso_base`, `min_wage_base`), `max_wage_base`) · `sso_ee` = `sso_base` × `employee_rate_pct` · `sso_er` = `sso_base` × `employer_rate_pct`
      · **Create Record** `hr_payslip_line` × 2 (ลูกจ้างเป็น Deduction · นายจ้างเป็น Employer contribution) · `calc_note` = "อัตรา {employee_rate_pct}% ฐาน {sso_base} ตามอัตราที่มีผล {effective_from}"
  11. **ภาษีหัก ณ ที่จ่าย** —
      a. Query `hr_dependent` ที่ `employee` ตรงกัน AND `is_tax_allowance` = จริง → นับตามประเภท
      b. Query `hr_tax_allowance` ของ `tax_year` = ปีของ `biz_pay_date` → **Numerical operations** รวมค่าลดหย่อนทั้งหมด (รวมค่าใช้จ่าย 50% ไม่เกินเพดาน + ลดหย่อนส่วนตัว + คู่สมรส + บุตร + ประกันสังคมที่จ่ายทั้งปี)
      c. **Numerical operations** — `annual_income` = (`total_earning` − OT ที่ไม่ประจำ) × จำนวนงวดที่เหลือ + รายได้สะสม `ytd_income` (วิธีประมาณการทั้งปี A-HR-11)
      d. Query `hr_tax_bracket` ของปีภาษี **เรียงตาม `bracket_order`** → Sub-process `sequential_each` → คำนวณภาษีสะสมตามขั้นบันได
      e. **Numerical operations** — `wht_amount` = (ภาษีทั้งปี − `ytd_wht`) ÷ จำนวนงวดที่เหลือ
      f. **Create Record** `hr_payslip_line` (component = ภาษีหัก ณ ที่จ่าย · Deduction) · `calc_note` = "ประมาณการเงินได้ทั้งปี {annual_income} ภาษีทั้งปี {annual_tax} หักสะสมแล้ว {ytd_wht}"
  12. **รวมรายหักและยอดสุทธิ** — Query บรรทัดที่ type = **Deduction** → SUM → `total_deduction` · **Numerical operations** `net_pay` = `total_earning` − `total_deduction`
  13. **Update Record** (สลิป) — `base_salary` · `worked_days` · `absent_days` · `unpaid_leave_days` · `ot_hours_15/10/30` · `total_earning` · `total_deduction` · `net_pay` · `sso_ee` · `sso_er` · `wht_amount` · `ytd_income` · `ytd_wht` · `payslip_status` = **Calculated** · `calculated_flag` = 1 · `calculated_at` = System › Current time
- **Test recipe (AC-06 · AC-05 · AC-19):**
  - seed พนักงานทดสอบ 3 คน: (ก) เงินเดือนอย่างเดียว (ข) เงินเดือน + OT ที่อนุมัติ 1 ใบ + OT ที่ยังไม่อนุมัติ 1 ใบ (ค) เงินเดือน + ขาดงาน 2 วัน + ลาไม่รับค่าจ้าง 1 วัน
  - ยิง: `update_record(hr_payslip, {recalc_flag: 1}, triggerWorkflow:true)`
  - คาด: ทุกยอดตรงกับกระดาษคำนวณที่เตรียมไว้ 100% · คนที่ (ข) ต้องมีบรรทัด OT **ใบเดียว** · ทุกบรรทัดมี `calc_note` ที่อธิบายที่มา · `_updatedBy` = `user-workflow`
  - **ทดสอบ AC-19:** แก้ `employee_rate_pct` ในตาราง `hr_sso_rate` แล้วสร้าง record อัตราใหม่ที่ `effective_from` ใหม่ → กดคำนวณใหม่ → ยอด `sso_ee` ต้องเปลี่ยนโดย**ไม่ได้แก้ workflow เลย**
  - reset: ลบสลิปทดสอบ · คืน `paid_flag` ของใบ OT เป็น 0
- **Pitfall:** 🔴 node 5 (ลบบรรทัดเดิม) สำคัญมาก — ถ้าไม่ลบ การกดคำนวณใหม่จะทำให้บรรทัดซ้อนกันและยอดคูณสอง
  🔴 `paid_flag` ของใบ OT ต้องเซ็ตใน node 7 ไม่ใช่ตอนจบ ไม่งั้นการคำนวณใหม่ในงวดเดิมจะข้าม OT ไป · ✅ ตาราง `hr_payslip`/`hr_payslip_line` สร้างครบแล้ว (P5-2, 27 ส.ค. 2569) — พร้อมประกอบ workflow นี้ได้

---

### WF-HR-09 อนุมัติงวดจ่ายเงินเดือน `<TBD-WF-09>`

- **ชนิด:** `worksheet_event` (update) · `triggerFields = [period_status]` · **MCP**
- **Nodes:**
  1. Trigger — `hr_pay_period` `6a8ff2878b6633ef76f1387b`
  2. **Branch** — `biz_period_status` equals **Pending approval** (`4b772a20-1b19-4f49-b635-f4b809e97b1b`) AND `biz_pp_submitted_flag` **not equal to** 1 · `overrule` → จบ
  3. **Query worksheet** — `hr_payslip` ที่ `pay_period` = trigger AND `payslip_status` = **Draft** → **Branch** พบ > 0 → Update Record คืน `biz_period_status` = Calculating + แจ้งเตือน "ยังมีสลิปที่ยังไม่ได้คำนวณ {n} รายการ" → จบ
  4. **Query worksheet** — `hr_payslip` ที่ `pay_period` = trigger → **Function calculation** SUM → `total_earning` / `total_deduction` / `total_net` / `total_sso_ee` / `total_sso_er` / `total_wht`
  5. **`get_single`** — `hr_approval_rule` `6a8eebf81378964f998499f8` ที่ `hr_doc_kind` = **Payroll period** (`0f03c028-ef9c-4eee-9611-bd3d62d0c831`) AND `hr_rule_is_active` = จริง (🔴 ภายในสายอนุมัติ)
  6. **Update Record** — `biz_pp_submitted_flag` = 1 · ยอดรวมทั้ง 6 ตัว (`biz_total_earning` / `biz_total_deduction` / `biz_total_net` / `biz_total_sso_ee` / `biz_total_sso_er` / `biz_total_wht`)
  7. **Initiate Approval Flow** — To-do title = "งวดจ่าย {biz_period_name} ยอดสุทธิ {biz_total_net} รออนุมัติ"
  8. **Approve** — Approver อ้าง `{kind:"field", node:<node 5>, fieldId:<hr_approver_role 6a8eec6e8b6633ef76f12a56>}` · empty policy = Delegate by the workflow owner
     · **Data Update › after approves:** `biz_period_status` = **Approved** (`3c7aa8cd-6a7c-446a-9d9e-b123dbc1cbd9`) · `biz_approved_at` = System › Current time
     · **Data Update › when rejects:** `biz_period_status` = **Calculating**
  9. **Branch `approval_result`** — `pass` → Sub-process `sequential_each` บนสลิปทั้งงวด → Update `payslip_status` = **Approved** · `overrule` → แจ้งเตือน Payroll
  10. **Send Internal Notification** — ถึง Payroll และ HR Manager
- **Test recipe:** ต้องมีสลิปที่ Calculated ครบก่อน → กดปุ่ม "ส่งงวดจ่ายให้อนุมัติ" → HR Manager กดใน To-do → `biz_period_status` = Approved และสลิปทุกใบเป็น Approved

---

### WF-HR-10 ผ่านรายการเงินเดือนเข้าบัญชี `<TBD-WF-10>` 🔴 จุดเชื่อมกับโมดูลบัญชี

- **ชนิด:** `worksheet_event` (update) · `triggerFields = [post_flag]` · **MCP**
- **Nodes:**
  1. Trigger — `hr_pay_period` `6a8ff2878b6633ef76f1387b` · Trigger Field = `biz_post_flag`
  2. **Branch** — `biz_post_flag` equals 1 AND `biz_period_status` equals **Approved** AND `biz_voucher_ref` **is empty** · `overrule` → จบ (🔴 **AC-08** สามชั้น: ธง + สถานะ + ตรวจว่ายังไม่มีใบสำคัญ)
  3. **Get associated records** — `biz_ac_period_ref` → `ac_period` `6a8434d5055f2288c5b6d4b8`
  4. **Branch (ตรวจงวดบัญชี)** — node 3 › `period_status` `6a851f70055f2288c5b73edf` equals key **`f662571c-3de0-4e4c-9828-9172e337d223`** (Open) · `overrule` → Update Record `biz_post_flag` = 0 + แจ้งเตือน "งวดบัญชีปิดแล้ว ไม่สามารถผ่านรายการได้" → จบ
  5. **Query worksheet** — `ac_posting_rule` `6a85518c33560633b8cd6a15` ที่ `event_code` `6a85518c055f2288c5b7430b` = **`PAYROLL_ACCRUAL`** (✅ option พร้อมใช้แล้ว — Gap G-02 ปิด 28 ส.ค. 2569 ต่อเนื่อง 6, key `ad4850c4-f1c1-4a65-adbb-fb0054a6e0c8`) AND `is_active` `6a85e6b09b6999a714d2a409` = จริง AND `effective_from` **lte** `biz_pay_date` — ✅ **ยืนยันโดยฝ่ายบัญชีว่านี่คือ source-of-truth หลักของรหัสบัญชี** `hr_pay_component.biz_coa_account` เป็นแค่ fallback เมื่อไม่พบกฎที่ตรงเงื่อนไข (ไม่ใช่ตรงกันข้าม)
  6. **Branch** — พบกฎ · `overrule` → แจ้งเตือน "ไม่พบกฎการผ่านรายการของเงินเดือน" → `biz_post_flag` = 0 → จบ (🔴 **ห้าม fallback ไปใช้รหัสบัญชีที่ฝังใน node**)
  7. **Create Record** — `ac_voucher` `6a85fb2e9b6999a714d2a53d`:
     - `description` `6a85fb2e055f2288c5b77753` = "บันทึกค่าใช้จ่ายเงินเดือน งวด {biz_period_name}"
     - `voucher_date` `6a85fb2e055f2288c5b77754` = trigger › `biz_pay_date`
     - `journal` `6a85fb2e055f2288c5b77755` = สมุดรายวันทั่วไป (จาก `hr_setting` หรือ Query `ac_journal`)
     - `voucher_type` `6a85fb2e055f2288c5b77757` = ประเภทเอกสารเงินเดือน (Query `ac_doc_type`)
     - `period` `6a85fb2e055f2288c5b77759` = node 3 › rowid
     - `currency` `6a85fb2e055f2288c5b7775b` = บาท (Query `ac_currency`)
     - `source_doc_id` `6a85fb2e055f2288c5b7775e` = trigger › `biz_period_name`
     - **`source_module` `6a86021833560633b8cd9fb1` = key `914f5226-dc4c-4572-bd4d-18bb278414b5` (Payroll)** 🔴 **จำเป็น** เพราะ `source_doc_type` ยังไม่มีค่าสำหรับ HR (Gap G-01)
     - `voucher_status` `6a86016b1049edca1eed028a` = key `3536165d-460c-4942-8bec-6f381209d8da` (Draft)
  8. **Create Record** — `ac_voucher_line` `6a85fb3933560633b8cd9f40` × N บรรทัด · ทุกบรรทัด `voucher` `6a85fb399b6999a714d2a557` = node 7 › rowid
     | บรรทัด | `account` `…a559` | `debit` `…a55b` | `credit` `…a55c` | `cost_center` `…a55d` |
     |---|---|---|---|---|
     | 1 | node 5 › `debit_account` (ค่าใช้จ่ายเงินเดือน) | `biz_total_earning` | — | ต่อศูนย์ต้นทุน |
     | 2 | บัญชีเจ้าหนี้เงินเดือน (จากกฎ `credit_account`) | — | `biz_total_net` | — |
     | 3 | บัญชีประกันสังคมค้างจ่าย (กฎแยก event) | — | `biz_total_sso_ee` + `biz_total_sso_er` | — |
     | 4 | บัญชีภาษีหัก ณ ที่จ่ายค้างจ่าย | — | `biz_total_wht` | — |
     | 5 | ค่าใช้จ่ายเงินสมทบนายจ้าง | `biz_total_sso_er` | — | ต่อศูนย์ต้นทุน |
     > 🔴 รหัสบัญชีทุกบรรทัด**ต้องมาจาก `ac_posting_rule` เท่านั้น** (BR-09 · **AC-07**)
     > 💡 ถ้าต้องแยกตามศูนย์ต้นทุน ให้ Query `hr_payslip` group by `cost_center` แล้ว Sub-process `sequential_each` สร้างบรรทัดเดบิตต่อศูนย์ต้นทุน
  9. **Function calculation** — ตรวจดุล: SUM(debit) − SUM(credit) ต้องเป็น 0 · **Branch** ไม่เป็น 0 → ลบใบสำคัญที่สร้าง + แจ้งเตือน + `biz_post_flag` = 0 → จบ
  10. **Update Record** (trigger) — `biz_voucher_ref` = node 7 › rowid · `biz_period_status` = **Posted** (`a40f98e5-d1a8-408c-a0a5-03c4eeafe5e8`)
  11. **Send Internal Notification** — ถึงฝ่ายบัญชีและ HR Manager "ใบสำคัญเงินเดือน {voucher_no} สร้างแล้ว รอการอนุมัติในโมดูลบัญชี"
- **Test recipe (AC-07 · AC-08):**
  - ยิง: `update_record(hr_pay_period, {biz_post_flag: 1}, triggerWorkflow:true)`
  - คาด: เกิด `ac_voucher` 1 ใบ · `source_module` = Payroll key · `total_debit` = `total_credit` (ดูฟิลด์ Rollup `6a8603f4055f2288c5b777d2` / `6a8604c08b36df988c176286`) · `balance_diff` `6a860ae8055f2288c5b777f1` = 0 · `hr_pay_period.biz_voucher_ref` มีค่า · `_updatedBy` = `user-workflow`
  - **ยิงซ้ำ:** `update_record(post_flag: 1)` อีกครั้ง → **ต้องไม่เกิดใบสำคัญที่สอง** (node 2 ตรวจ `voucher_ref` is empty)
  - reset: ลบ `ac_voucher_line` แล้วลบ `ac_voucher` · ล้าง `biz_voucher_ref` · `biz_post_flag` = 0 · `biz_period_status` = Approved
- **Pitfall:**
  ✅ **Gap G-02 ปิดแล้ว 28 ส.ค. 2569 (ต่อเนื่อง 6)** — `event_code` = `PAYROLL_ACCRUAL`/`PAYROLL_PAYMENT` มีแล้ว (ฝ่ายบัญชีเพิ่มให้ผ่าน MCP) — ยังต้องสร้าง `ac_posting_rule` จริง (P5-5) ก่อน node 5 จะ query เจอกฎ
  ⚠️ **`_updatedAt` ของใบสำคัญไม่ขยับเมื่อ Rollup คำนวณใหม่** — ห้ามใช้ `_updatedAt` จับการเปลี่ยนแปลงของยอดรวม
  🔴 `ac_voucher` มีฟิลด์ required 5 ตัว (`description` `voucher_date` `journal` `voucher_type` `period` `currency`) — ขาดตัวใดตัวหนึ่ง Create Record จะล้มเงียบ

---

### WF-HR-11 อนุมัติใบเบิกสวัสดิการ 2 ระดับ + ตัดวงเงิน `<TBD-WF-11>`

- **ชนิด:** `worksheet_event` (create + update) · `triggerFields = [claim_status]` · **MCP**
- **โครงสร้างอนุมัติเหมือน WF-HR-01** (ธง `claim_submitted_flag` · สถานะ `claim_status` · `approver_user` จาก `employee.supervisor_user`) พร้อมส่วนเพิ่ม:
  - **ก่อน Initiate Approval:** Query `hr_welfare_balance` ที่ (`employee`, `welfare_scheme`, `benefit_year`) → **Branch** `remaining_amount` **gte** `claim_amount` · `overrule` → คืน Draft + `reject_reason` = "จำนวนเงินเกินวงเงินคงเหลือ" → จบ (ด่านที่สองหลัง BR-19.1)
  - **หลัง Approve ขั้นที่ 2 (`approval_result` = `pass`):**
    1. **Branch** — `deducted_flag` **not equal to** 1 · `overrule` → ข้าม
    2. **Update Record** (trigger) — `deducted_flag` = 1
    3. **Numerical operations** — `new_used` = `used_amount` + `claim_amount` · `new_remaining` = `entitled_amount` − `new_used`
    4. **Update Record** `hr_welfare_balance` — `used_amount` · `remaining_amount`
    5. **Send Internal Notification** — ถึงพนักงาน "ใบเบิก {claim_no} อนุมัติแล้ว วงเงินคงเหลือ {new_remaining} บาท"
- **Test recipe (AC-10 ส่วนแรก):** ยื่นใบเบิกเกินวงเงิน → ถูกบล็อกที่กฎฟอร์ม · ยื่นใบที่พอดี → อนุมัติ 2 ขั้น → `remaining_amount` ลดลงเท่ากับ `claim_amount` · ยิงซ้ำต้องไม่ตัดซ้ำ

---

### WF-HR-12 ส่งใบเบิกเข้าใบขออนุมัติเบิกจ่าย `<TBD-WF-12>` 🔴 จุดเชื่อมกับโมดูลบัญชี

- **ชนิด:** `worksheet_event` (update) · `triggerFields = [claim_status]` · **MCP**
- **Nodes:**
  1. Trigger — `hr_claim`
  2. **Branch** — `claim_status` equals **Approved** AND `sent_to_ac_flag` **not equal to** 1 AND `pay_req_ref` **is empty** · `overrule` → จบ
  3. **Update Record** — `sent_to_ac_flag` = 1
  4. **Get associated records** — `employee` → `hr_employee` · `welfare_scheme` → `hr_welfare_scheme`
  5. **Create Record** — `ac_pay_req` `6a8677b19b6999a714d2aa83`:
     - `request_reason` `6a8677b18b36df988c176cb2` = "เบิก{scheme_name} ของ {employee} ตามใบเบิก {claim_no}"
     - `requester` `6a8677b18b36df988c176cb3` = node 4 › `emp_user` (Collaborator)
     - `required_pay_date` `6a8677b18b36df988c176cb7` = วันที่ตามนโยบาย (เช่น +7 วันจากวันอนุมัติ)
     - `biz_preq_amount` `6a8ead839762533b5b717036` = trigger › `claim_amount`
     - `biz_preq_status` `6a8ec5be353e1b0e4a506d75` = key **`08092993-906a-4956-b0ff-6f91f766fe61`** (Draft)
     - `biz_preq_doc_type` `6a8ead839762533b5b71703b` = ประเภทเอกสารเบิกสวัสดิการ (Query `ac_doc_type` `6a8434dd9b6999a714d22e3d`)
  6. **Update Record** (trigger) — `pay_req_ref` = node 5 › rowid
  7. **Send Internal Notification** — ถึงฝ่ายการเงิน "มีใบขออนุมัติเบิกจ่ายใหม่จากโมดูลบุคคล จำนวน {claim_amount} บาท"
- **Test recipe (AC-10 ส่วนหลัง):** อนุมัติใบเบิก → เกิด `ac_pay_req` 1 ใบที่ยอดตรงกัน · `hr_claim.pay_req_ref` มีค่า · **ยิงซ้ำต้องไม่เกิดใบที่สอง**
- **Pitfall:** ⚠️ `ac_pay_req.request_reason` เป็น required — ขาดแล้ว Create Record ล้มเงียบ

---

### WF-HR-13 เตือนสัญญาจ้าง/ทดลองงานใกล้ครบกำหนด `<TBD-WF-13>`

- **ชนิด:** `date_field` · **MCP** — ⚠️ **ต้องสร้าง 2 workflow แยก** เพราะ trigger ผูกกับฟิลด์วันที่คนละตาราง
  - **13A:** `hr_employment_contract.contract_to` · **30 วันก่อนวันที่** · 09:00 +07:00
  - **13B:** `hr_employee.probation_end_date` · **14 วันก่อนวันที่** · 09:00 +07:00
- **Nodes (13A):**
  1. Trigger by date field — `contract_to` · ก่อน 30 วัน
  2. **Branch** — `contract_status` equals **Active** AND `expiry_alert_flag` **not equal to** 1 · `overrule` → จบ
  3. **Update Record** — `expiry_alert_flag` = 1 · `contract_status` = **Expiring soon**
  4. **Get associated records** — `employee` → `hr_employee`
  5. **Send Internal Notification** — ถึง node 4 › `supervisor_user` และ HR "สัญญาจ้างของ {employee} เลขที่ {contract_no} จะครบกำหนดวันที่ {contract_to}"
- **Nodes (13B):** เหมือนกัน แต่ธง = `probation_alert_flag` · ผู้รับ = `supervisor_user` + HR · ข้อความเรื่องการประเมินผลทดลองงาน
- **Test recipe:** ตั้ง `contract_to` = วันนี้ + 30 วัน → รอรอบ หรือกด Execute now → ผู้รับได้รับแจ้งเตือน · `contract_status` = Expiring soon · `_updatedBy` = `user-workflow`
- **Pitfall:** ⚠️ workflow ชนิด date field **ยิงตามรอบเวลา ไม่ยิงทันที** — อย่าสรุปว่าพังเพราะไม่เห็นผลทันที

---

### WF-HR-14 ยกยอดสิทธิลาต้นปี `<TBD-WF-14>`

- **ชนิด:** `schedule` — **1 มกราคม 00:30 +07:00** ทุกปี · **MCP**
- **Nodes:**
  1. Trigger by schedule
  2. **Query worksheet** — `hr_employee` ที่ `emp_status` **in** (Probation, Active, On leave)
  3. **Sub-process (`sequential_each`)** ต่อพนักงาน:
     a. **Query worksheet** — `hr_leave_type` ที่ `is_active` = จริง
     b. **Sub-process (`sequential_each`)** ต่อประเภทการลา:
        - **Duration / Function calculation** — `service_months` = เดือนตั้งแต่ `hire_date` ถึงวันนี้
        - **Query worksheet** — `hr_leave_policy` ที่ `leave_type` ตรงกัน AND (`job_level` = พนักงาน › `job_level` OR `job_level` **is empty**) AND `min_service_months` **lte** `service_months` AND (`max_service_months` **is empty** OR `max_service_months` **gte** `service_months`) AND `effective_from` **lte** วันนี้ · 🔴 **เรียงตาม `min_service_months` มาก→น้อย แล้วเอาแถวแรก**
        - **Query worksheet** — `hr_leave_balance` ของปีที่แล้ว → **Branch** ตาม `leave_type.carry_policy`:
          · **No carry forward** → `carry` = 0
          · **Carry all** → `carry` = ปีก่อน › `remaining_days`
          · **Carry up to cap** → `carry` = MIN(ปีก่อน › `remaining_days`, `leave_type.carry_cap_days`)
        - **Create Record** `hr_leave_balance` ปีใหม่ — `entitled_days` = นโยบาย › `entitlement_days` · `carried_days` = `carry` · `total_days` = ผลรวม · `used_days` = 0 · `remaining_days` = `total_days`
        - **Create Record** `hr_leave_ledger` × 2 — (1) `ledger_type` = **Annual grant** `ledger_days` = `entitled_days` · (2) `ledger_type` = **Carry forward** `ledger_days` = `carry` (สร้างเฉพาะเมื่อ > 0)
  4. **Send Internal Notification** — ถึง HR "ยกยอดสิทธิลาปี {year} เสร็จสิ้น จำนวน {n} พนักงาน"
- **Test recipe (AC-20):** ทดสอบด้วย **Execute now** (ไม่ต้องรอ 1 ม.ค.) → ตรวจว่าพนักงานทดสอบทุกคนมี `hr_leave_balance` ปีใหม่ครบทุกประเภทที่ active · ลาพักผ่อนยกยอดไม่เกิน `carry_cap_days` · ลาป่วยยกยอด 0 · ledger มีคู่กันทุกแถว
- **Pitfall:** 🔴 ถ้ามีนโยบายซ้อนทับช่วงอายุงาน ต้องเรียงและเอาแถวแรกเสมอ ไม่งั้นพนักงานจะได้สิทธิผิด · ⚠️ ควรรัน Backup ก่อนกด Execute now ในระบบจริง

---

### WF-HR-15 อนุมัติใบขออัตรากำลัง `<TBD-WF-15>`
- **ชนิด:** `worksheet_event` (update) · `triggerFields = [req_status]` · **MCP**
- **โครงสร้างเหมือน WF-HR-01** แต่ผู้อนุมัติขั้นที่ 1 = หัวหน้าหน่วยงานที่ขอ (จาก `cost_center`) · ขั้นที่ 2 = HR Manager (จาก `hr_approval_rule`) · ไม่มีการตัดสิทธิใด ๆ
- **หลังอนุมัติ:** Update `req_status` = Approved → Send Internal Notification ถึงทีมสรรหา
- **Test recipe:** อนุมัติ 2 ขั้น → `req_status` = Approved · `get_approval_list_by_row` มี 2 instance

### WF-HR-16 เลื่อนสถานะผู้สมัครและแจ้งนัดสัมภาษณ์ `<TBD-WF-16>`
- **ชนิด:** `worksheet_event` (update) · `triggerFields = [stage]` · **MCP**
- **Nodes:** Trigger → Branch (`stage` เปลี่ยน) → Update `stage_changed_at` → **Branch** `stage` **in** (Interview 1, Interview 2) → Query `hr_interview` ของผู้สมัครที่ `notified_flag` **not equal to** 1 → Sub-process → Send Internal Notification ถึง `interviewers` + Update `notified_flag` = 1
- **Test recipe:** เปลี่ยน `stage` เป็น Interview 1 → กรรมการสัมภาษณ์ได้รับแจ้งเตือน 1 ครั้ง (ยิงซ้ำต้องไม่แจ้งซ้ำ)

### WF-HR-17 สร้างทะเบียนพนักงานจากผู้สมัครที่ถูกจ้าง `<TBD-WF-17>`
- **ชนิด:** `worksheet_event` (update) · `triggerFields = [stage]` · **MCP**
- **Nodes:**
  1. Trigger — `hr_candidate`
  2. **Branch** — `stage` equals **Hired** AND `hire_flag` **not equal to** 1 AND `hired_employee` **is empty** · `overrule` → จบ
  3. **Update Record** — `hire_flag` = 1
  4. **Create Record** `hr_employee` — คัดลอก `candidate_name` → `first_name_th`/`last_name_th` · `candidate_national_id` → `national_id` · `birth_date` · `email` · `mobile` · `position` = `applied_position` · `emp_status` = **Probation** · `hire_date` = วันนี้ (หรือวันที่ตกลง) · `emp_code` = จากกฎการออกเลขที่
     > ⚠️ `emp_user` (Collaborator) **ต้องกรอกด้วยมือภายหลัง** — workflow หา userId จากชื่อไม่ได้ (tool `find_member` ถูกถอดออกจาก connector แล้ว)
  5. **Update Record** (trigger) — `hired_employee` = node 4 › rowid
  6. **Update Record** `hr_job_requisition` — `filled_count` + 1
  7. **Send Internal Notification** — ถึง HR "สร้างทะเบียนพนักงาน {emp_code} แล้ว 🔴 กรุณาผูกบัญชีผู้ใช้ในระบบและตั้งค่าโครงสร้างเงินเดือน"
- **Test recipe (AC-17):** เปลี่ยน `stage` = Hired → เกิด `hr_employee` 1 record ที่ข้อมูลตรงกับผู้สมัคร · ยิงซ้ำต้องไม่เกิด record ที่สอง
- **Pitfall:** 🔴 `emp_user` และ `supervisor_user` ว่างตอนสร้าง ⇒ พนักงานใหม่ยังยื่นใบลาไม่ได้จนกว่า HR จะกรอก — การแจ้งเตือนใน node 7 จึงจำเป็น

### WF-HR-18 เปิดรอบประเมิน — สร้างแบบประเมินทุกคน `<TBD-WF-18>`
- **ชนิด:** `worksheet_event` (update) · `triggerFields = [cycle_open_flag]` · **MCP**
- **Nodes:** Trigger → Branch (`cycle_open_flag` = 1 AND `generated_count` = 0) → Query `hr_employee` (active AND `hire_date` **lte** `period_from`) → **Sub-process `sequential_each`** → Create Record `hr_appraisal` (`cycle` · `employee` · `supervisor_user` = พนักงาน › `supervisor_user` · `appraisal_status` = **Self assessment**) → นับ → Update `generated_count` → Send Internal Notification ถึงพนักงานทุกคน
- **Test recipe:** เปิดรอบ → มี `hr_appraisal` เท่ากับจำนวนพนักงาน · unique index (`cycle`,`employee`) กันซ้ำเป็นด่านที่สอง

### WF-HR-19 เดินสถานะแบบประเมิน 3 ขั้น `<TBD-WF-19>`
- **ชนิด:** `worksheet_event` (update) · `triggerFields = [appraisal_status]` · **MCP**
- **Nodes:** Trigger → Branch ตามสถานะปัจจุบัน:
  - **Self assessment → Supervisor review:** ตรวจว่า `self_score` มีค่า → Update `submitted_at` → Send Notification ถึง `supervisor_user`
  - **Supervisor review → HR review:** ตรวจ `supervisor_score` มีค่า → Numerical operations `final_score` = ค่าเฉลี่ยถ่วงน้ำหนักจาก `hr_appraisal_item` → Send Notification ถึง HR
  - **HR review → Completed:** Update `completed_at` = System › Current time → Send Notification ถึงพนักงานและหัวหน้า
- **Test recipe:** เดินครบ 3 ขั้นด้วยบัญชีทดสอบคนละบทบาท → `final_score` คำนวณถูกต้องตาม `weight_pct` · `appraisal_status` = Completed และฟอร์มถูกล็อก (BR-22.1)

### WF-HR-20 ออกหนังสือรับรองการหักภาษีประจำปี `<TBD-WF-20>`
- **ชนิด:** `worksheet_event` (update) · `triggerFields = [issue_cert_flag]` · **MCP**
- **Nodes:** Trigger `hr_pnd1_filing` → Branch (`issue_cert_flag` = 1 AND `form_type` = P.N.D.1 Kor AND `filing_status` = Filed) → Query `hr_payslip` ที่ `pay_period.period_year` = `tax_year` AND `payslip_status` **in** (Approved, Published) → **จัดกลุ่มตาม `employee`** → Sub-process `sequential_each` → Function calculation SUM(`total_earning`) และ SUM(`wht_amount`) → Create Record `hr_wht_cert` (`employee` · `tax_year` · `total_income` · `total_wht` · `payee_legal_form` = key `1aeb1a04-1957-4905-92d9-c506d8bbdccc` (Individual) · `cert_status` = **Issued** · `issue_date` = วันนี้) → Update `issue_cert_flag` = 0 → Send Notification
- **Test recipe:** ยิงกับปีทดสอบที่มีสลิป 3 งวด → เกิด `hr_wht_cert` 1 ใบต่อพนักงาน · `total_wht` = ผลรวมของ 3 งวด · ยิงซ้ำต้องไม่เกิดใบที่สอง (unique index IX-12.6)

---

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
