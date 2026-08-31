# Workflow Catalog — โมดูล HR (TILSNA ERP)

_แยกออกจาก `02-BuildSpec-FRS.md` เมื่อ 31 ส.ค. 2569 — **เนื้อหาเหมือนเดิมทุกตัวอักษร ไม่ได้ตัดอะไรทิ้ง**_

> **ทำไมแยก:** `02-BuildSpec-FRS.md` โตถึง 276,580 bytes (~37,075 tokens) ซึ่ง **เกินเพดาน Read 25,000 tokens** ⇒ agent อ่านไฟล์ที่ §0 ของมันเองสั่งให้ "เปิดทุกครั้งก่อนแตะ object ใด ๆ" ไม่จบใน 1 call
> แบ่งตามหลัก **"อะไรที่ต้องเปิดพร้อมกัน"**: §0 กฎ + §1 ID Registry + §4–§6 = แกนที่ต้องเปิดทุกครั้ง (อยู่ใน `02-`) · ส่วนสเปกราย FR และ Workflow Catalog เป็นการ **เปิดหาเฉพาะตัวที่กำลังทำ** จึงแยกออกมา

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
