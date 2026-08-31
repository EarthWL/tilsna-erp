# สเปกรายโมดูล FR-01 … FR-19 — โมดูลบัญชี

> แยกออกจาก `02-BuildSpec-FRS.md` เมื่อ 31 ส.ค. 2569 (agent-ac · claim `AC/SPLIT-BUILDSPEC`)
> เหตุผล: ไฟล์แม่โต 316,054 bytes ≈ 42,366 tokens **เกินเพดาน Read 25,000 tokens ไป 1.7 เท่า** ทั้งที่ `02-BuildSpec-FRS.md` §0 ของมันสั่งให้ agent เปิดทุกครั้งก่อนแตะ object
> **เนื้อหาย้ายมาครบทุกตัวอักษร ไม่ได้ย่อหรือตัดทิ้ง** — ยืนยันด้วยการเทียบ byte-ต่อ-byte กับต้นฉบับ

---

## §2. สเปกรายโมดูล (FR-01 … FR-19)

> อ่านคู่กับ `13-ID-Registry-AC.md` §1 เสมอ · ตารางฟิลด์ทุกตารางในส่วนนี้ **คัดลอกตรงจากเซิร์ฟเวอร์** — แถวที่ขึ้นต้นด้วย 🆕 คือฟิลด์ที่ **ยังไม่มี** และต้องสร้าง

---

### FR-01 ตั้งค่าเอกสารและกฎอนุมัติ

**สถานะ: 🔶 ตารางครบ · ข้อมูลตั้งค่ายังไม่ครบ · ยังไม่มี workflow ใดใช้งานจริง**

#### FR-01.1 สมุดรายวัน — **Worksheet `AC_JOURNAL`** · ws `6a8434da33560633b8cd2efd` · alias `ac_journal` · view `6a8434da33560633b8cd2f01`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `journal_code` | `6a8434da33560633b8cd2f07` | Text (subType 0) | required · **isTitle = true** |
| `journal_name` | `6a8434da33560633b8cd2f08` | Text (subType 0) | required |
| `journal_type` | `6a8434da33560633b8cd2f09` | SingleSelect (subType 0) | required · options: `f0881dbf-d50b-4cf0-a3a7-ee4283dfe876`=General · `2da23e7e-a843-4308-b1c0-356bfc8033a3`=Purchase · `55a6baa2-6866-462a-bc14-5800e6b8dc77`=Sales · `53bf163f-b1e6-47ed-92d5-2ab8a0d8ee89`=Payment · `4414a81d-b18a-4848-b3e5-a90ba53ee923`=Receipt |
| `voucher_prefix` | `6a8434da33560633b8cd2f0a` | Text (subType 0) |  |

#### FR-01.2 ประเภทเอกสาร — **Worksheet `AC_DOC_TYPE`** · ws `6a8434dd9b6999a714d22e3d` · alias `ac_doc_type` · view `6a8434dd9b6999a714d22e41`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `doc_code` | `6a8434dd9b6999a714d22e47` | Text (subType 0) | required · **isTitle = true** |
| `doc_name` | `6a8434dd9b6999a714d22e48` | Text (subType 0) | required |
| `journal` | `6a84366133560633b8cd2f2e` | Relation (subType 1) | required · **→ ws `6a8434da33560633b8cd2efd` (AC_JOURNAL)** · sourceField `6a84366133560633b8cd2f2f` · bidirectional=false · level 2 |
| `number_rule` | `6a84366133560633b8cd2f30` | Relation (subType 1) | **→ ws `6a8434ea8b36df988c16ed84` (AC_DOC_NUMBER_RULE)** · sourceField `6a84366133560633b8cd2f31` · bidirectional=false · level 2 |
| `approval_rule` | `6a84366133560633b8cd2f32` | Relation (subType 1) | **→ ws `6a8434f18b36df988c16ed8e` (AC_APPROVAL_RULE)** · sourceField `6a84366133560633b8cd2f33` · bidirectional=false · level 2 |
| `is_active` | `6a8438a933560633b8cd30aa` | Checkbox (subType 0) |  |

#### FR-01.3 กฎการออกเลขที่เอกสาร — **Worksheet `AC_DOC_NUMBER_RULE`** · ws `6a8434ea8b36df988c16ed84` · alias `ac_doc_number_rule` · view `6a8434ea8b36df988c16ed88`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `year_era` | `6a8434ea1049edca1eec9f6d` | SingleSelect (subType 0) | required · options: `1a4e4946-e30e-44dc-ab07-e1e355293e3a`=CE · `295b875b-b296-44f3-ba9a-e6a456477dca`=BE |
| `effective_from` | `6a8434ea1049edca1eec9f6c` | Date (subType 3) | required |
| `current_sequence` | `6a8434ea1049edca1eec9f6b` | Number (subType 0) | precision 0 |
| `running_length` | `6a8434ea1049edca1eec9f6a` | Number (subType 0) | required · precision 0 |
| `prefix` | `6a8434ea1049edca1eec9f69` | Text (subType 0) |  |
| `doc_type` | `6a8434ea1049edca1eec9f67` | Relation (subType 1) | required · **→ ws `6a8434dd9b6999a714d22e3d` (AC_DOC_TYPE)** · sourceField `6a8434ea1049edca1eec9f68` · bidirectional=false · level 2 |
| `rule_name` | `6a8434ea1049edca1eec9f66` | Text (subType 0) | required · **isTitle = true** |
| `is_active` | `6a8437ed8b36df988c16ede5` | Checkbox (subType 0) |  |
| `date_pattern` | `6a8520458b36df988c1721a8` | Dropdown (subType 0) | required · optionset dataSource `9242ead9-9da9-4b41-a5a7-9889c0b977d5` · options: `b33e3220-4da5-4ced-810b-7b43d7907a4f`=None · `5f1bb091-5182-447b-84ae-000057726204`=Year · `89d7165e-fc0b-4459-9ab2-e2ee9ff52a95`=Year-month · `9f7d4abd-3f4d-42d4-ab5c-ca8818254ec4`=Year-month-day |
| `reset_cycle` | `6a8520458b36df988c1721a9` | Dropdown (subType 0) | required · optionset dataSource `24ee40c8-2c68-4cd4-8d1f-1d24a80c7304` · options: `76525298-efb4-4c85-885f-16df5f91688f`=Never · `0263cfa6-6e12-4d44-9fe3-f25abf470587`=Yearly · `fd01abe2-ed6b-44ef-94c0-e54d61355e67`=Monthly · `9f87515c-a0d8-49e8-9a24-172057038ae5`=Daily |

> `year_era` รองรับ พ.ศ. (`295b875b-b296-44f3-ba9a-e6a456477dca`) ตามที่เอกสารภาษาไทยต้องการ — เป็นค่าตั้งค่า **ไม่ใช่การแก้โค้ด** (BR-13)
> ⚠️ `current_sequence` เป็น Number ธรรมดา — การเดินเลขต้องทำใน workflow แบบ **อ่าน → +1 → เขียนกลับ** ห้ามใช้ AutoNumber ของแพลตฟอร์มเพราะรีเซ็ตตามรอบไม่ได้ตามกฎนี้ · ต้องมี **Unique index บน `voucher_no`/`ap_no`/… เพื่อกันเลขซ้ำเมื่อสองคนกดพร้อมกัน**

#### FR-01.4 พฤติกรรมเอกสาร — **Worksheet `AC_DOC_SETTING`** · ws `6a8434f69b6999a714d22e75` · alias `ac_doc_setting` · view `6a8434f69b6999a714d22e79`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `standard_remark` | `6a8434f69b6999a714d22e82` | Text (subType 0) |  |
| `side` | `6a8434f69b6999a714d22e81` | SingleSelect (subType 0) | required · options: `1c74b144-1225-41e5-872f-1cf5d7f8d708`=Purchase · `e6a7b9b8-9e24-4109-bed0-44a131d91f74`=Sales |
| `setting_name` | `6a8434f69b6999a714d22e80` | Text (subType 0) | required · **isTitle = true** |
| `show_adjustment_lines_on_receipt` | `6a843a0a33560633b8cd30b9` | Checkbox (subType 0) |  |
| `logo_image` | `6a843a0a33560633b8cd30ba` | Attachment (subType 3) | placeholder "Add files" |
| `seal_image` | `6a843a0a33560633b8cd30bb` | Attachment (subType 3) | placeholder "Add files" |
| `default_price_basis` | `6a85229a8b36df988c1721d5` | Dropdown (subType 0) | required · optionset dataSource `abd98ad7-017f-4af5-8edd-1a0e26d1419d` · options: `b3171393-58cd-4a43-b241-b83548e37f3f`=VAT-exclusive · `77f0e10d-e397-4822-8342-d3b803e7ba88`=VAT-inclusive |
| `vat_compute_position` | `6a85229a8b36df988c1721d6` | Dropdown (subType 0) | required · optionset dataSource `3ac59595-7dba-4e49-822c-e8ba261f5764` · options: `2e2e0f4e-7553-4523-afd8-7fe886173bcc`=Line level · `7397640a-c70e-47cd-a4a3-b23e003b8801`=Document level |
| `discount_compute_position` | `6a85229a8b36df988c1721d7` | Dropdown (subType 0) | required · optionset dataSource `3ac59595-7dba-4e49-822c-e8ba261f5764` (ชุดเดียวกับ vat_compute_position) · options: `2e2e0f4e-7553-4523-afd8-7fe886173bcc`=Line level · `7397640a-c70e-47cd-a4a3-b23e003b8801`=Document level |
| `wht_compute_position` | `6a85229a8b36df988c1721d8` | Dropdown (subType 0) | required · optionset dataSource `3ac59595-7dba-4e49-822c-e8ba261f5764` (ชุดเดียวกับ vat_compute_position) · options: `2e2e0f4e-7553-4523-afd8-7fe886173bcc`=Line level · `7397640a-c70e-47cd-a4a3-b23e003b8801`=Document level |
| `wht_timing` | `6a85229a8b36df988c1721d9` | Dropdown (subType 0) | required · optionset dataSource `b55a29cd-8827-43a1-bf5f-677fd691329c` · options: `250c24af-dc6b-452d-a1cb-eefcc736f0fb`=At invoice · `998bd1a6-1d3b-4b57-9b8e-9587624b3614`=At payment |

> ฟิลด์ 3 ตัว (`vat_compute_position`, `discount_compute_position`, `wht_compute_position`) ใช้ optionset ชุดเดียวกัน `3ac59595-…` — ตั้งค่าต่างกันได้ อย่าถือว่าเปลี่ยนพร้อมกัน
> `wht_timing` = **At payment** ตามข้อสมมติ A-10 ⇒ ใบรับรองหัก ณ ที่จ่ายออกโดย **WF-AC-14** ไม่ใช่ WF-AC-06

#### FR-01.5 กฎอนุมัติตามวงเงิน — **Worksheet `AC_APPROVAL_RULE`** · ws `6a8434f18b36df988c16ed8e` · alias `ac_approval_rule` · view `6a8434f18b36df988c16ed92`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `rule_name` | `6a8434f19b6999a714d22e54` | Text (subType 0) | required · **isTitle = true** |
| `doc_type` | `6a8434f19b6999a714d22e55` | Relation (subType 1) | required · **→ ws `6a8434dd9b6999a714d22e3d` (AC_DOC_TYPE)** · sourceField `6a8434f19b6999a714d22e56` · bidirectional=false · level 2 |
| `value_from` | `6a8434f19b6999a714d22e57` | Number (subType 0) | required · precision 2 |
| `value_to` | `6a8434f19b6999a714d22e58` | Number (subType 0) | precision 2 |
| `effective_from` | `6a8434f19b6999a714d22e5c` | Date (subType 3) | required |
| `is_active` | `6a843887055f2288c5b6d78d` | Checkbox (subType 0) |  |
| `completion_mode` | `6a8520d933560633b8cd65ca` | Dropdown (subType 0) | required · optionset dataSource `7eb8ad24-65e2-411e-ab58-a7f030f21876` · options: `0605fa6b-13ff-4063-b41f-ae690e450e23`=All must approve · `fe6a0464-36ce-4553-9ad8-bfb2cfb431ab`=Any one may approve |
| `approver_role_1` | `6a85f7e01049edca1eed022d` | OrgRole (subType 0) |  |
| `approver_role_2` | `6a85f7e01049edca1eed022e` | OrgRole (subType 0) |  |
| `approver_role_3` | `6a85f7e01049edca1eed022f` | OrgRole (subType 0) |  |

> 🔑 `approver_role_1/2/3` เป็นชนิด **OrgRole** — เก็บ "บทบาท" ไม่ใช่ "ตัวบุคคล" ⇒ workflow ต้องแปลงบทบาทเป็นผู้อนุมัติจริงก่อนเข้า Approve node (ดู `15-Workflow-Catalog-AC.md` §3 WF-AC-01 ขั้นที่ 4)
> ⚠️ Approve node เลือกผู้อนุมัติได้เฉพาะฟิลด์ **Personnel/Collaborator บน data object ของ approval เอง** ⇒ **AC_VOUCHER ต้องมีฟิลด์ Collaborator `approver_user`** ซึ่ง**ยังไม่มี** (ดู FR-06 แถว 🆕)

#### FR-01.6 กฎการผ่านรายการอัตโนมัติ — **Worksheet `AC_POSTING_RULE`** · ws `6a85518c33560633b8cd6a15` · alias `ac_posting_rule` · view `6a85518c33560633b8cd6a19`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `rule_name` | `6a85518c055f2288c5b7430a` | Text (subType 0) | required · **isTitle = true** |
| `event_code` | `6a85518c055f2288c5b7430b` | SingleSelect (subType 0) | required · options: `441ffaf1-01d5-415e-a79b-87c557b97e6f`=AP_RECOGNITION · `30c11f67-b239-41f6-9f77-0d221e0ff487`=AP_SETTLEMENT · `cb43c092-05e8-4858-9ed0-70ea2bf722c0`=AR_RECOGNITION · `55fdff1b-90c2-44f8-be19-8bcfca7c08f7`=AR_COLLECTION · `6d4e44df-1d0c-4710-aabb-2dc67dcdc4a6`=DEPRECIATION · `3e16e8a7-39fe-4cef-9909-5e0cefd27fc1`=DISPOSAL · `7a9a4edb-94dd-4d10-999d-3e6569358f85`=VAT_TRANSFER · `86faafbf-f191-460a-9890-bdfab9d5d368`=WHT_ACCRUAL · `c42dbc06-05f9-4337-a321-a1d8084bf8e6`=FX_REVAL · `49686cf3-b945-4819-95d1-182d930f3eed`=CLOSING |
| `condition` | `6a85518c055f2288c5b7430c` | Text (subType 0) |  |
| `debit_account` | `6a85518c055f2288c5b7430d` | Relation (subType 1) | required · **→ ws `6a85516e1049edca1eecd9b7` (AC_COA)** · sourceField `6a85518c055f2288c5b7430e` · bidirectional=false · level 2 |
| `credit_account` | `6a85518c055f2288c5b7430f` | Relation (subType 1) | required · **→ ws `6a85516e1049edca1eecd9b7` (AC_COA)** · sourceField `6a85518c055f2288c5b74310` · bidirectional=false · level 2 |
| `effective_from` | `6a85518c055f2288c5b74311` | Date (subType 3) | required |
| `is_active` | `6a85e6b09b6999a714d2a409` | Checkbox (subType 0) |  |

> `event_code` 10 ค่าครอบคลุมทุกเหตุการณ์ที่ workflow ต้องใช้ — WF ทุกตัวที่สร้างใบสำคัญ **ต้องอ่านคู่บัญชีจากตารางนี้** ห้าม hard-code รหัสบัญชีใน node
> `condition` เป็น Text อิสระ ⇒ ต้องกำหนดไวยากรณ์ให้ตายตัวก่อนใช้ (ข้อเสนอ: `field=value` คั่นด้วย `;`) — **ยังไม่ตกลง 🔴**

**Form rules (ไม่ใช่ workflow — ลอง CLI ก่อน แล้วค่อย Browser)**

> ✅ **แก้ 30 ส.ค. 2569** — Business Rule มีคำสั่ง CLI แล้ว: `hap worksheet rules <ws>` **อ่านได้จริง [V]** · `hap worksheet save-rule --type 0|1|2 --check-type 0|1` เขียน **[S] ยังไม่เคยยิง** ⇒ อ่านของเดิมด้วย CLI ได้เลย ส่วนการเขียนให้ลอง CLI ก่อน ถ้าไม่ผ่านค่อยเข้า Browser · ตรวจผลด้วย **Role Debugging** เสมอ (ไม่ใช่ `get_record_logs`)

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-01.1 | Business Rule · validation | `AC_APPROVAL_RULE.value_to` < `value_from` (และ `value_to` ไม่ว่าง) | Block save "วงเงินสูงสุดต้องไม่น้อยกว่าวงเงินต่ำสุด" |
| BR-01.2 | Business Rule · validation | `AC_DOC_NUMBER_RULE.running_length` < 1 หรือ > 10 | Block save |
| IX-01.1 | Unique index | `AC_JOURNAL.journal_code` | กันรหัสสมุดรายวันซ้ำ (ฟิลด์ required อยู่แล้ว ✓) |
| IX-01.2 | Unique index | `AC_DOC_TYPE.doc_code` | กันรหัสประเภทเอกสารซ้ำ (required ✓) |
| BR-01.3 | Business Rule · interaction | `is_active` = ไม่ติ๊ก | ตั้งฟิลด์อื่นทั้งหมดเป็น read-only (เก็บประวัติ ไม่ลบ) |

**Definition of Done:** ทั้ง 6 ตารางมีข้อมูลจริงครบทุกประเภทเอกสารที่ใช้ใน FR-06…FR-12 · สร้างใบสำคัญทดสอบแล้วได้เลขที่ตามรูปแบบที่กำหนดใน `AC_DOC_NUMBER_RULE`
**วิธี verify:** `get_record_list(ac_doc_type, includeTotalCount)` ≥ จำนวนประเภทเอกสารที่ใช้จริง · `create_record(ac_voucher)` แล้วอ่าน `voucher_no` กลับ — ต้องตรงรูปแบบ
**Gap:** ยังไม่ได้ตรวจจำนวน record ของทั้ง 6 ตาราง (`13-ID-Registry-AC.md` §1.2 คอลัมน์ record = `—`) · ไวยากรณ์ `AC_POSTING_RULE.condition` ยังไม่ตกลง 🔴

---

### FR-02 งวดบัญชี

**สถานะ: ⚠️ ตารางครบ มีข้อมูล 13 record แต่ยังไม่มี workflow ใดบังคับใช้สถานะงวด**

**Worksheet `AC_PERIOD`** · ws `6a8434d5055f2288c5b6d4b8` · alias `ac_period` · view `6a8434d5055f2288c5b6d4bc`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `period_name` | `6a8434d58b36df988c16ed65` | Text (subType 0) | required · **isTitle = true** |
| `fiscal_year` | `6a8434d58b36df988c16ed66` | Number (subType 0) | required · precision 0 |
| `period_no` | `6a8434d58b36df988c16ed67` | Number (subType 0) | required · precision 0 |
| `date_from` | `6a8434d58b36df988c16ed68` | Date (subType 3) | required |
| `date_to` | `6a8434d58b36df988c16ed69` | Date (subType 3) | required |
| `closed_by` | `6a8434d58b36df988c16ed6a` | Collaborator (subType 0) |  |
| `closed_at` | `6a8434d58b36df988c16ed6b` | DateTime (subType 1) |  |
| `reopen_reason` | `6a8434d58b36df988c16ed6c` | Text (subType 0) |  |
| `period_status` | `6a851f70055f2288c5b73edf` | Dropdown (subType 0) | required · optionset dataSource `e9ae2c06-eb06-45ee-a2ee-4eb1757f1116` · options: `f662571c-3de0-4e4c-9828-9172e337d223`=Open · `b2986cb5-59db-4fdc-87ed-d57a38201c6a`=Soft-closed · `38392e32-7c09-4339-a9b4-81a9f53eba0a`=Permanently locked |
| `tax_period_status` | `6a851f70055f2288c5b73ee0` | Dropdown (subType 0) | required · optionset dataSource `a04fa23c-4498-473a-9637-12e754802d06` · options: `d41e3a2e-684b-4533-9913-09a04302626e`=Open · `fa108e9e-c642-4740-af6a-a6964ecc50d3`=Filed · `3d94b4e7-170b-47ee-a5e1-e3a2e415cfa4`=Amended |
| `biz_close_flag` (ปิดงวด (ธง)) | `6a903ea68b6633ef76f169c5` | Number (subType 0) | precision 0 · default 0 · ✅ สร้างแล้ว 27 ส.ค. 2569 — ธงกันยิงซ้ำ/trigger field ของ **WF-AC-09** (เดิมชื่อ 🆕 `close_flag` ในเอกสาร — สร้างจริงเป็น `biz_close_flag`) |
| `biz_close_year_flag` (ปิดปี (ธง)) | `6a90ef228b6633ef76f16f55` | Number (subType 0) | precision 0 · default 0 · ✅ สร้างแล้ว 28 ส.ค. 2569 — ธงกันยิงซ้ำ/trigger field ของ **WF-AC-11** (ปิดปีและยกยอด) — pattern เดียวกับ `biz_close_flag`/WF-AC-09 |

| 🆕 ฟิลด์ที่ต้องสร้างเพิ่ม | type MCP | เหตุผล |
|---|---|---|
| 🆕 `reopened_by` | `Collaborator` subType 0 | BR-03 บังคับให้บันทึกผู้อนุมัติการเปิดงวดใหม่ — ปัจจุบันมีแต่ `closed_by` |
| 🆕 `reopened_at` | `DateTime` subType 1 | เวลาเปิดงวดใหม่ (เขียนโดย workflow) |
| ~~🆕 `close_flag`~~ | ~~`Number` precision 0~~ | ✅ **สร้างแล้ว 27 ส.ค. 2569** เป็น `biz_close_flag` (`6a903ea68b6633ef76f169c5`) — ย้ายขึ้นตารางฟิลด์จริงด้านบนแล้ว ไม่ใช่รายการค้างอีกต่อไป |

**State machine (`period_status`)**

| จาก | ไป | ขับด้วย | เงื่อนไข / ผู้มีสิทธิ์ |
|---|---|---|---|
| Open `f662571c-…` | Soft-closed `b2986cb5-…` | ปุ่ม "ปิดงวด" → **WF-AC-09** | ไม่มีใบสำคัญค้างอนุมัติในงวดนั้น · AC-R3 |
| Soft-closed | Open | ปุ่ม "เปิดงวดใหม่" (`updateCurrentRecord`) | AC-R3 เท่านั้น · **บังคับกรอก `reopen_reason`** |
| Soft-closed | Permanently locked `38392e32-…` | **WF-AC-11** (ปิดปี) | หลังปิดปีสำเร็จ |
| Permanently locked | — | **ไม่มีทางกลับ** | — |

**State machine (`tax_period_status`) — แยกอิสระจาก `period_status`**

| จาก | ไป | ขับด้วย |
|---|---|---|
| Open `d41e3a2e-…` | Filed `fa108e9e-…` | **WF-AC-16 / WF-AC-17** เมื่อยื่นแบบสำเร็จ |
| Filed | Amended `3d94b4e7-…` | **WF-AC-16** เมื่อมีการยื่นเพิ่มเติม |

> 🔑 การแยกสองสถานะนี้คือกลไกที่ทำให้ **TC-21** ผ่าน (ใบกำกับที่ tax point ตกในงวดที่ยื่นแล้ว ต้องถูกโยนไปงวดภาษีที่ยังเปิด)

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-02.1 | Business Rule · interaction | `period_status` in (Soft-closed, Permanently locked) | Set all fields read-only |
| BR-02.2 | Business Rule · validation | `date_to` < `date_from` | Block save |
| IX-02.1 | Unique index | (`fiscal_year`, `period_no`) | กันงวดซ้ำ — ทั้งสองฟิลด์ required ✓ · **ล้างถังขยะก่อนสร้าง index** |
| DV-02.1 | Dynamic default | `period_name` ← `{fiscal_year}-{period_no ปรับเป็น 2 หลัก}` | รูปแบบตาม SDS Appendix A |

**Definition of Done:** งวดของปีบัญชีปัจจุบันครบทุกงวดรวมงวด 13 · ปิดงวดผ่านปุ่มแล้วสถานะเปลี่ยนโดย workflow (log ขึ้น `user-workflow`) · ใบสำคัญลงวันที่ในงวดที่ปิดแล้วบันทึกไม่ได้
**วิธี verify:** `get_record_list(ac_period)` = 13 ✓ (ตรวจแล้ว) · `create_record(ac_voucher)` ที่ผูกงวด Soft-closed → ต้องถูกปฏิเสธโดย Branch node ของ WF-AC-01
**Pitfall:** `period_status` เป็น Dropdown ที่ผูก optionset — **ห้ามใช้เป็น Trigger Condition** (field-cache bug) ให้ใช้ Trigger Field แล้วเช็กใน Branch node แรก

---

### FR-03 ผังบัญชีและมิติทางบัญชี

**สถานะ: ⚠️ ตารางครบ · ผังบัญชีนำเข้าแล้ว 79 record · ยังไม่ได้ตรวจว่าครบตามผังจริงขององค์กร**

#### FR-03.1 ผังบัญชี — **Worksheet `AC_COA`** · ws `6a85516e1049edca1eecd9b7` · alias `ac_coa` · view `6a85516e1049edca1eecd9bb`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `account_code` | `6a85516e055f2288c5b742e6` | Text (subType 0) | required · **isTitle=True** |
| `account_name_th` | `6a85516e055f2288c5b742e7` | Text (subType 0) | required |
| `account_name_en` | `6a85516e055f2288c5b742e8` | Text (subType 0) |  |
| `statement_line` | `6a85516e055f2288c5b742e9` | Text (subType 0) | required |
| `level` | `6a85516e055f2288c5b742ea` | Number (subType 0) | required |
| `gfmis_code` | `6a85516e055f2288c5b742eb` | Text (subType 0) |  |
| `default_vat_rate` | `6a85516e055f2288c5b742ec` | Relation (subType 1) | → ws `6a8545469b6999a714d2673c` (AC_VAT_RATE) · sourceField `6a85516e055f2288c5b742ed` |
| `bank_account` | `6a85516e055f2288c5b742ee` | Relation (subType 1) | → ws `6a854584055f2288c5b74202` (AC_BANK) · sourceField `6a85516e055f2288c5b742ef` |
| `parent_account` | `6a85517b9b6999a714d268cb` | Relation (subType 1) | → ws `6a85516e1049edca1eecd9b7` (AC_COA, self) · sourceField `6a85517b9b6999a714d268cc` |
| `child_accounts` | `6a85517b9b6999a714d268cc` | Relation (subType 2) | → ws `6a85516e1049edca1eecd9b7` (AC_COA, self) · sourceField `6a85517b9b6999a714d268cb` |
| `account_type` | `6a85590b055f2288c5b743b3` | Dropdown (subType 0) | optionset `1c7f8e6f-4353-45b7-ab5d-a7bf378d373d` · keys: `eb611620-08c4-437f-8b3a-82ede5b2d943`=Asset · `87120a74-f416-470f-90ce-3b3be2d2dd3f`=Liability · `1e26342f-db85-4079-b58a-698e6f776ba5`=Equity · `9219f18a-5776-46c9-b42a-6c1a6bd129f7`=Revenue · `047a0a8e-027b-4ddc-b64d-975de50b6f2e`=Expense |
| `account_group` | `6a85590b055f2288c5b743b4` | Dropdown (subType 0) | optionset `ffaa0703-87d3-4c56-b1be-4d10b9112eb3` · keys: `d89e8412-6a5e-4ffc-a9f6-05fce91af7d7`=Current asset · `44aded18-d965-4ea0-a75e-71da0749081e`=Non-current asset · `6a7c6caf-d02d-4e3f-a570-d3e40de7177c`=Current liability · `894a6ccb-c7a7-4174-8cd2-1300659f82ea`=Non-current liability · `980407cb-affa-4291-837d-e5f8b0a1364a`=Equity · `b4b4ea00-ad31-4432-904a-db320c1ef01b`=Revenue · `8b03244f-0b84-44c5-91d7-27a23037423a`=Cost of sales · `ffc39820-e429-4b1f-92a1-4656770b340b`=Selling · `6b4bdaa2-7c62-489e-a69f-910941f38fa5`=Administrative · `521683be-8fb3-45e2-a266-6e575c6fb240`=Other |
| `normal_balance` | `6a85590b055f2288c5b743b5` | Dropdown (subType 0) | optionset `4c41d346-4823-4c60-924f-c6f7744b7d70` · keys: `f3042960-4a2d-4fcc-856a-3a1d1683932a`=Debit · `1288a1c8-115d-4293-bddc-077cb623fe4d`=Credit |
| `is_postable` | `6a85590b055f2288c5b743b6` | Checkbox (subType 0) |  |
| `require_cost_center` | `6a85590b055f2288c5b743b7` | Checkbox (subType 0) |  |
| `require_fund` | `6a85590b055f2288c5b743b8` | Checkbox (subType 0) |  |
| `require_project` | `6a85590b055f2288c5b743b9` | Checkbox (subType 0) |  |
| `require_partner` | `6a85590b055f2288c5b743ba` | Checkbox (subType 0) |  |
| `is_active` | `6a85590b055f2288c5b743bb` | Checkbox (subType 0) |  |

> `parent_account` / `child_accounts` เป็นคู่ self-relation ⇒ ลำดับชั้นใช้ได้แล้ว
> `is_postable` เป็น **Checkbox** ซึ่ง **MCP สร้างไม่ได้** — ลอง `hap worksheet add-fields` (Surface C) ก่อน [S] ถ้าไม่ผ่านค่อยทำใน Browser แล้วอ่าน ID กลับ
> ⚠️ `account_type`, `account_group`, `normal_balance` ทั้งสามตัว `required=False` บนเซิร์ฟเวอร์ แต่ SDS ระบุว่าบังคับ ⇒ ต้องตั้ง required เพิ่ม · **MCP ตั้ง required/validation ไม่ได้ แต่ CLI edit-spec `field.update` น่าจะได้ [S]** — ลอง CLI ก่อน ถ้าไม่ผ่านค่อย Browser (แก้ 30 ส.ค. 2569 จากเดิมที่เขียนว่า Browser อย่างเดียว)

#### FR-03.2 หน่วยงาน / ศูนย์ต้นทุน — **Worksheet `AC_COST_CENTER`** · ws `6a85452b9b6999a714d26720` · alias `ac_cost_center` · view `6a85452b9b6999a714d26725`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `cc_code` | `6a85452b055f2288c5b741b9` | Text (subType 0) | required · **isTitle=True** |
| `cc_name_th` | `6a85452b055f2288c5b741ba` | Text (subType 0) | required |
| `cc_name_en` | `6a85452b055f2288c5b741bb` | Text (subType 0) |  |
| `hrms_unit_id` | `6a85452b055f2288c5b741bc` | Text (subType 0) |  |
| `parent_cc` | `6a8545b7055f2288c5b74231` | Relation (subType 1) | → ws `6a85452b9b6999a714d26720` (AC_COST_CENTER, self) · sourceField `6a8545b7055f2288c5b74232` |
| `child_cost_centers` | `6a8545b7055f2288c5b74232` | Relation (subType 2) | → ws `6a85452b9b6999a714d26720` (AC_COST_CENTER, self) · sourceField `6a8545b7055f2288c5b74231` |
| `is_active` | `6a85e62733560633b8cd9eca` | Checkbox (subType 0) |  |

#### FR-03.3 แหล่งเงิน — **Worksheet `AC_FUND`** · ws `6a85453033560633b8cd68dc` · alias `ac_fund` · view `6a85453033560633b8cd68e0`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `fund_code` | `6a8545309b6999a714d2672c` | Text (subType 0) | required · **isTitle=True** |
| `fund_name` | `6a8545309b6999a714d2672d` | Text (subType 0) | required |
| `fund_type` | `6a8545309b6999a714d2672e` | SingleSelect (subType 0) | required · inline options (no optionset id) · keys: `ee7d5539-1267-476f-92f1-89efd3671287`=Budget · `9a254a31-7aba-459e-ade2-619086ed9ead`=Non-budgetary · `76566396-abf3-4b36-9f8f-fe61f5928748`=Own revenue · `cb8f4292-a8e4-46cc-9226-624dc9de123b`=Research |
| `is_active` | `6a85e6361049edca1eed0194` | Checkbox (subType 0) |  |

#### FR-03.4 มิติโครงการ — **Worksheet `AC_PROJECT_DIM`** · ws `6a854534055f2288c5b741ce` · alias `ac_project_dim` · view `6a854534055f2288c5b741d2`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `project_code` | `6a8545341049edca1eecd822` | Text (subType 0) | required · **isTitle=True** |
| `project_name` | `6a8545341049edca1eecd823` | Text (subType 0) | required |
| `grant_module_ref` | `6a8545341049edca1eecd824` | Text (subType 0) |  |
| `date_from` | `6a8545341049edca1eecd825` | Date (subType 3) |  |
| `date_to` | `6a8545341049edca1eecd826` | Date (subType 3) |  |
| `is_active` | `6a85e6418b36df988c1760a4` | Checkbox (subType 0) |  |

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-03.1 | Business Rule · validation | `is_postable` ติ๊ก **และ** `child_accounts` ไม่ว่าง | Block save "บัญชีที่มีบัญชีย่อยรับรายการไม่ได้" — บังคับ **TC-03** |
| BR-03.2 | Business Rule · interaction | `account_type` in (Asset, Expense) | ตั้ง `normal_balance` = Debit เป็นค่าเริ่มต้น |
| IX-03.1 | Unique index | `AC_COA.account_code` | required ✓ |
| IX-03.2 | Unique index | `AC_COST_CENTER.cc_code` · `AC_FUND.fund_code` · `AC_PROJECT_DIM.project_code` | required ✓ ทั้งหมด |
| BR-03.3 | Business Rule · validation | `AC_PROJECT_DIM.date_to` < `date_from` | Block save |

**Definition of Done:** ผังบัญชีตรงกับผังจริงขององค์กรทุกบัญชี · บัญชีระดับสรุปไม่ปรากฏใน picker ของ `AC_VOUCHER_LINE.account`
**วิธี verify:** `get_record_list(ac_coa, filter is_postable = ติ๊ก, includeTotalCount)` แล้วเทียบกับผังจริง · เปิดฟอร์ม AC_VOUCHER_LINE ด้วย **Role Debugging** เป็น AC-R1 แล้วดูรายการบัญชีใน picker
**Gap:** ยังไม่ได้พิสูจน์ว่า 79 บัญชีคือผังจริงหรือชุดตัวอย่าง 🔴 · การกรอง picker ตาม `is_postable` ต้องทำด้วย **filter บน relation field** ซึ่งตั้งใน Browser

---

### FR-04 คู่ค้าและบัญชีธนาคาร

**สถานะ: ⚠️ ตารางครบ · คู่ค้า 30 record · ยังไม่มีการปกปิดข้อมูลอ่อนไหวตาม NFR-02**

#### FR-04.1 คู่ค้า — **Worksheet `AC_PARTNER`** · ws `6a85457033560633b8cd6920` · alias `ac_partner` · view `6a85457033560633b8cd6924`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `partner_code` | `6a8545701049edca1eecd865` | Text (subType=0) | required · isTitle=True |
| `name_th` | `6a8545701049edca1eecd866` | Text (subType=0) | required |
| `name_en` | `6a8545701049edca1eecd867` | Text (subType=0) |  |
| `tax_id` | `6a8545701049edca1eecd868` | Text (subType=0) |  |
| `branch_code` | `6a8545701049edca1eecd869` | Text (subType=0) |  |
| `address` | `6a8545701049edca1eecd86a` | Text (subType=0) | required |
| `postcode` | `6a8545701049edca1eecd86b` | Text (subType=0) | required |
| `delivery_info` | `6a8545701049edca1eecd86c` | Text (subType=0) |  |
| `is_domestic` | `6a8545701049edca1eecd86d` | SingleSelect (subType=0) | required · options: `5d274ae0-5cd5-49e3-b230-89ddd24b5865`=Domestic · `d26d20fa-44d0-4702-80ae-cf8779b0b9a4`=Foreign |
| `credit_days` | `6a8545701049edca1eecd86e` | Number (subType=0) | required |
| `default_wht_type` | `6a8545701049edca1eecd86f` | Relation (subType=1) | → ws `6a85454133560633b8cd68e6` (AC_WHT_INCOME_TYPE) · sourceField = `6a8545701049edca1eecd870` |
| `contact_name` | `6a8545701049edca1eecd871` | Text (subType=0) |  |
| `email` | `6a8545701049edca1eecd872` | Text (subType=0) |  |
| `mobile` | `6a8545701049edca1eecd873` | Text (subType=0) |  |
| `phone` | `6a8545701049edca1eecd874` | Text (subType=0) |  |
| `fax` | `6a8545701049edca1eecd875` | Text (subType=0) |  |
| `website` | `6a8545701049edca1eecd876` | Text (subType=0) |  |
| `note` | `6a8545701049edca1eecd877` | Text (subType=0) |  |
| `bank_accounts` | `6a8545b58b36df988c172486` | Relation (subType=2) | → ws `6a85458033560633b8cd692a` (AC_PARTNER_BANK) · sourceField = `6a8545b58b36df988c172487` |
| `partner_type` | `6a85e4269b6999a714d2a3f0` | MultipleSelect (subType=0) | optionset dataSource = `fd947876-5402-408c-8c09-87db96c188c5` · options: `90ce110c-6767-44bc-97ca-5de884c2ad49`=Customer · `13235e3d-088a-49b0-8c48-aec8c33280cd`=Supplier |
| `legal_form` | `6a85e486055f2288c5b77672` | Dropdown (subType=0) | optionset dataSource = `b97a1a08-78ab-4683-8472-837c48af4423` · options: `adf4bb5f-5a6b-4a99-b416-4d03ec5e295e`=Juristic person · `1aeb1a04-1957-4905-92d9-c506d8bbdccc`=Individual |
| `branch_type` | `6a85e486055f2288c5b77673` | Dropdown (subType=0) | optionset dataSource = `081f8bfc-bab8-4a89-91cf-ea3e501b3b4c` · options: `6ec11519-e394-42db-8610-db6abdd5ab6d`=Head office · `f5abd6cd-e45b-4353-b0a7-527c0d18d027`=Branch |
| `is_active` | `6a85e486055f2288c5b77674` | Checkbox (subType=0) |  |
| `attachments` | `6a85e486055f2288c5b77675` | Attachment (subType=3) |  |

#### FR-04.2 บัญชีธนาคารคู่ค้า — **Worksheet `AC_PARTNER_BANK`** · ws `6a85458033560633b8cd692a` · alias `ac_partner_bank` · view `6a85458033560633b8cd692e`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `account_name` | `6a854581055f2288c5b741e1` | Text (subType=0) | required · isTitle=True |
| `partner` | `6a854581055f2288c5b741e2` | Relation (subType=1) | required · → ws `6a85457033560633b8cd6920` (AC_PARTNER) · sourceField = `6a854581055f2288c5b741e3` |
| `bank` | `6a854581055f2288c5b741e4` | Text (subType=0) | required |
| `account_no` | `6a854581055f2288c5b741e5` | Text (subType=0) | required |
| `branch` | `6a854581055f2288c5b741e6` | Text (subType=0) |  |
| `account_type` | `6a854581055f2288c5b741e7` | Text (subType=0) |  |
| `swift_code` | `6a854581055f2288c5b741e8` | Text (subType=0) |  |
| `bank_address` | `6a854581055f2288c5b741e9` | Text (subType=0) |  |
| `is_active` | `6a85e6638b36df988c1760a9` | Checkbox (subType=0) |  |

#### FR-04.3 บัญชีธนาคารขององค์กร — **Worksheet `AC_BANK`** · ws `6a854584055f2288c5b74202` · alias `ac_bank` · view `6a854584055f2288c5b74206`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `account_name` | `6a8545849b6999a714d26747` | Text (subType=0) | required · isTitle=True |
| `bank_name` | `6a8545849b6999a714d26748` | Text (subType=0) | required |
| `account_no` | `6a8545849b6999a714d26749` | Text (subType=0) | required |
| `branch` | `6a8545849b6999a714d2674a` | Text (subType=0) |  |
| `currency` | `6a8545849b6999a714d2674b` | Relation (subType=1) | required · → ws `6a8545261049edca1eecd818` · sourceField = `6a8545849b6999a714d2674c` |
| `gl_account` | `6a85519a33560633b8cd6a1f` | Relation (subType=1) | required · → ws `6a85516e1049edca1eecd9b7` · sourceField = `6a85519a33560633b8cd6a20` |
| `is_active` | `6a85e65333560633b8cd9ecf` | Checkbox (subType=0) |  |

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-04.1 | Business Rule · validation | `legal_form` = Juristic person `adf4bb5f-…` และ `tax_id` ไม่ใช่ 13 หลัก | Block save "เลขประจำตัวผู้เสียภาษีต้องมี 13 หลัก" |
| BR-04.2 | Business Rule · interaction | `branch_type` = Branch `f5abd6cd-…` | `branch_code` เป็นฟิลด์บังคับ |
| BR-04.3 | Business Rule · interaction | `is_domestic` = Foreign `d26d20fa-…` | ซ่อน `tax_id`, `branch_type` · แสดง `swift_code` บนตารางลูก |
| IX-04.1 | Unique index | `AC_PARTNER.partner_code` | required ✓ |
| IX-04.2 | Unique index | (`AC_PARTNER.tax_id`, `AC_PARTNER.branch_code`) | ⚠️ ทั้งสองฟิลด์ **ไม่ required** — ค่าว่างได้แค่ 1 แถวทั้งตาราง ⇒ **ต้องตั้ง required ก่อน หรือใช้ workflow กันซ้ำแทน** |
| BR-04.4 | Field permission | ซ่อน `tax_id` และ `AC_PARTNER_BANK.account_no` จาก AC-R6 | NFR-02 / PDPA — ตั้งในหน้า Role |

**Definition of Done:** คู่ค้าทุกรายที่ใช้ในเอกสารทดสอบมีเลขผู้เสียภาษีและประเภทสำนักงานครบ · AC-R6 เปิดดูคู่ค้าแล้วไม่เห็นเลขผู้เสียภาษีและเลขบัญชี
**วิธี verify:** **Role Debugging** → สลับเป็น AC-R6 → เปิด AC_PARTNER → ฟิลด์ต้องถูกซ่อน
**Gap:** ยังไม่มีการปกปิดฟิลด์เลย 🔴 · ยังไม่ได้ยืนยันว่า 30 record เป็นข้อมูลจริงหรือข้อมูลทดสอบ

---

### FR-05 ข้อมูลหลักด้านภาษี สินค้า และสกุลเงิน

**สถานะ: ⚠️ ตารางครบทั้ง 8 · อัตรา VAT 5 record · ยังไม่ตรวจตารางที่เหลือ**

#### FR-05.1 อัตราภาษีมูลค่าเพิ่ม — **Worksheet `AC_VAT_RATE`** · ws `6a8545469b6999a714d2673c` · alias `ac_vat_rate` · view `6a8545469b6999a714d26740`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `vat_code` | `6a8545468b36df988c17244c` | Text (subType=0) | required · isTitle=True |
| `vat_name` | `6a8545468b36df988c17244d` | SingleSelect (subType=0) | required · options: `38bd3e38-85c1-4645-a470-6f50ab8720a7`=Standard-rated · `abf766cc-682d-4c27-9efa-52d2e24189b8`=Zero-rated · `bb56396e-c0ad-4006-9946-174c2824031a`=Exempt · `5f03e574-907f-4fc5-a72b-ad68917efc4f`=Non-VAT |
| `rate_percent` | `6a8545468b36df988c17244e` | Number (subType=0) | required |
| `effective_from` | `6a8545468b36df988c17244f` | Date (subType=3) | required |
| `effective_to` | `6a8545468b36df988c172450` | Date (subType=3) |  |
| `is_taxable_base` | `6a85e5dd33560633b8cd9ec0` | Checkbox (subType=0) |  |
| `is_active` | `6a85e5f933560633b8cd9ec5` | Checkbox (subType=0) |  |

> `is_taxable_base` คือฟิลด์ที่ทำให้ **TC-16** ผ่าน — แยกฐานที่ต้องเสียภาษีออกจากฐานที่ไม่ต้อง เมื่อเอกสารเดียวมีหลายอัตราปนกัน

#### FR-05.2 อัตราภาษีหัก ณ ที่จ่าย — **Worksheet `AC_WHT_RATE`** · ws `6a8545688b36df988c172471` · alias `ac_wht_rate` · view `6a8545688b36df988c172475`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `rate_name` | `6a85456833560633b8cd6908` | Text (subType=0) | required · isTitle=True |
| `income_type` | `6a85456833560633b8cd6909` | Relation (subType=1) | required · → ws `6a85454133560633b8cd68e6` (AC_WHT_INCOME_TYPE) · sourceField = `6a85456833560633b8cd690a` |
| `rate_percent` | `6a85456833560633b8cd690b` | Number (subType=0) | required |
| `effective_from` | `6a85456833560633b8cd690c` | Date (subType=3) | required |
| `effective_to` | `6a85456833560633b8cd690d` | Date (subType=3) |  |
| `payee_legal_form` | `6a85e519055f2288c5b7768d` | Dropdown (subType=0) | optionset dataSource = `b97a1a08-78ab-4683-8472-837c48af4423` · options: `adf4bb5f-5a6b-4a99-b416-4d03ec5e295e`=Juristic person · `1aeb1a04-1957-4905-92d9-c506d8bbdccc`=Individual |
| `form_type` | `6a85e519055f2288c5b7768e` | Dropdown (subType=0) | optionset dataSource = `7b605ddd-bf7f-4837-9fa7-e6ae2153b2f8` · options: `d6c591cf-32c0-43d0-916d-803266f5e121`=P.P.30 · `614d5168-334c-4cb2-bd34-cda27357d134`=P.P.36 · `86d28c16-c735-403b-beb1-1573990188d6`=P.N.D.3 · `08e5c9c1-bcd7-4e28-9a08-ed0c028dc21b`=P.N.D.53 · `2b0971ed-7db0-4a2e-ba7b-e83d6b18a987`=P.N.D.54 |
| `is_active` | `6a85e519055f2288c5b7768f` | Checkbox (subType=0) |  |

#### FR-05.3 ประเภทเงินได้หัก ณ ที่จ่าย — **Worksheet `AC_WHT_INCOME_TYPE`** · ws `6a85454133560633b8cd68e6` · alias `ac_wht_income_type` · view `6a85454133560633b8cd68ea`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `type_code` | `6a8545411049edca1eecd84c` | Text (subType=0) | required · isTitle=True |
| `description_th` | `6a8545411049edca1eecd84d` | Text (subType=0) | required |
| `description_en` | `6a8545411049edca1eecd84e` | Text (subType=0) |  |
| `sort_order` | `6a8545411049edca1eecd84f` | Number (subType=0) |  |
| `form_type` | `6a85e538055f2288c5b77698` | Dropdown (subType=0) | optionset dataSource = `7b605ddd-bf7f-4837-9fa7-e6ae2153b2f8` · options: `d6c591cf-32c0-43d0-916d-803266f5e121`=P.P.30 · `614d5168-334c-4cb2-bd34-cda27357d134`=P.P.36 · `86d28c16-c735-403b-beb1-1573990188d6`=P.N.D.3 · `08e5c9c1-bcd7-4e28-9a08-ed0c028dc21b`=P.N.D.53 · `2b0971ed-7db0-4a2e-ba7b-e83d6b18a987`=P.N.D.54 |

#### FR-05.4 สินค้าและบริการ — **Worksheet `AC_ITEM`** · ws `6a8545a89b6999a714d26769` · alias `ac_item` · view `6a8545a89b6999a714d2676d`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `item_code` | `6a8545a81049edca1eecd8bc` | Text (subType 0) | required · **isTitle=True** |
| `name_th` | `6a8545a81049edca1eecd8bd` | Text (subType 0) | required |
| `name_en` | `6a8545a81049edca1eecd8be` | Text (subType 0) |  |
| `unit` | `6a8545a81049edca1eecd8bf` | Text (subType 0) | required |
| `vat_rate` | `6a8545a81049edca1eecd8c0` | Relation (subType 1) | required · → ws `6a8545469b6999a714d2673c` (AC_VAT_RATE) · sourceField `6a8545a81049edca1eecd8c1` |
| `wht_type` | `6a8545a81049edca1eecd8c2` | Relation (subType 1) | → ws `6a85454133560633b8cd68e6` (AC_WHT_INCOME_TYPE) · sourceField `6a8545a81049edca1eecd8c3` |
| `standard_price` | `6a8545a81049edca1eecd8c4` | Number (subType 0) |  |
| `revenue_account` | `6a8551af9b6999a714d268e0` | Relation (subType 1) | → ws `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a8551af9b6999a714d268e1` |
| `expense_account` | `6a8551af9b6999a714d268e2` | Relation (subType 1) | → ws `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a8551af9b6999a714d268e3` |
| `item_type` | `6a85e4cd055f2288c5b77685` | Dropdown (subType 0) | optionset `b6d21a09-f425-491c-9c2c-0c0d832a4ecf` · keys: `f9a1e0c2-6418-42f7-8afc-777e9fb8053a`=Goods · `b705d9f2-e0f5-44c1-8299-1e5fc621d1e8`=Service |
| `is_active` | `6a85e4cd055f2288c5b77686` | Checkbox (subType 0) |  |

#### FR-05.5 สกุลเงิน — **Worksheet `AC_CURRENCY`** · ws `6a8545261049edca1eecd818` · alias `ac_currency` · view `6a8545261049edca1eecd81c`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `currency_code` | `6a854527055f2288c5b741a6` | Text (subType 0) | required · **isTitle=True** |
| `name` | `6a854527055f2288c5b741a7` | Text (subType 0) | required |
| `symbol` | `6a854527055f2288c5b741a8` | Text (subType 0) |  |
| `decimals` | `6a854527055f2288c5b741a9` | Number (subType 0) | required |
| `is_base` | `6a85e6179b6999a714d2a400` | Checkbox (subType 0) |  |
| `is_active` | `6a85e6179b6999a714d2a401` | Checkbox (subType 0) |  |

#### FR-05.6 อัตราแลกเปลี่ยน — **Worksheet `AC_FX_RATE`** · ws `6a8545911049edca1eecd8a5` · alias `ac_fx_rate` · view `6a8545911049edca1eecd8a9`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `rate_key` | `6a854591055f2288c5b7420d` | Text (subType=0) | required · isTitle=True |
| `currency` | `6a854591055f2288c5b7420e` | Relation (subType=1) | required · → ws `6a8545261049edca1eecd818` · sourceField = `6a854591055f2288c5b7420f` |
| `rate_date` | `6a854591055f2288c5b74210` | Date (subType=3) | required |
| `rate` | `6a854591055f2288c5b74211` | Number (subType=0) | required |
| `source` | `6a854591055f2288c5b74212` | Text (subType=0) | required |
| `rate_type` | `6a85e55d9b6999a714d2a3f5` | Dropdown (subType=0) | optionset dataSource = `6dcb809e-06b3-4166-9ba4-b426ccc2b639` · options: `d5815116-73c7-4378-8222-139ca6f2d79d`=Buying · `3413a137-92a6-4dcd-80a5-5327f67a951f`=Selling · `a297fbff-e177-4de7-844a-b6eba96bc424`=Average · `d71fcd1b-a5e0-41b2-826a-1bbb9f759582`=Reference |

#### FR-05.7 ประเภทสินทรัพย์ — **Worksheet `AC_ASSET_CATEGORY`** · ws `6a8545948b36df988c17247c` · alias `ac_asset_category` · view `6a8545948b36df988c172480`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `category_name` | `6a8545941049edca1eecd8af` | Text (subType 0) | required · **isTitle=True** |
| `default_life_years` | `6a8545941049edca1eecd8b0` | Number (subType 0) | required |
| `asset_account` | `6a85519f33560633b8cd6a26` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a85519f33560633b8cd6a27` |
| `depr_expense_account` | `6a85519f33560633b8cd6a28` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a85519f33560633b8cd6a29` |
| `accum_depr_account` | `6a85519f33560633b8cd6a2a` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a85519f33560633b8cd6a2b` |
| `default_method` | `6a85e57c33560633b8cd9eba` | Dropdown (subType 0) | optionset `c66475a4-14fb-4156-990e-92163ee9c8ee` · keys: `ed9d0c63-0c76-4043-9257-bbc797ec6904`=Straight line · `4e88576a-ede3-4600-9c1e-04f0b5de65fe`=Declining balance |

| 🆕 ฟิลด์ที่ต้องสร้างเพิ่ม | type MCP | เหตุผล |
|---|---|---|
| 🆕 `AC_ASSET_CATEGORY.default_salvage_pct` | `Number` precision 2 | SDS ระบุมูลค่าซากเป็นดุลพินิจทางบัญชี (BR-12) แต่ยังไม่มีฟิลด์ |
| 🆕 `AC_ASSET_CATEGORY.gain_loss_account` | `Relation` → `ac_coa` | บัญชีกำไร/ขาดทุนจากการตัดจำหน่าย ใช้โดย WF-AC-21 |

#### FR-05.8 ช่องทางการจ่ายเงิน — **Worksheet `AC_PAYMENT_CHANNEL`** · ws `6a8545a19b6999a714d2675f` · alias `ac_payment_channel` · view `6a8545a19b6999a714d26763`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `channel_code` | `6a8545a1055f2288c5b74226` | Text (subType 0) | required · **isTitle=True** |
| `gl_account` | `6a8551ab9b6999a714d268d9` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a8551ab9b6999a714d268da` |
| `channel_name` | `6a85e597055f2288c5b7769e` | Dropdown (subType 0) | optionset `32bfb7c2-a519-4aa0-820a-f777b533e719` · keys: `90bb0b39-e86d-42a5-90c9-a0f7fad884ab`=Cash · `4bb5ba34-48da-45f6-8a39-03abbcc4107d`=Bank transfer · `2c443ee1-d84e-4141-94d7-31f76528c5d8`=Cheque |

**Form rules (ใช้ร่วมทุกตารางในกลุ่มนี้)**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-05.1 | Business Rule · validation | `effective_to` < `effective_from` | Block save (ใช้กับ AC_VAT_RATE, AC_WHT_RATE) |
| BR-05.2 | Business Rule · interaction | `vat_name` in (Zero-rated `abf766cc-…`, Exempt `bb56396e-…`, Non-VAT `5f03e574-…`) | `rate_percent` = 0 และ read-only |
| IX-05.1 | Unique index | `AC_VAT_RATE.vat_code` · `AC_ITEM.item_code` · `AC_CURRENCY.currency_code` | required ✓ ทั้งหมด |
| IX-05.2 | Unique index | (`AC_FX_RATE.currency`, `rate_date`, `rate_type`) | ⚠️ `rate_type` ไม่ required ⇒ ตั้ง required ก่อน |
| BR-05.3 | Business Rule · validation | มี `AC_CURRENCY.is_base` ติ๊กมากกว่า 1 record | ต้องกันด้วย workflow (Business Rule มองข้ามแถวอื่นไม่ได้) |

> 🔑 **หลักการที่ห้ามฝ่าฝืน:** อัตราภาษีและอัตราแลกเปลี่ยนต้องมีวันที่มีผลบังคับเสมอ · เอกสารเก่าต้อง**คงอัตราที่ใช้ตอนนั้นไว้** ⇒ workflow ต้องคัดลอกค่าอัตราลงบนบรรทัดเอกสาร ไม่ใช่ lookup แบบ sync ตลอด (ห้ามใช้ Foreign field สำหรับตัวเลขอัตรา — `AC_AP_LINE.wht_rate` ที่เป็น Number อยู่แล้วถูกต้อง)

**Definition of Done:** อัตรา VAT ครบ 4 ประเภท · ประเภทเงินได้หัก ณ ที่จ่ายครบตามที่ใช้จริง พร้อมผูกแบบยื่นถูกฉบับ · มีสกุลเงินฐาน 1 สกุล
**วิธี verify:** `get_record_list(ac_vat_rate)` = 5 ✓ · `get_record_list(ac_currency, filter is_base)` ต้องได้ 1 record
**Gap:** ยังไม่ตรวจจำนวน record ของ AC_WHT_RATE / AC_WHT_INCOME_TYPE / AC_ITEM / AC_CURRENCY / AC_FX_RATE / AC_ASSET_CATEGORY / AC_PAYMENT_CHANNEL

---

### FR-06 ใบสำคัญและบัญชีแยกประเภท 🔴 **แกนกลางของโมดูล**

**สถานะ: 🔶 ตารางครบ · มีใบสำคัญทดสอบ 4 ใบ · ⚠️ ไม่มี workflow ใดทำงาน (log มีแต่ `user-api`)**

#### FR-06.1 หัวใบสำคัญ — **Worksheet `AC_VOUCHER`** · ws `6a85fb2e9b6999a714d2a53d` · alias `ac_voucher` · view `6a85fb2e9b6999a714d2a541`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `description` | `6a85fb2e055f2288c5b77753` | Text (subType 0) | required |
| `voucher_date` | `6a85fb2e055f2288c5b77754` | Date (subType 3) | required |
| `journal` | `6a85fb2e055f2288c5b77755` | Relation (subType 1) | required · → ws `6a8434da33560633b8cd2efd` · sourceField `6a85fb2e055f2288c5b77756` |
| `voucher_type` | `6a85fb2e055f2288c5b77757` | Relation (subType 1) | required · → ws `6a8434dd9b6999a714d22e3d` · sourceField `6a85fb2e055f2288c5b77758` |
| `period` | `6a85fb2e055f2288c5b77759` | Relation (subType 1) | required · → ws `6a8434d5055f2288c5b6d4b8` · sourceField `6a85fb2e055f2288c5b7775a` |
| `currency` | `6a85fb2e055f2288c5b7775b` | Relation (subType 1) | required · → ws `6a8545261049edca1eecd818` · sourceField `6a85fb2e055f2288c5b7775c` |
| `fx_rate` | `6a85fb2e055f2288c5b7775d` | Number (subType 0) |  |
| `source_doc_id` | `6a85fb2e055f2288c5b7775e` | Text (subType 0) |  |
| `posted_flag` | `6a85fb2e055f2288c5b7775f` | Number (subType 0) |  |
| `approved_by` | `6a85fb2e055f2288c5b77760` | Collaborator (subType 0) |  |
| `posted_at` | `6a85fb2e055f2288c5b77761` | DateTime (subType 1) |  |
| AC_VOUCHER_LINE → alias `ac_voucher_line` ⚠️ | `6a85fb399b6999a714d2a558` | Relation (subType 2) | → ws `6a85fb3933560633b8cd9f40` (AC_VOUCHER_LINE) · sourceField `6a85fb399b6999a714d2a557` |
| `reversal_of` | `6a85fb489b6999a714d2a5cd` | Relation (subType 1) | → ws `6a85fb2e9b6999a714d2a53d` (self) · sourceField `6a85fb489b6999a714d2a5ce` |
| `reversing_vouchers` | `6a85fb489b6999a714d2a5ce` | Relation (subType 2) | → ws `6a85fb2e9b6999a714d2a53d` (self) · sourceField `6a85fb489b6999a714d2a5cd` |
| `source_doc_type` | `6a85fb7033560633b8cd9f56` | SingleSelect (subType 0) | options: `9167f8e3-be47-42fb-93d4-b5855e1cdcfd` = AC_AP · `41d6a7c8-8d13-430e-96be-9269cb9242a4` = AC_AR · `6dc4c5b9-5749-44bd-895c-bb0dc458d891` = AC_PAY · `d7a78710-41c5-4286-92ce-472ca7db6199` = AC_DEPR · `87c9789e-d222-411d-ae5d-51f2d29b7419` = AC_CLOSE · `ec6ec0cd-e223-4b5b-a6ea-1d70f2f45fcd` = Manual |
| `voucher_no` | `6a85ff5933560633b8cd9f83` | Text (subType 0) | **isTitle = True** |
| status → alias `status1` ⚠️ | `6a86016b1049edca1eed028a` | Dropdown (subType 0) | optionset (dataSource) `0bdd7e11-c2bc-44cb-a25a-34009a1436a2` · options: `3536165d-460c-4942-8bec-6f381209d8da` = Draft · `982090bd-bec8-4cec-a0e5-7b4de07d4d13` = Pending approval · `69d8e25d-e949-49a6-aba6-11e1732f59d1` = Approved · `a234503a-f4fd-4d8a-86c3-34a2d9ed219f` = Posted · `e0474c62-202d-4a41-98ff-7c4cf417eec8` = Cancelled · `8ce6c682-5c42-42f3-b6a9-62ea17a12205` = Reversed · **ระวัง: alias คือ `status1` ไม่ใช่ `status`** |
| `source_module` | `6a86021833560633b8cd9fb1` | Dropdown (subType 0) | optionset (dataSource) `098ff000-5d07-4c73-9622-c37e691f9f75` · options: `3f9b4640-60f2-4387-8c90-7308a66579ed` = Manual · `add7f979-fa25-4dda-8a1d-6ca4de96c53d` = Scan · `d07bebc6-0e9a-4b76-8fbe-fcb1ac87bda1` = Procurement · `c2b119a5-2d34-4af6-905d-ed52e76869d1` = Finance · `901a32f6-b514-431d-820f-0dd88248cbd8` = Asset · `914f5226-dc4c-4572-bd4d-18bb278414b5` = Payroll · `23db6df8-38f9-4a85-ad34-87b20386d265` = Tax · `5d980264-7b9a-49d9-9c6c-2e6daa1946e7` = Period close |
| `attachments` | `6a86021833560633b8cd9fb2` | Attachment (subType 3) |  |
| `total_debit` | `6a8603f4055f2288c5b777d2` | Rollup (subType 5) | rolls up relation field `$6a85fb399b6999a714d2a558$` (AC_VOUCHER_LINE) · sourceField `6a85fb399b6999a714d2a55b` (debit) |
| `total_credit` | `6a8604c08b36df988c176286` | Rollup (subType 5) | rolls up relation field `$6a85fb399b6999a714d2a558$` (AC_VOUCHER_LINE) · sourceField `6a85fb399b6999a714d2a55c` (credit) |
| `balance_diff` | `6a860ae8055f2288c5b777f1` | Formula (subType 1) | expression: `$6a8603f4055f2288c5b777d2$-$6a8604c08b36df988c176286$` (total_debit − total_credit) |
| period_status_ref — ⚠️ **ไม่มี alias** อ้างด้วย field id เท่านั้น | `6a8b2f728b36df988c17f00f` | Lookup (subType 0) | lookup ผ่านฟิลด์ `$6a85fb2e055f2288c5b77759$` (period) · sourceField `6a851f70055f2288c5b73edf` · options: `f662571c-3de0-4e4c-9828-9172e337d223` = Open · `b2986cb5-59db-4fdc-87ed-d57a38201c6a` = Soft-closed · `38392e32-7c09-4339-a9b4-81a9f53eba0a` = Permanently locked |
| fiscal_year_ref — ⚠️ **ไม่มี alias** อ้างด้วย field id เท่านั้น | `6a8b305633560633b8ce2c5c` | Lookup (subType 0) | lookup ผ่านฟิลด์ `$6a85fb2e055f2288c5b77759$` (period) · sourceField `6a8434d58b36df988c16ed66` · ไม่มี options |

> 🔴 **`status` มี alias เป็น `status1`** — เขียนผิดจะเงียบและไม่มี error
> 🔴 **`period_status_ref` และ `fiscal_year_ref` ไม่มี alias** — อ้างด้วย field id เท่านั้น (`6a8b2f728b36df988c17f00f`, `6a8b305633560633b8ce2c5c`) · ทั้งสองเป็น Lookup ผ่าน `period` ⇒ **ใช้ตรวจสถานะงวดใน Branch node ได้โดยไม่ต้อง Get Single Record**
> ✅ `total_debit` / `total_credit` เป็น **Rollup** และ `balance_diff` เป็น **Formula** = `total_debit − total_credit` — ตรวจดุลได้ทันทีโดยไม่ต้องคำนวณใน workflow (บังคับ TC-01)
> ⚠️ `balance_diff` เป็น Formula field ซึ่ง playbook เตือนว่า dialog ไม่เสถียร — **ของเดิมใช้ได้อยู่ ห้ามแตะ** ถ้าต้องแก้ให้บันทึกลง `13-ID-Registry-AC.md` §1 ทันทีเพราะ field id จะเปลี่ยน

| ฟิลด์ที่สร้างแล้ว 26 ส.ค. 2569 | Field ID | type | เหตุผล |
|---|---|---|---|
| `approver_user` `biz_vch_approver_user` | `6a8ea405ae2a0e3743a084ee` | Collaborator subType 0 | ⚠️ **สร้างไว้แต่ยังไม่ได้ใช้** — ดูกับดัก OrgRole ใน `02-BuildSpec-FRS.md` §0 · เก็บไว้เผื่อเปลี่ยนไปเก็บผู้อนุมัติเป็นตัวบุคคล |
| `approver_orgrole` `biz_vch_approver_orgrole` | `6a8ea8fa8b6633ef76f0fc69` | Role (OrgRole) | ⚠️ เช่นเดียวกัน — เขียนค่าจากกฎไม่ได้ ปัจจุบันสายอนุมัติอ้างกฎโดยตรงแทน |
| `approval_level` `biz_vch_approval_level` | `6a8ea405ae2a0e3743a084ef` | Number precision 0 | ระดับอนุมัติปัจจุบัน — WF-AC-01 เขียน 1 เมื่อส่งขออนุมัติ |
| `submitted_flag` `biz_vch_submitted_flag` | `6a8ea405ae2a0e3743a084f0` | Number precision 0 · **default 0** | 🔴 ธงกันยิงซ้ำ · **ต้องมีค่า 0 ไม่ใช่ว่าง** มิฉะนั้นเงื่อนไข `ne 1` ไม่ผ่าน |
| `approved_at` `biz_vch_approved_at` | `6a8ea405ae2a0e3743a084f1` | DateTime subType 1 | เวลาอนุมัติ/ตีกลับ เขียนโดย node ในสายอนุมัติ |
| `reject_reason` `biz_vch_reject_reason` | `6a8ea405ae2a0e3743a084f2` | Text (multiline) | เหตุผลการตีกลับ — WF-AC-01 เขียนพร้อมตัวเลขผลต่างและเวลา |
| `total_debit_thb` `biz_vch_total_debit_thb` | `6a8ea405ae2a0e3743a084f3` | Number | ยอดเงินบาท ⬜ ยังไม่มี workflow เขียน |
| `total_credit_thb` `biz_vch_total_credit_thb` | `6a8ea405ae2a0e3743a084f4` | Number | ยอดเงินบาท ⬜ ยังไม่มี workflow เขียน |

> ✅ `posted_flag` `6a85fb2e055f2288c5b7775f` (มีอยู่เดิม) ถูกตั้ง **default = 0** และ backfill ให้ record เดิมครบแล้ว

#### FR-06.2 บรรทัดใบสำคัญ — **Worksheet `AC_VOUCHER_LINE`** · ws `6a85fb3933560633b8cd9f40` · alias `ac_voucher_line` · view `6a85fb3933560633b8cd9f44`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `line_description` | `6a85fb399b6999a714d2a555` | Text (subType 0) | **isTitle = True** |
| `line_no` | `6a85fb399b6999a714d2a556` | Number (subType 0) | required |
| `voucher` | `6a85fb399b6999a714d2a557` | Relation (subType 1) | required · → ws `6a85fb2e9b6999a714d2a53d` (AC_VOUCHER) · sourceField `6a85fb399b6999a714d2a558` |
| `account` | `6a85fb399b6999a714d2a559` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` · sourceField `6a85fb399b6999a714d2a55a` |
| `debit` | `6a85fb399b6999a714d2a55b` | Number (subType 0) |  |
| `credit` | `6a85fb399b6999a714d2a55c` | Number (subType 0) |  |
| `cost_center` | `6a85fb399b6999a714d2a55d` | Relation (subType 1) | → ws `6a85452b9b6999a714d26720` · sourceField `6a85fb399b6999a714d2a55e` |
| `fund` | `6a85fb399b6999a714d2a55f` | Relation (subType 1) | → ws `6a85453033560633b8cd68dc` · sourceField `6a85fb399b6999a714d2a560` |
| `project` | `6a85fb399b6999a714d2a561` | Relation (subType 1) | → ws `6a854534055f2288c5b741ce` · sourceField `6a85fb399b6999a714d2a562` |
| `partner` | `6a85fb399b6999a714d2a563` | Relation (subType 1) | → ws `6a85457033560633b8cd6920` · sourceField `6a85fb399b6999a714d2a564` |
| `budget_ref` | `6a85fb399b6999a714d2a565` | Text (subType 0) |  |

#### FR-06.3 บัญชีแยกประเภท — **Worksheet `AC_GL`** · ws `6a85fb4133560633b8cd9f4a` · alias `ac_gl` · view `6a85fb4133560633b8cd9f4e`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `gl_id` | `6a85fb419b6999a714d2a589` | Text (subType 0) | **isTitle = True** |
| `posting_date` | `6a85fb419b6999a714d2a58a` | Date (subType 3) | required |
| `fiscal_year` | `6a85fb419b6999a714d2a58b` | Number (subType 0) | required |
| `journal` | `6a85fb419b6999a714d2a58c` | Relation (subType 1) | required · → ws `6a8434da33560633b8cd2efd` · sourceField `6a85fb419b6999a714d2a58d` |
| `voucher` | `6a85fb419b6999a714d2a58e` | Relation (subType 1) | required · → ws `6a85fb2e9b6999a714d2a53d` (AC_VOUCHER) · sourceField `6a85fb419b6999a714d2a58f` |
| `period` | `6a85fb419b6999a714d2a590` | Relation (subType 1) | required · → ws `6a8434d5055f2288c5b6d4b8` · sourceField `6a85fb419b6999a714d2a591` |
| `account` | `6a85fb419b6999a714d2a592` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` · sourceField `6a85fb419b6999a714d2a593` |
| `debit` | `6a85fb419b6999a714d2a594` | Number (subType 0) |  |
| `credit` | `6a85fb419b6999a714d2a595` | Number (subType 0) |  |
| `debit_thb` | `6a85fb419b6999a714d2a596` | Number (subType 0) |  |
| `credit_thb` | `6a85fb419b6999a714d2a597` | Number (subType 0) |  |
| `cost_center` | `6a85fb419b6999a714d2a598` | Relation (subType 1) | → ws `6a85452b9b6999a714d26720` · sourceField `6a85fb419b6999a714d2a599` |
| `fund` | `6a85fb419b6999a714d2a59a` | Relation (subType 1) | → ws `6a85453033560633b8cd68dc` · sourceField `6a85fb419b6999a714d2a59b` |
| `project` | `6a85fb419b6999a714d2a59c` | Relation (subType 1) | → ws `6a854534055f2288c5b741ce` · sourceField `6a85fb419b6999a714d2a59d` |
| `partner` | `6a85fb419b6999a714d2a59e` | Relation (subType 1) | → ws `6a85457033560633b8cd6920` · sourceField `6a85fb419b6999a714d2a59f` |
| `movement_seq` | `6a85fe6433560633b8cd9f79` | AutoNumber (subType 0) |  |
| `is_reversed` | `6a85fe6433560633b8cd9f7a` | Checkbox (subType 0) |  |
| `gl_no` | `6a860c4d1049edca1eed02d6` | AutoNumber (subType 0) |  |
| `voucher_row_id` | `6a8a93e01049edca1eed8e65` | Text (subType 2) |  |

> ✅ `movement_seq` เป็น **AutoNumber** = ลำดับการเคลื่อนไหวต่อเนื่องตาม NFR-05 · `voucher_row_id` (Text subType 2) ใช้เป็นกุญแจกันผ่านรายการซ้ำใน WF-AC-02

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-06.1 | Business Rule · validation | `balance_diff` ≠ 0 | **Block save เมื่อ `status1` = Pending approval** — บังคับ TC-01 (ตั้ง re-validate on server ☑) |
| BR-06.2 | Business Rule · validation | `AC_VOUCHER_LINE.debit` > 0 **และ** `credit` > 0 บนบรรทัดเดียวกัน | Block save "หนึ่งบรรทัดลงได้ด้านเดียว" |
| BR-06.3 | Business Rule · validation | `debit` = 0 และ `credit` = 0 | Block save |
| BR-06.4 | Business Rule · interaction | `status1` ≠ Draft | **Set all fields read-only** (ปุ่ม/workflow ยังเขียนได้) |
| BR-06.5 | Business Rule · interaction | `account.require_cost_center` ติ๊ก | `cost_center` เป็นฟิลด์บังคับ (ทำเช่นเดียวกับ fund / project / partner) |
| BR-06.6 | Business Rule · interaction (AC_GL) | เสมอ | **Set all read-only + Lock record** — BR-02 บังคับ TC-06 |
| IX-06.1 | Unique index | `AC_VOUCHER.voucher_no` | ⚠️ ปัจจุบัน `required=False` ⇒ **ตั้ง required ก่อน** (ค่าว่างได้แค่แถวเดียว) |
| IX-06.2 | Unique index | (`AC_GL.voucher_row_id`, `AC_GL.movement_seq`) | กันผ่านรายการซ้ำระดับข้อมูล — คู่กับการตรวจใน WF-AC-02 ขั้นที่ 1 |
| RU-06.1 | Rollup (มีแล้ว) | `AC_VOUCHER_LINE` → Sum(`debit`) / Sum(`credit`) | `total_debit` `total_credit` ✅ มีแล้ว |
| DV-06.1 | Dynamic default | `voucher_date` ← วันที่ปัจจุบัน · `currency` ← สกุลเงินฐาน | ลดการคีย์ |

**Verify form rules:** Role Debugging → AC-R1 → เปิด AC_VOUCHER ที่ `status1` = Posted → ทุกฟิลด์ต้องเป็น read-only และไม่มีปุ่มลบ

**State machine (`status1` · optionset `OS_DOC_STATUS`)**

| จาก | ไป | ขับด้วย | เงื่อนไข / ผู้มีสิทธิ์ |
|---|---|---|---|
| Draft `3536165d-…` | Pending approval `982090bd-…` | **ปุ่ม "ส่งอนุมัติ"** (`updateCurrentRecord`) → WF-AC-01 รับช่วง | `balance_diff` = 0 · งวดเปิด · AC-R1 |
| Pending approval | Approved `69d8e25d-…` | **Approve node · Data Update tab (after approves)** ใน WF-AC-01 | ครบทุกระดับตาม `AC_APPROVAL_RULE` |
| Pending approval | Draft | **Approve node · Data Update tab (when rejects)** + เขียน `reject_reason` | ผู้อนุมัติตีกลับ |
| Approved | Posted `a234503a-…` | **WF-AC-02** (Update Record) | ผ่านรายการสำเร็จ · เขียน `posted_at`, `posted_flag`=1 |
| Draft / Pending approval | Cancelled `e0474c62-…` | **ปุ่ม "ยกเลิกใบสำคัญ"** | AC-R1 (ของตนเอง) / AC-R2 |
| Posted | Reversed `8ce6c682-…` | **WF-AC-10** ผ่านปุ่ม "กลับรายการ" | AC-R3 เท่านั้น · สร้างใบสำคัญกลับรายการผูกด้วย `reversal_of` |

> **ฟิลด์ `status1` ต้องตั้งเป็น read-only บนฟอร์ม** — ทุก transition ขับด้วยปุ่มหรือ workflow ทั้งหมด

**Custom Actions ที่ผูก:** ส่งอนุมัติ · ยกเลิกใบสำคัญ · กลับรายการ (ดู `13-ID-Registry-AC.md` §1.6)
**Workflow ที่ผูก:** WF-AC-01 (อนุมัติ) · WF-AC-02 (ผ่านรายการ) · WF-AC-10 (กลับรายการ) — ดู `15-Workflow-Catalog-AC.md` §3

**Definition of Done**

1. ใบสำคัญที่เดบิต ≠ เครดิต ส่งอนุมัติไม่ได้ (TC-01)
2. ใบสำคัญในงวดที่ปิดแล้วบันทึกไม่ได้ (TC-02)
3. ใบสำคัญ > 1,000,000 เดินสายอนุมัติครบ 3 ระดับตามลำดับ (TC-04)
4. ผู้จัดทำอนุมัติเอกสารตนเองไม่ได้ (TC-05)
5. ไม่มีบทบาทใดแก้ AC_GL ได้ (TC-06)
6. ผ่านรายการซ้ำไม่เกิด GL ซ้ำ — ยิง `update_record` เปลี่ยนเป็น Approved สองครั้ง แล้วนับ AC_GL ต้องเท่าเดิม
7. งบทดลองมีเดบิตเท่าเครดิต (TC-12)

**วิธี verify**

| ต้องรู้ | เรียก | ผลที่คาด |
|---|---|---|
| WF-AC-01 ทำงาน | `get_record_details(ac_voucher, <rowid>, includeSystemFields:true)` | `_updatedBy` = **`user-workflow`** หลังเขียน `status1` — ⚠️ ห้ามใช้ operator จาก `get_record_logs` (ผลลบลวง) |
| approval ถูกส่งจริง | `get_approval_list_by_row(ac_voucher, <rowid>)` | มี instance พร้อมผู้รับผิดชอบ |
| WF-AC-02 สร้าง GL | `get_record_list(ac_gl, filter voucher_row_id = <rowid>, includeTotalCount)` | จำนวน = จำนวนบรรทัดของใบสำคัญ |
| ไม่ผ่านรายการซ้ำ | ยิง `update_record` ซ้ำ แล้วนับใหม่ | จำนวนเท่าเดิม |

**Pitfall / Gap**

- 🔴 ยังไม่มีฟิลด์ `approver_user` (Collaborator) ⇒ **สร้าง Approve node ไม่ได้เลย** — เป็นงานแรกของ Phase 2
- 🔴 ยังไม่มี workflow ใด ๆ — ใบสำคัญ 4 ใบที่มีอยู่ถูกสร้างด้วย API ล้วน
- ⚠️ `AC_VOUCHER.voucher_no` ยัง `required=False` และไม่มี unique index ⇒ เลขที่ซ้ำได้
- ⚠️ WF-AC-02 ต้องวนสร้าง GL รายบรรทัด แต่ **node Loop สร้างผ่าน MCP ไม่ได้** — ดูทางเลี่ยงใน `15-Workflow-Catalog-AC.md` §3

---

### FR-07 ค่าใช้จ่ายและเจ้าหนี้ 🔴 **มีตารางแต่ขาดฟิลด์สำคัญเกือบทั้งหมด**

**สถานะ: 🔶 ตารางครบ · 0 record · ❌ ไม่มีฟิลด์สถานะ ไม่มียอดรวม ไม่มียอดคงค้าง**

#### FR-07.1 เอกสารตั้งหนี้ — **Worksheet `AC_AP`** · ws `6a8673d61049edca1eed0638` · alias `ac_ap` · view `6a8673d61049edca1eed063c`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `ap_no` | `6a8673d69b6999a714d2a9bd` | Text (subType 0) | **isTitle=True** |
| `partner` | `6a8673d69b6999a714d2a9be` | Relation (subType 1) | required · → ws `6a85457033560633b8cd6920` · sourceField `6a8673d69b6999a714d2a9bf` |
| `invoice_no` | `6a8673d69b6999a714d2a9c0` | Text (subType 0) | required |
| `invoice_date` | `6a8673d69b6999a714d2a9c1` | Date (subType 3) | required |
| `due_date` | `6a8673d69b6999a714d2a9c2` | Date (subType 3) | required |
| `currency` | `6a8673d69b6999a714d2a9c3` | Relation (subType 1) | required · → ws `6a8545261049edca1eecd818` · sourceField `6a8673d69b6999a714d2a9c4` |
| `fx_rate` | `6a8673d69b6999a714d2a9c5` | Number (subType 0) |  |
| `project` | `6a8673d69b6999a714d2a9c6` | Relation (subType 1) | → ws `6a854534055f2288c5b741ce` · sourceField `6a8673d69b6999a714d2a9c7` |
| `reference_no` | `6a8673d69b6999a714d2a9c8` | Text (subType 0) |  |
| `po_ref` | `6a8673d69b6999a714d2a9c9` | Text (subType 0) |  |
| `gr_ref` | `6a8673d69b6999a714d2a9ca` | Text (subType 0) |  |
| `doc_discount` | `6a8673d69b6999a714d2a9cb` | Number (subType 0) |  |
| `voucher` | `6a8673d69b6999a714d2a9cc` | Relation (subType 1) | → ws `6a85fb2e9b6999a714d2a53d` · sourceField `6a8673d69b6999a714d2a9cd` |
| AC_AP_LINE — ⚠️ **ไม่มี alias** อ้างด้วย field id เท่านั้น | `6a8673e78b36df988c176b84` | Relation (subType 2) | → ws `6a8673e78b36df988c176b77` · sourceField `6a8673e78b36df988c176b83` |
| AC_PAY_LINE — ⚠️ **ไม่มี alias** อ้างด้วย field id เท่านั้น | `6a8677d71049edca1eed06ff` | Relation (subType 2) | → ws `6a8677d7055f2288c5b77d12` · sourceField `6a8677d71049edca1eed06fe` |

> 🔴 **ตารางนี้ยังบันทึกเอกสารตั้งหนี้ให้ครบตามข้อกำหนดไม่ได้** — ไม่มีสถานะ ไม่มียอดรวม ไม่มียอดคงค้าง ไม่มีงวดบัญชี ไม่มีการตั้งค่าเอกสาร

| ✅ ฟิลด์ที่สร้างแล้ว 26 ส.ค. 2569 | Field ID | type · subType | ผูกกับ / หมายเหตุ |
|---|---|---|---|
| `ap_status` `biz_ap_status` | `6a8ead08ae2a0e3743a0b1c3` | Dropdown | ✅ **ผูกกับ `OS_AP_STATUS` `9f29af16-…` แล้ว** — key ตาม `13-ID-Registry-AC.md` §1.3 |
| `doc_type` `biz_ap_doc_type` | `6a8ead2f9762533b5b716fa6` | Relation subType 1 | → AC_DOC_TYPE `6a8434dd9b6999a714d22e3d` |
| `period` `biz_ap_period` | `6a8ead2f9762533b5b716fa8` | Relation subType 1 | → AC_PERIOD `6a8434d5055f2288c5b6d4b8` · บังคับ BR-03 |
| `doc_setting` `biz_ap_doc_setting` | `6a8ead2f9762533b5b716faa` | Relation subType 1 | → AC_DOC_SETTING `6a8434f69b6999a714d22e75` |
| `price_basis` `biz_ap_price_basis` | `6a8ead2f9762533b5b716fac` | Dropdown | → `OS_PRICE_BASIS` `abd98ad7-…` · บังคับ **TC-17** |
| `taxable_base` `biz_ap_taxable_base` | `6a8ead2f9762533b5b716fad` | Number | ฐานที่ต้องเสีย VAT — workflow เขียน · **TC-16** |
| `non_taxable_base` `biz_ap_non_taxable_base` | `6a8ead2f9762533b5b716fae` | Number | ฐานที่ไม่ต้องเสีย VAT |
| `vat_amount` `biz_ap_vat_amount` | `6a8ead2f9762533b5b716faf` | Number | |
| `wht_amount` `biz_ap_wht_amount` | `6a8ead2f9762533b5b716fb0` | Number | |
| `total_amount` `biz_ap_total_amount` | `6a8ead2f9762533b5b716fb1` | Number | |
| `net_payable` `biz_ap_net_payable` | `6a8ead2f9762533b5b716fb2` | Number | total − wht |
| `paid_amount` `biz_ap_paid_amount` | `6a8ead2f9762533b5b716fb3` | Number · **default 0** | WF-AC-04 เขียน |
| `outstanding` `biz_ap_outstanding` | `6a8ead2f9762533b5b716fb4` | Number | net_payable − paid_amount · บังคับ **TC-24** |
| `submitted_flag` `biz_ap_submitted_flag` | `6a8ead3bae2a0e3743a0b209` | Number · **default 0** | 🔴 ธงกันยิงซ้ำ — ต้องมีค่า 0 ไม่ใช่ว่าง |
| `recognised_flag` `biz_ap_recognised_flag` | `6a8ead3bae2a0e3743a0b20a` | Number · **default 0** | กันรับรู้หนี้สินซ้ำ |
| `paid_flag` `biz_ap_paid_flag` | `6a8ead3bae2a0e3743a0b20b` | Number · **default 0** | กันตัดชำระซ้ำ |
| `approval_level` `biz_ap_approval_level` | `6a8ead3bae2a0e3743a0b20c` | Number · **default 0** | ระดับอนุมัติปัจจุบัน |
| `reject_reason` `biz_ap_reject_reason` | `6a8ead3bae2a0e3743a0b20d` | Text (multiline) | |
| `dup_key` `biz_ap_dup_key` | `6a8ead3bae2a0e3743a0b20e` | Text | คีย์กันซ้ำ = partner_code + invoice_no · ใช้ทำ unique index (IX-07.1) |
| `duplicate_justification` `biz_ap_duplicate_justification` | `6a8ead3bae2a0e3743a0b20f` | Text (multiline) | บังคับ **TC-09 / BR-22** |
| `recognised_at` `biz_ap_recognised_at` | `6a8ead3bae2a0e3743a0b210` | DateTime subType 1 | เขียนโดย workflow |

> ⬜ **ยังไม่สร้าง (เลื่อนไป Phase 11):** ฟิลด์รองรับการสแกน `scan_file` `extraction_confidence` `low_confidence_fields` `confirmed_flag` `confirmed_by` `confirmed_at`
> ✅ **ไม่ต้องมี `approver_user` บน AC_AP** — บทเรียนจาก WF-AC-01: ให้สายอนุมัติหากฎเองภายใน approval_block แล้วอ้างฟิลด์ OrgRole ของกฎตรง ๆ

> ⚠️ **`taxable_base` … `outstanding` เป็น Rollup ไม่ได้ทั้งหมด** เพราะ rollup รองรับ filter คงที่เท่านั้น แต่ฐาน VAT ต้องกรองตาม `AC_VAT_RATE.is_taxable_base` ของแต่ละบรรทัด ⇒ **ให้ workflow คำนวณและเขียนลง Number field** (WF-AC-03 / WF-AC-13)

#### FR-07.2 บรรทัดค่าใช้จ่าย — **Worksheet `AC_AP_LINE`** · ws `6a8673e78b36df988c176b77` · alias `ac_ap_line` · view `6a8673e78b36df988c176b7b`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `description` | `6a8673e78b36df988c176b81` | Text (subType 0) | required · **isTitle=True** |
| `line_no` | `6a8673e78b36df988c176b82` | Number (subType 0) | required |
| `ap` | `6a8673e78b36df988c176b83` | Relation (subType 1) | required · → ws `6a8673d61049edca1eed0638` (AC_AP) · sourceField `6a8673e78b36df988c176b84` |
| `item` | `6a8673e78b36df988c176b85` | Relation (subType 1) | → ws `6a8545a89b6999a714d26769` · sourceField `6a8673e78b36df988c176b86` |
| `account` | `6a8673e78b36df988c176b87` | Relation (subType 1) | required · → ws `6a85516e1049edca1eecd9b7` · sourceField `6a8673e78b36df988c176b88` |
| `qty` | `6a8673e78b36df988c176b89` | Number (subType 0) | required |
| `unit` | `6a8673e78b36df988c176b8a` | Text (subType 0) | required |
| `unit_price` | `6a8673e78b36df988c176b8b` | Number (subType 0) | required |
| `discount` | `6a8673e78b36df988c176b8c` | Number (subType 0) |  |
| `vat_rate` | `6a8673e78b36df988c176b8d` | Relation (subType 1) | required · → ws `6a8545469b6999a714d2673c` · sourceField `6a8673e78b36df988c176b8e` |
| `wht_type` | `6a8673e78b36df988c176b8f` | Relation (subType 1) | → ws `6a85454133560633b8cd68e6` · sourceField `6a8673e78b36df988c176b90` |
| `wht_rate` | `6a8673e78b36df988c176b91` | Number (subType 0) |  |
| `cost_center` | `6a8673e78b36df988c176b92` | Relation (subType 1) | → ws `6a85452b9b6999a714d26720` · sourceField `6a8673e78b36df988c176b93` |
| `fund` | `6a8673e78b36df988c176b94` | Relation (subType 1) | → ws `6a85453033560633b8cd68dc` · sourceField `6a8673e78b36df988c176b95` |
| `project` | `6a8673e78b36df988c176b96` | Relation (subType 1) | → ws `6a854534055f2288c5b741ce` · sourceField `6a8673e78b36df988c176b97` |
| `budget_ref` | `6a8673e78b36df988c176b98` | Text (subType 0) |  |

| ✅ ฟิลด์ที่สร้างแล้วบน AC_AP_LINE | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `line_amount` `biz_apl_line_amount` | `6a8ead448b6633ef76f12007` | Number | qty × unit_price − discount |
| `line_taxable_base` `biz_apl_line_taxable_base` | `6a8ead448b6633ef76f12008` | Number | 0 เมื่อ `vat_rate.is_taxable_base` ไม่ติ๊ก |
| `line_vat` `biz_apl_line_vat` | `6a8ead448b6633ef76f12009` | Number | |
| `wht_base` `biz_apl_wht_base` | `6a8ead448b6633ef76f1200a` | Number | **ต่างจากฐาน VAT** (BR-07) |
| `line_wht` `biz_apl_line_wht` | `6a8ead448b6633ef76f1200b` | Number | |
| `vat_rate_percent` `biz_apl_vat_rate_percent` | `6a8ead448b6633ef76f1200c` | Number | **สำเนาอัตราที่ใช้จริง** — ห้าม lookup แบบ sync |
| `wht_borne_by` `biz_apl_wht_borne_by` | `6a8ead448b6633ef76f1200d` | Dropdown | → `OS_WHT_BORNE_BY` `ce278c49-…` · บังคับ **TC-18** |

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-07.1 | Business Rule · interaction | `ap_status` ≠ Draft | Set all read-only |
| BR-07.2 | Business Rule · validation | `AC_AP_LINE.qty` ≤ 0 หรือ `unit_price` < 0 | Block save |
| BR-07.3 | Business Rule · validation | `discount` > `qty × unit_price` | Block save |
| BR-07.4 | Business Rule · validation | `due_date` < `invoice_date` | Block save |
| BR-07.5 | Business Rule · interaction | `wht_borne_by` in (Payer …) | แสดงข้อความเตือนว่าฐานจะถูก gross-up |
| DV-07.1 | Dynamic default · Other field | `AC_AP_LINE.account` ← `item.expense_account` · `vat_rate` ← `item.vat_rate` · `wht_type` ← `item.wht_type` · `unit` ← `item.unit` | ดึงตอนสร้างแล้วล็อก — **ห้ามใช้ Foreign field** เพราะแก้ item ย้อนหลังจะทำให้เอกสารเก่าเปลี่ยน |
| DV-07.2 | Dynamic default · Other field | `AC_AP.currency` ← สกุลเงินฐาน · `due_date` ← `invoice_date` + `partner.credit_days` | ⚠️ การบวกวันต้องทำด้วย workflow (dynamic default บวกวันไม่ได้) |
| IX-07.1 | Unique index | (`AC_AP.dup_key`) | 🔴 บังคับ BR-22 / TC-09 · `dup_key` ต้อง required และเขียนโดย workflow ก่อน save ⇒ **ถ้าทำไม่ได้ ให้ใช้ workflow กันซ้ำ: `Query worksheet` → Branch → Terminate** |

**State machine (`ap_status` · `OS_AP_STATUS` — 🆕 ยังไม่มีฟิลด์)**

| จาก | ไป | ขับด้วย |
|---|---|---|
| Draft `e10952c6-…` | Pending approval `35be3f29-…` | ปุ่ม "ส่งตั้งหนี้เพื่ออนุมัติ" → WF-AC-01 (เวอร์ชัน AP) |
| Pending approval | Recognised `ffca5173-…` | Approve node Data Update → แล้ว WF-AC-03 สร้างใบสำคัญและผ่านรายการ |
| Recognised | Partially paid `b8914358-…` | **WF-AC-04** เมื่อ `paid_amount` > 0 และ < `net_payable` |
| Partially paid / Recognised | Fully paid `7c3abf94-…` | **WF-AC-04** เมื่อ `outstanding` = 0 |
| Draft / Pending approval | Cancelled `60a0ca22-…` | ปุ่ม "ยกเลิก" |

**DoD:** ตั้งหนี้ที่มีบรรทัดอัตราปกติ + ศูนย์ + ยกเว้นปนกัน แยกฐานถูกต้องและคิด VAT เฉพาะฐานที่ต้องเสีย (TC-16) · เอกสารเดียวกันแบบราคารวมภาษีให้ยอด GL เท่ากับแบบแยกภาษี (TC-17) · กรณีผู้จ่ายออกภาษีแทน ฐานถูก gross-up และใบรับรองตรงกับ GL (TC-18) · ใบแจ้งหนี้ซ้ำถูกเตือนและบังคับให้ระบุเหตุผล (TC-09)
**วิธี verify:** `create_record(ac_ap)` + 3 บรรทัดต่างอัตรา → อ่าน `taxable_base`, `non_taxable_base`, `vat_amount` กลับ และ `get_record_details(includeSystemFields:true)._updatedBy` ต้องขึ้น `user-workflow` (⚠️ ไม่ใช่ operator จาก `get_record_logs` — ให้ผลลบลวง)
**Gap:** 🔴 ต้องสร้าง **17 ฟิลด์บน AC_AP + 7 ฟิลด์บน AC_AP_LINE** ก่อนเริ่ม workflow ใด ๆ ของ FR-07

---

### FR-08 วงจรการจ่ายเงิน

**สถานะ: 🔶 ตารางครบ 4 ตาราง · ❌ ไม่มีฟิลด์สถานะและยอดรวมทุกตาราง**

#### FR-08.1 คำขอเบิกจ่าย — **Worksheet `AC_PAY_REQ`** · ws `6a8677b19b6999a714d2aa83` · alias `ac_pay_req` · view `6a8677b19b6999a714d2aa87`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `req_no` | `6a8677b18b36df988c176cb1` | Text (subType 0) | **isTitle=True** |
| `request_reason` | `6a8677b18b36df988c176cb2` | Text (subType 0) | required |
| `requester` | `6a8677b18b36df988c176cb3` | Collaborator (subType 0) |  |
| `approvers` | `6a8677b18b36df988c176cb4` | Collaborator (subType 1) | subType 1 = multi-collaborator |
| `documents` | `6a8677b18b36df988c176cb5` | Relation (subType 2) | → ws `6a8673d61049edca1eed0638` (AC_AP) · sourceField `6a8677b18b36df988c176cb6` |
| `required_pay_date` | `6a8677b18b36df988c176cb7` | Date (subType 3) |  |

| ✅ ฟิลด์ที่สร้างแล้ว | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `req_status` `biz_preq_status` | `6a8ead839762533b5b717035` | Dropdown | → **`OS_PAYREQ_STATUS` `4ab44bf7-1c5f-48c1-9669-8ac180dc4fc0`** (สร้างใหม่ 26 ส.ค.) |
| `request_amount` `biz_preq_amount` | `6a8ead839762533b5b717036` | Number | ยอดที่ขอเบิกรวม |
| `submitted_flag` `biz_preq_submitted_flag` | `6a8ead839762533b5b717037` | Number · default 0 | |
| `paid_flag` `biz_preq_paid_flag` | `6a8ead839762533b5b717038` | Number · default 0 | กันสร้างใบสำคัญจ่ายซ้ำ |
| `approval_level` `biz_preq_approval_level` | `6a8ead839762533b5b717039` | Number · default 0 | |
| `reject_reason` `biz_preq_reject_reason` | `6a8ead839762533b5b71703a` | Text (multiline) | |
| `doc_type` `biz_preq_doc_type` | `6a8ead839762533b5b71703b` | Relation subType 1 | → AC_DOC_TYPE (ใช้หากฎอนุมัติ) |

> ✅ `approvers` `6a8677b18b36df988c176cb4` (multi-collaborator เดิม) **ไม่ต้องใช้เป็นผู้อนุมัติของ node** — สายอนุมัติหากฎเองตามแบบ WF-AC-01

#### FR-08.2 ใบสำคัญจ่าย — **Worksheet `AC_PAY`** · ws `6a8677c38b36df988c176cd3` · alias `ac_pay` · view `6a8677c38b36df988c176cd7`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `pay_no` | `6a8677c38b36df988c176cdd` | Text (subType 0) | **isTitle=True** |
| `doc_date` | `6a8677c38b36df988c176cde` | Date (subType 3) | required |
| `pay_due_date` | `6a8677c38b36df988c176cdf` | Date (subType 3) |  |
| `prepared_by` | `6a8677c38b36df988c176ce0` | Collaborator (subType 0) |  |
| `currency` | `6a8677c38b36df988c176ce1` | Relation (subType 1) | required · → ws `6a8545261049edca1eecd818` · sourceField `6a8677c38b36df988c176ce2` |
| `fx_rate` | `6a8677c38b36df988c176ce3` | Number (subType 0) |  |
| `pay_req` | `6a8677c38b36df988c176ce4` | Relation (subType 1) | → ws `6a8677b19b6999a714d2aa83` (AC_PAY_REQ) · sourceField `6a8677c38b36df988c176ce5` |
| `voucher` | `6a8677c38b36df988c176ce6` | Relation (subType 1) | → ws `6a85fb2e9b6999a714d2a53d` · sourceField `6a8677c38b36df988c176ce7` |
| AC_PAY_LINE — ⚠️ **ไม่มี alias** อ้างด้วย field id เท่านั้น | `6a8677d71049edca1eed06fd` | Relation (subType 2) | → ws `6a8677d7055f2288c5b77d12` (AC_PAY_LINE) · sourceField `6a8677d71049edca1eed06fc` |

| ✅ ฟิลด์ที่สร้างแล้ว | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `pay_status` `biz_pay_status` | `6a8ead8f1378964f998490f6` | Dropdown | → **`OS_PAY_STATUS` `d2d61597-824a-42b6-a9bd-5d98a856516e`** (สร้างใหม่ 26 ส.ค.) |
| `period` `biz_pay_period` | `6a8ead8f1378964f998490f7` | Relation subType 1 | → AC_PERIOD · บังคับ BR-03 |
| `doc_type` `biz_pay_doc_type` | `6a8ead8f1378964f998490f9` | Relation subType 1 | → AC_DOC_TYPE |
| `total_gross` `biz_pay_total_gross` | `6a8ead8f1378964f998490fb` | Number | |
| `total_wht` `biz_pay_total_wht` | `6a8ead8f1378964f998490fc` | Number | |
| `total_net` `biz_pay_total_net` | `6a8ead8f1378964f998490fd` | Number | |
| `submitted_flag` `biz_pay_submitted_flag` | `6a8ead8f1378964f998490fe` | Number · default 0 | |
| `settled_flag` `biz_pay_settled_flag` | `6a8ead8f1378964f998490ff` | Number · default 0 | กันตัดชำระซ้ำจาก webhook |
| `approval_level` `biz_pay_approval_level` | `6a8ead8f1378964f99849100` | Number · default 0 | |
| `reject_reason` `biz_pay_reject_reason` | `6a8ead8f1378964f99849101` | Text (multiline) | |

#### FR-08.3 บรรทัดใบสำคัญจ่าย — **Worksheet `AC_PAY_LINE`** · ws `6a8677d7055f2288c5b77d12` · alias `ac_pay_line` · view `6a8677d7055f2288c5b77d16`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `line_ref` | `6a8677d71049edca1eed06fa` | Text (subType 0) | **isTitle=True** |
| `line_no` | `6a8677d71049edca1eed06fb` | Number (subType 0) | required |
| `pay` | `6a8677d71049edca1eed06fc` | Relation (subType 1) | required · → ws `6a8677c38b36df988c176cd3` (AC_PAY) · sourceField `6a8677d71049edca1eed06fd` |
| `ap` | `6a8677d71049edca1eed06fe` | Relation (subType 1) | required · → ws `6a8673d61049edca1eed0638` (AC_AP) · sourceField `6a8677d71049edca1eed06ff` |
| `partner` | `6a8677d71049edca1eed0700` | Relation (subType 1) | required · → ws `6a85457033560633b8cd6920` · sourceField `6a8677d71049edca1eed0701` |
| `doc_amount` | `6a8677d71049edca1eed0702` | Number (subType 0) | required |
| `wht_amount` | `6a8677d71049edca1eed0703` | Number (subType 0) |  |
| `net_amount` | `6a8677d71049edca1eed0704` | Number (subType 0) | required |

> ✅ ตารางนี้ **ไม่มีในต้นฉบับ SDS** แต่จำเป็นจริง — เป็นตัวที่ทำให้ **TC-23** (ใบสำคัญจ่าย 1 ใบ ครอบคลุม 3 คู่ค้า 7 เอกสาร) เป็นไปได้ · ถือเป็นการปรับปรุงที่ยอมรับแล้ว บันทึกไว้ใน `03-RTM-Status.md` §E

#### FR-08.4 บันทึกตัดชำระ — **Worksheet `AC_PAY_SETTLE`** · ws `6a8677de8b36df988c176d02` · alias `ac_pay_settle` · view `6a8677de8b36df988c176d06`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `settle_ref` | `6a8677de9b6999a714d2aa9f` | Text (subType 0) | **isTitle=True** |
| `pay` | `6a8677de9b6999a714d2aaa0` | Relation (subType 1) | required · → ws `6a8677c38b36df988c176cd3` (AC_PAY) · sourceField `6a8677de9b6999a714d2aaa1` |
| `partner` | `6a8677de9b6999a714d2aaa2` | Relation (subType 1) | required · → ws `6a85457033560633b8cd6920` · sourceField `6a8677de9b6999a714d2aaa3` |
| `gross` | `6a8677de9b6999a714d2aaa4` | Number (subType 0) | required |
| `wht` | `6a8677de9b6999a714d2aaa5` | Number (subType 0) |  |
| `net` | `6a8677de9b6999a714d2aaa6` | Number (subType 0) | required |
| `payment_date` | `6a8677de9b6999a714d2aaa7` | Date (subType 3) | required |
| `payment_channel` | `6a8677de9b6999a714d2aaa8` | Relation (subType 1) | required · → ws `6a8545a19b6999a714d2675f` · sourceField `6a8677de9b6999a714d2aaa9` |
| `own_bank_account` | `6a8677de9b6999a714d2aaaa` | Relation (subType 1) | → ws `6a854584055f2288c5b74202` · sourceField `6a8677de9b6999a714d2aaab` |
| `partner_bank_account` | `6a8677de9b6999a714d2aaac` | Relation (subType 1) | → ws `6a85458033560633b8cd692a` · sourceField `6a8677de9b6999a714d2aaad` |
| `reference` | `6a8677de9b6999a714d2aaae` | Text (subType 0) |  |
| `remark` | `6a8677de9b6999a714d2aaaf` | Text (subType 0) |  |

| ✅ ฟิลด์ที่สร้างแล้ว | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `settle_status` `biz_stl_status` | `6a8ead961378964f9984911e` | Dropdown | → **`OS_SETTLE_STATUS` `b028f1d7-ec71-465a-afd0-ba9c0fe09788`** (สร้างใหม่ 26 ส.ค.) |
| `finance_ref` `biz_stl_finance_ref` | `6a8ead961378964f9984911f` | Text | เลขอ้างอิงจากโมดูลการเงิน · ใช้ทำ idempotency ของ WF-AC-04 |

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-08.1 | Business Rule · validation | `AC_PAY_LINE.doc_amount` > `ap.outstanding` | **Block save "จ่ายเกินยอดคงเหลือ (คงเหลือ = …)"** — บังคับ **TC-24** |
| BR-08.2 | Business Rule · validation | `net_amount` ≠ `doc_amount` − `wht_amount` | Block save |
| BR-08.3 | Business Rule · interaction | `pay_status` ≠ ร่าง | Set all read-only |
| BR-08.4 | Business Rule · interaction | `payment_channel.channel_name` = Bank transfer `4bb5ba34-…` | `own_bank_account` และ `partner_bank_account` เป็นฟิลด์บังคับ |
| RU-08.1 | Rollup | `AC_PAY` ← Sum(`AC_PAY_LINE.net_amount`) | เป็นทางเลือกแทน `total_net` ถ้าไม่ต้องกรอง — **ใช้ rollup ได้เพราะ filter คงที่** |
| DV-08.1 | Dynamic default · Query worksheet | `partner_bank_account` ← บัญชีของคู่ค้าที่ `is_active` ติ๊ก | ลดการคีย์ผิดบัญชี |

**DoD:** ใบสำคัญจ่าย 1 ใบครอบคลุม 3 คู่ค้า 7 เอกสาร → เกิด `AC_PAY_SETTLE` 3 รายการ และ `AC_AP.outstanding` ของทั้ง 7 เป็น 0 (TC-23) · จ่ายเกินยอดคงเหลือถูกปฏิเสธพร้อมแสดงยอดคงเหลือ (TC-24)
**วิธี verify:** `get_record_list(ac_pay_settle, filter pay = <rowid>)` = 3 · `get_record_list(ac_ap, filter outstanding ne 0 AND rowid in […])` = 0 รายการ
**Gap:** 🔴 ต้องสร้างฟิลด์สถานะและยอดรวมทั้ง 4 ตารางก่อน · ยังไม่มีข้อตกลงรูปแบบ payload กับโมดูลการเงิน (ข้อสมมติ) 🔴

---

### FR-09 ภาษีหัก ณ ที่จ่ายและใบรับรอง

**สถานะ: 🔶 ตารางครบ · ❌ ขาดฟิลด์สถานะและเลขที่ตามแบบราชการ**

**Worksheet `AC_WHT`** · ws `6a8677f1055f2288c5b77d1d` · alias `ac_wht` · view `6a8677f1055f2288c5b77d21`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `wht_no` | `6a8677f1055f2288c5b77d27` | Text (subType 0) | **isTitle=True** |
| `partner` | `6a8677f1055f2288c5b77d28` | Relation (subType 1) | required · → ws `6a85457033560633b8cd6920` · sourceField `6a8677f1055f2288c5b77d29` |
| `source_id` | `6a8677f1055f2288c5b77d2a` | Text (subType 0) | required |
| `pay_date` | `6a8677f1055f2288c5b77d2b` | Date (subType 3) | required |
| `income_type` | `6a8677f1055f2288c5b77d2c` | Relation (subType 1) | required · → ws `6a85454133560633b8cd68e6` · sourceField `6a8677f1055f2288c5b77d2d` |
| `base_amount` | `6a8677f1055f2288c5b77d2e` | Number (subType 0) | required |
| `wht_rate` | `6a8677f1055f2288c5b77d2f` | Number (subType 0) | required |
| `wht_amount` | `6a8677f1055f2288c5b77d30` | Number (subType 0) | required |
| `filing` | `6a8677f1055f2288c5b77d31` | Relation (subType 1) | → ws `6a8677c79b6999a714d2aa93` · sourceField `6a8677f1055f2288c5b77d32` |
| `printed_at` | `6a8677f1055f2288c5b77d33` | DateTime (subType 1) |  |
| `printed_by` | `6a8677f1055f2288c5b77d34` | Collaborator (subType 0) |  |
| `source_type` | `6a8677f1055f2288c5b77d35` | SingleSelect (subType 0) | required · option keys: `4572f17b-f93e-4dac-8531-909f7c31a223` = "AP", `3b14bfb0-dc38-4f87-918d-b59a97755a66` = "PAY" |

| ✅ ฟิลด์ที่สร้างแล้ว | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `form_type` `biz_wht_form_type` | `6a8ead9f9762533b5b717052` | Dropdown | → `OS_FORM_TYPE` `7b605ddd-…` (ค่าเป็นอักษรโรมัน `P.N.D.3` / `P.N.D.53`) |
| `payee_legal_form` `biz_wht_payee_legal_form` | `6a8ead9f9762533b5b717053` | Dropdown | → `OS_LEGAL_FORM` `b97a1a08-…` · สำเนา ณ วันที่ออกใบรับรอง |
| `wht_status` `biz_wht_status` | `6a8ead9f9762533b5b717054` | Dropdown | → **`OS_WHT_STATUS` `b2f5604d-d432-434f-aae9-16ae87732eb9`** (สร้างใหม่ 26 ส.ค.) |
| `borne_by` `biz_wht_borne_by` | `6a8ead9f9762533b5b717055` | Dropdown | → `OS_WHT_BORNE_BY` `ce278c49-…` |
| `voucher` `biz_wht_voucher` | `6a8ead9f9762533b5b717056` | Relation subType 1 | → AC_VOUCHER |
| `pay_ref` `biz_wht_pay_ref` | `6a8ead9f9762533b5b717058` | Relation subType 1 | → AC_PAY (แทน `source_id` ที่เป็น Text) |

> ⚠️ `source_type` มีแค่ 2 ค่า (`AP`, `PAY`) ซึ่งพอสำหรับ A-10 = At payment · ถ้าเปลี่ยนเป็น At invoice ต้องทบทวน

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-09.1 | Business Rule · validation | `wht_amount` ≠ round(`base_amount` × `wht_rate` / 100, 2) | Block save |
| BR-09.2 | Business Rule · interaction | `printed_at` ไม่ว่าง | Set all read-only (ใบรับรองที่พิมพ์แล้วห้ามแก้) |
| IX-09.1 | Unique index | `wht_no` | ⚠️ ต้องตั้ง required ก่อน · เลขที่ใบรับรองต้องเรียงต่อเนื่องตามแบบราชการ |

**DoD:** ใบรับรองพิมพ์ออกมาตรงแบบราชการ มีเลขลำดับต่อเนื่องและลายเซ็นที่ประทับตอนพิมพ์ (TC-13) · ยอดรวมใบรับรองในเดือนตรงกับยอดในแบบ ภ.ง.ด.
**Gap:** print template ต้องทำใน **Browser** ทั้งหมด · ลายเซ็นและตราประทับเก็บเป็น Attachment บน `AC_DOC_SETTING.seal_image` ✅ มีฟิลด์แล้ว

---

### FR-10 ทะเบียนเอกสารภาษีมูลค่าเพิ่มและการควบคุม tax point 🔴

**สถานะ: 🔶 ตารางครบ · ❌ ขาดฟิลด์ที่ทำให้กลไก tax point ทำงานได้ทั้งหมด**

**Worksheet `AC_VAT_DOC`** · ws `6a8677f9055f2288c5b77d58` · alias `ac_vat_doc` · view `6a8677f9055f2288c5b77d5c`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `vat_doc_ref` | `6a8677f933560633b8cda33d` | Text (subType 0) | **isTitle = True** |
| `source_doc_id` | `6a8677f933560633b8cda33e` | Text (subType 0) | required |
| `partner` | `6a8677f933560633b8cda33f` | Relation (subType 1) | required · → ws `6a85457033560633b8cd6920` · sourceField `6a8677f933560633b8cda340` |
| `tax_invoice_no` | `6a8677f933560633b8cda341` | Text (subType 0) |  |
| `tax_invoice_date` | `6a8677f933560633b8cda342` | Date (subType 3) |  |
| `tax_point_date` | `6a8677f933560633b8cda343` | Date (subType 3) | required |
| `base_amount` | `6a8677f933560633b8cda344` | Number (subType 0) | required |
| `vat_amount` | `6a8677f933560633b8cda345` | Number (subType 0) | required |
| `vat_rate` | `6a8677f933560633b8cda346` | Relation (subType 1) | required · → ws `6a8545469b6999a714d2673c` · sourceField `6a8677f933560633b8cda347` |
| `claim_period` | `6a8677f933560633b8cda348` | Relation (subType 1) | → ws `6a8434d5055f2288c5b6d4b8` · sourceField `6a8677f933560633b8cda349` |
| `filing` | `6a8677f933560633b8cda34a` | Relation (subType 1) | → ws `6a8677c79b6999a714d2aa93` (AC_TAX_FILING) · sourceField `6a8677f933560633b8cda34b` |
| `sign` | `6a8677f933560633b8cda34c` | Number (subType 0) | required |
| `source_doc_type` | `6a8677f933560633b8cda34d` | SingleSelect (subType 0) | required · options: `5c9dabe4-af8e-4bb6-9999-2957219fafaa` = AC_AP · `42da0a88-7aa9-41f3-a0bc-b2c3655adbf2` = AC_INV · `64302feb-cd90-4a91-85f6-31c68b00413b` = AC_CN · `82db6291-0b15-4920-8682-3c9fd16d7650` = AC_DN |

| ✅ ฟิลด์ที่สร้างแล้ว | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `vat_side` `biz_vd_vat_side` | `6a8ead518b6633ef76f1201e` | Dropdown | → `OS_VAT_SIDE` `32f06106-…` · 🔑 แยกภาษีซื้อ/ขายได้แล้ว |
| `claim_status` `biz_vd_claim_status` | `6a8ead518b6633ef76f1201f` | Dropdown | → `OS_VAT_DOC_STATUS` `162d4782-…` · 🔑 คุม tax point + กันใช้เครดิตซ้ำ |
| `accrual_period` `biz_vd_accrual_period` | `6a8ead518b6633ef76f12020` | Relation subType 1 | → AC_PERIOD · งวดที่ตั้งค้างจ่าย (ต่างจาก `claim_period`) |
| `deferred_flag` `biz_vd_deferred_flag` | `6a8ead518b6633ef76f12022` | Number · **default 0** | ยังอยู่ในบัญชีภาษีซื้อรอเรียกคืน |
| `transfer_voucher` `biz_vd_transfer_voucher` | `6a8ead518b6633ef76f12023` | Relation subType 1 | → AC_VOUCHER · ใบสำคัญโอนภาษีซื้อ (event `VAT_TRANSFER`) |

> ✅ `sign` (Number) มีอยู่แล้ว = +1 / −1 — ใช้ทำรายการติดลบตอนกลับรายการหรือออกใบลดหนี้ (TC-07, TC-26)
> ✅ `tax_point_date` แยกจาก `tax_invoice_date` แล้ว — โครงสร้างถูก เหลือแค่ฟิลด์สถานะ

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| IX-10.1 | Unique index | (`vat_side`, `partner`, `tax_invoice_no`, `tax_invoice_date`) | 🔴 **กันใช้เครดิตซ้ำระดับข้อมูล — บังคับ TC-20** · ทุกฟิลด์ต้อง required |
| BR-10.1 | Business Rule · validation | `vat_amount` ≠ round(`base_amount` × `vat_rate.rate_percent` / 100, 2) | Block save (ยอมรับผลต่าง ±0.01) |
| BR-10.2 | Business Rule · interaction | `claim_status` in (Claimed, Filed) | Set all read-only |
| BR-10.3 | Business Rule · validation | `tax_point_date` > วันที่ปัจจุบัน | Block save |

**State machine (`claim_status` — 🆕)**

| จาก | ไป | ขับด้วย | เงื่อนไข |
|---|---|---|---|
| Awaiting tax invoice `d4514d7d-…` | Tax invoice received `73da6436-…` | **WF-AC-15** | ผู้ใช้กรอก `tax_invoice_no` + `tax_invoice_date` |
| Tax invoice received | Claimed `79e3b7e4-…` | **WF-AC-15** | กำหนด `claim_period` = งวดภาษีที่ยังเปิด + สร้างใบสำคัญโอนภาษีซื้อรอเรียกคืน |
| Claimed | Filed `023498c0-…` | **WF-AC-16** | เมื่อ ภ.พ.30 ของงวดนั้นถูกยื่น |
| ใด ๆ | Not claimable `343e36ca-…` | ผู้ใช้ (AC-R2) | เอกสารไม่เข้าเงื่อนไขเครดิตภาษี |

> 🔑 **กติกาที่ทำให้ TC-21 ผ่าน:** WF-AC-15 ต้องอ่าน `AC_PERIOD.tax_period_status` ของงวดที่ตรงกับ `tax_point_date` — ถ้าเป็น `Filed` หรือ `Amended` ให้กำหนด `claim_period` เป็น **งวดภาษีถัดไปที่ยังเป็น Open** และเขียนบันทึกเหตุผลลง log

**DoD:** ตั้งค้างจ่ายไม่มีใบกำกับ → ลงบัญชีภาษีซื้อรอเรียกคืน → ลงทะเบียนใบกำกับ 2 เดือนถัดมา → โอนเข้าภาษีซื้อและปรากฏใน ภ.พ.30 งวดหลัง (TC-19) · เอกสารเดียวกันใช้เครดิตซ้ำไม่ได้ (TC-20) · tax point ตกในงวดที่ยื่นแล้วถูกโยนไปงวดเปิดถัดไปพร้อม audit (TC-21)
**Gap:** 🔴 ขาด 5 ฟิลด์ · ยังไม่มี unique index · ยังไม่มี workflow

---

### FR-11 การยื่นแบบภาษี 🔴 **ตารางแทบว่างเปล่า**

**สถานะ: 🔶 ตารางมีอยู่แต่มีเพียง 6 ฟิลด์ธุรกิจ — ยังบันทึกการยื่นแบบตามข้อกำหนดไม่ได้**

**Worksheet `AC_TAX_FILING`** · ws `6a8677c79b6999a714d2aa93` · alias `ac_tax_filing` · view `6a8677c79b6999a714d2aa97`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `filing_no` | `6a8677c733560633b8cda326` | Text (subType 0) | **isTitle = True** |
| `tax_month` | `6a8677c733560633b8cda327` | Text (subType 0) | required |
| `filing_date` | `6a8677c733560633b8cda328` | Date (subType 3) |  |
| `payment_date` | `6a8677c733560633b8cda329` | Date (subType 3) |  |
| `approved_by` | `6a8677c733560633b8cda32a` | Collaborator (subType 0) |  |
| `original_filing` | `6a8678261049edca1eed0726` | Relation (subType 1) | → ws `6a8677c79b6999a714d2aa93` (self) · sourceField `6a8678261049edca1eed0727` |
| 子 — ⚠️ **ไม่มี alias** อ้างด้วย field id เท่านั้น | `6a8678261049edca1eed0727` | Relation (subType 2) | → ws `6a8677c79b6999a714d2aa93` (self) · sourceField `6a8678261049edca1eed0726` · ชื่อฟิลด์เป็นภาษาจีน `子` (auto-generated reverse relation ของ original_filing) และยังไม่ได้ตั้ง alias |

> 🔴 **ฟิลด์ `子` ไม่มี alias** (reverse relation ที่ระบบสร้างให้อัตโนมัติของ `original_filing`) — อ้างด้วย field id `6a8678261049edca1eed0727` เท่านั้น · **ควรตั้งชื่อและ alias ใหม่ผ่าน `update_worksheet.editFields` (ส่ง name + alias คู่กัน) เป็น `amended_filings`**

| ✅ ฟิลด์ที่สร้างแล้ว | Field ID | type | หมายเหตุ |
|---|---|---|---|
| `amended_filings` `biz_tf_amended_filings` | `6a8678261049edca1eed0727` | Relation subType 2 | ✅ **เปลี่ยนชื่อจาก `子` แล้ว** — reverse ของ `original_filing` |
| `form_type` `biz_tf_form_type` | `6a8ead611378964f9984907a` | Dropdown | → `OS_FORM_TYPE` `7b605ddd-…` |
| `filing_type` `biz_tf_filing_type` | `6a8ead611378964f9984907b` | Dropdown | → `OS_FILING_TYPE` `072eb596-…` · Normal / Additional · **TC-22** |
| `filing_status` `biz_tf_filing_status` | `6a8ead611378964f9984907c` | Dropdown | → `OS_FILING_STATUS` `edb8daeb-…` |
| `period` `biz_tf_period` | `6a8ead611378964f9984907d` | Relation subType 1 | → AC_PERIOD (แทน `tax_month` ที่เป็น Text) |
| `output_vat` `biz_tf_output_vat` | `6a8ead611378964f9984907f` | Number | |
| `input_vat` `biz_tf_input_vat` | `6a8ead611378964f99849080` | Number | |
| `net_payable` `biz_tf_net_payable` | `6a8ead611378964f99849081` | Number | output − input |
| `wht_total` `biz_tf_wht_total` | `6a8ead611378964f99849082` | Number | ยอดในแบบ ภ.ง.ด. |
| `doc_count` `biz_tf_doc_count` | `6a8ead611378964f99849083` | Number | จำนวนเอกสารที่นำไปยื่น |
| `submitted_flag` `biz_tf_submitted_flag` | `6a8ead611378964f99849084` | Number · **default 0** | |
| `export_file` `biz_tf_export_file` | `6a8ead611378964f99849085` | Attachment | ✅ **API สร้างฟิลด์ Attachment ได้จริง** |

**Form rules**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| IX-11.1 | Unique index | (`form_type`, `period`, `filing_type`) | กันยื่นปกติซ้ำในงวดเดียวกัน — ยื่นเพิ่มเติมยังทำได้เพราะ `filing_type` ต่างกัน |
| BR-11.1 | Business Rule · validation | `filing_type` = Additional `dfa22f2b-…` และ `original_filing` ว่าง | Block save "การยื่นเพิ่มเติมต้องอ้างอิงแบบยื่นเดิม" |
| BR-11.2 | Business Rule · interaction | `filing_status` in (Filed, Paid) | Set all read-only + Lock record |
| BR-11.3 | Business Rule · validation | `net_payable` ≠ `output_vat` − `input_vat` | Block save (เฉพาะ ภ.พ.30) |

**DoD:** ยื่น ภ.พ.30 แล้วยื่นเพิ่มเติมของเดือนเดียวกัน → บันทึกทั้งสองฉบับ ผูกกันด้วย `original_filing` และเอกสารถูกกำกับให้ฉบับที่ถูกต้อง (TC-22) · ยอดในแบบกระทบกับ AC_GL ได้
**Gap:** 🔴 ขาด 11 ฟิลด์ · ฟิลด์ `子` ต้องเปลี่ยนชื่อ · ยังไม่มี workflow

---

### FR-12 ลูกหนี้และห่วงโซ่เอกสารขาย ❌ **ย้ายออกนอกขอบเขตถาวร — ห้ามสร้าง**

> 🔴 **ปิดถาวร 28 ส.ค. 2569 — ข้อสมมติ A-09 ยืนยันแล้ว**: ผู้ใช้ตอบว่า "จะทำโมดูลการขายเข้ามาเพิ่มภายหลัง ให้เซลล์เป็นคนออก" ⇒ บัญชีไม่ได้เป็นเจ้าของห่วงโซ่เอกสารขาย จะมีโมดูลการขายแยกต่างหากสร้างขึ้นในอนาคต และฝ่ายขายเป็นผู้ออกเอกสารเอง (ดู `01-BRD.md` §11 A-09 และ `05-Roadmap-Tracker.md` §3.2/§5) — **ห้าม build agent สร้าง worksheet `AC_AR` / `AC_AR_LINE` / `AC_BL` / `AC_INV` / `AC_RE` / `AC_CN` / `AC_DN` ตามสเปกด้านล่างนี้เด็ดขาด** สเปกทั้งหมดยังเป็น `<TBD>` (ไม่เคยสร้างจริงบนเซิร์ฟเวอร์) จึงไม่มี data/object ให้ต้อง cleanup — เก็บไว้ด้านล่างเป็นข้อมูลอ้างอิงเท่านั้น เผื่อทีมโมดูลขายในอนาคตต้องการดูโครงสร้างที่เคยออกแบบไว้ · จุดเชื่อมต่อในอนาคตของบัญชีคือ**รับ**รายการรายได้/ลูกหนี้ที่ผ่านรายการแล้วจากโมดูลขายเข้ามาเท่านั้น (รูปแบบเดียวกับ Procurement/HRMS ที่ป้อนเข้าบัญชี) ไม่ใช่การสร้าง/ออกเอกสารขายเอง

**สถานะเดิมก่อนปิด (อ้างอิงประวัติ): ⬜ section `AC-05 Receivable and Revenue` `6a853a35e16cff5c409bc753` ว่างเปล่า · ขึ้นกับข้อสมมติ A-09 🔴**

> ~~**ห้ามเริ่มสร้าง FR นี้จนกว่าจะได้คำตอบข้อ A-09** — ถ้าองค์กรมีระบบขายแยกต่างหาก ขอบเขตนี้ย้ายออกทั้งก้อน (ราวหนึ่งในสี่ของโมดูล)~~ (คำตอบมาแล้ว 28 ส.ค. 2569 — ย้ายออกจริงตามที่คาดการณ์ไว้)

| Worksheet ที่ต้องสร้าง | ws ID | ฟิลด์หลัก (ทั้งหมดเป็น `<TBD>` จนกว่าจะสร้าง) |
|---|---|---|
| `AC_AR` | `<TBD>` | `ar_no` (isTitle, Text) · `partner` (Relation → `6a85457033560633b8cd6920`) · `doc_date` `due_date` (Date) · `period` (Relation → `6a8434d5055f2288c5b6d4b8`) · `currency` (Relation → `6a8545261049edca1eecd818`) · `fx_rate` (Number) · `ar_status` (Dropdown → `OS_AR_STATUS` `d3fad393-d804-4034-9751-a3858f3c54e9`) · `taxable_base` `non_taxable_base` `vat_amount` `total_amount` `collected_amount` `outstanding` (Number 2) · `voucher` (Relation → `6a85fb2e9b6999a714d2a53d`) · `approver_user` (Collaborator) · `submitted_flag` (Number 0) |
| `AC_AR_LINE` | `<TBD>` | ภาพสะท้อนของ `AC_AP_LINE` ฝั่งรายได้ — `ar` (Relation) · `item` · `revenue_account` (Relation → `6a85516e1049edca1eecd9b7`) · `qty` `unit_price` `discount` `line_amount` `line_taxable_base` `line_vat` (Number) · `vat_rate` (Relation → `6a8545469b6999a714d2673c`) · `vat_rate_percent` (Number, สำเนา) · `cost_center` `fund` `project` (Relation) |
| `AC_BL` ใบแจ้งหนี้ | `<TBD>` | `bl_no` · `partner` · `bl_date` `due_date` · `total_amount` · `converted_amount` (Number — ยอดที่แปลงเป็นใบกำกับแล้ว) · `bl_status` · `ar_docs` (Relation subType 2 → AC_AR — รองรับใบแจ้งหนี้รวมหลายรายการ) |
| `AC_INV` ใบกำกับภาษี | `<TBD>` | `inv_no` · `partner` · `inv_date` · `tax_point_date` (Date) · `source_bl` (Relation → AC_BL) · `taxable_base` `vat_amount` `total_amount` · `inv_status` · `vat_doc` (Relation → `6a8677f9055f2288c5b77d58`) |
| `AC_RE` ใบเสร็จรับเงิน | `<TBD>` | `re_no` · `partner` · `re_date` · `received_amount` · `payment_channel` (Relation → `6a8545a19b6999a714d2675f`) · `wht_deducted` (Number — ภาษีที่ลูกค้าหักไว้) · `invoices` (Relation subType 2 → AC_INV) |
| `AC_CN` ใบลดหนี้ | `<TBD>` | `cn_no` · `original_inv` (Relation → AC_INV, **required**) · `reason` (Text) · `base_amount` `vat_amount` (Number) · `cn_status` |
| `AC_DN` ใบเพิ่มหนี้ | `<TBD>` | โครงสร้างเดียวกับ AC_CN แต่ `sign` = +1 |

**Form rules ที่ต้องมี**

| # | ชนิด | เงื่อนไข | การกระทำ |
|---|---|---|---|
| BR-12.1 | Business Rule · validation | ยกเลิก `AC_BL` ขณะที่ `converted_amount` > 0 | Block save "แปลงเป็นใบกำกับไปแล้วบางส่วน" — บังคับ **TC-25** |
| BR-12.2 | Business Rule · validation | `AC_CN.base_amount` > ยอดคงเหลือของ `original_inv` | Block save |
| BR-12.3 | Business Rule · interaction | `AC_CN.original_inv` ว่าง | ทุกฟิลด์อื่น read-only — บังคับให้อ้างต้นฉบับเสมอ (BR-11) |
| IX-12.1 | Unique index | `AC_INV.inv_no` · `AC_RE.re_no` · `AC_CN.cn_no` · `AC_DN.dn_no` | เลขที่เอกสารภาษีห้ามซ้ำเด็ดขาด |

**DoD:** แปลงใบแจ้งหนี้เป็นใบกำกับบางส่วนได้ และยกเลิกใบแจ้งหนี้ไม่ได้ขณะใบกำกับยังมีผล (TC-25) · ออกใบลดหนี้กับใบกำกับที่ยื่นแบบไปแล้ว → รายการปรับปรุงไปอยู่ในงวดภาษีที่ยังเปิด โดยอ้างต้นฉบับ (TC-26)
**Workflow ที่ผูก:** WF-AC-05 · WF-AC-18 · WF-AC-19

---

### FR-13 บัญชีสินทรัพย์ถาวร ⬜ **ยังไม่มีตารางใดเลย**

**สถานะ: ✅ A-11 ยืนยันแล้ว 28 ส.ค. 2569 (บัญชีถือสมุดบัญชีสินทรัพย์เต็มรูปแบบ) — พร้อมเริ่มสร้าง ยังไม่ได้ลงมือสร้าง · section `AC-06 Fixed Assets` `6a853ab60f7255ac5594e0dc` ยังว่างเปล่า**

| Worksheet ที่ต้องสร้าง | ws ID | ฟิลด์หลัก |
|---|---|---|
| `AC_ASSET_BOOK` | `<TBD>` | `asset_code` (isTitle) · `asset_name` · `category` (Relation → `6a8545948b36df988c17247c` AC_ASSET_CATEGORY) · `acquire_date` (Date) · `cost` `salvage_value` `accum_depr_bf` (Number 2) · `life_years` (Number 0) · `depr_method` (Dropdown → `OS_DEPR_METHOD` `c66475a4-…`) · `asset_status` (Dropdown → `OS_ASSET_STATUS` `4f3a273d-…`) · `cost_center` `fund` `project` (Relation) · `inventory_ref` (Text — รหัสจากโมดูลสินทรัพย์) · `nbv` (Number 2, เขียนโดย workflow) |
| `AC_DEPR_SCHEDULE` | `<TBD>` | `asset` (Relation → AC_ASSET_BOOK) · `period` (Relation → `6a8434d5055f2288c5b6d4b8`) · `depr_amount` (Number 2) · `accum_after` (Number 2) · `posted_flag` (Number 0) · `depr_posting` (Relation → AC_DEPR) |
| `AC_DEPR` | `<TBD>` | `depr_no` · `period` · `category` · `cost_center` · `total_depr` (Number 2) · `voucher` (Relation → `6a85fb2e9b6999a714d2a53d`) · `depr_status` |
| `AC_ASSET_DISPOSAL` | `<TBD>` | `disposal_no` · `asset` (Relation) · `disposal_date` (Date) · `disposal_method` (Dropdown → `OS_DISPOSAL_METHOD` `2fdba55a-…`) · `proceeds` `nbv_at_disposal` `gain_loss` (Number 2) · `voucher` (Relation) · `disposal_status` |

**DoD:** รันค่าเสื่อมประจำเดือนแล้วใบสำคัญตรงกับตารางค่าเสื่อมและทะเบียนสินทรัพย์ (TC-10) · ตัดจำหน่ายสินทรัพย์ที่คิดค่าเสื่อมบางส่วน → ตัดทั้งราคาทุนและค่าเสื่อมสะสม พร้อมบันทึกกำไร/ขาดทุน (TC-28)
**Workflow ที่ผูก:** WF-AC-07 · WF-AC-21
**Pitfall:** ต้องเพิ่ม `gain_loss_account` และ `default_salvage_pct` บน AC_ASSET_CATEGORY ก่อน (ดู FR-05.7)

---

### FR-14 การกระทบยอดธนาคาร ✅ **สร้างตารางและฟิลด์ครบแล้ว 27 ส.ค. 2569**

**สถานะ: ✅ ตารางและฟิลด์พร้อมใช้งาน (0 record) · อยู่ใน section `AC-07 Close and Reconciliation` `6a853b2f0f7255ac5594e0e1` · สร้างด้วยวิธีแก้บั๊ก `create_worksheet` (ดู `13-ID-Registry-AC.md` §1.2c) · ✅ WF-AC-08 สร้าง publish และทดสอบผ่านครบแล้ว 27 ส.ค. 2569 (รอบเย็น)**

**Worksheet `AC_BANK_RECON`** · ws `6a8fd69d1378964f9984a2ad` · alias `worksheet22` · view `6a8fd69d1378964f9984a2b1` · section `6a853b2f0f7255ac5594e0e1`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `biz_bank_recon_no` | `6a8fd6e8353e1b0e4a507e2e` | Text (subType 0) | required · **isTitle = true** |
| `biz_bank_recon_bank_account` | `6a8fd6e8353e1b0e4a507e2f` | Relation (subType 1) | required · dataSource `6a854584055f2288c5b74202` (AC_BANK_ACCOUNT) · sourceField (reverse) `6a8fd6e8353e1b0e4a507e30` |
| `biz_bank_recon_period` | `6a8fd6e8353e1b0e4a507e31` | Relation (subType 1) | required · dataSource `6a8434d5055f2288c5b6d4b8` (AC_PERIOD) · sourceField `6a8fd6e8353e1b0e4a507e32` |
| `biz_bank_recon_statement_date` | `6a8fd6e8353e1b0e4a507e33` | Date (subType 3) |  |
| `biz_bank_recon_statement_balance` | `6a8fd6e8353e1b0e4a507e34` | Number (subType 0) | ยอดตาม Statement |
| `biz_bank_recon_book_balance` | `6a8fd6e8353e1b0e4a507e35` | Number (subType 0) | ยอดตามบัญชี |
| `biz_bank_recon_difference` | `6a8fd6e8353e1b0e4a507e36` | Number (subType 0) | ผลต่าง — ยังไม่ใช่ Formula (คำนวณโดย workflow ในอนาคต) |
| `biz_bank_recon_status` | `6a8fd6e8353e1b0e4a507e37` | SingleSelect (subType 0) | required · options: `337d5932-d7cb-426d-8239-97361bff3de7`=ร่าง · `e08efce9-56b1-4a53-8c19-8bd0f78715e0`=กระทบแล้ว · `d83ed345-846d-4193-bd62-976a428e4f03`=อนุมัติแล้ว |
| `biz_bank_recon_statement_file` | `6a8fd6e8353e1b0e4a507e38` | Attachment (subType 0) | ไฟล์ Statement (รายการเดินบัญชี) |
| *(ไม่มี alias — reverse relation)* | `6a8fd700353e1b0e4a507e56` | Relation (subType 2) | สร้างอัตโนมัติคู่กับ `AC_BANK_RECON_LINE.biz_bank_recon_line_recon` · dataSource `6a8fd69e8b6633ef76f1313f` |

**Worksheet `AC_BANK_RECON_LINE`** · ws `6a8fd69e8b6633ef76f1313f` · alias `worksheet23` · view `6a8fd69e8b6633ef76f13143` · section `6a853b2f0f7255ac5594e0e1`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `biz_bank_recon_line_ref` | `6a8fd700353e1b0e4a507e54` | Text (subType 0) | อ้างอิง Statement · **isTitle = true** |
| `biz_bank_recon_line_recon` | `6a8fd700353e1b0e4a507e55` | Relation (subType 1) | required · dataSource `6a8fd69d1378964f9984a2ad` (AC_BANK_RECON) · sourceField `6a8fd700353e1b0e4a507e56` |
| `biz_bank_recon_line_gl` | `6a8fd700353e1b0e4a507e57` | Relation (subType 1) | dataSource `6a85fb4133560633b8cd9f4a` (AC_GL) · sourceField `6a8fd700353e1b0e4a507e58` |
| `biz_bank_recon_line_amount` | `6a8fd700353e1b0e4a507e59` | Number (subType 0) |  |
| `biz_bank_recon_line_match_status` | `6a8fd700353e1b0e4a507e5a` | SingleSelect (subType 0) | options: `8f47646c-0cd3-41b2-af1e-1dee1e916636`=จับคู่แล้ว · `9517c437-20e3-4cce-aa67-77fa64d88386`=รายการค้างในบัญชี · `53a7ec15-dd5c-4b96-9b98-fd3701af37bc`=รายการค้างในธนาคาร |

**DoD:** `biz_bank_recon_difference` = 0 หรืออธิบายได้ทุกบาทด้วยรายการค้าง
**Workflow ที่ผูก:** WF-AC-08 (✅ publish แล้ว `6a8ff2c0fdab77a41c543108` v3 — ทดสอบผ่านครบทั้งเคสมี/ไม่มีผลต่าง)
**หมายเหตุ:** alias `worksheet22`/`worksheet23` เป็นค่า auto-generated จากบั๊ก `create_worksheet` (ไม่ใช่ `ac_bank_recon` ตามธรรมเนียมเดิม) — ดู `13-ID-Registry-AC.md` §1.2c ก่อนอ้างอิงตารางนี้ใน filter/formula ของ workflow ใหม่

---

### FR-15 ปิดงวด ปิดปี และยอดยกมา ✅ **สร้างตารางและฟิลด์ครบแล้ว 27 ส.ค. 2569**

**สถานะ: ✅ ตารางและฟิลด์พร้อมใช้งาน · สร้างด้วยวิธีแก้บั๊ก `create_worksheet` (ดู `13-ID-Registry-AC.md` §1.2c) · ✅ WF-AC-09 (ปิดงวด) และ ✅ WF-AC-11 (ปิดปีและยกยอด) สร้าง publish และทดสอบผ่านครบแล้ว (ดู `15-Workflow-Catalog-AC.md` §3) · ฟิลด์ `biz_close_flag` (WF-AC-09) และ `biz_close_year_flag` (WF-AC-11) บน `AC_PERIOD` สร้างแล้วทั้งคู่**

**Worksheet `AC_CLOSE`** · ws `6a8fd69e353e1b0e4a507e16` · alias `worksheet24` · view `6a8fd69e353e1b0e4a507e1a` · section `6a853b2f0f7255ac5594e0e1`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `biz_close_no` | `6a8fd7091378964f9984a2c2` | Text (subType 0) | **isTitle = true** |
| `biz_close_period` | `6a8fd7091378964f9984a2c3` | Relation (subType 1) | required · dataSource `6a8434d5055f2288c5b6d4b8` (AC_PERIOD) · sourceField `6a8fd7091378964f9984a2c4` |
| `biz_close_checklist_item` | `6a8fd7091378964f9984a2c5` | Text (subType 0) | required |
| `biz_close_item_status` | `6a8fd7091378964f9984a2c6` | SingleSelect (subType 0) | options: `ef71ce38-559f-4ce2-b765-1c522f23493e`=ยังไม่ทำ · `27447ced-2a81-43d0-922e-0ca14e76197e`=ผ่าน · `7c9b87b9-2a08-4b60-9dc6-9b099f6dbe89`=ไม่ผ่าน |
| `biz_close_checked_by` | `6a8fd7091378964f9984a2c7` | Collaborator (subType 0) |  |
| `biz_close_checked_at` | `6a8fd7091378964f9984a2c8` | DateTime (subType 1) |  |
| `biz_close_blocking` | `6a8fd7091378964f9984a2c9` | Number (subType 0) | 1 = ห้ามปิดงวดถ้ายังไม่ผ่าน |

**Worksheet `AC_CLOSING_ENTRY`** · ws `6a8fd69f9762533b5b718bce` · alias `worksheet25` · view `6a8fd69f9762533b5b718bd2` · section `6a853b2f0f7255ac5594e0e1`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `biz_closing_entry_no` | `6a8fd716353e1b0e4a507e6e` | Text (subType 0) | **isTitle = true** |
| `biz_closing_entry_fiscal_year` | `6a8fd716353e1b0e4a507e6f` | Number (subType 0) | required |
| `biz_closing_entry_period` | `6a8fd716353e1b0e4a507e70` | Relation (subType 1) | dataSource `6a8434d5055f2288c5b6d4b8` (AC_PERIOD) · sourceField `6a8fd716353e1b0e4a507e71` |
| `biz_closing_entry_re_account` | `6a8fd716353e1b0e4a507e72` | Relation (subType 1) | บัญชีกำไรสะสม · dataSource `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a8fd716353e1b0e4a507e73` |
| `biz_closing_entry_total_revenue` | `6a8fd716353e1b0e4a507e74` | Number (subType 0) |  |
| `biz_closing_entry_total_expense` | `6a8fd716353e1b0e4a507e75` | Number (subType 0) |  |
| `biz_closing_entry_net_result` | `6a8fd716353e1b0e4a507e76` | Number (subType 0) | ผลกำไร(ขาดทุน)สุทธิ |
| `biz_closing_entry_voucher` | `6a8fd716353e1b0e4a507e77` | Relation (subType 1) | dataSource `6a85fb2e9b6999a714d2a53d` (AC_VOUCHER) · sourceField `6a8fd716353e1b0e4a507e78` |
| `biz_closing_entry_status` | `6a8fd716353e1b0e4a507e79` | SingleSelect (subType 0) | options: `cdaf130d-bbe9-4815-a705-4e482f199910`=ร่าง · `d8e95dbf-6b53-474b-a986-bf7a54299fec`=รออนุมัติ · `100f88de-4a4f-4b57-9b93-218aac7e8d4c`=อนุมัติแล้ว · `871d8182-fada-4928-afb3-44c1441ad101`=ผ่านรายการแล้ว |

**Worksheet `AC_OPENING`** · ws `6a8fd69f353e1b0e4a507e20` · alias `worksheet26` · view `6a8fd69f353e1b0e4a507e24` · section `6a853b2f0f7255ac5594e0e1`

| ฟิลด์ (alias) | Field ID | type · subType | หมายเหตุ / option key · relation |
|---|---|---|---|
| `biz_opening_no` | `6a8fd7231378964f9984a2e0` | Text (subType 0) | **isTitle = true** |
| `biz_opening_fiscal_year` | `6a8fd7231378964f9984a2e1` | Number (subType 0) | required |
| `biz_opening_account` | `6a8fd7231378964f9984a2e2` | Relation (subType 1) | required · dataSource `6a85516e1049edca1eecd9b7` (AC_COA) · sourceField `6a8fd7231378964f9984a2e3` |
| `biz_opening_cost_center` | `6a8fd7231378964f9984a2e4` | Relation (subType 1) | dataSource `6a85452b9b6999a714d26720` · sourceField `6a8fd7231378964f9984a2e5` |
| `biz_opening_fund` | `6a8fd7231378964f9984a2e6` | Relation (subType 1) | dataSource `6a85453033560633b8cd68dc` · sourceField `6a8fd7231378964f9984a2e7` |
| `biz_opening_project` | `6a8fd7231378964f9984a2e8` | Relation (subType 1) | dataSource `6a854534055f2288c5b741ce` · sourceField `6a8fd7231378964f9984a2e9` |
| `biz_opening_debit` | `6a8fd7231378964f9984a2ea` | Number (subType 0) | ยอดยกมาเดบิต |
| `biz_opening_credit` | `6a8fd7231378964f9984a2eb` | Number (subType 0) | ยอดยกมาเครดิต |
| `biz_opening_source` | `6a8fd7231378964f9984a2ec` | SingleSelect (subType 0) | options: `cdeaeb5c-5923-4c8e-8b99-ab90949ee441`=ยกยอดจากปีก่อน · `ec53f07a-4a60-4a15-afa1-be74e8740bca`=นำเข้าตอนขึ้นระบบ |
| `biz_opening_voucher` | `6a8fd7231378964f9984a2ed` | Relation (subType 1) | dataSource `6a85fb2e9b6999a714d2a53d` (AC_VOUCHER) · sourceField `6a8fd7231378964f9984a2ee` |

**DoD:** ปิดงวดขณะมีใบสำคัญค้างอนุมัติไม่ได้ และระบบแสดงรายการที่ค้าง (TC-11) · ปิดหนึ่งงวดทดลองได้ครบวงจร · ยอดยกมาตรงกับระบบเดิมทุกบัญชี (AC-20)
**Workflow ที่ผูก:** WF-AC-09 · WF-AC-11 · WF-AC-22
**หมายเหตุ:** alias `worksheet24`/`worksheet25`/`worksheet26` เป็นค่า auto-generated จากบั๊ก `create_worksheet` — ดู `13-ID-Registry-AC.md` §1.2c

---

### FR-16 รายงานและแดชบอร์ด ⬜

**สถานะ: ⬜ ยังไม่มี view หรือ custom page ใดเลย (ทุกตารางมีแต่ view `全部` ที่ระบบสร้างให้)**

| รหัส | รายงาน | สร้างอย่างไรบน Nocoly | Surface |
|---|---|---|---|
| RPT-AC-01 | งบทดลอง | Pivot บน `ac_gl` — rows = `account` · values = Sum(`debit_thb`), Sum(`credit_thb`) · filter = `period` | Chart / Custom Page |
| RPT-AC-02 | สมุดรายวันแยกเล่ม | View บน `ac_gl` group by `journal` | View |
| RPT-AC-03 | บัญชีแยกประเภทรายบัญชี | View บน `ac_gl` filter `account` + ช่วง `posting_date` | View |
| RPT-AC-04 | งบแสดงฐานะการเงิน | Pivot บน `ac_gl` join `AC_COA.statement_line` — **`statement_line` เป็น Text บนเซิร์ฟเวอร์** ⚠️ ถ้าต้องการจัดกลุ่มที่เชื่อถือได้ควรเปลี่ยนเป็น Dropdown ผูก optionset ใหม่ | Custom Page |
| RPT-AC-05 | งบผลการดำเนินงาน | เช่นเดียวกับ RPT-AC-04 filter `account_type` in (Revenue, Expense) | Custom Page |
| RPT-AC-06 | รายงานภาษีซื้อ | View บน `ac_vat_doc` filter `vat_side` = Input 🔴 (ต้องมีฟิลด์ก่อน) | View |
| RPT-AC-07 | รายงานภาษีขาย | View บน `ac_vat_doc` filter `vat_side` = Output 🔴 | View |
| RPT-AC-08 | รายงานภาษีหัก ณ ที่จ่าย | View บน `ac_wht` group by `form_type` 🔴 (ต้องมีฟิลด์ก่อน) | View |
| RPT-AC-09 | อายุหนี้เจ้าหนี้ | Aggregated table บน `ac_ap` — bucket ตาม `due_date` 🔴 (ต้องมี `outstanding` ก่อน) | Chart |
| RPT-AC-10 | อายุหนี้ลูกหนี้ | เช่นเดียวกัน บน `ac_ar` ⬜ | Chart |
| RPT-AC-11 | ต้นทุนตามโครงการ | Pivot บน `ac_gl` rows = `project` | Chart |
| RPT-AC-12 | รายงานตามแหล่งเงิน | Pivot บน `ac_gl` rows = `fund` | Chart |
| DASH-01 | แดชบอร์ดผู้บริหาร | Custom Page รวม RPT-01/09/11/12 + ภาษีค้างยื่น | Browser |
| DASH-02 | แดชบอร์ดภาษี | Custom Page — ภาษีซื้อ–ขายรายเดือน · สถานะการยื่น · เอกสารรอใบกำกับ | Browser |

> ⚠️ **`create_chart` / `create_view` / `create_custom_page` มี tool แต่ยังไม่เคยเรียกสำเร็จที่ไหน** — Surface = `MCP (unverified)` และ DoD ของทุกรายงานต้องมีขั้น "เปิดหน้าจอดูว่ารายงานโผล่จริงและตัวเลขถูก"
> Rollup ใช้เงื่อนไข "วันนี้" ไม่ได้ ⇒ รายงานอายุหนี้ต้องทำด้วย **Chart / Aggregated table** ไม่ใช่ rollup

**DoD:** งบทดลองมีเดบิตเท่าเครดิต และงบแสดงฐานะการเงินมีสินทรัพย์ = หนี้สิน + ทุน (TC-12)

---

### FR-17 การเชื่อมต่อระบบ ⬜

| # | ระบบ | ทิศทาง | กลไกบน Nocoly | สถานะ |
|---|---|---|---|---|
| INT-01 | Procurement → บัญชี | เข้า | workflow ชนิด `webhook` (WF-AC-03) รับ payload การตรวจรับ → สร้าง AC_AP + AC_AP_LINE | ⬜ ยังไม่ตกลง payload 🔴 |
| INT-02 | บัญชี → Financial Management | ออก | node `Send API Request` (**Browser** — MCP สร้าง node นี้ไม่ได้) ส่งใบสำคัญจ่ายที่อนุมัติแล้ว | ⬜ |
| INT-03 | Financial Management → บัญชี | เข้า | `webhook` (WF-AC-04) รับผลการจ่าย → สร้าง AC_PAY_SETTLE + ปรับ `outstanding` | ⬜ |
| INT-04 | บัญชี → Budget Management | ออก | `Send API Request` สอบถามวงเงินคงเหลือก่อนรับรู้หนี้สิน (BR-15) | ⬜ |
| INT-05 | HRMS → บัญชี | เข้า | `webhook` (WF-AC-20) รับสมุดรายวันเงินเดือน | ⬜ |
| INT-06 | Inventory & Asset ↔ บัญชี | สองทาง | `webhook` + `Send API Request` — ขึ้นกับ A-11 | ⬜ |
| INT-07 | บัญชี → GFMIS / e-GP | ออก | ต้องมี `AC_GFMIS_MAP` ก่อน แล้วส่งออกด้วย `Send API Request` หรือไฟล์ | ⬜ ขึ้นกับ A-07 |
| INT-08 | กรมสรรพากร (ตรวจเลขผู้เสียภาษี) | เข้า | `Call Integrated API` (**Browser**) | ⬜ ขึ้นกับ A-14 — default = ไม่ใช้ |

**หลักการเชื่อมต่อ:** ทุกช่องทางขาเข้าต้อง **idempotent** (มีคีย์ภายนอกบันทึกไว้ แล้วตรวจก่อนสร้าง) · ทุกช่องทางต้องบันทึกหมายเลขอ้างอิงของระบบต้นทางลง Text field เพื่อตามรอยกลับได้ · ห้ามใช้ MCP write แทน webhook ในการทดสอบ เพราะ operator จะเป็น `user-api` ไม่ใช่ `user-workflow`

---

### FR-18 การรับเอกสารด้วยการสแกนและ AI ⬜

| # | ความสามารถ | กลไก | Surface | สถานะ |
|---|---|---|---|---|
| AI-01 | สแกน/อัปโหลดบิลแล้วสกัดข้อมูล | workflow WF-AC-13 + **AI node** | **Browser** (AI node นอก 17 ชนิดที่ MCP สร้างได้) | ⬜ |
| AI-02 | แสดงค่าความเชื่อมั่นรายฟิลด์ | ฟิลด์ `confidence_*` (Number) บน AC_AP + Business Rule ไฮไลต์สีเมื่อ < เกณฑ์ | Browser | ⬜ |
| AI-03 | บังคับยืนยันฟิลด์ความเชื่อมั่นต่ำก่อนส่งต่อ | Business Rule · validation: `min_confidence` < 0.8 และ `confirmed_flag` ≠ 1 → **Block save** | Browser | ⬜ บังคับ **TC-27** |
| AI-04 | ตรวจจับใบแจ้งหนี้ซ้ำ | unique index บน `dup_key` + workflow เตือน | MCP | ⬜ บังคับ **TC-09** |
| AI-05 | แจ้งเตือนความผิดปกติทางบัญชี | WF-AC-12 ชนิด `schedule` ทุกเช้าวันทำการ | MCP | ✅ `6a9032d3fdab77a41c56420b` publishVersion 1 ทดสอบผ่าน (baseline) 27 ส.ค. 2569 |

**กฎกำกับ AI (จาก `TILSNA-SDS-AC-001.md` §9.1):** AI เสนอค่าเท่านั้น **ห้ามผ่านรายการเอง** · ทุกค่าที่ AI เติมต้องมีผู้ใช้ยืนยันและบันทึกว่าใครยืนยัน · ค่าความเชื่อมั่นต้องเก็บไว้ตรวจสอบย้อนหลัง

| 🆕 ฟิลด์ที่ต้องเพิ่มบน AC_AP เพื่อรองรับการสแกน | type |
|---|---|
| 🆕 `scan_file` | `Attachment` subType 3 |
| 🆕 `extraction_confidence` | `Number` precision 2 |
| 🆕 `low_confidence_fields` | `Text` |
| 🆕 `confirmed_flag` | `Number` precision 0 |
| 🆕 `confirmed_by` / `confirmed_at` | `Collaborator` / `DateTime` subType 1 |

---

### FR-19 สิทธิ์และการควบคุมการเข้าถึง

**สถานะ: ⚠️ role ครบทั้ง 8 พร้อม ID · ❌ ไม่มีสมาชิกเลย · ❌ ยังไม่ยืนยัน permission**

**งานที่ต้องทำ**

1. ยืนยันความหมายของ `recordDataScope` ด้วย `get_role_details` กับ role ที่ตั้งค่าแล้ว 1 ตัว **ก่อน** ตั้งเป็นชุด
2. ตั้ง permission ตาม matrix ใน `13-ID-Registry-AC.md` §1.4 ให้ครบทั้ง 8 role
3. เพิ่มบัญชีทดสอบอย่างน้อย 1 บัญชีต่อ role — โดยเฉพาะ **AC-R1 (ผู้จัดทำ) และ AC-R2 (ผู้อนุมัติ) ต้องเป็นคนละบัญชี** ไม่อย่างนั้นพิสูจน์ TC-05 (SoD) ไม่ได้
4. ซ่อนฟิลด์อ่อนไหวจาก AC-R6 ตาม NFR-02
5. ตั้ง AC_GL เป็น read-only ทุก role รวม AC-R8

**วิธี verify**

| ต้องตรวจ | เรียก / ทำ | ผลที่คาด |
|---|---|---|
| permission ตรง matrix | `get_role_details(<roleId>)` | worksheetPermissions ตรงตาราง `13-ID-Registry-AC.md` §1.4 |
| SoD ทำงานจริง | **Role Debugging** → สลับเป็น AC-R1 → เปิดใบสำคัญที่ตนสร้าง | ไม่มีปุ่มอนุมัติ |
| AC_GL แก้ไม่ได้ | Role Debugging ทุก role → เปิด AC_GL | ไม่มีปุ่มแก้ไข/ลบ (TC-06) |
| ฟิลด์อ่อนไหวถูกซ่อน | Role Debugging → AC-R6 → เปิด AC_PARTNER | ไม่เห็น `tax_id`, `account_no` |
| ผู้ตรวจสอบภายในอ่านอย่างเดียว | Role Debugging → AC-R5 → เปิดทุกตาราง | เห็นทุกอย่าง ไม่มีปุ่มแก้ (TC-14) |

> ⚠️ multi-role ให้สิทธิ์แบบ **กว้างสุด** — ห้ามใส่บัญชีทดสอบไว้หลาย role พร้อมกันตอนพิสูจน์ SoD

---
