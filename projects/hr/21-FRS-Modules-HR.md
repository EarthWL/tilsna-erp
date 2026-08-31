# สเปกรายโมดูล (FR-HR-xx) — โมดูล HR (TILSNA ERP)

_แยกออกจาก `02-BuildSpec-FRS.md` เมื่อ 31 ส.ค. 2569 — **เนื้อหาเหมือนเดิมทุกตัวอักษร ไม่ได้ตัดอะไรทิ้ง**_

> **ทำไมแยก:** `02-BuildSpec-FRS.md` โตถึง 276,580 bytes (~37,075 tokens) ซึ่ง **เกินเพดาน Read 25,000 tokens** ⇒ agent อ่านไฟล์ที่ §0 ของมันเองสั่งให้ "เปิดทุกครั้งก่อนแตะ object ใด ๆ" ไม่จบใน 1 call
> แบ่งตามหลัก **"อะไรที่ต้องเปิดพร้อมกัน"**: §0 กฎ + §1 ID Registry + §4–§6 = แกนที่ต้องเปิดทุกครั้ง (อยู่ใน `02-`) · ส่วนสเปกราย FR และ Workflow Catalog เป็นการ **เปิดหาเฉพาะตัวที่กำลังทำ** จึงแยกออกมา

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
**Definition of Done:** AC-01 AC-02 AC-03 ผ่านครบ · `get_record_details(includeSystemFields:true)` → `_updatedBy` = `user-workflow` (และ `_processName`/`_processStatus` มีค่าเมื่อเข้าสายอนุมัติ) · `get_approval_list_by_row` มี instance ทั้ง 2 ขั้น · 🔴 **ห้ามใช้ operator ใน `get_record_logs` เป็นเกณฑ์ผ่าน — ให้ผลลบลวง** เพราะการเขียนฟิลด์ธุรกิจโดย node ของ workflow ถูกบันทึกเป็น `user-api` ([V] 28 ส.ค. 2569 — ดู Known Issues ใน `04-CLAUDE-memory.md`)
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
