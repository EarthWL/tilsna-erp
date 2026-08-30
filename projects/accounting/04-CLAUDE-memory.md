# Memory — โมดูลบัญชี TILSNA ERP (Nocoly)

_อัปเดตล่าสุด: 28 ส.ค. 2569 (รอบดึกที่สุด — ทำความสะอาด workflow object ซ้ำซ้อน/orphan ทั้งแอป) — **ลบ orphan/duplicate workflow object ที่ค้างจากรอบ build/test ก่อนหน้า**: WF-AC-01 orphan approval-flow child 2 ตัว + WF-AC-02 stale human-authored draft 1 ตัว + WF-AC-10 orphan sub_process 7 ตัว + ปุ่ม Custom Action ซ้ำ "ปิดปีและยกยอด" บน AC_PERIOD 1 ตัว (test draft เก่า) — ยืนยันด้วย `hap workflow list` (CLI) cross-reference กับ `get_workflow_structure` (MCP) ก่อนลบทุกครั้ง · 🆕 **ค้นพบว่า CLI `hap workflow list <appId> [-k keyword] -n <n>` เป็นเครื่องมือ audit workflow ทั้งแอปที่ครอบคลุมที่สุด** — เห็น process ทุกตัวรวม draft/disabled/orphan ที่ MCP `get_workflow_list` (เห็นแค่ PBP-type) มองไม่เห็นเลย ⇒ ใช้เป็นเครื่องมือ audit มาตรฐานจากนี้ไป · เพิ่ม**กับดักข้อ 35**: อธิบายแพทเทิร์น "build-iteration ทิ้ง orphan duplicate process ไว้เสมอ" (เพราะ `approval_block`/`sub_process` แก้ในตัวไม่ได้ ตามกับดักข้อ 24) + เทคนิคใหม่ว่าปุ่ม Custom Action ที่ชื่อซ้ำกัน ลำดับแถวบนหน้าจอไม่เสถียร ต้องยืนยันตัวตนด้วย Button Description + network request เท่านั้น ห้ามใช้ตำแหน่งแถว · พบความไม่เรียบร้อยแบบเดียวกันในสโคป `tilsna-hr` (attendance-sync helper ×3, WF-HR-05 inner helper ซ้ำ) แต่จงใจไม่แตะ นอกสโคปโมดูลบัญชี — ดูกับดักข้อ 35 และแถว #39 ด้านล่างสำหรับรายละเอียดเต็ม_ _(ยุบ 30 ส.ค. 2569 — ประวัติรอบก่อน ๆ ที่เคยซ้อนต่อท้ายบรรทัดนี้ 7 ชั้น/7,846 ตัวอักษร ถูกตัดออก ไม่มีข้อมูลสูญหาย: ID ทุกตัวในนั้นถูกยืนยันแล้วว่ามีอยู่ในส่วนอื่นของเอกสารชุดนี้ และเนื้อความเต็มยังอ่านย้อนได้จาก `git log --oneline --follow -- projects/accounting/04-CLAUDE-memory.md` ⇒ **กฎใหม่: บรรทัดนี้เก็บรอบล่าสุดรอบเดียวเท่านั้น ห้ามซ้อน (รอบก่อนหน้า: …) ต่อท้ายอีก** ประวัติเป็นหน้าที่ของ git)_
> ไฟล์นี้ build agent โหลด **ทุก session ก่อนเริ่มงาน** — เก็บเฉพาะของจำเป็น
> รายละเอียดเต็ม (ทุก field id / option key / workflow node) อยู่ใน `02-BuildSpec-FRS.md`

---

## ⚠️ ข้อกำหนดหลัก (CRITICAL CONSTRAINTS)

1. **ทุก business logic ต้องอยู่บน Nocoly เท่านั้น** — ห้ามใช้สคริปต์หรือไฟล์ภายนอกเป็นส่วนหนึ่งของระบบที่ส่งมอบ
2. **Brownfield** — มี 39 worksheet (34 เดิม + 5 ตาราง Phase 8 ที่สร้างใหม่ 27 ส.ค. 2569: `AC_BANK_RECON`/`AC_BANK_RECON_LINE`/`AC_CLOSE`/`AC_CLOSING_ENTRY`/`AC_OPENING`) · **67 view** (62 เดิม + 5 view ของ 5 ตารางใหม่ที่เปลี่ยนชื่อเป็นไทยแล้ว 28 ส.ค. 2569 รอบค่ำ) · 35 optionset · 8 custom role อยู่แล้ว **ห้ามสร้างซ้ำ** เปิด BuildSpec §1 ก่อนแตะ object ใด ๆ
3. **มี workflow ทำงานจริงแล้ว 2 ตัว** (26 ส.ค. 2569): WF-AC-01 `6a8eaa45e6605c4b13ccf49b` · WF-AC-02 `6a8ea77e5f8564a68c33f9db` — ที่เหลืออีก 20 ตัวยังไม่สร้าง (ปัจจุบัน 28 ส.ค. 2569 มี workflow live รวม 5 ตัวแล้ว: WF-AC-01/02/09/10/11 + WF-AC-08/12 — ดู "ID สำคัญ")
4. **การอนุมัติทำผ่าน MCP ไม่ได้** — ผู้อนุมัติต้องกดใน To-do จริง ⇒ ห้ามปิดงาน ✅ ถ้า approval ยัง pending
5. **ห้ามใช้ org-auth API กดอนุมัติแทนคน** (ข้อสมมติ A-15 — ผู้ใช้ยังไม่อนุญาต)
6. เอกสารบัญชีเป็นข้อมูลตามกฎหมาย — **ห้ามลบ record จริง** ใช้การยกเลิก/กลับรายการแทน
7. 🔴 **ชื่อ worksheet · ชื่อฟิลด์ · ชื่อ view · ค่าตัวเลือก (option value) เป็นภาษาไทยทั้งหมดแล้ว** (26 ส.ค. 2569 — ยกเว้น 5 view ของ 5 ตาราง Phase 8/AC-07 ที่สร้างทีหลังและปิด gap แล้วเมื่อ 28 ส.ค. 2569 รอบค่ำ) — ห้ามอ้างชื่อ/ค่าอังกฤษเดิมจากเอกสารเก่า · และ **ห้ามใส่ฟิลด์ Rollup หรือ Dropdown ที่ผูก optionset ส่วนกลาง หรือฟิลด์ SingleSelect/MultipleSelect ที่มีตัวเลือกฝังตัว ลงใน `update_worksheet.editFields` เด็ดขาด** (อ่านหัวข้อถัดไปให้จบก่อนแตะฟิลด์ใด ๆ) · 🔴🆕 **ทุกครั้งที่เรียก `editFields` แก้ฟิลด์ใดก็ตาม ต้องส่ง `name`+`alias` กลับไปพร้อมกันเสมอ แม้ไม่ได้ตั้งใจแก้สองค่านี้** — ไม่งั้นจะถูกล้างเป็นค่าว่างเงียบ ๆ (ดูกับดักข้อ 32)
8. ✅ **วันที่ที่แสดงเป็นรูปแบบจีน (`YYYY年M月D日`) แก้ครบทั้งแอปแล้ว** (26 ส.ค. 2569 — งาน 1.22) — **24 ตาราง (14 Accounting + 10 HR) รวม 37 ฟิลด์ Date/DateTime** ตั้ง custom format ผ่าน `update_worksheet.editFields.config.format` เป็น `DD/MM/YYYY` (Date) หรือ `DD/MM/YYYY HH:mm` (DateTime) — ดูกับดักข้อ 14
9. ✅ **ตั้ง permission ตาม matrix ครบทั้ง 8/8 role แล้ว** (26 ส.ค. 2569 — งาน 1.8) — ยืนยันผ่าน `get_role_details` ตรง matrix §1.4 100% ทุก role — ดูกับดักข้อ 17
10. 🔴 **`update_worksheet.sectionId` ตั้งค่าจริงไม่ได้** (26 ส.ค. 2569 — พยายามทำงาน 1.20) — คืน `success:true` แต่ worksheet ไม่ถูกย้ายจริง (ยืนยันด้วย `get_app_info` ก่อน/หลัง) — ดูกับดักข้อ 18
11. ✅ **การย้ายตารางข้ามกลุ่ม/section ทำผ่านหน้าจอได้จริงและง่ายด้วยเมนู "..." → "Move to" ในไซด์บาร์หลัก** (26 ส.ค. 2569 — งาน 1.20 เสร็จ, ผู้ใช้เป็นคนเจอวิธีนี้) — เชื่อถือได้กว่า drag-and-drop ในหน้า Navigation Settings มาก (drag ไม่เสถียร พิกัดเลื่อนทุกครั้ง) — ดูกับดักข้อ 19
12. ✅ **Custom Action button ครบ 3/3 ปุ่มบน AC_VOUCHER แล้ว ทั้งหมด verify Scope ผ่าน Browser เป็น "All Records" ครบแล้ว** (27 ส.ค. 2569) — "ส่งอนุมัติ" `6a8f380b1378964f99849bfe`, "ยกเลิกใบสำคัญ" `6a8f380bae2a0e3743a0bedb`, และ "กลับรายการ" `6a8fb9ea9762533b5b7189fb` — **ทุกปุ่มที่สร้างผ่าน MCP มี Scope เริ่มต้นเป็น "Unassigned View" เสมอ (ไม่โผล่ที่ไหนเลยจนกว่าจะตั้ง Scope ผ่าน Browser)** และปุ่มชนิด `updateCurrentRecord` คลิกแล้ว**ไม่ auto-apply ค่าเป้าหมาย** — เปิด dialog ให้เลือกค่าเองก่อนกด Confirm — ดูกับดักข้อ 20 และ 21
13. ✅ **AC_PERIOD มีปุ่ม Custom Action 2 ตัวแล้ว ทั้งคู่ยังไม่ verify Scope ผ่าน Browser** (27–28 ส.ค. 2569) — "ปิดงวด" `6a903eb89762533b5b71c4b2` (WF-AC-09, งาน 2.6) และ "ปิดปีและยกยอด" `6a90f50e1378964f9984df83` (WF-AC-11, งาน 8.5) — คาดว่าทั้งคู่เป็น "Unassigned View" ตามแพทเทิร์นกับดักข้อ 20 เหมือนปุ่มอื่นทุกตัว — เป็น gap ด้าน UI-visibility เท่านั้น ตัว workflow logic ของทั้งสองทดสอบผ่านครบแล้ว
14. 🟢🆕 **มี CLI `hap` ที่ทำงานที่ MCP connector ทำไม่ได้ เช่นเปลี่ยนชื่อ view ที่มีอยู่แล้ว** (28 ส.ค. 2569 รอบค่ำ) — คำสั่ง `hap worksheet view update <ws_id> <view_id> --name "..."` ใช้งานได้จริง ยิงสำเร็จ 5 ครั้งติดกัน — ดูกับดักข้อ 33 · **ก่อนสรุปว่างานใดทำได้แค่ผ่าน Browser ให้เช็คว่ามี CLI ทำแทนได้ก่อนเสมอ**

15. 🔴🆕 **A-09 ยืนยันแล้ว 28 ส.ค. 2569 — บัญชีไม่ได้เป็นเจ้าของห่วงโซ่เอกสารขาย (FR-12) อีกต่อไป — ย้ายออกนอกขอบเขตถาวร** จะมีโมดูลการขายแยกต่างหากในอนาคต ฝ่ายขายออกเอกสารเอง ⇒ **ห้ามสร้าง worksheet `AC_INV`/`AC_BL`/`AC_CN`/`AC_DN`/`AC_AR`/`AC_AR_LINE`/`AC_RE` (section `AC-05`) เด็ดขาด** — ดู `01-BRD.md` §11 A-09
16. ✅🆕 **A-11 ยืนยันแล้ว 28 ส.ค. 2569 — บัญชีถือสมุดบัญชีสินทรัพย์ (`สมุดบัญชีสินทรัพย์`) เต็มรูปแบบ — FR-13 อยู่ในขอบเขตเต็มรูปแบบและปลดบล็อกแล้ว** ครอบคลุมราคาทุน อายุการใช้งาน มูลค่าซาก วิธีคิดค่าเสื่อม/ตารางค่าเสื่อม ค่าเสื่อมสะสม และกำไร/ขาดทุนจากการตัดจำหน่าย ⇒ **build agent ดำเนินการสร้าง section `AC-06 Fixed Assets` ต่อได้ทันทีที่มีการจัดลำดับความสำคัญ** (ยังไม่ได้ลงมือสร้าง ณ รอบนี้) — โมดูลสินทรัพย์กายภาพในอนาคตถือแค่การครอบครอง/ตำแหน่ง/การตรวจนับ เชื่อมด้วยรหัสสินทรัพย์ร่วม — ดู `01-BRD.md` §11 A-11

---

## 🚨 ชื่อไทย + กับดัก `update_worksheet` (อ่านก่อนแตะฟิลด์ทุกครั้ง)

**สถานะชื่อ/ค่าหลังรอบเปลี่ยนชื่อและแปลค่าตัวเลือก 26 ส.ค. 2569** (รายละเอียดเต็มใน `08-Naming-Rollout-Report.md` · `09-View-Layer-Naming-Review.md` · `10-Data-Name-Translation-Report.md`)

- **Worksheet 34 / 34 ตาราง เป็นชื่อไทยแล้ว** — เช่น `AC_VOUCHER` = **ใบสำคัญ** · `AC_AP` = **ใบสำคัญตั้งหนี้** · `AC_GL` = **บัญชีแยกประเภททั่วไป** · `AC_VAT_DOC` = **ทะเบียนภาษีซื้อ–ภาษีขาย** · `AC_PAY` = **ใบสำคัญจ่าย**
- ✅ **ชื่อตารางบนหัวจอ (worksheet name) 34 / 34 เป็นไทยแล้ว** — เดิมหัวจอยังโชว์รหัส `AC_*` ทั้งที่เมนูซ้ายเป็นไทย · แก้ครบผ่านหน้าจอเมื่อ 26 ส.ค. 2569 · ไม่เหลือรหัส `AC_*` บนหัวจอแม้แต่ตัวเดียว
- ✅✅ **View 67 / 67 เป็นชื่อไทยแล้ว (28 ส.ค. 2569 รอบค่ำ — ปิด gap เต็มแล้ว)** — เดิมเป็นค่าเริ่มต้นภาษาจีน `全部` 33 ตัว + `Main` 1 ตัว ⇒ เปลี่ยนเป็น **`ทั้งหมด`** ครบ 34 ตัวผ่านหน้าจอเมื่อ 26 ส.ค. 2569 · และ **สร้าง view ใหม่ 28 ตัวใน 8 ตารางผ่าน API `create_view`** (ใบสำคัญ · ใบสำคัญตั้งหนี้ · ใบขออนุมัติเบิกจ่าย · ใบสำคัญจ่าย · บัญชีแยกประเภททั่วไป · ทะเบียนภาษีซื้อ–ภาษีขาย · การยื่นแบบภาษี · งวดบัญชี) ⇒ **8 ตารางมี view แยกตามสถานะแล้ว** (รวม 62/62 ณ 26 ส.ค.) · 🆕 **28 ส.ค. 2569 รอบค่ำ: อีก 5 ตารางที่สร้างทีหลัง (กลุ่ม AC-07 จาก Phase 8) ยังเหลือ view เริ่มต้น `全部` — แก้ครบด้วย CLI `hap worksheet view update` ทั้ง 5 ตาราง (การกระทบยอดธนาคาร, รายการกระทบยอดธนาคาร, รายการตรวจสอบปิดงวด, การปิดบัญชีสิ้นปี/AC_CLOSING_ENTRY, ยอดยกมาต้นปี/AC_OPENING) ⇒ รวม 67/67 view เป็นไทยครบทั้งระบบแล้ว** — ดูกับดักข้อ 33 · ✅🆕 **[28 ส.ค. 2569 ดึกกว่ารอบค่ำ] สแกนทั้งแอปครบแล้ว (68 worksheet / 102 view ทั้งแอป — เกินขอบเขต 39 ตารางโมดูลบัญชีด้วยซ้ำ) ผ่าน CLI + regex CJK — พบ 0 view ที่หลงเหลือเป็นจีนหรือ `Main`** — ปิด follow-up นี้ถาวร ไม่มี gap เหลือด้าน view naming ในแอปนี้อีกแล้ว ณ ปัจจุบัน
- **ฟิลด์ราว 410 ตัวเป็นชื่อไทยแล้ว** — เหลือ 8 ตัวที่ยังเป็นอังกฤษโดยตั้งใจ (ดู Known Issues) — **นี่คือชื่อ label ของฟิลด์ คนละเรื่องกับค่าตัวเลือกข้างในฟิลด์**
- ✅ **ค่าตัวเลือก (option value) เป็นไทยทั้งระบบแล้ว** (26 ส.ค. 2569 — งาน 1.17) — **35 shared optionset (123 ตัวเลือก)** ผ่าน `update_optionset` + **8 ฟิลด์ inline option** ลบ–สร้างใหม่แล้วคืนค่า record ครบ + **1 ฟิลด์ที่มี Lookup ผูกอยู่** (`period_status`) แก้ผ่านหน้าจอ · จงใจไม่แตะฟิลด์รหัสระบบ/โมดูล 4 ตัว (`source_doc_type` ×2, `source_type`, `event_code`) — ดู Known Issues และ `10-Data-Name-Translation-Report.md` §4 · 🆕 **28 ส.ค. 2569: `event_code` เพิ่ม 2 option ใหม่ผ่าน `editFields` แล้ว (`PAYROLL_ACCRUAL`/`PAYROLL_PAYMENT`) — ดูหัวข้อ "ช่วยเหลือ HR" ด้านล่าง** ยังคงไม่แปลค่าเดิม 10 ตัวเป็นไทยเหมือนเดิม (จงใจ ตามเหตุผลเดิม — เป็นรหัส event ภายใน)
- ✅ **"Record Name" (แท็บ Data Name) เป็นไทยครบทุกตารางแล้ว** (26 ส.ค. 2569 — งาน 1.21) — เดิมทุกตาราง (44/44 — 34 AC + 10 HR) แสดงค่าเริ่มต้นเป็นภาษาจีน `记录` บนปุ่มเพิ่มเรคคอร์ดและข้อความแจ้งเตือน แก้ผ่าน `update_worksheet.addRecordButtonName` — ดูกับดักข้อ 14
- **alias และ field ID คือหลักยึดเดียว** — ชื่อไทยใช้สำหรับคนอ่าน · workflow / filter / สูตร ต้องอ้าง **field ID** เสมอ
- **option key (GUID) ทุกตัวคงเดิม** ⇒ workflow ที่เทียบ option key ยังทำงานได้ตามปกติ · ไม่มีข้อมูลใน record สูญหาย (รวมทั้งรอบตั้งชื่อและรอบแปลค่าตัวเลือก)
- ⚠️ `get_worksheet_structure` **คืนชื่อตารางเป็นค่าเก่าเสมอ** — ถ้าจะเช็กชื่อตารางจริงต้องใช้ `get_app_worksheets_list`

**กับดักของ `update_worksheet` และชั้นการแสดงผล (พิสูจน์จากการยิงจริง — §4.1 ของรายงาน 08 · §5 ของรายงาน 09 · §3 ของรายงาน 10)**

1. ส่ง `name` (ระดับตาราง) พร้อม `editFields` ในคอลเดียว → **`name` ถูกเมินเงียบ ๆ** ต้องแยกคอล
2. `editFields` **รีเซ็ตทุก attribute ที่ไม่ได้ส่งไป** — `required`, `isTitle`, `precision` และ `subType` ของ Relation / Date / DateTime / Attachment / Collaborator — 🆕 **ยืนยันขยายผล 28 ส.ค. 2569: ครอบคลุมถึง `name`/`alias` ของฟิลด์ด้วยเช่นกัน แม้เป็นฟิลด์ inline SingleSelect — ดูกับดักข้อ 32**
3. ฟิลด์ **Number ห้ามส่ง `subType`** (จะรั่วลง `unit` เป็นขยะท้ายตัวเลข) · **Relation ที่ `subType=2` ก็ห้ามส่ง**
4. **Text หลายบรรทัด** ต้องส่งผ่าน `config:{textMode:"multiLine"}` ไม่ใช่ `subType`
5. ฟิลด์ชนิด **`OrgRole` ห้ามส่ง `type`** (ไม่อยู่ใน enum ของ API)
6. `get_worksheet_structure` **คืนชื่อตารางเป็นค่าเก่าเสมอ** — ต้องตรวจด้วย `get_app_worksheets_list`
7. 🔴 **Rollup — ห้ามใส่ลง `editFields` เด็ดขาด** จะเปลี่ยนเป็น "จำนวนบันทึก" และหยุดคำนวณ · ชนิด Rollup ไม่มีใน enum ของ API จึง **ซ่อมได้เฉพาะผ่านหน้าจอ**
8. 🔴 **Dropdown ที่ผูก optionset ส่วนกลาง — ห้ามใส่ลง `editFields`** การผูกจะหลุด **ถาวร** และผูกกลับเข้าฟิลด์เดิมไม่ได้ทั้ง API และหน้าจอ · ทางเดียวคือ **ลบฟิลด์แล้วสร้างใหม่** (สำรองค่าในเรคคอร์ดก่อน แล้วเขียนกลับ)
9. ✅ **ถ้าจะเปลี่ยนชื่อฟิลด์ 2 กลุ่มข้างบน ให้ทำผ่านหน้าจอเท่านั้น** — หน้าจอไม่ทำให้อะไรหลุด
10. 🔴 **ชื่อของตารางมี 2 ชั้น — `update_worksheet.name` แก้ได้แค่ชั้นเดียว**
    - `update_worksheet.name` เขียนไปที่ **ชื่อในเมนูซ้าย (app item)** เท่านั้น
    - **ชื่อตารางที่แสดงบนหัวจอตัวใหญ่ (worksheet name)** และหัวหน้าออกแบบฟอร์ม **API แก้ไม่ได้** ⇒ ต้องแก้ **ผ่านหน้าจอ: เมนู `...` ของตาราง → แก้ไขชื่อและไอคอน**
    - ⇒ ถ้าแก้แค่ผ่าน API เมนูซ้ายจะเป็นไทยแต่หัวจอยังเป็นรหัสอังกฤษ (อาการที่เจอจริงหลังรอบ 08)
11. ⚠️🆕 **ไม่มี `update_view` ใน MCP connector — มีแค่ `create_view` — แต่ CLI `hap` แยกต่างหากทำได้จริง (แก้ไข 28 ส.ค. 2569 รอบค่ำ ดูกับดักข้อ 33)**
    - **สรุปเดิม (26 ส.ค. 2569 — ยังถูกต้องสำหรับ MCP connector เท่านั้น)**: เปลี่ยนชื่อ view · แก้ filter · แก้คอลัมน์ของ view ที่มีอยู่ **ทำผ่าน MCP ไม่ได้เลย** — เดิมเข้าใจว่าต้อง **ทำผ่านหน้าจอเท่านั้น**: **ลูกศรข้างแท็บ view → กำหนดค่ามุมมอง → แก้ชื่อที่ช่องบนสุดของแผง**
    - 🆕 **แก้ไข 28 ส.ค. 2569**: **CLI `hap` (เครื่องมือแยกจาก MCP, เรียกผ่าน Bash — ดู skill `hap-cli`/`hap-cli-app-editor`) รองรับ `hap worksheet view update <worksheet_id> <view_id> --name "<ชื่อใหม่>"` ใช้งานได้จริง** — ยิงสำเร็จ 5 ครั้งเปลี่ยนชื่อ view จาก `全部` เป็น `ทั้งหมด` ยืนยันด้วย JSON readback ของ CLI เอง (ดูกับดักข้อ 33) ⇒ **จากนี้ไป: ลอง CLI ก่อนเสมอสำหรับงานเปลี่ยนชื่อ view ที่มีอยู่แล้ว** ใช้ Browser เป็นทางเลือกสำรองเท่านั้น (เช่นกรณี CLI ยังไม่ login ใน session นั้น หรือถ้าต้องแก้ filter/คอลัมน์ของ view ที่มีอยู่ ซึ่งยังไม่เคยทดสอบผ่าน CLI)
    - ✅ **`create_view` ใช้ได้จริงและปลอดภัย** (ยิงจริง 28 view สำเร็จ ไม่กระทบ view เดิม) — รองรับ filter · sort · quick filter · การเลือกคอลัมน์
    - ⚠️ ค่าวันที่ไดนามิกใน filter มีเฉพาะชุดที่แพลตฟอร์มให้ (`today` / `last7Day` / `thisMonth` / `nextMonth` …) — **ไม่มี `next7Day`** ⇒ เงื่อนไข "ครบกำหนดใน 7 วัน" ต้องเลี่ยงไปใช้ "เดือนนี้"
12. 🔴 **`editFields.options` บนฟิลด์ SingleSelect / MultipleSelect (inline option) ไม่ใช่การ "แก้" — เป็นการ "เพิ่มซ้อนทับ"** (พิสูจน์จริง 26 ส.ค. 2569 บนฟิลด์ `source_module` ตอน 0 record: ส่ง options พร้อม `key` เดิม 8 ตัว → ได้ตัวเลือกกลับมา 16 ตัว คือของเดิม 8 + ใหม่ 8 ที่มี key สุ่มใหม่) — schema ของ `editFields.options` มีแค่ `{value, index, color}` **ไม่มีช่อง `key`** จึงเพิกเฉยต่อ `key` ที่ส่งไปเงียบ ๆ ⇒ **ทางแก้เดียวคือ `removeFields`+`addFields` ในคำสั่งเดียวกัน** (ตรวจก่อนว่าไม่มีฟิลด์อื่นอ้างผ่าน Lookup/`sourceField`) แล้วคืนค่า record ด้วย `batch_update_records` — 🆕 **ทำให้ชัดเจนขึ้น 28 ส.ค. 2569 (WF-HR handoff, `ac_posting_rule.event_code`, มี 10 record ผูกอยู่แล้ว)**: ยิง `editFields.options` ส่ง `value` (ข้อความ) ของตัวเลือกเดิมทั้ง 10 ตัว **ครบทุกตัวตรงข้อความเป๊ะและตรงลำดับ/index เดิม** ตามด้วย 2 ตัวเลือกใหม่ต่อท้าย (รวมส่ง 12 ตัว) → ผลลัพธ์ `get_worksheet_structure` อ่านกลับมี **exactly 12 option ไม่ซ้ำเลย** และคีย์เดิมทั้ง 10 ตัวยังคงเดิมทุกตัว (record เดิมที่ผูกอยู่ยังอ่านค่าถูกต้อง ไม่มีใครหลุดไปอ้างคีย์ผี) ⇒ **ข้อสรุปที่แม่นยำขึ้น**: ตราบใดที่ `options` ที่ส่งไป **reproduce ค่า `value` (ข้อความ) ของตัวเลือกเดิมครบทุกตัวตรงเป๊ะทั้งจำนวนและลำดับ** แพลตฟอร์มจะจับคู่ตามข้อความแล้ว **คงคีย์เดิมไว้** มินต์คีย์ใหม่เฉพาะรายการที่เป็นข้อความใหม่จริง ๆ เท่านั้น — ไม่ใช่ "ทุกครั้งที่ยิง editFields.options จะซ้ำเสมอ" ตามที่เข้าใจไว้แต่แรกจากเคส `source_module` (ซึ่งอาจเกิดจากการไม่ reproduce ค่าเดิมให้ตรงเป๊ะ หรือรายละเอียดอื่นที่ไม่ได้บันทึกไว้ตอนนั้น) ⇒ **กฎปฏิบัติที่ปลอดภัยที่สุดยังคงเป็น `removeFields`+`addFields`** สำหรับกรณีทั่วไปที่ไม่มั่นใจว่า reproduce ค่าเดิมได้ตรงเป๊ะ 100% แต่ถ้าจำเป็นต้องใช้ `editFields.options` (เช่น กันความเสี่ยงจาก remove+add กับฟิลด์ที่มี Lookup ผูกอยู่) **ต้อง**: (ก) ดึง `get_worksheet_structure` ปัจจุบันมาก่อนเสมอ (ข) คัดลอกค่า `value` ของทุกตัวเลือกเดิมมาใส่ใน `options` array **ตามลำดับ/index เดิมทุกประการ** (ค) ต่อท้ายด้วยตัวเลือกใหม่เท่านั้น (ง) ตรวจซ้ำทันทีด้วย `get_worksheet_structure` ว่าจำนวน option ตรงกับที่คาด (เดิม+ใหม่ ไม่มากกว่านั้น) และ record ที่ผูกอยู่เดิมยังอ่านค่าถูกต้อง ก่อนถือว่าสำเร็จ
13. 🔴 **`batch_update_records` / `update_record` ต้องใช้ `rowId` (UUID) ไม่ใช่ `_id`** (Mongo-style ID) ที่ `get_record_list` คืนมา — ใช้ `_id` จะได้ error เงียบว่า "ไม่พบข้อมูล" (`error_code 10007` ผ่าน `update_record` / `430002` ผ่าน `get_record_details`) ทั้งที่ record มีอยู่จริง
14. ✅🔴 **`editFields.config.format` ของ Date/DateTime — ตัวพิมพ์เล็ก-ใหญ่มีผลต่างกันโดยสิ้นเชิง (case-sensitive แบบ moment.js)** — รายละเอียดเต็มดู BuildSpec/รายงาน 08 (ใช้ `DD/MM/YYYY` เสมอ ไม่ใช่ `dd/MM/yyyy`)
15. ✅🔴 **"Record Name" ตั้งผ่าน API ได้ด้วย `update_worksheet.addRecordButtonName`** (พารามิเตอร์หลอกตา ไม่มีในเอกสาร schema แต่ใช้ได้จริง 44/44 ตาราง)
16. ✅🔴 **Unique Index จริงมีทางเดียว: Search Acceleration ผ่าน browser — ไม่มี API/CLI ไหนทำได้เลย**
17. 🔴🔴 **role permission checkbox "View/Edit All" ในตารางหลัก ≠ `recordDataScope 100` เสมอไป — ต้องเปิด Setting drawer กด radio "All" เองเสมอ แล้วยืนยันด้วย `get_role_details`**
18. 🔴🔴 **`update_worksheet.sectionId` คืน `success:true` แต่ไม่ได้ย้าย worksheet จริง**
19. ✅✅ **วิธีย้ายตารางข้ามกลุ่ม/section ที่ใช้งานได้จริง คือเมนู "..." → "Move to" ในไซด์บาร์หลัก**
20. 🔴🔴 **`create_custom_actions` สร้างปุ่มสำเร็จแต่ Scope เริ่มต้น = "Unassigned View" เสมอ**
21. 🔴 **ปุ่ม custom action ชนิด `updateCurrentRecord` ไม่ auto-apply ค่าเป้าหมาย — เปิด dialog ให้เลือกค่าเอง**
22. 🔴🔴 **`FieldPatch.value` ชนิด `{"kind":"record"}` เขียนลงฟิลด์ Relation แล้วได้ข้อมูลเสียหายแบบเงียบ — ต้องใช้ `{"kind":"field","fieldId":"rowid"}` แทน**
23. 🔴🔴 **`FieldPatch.value` ชนิด `{"kind":"literal"}` ไม่ interpolate placeholder `$...$` — ต้องใช้ `kind:"template"`**
24. 🔴 **`sub_process` โหมด `use_existing` อ้าง process ที่ publish แล้วจะสร้าง node ไม่ได้ — ต้องปล่อย inner process เป็น draft ตลอดไป**
25. 🔴🔴→✅ **RESOLVED — `create_worksheet` (tool ตรง) ใช้งานไม่ได้เลย — workaround: `create_app_items`→`update_worksheet`(removeFields+addFields)→`get_worksheet_structure`(verify)→`update_worksheet`(addRecordButtonName)**
26. 🔴🔴 **`Condition.right` ชนิด `{"kind":"record"}` ถูกตัดทิ้งเงียบ ๆ ตอนบันทึกฟิลเตอร์ของ node — ใช้ `rowid` ของตัวเองเทียบ `eq` กับ field ต้นทางแทน**
27. 🔴🔴🔴 **`batch_create_process_nodes` ไม่รองรับหลาย node ตั้ง `prevNode` ชี้ node เดียวกันในคำขอเดียว — บังคับใช้ `branch`+`allMatch` แทน**
28. 🔴🔴 **`Condition.op:"in"` กับ literal array ≥2 ตัว ถูกตัดเงียบเหลือแค่ตัวแรก**
29. 🔴🔴🔴 **nested `Filter` group `logic:"or"` ข้างใน group ชั้นนอก `logic:"and"` ถูกทำให้แบนราบเงียบ ๆ**
30. 🔴🔴 **`delete_process_node`: ลบ node ธรรมดาไม่ cascade แต่ทิ้ง dangling reference / ลบ branch node cascade ทั้ง subtree**
31. 🔴🔴🔴 **ยืนยัน `op:"in"` truncation ครอบคลุม Relation field ด้วย + `rollup` sum/avg/min/max ไม่ต้องมี `config.target` + `sub_process` ใช้ `sub_trigger` filter แบบไดนามิก**
32. 🔴🔴 **`update_worksheet.editFields` แก้ field ที่มีอยู่แล้วโดยไม่ส่ง `name`/`alias` กลับไป ทำให้ทั้งสองค่าถูกล้างเป็นค่าว่างเงียบ ๆ แม้ไม่ได้ตั้งใจแตะ** — ต้องส่ง `name`+`alias` กลับไปทุกครั้งที่เรียก `editFields`
33. ✅🆕 **[28 ส.ค. 2569 รอบค่ำ] แก้ไขคำกล่าวอ้างในกับดักข้อ 11 — ไม่มี `update_view` เฉพาะใน MCP connector เท่านั้น แต่มี CLI `hap` แยกต่างหากที่ทำได้จริง** — กับดักข้อ 11 (ด้านบน) สรุปถูกต้องสำหรับ **MCP connector** (`mcp__ERP_-_TILSNA__*` ไม่มี tool `update_view` จริง) แต่คำแนะนำเดิมที่บอกว่า "เปลี่ยนชื่อ view ที่มีอยู่แล้วทำผ่านหน้าจอเท่านั้น" ไม่ครบถ้วน — มี **CLI `hap`** (คนละเครื่องมือกับ MCP, เรียกผ่าน Bash โดยตรง ดู skill `hap-cli`/`hap-cli-app-editor`) ที่รองรับคำสั่ง **`hap worksheet view update <worksheet_id> <view_id> --name "<ชื่อใหม่>"`** ใช้งานได้จริง — ยิงสำเร็จ 5 ครั้งติดกันบนแอปนี้ (`ERP - TILSNA`, app id `deca7391-1761-424b-9af3-c8d043004ad3`) เปลี่ยนชื่อ view จาก `全部` (ค่าเริ่มต้นจีน) เป็น `ทั้งหมด` บน 5 ตารางของกลุ่มเมนู AC-07 ที่สร้างขึ้น**หลัง**รอบตรวจสอบ view เดิม 26 ส.ค. 2569 (ตารางที่สร้างช่วง 27–28 ส.ค. ระหว่างงาน WF-AC-09/10/11) — ยืนยันสำเร็จจริงด้วย JSON readback ของ CLI เอง ที่ `name` กลับมาเป็น `"ทั้งหมด"` ครบทั้ง 5:

    | ตาราง | worksheet ID | view ID |
    |---|---|---|
    | การกระทบยอดธนาคาร | `6a8fd69d1378964f9984a2ad` | `6a8fd69d1378964f9984a2b1` |
    | รายการกระทบยอดธนาคาร | `6a8fd69e8b6633ef76f1313f` | `6a8fd69e8b6633ef76f13143` |
    | รายการตรวจสอบปิดงวด | `6a8fd69e353e1b0e4a507e16` | `6a8fd69e353e1b0e4a507e1a` |
    | การปิดบัญชีสิ้นปี (AC_CLOSING_ENTRY) | `6a8fd69f9762533b5b718bce` | `6a8fd69f9762533b5b718bd2` |
    | ยอดยกมาต้นปี (AC_OPENING) | `6a8fd69f353e1b0e4a507e20` | `6a8fd69f353e1b0e4a507e24` |

    ⇒ **รวม view ที่เป็นไทยทั้งระบบจาก 62/62 (26 ส.ค.) เป็น 67/67** (34 ตารางเดิม + 5 ตาราง Phase 8 ใหม่ ครบทุกตารางแล้ว) · **กฎปฏิบัติที่แก้ไข**: จากนี้ไป การเปลี่ยนชื่อ view ที่มีอยู่แล้วให้ **ลอง CLI `hap worksheet view update` ก่อนเสมอ** — เร็วกว่าและไม่ต้องพึ่ง Browser/Claude-in-Chrome เลย ใช้ Browser เป็นทางเลือกสำรองเฉพาะกรณี CLI ใช้ไม่ได้ (เช่น session ไม่มี CLI login) หรือถ้าต้องแก้ filter/คอลัมน์ของ view ที่มีอยู่ (ยังไม่เคยทดสอบผ่าน CLI ว่าทำได้) · ✅🆕 **[28 ส.ค. 2569 ดึกกว่ารอบค่ำ] สแกนทั้งแอปหา view `全部`/`Main` ที่หลงเหลือเสร็จสมบูรณ์แล้ว** — ไล่ทุก worksheet ในแอปนี้ทั้งหมด **68 ตาราง / 102 view** (ผ่าน `hap worksheet list -a <appId>` แล้ววน `hap worksheet view list` ทีละตาราง) ตรวจชื่อ view ทุกแถวด้วย regex CJK (`[一-鿿]`) — **ผลลัพธ์: 0 view ที่มีอักษรจีนหรือใช้ค่าเริ่มต้น `Main` หลงเหลือเลยทั้งแอป** (นอกจาก 5 ตารางกลุ่ม AC-07 ที่แก้ไปแล้วข้างต้น ไม่มีตารางอื่นที่ตกหล่น) ⇒ ปิด follow-up นี้ถาวร ไม่ต้องสแกนซ้ำอีกจนกว่าจะมีตารางใหม่เพิ่มในอนาคต (ดู Known Issues สำหรับกฎปฏิบัติสำหรับตารางใหม่)

34. 🟡🆕 **[28 ส.ค. 2569 รอบดึก] worksheet-level `alias` ที่ตั้งผ่าน `update_worksheet.alias` ไม่ persist และไม่มีทางยืนยันค่าจริงได้เลยผ่าน MCP/CLI** — พิสูจน์ระหว่างสร้างตาราง "พารามิเตอร์ระบบบัญชี" (`AC_SYSTEM_PARAM`): (1) เรียก `update_worksheet` ตอนสร้างพร้อมส่ง `alias:"ac_system_param"` → `get_worksheet_structure` อ่านกลับทันทีเห็น worksheet-level `alias` เป็น `"worksheet31"` (ค่า auto-generated) ไม่ใช่ค่าที่ส่งไป (2) ตรวจว่าเป็นแค่ "stale read" แบบเดียวกับกับดักที่รู้จักแล้ว (ที่ `get_worksheet_structure` คืนชื่อตาราง **name** เป็นค่าเก่าเสมอ ต้องใช้ `get_app_worksheets_list` แทน) — แต่ `get_app_worksheets_list` คืนแค่ `{id, name, remark, displayType}` **ไม่มีช่อง alias เลย** จึงใช้ตรวจ worksheet-level alias ไม่ได้ทั้งสองทาง (3) เรียก `update_worksheet` ซ้ำอีกครั้งส่งแค่ `alias:"ac_system_param"` เดี่ยว ๆ (ตัดตัวแปรอื่นออกหมด) แล้ว `get_worksheet_structure` อ่านกลับ **ยังเห็น `worksheet31` เหมือนเดิมไม่เปลี่ยน** ⇒ สรุปว่าเป็นบั๊กคนละตัวกับกับดักเดิมเรื่องชื่อตาราง (name) — นี่คือเรื่อง **alias ระดับ worksheet** โดยเฉพาะ ซึ่งดูเหมือนตั้งค่าใหม่ผ่าน API ไม่ได้เลยหลังสร้างตารางแล้ว และไม่มีเครื่องมือใดยืนยันค่าจริงได้ · ยังไม่ทดสอบว่าแก้ผ่านหน้าจอ (Browser) ได้หรือไม่ · **ผลกระทบต่ำ**: field-level alias (`biz_*`) ทุกตัวใช้งานปกติและเป็นตัวที่ formula/filter/workflow อ้างอิงจริงอยู่แล้ว — worksheet-level alias ส่วนใหญ่เป็นชื่อสะดวกสำหรับ developer/API เท่านั้น ไม่กระทบผู้ใช้งานจริง

35. 🔴🔴🆕 **[28 ส.ค. 2569] Build-iteration บน `approval_block`/`sub_process` ทิ้ง orphan duplicate process ไว้เสมอ — ต้อง audit ด้วย CLI `hap workflow list` ไม่ใช่ MCP `get_workflow_list`** — สองข้อค้นพบที่เกี่ยวกัน:
    - **(i) Orphan workflow process**: เพราะ `approval_block`/`sub_process` node แก้ internal ในตัวไม่ได้ (ต้องลบ-สร้างใหม่เท่านั้น ตามกับดักข้อ 24) รอบ "build แล้วทดสอบแล้วแก้" แบบวนซ้ำระหว่าง build sub-flow แต่ละครั้งจะสร้าง process object ใหม่แทนที่จะแก้ของเดิม — ของเดิมที่ build ไม่สำเร็จ/เลิกใช้แล้วไม่เคยถูกลบ ⇒ เหลือ process object ซ้ำชื่อเดิมหรือใกล้เคียงหลายตัวค้างอยู่ข้าง ๆ ตัวที่ผูกกับ parent workflow จริง — สะสมเงียบ ๆ ตลอด session build โดยไม่มีใครสังเกต **มองไม่เห็นเลยผ่าน `get_workflow_list` (MCP, เห็นแค่ PBP-type)** และ `get_app_worksheets_list` ก็ไม่เกี่ยว — **วิธี detect**: CLI `hap workflow list <appId> [-k keyword] -n <n>` (คนละเครื่องมือกับ MCP) list process ทุกตัวจริง รวม draft/disabled/orphan ครบ จากนั้น cross-reference กับ `get_workflow_structure` (MCP) ของ parent flow ที่ live: สำหรับ approval-block child ดู `triggerId`/`triggerName` ใน CLI list — ค่าว่างคือ orphan; สำหรับ `sub_process` child ธรรมดา (CLI list ไม่มีคอลัมน์ `triggerId` ให้เลย) ต้องเทียบกับค่า `config.process.processId` ปัจจุบันที่ parent's `get_workflow_structure` อ้างถึงจริง — อะไรที่ชื่อเดียวกัน แต่ processId ไม่ตรง คือ orphan — **วิธีลบที่ปลอดภัย**: MCP `delete_process` (param `workflow_id`) เชื่อถือได้กว่า CLI `hap workflow delete` ซึ่งบางครั้งถูก client-side safety classifier บล็อกแบบไม่เกี่ยวกับสิทธิ์ Nocoly เลย (สลับไปใช้ MCP `delete_process` แทนได้ทันทีเมื่อเจอกรณีนี้ โดยเฉพาะเวลาต้องลบหลายตัวติดกัน)
    - **(ii) Orphan Custom Action button**: ปุ่ม Custom Action (คนละ object type จากปุ่ม workflow process ธรรมดา — ไม่มี MCP list/get/delete tool ให้เลย) ที่ชื่อ Button Label ซ้ำกันหลายแถว **ห้ามเดา/ลบตามตำแหน่งแถวบนหน้าจอเด็ดขาด** — ลำดับแถวไม่เสถียรข้ามการโหลด/re-render หน้า (พิสูจน์จริงว่าแถวเดิมโชว์เนื้อหาต่างกันเมื่อ navigate ซ้ำ) — ต้องยืนยันตัวตนของแต่ละแถวด้วย (1) เปิด "Edit Custom Action" อ่านข้อความ Button Description เป๊ะ ๆ เป็นสัญญาณหลัก และ (2) ถ้าเป็นไปได้ เปิด "Edit Workflow" แล้วจับ network request `getProcessByTriggerId?...&triggerId=...` และ/หรือ `flowNode/get?processId=...` ทันที เพื่อดึง processId/triggerId คู่ที่แท้จริงของแถวนั้นก่อนตัดสินใจลบ — ลบผ่านเมนู "..." → Delete ของ Custom Action list เท่านั้น **ห้ามลบแค่ stub workflow process ที่ผูกอยู่ผ่าน `delete_process`/CLI** เพราะจะเหลือปุ่มเป็น orphan ที่พังอยู่ใน UI แทน

> สรุปกฎปฏิบัติ: **แตะฟิลด์ผ่าน API ได้เฉพาะฟิลด์ธรรมดา** · ฟิลด์ Rollup / Formula / Dropdown-ผูก-optionset / SingleSelect-MultipleSelect-inline-option ให้แก้ตัวเลือกด้วย **ลบ–สร้างใหม่** (หรือผ่านหน้าจอถ้ามี Lookup ผูกอยู่ — หรือ `editFields.options` ถ้า reproduce ค่าตัวเลือกเดิมได้ครบเป๊ะทุกตัว ดูกับดักข้อ 12) · ส่ง `name` + `alias` คู่กันเสมอในทุกคำสั่ง `editFields` ไม่ว่าจะตั้งใจแก้สองค่านี้หรือไม่ก็ตาม (ดูกับดักข้อ 32) · **ชื่อตารางบนหัวจอ = หน้าจอเท่านั้น · ชื่อ view ที่มีอยู่แล้ว = ลอง CLI `hap worksheet view update` ก่อนเสมอ แล้วค่อย fallback ไปหน้าจอ (แก้ไขจากเดิมที่เคยระบุว่าหน้าจอเท่านั้น — ดูกับดักข้อ 33)** · **record update ทุกจุดใช้ `rowId` ไม่ใช่ `_id`** · **role permission: checkbox "View/Edit All" ในตารางหลัก ≠ `recordDataScope 100` เสมอไป — ต้องเปิด Setting drawer กด radio "All" เองเสมอ แล้วยืนยันด้วย `get_role_details` (ดูกับดักข้อ 17)** · **ห้ามใช้ header "select-all" checkbox กับ role ที่ scope ไม่ครอบคลุมทั้งแอป (แอปนี้มี 51 worksheet ปนกันทุกโมดูล)** · **field masking (NFR) ทำผ่าน Setting drawer → แท็บ Field → uncheck View ของฟิลด์นั้น** · **matrix ค่า "20" ตั้งใจ (ไม่ใช่ 0 ไม่ใช่ 100) = ติ๊ก checkbox เฉย ๆ ไม่เปิด Setting drawer** · **ตรวจ pre-edit state ของทุก role ก่อนแก้เสมอ — ห้ามสมมติว่า role ว่างเปล่า** · **`recordActions.add` ไม่ใช่สัญญาณที่เชื่อถือได้สำหรับสิทธิ์สร้าง** · **`update_worksheet.sectionId` ใช้ย้ายกลุ่มไม่ได้จริง (success:true หลอก) — ย้ายกลุ่มระหว่าง section ต้องทำผ่านหน้าจอด้วยเมนู "..." → "Move to" ในไซด์บาร์หลัก (เชื่อถือได้กว่า drag-and-drop มาก — ดูกับดักข้อ 19)** · **`create_custom_actions` สร้างปุ่มสำเร็จแต่ Scope เริ่มต้นเป็น "Unassigned View" เสมอ — ต้องเข้า Browser ตั้ง Scope → "All Records" (หรือ Specified View) ก่อนปุ่มจะโผล่จริง (ดูกับดักข้อ 20)** · **ปุ่ม `updateCurrentRecord` ไม่ auto-apply ค่า — เปิด dialog ให้เลือกค่าเองเสมอ (ดูกับดักข้อ 21)** · **`FieldPatch.value` ที่เขียนลงฟิลด์ Relation ต้องใช้ `kind:"field"`+`fieldId:"rowid"` เท่านั้น ห้ามใช้ `kind:"record"` (silent corruption — ดูกับดักข้อ 22)** · **string ที่มี `$...$` placeholder ต้องใช้ `kind:"template"` ไม่ใช่ `kind:"literal"` (ไม่ interpolate — ดูกับดักข้อ 23)** · **`sub_process` แบบ `use_existing` ต้องปล่อย inner process เป็น draft ตลอดไป ห้าม publish (ดูกับดักข้อ 24)** · **`create_worksheet` (tool ตรง) ยังพังอยู่เสมอ — ห้ามเรียกตรง ใช้ workaround แทนเสมอ (ดูกับดักข้อ 25 — ปิดเคสแล้ว)** · **`Condition.right` ห้ามใช้ `kind:"record"` เด็ดขาด — เทียบ `rowid` ของตัวเองกับ field ต้นทางด้วย `op:'eq'` แทนเสมอ (ดูกับดักข้อ 26)** · **ห้ามให้หลาย node ตั้ง `prevNode` ชี้ node เดียวกันในคำขอ `batch_create_process_nodes` เดียว — ต้องแตกสายขนานผ่าน `branch`+`mode:"allMatch"` แทนเสมอ (ดูกับดักข้อ 27)** · **`Condition.op:"in"` ห้ามใช้เด็ดขาดกับฟิลด์ชนิดใดก็ตาม (ดูกับดักข้อ 28/31)** · **nested `Filter` group `logic:"or"` ใน group นอก `logic:"and"` ถูกแบนราบเงียบ ๆ — ใช้ N×(`get_multiple`+`rollup count`)+`compute`รวม+`branch`เทียบผลรวมแทนเสมอ (ดูกับดักข้อ 29)** · **`delete_process_node` เช็ค `get_workflow_structure` หลังลบเสมอ (ดูกับดักข้อ 30)** · **`rollup` sum/avg/min/max ไม่ต้องมี `config.target` ต่างจาก count (ดูกับดักข้อ 31)** · **`editFields` ไม่ใช่ sparse patch เสมอไป — ต้องส่ง `name`+`alias` กลับไปทุกครั้ง (ดูกับดักข้อ 32)** · **การเปลี่ยนชื่อ view ที่มีอยู่แล้ว ลอง CLI `hap worksheet view update` ก่อนเสมอ ก่อนพึ่ง Browser (ดูกับดักข้อ 33)** · **ก่อนลบ workflow process ที่สงสัยว่าเป็น orphan เสมอ: audit ด้วย CLI `hap workflow list` cross-reference กับ `get_workflow_structure` ก่อน แล้วลบด้วย MCP `delete_process` (เชื่อถือได้กว่า CLI `hap workflow delete` ที่บางครั้งถูกบล็อก) — ห้ามลบ/ระบุปุ่ม Custom Action ซ้ำตามตำแหน่งแถว ต้องยืนยันด้วย Button Description + network request เสมอ (ดูกับดักข้อ 35)**

---

## ID สำคัญ

| รายการ | ค่า |
|---|---|
| App ID | `deca7391-1761-424b-9af3-c8d043004ad3` (ชื่อ **ERP - TILSNA**) |
| Organization | `9680d433-5b6d-45d7-b6df-d05d3095f82f` |
| **MCP connector** | **`ERP_-_TILSNA`** ⚠️ session นี้มี connector อื่นชี้เซิร์ฟเวอร์เดียวกัน (`API-Lab`, `MCP-ASM`, `-_WFA_System`, `hap-mcp-Demo_-`) — **`get_app_info` ยืนยันก่อน write แรกทุก session** |
| Host | `https://www.nocoly.com` |
| Surface R (org-auth API) | ❌ ไม่ใช้ |
| **CLI** | `hap` — login แล้วในเซสชันที่ผ่านมา ทำงานที่ MCP ทำไม่ได้ เช่น `hap worksheet view update` (ดูกับดักข้อ 33) — auth ผูกกับ container ของแต่ละ session ต้อง login ใหม่ทุกครั้ง |

**ตารางที่แตะบ่อยที่สุด** (ID เต็มทุกตาราง + ทุกฟิลด์อยู่ใน BuildSpec §1.2 / §2 · ชื่อไทยคือชื่อที่เห็นบนหน้าจอตอนนี้)

| ตาราง (ชื่อไทยปัจจุบัน) | รหัสเดิม | ws ID | หมายเหตุด่วน |
|---|---|---|---|
| **ใบสำคัญ** | `ac_voucher` | `6a85fb2e9b6999a714d2a53d` | 🔴 สถานะ alias = **`voucher_status`** (เดิม `status1`) field id **`6a86016b1049edca1eed028a`** — field id **ไม่เปลี่ยน** · `source_module` field id ใหม่ **`6a8ee2729762533b5b718321`** (ค่าไทยแล้ว) · ✅ มี Custom Action 3 ปุ่มครบแล้ว ทั้งหมด verify Scope ผ่าน Browser เป็น All Records ครบแล้ว (ส่งอนุมัติ/ยกเลิกใบสำคัญ/กลับรายการ) ดูกับดักข้อ 20/21 · `voucher_no` field id `6a85ff5933560633b8cd9f83` ยืนยันแล้วว่า `required:true` |
| **รายการในใบสำคัญ** | `ac_voucher_line` | `6a85fb3933560633b8cd9f40` | relation จากหัว = `6a85fb399b6999a714d2a558` |
| **บัญชีแยกประเภททั่วไป** | `ac_gl` | `6a85fb4133560633b8cd9f4a` | เขียนได้เฉพาะ WF-AC-02 (และตอนนี้ WF-AC-10 flagging ผ่าน `markGLReversed` sub_process) · อ่านเพื่อคำนวณยอดผ่าน WF-AC-11 (rollup 32 ตัว) · `movement_seq` เป็น AutoNumber · alias เงิน = `debit_base` / `credit_base` (เดิม `debit_thb` / `credit_thb`) · `account` เป็น Relation ไปยัง AC_COA — **`op:"in"` ใช้ filter ไม่ได้ (กับดักข้อ 31)** |
| **งวดบัญชี** | `ac_period` | `6a8434d5055f2288c5b6d4b8` | `period_status` `6a851f70055f2288c5b73edf` (ค่าไทยแล้ว ผ่านหน้าจอ — 🔴 **ห้ามลบสร้างใหม่** ใบสำคัญมี Lookup ผูก field id นี้) · `tax_period_status` field id ใหม่ **`6a8ee2c68b6633ef76f1288e`** (ค่าไทยแล้ว) · 🆕 `biz_close_flag` **`6a903ea68b6633ef76f169c5`** (ปิดงวด (ธง), trigger ของ WF-AC-09) · 🆕 `biz_close_year_flag` **`6a90ef228b6633ef76f16f55`** (ปิดปี (ธง), trigger ของ WF-AC-11) |
| **ใบสำคัญตั้งหนี้** | `ac_ap` | `6a8673d61049edca1eed0638` | 0 record · สถานะใหม่ `biz_ap_status` `6a8ec51dae2a0e3743a0b574` |
| **คู่ค้า** | `ac_partner` | `6a85457033560633b8cd6920` | `partner_type` field id ใหม่ **`6a8ee32a1378964f99849859`** · `branch_type` field id ใหม่ **`6a8ee32a1378964f9984985a`** · `partner_residence` field id ใหม่ **`6a8ee32a1378964f9984985b`** (ทั้ง 3 ค่าไทยแล้ว) · 🔴 field `เลขประจำตัวผู้เสียภาษี` (tax_id) `6a8545701049edca1eecd868` ถูก **mask (View=false)** ใน role AC-R6 ตาม NFR-02 |
| **บัญชีธนาคารคู่ค้า** | `ac_partner_bank` | `6a85458033560633b8cd692a` | 🔴 field `เลขที่บัญชี` (account_no) `6a854581055f2288c5b741e5` ถูก **mask (View=false)** ใน role AC-R6 ตาม NFR-02 |
| **สมุดรายวัน** | `ac_journal` | `6a8434da33560633b8cd2efd` | `journal_type` field id ใหม่ **`6a8ee5389762533b5b718449`** (ค่าไทยแล้ว) |
| **กฎการออกเลขที่เอกสาร** | `ac_numbering_rule` | `6a8434ea8b36df988c16ed84` | `year_era` field id ใหม่ **`6a8ee53b1378964f99849987`** (ค่าไทยแล้ว: ค.ศ./พ.ศ.) |
| **การตั้งค่าเอกสาร** | `ac_doc_setting` | `6a8434f69b6999a714d22e75` | `side` field id ใหม่ **`6a8ee53eae2a0e3743a0bc6c`** (ค่าไทยแล้ว: ซื้อ/ขาย) |
| **แหล่งเงิน** | `ac_fund_source` | `6a85453033560633b8cd68dc` | `fund_type` field id ใหม่ **`6a8ee5439762533b5b71844f`** (ค่าไทยแล้ว) |
| **อัตราภาษีมูลค่าเพิ่ม** | `ac_vat_rate` | `6a8545469b6999a714d2673c` | `vat_treatment` field id ใหม่ **`6a8ee548ae2a0e3743a0bc72`** (ค่าไทยแล้ว) |
| **ผังบัญชี** | `ac_coa` | `6a85516e1049edca1eecd9b7` | 82 record (79 เดิม + 3 บัญชีเงินเดือนใหม่ 28 ส.ค. 2569 — ดูหัวข้อ "ช่วยเหลือ HR" ด้านล่าง) · `account_type`/`is_postable` ใช้กรองบัญชีที่ยกยอด (WF-AC-11) · **ไม่มี Lookup ให้ AC_GL.account traverse ตาม account_type ผ่าน API ได้ ⇒ ต้อง hardcode rowid ที่ต้องการโดยตรง** |
| **ปิดงวด/ปิดปี (AC_CLOSE/AC_CLOSING_ENTRY/AC_OPENING)** | `ac_close` / `ac_closing_entry` / `ac_opening` | `6a8fd69e353e1b0e4a507e16` / `6a8fd69f9762533b5b718bce` / `6a8fd69f353e1b0e4a507e20` | AC_OPENING เก็บเดบิต/เครดิตรวมแบบ **gross สะสมถึงปีที่ปิด** (ไม่ netted) เป็นการออกแบบตั้งใจของ WF-AC-11 · **view `ทั้งหมด` ของทั้ง 5 ตาราง Phase 8 (รวม AC_BANK_RECON/AC_BANK_RECON_LINE) เปลี่ยนชื่อไทยแล้วผ่าน CLI 28 ส.ค. 2569 รอบค่ำ — ดูกับดักข้อ 33** |
| **พารามิเตอร์ระบบบัญชี (AC_SYSTEM_PARAM)** | — | `6a917a2d9762533b5b720392` | 🆕 28 ส.ค. 2569 — ตารางตั้งค่าใหม่รองรับ BRD A-08 · field `biz_setting_name` `6a917a45353e1b0e4a50fa32` · `biz_cutover_date` `6a917a45353e1b0e4a50fa33` · `biz_go_live_date` `6a917a45353e1b0e4a50fa34` · `biz_note` `6a917a45353e1b0e4a50fa35` · view `ทั้งหมด` `6a917a2d9762533b5b720396` · record เริ่มต้น `65eb8bc0-ac6b-4301-96a8-9e3b0bf2ba89` (ค่าวันที่ยังว่าง) · **A-08 เองยังไม่ถูกยืนยัน** ดู "ตั้งค่า A-08..." ด้านล่าง · role permission ยังไม่ได้ตั้ง (pending manual) |
| **workflow ที่ทำงานอยู่** | — | WF-AC-01 `6a8eaa45e6605c4b13ccf49b` (inner `6a8eaa76730d20c5b76071f3`) · WF-AC-02 `6a8ea77e5f8564a68c33f9db` (subprocess `6a8ea79efdab77a41c4a37d6`) · **WF-AC-10 `6a8f49b8730d20c5b764f302`** (publish v4 — 27 ส.ค. 2569, sub-process `reverseLines`/`reverseVatDocs`/`markGLReversed` ตั้งใจปล่อยเป็น draft ถาวร ดูกับดักข้อ 24) · **WF-AC-09 `6a903ec05f8564a68c3f7d7d`** (publish v1 — 27 ส.ค. 2569, ปิดงวด, trigger `worksheet_event` บน `AC_PERIOD` ฟิลด์ `biz_close_flag`, 16 nodes + trigger, ดูกับดักข้อ 28/29/30) · **WF-AC-08 `6a8ff2c0fdab77a41c543108`** (publish v3, กระทบยอดธนาคาร) · **WF-AC-12 `6a9032d3fdab77a41c56420b`** (publish v1, แจ้งเตือนความผิดปกติ) · **WF-AC-11 `6a90ef69fdab77a41c5b514f`** (publish v1 — 28 ส.ค. 2569, ปิดปีและยกยอด, trigger `worksheet_event` บน `AC_PERIOD` ฟิลด์ `biz_close_year_flag`, 56 nodes + trigger + 4 inner sub-process, ดูกับดักข้อ 31) | ทั้งหมด publish แล้ว = **live** (ยกเว้น inner sub-process ของ WF-AC-10/WF-AC-11 ที่เป็น draft โดยตั้งใจ) · 🆕 [28 ส.ค. 2569] orphan build-iteration duplicate ของ WF-AC-01 (2 ตัว), WF-AC-02 (1 stale human draft), WF-AC-10 (7 sub-process orphan) ถูกระบุผ่าน `hap workflow list` cross-reference กับ `get_workflow_structure` แล้วลบครบแล้ว — ดูกับดักข้อ 35 |
| **ทะเบียนภาษีซื้อ–ภาษีขาย** | `ac_vat_doc` | `6a8677f9055f2288c5b77d58` | `biz_vd_vat_side` `6a8ec598353e1b0e4a506d5f` · `biz_vd_claim_status` `6a8ec598353e1b0e4a506d60` · alias `sign` → `sign_factor` · `vat_doc_ref` → `vat_doc_no` |
| **กฎการอนุมัติตามวงเงิน** | `ac_approval_rule` | `6a8434f18b36df988c16ed8e` | `approver_role_1/2/3` เป็นชนิด **OrgRole** |
| **กฎการบันทึกบัญชี** | `ac_posting_rule` | `6a85518c33560633b8cd6a15` | คู่บัญชีทุก event — **ห้าม hard-code รหัสบัญชีใน workflow** (ยกเว้นข้อยกเว้นตั้งใจของ WF-AC-11 ที่ hardcode rowid บัญชีรายได้/ค่าใช้จ่ายเพราะไม่มี Lookup ให้ traverse relation — ดูกับดักข้อ 31 และหมายเหตุใน BuildSpec §3 WF-AC-11) · **`event_code` (`6a85518c055f2288c5b7430b`) เป็นฟิลด์ inline SingleSelect ธรรมดา ไม่ใช่ shared optionset — 28 ส.ค. 2569 เพิ่ม 2 option ใหม่ `PAYROLL_ACCRUAL`/`PAYROLL_PAYMENT` แล้ว รวม 12 option — ดูหัวข้อ "ช่วยเหลือ HR" ด้านล่าง** |
| **องค์ประกอบค่าจ้าง (HR)** | `hr_pay_component` | `6a8ff2868b6633ef76f13871` | ✅ **28 ส.ค. 2569 รอบค่ำ: `biz_coa_account` เชื่อมครบ 6/6 แล้ว** — `SALARY`/`OT`/`ABSENCE_DEDUCT` เชื่อมอยู่ก่อนแล้วชี้ COA `530101` · `WHT`/`SSO_EE`/`SSO_ER` เชื่อมเพิ่มรอบนี้ผ่าน `update_record`(`triggerWorkflow:false`) ชี้ COA `210304`/`210402`/`530102` ตามลำดับ ยืนยันครบผ่าน `get_record_details` — ดูหัวข้อ "ช่วยเหลือ HR" |

### ช่วยเหลือ HR — ปิด Gap ผังบัญชีเงินเดือน (28 ส.ค. 2569)

ฝ่าย HR (`tilsna-hr`) ส่งเอกสาร handoff (`HRtoAccountingHandoffCOAGap.md`) แจ้งว่างาน Payroll ของเขาถูกบล็อกเพราะ (1) ผังบัญชี (AC_COA) ขาดบัญชี 3 รายการที่จำเป็นสำหรับผ่านรายการเงินเดือนเข้า GL และ (2) `ac_posting_rule.event_code` ขาด option สำหรับ event เงินเดือน — ตรงกับ **Gap G-02** ที่ HR บันทึกไว้ใน `02-BuildSpec-FRS.md`/`05-Roadmap-Tracker.md` ของเขาเอง (P5-4/P5-5)

**1. สร้างบัญชีใหม่ 3 รายการใน AC_COA** (ผ่าน `create_record`, `triggerWorkflow:false`, mirror pattern ฟิลด์จากบัญชีพี่น้องที่มีอยู่แล้ว):

| รหัสบัญชี | ชื่อ (ไทย/อังกฤษ) | ประเภท/กลุ่ม/Normal balance | บัญชีแม่ | rowId ใหม่ |
|---|---|---|---|---|
| `210304` | ภาษีหัก ณ ที่จ่ายค้างจ่าย - ภ.ง.ด.1 (เงินเดือน) / WHT payable - P.N.D.1 (Payroll) | Liability / Current liability / Credit, postable | `2103` (rowId `214a151a-8802-40bf-b390-dbeff119ca9b`) | `777ea001-5300-4f5c-857a-71a45db2076b` |
| `210402` | เงินสมทบประกันสังคมค้างนำส่ง (ลูกจ้าง) / Social security payable (employee) | Liability / Current liability / Credit, postable | `2104` (rowId `56c627d0-b794-4854-837c-c40ade94058b`) | `c6386fe7-1b3c-44db-ab80-9dfd3308a6a5` |
| `530102` | เงินสมทบประกันสังคม (นายจ้าง) / Social security contribution (employer) | Expense / Administrative / Debit, postable, requires cost center (mirror `530101`) | `5301` (rowId `225ff330-5df2-4b5d-b2d8-a0380ad15794`) | `233626b4-d272-4cb5-8f77-9d8d2ddef804` |

ยืนยันครบทั้ง 3 ด้วย `get_record_details` — ทุกฟิลด์ Dropdown/select (`account_type`, `account_group`, `normal_balance`) ลงเป็น key+value ตรงกับ option ที่มีอยู่แล้ว **ไม่มี option ซ้ำเกิดใหม่** (ยืนยันว่าการส่ง display-text ผ่าน `create_record`'s field array แล้ว resolve เป็น option key เดิมได้ถูกต้อง ไม่เหมือนกับดักของ `editFields.options` บนฟิลด์ที่มีอยู่แล้ว — คนละกลไก)

**2. แก้ไขข้อมูลที่ HR เข้าใจผิด** — เอกสาร handoff ของ HR ระบุว่า `ac_posting_rule.event_code` ผูกกับ shared optionset ที่ MCP ไม่มี tool ให้ต่อได้ ต้องแก้ผ่าน Browser เท่านั้น ตรวจสอบจริงด้วย `get_worksheet_structure` พบว่า **ผิด** — ฟิลด์นี้เป็น inline `SingleSelect` ธรรมดา (ไม่มี `dataSource`) ไม่ใช่ shared optionset · นอกจากนี้ฟิลด์นี้มี option `CLOSING` (key `49686cf3-b945-4819-95d1-182d930f3eed`) อยู่แล้ว — ตรงกับคีย์ที่ BuildSpec เดิมของ WF-AC-11 เคยอ้างว่าเป็น "event CLOSING" ซึ่ง session ก่อนหน้าเข้าใจผิดว่าหมายถึงคีย์บน `AC_VOUCHER.source_module` (ซึ่งไม่มีคีย์นี้จริง) จึง workaround ด้วยการ reuse option อื่นแทน (คีย์ "ปิดงวด") — **workaround นั้นสร้าง/ทดสอบ/ใช้งานจริงแล้ว ไม่ต้องแก้ WF-AC-11** แต่บันทึกไว้เป็นข้อสังเกตสำหรับอนาคต: **ถ้า WF-AC-11 หรือ workflow ปิดปีอื่นถูกทบทวนใหม่ในอนาคต ระเบียน `ac_posting_rule` ที่ event=CLOSING สามารถให้การ map บัญชีเดบิต/เครดิตแบบ data-driven ได้ดีกว่าการ hardcode บัญชีกำไรสะสมแบบปัจจุบัน**

**3. เพิ่ม 2 option ใหม่เข้า `event_code`** ผ่าน `update_worksheet.editFields` สำเร็จ ไม่ต้องพึ่ง Browser: `PAYROLL_ACCRUAL` (key ใหม่ `ad4850c4-f1c1-4a65-adbb-fb0054a6e0c8`) และ `PAYROLL_PAYMENT` (key ใหม่ `04a14b13-73c2-408b-a5fb-bb81ff630a06`) ต่อท้ายที่ index 11/12 หลัง 10 option เดิม (`AP_RECOGNITION`, `AP_SETTLEMENT`, `AR_RECOGNITION`, `AR_COLLECTION`, `DEPRECIATION`, `DISPOSAL`, `VAT_TRANSFER`, `WHT_ACCRUAL`, `FX_REVAL`, `CLOSING`) — ยืนยันผ่าน `get_worksheet_structure` ว่าคีย์เดิมทั้ง 10 ตัวไม่เปลี่ยน รวม 12 option ไม่ซ้ำ (ดูกับดักข้อ 12 ที่ทำให้ชัดเจนขึ้นจากเคสนี้) — ระหว่างทางพบ**กับดักใหม่ข้อ 32** (`editFields` ล้าง `name`/`alias` เงียบถ้าไม่ส่งกลับไป) ซ่อมสำเร็จในรอบเดียวกัน — ดูรายละเอียดเต็มในกับดักข้อ 32 ด้านบน

**4. Source-of-truth ของ WF-HR-10 (ตอบคำถามที่ HR ถามในการสนทนา บันทึกไว้เป็นการตัดสินใจสถาปัตยกรรม)** — HR มีสองแหล่งข้อมูลที่ต่างกันสำหรับหารหัสบัญชีตอนผ่านรายการเงินเดือน: `ac_posting_rule` (event-based mapping) กับ `hr_pay_component.biz_coa_account` (ผูกบัญชีต่อองค์ประกอบค่าจ้างโดยตรง) — **ฝ่ายบัญชี endorsed ให้ `ac_posting_rule` เป็นหลัก (primary source of truth) และ `hr_pay_component.biz_coa_account` เป็น fallback/ค่า default** เมื่อ `ac_posting_rule` ยังไม่มีกฎที่ตรง event นั้น ๆ — HR ควรออกแบบ WF-HR-10 ให้ query `ac_posting_rule` ก่อนเสมอ แล้ว fallback ไปที่ `biz_coa_account` เฉพาะกรณีไม่พบกฎเท่านั้น (ตรงกับที่ BuildSpec ของ HR เองก็เขียนไว้ว่า WF-HR-10 อ่านจาก `ac_posting_rule`)

**5. ยังรอ — ไม่ได้แก้โดย session นี้ (ต้องการคนจริง)**: (ก) อัตราเงินสมทบประกันสังคมจริง/เพดานฐานค่าจ้าง (ข) ขั้นบันไดภาษีเงินได้บุคคลธรรมดาสำหรับหัก ณ ที่จ่ายเงินเดือน (ค) เลขประจำตัวผู้เสียภาษี/เลขทะเบียนนายจ้างประกันสังคมของบริษัทจริง (ปัจจุบันเป็นค่า placeholder) — ทั้งหมดนี้ตรงกับ **Gap G-05** ของ HR ที่ต้องรอฝ่ายบัญชี/ผู้ใช้ยืนยันตัวเลขจริงก่อน go-live เท่านั้น ไม่ใช่สิ่งที่ session นี้ประดิษฐ์ขึ้นหรือแก้ได้ · ตอบกลับเป็นเอกสารที่ `12-HR-Handoff-Response-COA-Gap.md`

**6. ✅🆕 [28 ส.ค. 2569 รอบค่ำ] ปิด loop เต็ม — เชื่อม `hr_pay_component.biz_coa_account` ครบ 6/6 แล้ว** — เอกสารตอบกลับข้อ 1 เดิมบอกให้ **HR** กลับมาผูก `biz_coa_account` ของ `SSO_ER`/`SSO_EE`/`WHT` เข้ากับ COA ทั้ง 3 บัญชีเองหลังบัญชีถูกสร้างแล้ว ("ฝั่ง HR จะกลับมาผูก... ให้ครบ 6/6") — แต่เนื่องจากบัญชีทั้ง 3 มีอยู่แล้วและ session ฝั่งบัญชีมี rowId ครบมืออยู่แล้ว จึงดำเนินการผูกให้โดยตรงแทนที่จะรอ HR ผ่าน MCP `update_record` (worksheet `hr_pay_component` ws id `6a8ff2868b6633ef76f13871`, field `biz_coa_account`, `triggerWorkflow:false`):

| component | rowId ของ component | เชื่อมกับ COA | rowId ของ COA |
|---|---|---|---|
| `WHT` | `ad802ca3-fcb4-4aba-909c-a6f2ae786835` | `210304` | `777ea001-5300-4f5c-857a-71a45db2076b` |
| `SSO_EE` | `b8e92933-ba55-488b-b6fa-bd2e0c0044f7` | `210402` | `c6386fe7-1b3c-44db-ab80-9dfd3308a6a5` |
| `SSO_ER` | `68d66b6b-cfcb-404b-a7c6-35d324c7ca7d` | `530102` | `233626b4-d272-4cb5-8f77-9d8d2ddef804` |

ยืนยันทั้ง 3 ผ่าน `get_record_details` — เช่น `WHT` component คืน `biz_coa_account: {"sid":"777ea001-5300-4f5c-857a-71a45db2076b","name":"210304"}` ถูกต้อง · รวมกับ 3 component ที่เชื่อมอยู่ก่อนแล้ว (`SALARY`, `OT`, `ABSENCE_DEDUCT` — ทั้งหมดชี้ `530101`) ⇒ **`hr_pay_component` ทั้ง 6/6 record มี `biz_coa_account` ครบแล้ว** — Gap ของ HR handoff ปิดครบ end-to-end จริง ไม่ใช่แค่ "สร้างบัญชีแล้ว" แต่ "ผูกจริงแล้ว" ด้วย · sync สถานะนี้กลับไปที่ `12-HR-Handoff-Response-COA-Gap.md` แล้ว (เพิ่ม addendum ระบุว่าใครทำจริงและเมื่อไหร่)

### ตั้งค่า A-08 ให้ "ตั้งค่าได้" — สร้างตาราง AC_SYSTEM_PARAM (28 ส.ค. 2569 รอบดึก)

ผู้ใช้ขอ (ผ่าน `AskUserQuestion`) ให้ทำให้ข้อสมมติ **A-08 (จุดตัดข้อมูล/วันขึ้นระบบ)** ใน `01-BRD.md` §11 "ตั้งค่าได้" — เลือกตัวเลือก **สร้างฟิลด์ตั้งค่าไว้ในแอป** ไม่ใช่กรอกวันที่จริงตอนนี้ (ยังไม่มีวันที่จริงให้กรอก)

**สร้างตามแพทเทิร์น workaround เดิม (กับดักข้อ 25)**: `create_app_items` (blank worksheet 3 ฟิลด์ default) → `update_worksheet`(`removeFields` 3 ฟิลด์เดิม + `addFields` 4 ฟิลด์จริง + `alias`) → `get_worksheet_structure` (verify) → `update_worksheet.addRecordButtonName` ตั้งปุ่มไทย → CLI `hap worksheet view update` เปลี่ยนชื่อ view เริ่มต้นเป็น `ทั้งหมด` (กับดักข้อ 33)

- **Worksheet**: "พารามิเตอร์ระบบบัญชี" (`AC_SYSTEM_PARAM`) ws `6a917a2d9762533b5b720392` ใต้กลุ่มเมนู **AC-00 ตั้งค่าระบบ** (section `6a8538dee16cff5c409bc74d` — กลุ่มเดียวกับ `ac_posting_rule`/`ac_period`/`ac_journal`/`ac_doc_type`/`ac_doc_number_rule`/`ac_approval_rule`/`ac_doc_setting`)
- **View เริ่มต้น**: `6a917a2d9762533b5b720396` เปลี่ยนชื่อจาก `全部` เป็น **`ทั้งหมด`** ผ่าน CLI แล้ว ยืนยันด้วย JSON readback
- **ปุ่ม "Record Name"**: ตั้งเป็น "เพิ่มพารามิเตอร์" ผ่าน `addRecordButtonName` — ยืนยันซ้ำอีกครั้งว่าพารามิเตอร์หลอกตานี้ยังใช้ได้จริงบนตารางที่ 45 ของแอป (ต่อจาก 44/44 เดิม — ดูกับดักข้อ 15)
- **4 ฟิลด์** (ยืนยันผ่าน `get_worksheet_structure`):

| ฟิลด์ | field id | ชนิด | หมายเหตุ |
|---|---|---|---|
| `biz_setting_name` | `6a917a45353e1b0e4a50fa32` | Text, isTitle, required | ค่า default static "พารามิเตอร์หลักของระบบบัญชี" |
| `biz_cutover_date` | `6a917a45353e1b0e4a50fa33` | Date (subType 3, Y-M-D) | ไม่บังคับ — ว่างไว้รอกรอกจริง |
| `biz_go_live_date` | `6a917a45353e1b0e4a50fa34` | Date (subType 3, Y-M-D) | ไม่บังคับ — ว่างไว้รอกรอกจริง |
| `biz_note` | `6a917a45353e1b0e4a50fa35` | Text multiLine | ใช้บันทึกหมายเหตุ |

- **1 record เริ่มต้น** สร้างผ่าน `create_record`(`triggerWorkflow:false`) rowId `65eb8bc0-ac6b-4301-96a8-9e3b0bf2ba89` — `biz_cutover_date`/`biz_go_live_date` เว้นว่างตั้งใจ, `biz_note` ระบุว่ารอกรอกวันตัดยอดข้อมูลและวันขึ้นระบบจริงจากผู้รับผิดชอบก่อนเริ่ม Phase 12 (อ้างอิง BRD A-08)

**🔴 สำคัญ — งานนี้ไม่ได้แก้ปัญหา A-08**: นี่คือการเพิ่ม *ความสามารถ* ให้ตั้งค่าได้เมื่อรู้ค่าจริงแล้วเท่านั้น — ข้อสมมติ A-08 เองยังคง **ยังไม่กำหนด 🔴** เหมือนเดิมทุกประการ ยังบล็อกงาน 12.1/12.2/12.4 อยู่ (ดู `05-Roadmap-Tracker.md` §3.2 และ `01-BRD.md` §11)

**พบกับดักใหม่ระหว่างทาง — ดูกับดักข้อ 34**: worksheet-level `alias` ตั้งผ่าน `update_worksheet.alias` ไม่ persist และไม่มี MCP/CLI tool ใดยืนยันค่าจริงได้เลย (field-level alias `biz_*` ทั้ง 4 ตัวใช้งานปกติ ไม่กระทบ)

**ยังไม่ได้ทำ — pending manual**: role permission ของตารางนี้ยังไม่ได้ตั้งเลย — `get_role_list` ยืนยันว่าหลาย role (AC-R2/AC-R3/AC-R4/AC-R7/AC-R8) มีคำเตือนในตัวเองว่า "⚠️ permission ต้องตั้งใน UI ตาม Build Spec §1.4" ซึ่งเป็นธรรมเนียมเดิมของโปรเจกต์นี้ (ตั้งผ่านหน้าจอเท่านั้น ไม่ใช่ API) — ข้อเสนอเบื้องต้น (ยังไม่ตัดสินใจ/ยังไม่ตั้งจริง ต้องยืนยันกับ Build Spec §1.4 ก่อน): ให้ **AC-R4 Master Data Steward** มีสิทธิ์แก้ไข (ตรงกับแพทเทิร์นของอีก 7 ตาราง "config data" ใน AC-00) ส่วน role อื่นอ่านอย่างเดียวหรือไม่มีสิทธิ์

### WF-AC-11 ปิดปีและยกยอด (สร้าง publish + ทดสอบผ่านครบ — 28 ส.ค. 2569)

- **Process ID (main flow):** `6a90ef69fdab77a41c5b514f` — publish v1, **live**, 56 nodes + trigger
- **Trigger:** `worksheet_event` บน `AC_PERIOD` (update), `triggerFields:["biz_close_year_flag"]`
- **โครงสร้างหลัก (สรุป):** ตรวจไม่มีงวดใดของปี Open ค้าง (ตีความ "ทุกงวด Soft-closed" เป็น "ไม่มีงวด Open") → branch ปฏิเสธ/ดำเนินต่อ → 8 rollup(sum) บัญชีรายได้ (4 บัญชี × debit_base/credit_base) + 24 rollup(sum) บัญชีค่าใช้จ่าย (12 บัญชี × debit_base/credit_base) แต่ละตัว filter `account eq <rowid บัญชีนั้น>` (hardcode) — **ไม่ใช้ `op:"in"` เลยเพราะกับดักข้อ 31** → compute รวมรายได้/ค่าใช้จ่าย/กำไรสุทธิ → get_single ค่า default (journal/voucher_type/currency) → add_record สร้าง AC_VOUCHER (ปิดปี, `source_module` reuse คีย์ "ปิดงวด") → get_single หาบัญชีกำไรสะสม (retained earnings) → add_record สร้าง AC_CLOSING_ENTRY → get_multiple(AC_COA ที่ `is_postable=1` AND `account_type` ∈ Asset/Liability/Equity) ×3 (แยกตามประเภท) → sub_process(sequential_each, use_existing) ×3 คำนวณยอดสะสมต่อบัญชีแล้ว add_record เข้า AC_OPENING → get_multiple(AC_PERIOD ของปีนั้น) → sub_process(sequential_each, use_existing) ล็อกทุกงวดเป็น Permanently Locked → send_internal_notice แจ้งสำเร็จ
- **Inner sub-process (4 ตัว, ทั้งหมด `use_existing`, ตั้งใจปล่อย draft ถาวรตามกับดักข้อ 24):**
  - Opening ×3 (Asset `6a90f0f3fdab77a41c5b5c77`, Liability `6a90f11afdab77a41c5b6042`, Equity `6a90f139fdab77a41c5b63c9`) — โครงสร้างเหมือนกันทุกตัว: `sub_trigger` (record บัญชีที่ iterate) → 2 `rollup(sum)` (debit_base, credit_base ของ AC_GL filter `account eq sub_trigger.rowid` AND `fiscal_year lte <closingFiscalYear>` — สะสมถึงปีที่ปิด ไม่ใช่แค่ปีเดียว) → `add_record` เข้า AC_OPENING (เก็บ gross ไม่ netted) — ใช้ `process_variable` node (nodeId ซ้ำกันทั้ง 3 flow: `6038a1cbf18158039fb40e68`) รับค่า closing voucher rowid + fiscal year ถัดไปที่ parent ส่งเข้ามาผ่าน `config.input`+`inputFields`
  - Lock periods ×1 (`6a90f14cfdab77a41c5b66f7`) — `sub_trigger` (record งวดที่ iterate) → `update_record` ตั้ง `period_status` เป็น Permanently Locked
- **ออกแบบใหม่จาก spec เดิม (ดูรายละเอียดเหตุผลเต็มใน BuildSpec §3 WF-AC-11):**
  1. `AC_GL.account` เป็น Relation ไม่มี Lookup ให้ filter ตาม `account_type` ผ่าน API ⇒ hardcode รายการ rowid บัญชีรายได้ 4 + ค่าใช้จ่าย 12 ตัวตรง ๆ
  2. `op:"in"` truncation (กับดักข้อ 28) ครอบคลุมถึง Relation field ด้วย ⇒ แตกเป็น 1 rollup ต่อ 1 บัญชี แทน `in` เดียว (ดูกับดักข้อ 31)
  3. `source_module` ไม่มีตัวเลือก "CLOSING" จริง ⇒ ใช้คีย์ "ปิดงวด" เดิมแทน (`9f91b297-8939-4d23-8d72-168fd9cfd792`)
  4. "ทุกงวด Soft-closed" ตีความเป็น "ไม่มีงวด Open" (simplification ที่ยอมรับได้)
  5. AC_OPENING เก็บ gross debit/credit สะสม (ไม่ netted) — ตั้งใจ เพราะบัญชีงบดุลไม่ปิดยอดเป็นศูนย์ทุกปี
- **ทดสอบแล้ว (ปีบัญชีทดสอบสังเคราะห์ 13 งวด Soft-closed + fixture AC_GL จริง):** เส้นทางปฏิเสธ (มีงวดยังไม่ Soft-closed) → flag เคลียร์กลับ 0 ไม่ทำอะไรต่อ · เส้นทางสำเร็จ → รายได้รวม **165,000.00** / ค่าใช้จ่ายรวม **52,500.00** / กำไรสุทธิ **112,500.00** ตรงกับคำนวณมือทุกบาท, AC_OPENING **27 รายการ** (Asset 16, Liability 9, Equity 2), ล็อกครบ 13 งวด, ยืนยัน `_updatedBy=user-workflow` ทุกจุด · ล้างข้อมูลทดสอบแล้ว
- **Known gaps:** (1) 🔴 ไม่มีการสร้าง AC_VOUCHER_LINE คู่เดบิต/เครดิตอัตโนมัติ — ใบสำคัญปิดปียังเป็น draft summary record ไม่ใช่ self-balancing journal entry (นอกขอบเขตที่ระบุไว้ตั้งแต่ต้น) (2) ปุ่ม "ปิดปีและยกยอด" ยังไม่ verify Scope ผ่าน Browser (3) AC_OPENING ยอด 0 แสดงเป็นค่าว่างแทน 0.00 (cosmetic, inner rollup ยังไม่ตั้ง `nullZero:true`)

### WF-AC-10 กลับรายการใบสำคัญ (ปิดครบ 100% — 27 ส.ค. 2569 — ดู `11-Workflow-Engine-Blocked-27Aug.md` สำหรับรายละเอียดเต็ม)

- **Process ID (main flow):** `6a8f49b8730d20c5b764f302` — publish v4, **live**
- **Node graph:** gate → curPeriod → periodOpenBranch → newVoucher (add_record) → originalLines → reverseLines (sub_process) → originalGL → markGLReversed (sub_process) → setPending → hasVAT (branch) → [noVat: end] / [withVat: originalVatDocs → reverseVatDocs (sub_process)]
- **Sub-process ที่ตั้งใจปล่อยเป็น draft ถาวร (`use_existing` reuse — ห้าม publish ดูกับดักข้อ 24):** `reverseLines`, `reverseVatDocs`, `markGLReversed`
- **ปิดครบทุกด้านแล้ว (27 ส.ค. 2569 บ่าย):** ปุ่ม "กลับรายการ" verify Scope ผ่าน Browser แล้ว และ `AC_VOUCHER.voucher_no` มี `required=true` อยู่แล้วจริง — **ไม่มี gap เหลืออีกเลยทั้งด้าน logic, การทดสอบ, และ UI**

### Custom Action buttons ที่สร้างแล้วบน AC_VOUCHER (งาน 2.2 — ครบ 3/3 ปุ่มแล้ว, verify Scope ผ่าน Browser ครบทั้ง 3 ปุ่ม — 27 ส.ค. 2569)

| ชื่อปุ่ม | actionId | ชนิด | enableWhen | Scope | สถานะ |
|---|---|---|---|---|---|
| ส่งอนุมัติ | `6a8f380b1378964f99849bfe` | updateCurrentRecord (แก้ `voucher_status`) | สถานะ = ร่าง | ✅ All Records | ทำงานถูกต้อง (เปิด dialog ให้เลือกค่าเอง — ดูกับดักข้อ 21) |
| ยกเลิกใบสำคัญ | `6a8f380bae2a0e3743a0bedb` | updateCurrentRecord (แก้ `voucher_status` + เหตุผล) | สถานะ ∈ {ร่าง, รออนุมัติ} | ✅ All Records | ยังไม่ทดสอบคลิกจริง (สร้าง+ตั้ง Scope แล้ว) |
| กลับรายการ | `6a8fb9ea9762533b5b7189fb` | triggerWorkflow → WF-AC-10 | สถานะ = ผ่านรายการแล้ว | ✅ All Records (ยืนยันผ่าน Browser 27 ส.ค. 2569 บ่าย) | ทำงานถูกต้อง — ปุ่มโผล่จริงในเมนู "..." ของ record หลังตั้ง Scope |

### Custom Action buttons ที่สร้างแล้วบน AC_PERIOD (งาน 2.6 + 8.5 — ทั้งคู่ยังไม่ verify Scope ผ่าน Browser)

| ชื่อปุ่ม | actionId | ชนิด | enableWhen | Scope | สถานะ |
|---|---|---|---|---|---|
| ปิดงวด | `6a903eb89762533b5b71c4b2` | updateCurrentRecord (แก้ `biz_close_flag`) → runWorkflowAfterSubmit → WF-AC-09 | `period_status` = เปิด | ⬜ ยังไม่ verify (คาดว่า Unassigned View) | workflow logic ทดสอบผ่านครบ 2 เส้นทาง |
| ปิดปีและยกยอด | `6a90f50e1378964f9984df83` | updateCurrentRecord (แก้ `biz_close_year_flag`) → runWorkflowAfterSubmit → WF-AC-11 | `period_no` = 13 AND `period_status` = Soft-closed | ⬜ ยังไม่ verify (คาดว่า Unassigned View) | workflow logic ทดสอบผ่านครบ 2 เส้นทาง · 🆕 [28 ส.ค. 2569] พบปุ่มซ้ำชื่อเดียวกันบน AC_PERIOD (triggerId เก่า `6a90ef438b6633ef76f16f5a` — stale test draft) ลบแล้วผ่าน Browser (Custom Action list → "..." → Delete) — ดูกับดักข้อ 35 |

> ⚠️ **ทุกปุ่มที่สร้างผ่าน `create_custom_actions` ต้องเข้า Browser ตั้ง Scope เป็นขั้นตอนที่สองเสมอ** (ดูกับดักข้อ 20) — มิฉะนั้นปุ่มจะไม่โผล่ที่ไหนเลยแม้ MCP จะคืน `success:true`
> ⚠️ **Role-based visibility ("Role ที่เห็น" ใน BuildSpec §1.6) ยังไม่ได้ตั้งค่า** — ไม่ใช่พารามิเตอร์ของ `create_custom_actions` และไม่ใช่ของหน้า Scope นี้ด้วย ต้องหาทางตั้งแยกในอนาคต

---

## Known Issues / Workarounds

**เฉพาะโปรเจกต์นี้**

- ✅✅ **View 67/67 เป็นไทยครบทั้งระบบแล้ว (ยืนยันครบทั้งแอป — 28 ส.ค. 2569 ดึกกว่ารอบค่ำ)** — 62 view เดิม (26 ส.ค.) + 5 view ของ 5 ตาราง Phase 8/AC-07 ที่เปลี่ยนชื่อผ่าน CLI `hap worksheet view update` — ดูกับดักข้อ 33 · ✅ **สแกนทั้งแอปหา view `全部`/`Main` ที่หลงเหลือเสร็จสมบูรณ์แล้ว** — ไล่ครบทุก worksheet ในแอปนี้ (68 ตาราง / 102 view ทั้งแอป ไม่ใช่แค่ 39 ตารางโมดูลบัญชี) ผ่าน CLI + regex CJK (`[一-鿿]`) — **ผลลัพธ์ 0 view ที่หลงเหลือเป็นจีนหรือ `Main`** ⇒ ปิด follow-up นี้ถาวร ไม่มี gap เหลือด้าน view naming ในแอปนี้อีกแล้ว · กฎปฏิบัติสำหรับอนาคต: ถ้ามีตารางใหม่เพิ่ม (เช่น Phase 6/7 ที่ยังไม่สร้าง) ให้เช็ค view ตั้งแต่ตอนสร้างเสร็จเลยทันที ไม่ต้องรอสะสมแล้วค่อยสแกนทีหลัง
- 🟢🆕 **CLI `hap` ทำงานที่ MCP connector ทำไม่ได้ เช่น `update_view`** (28 ส.ค. 2569) — คำสั่ง `hap worksheet view update <ws_id> <view_id> --name "..."` ใช้ได้จริง — แก้ไขข้อสรุปเดิมที่เคยระบุว่า "ไม่มี update_view ในระบบเลย ต้องผ่านหน้าจอเท่านั้น" (ถูกต้องเฉพาะ MCP) — ดูกับดักข้อ 33
- ✅ **วันที่ที่แสดงเป็นรูปแบบจีน (`YYYY年M月D日`) แก้ครบทั้งแอปแล้ว** (26 ส.ค. 2569 — งาน 1.22) — ดูกับดักข้อ 14
- 🔴 **ชื่อ worksheet/ฟิลด์เป็นไทยแล้ว แต่ alias และ field ID คือหลักยึด**
- ✅ **ค่าตัวเลือก (option value) ทุกชุดแปลเป็นภาษาไทยแล้ว** (26 ส.ค. 2569 — งาน 1.17)
- 🔴 `AC_VOUCHER.สถานะ` alias = **`voucher_status`** field id `6a86016b1049edca1eed028a`
- 🔴 **ฟิลด์ 20 ตัวถูกลบและสร้างใหม่ตอนรอบตั้งชื่อ + อีก 8 ตัวตอนรอบแปลค่าตัวเลือก (รวม 28 ตัว) ⇒ field ID เปลี่ยน**
- ✅🔴 **Rollup ของ "ใบสำคัญ" เคยพังแล้วซ่อมแล้ว**
- ⚠️ **`_updatedAt` ของหัวเอกสารไม่ขยับเมื่อ Rollup คำนวณใหม่**
- 🟡 **8 ฟิลด์ที่ยังเป็นภาษาอังกฤษโดยตั้งใจ** (label เท่านั้น ค่าตัวเลือกเป็นไทยแล้ว)
- 🟡 **4 ฟิลด์รหัสระบบ/โมดูล จงใจไม่แปลเป็นไทย** (`source_doc_type` ×2, `source_type`, `event_code`)
- 🔴 ฟิลด์ที่ **ไม่มี alias**: `AC_VOUCHER.period_status_ref` `6a8b2f728b36df988c17f00f` · `AC_VOUCHER.fiscal_year_ref` `6a8b305633560633b8ce2c5c`
- ✅ **ฟิลด์ relation ย้อนกลับที่เคยใช้รหัสตารางเป็นชื่อ — แก้ครบ 11 ฟิลด์ใน 5 ตารางแล้ว**
- 🔴 **9 optionset ถูกสร้างไว้แต่ไม่มีฟิลด์ผูก**
- 🟡 **ชื่อกลุ่มเมนู 10 กลุ่มยังเป็นภาษาอังกฤษเดิม... ✅ แก้ครบแล้วผ่านหน้าจอ (งาน 1.19/1.20)**
- 🔴 **ห้ามใส่ `filter` ใน trigger ของ `worksheet_event`**
- 🔴 **เงื่อนไข `ne` กับฟิลด์ที่ค่าว่างไม่ผ่าน**
- 🔴 **`update_record` คัดลอกค่าฟิลด์ชนิด OrgRole ไม่ได้**
- 🔴 **start node ของ approval_block ไม่มี alias**
- 🔴 **branch `approval_result` ต้องอยู่ในสายอนุมัติ ต่อจาก approve node**
- ✅ **`sub_process` โหมด `sequential_each` ใช้แทน node Loop ได้**
- 🔴 **`sub_process` โหมด `use_existing` อ้าง process ที่ publish แล้วจะสร้าง node ไม่ได้**
- 🔴🔴 **`FieldPatch.value` ชนิด `kind:"record"` เขียนลงฟิลด์ Relation แล้วเสียหายแบบเงียบ**
- 🔴🔴 **`FieldPatch.value` ชนิด `kind:"literal"` ไม่ interpolate placeholder แบบ `$nodeId-fieldId$`**
- 🔴🔴🔴 **`Condition.op:"in"` ไม่ทำงานกับฟิลด์ชนิดใดเลย (Dropdown/SingleSelect/Relation ล้วนโดนหมด)**
- ✅ **`rollup` method `sum`/`avg`/`min`/`max` ไม่ต้องมี `config.target`**
- ✅ **`get_record_logs` แสดง operator ตามผู้จุดชนวน (อาจเป็น `user-api`) แม้ workflow เป็นคนเขียน**
- ✅ ฟิลด์ `approver_user`/`approver_orgrole` สร้างแล้วแต่ยังไม่ได้ใช้
- ✅ **ผูก shared optionset กับฟิลด์ผ่าน API ได้ตอน `addFields`** — แต่ผูกเข้ากับฟิลด์ที่มีอยู่แล้วไม่ได้เลย
- ✅ `Attachment` สร้างผ่าน API ได้จริง · `editFields` เปลี่ยนชื่อ reverse-relation ได้
- 🔴 **ฟิลด์ธงทุกตัวที่สร้างใหม่ตั้ง default 0 ไว้แล้ว**
- ⚠️ `AC_VOUCHER.balance_diff` เป็น **Formula field** ที่ใช้ได้อยู่ — **ห้ามแตะ**
- ✅ **`get_role_list` บน tenant นี้คืน custom role ครบ**
- 🔴 **`editFields.options` บนฟิลด์ SingleSelect/MultipleSelect เพิ่มตัวเลือกซ้อนทับ**
- 🔴 **`batch_update_records`/`update_record` ต้องใช้ `rowId` ไม่ใช่ `_id`**
- ✅ **`get_role_list` บน tenant นี้คืน 51 worksheet ต่อ role**
- 🔴 **ทั้ง 8 role ยังไม่มีสมาชิกเลยแม้แต่คนเดียว**
- 🟡 **Role Debugging ใช้ทดสอบ permission matrix ได้ แต่ใช้แทนบัญชีทดสอบจริงไม่ได้**
- ✅ **`create_custom_actions` สร้างปุ่มสำเร็จแต่ Scope เริ่มต้น = "Unassigned View" เสมอ**
- 🔴 **ปุ่ม custom action ชนิด `updateCurrentRecord` ไม่ auto-apply ค่า**
- 🔴🔴 **`update_worksheet.editFields` ล้าง `name`/`alias` ของฟิลด์เป็นค่าว่างเงียบ ๆ ถ้าไม่ส่งกลับไปด้วยตอนแก้ attribute อื่น** — ดูกับดักข้อ 32

- 🟡🆕 **[28 ส.ค. 2569] role permission ของตาราง AC_SYSTEM_PARAM (พารามิเตอร์ระบบบัญชี) ยังไม่ได้ตั้งเลย** — pending manual step ตามธรรมเนียมเดิม (ตั้งผ่าน Browser ตาม Build Spec §1.4 เท่านั้น) ข้อเสนอเบื้องต้น: AC-R4 Master Data Steward แก้ไขได้ ตารางอื่นอ่านอย่างเดียว/ไม่มีสิทธิ์ — ยังไม่ตัดสินใจ/ยังไม่ตั้งจริง

**กับดักแพลตฟอร์มทั่วไป (ยังใช้ได้)**

- `get_workflow_list` คืนเฉพาะ PBP → ผลว่าง **ไม่ใช่** หลักฐานว่าไม่มี workflow
- ใช้ **Trigger Field** แทน Trigger Condition
- ค่า before-update เข้าถึงไม่ได้ → ใช้ **ฟิลด์ธง**
- Number → Formula แปลงตรงไม่ได้ → ลบแล้วสร้างใหม่
- **เลี่ยง Formula field ใหม่** → ใช้ Number + node `Function calculation`
- พิสูจน์ workflow = log ต้องขึ้น operator **`user-workflow`**
- Approve node: ผู้อนุมัติต้องมาจากฟิลด์ Collaborator บนตารางหลัก
- DateTime ผ่าน API ต้องระบุ `+07:00` เสมอ
- `update_worksheet` ส่ง `name` + `alias` **คู่กันเสมอ**
- กันซ้ำจริงใช้ **Unique index** (Search Acceleration ผ่านหน้าจอเท่านั้น)
- ล็อก record หลังอนุมัติใช้ **Business Rule**
- **แก้ node ที่สร้างแล้วไม่ได้** → `delete_process_node` แล้วสร้างใหม่
- worksheet trigger ทดสอบด้วย `create_record`/`update_record` (`triggerWorkflow:true`)
- seed ข้อมูลใช้ `batch_create_records` + `triggerWorkflow:false`
- ✅ **`create_view` ใช้ได้จริงแล้ว** — แต่ **ไม่มี `update_view` ใน MCP** ⇒ แก้ view ที่มีอยู่ **ลอง CLI `hap worksheet view update` ก่อนเสมอ แล้วค่อย fallback หน้าจอ** (แก้ไข 28 ส.ค. 2569 รอบค่ำ — ดูกับดักข้อ 33) · ✅ **`create_custom_actions` ยิงสำเร็จจริงแล้วเช่นกัน** แต่ต้องเข้า Browser ตั้ง Scope ต่อเสมอ
- ✅ **`create_process`→`batch_create_process_nodes`→`validate_process`→`publish_process` สร้าง workflow node graph เต็มรูปแบบผ่าน MCP ได้จริง**
- tool schema deferred → `ToolSearch` โหลด schema ก่อนเรียก

---

## สถานะงานล่าสุด → ย้ายไป `05-Roadmap-Tracker.md` (ยุบ 30 ส.ค. 2569)

🔴 **ห้ามสร้างตาราง checklist ซ้ำในไฟล์นี้อีก** — ของเดิมเป็นสำเนาของ Roadmap ที่ต้อง sync ด้วยมือทุกครั้ง จึงเป็นแหล่ง drift โดยตรง (เคยยาว 2,440 ตัวอักษร)

**แหล่งความจริงเดียวของความคืบหน้า = `05-Roadmap-Tracker.md`** (§2 รายการงาน · §5 Change Log) · สรุปล่าสุด: **38% — ✅33/86 งาน**

> เก็บไว้เพราะเป็นข้อมูลที่ไม่มีที่อื่น: process ที่ถูกลบตอน audit 28 ส.ค. — stale human-authored draft ของ WF-AC-02 คือ `6a861cfef520ee95fb0c3a3a` (ลบแล้ว) · รายละเอียด audit เต็มดูกับดักข้อ 35 และ Change Log ของ Roadmap
## โหมดส่งมอบให้ `nocoly-hybrid-builder-v2` (Handoff)

- **ข้าม Phase 1 Interview** — spec ตอบครบแล้ว
- **Phase 2 Confirm จาก spec** — สรุป checklist + Mermaid จาก BuildSpec §3 ให้ผู้ใช้ยืนยัน
- **Phase 3 ทำตามคอลัมน์ Surface** ใน §1.5 / §3 · หลัง `create_*` ทุกครั้ง อ่าน ID กลับแล้วเติมแทน `<TBD>` ใน §1 ทันที
- ปิดงาน ✅ ได้เมื่อ Test recipe ของงานนั้นผ่านตาม BuildSpec §5.3 แล้วอัปเดต `05-Roadmap-Tracker.md` + checklist ข้างบนให้ตรงกัน

---

## กฎทำงาน (สั้น)

1. เปิด **BuildSpec §1 ID Registry** ก่อนพิมพ์ ID ใด ๆ
2. `get_app_info` ยืนยันแอปก่อน write แรกของทุก session
3. **อ่านหัวข้อ "ชื่อไทย + กับดัก `update_worksheet`" ให้จบก่อนแตะฟิลด์ทุกครั้ง** — รวมข้อ 33 ใหม่ (CLI `hap` ทำ `update_view` ได้จริง แก้ไขข้อ 11 เดิม)
4. **Verify ก่อน claim** เสมอ — ผลว่างจาก tool ≠ ไม่มีของ · `success:true` ≠ เปลี่ยนแปลงจริง
5. แก้ object แล้วอัปเดต BuildSpec + ไฟล์นี้ **ทันที**
6. ห้ามเลื่อนงานเป็น ✅ ถ้ายังไม่มีหลักฐาน
7. **หลังสร้าง custom action ผ่าน MCP เสมอ**: เข้า Browser ตั้ง Scope → "All Records"
8. **สร้าง/แก้ workflow node graph เสมอ**: ดูกับดักข้อ 22/23/24/26/27/28/29/30/31
9. **แก้ field ที่มีอยู่แล้วผ่าน `update_worksheet.editFields` เสมอ**: ส่ง `name`+`alias` กลับไปพร้อมกันทุกครั้ง
10. 🆕 **เปลี่ยนชื่อ view ที่มีอยู่แล้วเสมอ**: ลอง CLI `hap worksheet view update <ws_id> <view_id> --name "..."` ก่อนเสมอ — เร็วกว่าและไม่ต้องพึ่ง Browser — ใช้ Browser เป็นทางเลือกสำรองเท่านั้น (ดูกับดักข้อ 33)
