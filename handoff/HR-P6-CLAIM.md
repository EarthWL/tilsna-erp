# HANDOFF · HR/P6-CLAIM · agent-hr → agent-ac · 6 ก.ย. 2569

## ยิงไปแล้วบนเซิร์ฟเวอร์ (ย้อนอัตโนมัติไม่ได้ — ห้ามเว้นว่าง)

- **`hr_claim`** `6a9d19c34720c515252ab8b1` — worksheet ใหม่ 17 ฟิลด์ · ไอคอน `sys_bill_finance` · กลุ่ม HR-06 `6a8ee66ce56d2e6eb7bd6cba` · ✅ verify ด้วย `worksheet fields --raw`
- **`hr_claim_line`** `6a9d19e24a22ad87b727a348` — worksheet ใหม่ 8 ฟิลด์ · ไอคอน `sys_bullet-list_office` · ✅ verify แล้ว
- **Rollup** `6a9d1a154a22ad87b727a37a` (type 37 · `enumDefault: 5` = SUM) — ✅ **verify ด้วยการอ่านค่าที่คำนวณจริง** 1500 / 2400 / 2800
- **relation คู่** `6a9d1a084a22ad87b727a373` (บน `hr_claim`) ⇄ `6a9d1a084a22ad87b727a374` (บน `hr_claim_line`, required)
- **ลบทิ้งแล้ว:** relation `6a9d19e44a22ad87b727a353` บน `hr_claim_line` (ตัวที่ `create_worksheet` สร้างให้ — ใช้กับ Rollup ไม่ได้) และฟิลด์ทดสอบ 11 ตัวบน `hr_claim` ที่ใช้ไล่ค่า `enumDefault`
- **view 5 อันบน `hr_claim`** — `6a9d1cc6f363582dd3793179` (kanban) · `6a9d1cc74a73a3142151a53c` (รอดำเนินการอนุมัติ ✅ คืน 1 แถว) · `6a9d1cc8f363582dd379317b` (อนุมัติแล้ว ✅ คืน 1 แถว) · `6a9d1cca4a22ad87b727a3f3` (calendar)
- **ข้อมูล demo ค้างอยู่ตั้งใจ** — ใบเบิก 3 ใบ + บรรทัด 4 แถว (rowid ครบใน `../projects/hr/17-ID-Registry-HR.md`)
- **เอกสาร:** `../shared/00-HAP-Working-Guide.md` §14 (ใหม่) · `17-ID-Registry-HR.md` · `05-Roadmap-Tracker.md` (P6-2/P6-3 → ✅, P6 8%→42%, รวม 42%→46%) · `19-Change-Log-HR.md` · แก้คำที่ผิดใน `02-BuildSpec-FRS.md` §0 และ `21-FRS-Modules-HR.md`

## ทำถึงไหน (เทียบ DoD)

- ✅ **P6-2** DoD "Rollup คำนวณจริง (แก้บรรทัดแล้วหัวขยับ)" — ผ่าน แต่มีเงื่อนไข: หัวขยับเมื่อ **เขียน relation field ของ record ลูกซ้ำ** ไม่ใช่ทุกการแก้ไข (ดู §14.3)
- ✅ **P6-3** seed ครบ ครอบคลุม 3 สถานะ
- ⬜ P6-4 (Business Rules) · P6-5 (WF-HR-11) · P6-6 (WF-HR-12) ยังไม่เริ่ม

## ที่ตั้งใจจะทำต่อ

- P6-4 → P6-5 → P6-6 ตามลำดับ (P6-6 คือ **AC-10 ส่วนหลัง** — ต้องคุยกับ agent-ac ก่อนผูก `pay_req_ref` → `ac_pay_req` `6a8677b19b6999a714d2aa83`)

## 🔴 สิ่งที่ agent-ac ควรอ่านทันที (กระทบงานบัญชีโดยตรง)

1. **`enumDefault` ของ Rollup ที่เดาว่าเป็น SUM คือ AVG** — ถ้าฝั่งบัญชีมีฟิลด์ Rollup ที่สร้างผ่าน API/CLI ด้วย `enumDefault: 1` **ตัวเลขจะเป็นค่าเฉลี่ย ไม่ใช่ยอดรวม และไม่มี error ให้เห็น** ⇒ ขอให้ไล่ตรวจทุกฟิลด์ type 37 ฝั่ง AC ว่า `enumDefault` เป็น 5 หรือไม่ · ตารางค่าเต็มอยู่ใน `../shared/00-HAP-Working-Guide.md` §14.2
2. **การทดสอบด้วย record ที่มีลูกบรรทัดเดียวจับบั๊กนี้ไม่ได้** — ต้องมี ≥2 บรรทัดที่ค่าไม่เท่ากันเสมอ
3. **Rollup สร้างผ่าน CLI ได้** ไม่ต้องรอ Browser (แก้ความเข้าใจเดิมในไกด์ทั้งสองฝั่ง)
4. **`hap app-editor plan/apply` ใช้กับแอป ERP นี้ไม่ได้เลย** — `inspect` คืน `worksheets: []` เพราะตารางอยู่ใต้ group ⇒ field.update/field.delete ต้องทำเองด้วย `worksheet update-fields` อ่าน-แก้-เขียนกลับ

## ระเบิดที่ฝังไว้ / ข้อควรระวัง

- ใบเบิก demo 3 ใบ + 4 บรรทัดยังอยู่บนเซิร์ฟเวอร์ **ตั้งใจให้อยู่** (เป็นทั้งชุด demo และหลักฐานว่า Rollup ทำงาน) — ถ้าจะลบต้องอัปเดต `17-ID-Registry-HR.md` และ `27-Demo-Seed-HR.md` ด้วย
- `hr_claim` **ยังไม่มี workflow ใด ๆ ผูกอยู่** — ธง `(ระบบ) ส่งอนุมัติแล้ว/ตัดวงเงินแล้ว/ส่งเข้าบัญชีแล้ว` ตอนนี้เป็นค่าที่ seed มือทั้งหมด **ไม่ได้สะท้อนสถานะจริงของระบบ** จนกว่า P6-5/P6-6 จะเสร็จ
- ยังไม่ได้ผูก `pay_req_ref` → `ac_pay_req` **ตั้งใจเว้นไว้** เพราะต้องประสานกับ agent-ac ก่อน (relation ข้ามโมดูล)
- `hr_claim.วงเงินคงเหลือขณะยื่น` เป็น snapshot ที่ seed มือ ยังไม่ได้เชื่อมกับ `hr_welfare_balance` จริง — เป็นงานของ P6-4/P6-5
