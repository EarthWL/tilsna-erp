# Workflow Catalog 22 workflow node-by-node — โมดูลบัญชี

> แยกออกจาก `02-BuildSpec-FRS.md` เมื่อ 31 ส.ค. 2569 (agent-ac · claim `AC/SPLIT-BUILDSPEC`)
> เหตุผล: ไฟล์แม่โต 316,054 bytes ≈ 42,366 tokens **เกินเพดาน Read 25,000 tokens ไป 1.7 เท่า** ทั้งที่ `02-BuildSpec-FRS.md` §0 ของมันสั่งให้ agent เปิดทุกครั้งก่อนแตะ object
> **เนื้อหาย้ายมาครบทุกตัวอักษร ไม่ได้ย่อหรือตัดทิ้ง** — ยืนยันด้วยการเทียบ byte-ต่อ-byte กับต้นฉบับ

---

## §3. Workflow Catalog — 22 workflow, node-by-node

> **WF-AC-01, WF-AC-02 สร้างและ publish แล้ว** — ที่เหลือทุก ID เป็น `<TBD>` · เติมทันทีหลัง `create_process`
> **ก่อนสร้างตัวใหม่:** เปิดหน้า **Automated Workflow** ยืนยันด้วยตาว่าสถานะตรงกับ `13-ID-Registry-AC.md` §1.5 แล้วบันทึกผลลง `13-ID-Registry-AC.md` §1.5
> ลำดับการสร้าง: `create_process` → `batch_create_process_nodes` → `validate_process` → `publish_process` · **publish = เปิดใช้งานทันที ไม่มีขั้น Enable**
> **แก้ node ที่สร้างแล้วไม่ได้** — ต้อง `delete_process_node` แล้วสร้างใหม่ และ `validate_process` ทุกครั้งหลัง batch
> เมื่อ Surface = MCP: `fieldId` ต้องเป็นเลข 24 หลักจริง (ห้าม alias) · ตัวดำเนินการตามพจนานุกรม workflow (`gte` ไม่ใช่ `ge`) · `branch.paths[].result` = `pass` / `overrule`

### ลำดับความสำคัญในการสร้าง

| ลำดับ | Workflow | ทำไมต้องก่อน |
|---|---|---|
| 1 | WF-AC-01 | เป็นแม่แบบสายอนุมัติของทุกเอกสาร — ทำถูกครั้งเดียวแล้วคัดลอกได้ |
| 2 | WF-AC-02 | ไม่มีตัวนี้ ไม่มีอะไรเข้าบัญชีแยกประเภท = ทดสอบอย่างอื่นไม่ได้ |
| 3 | WF-AC-10 | คู่กับ 02 — พิสูจน์ว่าแก้รายการที่ผ่านแล้วได้อย่างถูกวิธี |
| 4 | WF-AC-09 | ปิดกั้นการบันทึกในงวดที่ปิด = พิสูจน์ BR-03 · ✅ **สร้าง publish และทดสอบผ่านครบแล้ว 27 ส.ค. 2569** |
| 5 | WF-AC-15 → 16 → 17 | สายภาษี ซึ่งเป็นเหตุผลหลักของเวอร์ชัน 2.0 |

---

### WF-AC-01 อนุมัติใบสำคัญ — **สร้างและ publish แล้ว** `6a8eaa45e6605c4b13ccf49b`

- **ชนิด / Surface:** `worksheet_event` (update) · **MCP** · publish 26 ส.ค. 2569 v1
- **Trigger:** worksheet `ac_voucher` `6a85fb2e9b6999a714d2a53d` · **Trigger Field = `status1` `6a86016b1049edca1eed028a`** · 🔴 **ห้ามใส่ `filter` ใน trigger** (ทำให้ไม่ยิงเลย — ยิงจริงพิสูจน์แล้ว) เงื่อนไขสถานะอยู่ใน branch แรกแทน
- **กันยิงซ้ำ:** `submitted_flag` `6a8ea405ae2a0e3743a084f0` `ne 1` — ฟิลด์ต้องมี **default 0**

**Nodes ที่สร้างจริง (ลำดับตามที่ publish)**

| # | nodeAlias | ชนิด | ทำอะไร |
|---|---|---|---|
| 1 | `gate` | branch condition | path `p_go`: `status1` eq Pending approval `982090bd-…` **AND** `submitted_flag` ne 1 · path `p_skip`: fallback |
| 2 | `set_flag` | update_record | `submitted_flag`=1 · `approval_level`=1 |
| 3 | `chk_balance` | branch condition | path `p_unbal`: `balance_diff` `6a860ae8055f2288c5b777f1` ne 0 · path `p_bal`: fallback |
| 4 | `rej_unbal` | update_record | `status1`=Draft · `submitted_flag`=0 · `reject_reason` = template พร้อมผลต่างและ `$system-nowTime$` |
| 5 | `notify_unbal` | send_internal_notice | แจ้ง `caid` (ผู้สร้าง) |
| 6 | `chk_period` | branch condition | path `p_closed`: `period_status_ref` `6a8b2f728b36df988c17f00f` ne Open `f662571c-…` · path `p_open`: fallback |
| 7 | `rej_period` | update_record | ตีกลับเป็น Draft พร้อมเหตุผล |
| 8 | `notify_period` | send_internal_notice | แจ้งผู้สร้าง |
| 9 | `appr_block` | approval_block | target = trigger · initiators = `caid` · สายอนุมัติภายใน `6a8eaa76730d20c5b76071f3` |

**Nodes ภายในสายอนุมัติ `6a8eaa76730d20c5b76071f3`** (start node **ไม่มี alias** — อ้างด้วย nodeId `6a8eaa76730d20c5b76071fc`)

| # | nodeAlias | ชนิด | ทำอะไร |
|---|---|---|---|
| 1 | `i_get_rule` | get_single | 🔑 **หากฎอนุมัติภายในสายอนุมัติ** — `ac_approval_rule` filter `doc_type` eq start›`voucher_type` **AND** `value_from` lte start›`total_debit` **AND** `is_active` checked · sort `effective_from` desc · ifEmpty `stop` |
| 2 | `approve_l1` | approve | 🔑 **`approvers` = `{kind:"field", node:{nodeAlias:"i_get_rule"}, fieldId:"6a85f7e01049edca1eed022d"}`** (ฟิลด์ OrgRole ของกฎ — อ้างตรง ห้ามคัดลอก) · `allowReject:true` · `allowTransfer:true` |
| 3 | `res_branch` | branch approval_result | `r_pass` (pass) · `r_reject` (overrule) — **ต้องอยู่ในสายอนุมัติต่อจาก approve** |
| 4 | `upd_approved` | update_record | `status1`=Approved `69d8e25d-…` · `approved_at`=nowTime · `approved_by` = `$approve_l1-executorid$` |
| 5 | `upd_rejected` | update_record | `status1`=Draft · `submitted_flag`=0 · `approved_at`=nowTime · `reject_reason` = template + `$approve_l1-opinionSummary$` |

**ผลการทดสอบจริง 26 ส.ค. 2569**

| เคส | ผล |
|---|---|
| ใบสำคัญไม่สมดุล (เดบิต 100 / เครดิต 0) ส่งขออนุมัติ | ✅ ถูกตีกลับเป็น Draft · `reject_reason` = "เดบิตไม่เท่ากับเครดิต ผลต่าง 100.00 บาท - ระบบตีกลับเป็นร่างเมื่อ 2026-08-26 16:42:56" · `_updatedBy` = **`user-workflow`** → **TC-01 ผ่าน** |
| ใบสำคัญสมดุล 50,000 ส่งขออนุมัติ | ✅ `get_approval_list_by_row` มี instance สถานะ 1 (รอดำเนินการ) · node "อนุมัติระดับที่ 1" · **ผู้รับผิดชอบ = Kunlasatri.c** ซึ่งมาจากบทบาท AC-R2 ในกฎ "ใบสำคัญทั่วไป - ไม่เกิน 100,000" |
| การกดอนุมัติ / ตีกลับจริงใน To-do | ⬜ **ยังไม่ทดสอบ** — ต้องมีบัญชีผู้อนุมัติกดเอง (ห้ามปิด ✅ จนกว่าจะกดจริง) |
| สายอนุมัติหลายระดับ (TC-04) | ⬜ ยังไม่ทำ — ปัจจุบันมี approve node ระดับเดียว |

- **Test recipe:** `create_record(ac_voucher, …, status1=Draft, submitted_flag=0)` + บรรทัด → `update_record(status1="Pending approval", triggerWorkflow:true)` → รอ ~10 วินาที → `get_record_details(includeSystemFields:true)` ต้องเห็น `_updatedBy` = `user-workflow` · `get_approval_list_by_row` ต้องมี instance
- **Pitfall:** ลบ record ทดสอบทุกครั้ง มิฉะนั้น To-do ค้างอยู่กับผู้อนุมัติจริง

---

### WF-AC-02 ผ่านรายการเข้าบัญชีแยกประเภท — **สร้างและ publish แล้ว** `6a8ea77e5f8564a68c33f9db`

- **ชนิด / Surface:** `worksheet_event` (update) · **MCP** ✅
  > 🔑 **แก้จาก spec เดิมที่ระบุ Browser** — node **`sub_process`** โหมด `sequential_each` ทำหน้าที่แทน Loop ได้ ⇒ ทำบน MCP ได้ทั้งตัว **ไม่ต้องเข้า Browser เลย**
- **Trigger:** `ac_voucher` · Trigger Field = `status1` · ไม่มี trigger filter
- **กันยิงซ้ำ:** `posted_flag` `6a85fb2e055f2288c5b7775f` `ne 1` (default 0 แล้ว)

**Nodes ที่สร้างจริง**

| # | nodeAlias | ชนิด | ทำอะไร |
|---|---|---|---|
| 1 | `gate` | branch condition | `p_post`: `status1` eq Approved `69d8e25d-…` **AND** `posted_flag` ne 1 · `p_skip`: fallback |
| 2 | `set_posted_flag` | update_record | `posted_flag`=1 (เซ็ตก่อนทำงานหนัก) |
| 3 | `get_lines` | get_multiple | `ac_voucher_line` filter `voucher` `6a85fb399b6999a714d2a557` eq trigger›`rowid` · sort `line_no` asc · limit 500 · ifEmpty `stop` |
| 4 | `loop_lines` | **sub_process** | target = `get_lines` · `execution.mode` = **`sequential_each`** · `continueAfterComplete` = true · พารามิเตอร์ `p_voucher_rowid` (text) = trigger›`rowid` · สาย subprocess `6a8ea79efdab77a41c4a37d6` |
| 5 | `mark_posted` | update_record | `status1`=Posted `a234503a-…` · `posted_at`=nowTime |
| 6 | `notify_posted` | send_internal_notice | แจ้งผู้สร้างว่ารายการที่ผ่านแล้วแก้ไม่ได้ ต้องกลับรายการ |

**Nodes ภายใน subprocess `6a8ea79efdab77a41c4a37d6`** (start alias = **`sub_trigger`** = บรรทัดใบสำคัญ · พารามิเตอร์อ้างด้วย `process_variable`)

| # | nodeAlias | ชนิด | ทำอะไร |
|---|---|---|---|
| 1 | `c_get_voucher` | get_single | `ac_voucher` filter `rowid` eq `process_variable`›`p_voucher_rowid` · ifEmpty `stop` |
| 2 | `c_add_gl` | add_record | สร้าง 1 แถวใน `ac_gl` — `posting_date`/`fiscal_year`/`journal`/`period` จาก `c_get_voucher` · `voucher` = `{kind:"record", node:c_get_voucher}` · `account`/`debit`/`credit`/`debit_thb`/`credit_thb`/`cost_center`/`fund`/`project`/`partner` จาก `sub_trigger` · `voucher_row_id` จากพารามิเตอร์ |

**ผลการทดสอบจริง 26 ส.ค. 2569**

| เคส | ผล |
|---|---|
| ใบสำคัญสมดุล 2 บรรทัด → Approved | ✅ เกิด `ac_gl` **2 แถวพอดี** (540199 เดบิต 100 · 540101 เครดิต 100) พร้อม `journal`=JV, `period`=2569-11, `posting_date`, `voucher_row_id` ครบ · `movement_seq` เดินต่อเนื่อง 2, 3 |
| ยิงซ้ำเป็น Approved อีกครั้ง | ✅ จำนวน `ac_gl` **เท่าเดิม (2)** — กันผ่านรายการซ้ำได้จริง |
| `status1` → Posted และ `posted_at` | ✅ `posted_at` = 2026-08-26 16:46:51 เขียนโดย workflow |

- **Gap ที่ยังเหลือ:** `debit_thb`/`credit_thb` ยังคัดลอกค่าเดิมโดยไม่คูณอัตราแลกเปลี่ยน (ถูกต้องเฉพาะ THB) · ยังไม่มีขั้นสร้าง `ac_vat_doc` เมื่อเอกสารมี VAT · ยังไม่ตรวจงวดบัญชีซ้ำ ณ วินาทีผ่านรายการ

---

### WF-AC-03 รับรู้หนี้สินจากการตรวจรับ `<TBD>`

- **ชนิด / Surface:** `webhook` · **MCP** · ⬜ รอข้อตกลง payload กับโมดูลจัดซื้อ 🔴
- **Nodes:** Trigger by webhook → **JSON Parsing** (⚠️ **Browser** — node นี้อยู่นอก 17 ชนิดของ MCP ⇒ **ทั้ง workflow ต้องทำใน Browser**) → Branch ตรวจ idempotency (`Query worksheet ac_ap` filter `gr_ref` `6a8673d69b6999a714d2a9ca` equals payload.gr_no → ถ้าเจอ Terminate) → Get Single Record `ac_partner` จากเลขผู้เสียภาษี → Branch สอบถามวงเงินงบประมาณ (BR-15, node **Send API Request**) → Create Record `ac_ap` → Loop สร้าง `ac_ap_line` → **Function calculation** คำนวณ `taxable_base`/`non_taxable_base`/`vat_amount`/`wht_amount`/`total_amount`/`net_payable`/`outstanding` → Update Record `ap_status` = Recognised → Create Record `ac_voucher` (อ่านคู่บัญชีจาก `ac_posting_rule` event `AP_RECOGNITION` `441ffaf1-01d5-415e-a79b-87c557b97e6f`) + `ac_voucher_line` → Update `status1` = Approved (ให้ WF-AC-02 รับช่วง)
- **Test recipe:** ยิง webhook ด้วย payload ตัวอย่าง 1 ชุด → `get_record_list(ac_ap, filter gr_ref=…)` = 1 · ยิงซ้ำ payload เดิม → ยังคง 1 (idempotent) · log ขึ้น `user-workflow`
- **Pitfall:** อย่าทดสอบด้วย `create_record` ผ่าน MCP เพราะ operator จะเป็น `user-api` และไม่ผ่าน trigger ของ webhook

---

### WF-AC-04 ตัดชำระเมื่อได้ผลการจ่าย `<TBD>`

- **ชนิด / Surface:** `webhook` · **Browser** (JSON Parsing)
- **Nodes:** Trigger by webhook → JSON Parsing → Get Single Record `ac_pay` จาก `pay_no` → Branch idempotency (`AC_PAY_SETTLE.finance_ref` 🆕 ซ้ำ → Terminate) → Loop สร้าง `ac_pay_settle` ต่อคู่ค้า (`gross` `6a8677de9b6999a714d2aaa4`, `wht` `…aa5`, `net` `…aa6`, `payment_date` `…aa7`, `payment_channel` `…aa8`) → Get associated records `ac_pay_line` → Loop: **Function calculation** `ap.paid_amount` += `net_amount` `6a8677d71049edca1eed0704` แล้ว `outstanding` = `net_payable` − `paid_amount` → Branch: `outstanding` = 0 → `ap_status` = Fully paid `7c3abf94-…` มิฉะนั้น Partially paid `b8914358-…` → Create Record `ac_voucher` จาก `ac_posting_rule` event `AP_SETTLEMENT` `30c11f67-b239-41f6-9f77-0d221e0ff487` → Branch: `wht_timing` = At payment → **สร้าง `ac_wht`** (ดู WF-AC-06)
- **DoD:** TC-23 ผ่าน — ใบสำคัญจ่าย 1 ใบ 3 คู่ค้า 7 เอกสาร → settle 3 รายการ · เจ้าหนี้ทั้ง 7 คงเหลือ 0

---

### WF-AC-05 รับรู้ลูกหนี้และการรับชำระ `<TBD>` ⬜

- **ชนิด / Surface:** `worksheet_event` (update) บน `ac_inv` `<TBD>` · **MCP** · ขึ้นกับ FR-12 (A-09)
- **Nodes:** Trigger Field = `inv_status` → Branch = Approved → Get associated records `ac_ar_line` → Function calculation ยอดรวม → Create Record `ac_voucher` จาก `ac_posting_rule` event `AR_RECOGNITION` `cb43c092-05e8-4858-9ed0-70ea2bf722c0` → Create Record `ac_vat_doc` (`vat_side` = Output `b76cdc18-743c-4822-b2aa-110b5a162768`, `sign` `6a8677f933560633b8cda34c` = 1) → Update `status1` = Approved
- **ส่วนรับชำระ:** trigger บน `ac_re` → event `AR_COLLECTION` `55fdff1b-90c2-44f8-be19-8bcfca7c08f7` → ปรับ `AC_AR.collected_amount` / `outstanding` / `ar_status`

---

### WF-AC-06 ออกใบรับรองหัก ณ ที่จ่าย `<TBD>`

- **ชนิด / Surface:** `worksheet_event` · **MCP**
- **จังหวะการออก:** ขึ้นกับ `AC_DOC_SETTING.wht_timing` `6a85229a8b36df988c1721d9`
  - **At payment `998bd1a6-1d3b-4b57-9b8e-9587624b3614` (ค่า default ตาม A-10)** → เรียกจาก **WF-AC-14 / WF-AC-04** ตอนออกใบสำคัญจ่าย · `AC_WHT.source_type` `6a8677f1055f2288c5b77d35` = `3b14bfb0-dc38-4f87-918d-b59a97755a66` (PAY)
  - At invoice `250c24af-…` → trigger จาก `ac_ap` เมื่อ `ap_status` = Recognised · `source_type` = `4572f17b-f93e-4dac-8531-909f7c31a223` (AP)
- **Nodes:** Branch อ่าน `wht_timing` → Get associated records `ac_ap_line` filter `wht_type` `6a8673e78b36df988c176b8f` is not empty → **จัดกลุ่มตาม `income_type`** (หนึ่งใบรับรองต่อคู่ค้าต่อประเภทเงินได้ต่อวันจ่าย) → Get Multiple Records `ac_wht_rate` `6a8545688b36df988c172471` filter `income_type` + `payee_legal_form` `6a85e519055f2288c5b7768d` = partner › `legal_form` `6a85e486055f2288c5b77672` + `effective_from` ≤ วันจ่าย → **Function calculation:** ถ้า `wht_borne_by` 🆕 = Payer → gross-up `base = net / (1 − rate/100)` มิฉะนั้น `base = line_amount` → Create Record `ac_wht` (`base_amount` `6a8677f1055f2288c5b77d2e`, `wht_rate` `…d2f`, `wht_amount` `…d30`, `pay_date` `…d2b`, `income_type` `…d2c`, `partner` `…d28`) → เดินเลขที่จาก `ac_doc_number_rule` → Update `wht_no` `6a8677f1055f2288c5b77d27`
- **DoD:** TC-18 ผ่าน — กรณี gross-up ฐานถูกคำนวณใหม่ และใบรับรองตรงกับ GL

---

### WF-AC-07 คิดและผ่านรายการค่าเสื่อมรายเดือน `<TBD>` ⬜

- **ชนิด / Surface:** `schedule` — สิ้นเดือน เวลา 23:00 (+07:00) · **MCP** · ขึ้นกับ FR-13 (A-11)
- **Nodes:** Trigger by time → Get Single Record `ac_period` ของเดือนนั้น → Branch `period_status` = Open → Get Multiple Records `ac_asset_book` filter `asset_status` = In use `8c42f795-…` → Loop: **Function calculation** ค่าเสื่อมตาม `depr_method` (เส้นตรง: `(cost − salvage_value) / life_years / 12`) → Create Record `ac_depr_schedule` → จัดกลุ่มตาม `category` + `cost_center` → Create Record `ac_depr` + `ac_voucher` จาก `ac_posting_rule` event `DEPRECIATION` `6d4e44df-1d0c-4710-aabb-2dc67dcdc4a6` → Update `posted_flag` บนตารางค่าเสื่อม
- **Test recipe:** ตั้งเวลาแล้วกด **"Execute now"** ใน Browser (schedule trigger ยิงผ่าน MCP ไม่ได้) → ดู Workflow History + log `user-workflow`
- **DoD:** TC-10 — ใบสำคัญตรงกับตารางค่าเสื่อมและทะเบียนสินทรัพย์

---

### WF-AC-08 กระทบยอดธนาคาร `6a8ff2c0fdab77a41c543108` — ✅ **สร้าง publish และทดสอบผ่านครบแล้ว 27 ส.ค. 2569 (รอบเย็น) — publishVersion 3**

- **ชนิด / Surface:** `worksheet_event` (add) บน `AC_BANK_RECON` ws `6a8fd69d1378964f9984a2ad` · **MCP ล้วน (ไม่ต้องใช้ Browser เลย ยกเว้นตอน debug ผ่าน Workflow History)**
- **Nodes จริงที่สร้าง (8 nodes):**
  1. `getBank` (get_single) — worksheetId `AC_BANK` `6a854584055f2288c5b74202` · filter: `left={field, node:getBank, fieldId:'rowid'}` `op:'eq'` `right={field, node:trigger, fieldId:'6a8fd6e8353e1b0e4a507e2f'}` (biz_bank_recon_bank_account) · `ifEmpty:'continue'`
  2. `rollupDebit` (rollup, method `sum`) — worksheetId `AC_GL` `6a85fb4133560633b8cd9f4a` fieldId `debit_base` `6a85fb419b6999a714d2a596` · filter: `account`(`6a85fb419b6999a714d2a592`) `eq` `getBank.gl_account`(`6a85519a33560633b8cd6a1f`) **AND** `posting_date`(`6a85fb419b6999a714d2a58a`) `lte` `trigger.statement_date`(`6a8fd6e8353e1b0e4a507e33`)
  3. `rollupCredit` (rollup, method `sum`) — เหมือนข้อ 2 แต่ fieldId `credit_base` `6a85fb419b6999a714d2a597`
  4. `bookBalance` (compute number) — `$rollupDebit-number_fx_id$-$rollupCredit-number_fx_id$`
  5. `diffCalc` (compute number) — `$trigger-6a8fd6e8353e1b0e4a507e34$-$bookBalance-number_fx_id$` (statement_balance − book_balance)
  6. `writeBalances` (update_record, target=trigger) — set `biz_bank_recon_book_balance`(`…e35`)=bookBalance, `biz_bank_recon_difference`(`…e36`)=diffCalc
  7. `diffBranch` (branch, condition) — path `hasDiff`: diffCalc.number_fx_id `ne` 0 · path `noDiff`: filter null (fallback)
  8. `notifyDiff` (send_internal_notice, parentNode+prevNode=`hasDiff`) — recipients `{kind:'role', roleId:'80bac1f7-44b2-4c5c-8808-53e4de14e2bf'}` (AC-R2) · template อ้าง `biz_bank_recon_no` และ `diffCalc.number_fx_id`
- **Gap:** ไม่มีแล้ว — ปิดครบ 100%
- **ผลทดสอบ (ทั้ง 2 เส้นทาง ผ่าน Workflow History + `get_record_details`):**
  - เคสมีผลต่าง (statement_balance 35,500 vs GL 50,000−15,000=35,000): `book_balance=35000.00`, `difference=500.00`, `_updatedBy=user-workflow`, log แสดง trigger→getBank→writeBalances→diffBranch(หาสมัผลต่าง)→**notifyDiff (Station Notice People ยิงจริง)**
  - เคสไม่มีผลต่าง (statement_balance 35,000 = GL 35,000): `difference=0.00`, log จบที่ branch path "ไม่มีผลต่าง" **ไม่ยิง notifyDiff** ตามที่ออกแบบ
  - Fixture ทดสอบ (2 แถว AC_GL backfill + 2 แถว AC_BANK_RECON) ลบออกหมดแล้วหลังยืนยันผล ตารางกลับเป็น 0 record
- **🔴 บั๊กแพลตฟอร์มใหม่ที่พบระหว่างสร้าง — ดูกับดักข้อ 26 ใน `04-CLAUDE-memory.md`:** `Condition.right` ชนิด `kind:"record"` ถูก**ตัดทิ้งเงียบ ๆ**ตอนบันทึก (ไม่มี `"value"` เหลืออยู่เลยตอนอ่านกลับด้วย `get_workflow_structure`) และ `validate_process` **ไม่จับ**ปัญหานี้ — ทำให้ node รันจริงแล้ว fail ด้วย "筛选条件值为空" (filter condition value is empty) เห็นได้เฉพาะใน **Browser → Workflow → History** เท่านั้น ไม่มีทางเห็นผ่าน MCP tool ใด ๆ เลย (get_record_logs ก็ไม่บันทึกอะไรถ้า workflow fail ตั้งแต่ node แรก ๆ)

---

### WF-AC-09 ปิดงวด `6a903ec05f8564a68c3f7d7d` — ✅ **สร้าง publish (v1) และทดสอบผ่านครบทั้ง 2 เส้นทาง 27 ส.ค. 2569 (รอบเย็น ต่ออีกครั้ง) — บังคับ BR-03**

- **ชนิด / Surface:** `worksheet_event` (update) บน `AC_PERIOD` ws `6a8434d5055f2288c5b6d4b8` · ยิงจากปุ่ม "ปิดงวด" · **MCP ล้วน (ไม่ต้องใช้ Browser เลยสำหรับตัว workflow — ยกเว้นขั้นตอนที่เหลือคือ verify Scope ของปุ่ม)**
- **Trigger:** `worksheet_event` (update) · **Trigger Field = `biz_close_flag`** (`6a903ea68b6633ef76f169c5`) · **ไม่มี filter บน trigger เอง** (ตามกฎเดิม — ห้ามใส่ filter ใน `worksheet_event` trigger เด็ดขาด เงื่อนไขทั้งหมดอยู่ใน branch แรกแทน)
- **ฟิลด์ใหม่ที่สร้าง:** `biz_close_flag` ("ปิดงวด (ธง)") — Number precision 0, default 0, field id **`6a903ea68b6633ef76f169c5`** (นี่คือฟิลด์ที่เดิมเอกสารระบุเป็น 🆕 `close_flag` — สร้างจริงในชื่อ `biz_close_flag`)
- **Custom Action button "ปิดงวด":** สร้างผ่าน `create_custom_actions` — actionId **`6a903eb89762533b5b71c4b2`**, internal workflowId `6a903eb8fdab77a41c5697ca`, ชนิด `updateCurrentRecord`, `updateFields:["biz_close_flag"]`, `enableWhen: period_status equals Open (f662571c-…)`, `runWorkflowAfterSubmit:true` · **Scope ยังไม่ verify ผ่าน Browser** (คาดว่าเป็น "Unassigned View" ตามแพทเทิร์นกับดักข้อ 20 — ดู Gap ด้านล่าง)

**Nodes จริงที่สร้าง (16 nodes + trigger — ต่างจาก 7-node design เดิมของ spec ฉบับร่าง เพราะเจอบั๊กแพลตฟอร์มใหม่ 2 ตัวระหว่างสร้าง ดูด้านล่าง)**

1. `gate` (branch) — path `gateOk`: `biz_close_flag` eq 1 **AND** `period_status` (`6a851f70055f2288c5b73edf`) eq Open (`f662571c-…`) · path `gateNo`: fallback (จบเงียบ ๆ ถ้าเงื่อนไขไม่ผ่าน)
2. `getPendingDraft` (get_multiple, parentNode=`gateOk`) — `AC_VOUCHER` ws `6a85fb2e9b6999a714d2a53d` filter `period` eq trigger›`rowid` (relation-vs-rowid pattern) **AND** `voucher_status` eq Draft (`3536165d-460c-4942-8bec-6f381209d8da`) · limit 50000
3. `getPendingWaiting` (get_multiple) — เหมือนข้อ 2 แต่ `voucher_status` eq Pending approval (`982090bd-bec8-4cec-a0e5-7b4de07d4d13`)
4. `rollupPendingDraft` (rollup, method count, target=`getPendingDraft`)
5. `rollupPendingWaiting` (rollup, method count, target=`getPendingWaiting`)
6. `sumPending` (compute number) — expression `$rollupPendingDraft-number_fx_id$+$rollupPendingWaiting-number_fx_id$`, `nullZero:true`
7. `checkPending` (branch) — path `hasPending`: `sumPending.number_fx_id` gt 0 · path `noPending`: fallback
8. `clearFlag1` (update_record, parentNode=`hasPending`) — reset `biz_close_flag` = 0 บน trigger record
9. `notifyPending` (send_internal_notice, ต่อจาก `clearFlag1`, ถึง triggerUser) — ระบุชื่องวดและจำนวนรายการค้างทั้ง 2 สถานะ · **เส้นทางนี้จบที่นี่ (natural termination) — ตรงตามพฤติกรรม "ปฏิเสธและหยุด" ที่ spec ต้องการ (บังคับ TC-11)**
10. `getBlocking` (get_multiple, parentNode=`noPending`) — `AC_CLOSE` ws `6a8fd69e353e1b0e4a507e16` filter `biz_close_period` (`6a8fd7091378964f9984a2c3`) eq trigger›`rowid` **AND** `biz_close_blocking` (`6a8fd7091378964f9984a2c9`) eq 1 **AND** `biz_close_item_status` (`6a8fd7091378964f9984a2c6`) ne ผ่าน (`27447ced-2a81-43d0-922e-0ca14e76197e`) · limit 50000
11. `rollupBlocking` (rollup, method count, target=`getBlocking`)
12. `checkBlocking` (branch) — path `hasBlocking`: `rollupBlocking.number_fx_id` gt 0 · path `noBlocking`: fallback
13. `clearFlag2` (update_record, parentNode=`hasBlocking`) — reset `biz_close_flag` = 0
14. `notifyBlocking` (send_internal_notice, parentNode=`hasBlocking`, ถึง triggerUser) — ระบุจำนวนรายการ checklist ที่ยังไม่ผ่าน · จบที่นี่เช่นกัน
15. `closePeriod` (update_record, parentNode=`noBlocking`) — `period_status` = **Soft-closed** (`b2986cb5-59db-4fdc-87ed-d57a38201c6a`) · `closed_by` (`6a8434d58b36df988c16ed6a`) = systemField triggeraid · `closed_at` (`6a8434d58b36df988c16ed6b`) = systemField nowTime · `biz_close_flag` = 0
16. `notifySuccess` (send_internal_notice, ถึง roles AC-R1 `c5819f0b-34f6-449b-a812-f8ec02073b85`, AC-R2 `80bac1f7-44b2-4c5c-8808-53e4de14e2bf`, AC-R3 `4de23d6f-a011-4308-9849-d1335183d34e`) — ระบุชื่องวด ปีบัญชี และลำดับงวด

> ยืนยันกราฟทุก node ผ่าน `get_workflow_structure` readback หลังทุก batch · `validate_process` ผ่าน 0 issue ก่อน `publish_process` เป็น **v1**

**🔴🔴 บั๊กแพลตฟอร์มใหม่ 2 ตัวที่พบระหว่างสร้าง (นี่คือเหตุผลที่กราฟจริงต่างจาก 7-node design เดิม) — ดูกับดักข้อ 28/29 ใน `04-CLAUDE-memory.md`:**

1. **`Condition.op:"in"` กับ `right` เป็น literal array ≥2 ตัว ถูกตัดเหลือค่าแรกเงียบ ๆ ตอนบันทึก** — node 3 เดิมของ design ฉบับร่าง (`voucher_status` in [Draft, Pending approval]) หลังสร้างแล้วอ่านกลับด้วย `get_workflow_structure` พบว่า filter จริงกลายเป็น `operator:"eq"` เหลือแค่ค่าแรก (Draft) ค่าที่สองหายไปเงียบ ๆ — `validate_process` ตอบ 0 issue เหมือนเดิมทุกครั้ง จับได้เฉพาะจากการอ่าน readback เทียบจำนวนค่าที่ส่งไปเท่านั้น
2. **nested `Filter` group `logic:"or"` ข้างใน group ชั้นนอก `logic:"and"` ถูกทำให้แบนราบเงียบ ๆ — เสีย OR semantics ไปหมด** — ลองแก้บั๊กข้อ 1 ด้วยวิธีมาตรฐาน (ห่อเงื่อนไข OR เป็น nested group วางใน `items` ของ group AND ชั้นนอก) แต่ readback พบว่าเงื่อนไขทั้งหมดถูกดึงแบนเป็น flat AND เดียวกันหมด (period eq X AND status eq Draft AND status eq Pending approval พร้อมกัน) ⇒ ไม่มี record ใดจะ match ได้เลย คืน 0 แถวเสมอโดยไม่มี error ใด ๆ ทั้ง `validate_process` และ runtime

**วิธีแก้ที่พิสูจน์แล้ว (แพทเทิร์นมาตรฐานสำหรับ "ฟิลด์ต้องเท่ากับหนึ่งใน N ค่า" ต่อจากนี้):** เลิกใช้ `op:"in"` และเลิกใช้ nested OR filter group ทั้งคู่ — สร้าง **N `get_multiple` แยกกัน** (แต่ละตัว filter แบบ flat AND-only ด้วย `eq` ค่าเดียว) + **N `rollup(method:"count", target:<get_multiple นั้น>)`** + **1 `compute` รวมยอดทุกตัว** (`nullZero:true`) + **1 `branch`** เช็คว่าผลรวม > 0 — คือ nodes `getPendingDraft`/`getPendingWaiting`/`rollupPendingDraft`/`rollupPendingWaiting`/`sumPending`/`checkPending` ข้างบน (แทนที่ node 3 เดิมของ 7-node design)

**พฤติกรรม delete node ที่พบระหว่างแก้บั๊กข้างบน (ดูกับดักข้อ 30):** ลบ node ธรรมดา (เช่น `get_multiple`/`rollup` เดี่ยว) ไม่ cascade ลบ node ลูก — node ถัดไปถูก auto-relink `prevNode` ให้เองแต่ **ไม่ซ่อม data reference อื่นที่ชี้ไปที่ node ที่ถูกลบ** (เช่น `rollup.config.target` จะหลุด key `node` ไปเลย หรือ template placeholder จะค้างอ้าง nodeId ที่ไม่มีอยู่จริง) ส่วนลบ **branch node** จะ cascade ลบทั้ง subtree ทุก path ทันที — เมื่อต้องแก้ node ที่มีลูกต่อพ่วงอยู่แล้วหลายตัว มักสะดวกกว่าที่จะลบ branch node ต้นทางที่ใกล้ที่สุดแล้วสร้างใหม่ทั้งสาย

- **ผลการทดสอบจริง 27 ส.ค. 2569 (ทั้ง 2 เส้นทางผ่าน):**
  - **เส้นทางปฏิเสธ (มีรายการค้าง):** ใช้ period ทดสอบ "2569-11" (rowId `c46fde49-bbd4-4f5a-8c14-24e627be98d2`) ซึ่งมี 4 ใบสำคัญทดสอบสถานะ Draft อยู่แล้ว (ZZTEST-JV-101/102/103, ZZTEST-REV-001 reversal target — ไม่ต้องสร้างข้อมูลทดสอบใหม่) ตั้ง `biz_close_flag=1` ผ่าน `update_record(triggerWorkflow:true)` ⇒ ยืนยันผ่าน `get_record_details(includeSystemFields:true)`: `_updatedBy=user-workflow`, `biz_close_flag` รีเซ็ตเป็น `0`, `period_status` ยังคงเป็น เปิด, `closed_by`/`closed_at` ยังว่างเปล่า
  - **เส้นทางปิดสำเร็จ:** ใช้ period "2569-01" (rowId `39f157cf-9da2-4026-a149-531a86386357`) ซึ่งไม่มีใบสำคัญและไม่มี AC_CLOSE checklist ผูกเลย (ตาราง AC_CLOSE ทั้งระบบมี 0 record — ยังไม่มี blocking item เกิดขึ้นจริงที่ไหนเลย) ตั้ง `biz_close_flag=1` ผ่าน `update_record(triggerWorkflow:true)` ⇒ ยืนยันผ่าน `get_record_details` (~6 วินาทีหลังยิง, workflow ทำงาน async): `_updatedBy=user-workflow`, `period_status`="ปิดชั่วคราว" (Soft-closed), `closed_at`=timestamp จริง, `closed_by`=บัญชีผู้ยิง, `biz_close_flag` รีเซ็ตเป็น `0`
  - **Cleanup:** revert period 2569-01 กลับเป็น Open พร้อมล้าง `closed_by`/`closed_at` ผ่าน `update_record(triggerWorkflow:false)` (ซ่อมข้อมูลล้วน ไม่ใช่ event ธุรกิจจริง) ยืนยันกลับสถานะเดิมแล้ว · period 2569-11 ไม่ต้อง cleanup เพิ่ม เพราะ `biz_close_flag` ถูก workflow เองรีเซ็ตเป็น 0 ไปแล้วตั้งแต่รอบทดสอบที่ 1
- **Test recipe:** `update_record(ac_period, biz_close_flag=1, triggerWorkflow:true)` บน period ที่มี/ไม่มีรายการค้าง → รอ ~5-10 วินาที → `get_record_details(includeSystemFields:true)` ต้องเห็น `_updatedBy=user-workflow`
- **Gap ที่เหลือ:** ปุ่ม "ปิดงวด" (`6a903eb89762533b5b71c4b2`) ยังไม่ verify Scope ผ่าน Browser — คาดว่าเป็น "Unassigned View" ตามแพทเทิร์นกับดักข้อ 20 เหมือนปุ่มก่อนหน้าทุกปุ่ม (ต้องเปลี่ยนเป็น "All Records" ก่อนปุ่มจะโผล่บนหน้าจอจริง) — เป็นเพียง gap ด้าน UI-visibility เท่านั้น ตัว workflow logic ทดสอบผ่านครบแล้วผ่าน `update_record` ตรง · ปุ่ม "เปิดงวดใหม่" และฟิลด์ `reopened_by`/`reopened_at` ของ BR-03 เป็นงานคนละส่วน (ยังไม่สร้าง) — อย่าปนกับ WF-AC-09

---

### WF-AC-10 กลับรายการใบสำคัญ `<TBD>`

- **ชนิด / Surface:** `worksheet_event` ยิงจากปุ่ม "กลับรายการ" (ชนิด `triggerWorkflow`) · **MCP**
- **Nodes**
  1. Trigger · 2. **Branch** — `status1` equals Posted `a234503a-…`
  3. **Get Single Record** `ac_period` ของวันที่ปัจจุบัน → Branch `period_status` = Open (ถ้างวดเดิมปิดแล้ว ให้ลงกลับรายการในงวดปัจจุบัน)
  4. **Create Record** `ac_voucher` ใหม่ — `voucher_date` = วันที่ปัจจุบัน · `journal` = ต้นฉบับ · `voucher_type` = ต้นฉบับ · `period` = งวดปัจจุบัน · `description` = `"กลับรายการใบสำคัญ {voucher_no}"` · **`reversal_of` `6a85fb489b6999a714d2a5cd` = ใบสำคัญต้นฉบับ** · `status1` = Draft
  5. **Get associated records** บรรทัดต้นฉบับ → **Loop → Create Record** `ac_voucher_line` โดย **สลับเดบิตกับเครดิต**
  6. **Branch (มี VAT)** → **Create Record** `ac_vat_doc` ด้วย `sign` `6a8677f933560633b8cda34c` = **−1** และ `base_amount` / `vat_amount` เป็นค่าติดลบ (บังคับ **TC-07**)
  7. **Update Record** (ต้นฉบับ) — `status1` = **Reversed** `8ce6c682-5c42-42f3-b6a9-62ea17a12205`
  8. **Update Record** — `AC_GL.is_reversed` `6a85fe6433560633b8cd9f7a` = ติ๊ก บนทุกแถวของใบสำคัญต้นฉบับ
  9. **Update Record** (ใบใหม่) — `status1` = Pending approval → เข้าสาย WF-AC-01 (ผู้อนุมัติ = AC-R3 เท่านั้นตาม `AC_APPROVAL_RULE`)
- **DoD:** TC-07 — ใบกลับรายการถูกสร้าง ต้นฉบับเป็น Reversed และรายการภาษีติดลบถูกสร้าง

---

### WF-AC-11 ปิดปีและยกยอด `6a90ef69fdab77a41c5b514f` — ✅ **สร้าง publish (v1) และทดสอบผ่านครบทั้ง 2 เส้นทาง 28 ส.ค. 2569**

> 🔴 **สเปกเดิมด้านล่าง (Branch ทุกงวดเป็น Soft-closed → filter `account.account_type` in Revenue/Expense → …) ใช้สร้างตรง ๆ ไม่ได้ 2 จุด — แก้แล้วดังนี้ (เหตุผลเต็มอยู่ในกับดักข้อ 28/31 ของ `04-CLAUDE-memory.md`):**
> 1. **`AC_GL` ไม่มีฟิลด์ Lookup/Formula ที่โผล่ `account.account_type`** และ Lookup/Formula สร้างผ่าน API ไม่ได้ (ต้องผ่านหน้าจอเท่านั้น) ⇒ **เปลี่ยนไปตรวจ `account_type` ที่ต้นทาง `AC_COA` ก่อน แล้ว hardcode รายชื่อ rowid บัญชีรายได้/ค่าใช้จ่ายที่ผ่านรายการได้จริงลงในตัว workflow แทน** (4 บัญชีรายได้ + 12 บัญชีค่าใช้จ่าย ณ วันที่สร้าง — ถ้าเพิ่มบัญชีใหม่ในผังบัญชีต้องมาแก้ node เพิ่มเอง ไม่ auto-scale)
> 2. **`Condition.op:"in"` กับ literal array ≥2 ค่า ถูกตัดเงียบเหลือค่าแรก (กับดักข้อ 28)** — แม้ AC_GL.`account` จะเป็น Relation ก็ตาม (ทดสอบยืนยันแล้วว่ากับดักข้อ 28 ครอบคลุมถึง Relation field ด้วย ไม่ใช่แค่ Dropdown) ⇒ **เลิกใช้ `in` ทั้งหมด สร้าง 1 rollup(sum) ต่อ 1 บัญชี ต่อ 1 ด้าน (เดบิต/เครดิต) แทน** — รายได้ 4 บัญชี×2 = 8 rollups, ค่าใช้จ่าย 12 บัญชี×2 = 24 rollups (รวม 32 rollups) แล้วบวกรวมด้วย `compute` แทนการ filter ด้วย `in` ครั้งเดียว
> 3. **`source_module` ไม่มีตัวเลือก "CLOSING"** (ค่าที่สเปกเดิมอ้าง `49686cf3-…` ไม่มีจริงใน optionset) — ตรวจ `get_optionset_list` แล้วพบว่าเป็นสเปกที่ล้าสมัย ⇒ **ใช้ค่า "ปิดงวด" ที่มีอยู่จริงแทน** (`9f91b297-8939-4d23-8d72-168fd9cfd792`) เพราะเป็นค่าที่ใกล้เคียงที่สุดในความหมาย (ผ่านรายการมาจากกระบวนการปิดงวด/ปิดปี ไม่ใช่จากเอกสารต้นทางภายนอก) — **บันทึกไว้ชัดเจนว่าเป็นการ reuse ค่าที่มีอยู่ ไม่ใช่ความหมายดั้งเดิมของ key นี้** หากภายหลังต้องแยกรายงานปิดงวดกับปิดปีออกจากกัน ให้เพิ่มตัวเลือก "CLOSING" ใหม่ผ่านหน้าจอ (SingleSelect inline แก้ได้เฉพาะทางหน้าจอ)
> 4. **ตรวจ "ทุกงวด 1–13 เป็น Soft-closed" ในทางปฏิบัติ implement เป็น "ไม่มีงวดไหนของปีนี้ยังเป็น Open"** (`getOpenPeriods` filter `period_status eq Open`, ไม่ใช่ filter หา Soft-closed ทั้ง 13 งวดแล้วนับให้ครบ 13) — สมมูลกันในทางปฏิบัติ (state machine ของ `period_status` ไม่มีทางย้อนจาก Soft-closed/Permanently-locked กลับเป็น Open โดยไม่ผ่านปุ่ม "เปิดงวดใหม่" ซึ่งเป็น manual action ที่ผู้ใช้ต้องตั้งใจทำ) แต่เขียนสั้นกว่าและไม่ต้องนับจำนวนงวดที่แน่นอน (13 หรือมากกว่าถ้ามีปีที่จำนวนงวดไม่เท่ากัน)
> 5. **ยกยอดบัญชีงบดุลเก็บเป็นยอดสะสมขั้นต้น (gross debit/credit) ไม่ใช่ยอด net เดียว** — เป็นการตัดสินใจออกแบบตั้งใจ (ดูหมายเหตุใน node graph ด้านล่าง) ต่างจากที่สเปกเดิมสื่อเป็นนัยว่าเก็บยอดเดียว

- **ชนิด / Surface:** `worksheet_event` (update) บน `AC_PERIOD` ws `6a8434d5055f2288c5b6d4b8` · **Trigger Field = `biz_close_year_flag`** (`6a90ef228b6633ef76f16f55`) · **ไม่มี filter บน trigger เอง** (เงื่อนไขทั้งหมดอยู่ใน branch แรก) · ยิงจากปุ่ม **"ปิดปีและยกยอด"** บนงวด 13 · **MCP ล้วน ทั้ง main flow และ 4 inner sub-process** — ไม่ต้องใช้ Browser เลยสำหรับตัว workflow (ยกเว้นขั้นตอนที่เหลือคือ verify Scope ของปุ่ม)
- **ฟิลด์ใหม่ที่สร้าง:** `biz_close_year_flag` ("ปิดปี (ธง)") — Number precision 0, default 0, field id **`6a90ef228b6633ef76f16f55`**
- **Custom Action button:** "ปิดปีและยกยอด" — actionId **`6a90f50e1378964f9984df83`** (internal workflowId `6a90f50e0e97bf440de723d7`) · `updateCurrentRecord` เขียน `biz_close_year_flag`=1 · `enableWhen`: `period_no` eq 13 **AND** `period_status` eq Soft-closed (`b2986cb5-…`) · `runWorkflowAfterSubmit:true` · ⚠️ **Scope ยังไม่ verify ผ่าน Browser** (คาดว่าเป็น "Unassigned View" ตามแพทเทิร์นกับดักข้อ 20 — ต้องเข้า Browser ตั้งเป็น "All Records" ก่อนปุ่มจะโผล่จริง)

**Node graph ตามจริง (56 nodes + trigger, สร้าง/ทดสอบผ่าน MCP ล้วน — ใหญ่กว่าดีไซน์ 16-node เดิมมากเพราะ workaround ข้อ 2 ด้านบน):**

1. `getOpenPeriods` (get_multiple, AC_PERIOD) — filter `fiscal_year` eq trigger.fiscal_year **AND** `period_status` eq Open
2. `rollupOpenCount` (rollup count, target=`getOpenPeriods`)
3. `gateReady` (branch firstMatch) — path `notReady`: `rollupOpenCount` > 0 · path `ready`: fallback
4. **[notReady]** `notifyNotReady` (send_internal_notice ถึงผู้กดปุ่ม `{kind:'triggerUser'}`) → `clearFlag1` (update_record รีเซ็ต `biz_close_year_flag`=0 บน trigger) — จบสาย
5. **[ready]** `sumRevDebit1..4` / `sumRevCredit1..4` (rollup sum ×8) — แต่ละตัว `AC_GL` filter `fiscal_year` eq trigger.fiscal_year **AND** `account` eq **1 ใน 4 rowid บัญชีรายได้เจาะจง** (`af49373e-…`, `f43fe825-…`, `10310f9b-…`, `bf7ba06c-…`)
6. `sumExpDebit1..12` / `sumExpCredit1..12` (rollup sum ×24) — แต่ละตัว `AC_GL` filter เดียวกันแต่ `account` eq **1 ใน 12 rowid บัญชีค่าใช้จ่ายเจาะจง** (`0325fd43-…`, `6f24c49f-…`, `72663a02-…`, `8a491b90-…`, `fb4ffa80-…`, `9228600c-…`, `8c855408-…`, `a719cf42-…`, `33f9712f-…`, `43ee2889-…`, `86485e09-…`, `e953681b-…`)
7. `computeRevenue` (compute, `nullZero:true`) = Σเครดิตรายได้ − Σเดบิตรายได้
8. `computeExpense` (compute, `nullZero:true`) = Σเดบิตค่าใช้จ่าย − Σเครดิตค่าใช้จ่าย
9. `computeNet` (compute) = `computeRevenue` − `computeExpense`
10. `computeNextYear` (compute) = trigger.fiscal_year + 1
11. `getDefaultJournal` / `getDefaultVoucherType` / `getDefaultCurrency` (get_single ×3, `ifEmpty:"stop"`) — หาสมุดรายวัน "ทั่วไป (General Journal)" (`6993214d-f358-424d-a971-93009d4ce40d`), ประเภทใบสำคัญ "ทั่วไป (General/JV)" (`fab0ca48-05c8-4045-be4f-c0ed0d80a3ab`), สกุลเงิน THB (`b9d9d4ff-fc96-4636-b0d0-203a34c8342a`) — **ทั้งสามค่าไม่ได้ระบุไว้ในสเปกเดิม ต้อง query หาจากข้อมูลจริงเอง** เพราะ `journal`/`voucher_type`/`currency` เป็นฟิลด์ required บน `AC_VOUCHER`
12. `createVoucher` (add_record, `AC_VOUCHER`) — `description` = template "ปิดบัญชีสิ้นปี {fiscal_year}" · `voucher_date` = nowTime · `journal`/`voucher_type`/`currency` = จาก node 11 · `period` = trigger.rowid (ผูกกับงวด 13 เอง) · `voucher_no` = template `"CLOSE-{fiscal_year}"` · `voucher_status` = Draft (`3536165d-460c-4942-8bec-6f381209d8da`) · `source_doc_type` = AC_CLOSE (`87c9789e-d222-411d-ae5d-51f2d29b7419`) · `source_module` = **"ปิดงวด"** (`9f91b297-8939-4d23-8d72-168fd9cfd792` — reuse, ดูหมายเหตุด้านบน)
13. `getREAccount` (get_single, `AC_COA` rowid eq `47ab3ece-d0a1-4f83-a5c7-060036b0919b`) — บัญชีกำไรสะสม (Retained Earnings) เจาะจง
14. `createClosingEntry` (add_record, `AC_CLOSING_ENTRY`) — `biz_closing_entry_no` = template · `fiscal_year` = trigger.fiscal_year · `period` = trigger.rowid · `re_account` = node 13 · `total_revenue`/`total_expense`/`net_result` = node 7/8/9 · `voucher` = node 12 · `status` = ร่าง (`cdaf130d-…`)
15. `getBSAccountsAsset` (get_multiple, `AC_COA`) — filter `is_postable` eq 1 **AND** `account_type` eq Asset (`eb611620-…`)
16. `openingSubProcessAsset` (sub_process `sequential_each`, target=node 15) — ดู inner flow ด้านล่าง
17. `getBSAccountsLiability` / `openingSubProcessLiability` — เหมือนข้อ 15-16 แต่ `account_type` eq Liability (`87120a74-…`)
18. `getBSAccountsEquity` / `openingSubProcessEquity` — เหมือนข้อ 15-16 แต่ `account_type` eq Equity (`1e26342f-…`)
19. `getAllPeriodsThisYear` (get_multiple, `AC_PERIOD`) — filter `fiscal_year` eq trigger.fiscal_year (**ทุกงวด ไม่กรองสถานะ**)
20. `lockSubProcess` (sub_process `sequential_each`, target=node 19) — ดู inner flow ด้านล่าง
21. `notifySuccess` (send_internal_notice ถึง role AC-R1/AC-R2/AC-R3) — สรุปรายได้รวม/ค่าใช้จ่ายรวม/กำไรขาดทุนสุทธิ/ปีถัดไป/เลขที่ใบสำคัญ

> 🔑 **ทำไมใช้ 3 คู่ (`get_multiple`+`sub_process`) แยก Asset/Liability/Equity แทนที่จะใช้ `get_multiple` ตัวเดียวกับ `account_type in [Asset,Liability,Equity]`** — เป็นการป้องกันกับดักข้อ 28 (`op:"in"` ตัดเหลือค่าแรก) ไว้ล่วงหน้า แม้ `account_type` จะเป็น Dropdown (ไม่ใช่ Relation) ก็ตาม เพื่อความปลอดภัยและสม่ำเสมอกับ pattern ที่ใช้กับ AC_GL

**Inner sub-process 1-3 — "ยกยอดบัญชี{สินทรัพย์/หนี้สิน/ส่วนของเจ้าของ}" (โครงเดียวกันทั้ง 3 ตัว, ต่างแค่ target ที่ parent ส่งเข้ามา):**

- processId: Asset `6a90f0f3fdab77a41c5b5c77` · Liability `6a90f11afdab77a41c5b6042` · Equity `6a90f139fdab77a41c5b63c9` (ทั้ง 3 ตั้งใจปล่อยเป็น **draft ถาวร** ตามกับดักข้อ 24 — ห้าม publish)
- `sub_process.config.input` ส่ง 3 ค่าเข้ามาจาก parent ทุกครั้งที่เรียก: `closingFiscalYear` (=ปีที่กำลังปิด), `nextFiscalYear` (=ปีถัดไป จาก `computeNextYear`), `closingVoucherRowId` (=rowid ใบสำคัญปิดบัญชีที่เพิ่งสร้าง) — ประกาศรับค่าฝั่ง child ผ่าน `process.start.inputFields` แล้วอ้างอิงข้างในด้วย virtual node `process_variable` (nodeId คงที่ `6038a1cbf18158039fb40e68` ในทุก inner flow)
- `sub_trigger` (virtual node) = เรคคอร์ด `AC_COA` ที่กำลังวนถึงในรอบนี้ (มาจาก `getBSAccounts{Asset/Liability/Equity}` ของ parent)
- `sumAcctDebit` (rollup sum, `AC_GL.debit_base`) — filter `account` eq `sub_trigger.rowid` **AND** `fiscal_year` **lte** `closingFiscalYear` (process variable) — **สะสมทุกปีตั้งแต่ต้นจนถึงปีที่ปิด ไม่ใช่แค่ปีนี้ปีเดียว** (เพราะบัญชีงบดุลไม่ปิดยอดทุกปีเหมือนบัญชีงบกำไรขาดทุน)
- `sumAcctCredit` (rollup sum, `AC_GL.credit_base`) — filter เดียวกัน
- `createOpening` (add_record, `AC_OPENING`) — `biz_opening_no` = template อ้าง `nextFiscalYear`+`sub_trigger.rowid` · `biz_opening_fiscal_year` = `nextFiscalYear` · `biz_opening_account` = `sub_trigger.rowid` · `biz_opening_debit` = `sumAcctDebit` · `biz_opening_credit` = `sumAcctCredit` · `biz_opening_source` = "ยกยอดจากปีก่อน" (`cdeaeb5c-5923-4c8e-8b99-ab90949ee441`) · `biz_opening_voucher` = `closingVoucherRowId` (process variable, เขียนผ่าน `kind:"field"`+`fieldId:"rowid"` — **ทดสอบยืนยันว่า pattern "เขียน Relation ด้วยค่าจาก process variable ข้าง sub_process" ใช้งานได้จริง ไม่ใช่ pattern ที่ล้มเหลว**)
> 🔑 **การตัดสินใจออกแบบที่ตั้งใจ: เก็บยอดยกมาเป็น debit/credit แยกกัน (gross) ไม่ netted เป็นยอดเดียว** — แม้ในทางบัญชีบัญชีหนึ่งจะมียอดคงเหลือสุทธิด้านเดียว (debit หรือ credit) แต่การเก็บทั้งสองด้านไว้ทำให้ตรวจสอบย้อนหลังได้ง่ายกว่า (เห็น gross debit/credit ทั้งคู่ ไม่ต้องเดาว่าเดิมสุทธิมาจากด้านไหน) และไม่ต้องมี logic แยกเงื่อนไข "ถ้า debit>credit ใส่ debit ถ้าไม่งั้นใส่ credit" ในตัว workflow

**Inner sub-process 4 — "ล็อกงวด" (`lockSubProcess`, processId `6a90f14cfdab77a41c5b66f7`, draft ถาวร):**

- `sub_trigger` = เรคคอร์ด `AC_PERIOD` ที่กำลังวนถึง (จาก `getAllPeriodsThisYear` ของ parent — ทุกงวดของปีนี้ ไม่ว่าสถานะอะไร)
- `updatePeriodLocked` (update_record) — `period_status` = **Permanently locked** (`38392e32-7c09-4339-a9b4-81a9f53eba0a`) · `closed_by` = systemField `triggeraid` · `closed_at` = systemField `nowTime`

**ผลทดสอบ (28 ส.ค. 2569 — สร้าง fixture ปีบัญชีสังเคราะห์ 9999 แยกจากข้อมูลจริง 2569 ทั้งหมด, 13 งวด Soft-closed + 13 แถว AC_GL + 1 ใบสำคัญทิ้ง):**

- **เส้นทางปฏิเสธ (มีงวดเปิดค้าง):** ตั้งงวดหนึ่งในปี 9999 กลับเป็น Open แล้ว `update_record(biz_close_year_flag=1, triggerWorkflow:true)` บนงวด 13 → `notifyNotReady` ยิงถึงผู้กด, `clearFlag1` รีเซ็ต flag กลับ 0, ไม่มีใบสำคัญ/closing entry/opening ใด ๆ ถูกสร้าง — ยืนยัน `_updatedBy=user-workflow`
- **เส้นทางปิดสำเร็จ (ทุกงวดปิดหมด):** คืนทุกงวดเป็น Soft-closed แล้วยิงซ้ำ → คำนวณได้ **รายได้รวม = 165,000.00 · ค่าใช้จ่ายรวม = 52,500.00 · กำไรสุทธิ = 112,500.00** ตรงกับยอดที่คำนวณมือ (sum ตรงจาก GL fixture) เป๊ะทุกบาท · สร้าง 1 `AC_VOUCHER` + 1 `AC_CLOSING_ENTRY` ถูกต้อง · สร้าง **27 `AC_OPENING`** (16 สินทรัพย์ + 9 หนี้สิน + 2 ส่วนของเจ้าของ ตรงกับจำนวนบัญชีที่ `is_postable=1` ในแต่ละหมวดของผังบัญชีจริง) ยอด debit/credit gross ตรงกับยอดสะสมใน GL fixture ทุกบัญชี · ทั้ง 13 งวดถูกอัปเดตเป็น **ปิดถาวร** ถูกต้อง (รวมงวด 13 เอง) · `notifySuccess` ยิงถึง AC-R1/R2/R3 พร้อมตัวเลขถูกต้อง
- ล้างข้อมูลทดสอบทั้งหมดหลังยืนยันผล (27 AC_OPENING, 1 AC_CLOSING_ENTRY, 2 AC_VOUCHER รวมใบทดสอบ, 13 AC_GL, 13 AC_PERIOD) — ยืนยันลบครบทุกตารางกลับสู่สถานะก่อนทดสอบ

**Known gaps (ยังไม่อยู่ในขอบเขตที่สร้าง — ระบุไว้ชัดเจนเพื่อให้ทีมมนุษย์ตรวจสอบต่อ):**

- 🔴 **ไม่มี `AC_VOUCHER_LINE` (บรรทัดเดบิต/เครดิตคู่กัน) ถูกสร้างอัตโนมัติสำหรับใบสำคัญปิดบัญชี** — `createVoucher` สร้างแค่หัวใบสำคัญ (draft summary record ที่มี `total_revenue`/`total_expense`/`net_result` เก็บอยู่ที่ `AC_CLOSING_ENTRY` ที่ผูกกัน) **ไม่ใช่ double-entry journal ที่สมดุลในตัวเอง** — ถ้าต้องการใบสำคัญปิดบัญชีที่ผ่านรายการเข้า GL ได้จริง (ปิดบัญชีรายได้/ค่าใช้จ่ายเป็น 0 แล้วโอนเข้ากำไรสะสม) ต้องสร้าง `AC_VOUCHER_LINE` เพิ่มเติมเอง (1 บรรทัดต่อบัญชีรายได้/ค่าใช้จ่ายที่มียอด + 1 บรรทัดกำไรสะสม) — **ไม่ได้อยู่ในสโคปของงานนี้ตามที่ระบุไว้**
- ⚠️ **Custom Action button "ปิดปีและยกยอด" ยังไม่ verify Scope ผ่าน Browser** (สร้างหลังยืนยัน workflow logic ผ่านการทดสอบตรงด้วย `update_record` แล้ว — เหมือนแพทเทิร์นของปุ่มอื่นทุกปุ่มในโปรเจกต์นี้ ดูกับดักข้อ 20)
- ⚠️ **`AC_OPENING` ที่มียอด 0 ทั้งสองด้าน (debit=0, credit=0) แสดงเป็นค่าว่างแทนที่จะเป็น 0.00 บนหน้าจอ** — เกิดจาก inner rollup (`sumAcctDebit`/`sumAcctCredit`) ไม่ได้ตั้ง `nullZero:true` (ค่าเริ่มต้น `false`) ⇒ บัญชีที่ไม่เคยมีการเคลื่อนไหวเลยจะได้ `null` แทน `0` — เป็นปัญหาความสวยงามของการแสดงผลเท่านั้น ไม่กระทบความถูกต้องของข้อมูล (คำนวณ/เปรียบเทียบ null เป็น 0 ได้ปกติ) — ถ้าต้องการแก้ ให้ตั้ง `nullZero:true` ในทั้งสอง rollup ของ inner flow ทั้ง 3 ตัว

---

### WF-AC-12 แจ้งเตือนความผิดปกติทางบัญชี `6a9032d3fdab77a41c56420b` — ✅ **สร้าง publish และทดสอบผ่านครบ 27 ส.ค. 2569 (รอบเย็น ต่อ) — publishVersion 1**

- **ชนิด / Surface:** `schedule` — `loopType:"workday"` (จันทร์–ศุกร์ 08:00 ตาม cron ที่เซิร์ฟเวอร์ auto-gen `0 0 8 ? * MON-FRI`) · **MCP ล้วน 33 nodes** · ⚠️ ช่อง `startTime` ของ trigger ไม่มีพารามิเตอร์ timezone ให้ตั้ง — ใช้ค่า `08:00` ตรง ๆ โดยยังไม่ยืนยันว่าตรงกับ 08:00 น. เวลาไทยจริงหรือคลาดเคลื่อนตามโซนเวลาเซิร์ฟเวอร์ (ดู NFR-07)
- **โครงสร้าง (สำคัญ — ต่างจาก WF-AC-08/WF-AC-10 ที่เป็น chain เดียว):** `trigger` → `compute0` (ค่าคงที่ `1+1` สำหรับใช้เป็นเงื่อนไข "จริงเสมอ") → `branch_all` (**branchType:"condition", mode:"allMatch"**, 6 paths `path1`…`path6` ทุก path filter เดียวกันคือ `compute0.number_fx_id > 0`) ⇒ **ทั้ง 6 path ทำงานขนานกันจริงทุกครั้งที่ยิง** (ไม่ใช่ mutually exclusive แบบ `firstMatch`) แต่ละ path เป็น chain ของตัวเองครบ get→rollup(count)→branch(ผลมากกว่า 0 หรือไม่)→notify:
  1. **path1 (SLA อนุมัติ):** `cutoff1`(compute dateOffset -1d) → `get1`(get_multiple AC_VOUCHER filter `voucher_status`=รออนุมัติ `982090bd-…` AND `utime` lt cutoff1) → `rollup1`(count) → `branch1`(`hasOverdue1`/`none1`) → `notify1`→AC-R2
  2. **path2 (ไม่สมดุลค้างนาน):** `cutoff3`(-3d) → `get2`(AC_VOUCHER filter `voucher_status`=ร่าง `3536165d-…` AND `balance_diff` ne 0 AND `utime` lt cutoff3) → `rollup2` → `branch2` → `notify2`→AC-R1
  3. **path3 (เจ้าหนี้เลยกำหนด):** `get3`(AC_AP filter `due_date` lt `{systemField nowTime}` AND `biz_ap_outstanding` gt 0) → `rollup3` → `branch3` → `notify3`→AC-R1+AC-R2
  4. **path4 (ภาษีซื้อรอใบกำกับเกิน 60 วัน):** `cutoff60`(-60d) → `get4`(AC_VAT_DOC filter `biz_vd_claim_status`=รอใบกำกับภาษี `d4514d7d-…` AND `tax_point_date` lt cutoff60) → `rollup4` → `branch4` → `notify4`→AC-R1
  5. **path5 (movement_seq ขาดหาย):** `get5a`(get_single AC_GL sort `movement_seq` desc, `ifEmpty:"continue"`) → `get5b`(get_multiple AC_GL ไม่มี filter limit 50000 — ใช้แทน rollup แบบ worksheet-report เพราะ `method:"count"` ไม่รับ `worksheetId` เดี่ยว ๆ ต้องมี `target`) → `rollup5b`(count target=get5b) → `compute5`(expression `$get5a-movement_seq$-$rollup5b-number_fx_id$`, `nullZero:true`) → `branch5`(≠0 หรือไม่) → `notify5`→AC-R5
  6. **path6 (ใกล้กำหนดยื่นแบบภาษี):** `code6`(node ชนิด `code`, JS คำนวณ `isCheckDay`=วันนี้เป็นวันที่ 10 หรือ 13 หรือไม่ + `prevMonth`=เดือนก่อนหน้ารูปแบบ `YYYY-MM`) → `branch6a`(`checkDay`/`notCheckDay`) → ใน `checkDay`: `get6`(AC_TAX_FILING filter `tax_month` eq code6.prevMonth AND `biz_tf_filing_status` not_in [Filed, ชำระแล้ว, ยื่นเพิ่มเติมแล้ว]) → `rollup6` → `branch6b` → `notify6`→AC-R2+AC-R3
- **Gap:** ไม่มีแล้ว — ปิดครบ 100% (ตัดการแจ้งเป็นรายบุคคล "ผู้จัดทำ/ผู้อนุมัติ" ต่อ record ออก ใช้แจ้งสรุปเป็น role แทนเพื่อความง่าย — ดู pitfall ด้านล่าง) · ยังไม่ได้เพิ่มฟิลด์ `last_alert_at` กันแจ้งซ้ำ (ยกไว้เป็นงานปรับปรุงภายหลัง เพราะ workflow นี้ยิงทุกวัน ไม่มีกลไก dedupe ในตัว)
- **🔴 ข้อจำกัดใหม่ที่พบระหว่างสร้าง (ไม่ใช่บั๊ก แต่เป็นข้อจำกัดสถาปัตยกรรมที่ต้องรู้ก่อนออกแบบ workflow ที่มีหลายสาขาอิสระ) — ดูกับดักข้อ 27/28 ใน `04-CLAUDE-memory.md`:**
  1. `batch_create_process_nodes` **ไม่รองรับให้หลาย node ชี้ `prevNode`ไปโหนดเดียวกันในคำขอเดียว** (แม้แต่ node แรกที่ต่อจาก trigger) — error `"暂不支持一次批量请求中多个节点接在同一个上级节点后"` ⇒ วิธีเดียวที่จะทำให้ trigger มี "ลูก" หลายสาขาคือใช้ **`branch` node เป็นตัวกลางเสมอ** (`mode:"allMatch"` ถ้าต้องการให้ทุกสาขาทำงานพร้อมกันไม่ผูกเงื่อนไขกัน — ใช้เงื่อนไข "จริงเสมอ" หลอก ๆ อย่าง `compute` ค่าคงที่ `>0` ในทุก path ได้)
  2. โหนดแรกในแต่ละ branch path (ที่ตั้ง `parentNode` แต่ไม่ตั้ง `prevNode`) **ถ้าเป็นโหนดตัวแรกในคำขอ batch นั้น ระบบจะ default `prevNode` เป็น "ต่อจาก trigger" ไม่ใช่ "ต่อจาก path"** ⇒ ต้องระบุ `prevNode` ชี้ไปที่โหนดของสาขา (เช่น `branch_all`) อย่างชัดเจนเสมอสำหรับโหนดแรกของแต่ละ path เมื่อมันไม่ใช่โหนดแรกในอาร์เรย์ของ batch call
  3. `rollup` method `count` **ต้องมี `config.target` เสมอ แม้ต้องการนับทั้งตาราง** (เอกสาร schema บอกว่า `worksheetId` อย่างเดียวก็พอสำหรับ count แต่จริง ๆ ยิงแล้ว error `config.target: 必填`) ⇒ ถ้าต้องการนับทั้งตาราง ต้องสร้าง `get_multiple` (ไม่มี filter, `limit` สูง) ก่อน แล้วให้ `rollup` อ้าง `target:{kind:'record',node:{...get_multiple...}}` แทน (ใช้ได้ปกติกับ `sum`/`avg`/`max`/`min` ที่ยังใช้ `worksheetId`+`fieldId` ตรง ๆ ได้ตามเอกสาร)
  4. **ยืนยันความสามารถใหม่ (ใช้งานได้จริง ไม่ใช่ปัญหา):** node ชนิด `code` ประกาศ `outputs` (name+type) แล้วโหนดถัดไปอ้างอิงผลลัพธ์ผ่าน `{kind:'field', node:{nodeAlias:'code6'}, fieldId:'<output name>'}` ได้ตรง ๆ — ใช้แก้ปัญหา logic ที่ node ชนิดอื่นทำไม่ได้ (เช่น หา "วันที่ของเดือนก่อนหน้าในรูปแบบ YYYY-MM" หรือเช็ค "วันนี้ตรงกับวันที่ 10 หรือ 13 หรือไม่") ได้ผลลัพธ์ทั้ง boolean และ string ใช้ต่อในเงื่อนไข branch และ filter ของ get_multiple ได้ปกติ
- **ผลทดสอบ (27 ส.ค. 2569 — ข้อมูลจริงตอนทดสอบยังไม่มี anomaly จึงเป็น baseline "ไม่มีรายการผิดปกติ" ทั้ง 6 ข้อ ยังไม่ได้ปั้นข้อมูลให้ชนเงื่อนไขจริงสักข้อ):** กด "Execute Now" ผ่าน Browser → Workflow History แสดง **"Done"** ครบทุก node ไม่มี error เลย — `branch_all` เข้าทั้ง 6 path พร้อมกันจริงตามที่ออกแบบ (ยืนยัน `mode:"allMatch"` ทำงานถูกต้อง) · path1-4 ทั้งหมดตกที่ path ย่อย "ไม่มี" (none) ตรงกับข้อมูลจริงที่ยังไม่มีเอกสารค้าง · path5: `get5a` ได้ **Skip** (AC_GL ว่างเปล่าจริงตอนทดสอบ) แต่ `compute5` จัดการค่าว่างด้วย `nullZero:true` ได้ถูกต้อง (0−0=0) ⇒ ตกที่ "ไม่ขาด" (none5) ถูกต้องตามข้อมูลจริง · path6: `code6` คำนวณถูกต้องว่าวันที่ทดสอบ (27 ส.ค.) ไม่ตรงวันที่ 10/13 ⇒ เข้า `notCheckDay` จบสายโดยไม่ยิง `get6`/`notify6` ตรงตาม logic ที่ตั้งใจ ⇒ **ยืนยันว่าโครงสร้างสาขาคู่ขนาน ตรรกะเงื่อนไข และ node ใหม่ (code, allMatch branch, rollup-via-get_multiple) ทำงานถูกต้องครบทุกจุดที่ตรวจสอบได้จากข้อมูลปัจจุบัน** · ⬜ **ยังไม่ได้ทดสอบเคส "พบความผิดปกติจริง" (notify ยิงจริง) สักข้อ** เพราะข้อมูลปัจจุบันสะอาดเกินไป — ต้องปั้น test fixture ที่ชนแต่ละเงื่อนไขในรอบถัดไปถ้าต้องการความมั่นใจเพิ่ม แต่ DoD ของงานนี้ ("Workflow History เห็นการยิงจริง") ผ่านแล้ว
- **Pitfall ที่ปรับจาก design เดิม:** ตัดการแจ้งเตือนแบบ per-record ("ผู้จัดทำ"/"ผู้อนุมัติ" ของแต่ละใบ) ออก เปลี่ยนเป็น**แจ้งสรุปจำนวนที่พบไปที่ role ที่เกี่ยวข้องแทน** (เช่น "พบใบสำคัญค้างอนุมัติ N ใบ" ไปที่ role AC-R2 แทนที่จะไล่แจ้งทีละคนตามฟิลด์ผู้อนุมัติของแต่ละใบ) เพื่อลดความซับซ้อนของ node graph ระดับที่ยังจัดการได้ผ่าน MCP ล้วน หากต้องการแจ้งรายบุคคลจริงในอนาคต ต้องเปลี่ยนแต่ละ path จาก `rollup(count)`+`branch` เป็น `sub_process`(`sequential_each` ต่อ get_multiple) ที่ส่ง `send_internal_notice` ต่อแถวแทน
- **กันแจ้งซ้ำ (ยังไม่ทำ):** เพิ่มฟิลด์ 🆕 `last_alert_at` (DateTime) บนตารางที่ถูกแจ้ง แล้วเช็กก่อนส่งว่าเกิน 24 ชั่วโมงแล้ว — ยกไว้เป็นงานปรับปรุงภายหลัง เนื่องจาก schedule นี้ยิงทุกวันทำการ ถ้าเงื่อนไขยังไม่หายจะแจ้งซ้ำทุกวัน

---

### WF-AC-13 รับเอกสารจากการสแกน `<TBD>` ⬜

- **ชนิด / Surface:** `worksheet_event` (create) บน `ac_ap` เมื่อ `scan_file` 🆕 ไม่ว่าง · **Browser** (ใช้ AI node)
- **Nodes:** Trigger → Branch `source_module` = Scan `add7f979-fa25-4dda-8a1d-6ca4de96c53d` → **AI node (OCR/สกัดข้อมูล)** → Update Record เติม `partner`, `invoice_no`, `invoice_date`, ยอดเงิน พร้อม `extraction_confidence` 🆕 → **Query worksheet** `ac_ap` filter `dup_key` เท่ากัน → Branch: พบซ้ำ → Update `duplicate_justification` = "" + Notification เตือน (BR-22 / **TC-09**) → Branch: `extraction_confidence` < 0.8 → Update `confirmed_flag` = 0 + Notification ให้ผู้ใช้ยืนยัน
- **กฎที่บังคับด้วย Business Rule ไม่ใช่ workflow:** `confirmed_flag` ≠ 1 และ `extraction_confidence` < 0.8 → **Block save เมื่อพยายามเปลี่ยน `ap_status` เป็น Pending approval** (บังคับ **TC-27**)
- **Pitfall:** AI เสนอค่าได้เท่านั้น ห้ามผ่านรายการเอง (`TILSNA-SDS-AC-001.md` §9.1) · ต้องบันทึกว่าใครยืนยันและเมื่อไร

---

### WF-AC-14 รอบเตรียมจ่าย `<TBD>`

- **ชนิด / Surface:** `worksheet_event` (update) บน `ac_pay_req` · **MCP**
- **Trigger Field:** `req_status` 🆕
- **Nodes**
  1. Trigger · 2. **Branch** `req_status` = อนุมัติ **AND** `paid_flag` 🆕 ≠ 1
  3. **Update Record** `paid_flag` = 1
  4. **Get associated records** — `documents` `6a8677b18b36df988c176cb5` (→ `ac_ap`)
  5. **Create Record** `ac_pay` — `doc_date` `6a8677c38b36df988c176cde` = วันนี้ · `pay_req` `6a8677c38b36df988c176ce4` = trigger · `currency` `…ce1` · `prepared_by` `…ce0` = trigger › `requester` `6a8677b18b36df988c176cb3`
  6. **Loop → Create Record** `ac_pay_line` ต่อ 1 เอกสาร — `pay` `6a8677d71049edca1eed06fc` · `ap` `…06fe` · `partner` `…0700` · `doc_amount` `…0702` = ap › `outstanding` 🆕 · `wht_amount` `…0703` = ap › `wht_amount` 🆕 · `net_amount` `…0704` = doc − wht
  7. **Function calculation** — `total_gross` / `total_wht` / `total_net` 🆕 บน `ac_pay`
  8. **Branch** — `AC_DOC_SETTING.wht_timing` = At payment `998bd1a6-…` → **จัดกลุ่มตามคู่ค้า + ประเภทเงินได้ → Create Record `ac_wht`** (ตามขั้นตอนใน WF-AC-06)
  9. **Update Record** — `pay_status` 🆕 = รออนุมัติ → เข้าสาย WF-AC-01 (เวอร์ชัน AC_PAY)
  10. หลังอนุมัติ → **Create Record** `ac_voucher` (ยังไม่ตัดชำระ — ตัดจริงเมื่อการเงินตอบกลับผ่าน WF-AC-04)
- **แบบ schedule เสริม:** trigger `schedule` ทุกวันศุกร์ 09:00 (+07:00) รวบเจ้าหนี้ที่ `due_date` ภายใน 7 วัน แล้วสร้างคำขอเบิกอัตโนมัติ (เปิดใช้เมื่อผู้ใช้ยืนยันรอบการจ่าย 🔴)
- **DoD:** TC-23 ผ่าน

---

### WF-AC-15 ลงทะเบียนและใช้เครดิตภาษีซื้อ `<TBD>` 🔴 **หัวใจของ FR-10**

- **ชนิด / Surface:** `worksheet_event` (create + update) บน `ac_vat_doc` · **MCP**
- **Trigger Field:** `tax_invoice_no` `6a8677f933560633b8cda341`
- **ข้อกำหนดก่อนสร้าง:** 🔴 ต้องมี `vat_side`, `claim_status`, `accrual_period`, `deferred_flag`, `transfer_voucher` ก่อน

**Nodes**

1. **Trigger by worksheet** — `ac_vat_doc` · create + update · Trigger Field = `tax_invoice_no`
2. **Branch** — `vat_side` 🆕 equals Input `fa5f09e9-5ee1-4368-a4be-01580459b983` · path `overrule` → Terminate (ภาษีขายไปสาย WF-AC-05)
3. **Branch** — `claim_status` 🆕 equals Claimed `79e3b7e4-…` หรือ Filed `023498c0-…` → **Terminate** (กันใช้เครดิตซ้ำชั้นที่หนึ่ง — ชั้นที่สองคือ unique index IX-10.1 · บังคับ **TC-20**)
4. **Branch** — `tax_invoice_no` is empty **หรือ** `tax_invoice_date` `6a8677f933560633b8cda342` is empty
   - path `pass` → **Update Record** `claim_status` = Awaiting tax invoice `d4514d7d-…` · `deferred_flag` = 1 → **Terminate**
5. **Update Record** — `claim_status` = Tax invoice received `73da6436-e9f7-48bf-826b-96841a7d6419`
6. **Get Multiple Records** — `ac_period` `6a8434d5055f2288c5b6d4b8` filter `date_from` `6a8434d58b36df988c16ed68` `lte` `tax_point_date` `6a8677f933560633b8cda343` **AND** `date_to` `…ed69` `gte` `tax_point_date`
7. **Branch** — node 6 › `tax_period_status` `6a851f70055f2288c5b73ee0` equals Open `d41e3a2e-684b-4533-9913-09a04302626e`
   - path `pass` → **Update Record** `claim_period` `6a8677f933560633b8cda348` = node 6
   - path `overrule` → **Get Multiple Records** `ac_period` filter `tax_period_status` = Open **AND** `date_from` > node 6 › `date_from` เรียงจากน้อยไปมาก เอาแถวแรก → **Update Record** `claim_period` = แถวนั้น → **Send Internal Notification** บันทึกเหตุผลให้ AC-R2 (บังคับ **TC-21**)
8. **Branch** — `deferred_flag` equals 1
   - path `pass` → **Create Record** `ac_voucher` จาก `ac_posting_rule` event `VAT_TRANSFER` `7a9a4edb-94dd-4d10-999d-3e6569358f85` (เดบิต ภาษีซื้อ / เครดิต ภาษีซื้อรอเรียกคืน) → **Update Record** `transfer_voucher` 🆕 = ใบสำคัญที่สร้าง · `deferred_flag` = 0
9. **Update Record** — `claim_status` = **Claimed** `79e3b7e4-a950-45ed-be9d-a54c81afb880`

- **Test recipe (ครอบ TC-19 / TC-20 / TC-21)**
  - **TC-19:** สร้าง `ac_vat_doc` ที่ไม่มี `tax_invoice_no` (งวด ส.ค.) → ต้องเป็น Awaiting tax invoice + `deferred_flag`=1 · จากนั้น `update_record` เติม `tax_invoice_no` + `tax_invoice_date` = 15 ต.ค. → `claim_period` ต้องเป็นงวด ต.ค. และเกิดใบสำคัญโอน
  - **TC-20:** `update_record` เติม `tax_invoice_no` เดิมซ้ำอีกครั้ง → node 3 Terminate · และ `create_record` ที่มี (vat_side, partner, tax_invoice_no, tax_invoice_date) ซ้ำ → **ต้องถูกปฏิเสธโดย unique index**
  - **TC-21:** ตั้ง `tax_period_status` ของงวด ต.ค. เป็น Filed แล้วยิงใหม่ → `claim_period` ต้องกลายเป็นงวด พ.ย.
  - คาด: log `user-workflow` ทุกครั้ง · reset: ลบ record ทดสอบ + ใบสำคัญโอน

---

### WF-AC-16 เตรียมแบบ ภ.พ.30 `<TBD>`

- **ชนิด / Surface:** `schedule` — วันที่ 1 ของทุกเดือน 06:00 (+07:00) · **MCP**
- **Nodes**
  1. Trigger by time
  2. **Get Single Record** `ac_period` ของเดือนก่อน
  3. **Branch** — `tax_period_status` = Open `d41e3a2e-…` · ถ้าเป็น Filed → สร้างเป็น **ยื่นเพิ่มเติม** แทน (`filing_type` 🆕 = Additional `dfa22f2b-4e58-4172-aaef-965336e9949f` + `original_filing` `6a8678261049edca1eed0726` ชี้ฉบับเดิม)
  4. **Get Multiple Records** `ac_vat_doc` filter `claim_period` = งวดนั้น **AND** `vat_side` = Output → **Function calculation** `output_vat` 🆕 = Σ(`vat_amount` × `sign`)
  5. **Get Multiple Records** `ac_vat_doc` filter `claim_period` = งวดนั้น **AND** `vat_side` = Input **AND** `claim_status` = Claimed → `input_vat` 🆕 = Σ(`vat_amount` × `sign`)
  6. **Function calculation** — `net_payable` 🆕 = `output_vat` − `input_vat` · `doc_count` 🆕 = จำนวนเอกสาร
  7. **Create Record** `ac_tax_filing` — `form_type` 🆕 = `P.P.30` (key `d6c591cf-32c0-43d0-916d-803266f5e121` — **อ้าง key ไม่ใช่ label**) · `period` 🆕 = งวด · `tax_month` `6a8677c733560633b8cda327` = `"YYYY-MM"` · `filing_status` 🆕 = Draft `fcd7fa27-…`
  8. **Loop → Update Record** `ac_vat_doc.filing` `6a8677f933560633b8cda34a` = แบบยื่นที่สร้าง (บังคับ **TC-22** — เอกสารถูกกำกับให้ฉบับที่ถูกต้อง)
  9. **Update Record** — `filing_status` = รออนุมัติ → เข้าสายอนุมัติ AC-R2 → AC-R3
  10. **หลังยื่น** (ปุ่ม "ยื่นแบบภาษี" เขียน `filing_status` = Filed `746ab42c-…`) → **Update Record** `ac_period.tax_period_status` = Filed `fa108e9e-…` · และ `ac_vat_doc.claim_status` = Filed `023498c0-…` ทุกฉบับที่ผูก
- **DoD:** ยอดในแบบกระทบกับ AC_GL ได้ · TC-22 ผ่าน

---

### WF-AC-17 เตรียมแบบ ภ.ง.ด. และไฟล์นำส่ง `<TBD>`

- **ชนิด / Surface:** `schedule` — วันที่ 1 ของทุกเดือน 06:30 (+07:00) · **MCP** (ยกเว้นการสร้างไฟล์นำส่งซึ่งใช้ node นอก MCP → ⚠️ ถ้าต้องสร้างไฟล์ ให้ทำทั้ง workflow ใน **Browser**)
- **Nodes:** Trigger by time → Get Multiple Records `ac_wht` `6a8677f1055f2288c5b77d1d` filter `pay_date` `…d2b` อยู่ในเดือนก่อน **AND** `filing` `…d31` is empty → **จัดกลุ่มตาม `form_type` 🆕** (`P.N.D.3` key `86d28c16-c735-403b-beb1-1573990188d6` = บุคคลธรรมดา · `P.N.D.53` key `08e5c9c1-bcd7-4e28-9a08-ed0c028dc21b` = นิติบุคคล) → Create Record `ac_tax_filing` หนึ่งฉบับต่อแบบ → Loop Update `ac_wht.filing` → Function calculation `wht_total` 🆕 → เข้าสายอนุมัติ
- **ไฟล์นำส่ง:** node **Print Record / Send API Request** (Browser) สร้างไฟล์ตามรูปแบบกรมสรรพากร แล้วแนบลง `export_file` 🆕
- **DoD:** ยอดรวมใบรับรองในเดือน = `wht_total` = ยอดในบัญชีภาษีหัก ณ ที่จ่ายค้างจ่ายใน AC_GL

---

### WF-AC-18 แปลงเอกสารขายตามห่วงโซ่ `<TBD>` ⬜

- **ชนิด / Surface:** ยิงจากปุ่ม (`triggerWorkflow`) · **MCP** · ขึ้นกับ FR-12
- **การแปลงที่รองรับ:** ใบแจ้งหนี้ → ใบกำกับภาษี · ใบกำกับภาษี → ใบเสร็จ · หลายใบกำกับ → ใบเสร็จรวม
- **Nodes:** Trigger by Custom Action → Branch ตรวจสถานะต้นทาง → **Function calculation** ยอดคงเหลือที่ยังแปลงได้ = `total_amount` − `converted_amount` → Branch: ยอดที่ขอแปลง > คงเหลือ → Terminate + Notification → Create Record เอกสารปลายทาง + บรรทัด → **Update Record** `converted_amount` บนต้นทาง → Branch: `converted_amount` = `total_amount` → สถานะต้นทาง = แปลงครบแล้ว
- **DoD:** TC-25 — แปลงบางส่วนได้ และยกเลิกต้นทางไม่ได้ขณะปลายทางยังมีผล (ตัวบังคับคือ **BR-12.1 Business Rule** ไม่ใช่ workflow)

---

### WF-AC-19 ออกใบลดหนี้ / ใบเพิ่มหนี้ `<TBD>` ⬜

- **ชนิด / Surface:** `worksheet_event` (update) บน `ac_cn` / `ac_dn` · **MCP** · ขึ้นกับ FR-12
- **Nodes:** Trigger Field = `cn_status` → Branch = อนุมัติ → Get Single Record ใบกำกับต้นฉบับ → **Create Record `ac_vat_doc`** ด้วย `sign` = **−1** (ใบลดหนี้) หรือ **+1** (ใบเพิ่มหนี้) และ **`claim_period` = งวดภาษีที่ยัง Open ณ ปัจจุบัน** ไม่ใช่งวดของใบกำกับต้นฉบับ (บังคับ **TC-26**) → Create Record `ac_voucher` → Update ยอดคงเหลือของ `ac_ar`
- **Pitfall:** ห้ามแก้ `ac_vat_doc` ของใบกำกับต้นฉบับที่ `claim_status` = Filed แล้ว — ต้องสร้างรายการปรับปรุงใหม่เสมอ

---

### WF-AC-20 ผ่านรายการสมุดรายวันเงินเดือน `<TBD>` ⬜

- **ชนิด / Surface:** `webhook` · **Browser** (JSON Parsing)
- **Nodes:** Trigger by webhook → JSON Parsing → Branch idempotency (`ac_voucher.source_doc_id` `6a85fb2e055f2288c5b7775e` ซ้ำ → Terminate) → Create Record `ac_voucher` (`source_module` `6a86021833560633b8cd9fb1` = Payroll `914f5226-dc4c-4572-bd4d-18bb278414b5`) → Loop Create `ac_voucher_line` ตามที่ HRMS ส่งมา → Branch ตรวจ `balance_diff` = 0 → Update `status1` = Approved (ให้ WF-AC-02 รับช่วง) · ถ้าไม่สมดุล → Notification ถึง AC-R2 และคงสถานะ Draft
- **Pitfall:** ข้อมูลเงินเดือนเป็นข้อมูลส่วนบุคคล (NFR-02) — ห้ามใส่รายละเอียดรายบุคคลลง `description` ให้ลงเป็นยอดรวมตามบัญชี

---

### WF-AC-21 ตั้งสินทรัพย์และตัดจำหน่าย `<TBD>` ⬜

- **ชนิด / Surface:** `worksheet_event` (update) · **MCP** · ขึ้นกับ FR-13
- **สายตั้งสินทรัพย์:** trigger บน `ac_ap_line` เมื่อ `account.account_group` = Non-current asset `44aded18-d965-4ea0-a75e-71da0749081e` **AND** `ap_status` = Recognised → Create Record `ac_asset_book` (`cost` = `line_amount`, `category` จาก `item`, `life_years` = `category.default_life_years` `6a8545941049edca1eecd8b0`, `salvage_value` = cost × `default_salvage_pct` 🆕) → Notification ถึงโมดูลสินทรัพย์
- **สายตัดจำหน่าย:** trigger บน `ac_asset_disposal` เมื่อสถานะ = อนุมัติ → **Function calculation** `nbv_at_disposal` = `cost` − ค่าเสื่อมสะสม · `gain_loss` = `proceeds` − `nbv_at_disposal` → Create Record `ac_voucher` จาก `ac_posting_rule` event `DISPOSAL` `3e16e8a7-39fe-4cef-9909-5e0cefd27fc1` — **ต้องเดบิต/เครดิตทั้งราคาทุนและค่าเสื่อมสะสม** (บังคับ **TC-28**) → Update `ac_asset_book.asset_status` = Retired `45103a03-…`

---

### WF-AC-22 ปรับปรุงอัตราแลกเปลี่ยนปลายงวด `<TBD>` ⬜

- **ชนิด / Surface:** `schedule` — วันสุดท้ายของเดือน 22:00 (+07:00) · **MCP** · ขึ้นกับ A-13
- **Nodes:** Trigger by time → Get Multiple Records `ac_ap` / `ac_ar` filter `currency` ≠ สกุลเงินฐาน **AND** `outstanding` > 0 → Get Single Record `ac_fx_rate` `6a8545911049edca1eecd8a5` filter `rate_date` `6a854591055f2288c5b74210` = สิ้นงวด **AND** `rate_type` `6a85e55d9b6999a714d2a3f5` = Reference `d71fcd1b-…` → **Function calculation** ผลต่าง = `outstanding` × (อัตราสิ้นงวด − `fx_rate` เดิม) → Branch: ผลต่าง ≠ 0 → Create Record `ac_voucher` จาก `ac_posting_rule` event `FX_REVAL` `c42dbc06-05f9-4337-a321-a1d8084bf8e6`
- **Pitfall:** ห้ามเขียนทับ `fx_rate` บนเอกสารเดิม — เอกสารต้องคงอัตราที่ใช้ตอนบันทึกไว้ (BR-14) รายการปรับปรุงเป็นใบสำคัญแยกต่างหาก

---
