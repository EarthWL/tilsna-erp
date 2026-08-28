# ✅ RESOLVED — WF-AC-10 กลับรายการใบสำคัญ สร้างสำเร็จและทดสอบผ่านครบทุก path แล้ว (27 ส.ค. 2569)

> **เดิมไฟล์นี้ชื่อ "Workflow engine หยุดทำงานทั้งระบบ" — การวินิจฉัยนั้น "ผิด"** ทิ้งไว้เป็นบทเรียน ดูหัวข้อ "การวินิจฉัยที่ผิดพลาด (เก็บไว้เป็นบทเรียน)" ด้านล่าง สรุปสั้น: **workflow engine ไม่เคยหยุดทำงานเลย** ปัญหาจริงคือ WF-AC-10 พังที่ node `newVoucher` (add_record) ด้วย error **"Duplicate row data"** เพราะไม่เคยตั้งค่า `voucher_no` ชนกับ unique index `IX-06.1_voucher_no_unique` — เห็นได้จาก **Nocoly Workflow History UI** เท่านั้น (ผู้ใช้ screenshot ให้ดู) ไม่ใช่จาก MCP tools ใด ๆ

## ผลลัพธ์สุดท้าย

**WF-AC-10 (กลับรายการใบสำคัญ)**: processId `6a8f49b8730d20c5b764f302` — **published, publishVersion 4, ทดสอบผ่านครบทุก path แล้ว (ไม่มี VAT + มี VAT + GL flagging)**

Node graph เต็ม (ทั้งหมดสร้างผ่าน MCP `batch_create_process_nodes`):

```
trigger (worksheet_event, AC_VOUCHER, triggerFields=[voucher_status])
 → gate (branch: voucher_status = กลับรายการแล้ว 8ce6c682-... / else skip)
   [doReverse] → curPeriod (get_single ac_period ของวันนี้, ifEmpty:stop)
     → periodOpenBranch (branch: period_status = เปิด / else ปิด)
       [periodClosed] → notifyPeriodClosed (send_internal_notice)
       [periodOpen] → newVoucher (add_record ac_voucher ใหม่ status=Draft)
         → originalLines (get_multiple ac_voucher_line ของใบต้นฉบับ)
         → reverseLines (sub_process use_existing → 6a8f46845f8564a68c38261c, sequential_each, สลับเดบิต/เครดิต)
         → originalGL (get_multiple ac_gl ของใบต้นฉบับ)
         → markGLReversed (sub_process use_existing → 6a8f46ca5f8564a68c382a4a, sequential_each, ติ๊ก is_reversed)
         → setPending (update_record ใบใหม่ status=รออนุมัติ 982090bd-...)
         → hasVAT (branch: trigger.biz_vch_vat_doc not_empty)
           [withVat] → originalVatDocs (get_multiple ac_vat_doc ของใบต้นฉบับ)
             → reverseVatDocs (sub_process use_existing → 6a8f46b35f8564a68c38288a, sequential_each, สร้างภาษีติดลบ)
           [noVat] → (จบ ไม่มี node)
```

**รอบทดสอบที่ 1 (ZZTEST-REV-001, path ไม่มี VAT — 27 ส.ค. 2569 เช้า):**
- ใบสำคัญใหม่ถูกสร้างโดย `user-workflow` ✅, `voucher_no` ไม่ซ้ำ (`REV-{original}-{utime}`) ✅
- `reversal_of` และ `period` ผูกถูกต้อง (ไม่ใช่ `已删除`) ✅
- 2 บรรทัดถูกสร้างโดยสลับเดบิต/เครดิตถูกต้อง (110101 debit1000/credit0 ↔ 530204 debit0/credit1000) พร้อม `line_description` แปลผล template ถูกต้อง ✅
- `total_debit`/`total_credit` rollup = 1000/1000, `balance_diff` = 0 ✅
- สถานะใบใหม่เลื่อนจาก Draft → รออนุมัติ (`982090bd-...`) อัตโนมัติ ✅
- `hasVAT` เข้า path `noVat` ถูกต้อง (fixture ไม่มี VAT doc ผูกอยู่ตอนนั้น) ✅

**รอบทดสอบที่ 2 (ZZTEST-REV-001 fixture เดิม เสริม GL + VAT doc จริงแล้ว re-trigger — 27 ส.ค. 2569 บ่าย) — ปิด gap ที่เหลือทั้งหมด:**

เสริม fixture ก่อน trigger: สร้าง 2 แถว `ac_gl` จริงที่ผูกกับ 2 บรรทัดของ ZZTEST-REV-001 (movement_seq 5/6, debit_base 1000/acct 530204 ↔ credit_base 1000/acct 110101, `triggerWorkflow:false` เพราะเป็นการ backfill ไม่ใช่ event ธุรกิจจริง) และสร้าง 1 แถว `ac_vat_doc` จริงที่ผูกกับใบสำคัญผ่าน `biz_vd_transfer_voucher` (base 1000, vat 70, VAT7-2569, sign_factor +1) แล้วอัปเดต `voucher_status` → "กลับรายการแล้ว" (`triggerWorkflow:true`) เพื่อยิง WF-AC-10 จริงอีกรอบ:

- ✅ **`markGLReversed` (sub_process) ติ๊ก `is_reversed` = 1 ถูกต้องบนทั้ง 2 แถว GL จริง** — ยืนยันผ่าน `get_record_details` หลัง trigger, `_updatedBy` ของทั้งสองแถวเปลี่ยนเป็น `user-workflow`
- ✅ **`hasVAT` เข้า path `withVat` ถูกต้อง** (มี `ac_vat_doc` ผูกอยู่จริงคราวนี้)
- ✅ **`reverseVatDocs` (sub_process) สร้างรายการภาษีติดลบถูกต้องสมบูรณ์**: `base_amount` 1000→**-1000**, `vat_amount` 70→**-70**, `sign_factor` 1→**-1**, `source_doc_id` = "ZZTEST-REV-001" (interpolate ถูกต้องผ่าน `kind:"template"`), `biz_vd_transfer_voucher` ผูกกับ**ใบสำคัญใหม่**ถูกต้อง (ไม่ใช่ใบต้นฉบับ, ไม่ใช่ `已删除`)
- ✅ **ใบสำคัญใหม่ครบทุกฟิลด์เหมือนรอบแรก** — `voucher_no` = "REV-ZZTEST-REV-001-2026-08-27 12:49", `reversal_of`/`period` ผูกถูกต้อง, 2 บรรทัดสลับเดบิต/เครดิตถูกต้อง (`line_description` = "กลับรายการ: ZZTEST จ่ายเงินสด" / "กลับรายการ: ZZTEST ค่าธรรมเนียมวิชาชีพ"), สถานะ "รออนุมัติ"

**⇒ ผลสรุป: WF-AC-10 ทดสอบผ่านครบ 100% ทุก path ที่มีในสเปค (non-VAT, VAT, GL flagging) ไม่มี gap เหลือด้านฟังก์ชันแล้ว**

**ทำความสะอาดหลังทดสอบ (27 ส.ค. 2569)**: ลบ record ทดสอบที่ WF-AC-10 สร้างขึ้นทั้งหมด (ใบสำคัญใหม่ + 2 บรรทัด + VAT doc กลับรายการ) และ fixture เสริมที่สร้างเพื่อทดสอบ (2 แถว GL, 1 แถว VAT doc ต้นฉบับ) ด้วย `delete_record(permanent:true)` แล้วรีเซ็ต `ZZTEST-REV-001` กลับสถานะ "ผ่านรายการแล้ว" (`triggerWorkflow:false`) — ยืนยันด้วย `get_record_details` ว่า `reversing_vouchers`/`biz_vch_vat_doc` ว่างเปล่าเหมือนก่อนทดสอบ **fixture พร้อมใช้ซ้ำสำหรับการทดสอบในอนาคต** (ไม่มีแถว GL/VAT doc ผูกค้างอยู่แล้ว — ต้องสร้างใหม่ถ้าจะทดสอบซ้ำ)

**Custom Action button "กลับรายการ"**: สร้างแล้วผ่าน MCP `create_custom_actions` — `actionId` `6a8fb9ea9762533b5b7189fb`, type `updateCurrentRecord`, `updateFields=[voucher_status]`, `enableWhen: voucher_status = ผ่านรายการแล้ว (a234503a-...)`, `runWorkflowAfterSubmit:true`. **ยืนยันด้วยตาผ่าน Browser แล้ว (27 ส.ค. 2569 บ่าย, เชื่อมต่อ Claude-in-Chrome สำเร็จ)** — เปิดหน้า ใบสำคัญ → เมนู "..." → Set Worksheet → Custom Action พบ Scope ของปุ่มนี้เป็น **"Unassigned View"** จริงตามที่คาดไว้ (ตรงกับ Trap #20 เป๊ะ) → คลิกลิงก์ "Scope" → เลือก radio **"All Records"** → บันทึกอัตโนมัติทันที (ไม่มีปุ่ม Save แยก) → เปิด record `ZZTEST-REV-001` ใหม่ พบปุ่ม "กลับรายการ" โผล่จริงในเมนู "..." ของ record (แถวเดียวกับ "Copy"/"Recreate") ⇒ **ปุ่มพร้อมใช้งานจริงครบทั้ง 3/3 ปุ่มแล้ว** (ตัวเวิร์กโฟลว์เองผ่านการทดสอบครบแล้วโดย trigger ผ่าน `update_record` ตรง ๆ — ปุ่มเป็นแค่ทางเข้า UI ที่เพิ่งปิด gap สุดท้ายนี้)

## กับดักใหม่ที่ยืนยันแล้วในรอบนี้ (สำคัญมาก — ใช้กับ workflow อื่นทุกตัวที่มี Relation field)

1. 🔴🔴 **`FieldPatch.value` ของ Relation field ห้ามใช้ `kind:"record"` — ต้องใช้ `kind:"field"` + `fieldId:"rowid"`**
   ยืนยันด้วยการทดสอบจริง: ตอนแรกเขียน `period`/`reversal_of` ด้วย `{"kind":"record","node":{"nodeAlias":"curPeriod"}}` → ระบบ**ไม่ error ไม่ validate fail** แต่เขียนค่าผิดแบบเงียบ ๆ กลายเป็น relation ที่ชี้ไปยัง **nodeId ของ node เอง** (อ่านกลับมาเห็น `{"sid":"[\"<nodeId>\"]","name":"已删除"}` — "已删除" = ถูกลบ/หาไม่เจอ) แก้เป็น `{"kind":"field","node":{"nodeAlias":"curPeriod"},"fieldId":"rowid"}` แล้วได้ค่าถูกต้องทันที (`sid` = rowid จริง, `name` = ชื่อ record จริง)
   ⚠️ **นี่คือบั๊กเงียบที่อันตรายที่สุดที่เจอมา — validate_process และ publish_process ผ่านหมดทั้งที่ข้อมูลผิด ต้องตรวจด้วย `get_record_list`/`get_record_details` แล้วดูว่า relation field name เป็น "已删除" หรือไม่ทุกครั้งหลัง add_record/update_record ที่เขียน Relation field**
   ส่วนการ "copy" ค่า Relation field จาก upstream node ไปยัง Relation field เดียวกัน (เช่น copy `journal`/`voucher_type` จาก trigger ไปยัง record ใหม่) ยังใช้ `kind:"field"` ชี้ตรงไปที่ fieldId เดิมได้ปกติ (ไม่ใช่บั๊ก) — บั๊กเกิดเฉพาะตอนจะ "ผูกไปยังทั้ง record ของ node" ด้วย `kind:"record"` เท่านั้น
   ข้อยกเว้น: `update_record`/`delete_record`/`approval_block`/`sub_process` ฯลฯ ที่ใช้ `config.target` (RecordValueRef) **ต้อง** ใช้ `kind:"record"` เสมอ — อันนี้ถูกต้องอยู่แล้วตาม schema ไม่ใช่บั๊ก (ยืนยันจาก `markGLReversed.flagLine.config.target` ทำงานถูกต้องทั้งสองรอบทดสอบ)

2. 🟡 **`kind:"literal"` กับ string ที่มี `$nodeId-fieldId$` placeholder ข้างในไม่ถูกตีความ — ต้องใช้ `kind:"template"`**
   พบใน `reverseLines.newLine` (field `description`) และ `reverseVatDocs.newVatDoc` (fields `source_doc_id`, `tax_invoice_no`) ที่สร้างไว้ในรอบก่อน แก้เป็น `kind:"template"` แล้วทดสอบยืนยันซ้ำสองรอบว่า `line_description`/`source_doc_id` แปลผล placeholder ถูกต้องจริง (เห็นข้อความ "กลับรายการ: ZZTEST จ่ายเงินสด" และ "ZZTEST-REV-001" ไม่ใช่ raw placeholder string)

3. 🔴 **`sub_process` แบบ `mode:"use_existing"` อ้าง processId ที่ตัวมันเอง `published:true` (เป็น standalone flow ที่ publish แยกแล้ว) จะ error**: `"内部流程不是草稿，不能追加节点: <alias>"` (แปล: "internal process ไม่ใช่ draft ห้าม append node")
   **แก้โดย**: หลังแก้ node ข้างในของ inner sub_process (delete_process_node + batch_create_process_nodes ใหม่) **ห้ามเรียก `publish_process` กับ inner flow นั้นอีก** ปล่อยให้สถานะเป็น `"status":"updated","published":false` (draft) ค้างไว้ แล้วค่อยไปสร้าง sub_process node ใน flow หลักที่อ้างถึง processId นั้นด้วย `mode:"use_existing"` — จะสำเร็จทันที จากนั้น `validate_process`+`publish_process` เฉพาะ **flow หลัก** เท่านั้น (inner flow จะยังคง `published:false` ตลอดไปก็ไม่เป็นไร ใช้งานได้ปกติผ่านการอ้างอิงจาก flow หลัก — ยืนยันซ้ำว่าทำงานถูกต้องทั้งสองรอบทดสอบ)
   ⇒ **สรุปกฎใหม่**: sub_process ที่จะ reuse ด้วย `use_existing` ต้องอยู่ในสถานะ **draft/unpublished เสมอ** ณ ตอนที่ flow หลักอ้างถึงมัน — ถ้าเผลอ publish มันแยกไปแล้วจะอ้างซ้ำไม่ได้อีก (ต้องลบ+สร้าง node ใหม่ในตัวมันเพื่อบังคับกลับเป็น draft ก่อน)

4. ✅ (ยืนยันซ้ำ) `get_workflow_structure` อ่านค่า `kind:"template"` ใน `FieldPatch.value` กลับมาเป็น `kind:"literal"` เสมอ (readback bug, ไม่ใช่หลักฐานว่า field ผิดจริง — เชื่อ payload ที่ส่งตอนสร้าง)

5. ✅ (ยืนยัน) inner sub_process ที่เขียนฟิลด์ Relation ด้วย `{"kind":"field","node":{"nodeId":"<process_variable virtual node>"},"fieldId":"<inputFields text param>"}` (ส่ง rowid ผ่าน subprocess parameter แบบ text แล้วเขียนเข้า Relation field) **ใช้งานได้จริง** ตราบใดที่ parent ส่ง rowid ที่ถูกต้องเข้ามาทาง `config.input` (เช่น `{"kind":"field","node":{"nodeAlias":"newVoucher"},"fieldId":"rowid"}`) — ยืนยันจากผลลัพธ์จริงที่บรรทัดใหม่ผูก `voucher` กลับไปยัง newVoucher ถูกต้อง 100% ทั้งสองรอบทดสอบ

6. ✅ **การทดสอบ sub_process แบบ `sequential_each` (execution mode) ด้วยการ backfill ข้อมูลจริงเข้า worksheet ปลายทางด้วย `triggerWorkflow:false` ก่อน แล้วค่อย trigger flow หลักจริง เป็นวิธีที่ใช้งานได้ดีสำหรับ "จำลอง" ข้อมูลที่ควรเกิดจาก workflow อื่น (WF-AC-02) โดยไม่ต้องรัน WF-AC-02 จริง** — ใช้ปิด gap การทดสอบ `markGLReversed`/`reverseVatDocs` ได้เต็มรูปแบบโดยไม่ต้องมี GL/VAT-doc จริงจากการผ่านรายการ

## Process ID สุดท้าย (สถานะล่าสุด)

- **WF-AC-10 หลัก**: `6a8f49b8730d20c5b764f302` — published v4 ✅ **ทดสอบผ่านครบทุก path**
- **reverseLines** (สร้างบรรทัดกลับรายการ): `6a8f46845f8564a68c38261c` — **draft/unpublished โดยตั้งใจ** (ดูกับดัก #3) ห้าม publish
- **reverseVatDocs** (สร้างรายการภาษีติดลบ): `6a8f46b35f8564a68c38288a` — **draft/unpublished โดยตั้งใจ** — ทดสอบผ่านแล้ว
- **markGLReversed** (ทำเครื่องหมาย GL ว่าถูกกลับรายการ): `6a8f46ca5f8564a68c382a4a` — **draft/unpublished โดยตั้งใจ** — ทดสอบผ่านแล้ว
- **WF-AC-01** (อนุมัติใบสำคัญ, ยืนยันทำงานปกติตลอด — ไม่เคยหยุดทำงานจริง): `6a8eaa45e6605c4b13ccf49b`
- **Custom Action "กลับรายการ"**: actionId `6a8fb9ea9762533b5b7189fb`, ผูก micro-workflow ว่างเปล่า `6a8fb9eae6605c4b13dc846d` (ไม่ต้องแก้ไข ไม่ได้ใช้งาน — WF-AC-10 ทำงานผ่าน field-trigger บน `voucher_status` โดยตรง ไม่ผ่าน micro-workflow นี้) — **Scope ตั้งเป็น "All Records" แล้ว 27 ส.ค. 2569 บ่าย**
- **Test fixture**: `ZZTEST-REV-001` (rowId `37263aee-33b2-480d-b6b7-065e343c6c80`) — รีเซ็ตกลับเป็น **Posted** แล้วหลังทดสอบทั้งสองรอบ พร้อมใช้ซ้ำ (มี 2 บรรทัด balance: debit 1000/acct 530204, credit 1000/acct 110101 — ไม่มี VAT doc/GL ผูกค้างอยู่แล้ว เพราะลบ fixture เสริมออกหลังทดสอบรอบ 2)

## งานที่เหลือสำหรับ WF-AC-10 / FR-06

1. ~~ทดสอบ path `withVat` ด้วย fixture ที่มี `ac_vat_doc` ผูกจริง~~ ✅ **เสร็จแล้ว 27 ส.ค. 2569 บ่าย**
2. ~~ทดสอบ `markGLReversed` ด้วย fixture ที่มีแถว `ac_gl` จริง~~ ✅ **เสร็จแล้ว 27 ส.ค. 2569 บ่าย** (backfill GL แทนการรัน WF-AC-02 จริง — ดูกับดัก #6)
3. ~~ยืนยัน Custom Action button ผ่าน Browser จริง + ตั้ง Scope "All Records" (Trap #20)~~ ✅ **เสร็จแล้ว 27 ส.ค. 2569 บ่าย** — Claude-in-Chrome เชื่อมต่อสำเร็จ, ยืนยัน Scope เดิมเป็น "Unassigned View" จริง, แก้เป็น "All Records", ยืนยันปุ่มโผล่จริงในเมนู record
4. ~~ยัง**ไม่ได้ตั้ง `required=True`** บน `AC_VOUCHER.voucher_no`~~ ✅ **ตรวจสอบแล้วพบว่า `required=true` ตั้งไว้อยู่แล้วจริง** (27 ส.ค. 2569 บ่าย) — เช็คผ่าน `get_worksheet_structure` (field id `6a85ff5933560633b8cd9f83`) ยืนยัน `required:true` มาตั้งแต่งาน 1.7 (26 ส.ค. 2569) — บันทึกก่อนหน้านี้เข้าใจคลาดเคลื่อนว่ายังไม่ได้ทำ ไม่มีอะไรต้องแก้เพิ่ม

**⇒ ทั้ง 4 ข้อในหัวข้อนี้ปิดครบหมดแล้ว — WF-AC-10 ไม่มี gap เหลืออีกเลยทั้งด้าน logic, การทดสอบ, และ UI**

## การวินิจฉัยที่ผิดพลาด (เก็บไว้เป็นบทเรียน)

ช่วงกลางการ debug เคยสรุปผิดว่า **"workflow engine ทั้งแอปหยุดทำงาน"** โดยอ้างหลักฐาน: ยิง WF-AC-01 (ที่เคยพิสูจน์ว่าทำงาน) แล้วรอ 15 วินาทีไม่เห็นผล แล้วรอซ้ำ 6.5 ชั่วโมงก็ยังไม่เห็นผล จึงสรุปว่า engine ทั้งระบบตาย

**ที่จริงคือ**: WF-AC-01 มี approval_block (สายอนุมัติ) ที่ใช้เวลาประมวลผลนานกว่าที่รอ และวิธีเช็คผ่าน `get_record_details`/`get_record_logs` ทาง API **มองไม่เห็นสถานะ per-node execution** เท่าหน้าจอ **Nocoly Workflow History** (เปิดจาก Automated Workflow list ในเบราว์เซอร์) ที่แสดง node-by-node log พร้อม error message ชัดเจน เมื่อผู้ใช้ส่ง screenshot ของหน้านี้มาให้ดู 3 ภาพ พบว่า:
1. WF-AC-01 ประมวลผล **ทุกการทดสอบสำเร็จทันที** ตลอดทั้งเซสชัน (ไม่เคยหยุดทำงานเลย)
2. WF-AC-10 เองก็ทำงาน**ทุกครั้ง** วิ่งผ่าน gate → curPeriod → periodOpenBranch สำเร็จ แล้ว**ไปติดที่ node `newVoucher` ด้วย error "Duplicate row data"** (เห็นชัดในหน้า Workflow History พร้อมปุ่ม Retry)

**บทเรียน**: เมื่อ workflow publish สำเร็จ, validate ผ่าน, แต่ผลลัพธ์ที่คาดหวังไม่เกิดขึ้น — **อย่ารีบสรุปว่า engine ตาย** ให้ขอให้ผู้ใช้เปิดหน้า **Workflow History** ของ workflow นั้นในเบราว์เซอร์ก่อนเสมอ (MCP ไม่มี tool อ่าน per-node execution trace ได้) เพราะสาเหตุที่แท้จริงมักเป็น node เดียวที่ error แบบเงียบ ๆ (เช่น unique index ชนกัน) ไม่ใช่ปัญหาระดับระบบ
