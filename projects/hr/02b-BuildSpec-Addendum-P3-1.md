# BuildSpec Addendum — P3-1 (hr_leave_request / hr_leave_balance / hr_leave_ledger)

> **นี่คือไฟล์เสริม (addendum) ของ `02-BuildSpec-FRS.md`** — สร้างแยกต่างหากแทนการเขียนทับไฟล์หลัก (ซึ่งมีขนาดใหญ่มาก) เพื่อลดความเสี่ยงการพิมพ์เนื้อหาเดิมผิดพลาดระหว่างแก้ไข
> **การใช้งาน:** เปิดไฟล์นี้คู่กับ `02-BuildSpec-FRS.md` และ `21-FRS-Modules-HR.md` (สเปกราย FR เดิม §2 — แยกออกมา 31 ส.ค. 2569) เสมอ — เนื้อหาที่นี่ **override** ค่า `<TBD>` ในแถว #20–22 ของ §1.3 และฟิลด์ทั้งหมดของ FR-HR-08 / FR-HR-09 ในไฟล์หลัก ส่วนที่เหลือของไฟล์หลัก (§0, §1.1–1.2, §1.4–1.12, §2 ของ FR อื่น ๆ, §3–§6) ยังใช้ได้ตามเดิมทั้งหมด ไม่มีการเปลี่ยนแปลง
> อัปเดต: 26 สิงหาคม 2569 — P3-1: สร้าง `hr_leave_balance` / `hr_leave_request` / `hr_leave_ledger` สำเร็จแล้ว (โครงสร้างฟิลด์ครบ ยังไม่ seed/ยังไม่ตั้ง form rules)

### §1.3 (แก้ไข) Worksheets แถว 20–22 — สร้างจริงแล้ว 26 ส.ค. 2569

| # | Worksheet (ไทย) | alias | Worksheet ID | View "ทั้งหมด" | กลุ่ม |
|---|---|---|---|---|---|
| 20 | **ใบลา** | `hr_leave_request` | `6a8f2dbaae2a0e3743a0beaa` ✅ | `6a8f2dbaae2a0e3743a0beae` | HR-03 ✅ |
| 21 | สิทธิและยอดคงเหลือการลา | `hr_leave_balance` | `6a8f2dba353e1b0e4a507757` ✅ | `6a8f2dba353e1b0e4a50775b` | HR-03 ✅ |
| 22 | รายการเคลื่อนไหวสิทธิลา | `hr_leave_ledger` | `6a8f2dba9762533b5b718675` ✅ | `6a8f2dba9762533b5b718679` | HR-03 ✅ |

สร้างผ่านทางเลือกสำรอง `create_app_items` → `get_worksheet_structure` → `update_worksheet.removeFields` (ลบ 3 field default) → `update_worksheet.addFields` (removeFields + addFields ส่งในคำสั่ง `update_worksheet` เดียวกันได้ — ทดสอบแล้วใช้ได้ปกติ ไม่ต้องแยก 2 คำสั่งเหมือนที่เข้าใจไว้เดิม) → `get_worksheet_structure` verify ครบทั้ง 3 ตาราง

### FR-HR-09 (แก้ไข ID จริง) สิทธิและยอดคงเหลือการลา

**9A. สิทธิและยอดคงเหลือ** `hr_leave_balance` `6a8f2dba353e1b0e4a507757` ✅ สร้างจริงแล้ว 26 ส.ค. 2569

| ฟิลด์ | alias | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| ชื่อรายการ | `balance_name` | `6a8f2e129762533b5b71867f` | `Text` | isTitle · required | |
| พนักงาน | `employee` | `6a8f2e129762533b5b718680` | `Relation` | subType 1 → `hr_employee` `6a8efa5e9762533b5b7185c1` · required | reverse field auto-created บน `hr_employee` id `6a8f2e129762533b5b718681` (ยังไม่ตั้งชื่อ) |
| ประเภทการลา | `leave_type` | `6a8f2e129762533b5b718682` | `Relation` | subType 1 → `hr_leave_type` `6a8eebf89762533b5b7184cf` · required | reverse field บน `hr_leave_type` id `6a8f2e129762533b5b718683` |
| ปีสิทธิ | `leave_year` | `6a8f2e129762533b5b718684` | `Number` | precision 0 · required | |
| สิทธิที่ได้รับปีนี้ | `entitled_days` | `6a8f2e129762533b5b718685` | `Number` | precision 1 · defaultValue 0 ส่งแล้ว (⚠️ readback md ไม่แสดงค่า default กลับมา — verify ด้วย record จริง) | เขียนโดย WF-HR-14 |
| ยอดยกมาจากปีก่อน | `carried_days` | `6a8f2e129762533b5b718686` | `Number` | precision 1 · defaultValue 0 | เขียนโดย WF-HR-14 |
| สิทธิรวม | `total_days` | `6a8f2e129762533b5b718687` | `Number` | precision 1 · defaultValue 0 | เขียนโดย workflow |
| ใช้ไปแล้ว | `used_days` | `6a8f2e129762533b5b718688` | `Number` | precision 1 · defaultValue 0 | เขียนโดย WF-HR-02/03 |
| คงเหลือ | `remaining_days` | `6a8f2e129762533b5b718689` | `Number` | precision 1 · defaultValue 0 | BR-08.2 อ่านค่านี้ |
| ปรับปรุงด้วยมือ | `adjustment_days` | `6a8f2e129762533b5b71868a` | `Number` | precision 1 · defaultValue 0 | |
| หมายเหตุ | `balance_note` | `6a8f2e129762533b5b71868b` | `Text` | multiLine | |
| (ระบบ) รายการเคลื่อนไหวสิทธิลา | — | `6a8f2e319762533b5b7186ad` | `Relation` | reverse field auto-created จาก `hr_leave_ledger.balance` | ยังไม่ตั้งชื่อ/alias ใหม่ |

**Form rules:** BR-09.1 interaction — Set all read-only สำหรับทุก role ยกเว้น R3 R4 (แก้ได้เฉพาะ `adjustment_days`) — ⬜ ยังไม่ตั้งใน Browser
**IX-09.1** Unique index (`employee`, `leave_type`, `leave_year`) — ⬜ ยังไม่ตั้ง Index Acceleration (P3-3)

**9B. รายการเคลื่อนไหวสิทธิลา** `hr_leave_ledger` `6a8f2dba9762533b5b718675` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 — **append-only · ห้ามแก้ ห้ามลบ**

| ฟิลด์ | alias | ID | type | props | หมายเหตุ |
|---|---|---|---|---|---|
| เลขที่รายการ | `ledger_no` | `6a8f2e319762533b5b7186ab` | `Text` | isTitle · **ไม่ required** | 🔴 **เบี่ยงจากสเปกเดิม** — สเปกเดิมกำหนดเป็น `AutoNumber` (สร้างผ่าน API ไม่ได้ ต้อง Browser) แต่ table ต้องมี isTitle field ตั้งแต่สร้าง จึงใช้ **Text ชั่วคราว** แทนไปก่อน · workflow (WF-HR-02/03/14) เขียนสตริงเลขที่ลงในนี้เองได้ (เช่น ต่อ string) จนกว่าจะตัดสินใจแปลงเป็น AutoNumber จริงใน Browser (P3-2 ยังเปิดอยู่ — การแปลงชนิดฟิลด์อาจต้องลบสร้างใหม่ เหมือนกรณี Number→Formula) |
| ยอดคงเหลือที่อ้างถึง | `balance` | `6a8f2e319762533b5b7186ac` | `Relation` | subType 1 → `hr_leave_balance` `6a8f2dba353e1b0e4a507757` · required | reverse field บน `hr_leave_balance` id `6a8f2e319762533b5b7186ad` |
| พนักงาน | `employee` | `6a8f2e319762533b5b7186ae` | `Relation` | subType 1 → `hr_employee` · required | reverse field id `6a8f2e319762533b5b7186af` |
| ประเภทรายการ | `ledger_type` | `6a8f2e319762533b5b7186b0` | `Dropdown` | ⚠️ **inline options** (ยังไม่ผูก `OS_HR_LEDGER_TYPE` `5b546b65-5050-4e7b-a02e-34fb55388a4b` — Browser-only ตามข้อจำกัดเดิม) | key inline: Annual grant=`ed2271ae-018b-433b-8061-a0d84093cf92` · Carry forward=`b3050388-65d0-40ed-b608-cb8c8c1e93bc` · Leave taken=`a70a70e4-94e6-41c3-a4ed-a13652086ffe` · Leave returned=`0b6c2026-21b3-49f6-b4b0-394102bc71ca` · Manual adjustment=`2e651fe9-85e4-4bbc-bb2e-95b5f64d062e` · Expiry=`3e6188be-b82a-4367-a071-d4ddb2d16014` 🔴 workflow ต้องอ้าง key inline เหล่านี้ ไม่ใช่ key ของ `OS_HR_LEDGER_TYPE` ใน §1.6.1 (คนละชุด จนกว่าจะรีไบนด์ผ่าน Browser) |
| จำนวนวัน (+ เพิ่ม / − ลด) | `ledger_days` | `6a8f2e319762533b5b7186b1` | `Number` | precision 1 · required | |
| ใบลาที่อ้างถึง | `leave_request` | `6a8f2e319762533b5b7186b2` | `Relation` | subType 1 → `hr_leave_request` `6a8f2dbaae2a0e3743a0beaa` | reverse field บน `hr_leave_request` id `6a8f2e319762533b5b7186b3` · ว่างได้กรณีให้สิทธิต้นปี |
| วันที่มีผล | `effective_date` | `6a8f2e319762533b5b7186b4` | `Date` | subType 3 · required | |
| ยอดคงเหลือหลังรายการนี้ | `balance_after` | `6a8f2e319762533b5b7186b5` | `Number` | precision 1 | เขียนโดย workflow |
| คำอธิบาย | `ledger_note` | `6a8f2e319762533b5b7186b6` | `Text` | multiLine | |

**DoD:** ทุกครั้งที่ `hr_leave_balance.used_days` เปลี่ยน ต้องมี record ledger คู่กัน 1 แถวเสมอ
**Pitfall:** ⚠️ `ledger_no` เป็น Text ชั่วคราว ไม่ใช่ AutoNumber จริง — อย่าอ้างอิงว่ามันการันตีความไม่ซ้ำกัน (unique index ต้องตั้งแยกถ้าจำเป็น)

### FR-HR-08 (แก้ไข ID จริง) ใบลา
**Worksheet:** ใบลา `hr_leave_request` `6a8f2dbaae2a0e3743a0beaa` ✅ สร้างจริงแล้ว 26 ส.ค. 2569 (view "ทั้งหมด" `6a8f2dbaae2a0e3743a0beae`)

| ฟิลด์ (ไทย) | alias | ID | type | subType / props | option / relation | หมายเหตุ |
|---|---|---|---|---|---|---|
| เลขที่ใบลา | `leave_no` | `6a8f2e231378964f99849b84` | `Text` | isTitle · **ไม่ required** (เขียนภายหลังโดย workflow/มือ — ยังไม่มีกฎการออกเลขที่จริง) | — | |
| พนักงาน | `employee` | `6a8f2e231378964f99849b85` | `Relation` | subType 1 · dataSource `6a8efa5e9762533b5b7185c1` · required | → `hr_employee` · reverse field id `6a8f2e231378964f99849b86` | |
| ประเภทการลา | `leave_type` | `6a8f2e231378964f99849b87` | `Relation` | subType 1 · dataSource `6a8eebf89762533b5b7184cf` · required | → `hr_leave_type` · reverse field id `6a8f2e231378964f99849b88` | |
| วันที่เริ่มลา | `leave_from` | `6a8f2e231378964f99849b89` | `Date` | subType 3 · required | — | |
| วันที่สิ้นสุดการลา | `leave_to` | `6a8f2e231378964f99849b8a` | `Date` | subType 3 · required | — | |
| หน่วยการลา | `leave_unit` | `6a8f2e231378964f99849b8b` | `Dropdown` | default Full day | ⚠️ **inline options** (ยังไม่ผูก `OS_HR_LEAVE_UNIT` `b91afbda-b1d3-4f35-b68b-9d800acc9aff`) key inline: Full day=`8f3ab519-2e9b-43c8-b94c-f5161aeee34f` · Half day (morning)=`9d6d4431-5ed3-47bf-b6d3-63878bdc7fcc` · Half day (afternoon)=`795b7973-24ed-417a-a07a-765cbd48b49e` · Hourly=`be352812-59a1-463c-ba70-a0a672811cd1` | |
| จำนวนวันลา | `leave_days` | `6a8f2e231378964f99849b8c` | `Number` | precision 1 | — | 🔴 เขียนโดย workflow ด้วย `Function calculation` — read-only บนฟอร์ม |
| จำนวนชั่วโมง | `leave_hours` | `6a8f2e231378964f99849b8d` | `Number` | precision 2 | — | |
| เหตุผลการลา | `leave_reason` | `6a8f2e231378964f99849b8e` | `Text` | multiLine · required | — | |
| ผู้ปฏิบัติงานแทน | `backup_person` | `6a8f2e231378964f99849b8f` | `Relation` | subType 1 → `hr_employee` | reverse field id `6a8f2e231378964f99849b90` | |
| เอกสารประกอบ | `attachments` | `6a8f2e231378964f99849b91` | `Attachment` | | — | 🔴 ซ่อนจาก R2 R6 (ตั้งใน Browser) |
| สถานะใบลา | `leave_status` | `6a8f2e231378964f99849b92` | `Dropdown` | default Draft · **ควร read-only บนฟอร์ม** (ตั้งใน Browser) | ⚠️ **inline options** (ยังไม่ผูก `OS_HR_REQUEST_STATUS` `8ea16e5f-c099-45e2-9734-b553ea40b8d0`) key inline: Draft=`6122e254-2ae3-488e-82d8-2272af05b830` · Pending supervisor=`8ab9022b-5ed7-469c-a2e6-351fbb49ed1e` · Pending HR=`eef4b91d-e609-4188-99f0-f4a349081e0c` · Approved=`3642500d-00f7-4533-b9b6-b6996e5ba251` · Rejected=`db7f8ace-7b05-4bd9-aa90-c6d3f3a972ef` · Cancelled=`c30bb57c-c4a3-4d80-8ae2-c049ceabaaf9` 🔴 WF-HR-01 ต้องอ้าง key inline เหล่านี้ ไม่ใช่ key ของ `OS_HR_REQUEST_STATUS` ใน §1.6.1 | |
| ผู้อนุมัติที่ระบบกำหนด | `approver_user` | `6a8f2e231378964f99849b93` | `Collaborator` | subType 0 | — | 🔴 จำเป็นสำหรับ Approve node |
| (ระบบ) ขั้นการอนุมัติปัจจุบัน | `approval_step` | `6a8f2e231378964f99849b94` | `Number` | precision 0 · defaultValue 0 ส่งแล้ว | — | |
| วันที่ส่งคำขอ | `submitted_at` | `6a8f2e231378964f99849b95` | `DateTime` | subType 1 | — | |
| วันที่อนุมัติขั้นสุดท้าย | `approved_at` | `6a8f2e231378964f99849b96` | `DateTime` | subType 1 | — | |
| ผู้อนุมัติขั้นที่ 1 | `approver1_user` | `6a8f2e231378964f99849b97` | `Collaborator` | subType 0 | — | |
| ผู้อนุมัติขั้นที่ 2 | `approver2_user` | `6a8f2e231378964f99849b98` | `Collaborator` | subType 0 | — | |
| เหตุผลที่ไม่อนุมัติ | `reject_reason` | `6a8f2e231378964f99849b99` | `Text` | multiLine | — | |
| เหตุผลการยกเลิก | `cancel_reason` | `6a8f2e231378964f99849b9a` | `Text` | multiLine | — | |
| (ระบบ) ส่งอนุมัติแล้ว | `submitted_flag` | `6a8f2e231378964f99849b9b` | `Number` | precision 0 · defaultValue 0 ส่งแล้ว | — | 🔴 กันยิงซ้ำ WF-HR-01 |
| (ระบบ) ตัดสิทธิแล้ว | `deducted_flag` | `6a8f2e231378964f99849b9c` | `Number` | precision 0 · defaultValue 0 ส่งแล้ว | — | 🔴 กันตัดสิทธิซ้ำ WF-HR-02 |
| (ระบบ) คืนสิทธิแล้ว | `returned_flag` | `6a8f2e231378964f99849b9d` | `Number` | precision 0 · defaultValue 0 ส่งแล้ว | — | 🔴 กันคืนสิทธิซ้ำ WF-HR-03 |
| (ระบบ) สิทธิคงเหลือขณะยื่น | `balance_snapshot` | `6a8f2e231378964f99849b9e` | `Number` | precision 1 | — | |
| ปีสิทธิ | `leave_year` | `6a8f2e231378964f99849b9f` | `Number` | precision 0 | — | |
| (ระบบ) รายการเคลื่อนไหวสิทธิลา | — | `6a8f2e319762533b5b7186b3` | `Relation` | reverse field auto-created จาก `hr_leave_ledger.leave_request` | ยังไม่ตั้งชื่อ/alias ใหม่ |

**⚠️ verify ยังไม่ทำ:** default 0 ของฟิลด์ธง (submitted/deducted/returned_flag, approval_step) ส่งใน `addFields` แล้ว แต่ readback `responseFormat:md` ไม่แสดง defaultValue กลับมา (บั๊กเดิมที่เจอกับ `hr_employee`/`hr_setting`) — ต้อง seed record ทดสอบแล้วเปิดดูค่าจริงก่อนเชื่อว่า default ใช้งานได้ (ยกไปพร้อม Test recipe WF-HR-01)

**Form rules / IX ที่ยังไม่ทำ (ทั้งหมดต้องทำใน Browser — งานค้าง):** BR-08.1…5 · DV-08.1 · IX-08.1 (`leave_no` unique) · ตั้ง `leave_status` เป็น read-only

**สถานะ P3-1:** 🟢 **โครงสร้างตารางสร้างครบทั้ง 3 ตาราง 26 ส.ค. 2569** (`hr_leave_balance` · `hr_leave_request` · `hr_leave_ledger`) ผ่าน `create_app_items`→`removeFields`+`addFields`(รวมคำสั่งเดียว)→verify · ยืนยันด้วย `get_worksheet_structure` และ `get_app_worksheets_list` ทั้ง 3 ตาราง · relation ทุกฟิลด์ตั้ง `bidirectional:true` สร้าง reverse field อัตโนมัติบน `hr_employee`/`hr_leave_type`/ข้ามกันเองระหว่าง 3 ตารางนี้แล้ว
**ยังไม่ทำ (ถัดไป):** seed record ทดสอบยืนยัน default value จริง · unique index (IX-08.1, IX-09.1) · form rules ทั้งหมด (Browser) · ผูก Dropdown ทั้ง 3 ฟิลด์เข้า shared optionset (Browser) · WF-HR-01/02/03 (รอ P3-1 นี้เสร็จเป็นตัวปลดบล็อก)
