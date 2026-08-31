# ID Registry (Master) — โมดูลบัญชี

> แยกออกจาก `02-BuildSpec-FRS.md` เมื่อ 31 ส.ค. 2569 (agent-ac · claim `AC/SPLIT-BUILDSPEC`)
> เหตุผล: ไฟล์แม่โต 316,054 bytes ≈ 42,366 tokens **เกินเพดาน Read 25,000 tokens ไป 1.7 เท่า** ทั้งที่ `02-BuildSpec-FRS.md` §0 ของมันสั่งให้ agent เปิดทุกครั้งก่อนแตะ object
> **เนื้อหาย้ายมาครบทุกตัวอักษร ไม่ได้ย่อหรือตัดทิ้ง** — ยืนยันด้วยการเทียบ byte-ต่อ-byte กับต้นฉบับ

---

## §1. ID Registry (Master)

### §1.1 ระบบ

| รายการ | ค่า |
|---|---|
| Application | `deca7391-1761-424b-9af3-c8d043004ad3` — ชื่อ **ERP - TILSNA** |
| Organization | `9680d433-5b6d-45d7-b6df-d05d3095f82f` |
| **MCP connector (ชื่อที่ใช้เรียก)** | **`ERP_-_TILSNA`** — ⚠️ session นี้มี connector อื่นชี้เซิร์ฟเวอร์เดียวกัน (`API-Lab`, `MCP-ASM`, `-_WFA_System`, `hap-mcp-Demo_-`) **ยืนยันด้วย `get_app_info` ก่อน write แรกเสมอ** |
| Host | `https://www.nocoly.com` |
| สถานะโครงการ | **Brownfield** — 39 worksheet (34 เดิม + 5 ใหม่ 27 ส.ค. 2569) · 30 optionset · 8 custom role สร้างแล้ว · **7 workflow publish แล้ว** (✅ ครบ 5: WF-AC-02/08/09/11/12 · ✅ WF-AC-10 ปิดครบแต่แถว §1.5 เคยตกหล่น · 🔶 WF-AC-01 เหลือทดสอบการกดอนุมัติจริง) **· Custom Action 5 ปุ่ม** — แก้ 30 ส.ค. 2569 เดิมเขียน "2 workflow" ตกรุ่นไปหลายรอบ · ความคืบหน้าจริงดูที่ `05-Roadmap-Tracker.md` เท่านั้น |
| Surface R (org-auth API กดอนุมัติแทนคน) | ❌ **ไม่ใช้** (ข้อสมมติ A-15) — ผู้อนุมัติต้องกดใน To-do เอง |

> **workflow สร้างผ่าน MCP ได้แล้ว** (ยืนยันด้วยการยิงจริง 26 ส.ค. 2569): `create_process` → `batch_create_process_nodes` → `validate_process` → `publish_process` และ **publish = เปิดใช้งานทันที ไม่มีขั้น Enable**
> 🔑 **ยืนยันซ้ำ 27 ส.ค. 2569:** วิธีแก้บั๊ก `create_worksheet` (ดู §1.2c) ที่ค้นพบครั้งแรกในโปรเจกต์ `tilsna-hr` ใช้ได้กับ connector `ERP_-_TILSNA` ของโปรเจกต์นี้เช่นกัน — ยืนยันข้าม app/connector ไม่ใช่เรื่องเฉพาะ tenant เดียว
> ✅ **แก้ 30 ส.ค. 2569 — `create_custom_actions` พิสูจน์แล้ว ไม่ใช่ unverified อีกต่อไป** (ยิงจริงสำเร็จครั้งแรก 27 ส.ค. ที่งาน 2.2 — ปุ่ม "ส่งอนุมัติ" `6a8f380b1378964f99849bfe` + "ยกเลิกใบสำคัญ" `6a8f380bae2a0e3743a0bedb`) · ⚠️ **แต่ปุ่มจะลง Scope = "Unassigned View" เสมอ และไม่โผล่ที่ไหนเลยจนกว่าจะเข้า Browser ตั้ง Scope → "All Records"** (กับดักข้อ 20 — ยืนยันซ้ำแล้วทั้งกับปุ่ม "กลับรายการ" 27 ส.ค.) การ **ตั้ง** Scope ยังไม่มี API ที่พิสูจน์แล้ว ⇒ Browser · แต่ **การ *ตรวจ* Scope ทำผ่าน CLI ได้แล้ว [V] 30 ส.ค. 2569** — `hap worksheet custom-actions <ws>` คืนฟิลด์ **`isAllView`**: `1` = All Records (ปุ่มมองเห็นได้) · `0` + `displayViews: []` = **Unassigned View (ปุ่มไม่โผล่ที่ไหนเลย)** ⇒ ไม่ต้องเปิด Browser เพื่อ *เช็ค* อีกต่อไป
> ⚠️ **`create_view` / `create_chart` / `create_chatbot` / `update_custom_page` ยังไม่เคยเรียกสำเร็จที่ไหน** — Surface เขียนเป็น `MCP (unverified)` และ **ทุก DoD ต้องมีขั้นเปิดหน้าจอดูว่า object โผล่จริง**

### §1.2 Worksheets + View — **ของจริงบนเซิร์ฟเวอร์ (39 ตาราง)**

> alias ของทุก worksheet = ชื่อ code ตัวพิมพ์เล็ก (ยืนยันจาก `get_app_info`) · ทุกตารางมี view เดียว ชื่อ `全部` ยกเว้น AC_PERIOD ที่ view ชื่อ `Main`
> คอลัมน์ record = จำนวนที่นับจริงเมื่อ 26 ส.ค. 2569 · `—` = ยังไม่ได้นับ (**ห้ามตีความว่าว่าง**)

**AC-00 Configuration · section `6a8538dee16cff5c409bc74d`**

| # | Worksheet | alias | Worksheet ID | View ID (`全部`/Main) | record |
|---|---|---|---|---|---|
| 1 | `AC_PERIOD` | `ac_period` | `6a8434d5055f2288c5b6d4b8` | `6a8434d5055f2288c5b6d4bc` | 13 |
| 2 | `AC_JOURNAL` | `ac_journal` | `6a8434da33560633b8cd2efd` | `6a8434da33560633b8cd2f01` | — |
| 3 | `AC_DOC_TYPE` | `ac_doc_type` | `6a8434dd9b6999a714d22e3d` | `6a8434dd9b6999a714d22e41` | — |
| 4 | `AC_DOC_NUMBER_RULE` | `ac_doc_number_rule` | `6a8434ea8b36df988c16ed84` | `6a8434ea8b36df988c16ed88` | — |
| 5 | `AC_APPROVAL_RULE` | `ac_approval_rule` | `6a8434f18b36df988c16ed8e` | `6a8434f18b36df988c16ed92` | — |
| 6 | `AC_DOC_SETTING` | `ac_doc_setting` | `6a8434f69b6999a714d22e75` | `6a8434f69b6999a714d22e79` | — |
| 7 | `AC_POSTING_RULE` | `ac_posting_rule` | `6a85518c33560633b8cd6a15` | `6a85518c33560633b8cd6a19` | — |
| 40 | `AC_SYSTEM_PARAM` | `worksheet31` ⚠️ | `6a917a2d9762533b5b720392` | `6a917a2d9762533b5b720396` | 1 |

> ✅ **เพิ่มใหม่ 28 ส.ค. 2569 (รอบดึก)** — แถว #40 `AC_SYSTEM_PARAM` ("พารามิเตอร์ระบบบัญชี") สร้างตามคำขอผู้ใช้ให้ทำให้ข้อสมมติ **A-08** (จุดตัดข้อมูล/วันขึ้นระบบ, `01-BRD.md` §11) "ตั้งค่าได้" — สร้างผ่าน workaround เดิม (§1.2c) เก็บ **วันตัดยอดข้อมูล** และ **วันขึ้นระบบจริง** ที่จะอ้างอิงโดย BRD A-08 เมื่อมีค่าจริง (ปัจจุบันยังว่าง) · ⚠️ alias ระดับ worksheet เป็น `worksheet31` (auto-generated) และ **ตั้งใหม่ผ่าน `update_worksheet.alias` ไม่ persist จริง** (ยืนยันซ้ำ 2 ครั้ง ไม่มี MCP/CLI ใดยืนยันค่าจริงได้เลย — ดูกับดักข้อ 34 ใน `04-CLAUDE-memory.md`) — field-level alias (`biz_*` ด้านล่าง) ใช้งานปกติ ไม่กระทบ · **4 ฟิลด์**: `biz_setting_name` (Text, isTitle, required) `6a917a45353e1b0e4a50fa32` · `biz_cutover_date` (Date subType 3) `6a917a45353e1b0e4a50fa33` · `biz_go_live_date` (Date subType 3) `6a917a45353e1b0e4a50fa34` · `biz_note` (Text multiLine) `6a917a45353e1b0e4a50fa35` · 1 record เริ่มต้น rowId `65eb8bc0-ac6b-4301-96a8-9e3b0bf2ba89` (ค่าวันที่ทั้งสองว่างไว้ตั้งใจ) · **role permission ยังไม่ได้ตั้ง** — pending manual ตาม §1.4

**AC-01 Master Data · section `6a8539557a3fe56d6dd35ba3`**

| # | Worksheet | alias | Worksheet ID | View ID (`全部`/Main) | record |
|---|---|---|---|---|---|
| 8 | `AC_COA` | `ac_coa` | `6a85516e1049edca1eecd9b7` | `6a85516e1049edca1eecd9bb` | 79 |
| 9 | `AC_COST_CENTER` | `ac_cost_center` | `6a85452b9b6999a714d26720` | `6a85452b9b6999a714d26725` | — |
| 10 | `AC_FUND` | `ac_fund` | `6a85453033560633b8cd68dc` | `6a85453033560633b8cd68e0` | — |
| 11 | `AC_PROJECT_DIM` | `ac_project_dim` | `6a854534055f2288c5b741ce` | `6a854534055f2288c5b741d2` | — |
| 12 | `AC_CURRENCY` | `ac_currency` | `6a8545261049edca1eecd818` | `6a8545261049edca1eecd81c` | — |
| 13 | `AC_FX_RATE` | `ac_fx_rate` | `6a8545911049edca1eecd8a5` | `6a8545911049edca1eecd8a9` | — |
| 14 | `AC_VAT_RATE` | `ac_vat_rate` | `6a8545469b6999a714d2673c` | `6a8545469b6999a714d26740` | 5 |
| 15 | `AC_WHT_RATE` | `ac_wht_rate` | `6a8545688b36df988c172471` | `6a8545688b36df988c172475` | — |
| 16 | `AC_WHT_INCOME_TYPE` | `ac_wht_income_type` | `6a85454133560633b8cd68e6` | `6a85454133560633b8cd68ea` | — |
| 17 | `AC_PARTNER` | `ac_partner` | `6a85457033560633b8cd6920` | `6a85457033560633b8cd6924` | 30 |
| 18 | `AC_PARTNER_BANK` | `ac_partner_bank` | `6a85458033560633b8cd692a` | `6a85458033560633b8cd692e` | — |
| 19 | `AC_BANK` | `ac_bank` | `6a854584055f2288c5b74202` | `6a854584055f2288c5b74206` | — |
| 20 | `AC_ITEM` | `ac_item` | `6a8545a89b6999a714d26769` | `6a8545a89b6999a714d2676d` | — |
| 21 | `AC_PAYMENT_CHANNEL` | `ac_payment_channel` | `6a8545a19b6999a714d2675f` | `6a8545a19b6999a714d26763` | — |
| 22 | `AC_ASSET_CATEGORY` | `ac_asset_category` | `6a8545948b36df988c17247c` | `6a8545948b36df988c172480` | — |

**AC-02 Ledger · section `6a8539a3c011bf786fef6b56`**

| # | Worksheet | alias | Worksheet ID | View ID (`全部`/Main) | record |
|---|---|---|---|---|---|
| 23 | `AC_VOUCHER` | `ac_voucher` | `6a85fb2e9b6999a714d2a53d` | `6a85fb2e9b6999a714d2a541` | 4 |
| 24 | `AC_VOUCHER_LINE` | `ac_voucher_line` | `6a85fb3933560633b8cd9f40` | `6a85fb3933560633b8cd9f44` | — |
| 25 | `AC_GL` | `ac_gl` | `6a85fb4133560633b8cd9f4a` | `6a85fb4133560633b8cd9f4e` | — |

**AC-03 Payable and Payment · section `6a8539cac011bf786fef6b59`**

| # | Worksheet | alias | Worksheet ID | View ID (`全部`/Main) | record |
|---|---|---|---|---|---|
| 26 | `AC_AP` | `ac_ap` | `6a8673d61049edca1eed0638` | `6a8673d61049edca1eed063c` | 0 |
| 27 | `AC_AP_LINE` | `ac_ap_line` | `6a8673e78b36df988c176b77` | `6a8673e78b36df988c176b7b` | — |
| 28 | `AC_PAY_REQ` | `ac_pay_req` | `6a8677b19b6999a714d2aa83` | `6a8677b19b6999a714d2aa87` | — |
| 29 | `AC_PAY` | `ac_pay` | `6a8677c38b36df988c176cd3` | `6a8677c38b36df988c176cd7` | — |
| 30 | `AC_PAY_LINE` | `ac_pay_line` | `6a8677d7055f2288c5b77d12` | `6a8677d7055f2288c5b77d16` | — |
| 31 | `AC_PAY_SETTLE` | `ac_pay_settle` | `6a8677de8b36df988c176d02` | `6a8677de8b36df988c176d06` | — |
| 32 | `AC_WHT` | `ac_wht` | `6a8677f1055f2288c5b77d1d` | `6a8677f1055f2288c5b77d21` | — |

**AC-04 Tax · section `6a8539e70f7255ac5594e0d9`**

| # | Worksheet | alias | Worksheet ID | View ID (`全部`/Main) | record |
|---|---|---|---|---|---|
| 33 | `AC_TAX_FILING` | `ac_tax_filing` | `6a8677c79b6999a714d2aa93` | `6a8677c79b6999a714d2aa97` | — |
| 34 | `AC_VAT_DOC` | `ac_vat_doc` | `6a8677f9055f2288c5b77d58` | `6a8677f9055f2288c5b77d5c` | — |

**AC-07 Close and Reconciliation · section `6a853b2f0f7255ac5594e0e1`** ✅ **สร้างใหม่ 27 ส.ค. 2569**

| # | Worksheet | alias | Worksheet ID | View ID (`全部`) | record |
|---|---|---|---|---|---|
| 35 | `AC_BANK_RECON` | `worksheet22` | `6a8fd69d1378964f9984a2ad` | `6a8fd69d1378964f9984a2b1` | 0 |
| 36 | `AC_BANK_RECON_LINE` | `worksheet23` | `6a8fd69e8b6633ef76f1313f` | `6a8fd69e8b6633ef76f13143` | 0 |
| 37 | `AC_CLOSE` | `worksheet24` | `6a8fd69e353e1b0e4a507e16` | `6a8fd69e353e1b0e4a507e1a` | 0 |
| 38 | `AC_CLOSING_ENTRY` | `worksheet25` | `6a8fd69f9762533b5b718bce` | `6a8fd69f9762533b5b718bd2` | 0 |
| 39 | `AC_OPENING` | `worksheet26` | `6a8fd69f353e1b0e4a507e20` | `6a8fd69f353e1b0e4a507e24` | 0 |

> ⚠️ alias ของทั้ง 5 ตารางนี้เป็น `worksheet22`…`worksheet26` (auto-generated จากบั๊ก `create_worksheet` — ดู §1.2c) ไม่ใช่ snake_case ตามธรรมเนียมเดิม · ชื่อไทย (Data Name) ตั้งผ่าน `addRecordButtonName` ครบแล้วทั้ง 5 ตาราง · field ทั้งหมดอยู่ใน FR-14 (AC_BANK_RECON, AC_BANK_RECON_LINE) และ FR-15 (AC_CLOSE, AC_CLOSING_ENTRY, AC_OPENING)

### §1.2b Worksheets ที่ **ยังไม่มี** — ต้องสร้าง (11 ตารางที่เหลือ)

> ต้นฉบับ `TILSNA-SDS-AC-001.md` §4.1 ระบุ inventory 49 ตาราง (ตัวเลข "44" ใน SDS §1.2 นับไม่ตรงกับตาราง — บันทึกไว้ใน `03-RTM-Status.md` §E)
> บนเซิร์ฟเวอร์มี 33 ตารางจากรายการนั้น **บวก `AC_PAY_LINE` ที่ไม่มีใน SDS** (ตารางลูกของใบสำคัญจ่าย — ถือว่าเป็นการปรับปรุงที่ยอมรับแล้ว) **บวก 5 ตารางที่สร้างใหม่ 27 ส.ค. 2569** (ดู §1.2 AC-07)

| Worksheet | ชนิด | เก็บอะไร | FR | ID | สถานะ |
|---|---|---|---|---|---|
| `AC_GFMIS_MAP` | Master | การแปลงรหัสบัญชีภายในเป็นรหัสมาตรฐานภาครัฐ | FR-17 | `<TBD-ws-ac_gfmis_map>` | ⬜ |
| `AC_AR` | Transaction | เอกสารลูกหนี้ / รับรู้รายได้ | FR-12 | `<TBD-ws-ac_ar>` | ⬜ |
| `AC_AR_LINE` | Transaction (child) | บรรทัดรายได้ — ภาพสะท้อนของ AC_AP_LINE | FR-12 | `<TBD-ws-ac_ar_line>` | ⬜ |
| `AC_BL` | Transaction | ใบแจ้งหนี้ (รวมแบบรวมหลายใบกำกับ) | FR-12 | `<TBD-ws-ac_bl>` | ⬜ |
| `AC_INV` | Transaction | ใบกำกับภาษี / ใบส่งของ — เอกสารภาษีขาย | FR-12 | `<TBD-ws-ac_inv>` | ⬜ |
| `AC_RE` | Transaction | ใบเสร็จรับเงิน | FR-12 | `<TBD-ws-ac_re>` | ⬜ |
| `AC_CN` | Transaction | ใบลดหนี้ — อ้างอิงใบกำกับต้นฉบับเสมอ | FR-12 | `<TBD-ws-ac_cn>` | ⬜ |
| `AC_DN` | Transaction | ใบเพิ่มหนี้ — อ้างอิงใบกำกับต้นฉบับเสมอ | FR-12 | `<TBD-ws-ac_dn>` | ⬜ |
| `AC_ASSET_BOOK` | Transaction | สมุดบัญชีสินทรัพย์ — มูลค่าและพารามิเตอร์ค่าเสื่อม | FR-13 | `<TBD-ws-ac_asset_book>` | ⬜ |
| `AC_DEPR_SCHEDULE` | Transaction | ตารางค่าเสื่อมรายสินทรัพย์รายงวด (ก่อนผ่านรายการ) | FR-13 | `<TBD-ws-ac_depr_schedule>` | ⬜ |
| `AC_DEPR` | Transaction | การผ่านรายการค่าเสื่อม สรุปตามประเภทและหน่วยงาน | FR-13 | `<TBD-ws-ac_depr>` | ⬜ |
| `AC_ASSET_DISPOSAL` | Transaction | การตัดจำหน่าย มูลค่าที่ได้รับ และกำไร/ขาดทุน | FR-13 | `<TBD-ws-ac_asset_disposal>` | ⬜ |

> ✅ **ย้ายออกจากตารางนี้แล้ว (สร้างสำเร็จ 27 ส.ค. 2569):** `AC_BANK_RECON` · `AC_BANK_RECON_LINE` · `AC_CLOSE` · `AC_CLOSING_ENTRY` · `AC_OPENING` — ดู §1.2 AC-07

### §1.2c 🔑 วิธีแก้บั๊ก `create_worksheet` — ยืนยันซ้ำแล้วบน `ERP_-_TILSNA` 27 ส.ค. 2569

> ค้นพบครั้งแรกในโปรเจกต์ `tilsna-hr` (บันทึกไว้ใน `tilsna-hr/04-CLAUDE-memory.md`) แล้วนำมาใช้ซ้ำสำเร็จในโปรเจกต์นี้ — ยืนยันว่าใช้ได้ข้าม connector/แอปที่ต่างกัน ไม่ใช่เรื่องเฉพาะ tenant เดียว

**อาการของบั๊ก:** เรียก `create_worksheet` ตรง ๆ (ส่ง `name` + `fields` พร้อมกัน) แล้วล้มเหลว/ทำงานไม่ครบ

**ขั้นตอนที่ใช้ได้จริง:**

1. `create_app_items` ด้วย `{type:"worksheet", name:"<ชื่อไทย>", sectionId:"<section id>"}` — สร้าง worksheet เปล่าที่มี 3 ฟิลด์ default อัตโนมัติ (名称=isTitle Text, 描述=Text multiLine, 附件=Attachment)
2. `update_worksheet` **เรียกครั้งเดียว** ส่งทั้ง `removeFields` (ID ของ 3 ฟิลด์ default) **และ** `addFields` (ฟิลด์จริงทั้งหมด รวม Relation ที่ `dataSource` ชี้ worksheet ที่มีอยู่แล้ว) — ยืนยันว่ารวมเป็นคำสั่งเดียวได้ ไม่ต้องแยกสองครั้ง
3. `get_worksheet_structure` ตรวจว่าฟิลด์จริงเข้าไปถูกต้อง (ID, type, dataSource, option key)
4. `update_worksheet` อีกครั้งด้วยพารามิเตอร์ `addRecordButtonName` (ไม่มีในเอกสาร แต่ใช้ได้จริง) เพื่อตั้งชื่อไทยของปุ่ม/Data Name

**ชนิดฟิลด์ที่ยืนยันว่าสร้างผ่าน `addFields` ได้:** Text, Number, SingleSelect, MultipleSelect, Date, DateTime, Collaborator, Relation, Checkbox, Role
**ยังไม่ยืนยัน/ต้องใช้ Browser หรือ CLI:** Department, SubTable, Formula, AutoNumber, Location, Rollup — MCP สร้างไม่ได้ · **ลอง `hap worksheet add-fields` (Surface C) ก่อนเข้า Browser** [S] ยังไม่เคยยิงกับ tenant นี้
> ✅ **แก้ 30 ส.ค. 2569 — ประโยคเดิมที่ว่า Dropdown ผูก shared optionset "ต้องทำใน Browser" ผิดและขัดกับ §1.3 ของเอกสารนี้เอง** (ดูบรรทัด "ข้อค้นพบ 26 ส.ค." และ "`create_optionset` สร้าง optionset ได้") — **ผูกผ่าน API ได้จริง** ส่ง `dataSource` = optionset id บนฟิลด์ชนิด `Dropdown` ยิงจริงสำเร็จ 26 ส.ค. 2569

### §1.3 Optionsets (shared) — 30 ชุด

**ผูกกับฟิลด์แล้ว (21 ชุด)**

| Optionset | ID | options (value → key) | ผูกกับฟิลด์ |
|---|---|---|---|
| `OS_DOC_STATUS` | `0bdd7e11-c2bc-44cb-a25a-34009a1436a2` | Draft `3536165d-460c-4942-8bec-6f381209d8da` · Pending approval `982090bd-bec8-4cec-a0e5-7b4de07d4d13` · Approved `69d8e25d-e949-49a6-aba6-11e1732f59d1` · Posted `a234503a-f4fd-4d8a-86c3-34a2d9ed219f` · Cancelled `e0474c62-202d-4a41-98ff-7c4cf417eec8` · Reversed `8ce6c682-5c42-42f3-b6a9-62ea17a12205` | AC_VOUCHER.status (alias `status1`) |
| `OS_PERIOD_STATUS` | `e9ae2c06-eb06-45ee-a2ee-4eb1757f1116` | Open `f662571c-3de0-4e4c-9828-9172e337d223` · Soft-closed `b2986cb5-59db-4fdc-87ed-d57a38201c6a` · Permanently locked `38392e32-7c09-4339-a9b4-81a9f53eba0a` | AC_PERIOD.period_status |
| `OS_TAX_PERIOD_STATUS` | `a04fa23c-4498-473a-9637-12e754802d06` | Open `d41e3a2e-684b-4533-9913-09a04302626e` · Filed `fa108e9e-c642-4740-af6a-a6964ecc50d3` · Amended `3d94b4e7-170b-47ee-a5e1-e3a2e415cfa4` | AC_PERIOD.tax_period_status |
| `OS_ACCOUNT_TYPE` | `1c7f8e6f-4353-45b7-ab5d-a7bf378d373d` | Asset `eb611620-08c4-437f-8b3a-82ede5b2d943` · Liability `87120a74-f416-470f-90ce-3b3be2d2dd3f` · Equity `1e26342f-db85-4079-b58a-698e6f776ba5` · Revenue `9219f18a-5776-46c9-b42a-6c1a6bd129f7` · Expense `047a0a8e-027b-4ddc-b64d-975de50b6f2e` | AC_COA.account_type |
| `OS_ACCOUNT_GROUP` | `ffaa0703-87d3-4c56-b1be-4d10b9112eb3` | 10 ค่า — Current asset `d89e8412-…` … Other `521683be-…` (ดูตารางฟิลด์ FR-03) | AC_COA.account_group |
| `OS_NORMAL_BALANCE` | `4c41d346-4823-4c60-924f-c6f7744b7d70` | Debit `f3042960-4a2d-4fcc-856a-3a1d1683932a` · Credit `1288a1c8-115d-4293-bddc-077cb623fe4d` | AC_COA.normal_balance |
| `OS_SOURCE_MODULE` | `098ff000-5d07-4c73-9622-c37e691f9f75` | Manual `3f9b4640-…` · Scan `add7f979-…` · Procurement `d07bebc6-…` · Finance `c2b119a5-…` · Asset `901a32f6-…` · Payroll `914f5226-…` · Tax `23db6df8-…` · Period close `5d980264-…` | AC_VOUCHER.source_module |
| `OS_PRICE_BASIS` | `abd98ad7-017f-4af5-8edd-1a0e26d1419d` | VAT-exclusive `b3171393-58cd-4a43-b241-b83548e37f3f` · VAT-inclusive `77f0e10d-e397-4822-8342-d3b803e7ba88` | AC_DOC_SETTING.default_price_basis |
| `OS_COMPUTE_POSITION` | `3ac59595-7dba-4e49-822c-e8ba261f5764` | Line level `2e2e0f4e-7553-4523-afd8-7fe886173bcc` · Document level `7397640a-c70e-47cd-a4a3-b23e003b8801` | AC_DOC_SETTING.vat_/discount_/wht_compute_position (3 ฟิลด์ใช้ชุดเดียวกัน) |
| `OS_WHT_TIMING` | `b55a29cd-8827-43a1-bf5f-677fd691329c` | At invoice `250c24af-dc6b-452d-a1cb-eefcc736f0fb` · At payment `998bd1a6-1d3b-4b57-9b8e-9587624b3614` | AC_DOC_SETTING.wht_timing |
| `OS_COMPLETION_MODE` | `7eb8ad24-65e2-411e-ab58-a7f030f21876` | All must approve `0605fa6b-13ff-4063-b41f-ae690e450e23` · Any one may approve `fe6a0464-36ce-4553-9ad8-bfb2cfb431ab` | AC_APPROVAL_RULE.completion_mode |
| `OS_DATE_PATTERN` | `9242ead9-9da9-4b41-a5a7-9889c0b977d5` | None `b33e3220-…` · Year `5f1bb091-…` · Year-month `89d7165e-…` · Year-month-day `9f7d4abd-…` | AC_DOC_NUMBER_RULE.date_pattern |
| `OS_RESET_CYCLE` | `24ee40c8-2c68-4cd4-8d1f-1d24a80c7304` | Never `76525298-…` · Yearly `0263cfa6-…` · Monthly `fd01abe2-…` · Daily `9f87515c-…` | AC_DOC_NUMBER_RULE.reset_cycle |
| `OS_FORM_TYPE` | `7b605ddd-bf7f-4837-9fa7-e6ae2153b2f8` | ⚠️ **ค่าบนเซิร์ฟเวอร์เป็นอักษรโรมัน ไม่ใช่ไทย**: `P.P.30` → `d6c591cf-32c0-43d0-916d-803266f5e121` · `P.P.36` → `614d5168-334c-4cb2-bd34-cda27357d134` · `P.N.D.3` → `86d28c16-c735-403b-beb1-1573990188d6` · `P.N.D.53` → `08e5c9c1-bcd7-4e28-9a08-ed0c028dc21b` · `P.N.D.54` → `2b0971ed-7db0-4a2e-ba7b-e83d6b18a987` | AC_WHT_RATE.form_type · AC_WHT_INCOME_TYPE.form_type |
| `OS_LEGAL_FORM` | `b97a1a08-78ab-4683-8472-837c48af4423` | Juristic person `adf4bb5f-…` · Individual `1aeb1a04-…` | AC_PARTNER.legal_form · AC_WHT_RATE.payee_legal_form |
| `OS_BRANCH_TYPE` | `081f8bfc-bab8-4a89-91cf-ea3e501b3b4c` | Head office `6ec11519-…` · Branch `f5abd6cd-…` | AC_PARTNER.branch_type |
| `OS_PARTNER_TYPE` | `fd947876-5402-408c-8c09-87db96c188c5` | Customer `90ce110c-…` · Supplier `13235e3d-…` | AC_PARTNER.partner_type (MultipleSelect) |
| `OS_ITEM_TYPE` | `b6d21a09-f425-491c-9c2c-0c0d832a4ecf` | Goods `f9a1e0c2-…` · Service `b705d9f2-…` | AC_ITEM.item_type |
| `OS_FX_RATE_TYPE` | `6dcb809e-06b3-4166-9ba4-b426ccc2b639` | Buying `d5815116-…` · Selling `3413a137-…` · Average `a297fbff-…` · Reference `d71fcd1b-…` | AC_FX_RATE.rate_type |
| `OS_DEPR_METHOD` | `c66475a4-14fb-4156-990e-92163ee9c8ee` | Straight line `ed9d0c63-0c76-4043-9257-bbc797ec6904` · Declining balance `4e88576a-ede3-4600-9c1e-04f0b5de65fe` | AC_ASSET_CATEGORY.default_method |
| `OS_PAYMENT_METHOD` | `32bfb7c2-a519-4aa0-820a-f777b533e719` | Cash `90bb0b39-…` · Bank transfer `4bb5ba34-…` · Cheque `2c443ee1-…` | AC_PAYMENT_CHANNEL.channel_name |

**✅ optionset ที่เคยกำพร้า — ผูกกับฟิลด์ครบแล้ว 26 ส.ค. 2569 (9 ชุด)**

> เดิมทั้ง 9 ชุดถูกสร้างไว้แต่ไม่มีฟิลด์ใดผูก ⇒ เป็นหลักฐานว่าฟิลด์สถานะยังไม่ถูกสร้าง
> **ตอนนี้สร้างฟิลด์และผูกครบแล้วทุกชุด** (ยกเว้น `OS_AR_STATUS` / `OS_ASSET_STATUS` / `OS_DISPOSAL_METHOD` ที่ยังรอตารางใน FR-12 / FR-13) — field id จริงอยู่ในตารางของแต่ละ FR
> 🔑 **ข้อค้นพบ 26 ส.ค.:** ผูก shared optionset **ผ่าน API ได้** โดยส่ง `dataSource` = optionset id บนฟิลด์ชนิด `Dropdown` — **ไม่ต้องเข้า Browser** ตามที่ playbook เคยระบุ

| Optionset | ID | options (value → key) | ฟิลด์ปลายทางที่ต้องสร้าง |
|---|---|---|---|
| `OS_AP_STATUS` | `9f29af16-6473-43d5-8104-96cde3dd78f3` | Draft `e10952c6-e7ba-4e07-8eae-30ac75aa28b4` · Pending approval `35be3f29-0c23-4687-b1da-d48a99527da7` · Recognised `ffca5173-7642-4853-85a6-52f08ad70009` · Partially paid `b8914358-76bb-4dc4-9768-368e2c4cf841` · Fully paid `7c3abf94-d5dd-40ee-8b9a-2a9e38c790e2` · Cancelled `60a0ca22-5d47-4fa7-b37e-42f230f43875` | AC_AP.ap_status — **ยังไม่มีฟิลด์นี้** (FR-07) |
| `OS_AR_STATUS` | `d3fad393-d804-4034-9751-a3858f3c54e9` | Draft `ec7e70b0-…` · Pending approval `a7dd4d1b-…` · Recognised `39733f26-…` · Partially collected `8d02d91b-…` · Fully collected `4765d973-…` · Cancelled `ead82ee7-…` | AC_AR.ar_status — **ยังไม่มีทั้งตารางและฟิลด์** (FR-12) |
| `OS_VAT_SIDE` | `32f06106-b262-4847-bcc2-dfab3153418d` | Input `fa5f09e9-5ee1-4368-a4be-01580459b983` · Output `b76cdc18-743c-4822-b2aa-110b5a162768` | AC_VAT_DOC.vat_side — **ยังไม่มีฟิลด์นี้** (FR-10) 🔴 ทำให้แยกภาษีซื้อ/ขายไม่ได้ |
| `OS_VAT_DOC_STATUS` | `162d4782-91ff-4553-9ab5-01a6b6862862` | Awaiting tax invoice `d4514d7d-…` · Tax invoice received `73da6436-…` · Claimed `79e3b7e4-…` · Filed `023498c0-…` · Not claimable `343e36ca-…` | AC_VAT_DOC.claim_status — **ยังไม่มีฟิลด์นี้** (FR-10) 🔴 ทำให้คุม tax point ไม่ได้ |
| `OS_WHT_BORNE_BY` | `ce278c49-c743-4311-a202-369451db4144` | Payee `46d4ae25-…` · Payer (single payment) `5f9ef035-…` · Payer (permanent) `a577d502-…` | AC_AP_LINE.wht_borne_by — **ยังไม่มีฟิลด์นี้** (FR-07) ทำให้ gross-up ไม่ได้ |
| `OS_FILING_TYPE` | `072eb596-9774-4d6b-98f8-fb712cdcd3ea` | Normal `d3a384b9-78e3-4875-9bc6-a3b261880543` · Additional `dfa22f2b-4e58-4172-aaef-965336e9949f` | AC_TAX_FILING.filing_type — **ยังไม่มีฟิลด์นี้** (FR-11) |
| `OS_FILING_STATUS` | `edb8daeb-8835-4c17-bf5f-db93e984a7d1` | Draft `fcd7fa27-…` · Approved `f8c0a410-…` · Filed `746ab42c-…` · Paid `58f6096f-…` · Amended `1ca5071a-…` | AC_TAX_FILING.filing_status — **ยังไม่มีฟิลด์นี้** (FR-11) |
| `OS_ASSET_STATUS` | `4f3a273d-6971-4c86-8b33-b005b118d5d3` | In use `8c42f795-…` · Suspended `5e0d09a2-…` · Retired `45103a03-…` | AC_ASSET_BOOK.asset_status — **ยังไม่มีทั้งตารางและฟิลด์** (FR-13) |
| `OS_DISPOSAL_METHOD` | `2fdba55a-ac2d-438b-badf-58445669f1ed` | Sale `102c5754-…` · Write-off `a2e9b123-…` · Donation `c28f2079-…` · Trade-in `787c4947-…` | AC_ASSET_DISPOSAL.disposal_method — **ยังไม่มีทั้งตารางและฟิลด์** (FR-13) |

> 🔴 **label ของ option บนเซิร์ฟเวอร์เป็นภาษาอังกฤษ/อักษรโรมันทั้งหมด** (`Draft`, `Pending approval`, `P.P.30` …) — เอกสารชุดนี้เขียนคำอธิบายเป็นไทยเพื่อให้อ่านง่าย แต่ **workflow และ filter ทุกจุดต้องอ้าง `key` ไม่ใช่ label** · ถ้าจะเปลี่ยน label เป็นไทยให้ทำครั้งเดียวใน Browser แล้วบันทึกลงตารางนี้

**optionset ที่สร้างใหม่ 26 ส.ค. 2569 (4 ชุด)**

| Optionset | ID | options | ผูกกับฟิลด์ |
|---|---|---|---|
| `OS_PAYREQ_STATUS` | `4ab44bf7-1c5f-48c1-9669-8ac180dc4fc0` | Draft `08092993-906a-4956-b0ff-6f91f766fe61` · Pending approval `e2c2a9dc-b419-481b-9d59-ffc15d3ccac5` · Approved `b96dfce0-92fe-43f9-8dea-61d948d137fb` · Rejected `de0313ee-d908-476f-9274-cae4020be0b6` · Payment voucher issued `4eba71d6-3565-43d4-bedf-60473f92553d` · Cancelled `fba662e2-5012-4450-ab9f-0913b28bd572` | `AC_PAY_REQ.req_status` `6a8ead839762533b5b717035` |
| `OS_PAY_STATUS` | `d2d61597-824a-42b6-a9bd-5d98a856516e` | Draft `abe8163a-9ba8-43e7-8388-553f7679f6d3` · Pending approval `30078aa4-ee7f-4559-a41b-9a3f3b650a7a` · Approved `06961b0a-4937-4224-9ea5-a3b83d10ff86` · Sent to Finance `9da5bcd0-052b-4f0a-9278-f1177bf12a96` · Paid `d1458ded-290f-41d3-b358-5720a206a12d` · Cancelled `44b3350e-8d2c-45ff-82e1-d153d1b92c02` | `AC_PAY.pay_status` `6a8ead8f1378964f998490f6` |
| `OS_SETTLE_STATUS` | `b028f1d7-ec71-465a-afd0-ba9c0fe09788` | Awaiting payment `8de696f1-b103-49b2-852a-62123a0dd7ea` · Paid `9e7fbebc-3af7-4932-8592-aad7012a9fdb` · Cancelled `051d7c57-2567-4301-bb42-78907346b9f4` | `AC_PAY_SETTLE.settle_status` `6a8ead961378964f9984911e` |
| `OS_WHT_STATUS` | `b2f5604d-d432-434f-aae9-16ae87732eb9` | Issued `aa03d4a6-12c4-4e91-a180-eb6a4b650169` · Printed `1cb06165-37bf-4691-9d7d-21b511f4f0f2` · Included in filing `bb0ad4a2-7b0a-4b01-bacf-5b5dd9357d35` · Cancelled `b7f38a58-b6ed-488f-95cb-2076032bbd86` | `AC_WHT.wht_status` `6a8ead9f9762533b5b717054` |

> ✅ อ่าน key กลับมาครบแล้ว 26 ส.ค. 2569 · ทั้ง 4 ชุดเปิดใช้สี (`enableColor`) ต่างจาก 30 ชุดเดิมที่ไม่มีสี
> ⬜ **เหลือ optionset กำพร้าจริง 3 ชุด**: `OS_AR_STATUS` `d3fad393-…` · `OS_ASSET_STATUS` `4f3a273d-…` · `OS_DISPOSAL_METHOD` `2fdba55a-…` — รอตารางใน FR-12 / FR-13

> ✅ **`create_optionset` สร้าง optionset ได้ และผูกกับฟิลด์ผ่าน API ได้ด้วย** — ส่ง `dataSource` = optionset id ตอน `addFields` ชนิด `Dropdown` (ยิงจริง 26 ส.ค. · แก้ข้อมูลเดิมที่ว่าต้องทำใน Browser) · workflow condition อ้าง **key** ไม่ใช่ label เสมอ

### §1.4 Roles (custom) — **มีจริงแล้วทั้ง 8 บทบาท**

> 🔬 **ข้อค้นพบ 26 ส.ค. 2569:** บน tenant นี้ `get_role_list` **คืน custom application role ครบทั้ง 8 ตัวพร้อม ID** — ต่างจากที่ playbook เคยระบุว่าคืนเฉพาะ org role (บันทึกไว้ใน `03-RTM-Status.md` §E)

| Role | ID | roleType | สมาชิก | สถานะ permission |
|---|---|---|---|---|
| AC-R1 Accounting Officer | `c5819f0b-34f6-449b-a812-f8ec02073b85` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI |
| AC-R2 Accounting Supervisor | `80bac1f7-44b2-4c5c-8808-53e4de14e2bf` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI |
| AC-R3 Director of Finance and Accounting | `4de23d6f-a011-4308-9849-d1335183d34e` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI |
| AC-R4 Master Data Steward | `1abb24d0-61a7-47fe-bcd5-a20bd59e5d94` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI |
| AC-R5 Internal Auditor | `7bda33aa-992f-4fef-acdb-8991fb6ac51f` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI |
| AC-R6 Executive | `7004ac7f-b40a-4e27-a584-0a04f5b5858b` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI |
| AC-R7 Requester | `05296745-693a-431e-a1fa-a7835f381192` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI · record scope ต้องเป็น "เฉพาะที่ตนสร้าง" |
| AC-R8 System Administrator | `ba6a6769-08c4-4906-bc16-953decfadfee` | 0 | (ว่าง) | ⚠️ ต้องตั้ง/ตรวจใน UI · **ห้ามมีสิทธิ์อนุมัติ/ผ่านรายการ** (NFR-12) |

**Org role พื้นฐาน (มีมากับระบบ ห้ามแก้):** 管理员 `aeb31e00-16a3-4d83-adc7-23f150cdac65` (สมาชิก: Kunlasatri.c `202df0a6-d681-466f-af36-942186dea09c`, Wanadtapong.l `4dc40ac1-a142-4585-a460-713466f037cf`) · 运营者 `151b7b32-…` · 开发者 `d45f5443-…` · 成员 `63c6e77b-…` · 只读 `210aa5bb-…`

**🔴 งานค้าง:** ทั้ง 8 role **ไม่มีสมาชิกเลย** และยังไม่ได้ยืนยันว่า permission ถูกตั้งตาม matrix ด้านล่าง — ต้องทำก่อนอ้างว่า FR-19 เสร็จ

**Permission matrix (แปลงจาก `01-BRD.md` §5 / `TILSNA-SDS-AC-001.md` §3.2)**

> รหัส recordDataScope: `0` ไม่มีสิทธิ์ · `20` เฉพาะที่ตนสร้าง · `30` ตนเอง + ผู้ใต้บังคับบัญชา · `100` ทั้งหมด
> ⚠️ ความหมายของรหัสมาจากสกิล **ยังไม่ยืนยันกับ tenant นี้** — ก่อนตั้งเป็นชุด ให้เรียก `get_role_details` กับ role ที่ตั้งค่าแล้ว 1 ตัวเพื่อยืนยันความหมายก่อน

| กลุ่ม Worksheet | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 |
|---|---|---|---|---|---|---|---|---|
| ข้อมูลตั้งค่า (AC_JOURNAL, AC_DOC_TYPE, AC_DOC_NUMBER_RULE, AC_DOC_SETTING, AC_APPROVAL_RULE, AC_POSTING_RULE) | read 100 | read 100 | read 100 | read/edit 100 · create ✓ | read 100 | read 100 | 0 | read 100 · **ไม่มี approve** |
| ข้อมูลหลัก (AC_COA, AC_COST_CENTER, AC_FUND, AC_PROJECT_DIM, AC_ITEM, AC_VAT_RATE, AC_WHT_RATE, AC_WHT_INCOME_TYPE, AC_CURRENCY, AC_FX_RATE, AC_ASSET_CATEGORY, AC_PAYMENT_CHANNEL, AC_BANK) | read 100 | read 100 | read 100 | read/edit 100 · create ✓ | read 100 | read 100 | 0 | read 100 |
| AC_PARTNER, AC_PARTNER_BANK | read 100 | read 100 | read 100 | read/edit 100 · create ✓ | read 100 | read 100 · **ซ่อน `tax_id`, `AC_PARTNER_BANK.account_no`** (NFR-02) | 0 | read 100 |
| AC_PERIOD | read 100 | read 100 | read/edit 100 · **approve** | read/edit 100 | read 100 | read 100 | 0 | read 100 |
| AC_VOUCHER, AC_VOUCHER_LINE | create ✓ · read 100 · **edit เฉพาะ record ที่ตนสร้าง และสถานะ = Draft** | read/edit 100 · **approve** | read/edit 100 · **approve** | read 100 | read 100 | read 100 | 0 | read 100 |
| AC_GL | read 100 · **edit 0 · delete 0** | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | read 100 · edit 0 | 0 | read 100 · **edit 0** |
| AC_AP, AC_AP_LINE | create ✓ · read/edit 100 | read/edit 100 · **approve** | read/edit 100 · **approve** | read 100 | read 100 | read 100 | **read 20** | read 100 |
| AC_PAY_REQ | create ✓ · read/edit 100 | read/edit 100 · **approve** | read/edit 100 · **approve** | read 100 | read 100 | read 100 | **create ✓ · read/edit 20** | read 100 |
| AC_PAY, AC_PAY_LINE, AC_PAY_SETTLE | create ✓ · read/edit 100 | read/edit 100 · **approve** | read/edit 100 · **approve** | read 100 | read 100 | read 100 | **read 20** | read 100 |
| ภาษี (AC_VAT_DOC, AC_WHT, AC_TAX_FILING) | create ✓ · read/edit 100 | read/edit 100 · **approve** | read/edit 100 · **approve** | read 100 | read 100 | **0** | 0 | read 100 |
| สินทรัพย์ (AC_ASSET_BOOK, AC_DEPR_SCHEDULE, AC_DEPR, AC_ASSET_DISPOSAL) `<ยังไม่มีตาราง>` | create ✓ · read/edit 100 | read/edit 100 · **approve** | read 100 | read 100 | read 100 | read 100 | 0 | read 100 |
| AC_BANK_RECON, AC_BANK_RECON_LINE ✅ **มีตารางแล้ว 27 ส.ค. — permission ยังไม่ได้ตั้ง** | create ✓ · read/edit 100 | read/edit 100 · **approve** | read 100 | **0** | read 100 | **0** | 0 | read 100 |
| ปิดงวด (AC_CLOSE, AC_CLOSING_ENTRY, AC_OPENING) ✅ **มีตารางแล้ว 27 ส.ค. — permission ยังไม่ได้ตั้ง** | create ✓ · read/edit 100 | read/edit 100 | read/edit 100 · **approve** | **0** | read 100 | read 100 | 0 | read 100 |
| เอกสารขาย (AC_AR…AC_DN) `<ยังไม่มีตาราง>` | create ✓ · read/edit 100 | read/edit 100 · **approve** | read/edit 100 · **approve** | read 100 | read 100 | read 100 | **read 20** | read 100 |

> การกรองแบบ "เห็นเฉพาะหน่วยงานตัวเอง" ทำด้วย recordDataScope ไม่ได้ (API รองรับเฉพาะ own / own+subordinates / all) → ใช้ **View filter + `recordPermissionInViews`**

### §1.5 Workflows — **2 ตัวสร้างและ publish แล้ว**

> 🔬 หลักฐาน 26 ส.ค. 2569: `get_workflow_list` คืน `{"processes":[]}` (จุดบอดที่รู้อยู่แล้ว — คืนเฉพาะ PBP) **และ** `get_record_logs` ของ AC_VOUCHER record `74750822-0ff2-4eaa-b273-e0a38066716d` มี operator เป็น `user-api` ทั้งหมด ไม่มี `user-workflow` เลย (ก่อนสร้าง WF-AC-01/02)
> ⇒ **ก่อนสร้างตัวใหม่ ให้เปิดหน้า Automated Workflow ยืนยันด้วยตาก่อนหนึ่งครั้ง** แล้วบันทึกผลลงตารางนี้

| Workflow | ชนิด trigger | Surface | ID | สถานะ | FR |
|---|---|---|---|---|---|
| WF-AC-01 อนุมัติใบสำคัญ | `worksheet_event` (update) | MCP | **`6a8eaa45e6605c4b13ccf49b`** · สายอนุมัติภายใน **`6a8eaa76730d20c5b76071f3`** | 🔶 publish แล้ว · เส้นทางตรวจดุล/ตรวจงวดพิสูจน์แล้ว · การกดอนุมัติจริงยังไม่ทดสอบ | FR-06 |
| WF-AC-02 ผ่านรายการเข้าบัญชีแยกประเภท | `worksheet_event` (update) | MCP | **`6a8ea77e5f8564a68c33f9db`** · subprocess วนบรรทัด **`6a8ea79efdab77a41c4a37d6`** | ✅ พิสูจน์ครบรวมการยิงซ้ำ | FR-06 |
| WF-AC-03 รับรู้หนี้สินจากการตรวจรับ | `webhook` | MCP | `<TBD>` | ⬜ | FR-07/17 |
| WF-AC-04 ตัดชำระเมื่อได้ผลการจ่าย | `webhook` | MCP | `<TBD>` | ⬜ | FR-08/17 |
| WF-AC-05 รับรู้ลูกหนี้และการรับชำระ | `worksheet_event` (update) | MCP | `<TBD>` | ⬜ | FR-12 |
| WF-AC-06 ออกใบรับรองหัก ณ ที่จ่าย | `worksheet_event` (update) | MCP | `<TBD>` | ⬜ | FR-09 |
| WF-AC-07 คิดและผ่านรายการค่าเสื่อมรายเดือน | `schedule` | MCP | `<TBD>` | ⬜ | FR-13 |
| WF-AC-08 กระทบยอดธนาคาร | `worksheet_event` (add) | MCP | `6a8ff2c0fdab77a41c543108` | ✅ **สร้าง publish และทดสอบผ่านครบ 27 ส.ค. 2569 (รอบเย็น) v3** | FR-14 |
| WF-AC-09 ปิดงวด | Custom Action → `worksheet_event` | MCP | **`6a903ec05f8564a68c3f7d7d`** | ✅ **สร้าง publish (v1) และทดสอบผ่านครบทั้ง 2 เส้นทาง 27 ส.ค. 2569 (รอบเย็น ต่ออีกครั้ง) — 16 nodes + trigger** | FR-15 |
| WF-AC-10 กลับรายการใบสำคัญ | Custom Action → `worksheet_event` | MCP | **`6a8f49b8730d20c5b764f302`** (published v4) | ✅ **แก้ 30 ส.ค. 2569 — แถวนี้เคยเขียน `<TBD>` / ⬜ ทั้งที่สร้างและทดสอบเสร็จ 100% ตั้งแต่ 27 ส.ค.** (logic 2 path + UI Scope + data integrity ปิดครบ — ดู `11-Workflow-Engine-Blocked-27Aug.md` และ Change Log ของ `05-Roadmap-Tracker.md`) ⚠️ **ID หายจาก Registry แปลว่า agent รอบถัดไปเสี่ยงสร้างซ้ำทั้งตัว** | FR-06 |
| WF-AC-11 ปิดปีและยกยอด | Custom Action → `worksheet_event` | MCP | **`6a90ef69fdab77a41c5b514f`** | ✅ **สร้าง publish (v1) และทดสอบผ่านครบทั้ง 2 เส้นทาง 28 ส.ค. 2569 — 56 nodes + trigger + 4 inner sub-process** | FR-15 |
| WF-AC-12 แจ้งเตือนความผิดปกติทางบัญชี | `schedule` (ทุกเช้าวันทำการ) | MCP | `6a9032d3fdab77a41c56420b` | ✅ | FR-18 |
| WF-AC-13 รับเอกสารจากการสแกน | `worksheet_event` (create) + AI node | **Browser** (AI node นอก 17 ชนิดที่ MCP สร้างได้) | `<TBD>` | ⬜ | FR-18 |
| WF-AC-14 รอบเตรียมจ่าย | `worksheet_event` (update) + `schedule` | MCP | `<TBD>` | ⬜ | FR-08 |
| WF-AC-15 ลงทะเบียนและใช้เครดิตภาษีซื้อ | `worksheet_event` (create+update) | MCP | `<TBD>` | ⬜ | FR-10 |
| WF-AC-16 เตรียมแบบ ภ.พ.30 | `schedule` (หลังสิ้นเดือน) | MCP | `<TBD>` | ⬜ | FR-11 |
| WF-AC-17 เตรียมแบบ ภ.ง.ด. และไฟล์นำส่ง | `schedule` (หลังสิ้นเดือน) | MCP | `<TBD>` | ⬜ | FR-11 |
| WF-AC-18 แปลงเอกสารขายตามห่วงโซ่ | Custom Action → `worksheet_event` | MCP | `<TBD>` | ⬜ | FR-12 |
| WF-AC-19 ออกใบลดหนี้ / ใบเพิ่มหนี้ | `worksheet_event` (update) | MCP | `<TBD>` | ⬜ | FR-12 |
| WF-AC-20 ผ่านรายการสมุดรายวันเงินเดือน | `webhook` | MCP | `<TBD>` | ⬜ | FR-17 |
| WF-AC-21 ตั้งสินทรัพย์และตัดจำหน่าย | `worksheet_event` (update) | MCP | `<TBD>` | ⬜ | FR-13 |
| WF-AC-22 ปรับปรุงอัตราแลกเปลี่ยนปลายงวด | `schedule` | MCP | `<TBD>` | ⬜ | FR-15 |

> **Surface default = MCP** · เขียน **Browser** เฉพาะ workflow ที่ใช้ trigger นอก 4 ชนิด (`worksheet_event` / `schedule` / `date_field` / `webhook`) หรือ node นอก 17 ชนิดที่ MCP สร้างได้ (Loop, Terminate, Send API Request, JSON Parsing, Print Record, AI nodes …) — และเมื่อเป็นแบบนั้นให้ทำ **ทั้ง workflow** ใน Browser ห้ามแบ่งกราฟเดียวข้าม surface
> ⚠️ **WF-AC-02 ใช้ node Loop** ซึ่ง MCP สร้างไม่ได้ → ดูทางเลี่ยงใน `15-Workflow-Catalog-AC.md` §3 WF-AC-02

### §1.6 Custom Actions (ปุ่มบน record) — สร้างแล้ว 5 ปุ่ม (แก้ 30 ส.ค. 2569)

> ✅ **Scope ปิดครบทั้งโมดูลแล้ว 31 ส.ค. 2569 — กวาดครบ 34 ตาราง เจอปุ่มทั้งหมด 5 ปุ่ม `isAllView: 1` ทุกตัว ไม่มีปุ่มไหนซ่อนอยู่อีก**
>
> ประวัติ: 30 ส.ค. ตรวจด้วย `hap worksheet custom-actions` พบ `ac_period` 2 ปุ่ม (ปิดงวด `6a903eb89762533b5b71c4b2`, ปิดปีและยกยอด `6a90f50e1378964f9984df83`) เป็น `isAllView: 0` ⇒ **WF-AC-09 และ WF-AC-11 ที่ทดสอบผ่านครบแล้ว ไม่มีทางถูกเรียกจากหน้าจอจริง** · **แก้แล้ว 31 ส.ค. ผ่าน Browser** (Custom Action → Scope → All Records) ยืนยันซ้ำด้วย API ว่า `isAllView` เป็น `1` จริงทั้งคู่
>
> 🔑 **ต้นเหตุที่เห็นกับตาบนหน้าจอ — ละเอียดกว่าที่กับดักข้อ 20 เคยเขียนไว้:** ปุ่มไม่ได้ "ไม่มี scope" แต่ถูกตั้งเป็น **`Specified View` โดยไม่ได้ติ๊ก view ใดเลยสักช่อง** จึงไม่โผล่ที่ไหน · การแก้คือเปลี่ยน radio เป็น **All Records** ซึ่ง **บันทึกทันทีไม่มีปุ่ม Save**
>
> 📌 **วิธีตรวจที่ถูกจากนี้ไป — ไม่ต้องเปิด Browser:** `hap worksheet custom-actions <ws>` → อ่าน `isAllView` (`1` = All Records เห็นได้ · `0` + `displayViews: []` = Unassigned View ไม่โผล่) · **การ *ตั้ง* ยังต้อง Browser เท่านั้น การ *ตรวจ* ไม่ต้องแล้ว**
>
> ⚠️ **หัวข้อเดิมเขียนว่า "ยังไม่มีสักปุ่ม" ซึ่งขัดกับตารางของตัวเอง** — ตอนนี้มีปุ่มจริงบนเซิร์ฟเวอร์แล้วอย่างน้อย 5 ปุ่ม: บน `ac_voucher` 3 ปุ่ม (ส่งอนุมัติ `6a8f380b1378964f99849bfe` · ยกเลิกใบสำคัญ `6a8f380bae2a0e3743a0bedb` · กลับรายการ — งาน 2.2 ครบ 3/3) และบน `ac_period` 2 ปุ่ม (ปิดงวด `6a903eb89762533b5b71c4b2` · ปิดปีและยกยอด `6a90f50e1378964f9984df83`) · แถวที่ยังเป็น `<TBD>` ด้านล่างคือปุ่มที่**ยังไม่ได้สร้าง** ไม่ใช่ว่าไม่มีปุ่มเลย

| ปุ่ม | Worksheet · scope | ชนิด | ทำอะไร | เปิดใช้เมื่อ (`enableWhen`) | Role ที่เห็น | ยืนยัน | ID | Surface |
|---|---|---|---|---|---|---|---|---|
| ส่งอนุมัติ | `ac_voucher` · Record details ทุก view | `updateCurrentRecord` | `status1` = Pending approval `982090bd-…` → WF-AC-01 รับช่วง | `status1` equals Draft `3536165d-…` | R1 | ✓ | `<TBD>` | MCP (unverified) |
| ยกเลิกใบสำคัญ | `ac_voucher` | `updateCurrentRecord` | `status1` = Cancelled `e0474c62-…` | `status1` in (Draft, Pending approval) | R1, R2 | ✓ + ระบุเหตุผล | `<TBD>` | MCP (unverified) |
| กลับรายการ | `ac_voucher` | `triggerWorkflow` → WF-AC-10 | สร้างใบสำคัญกลับรายการ | `status1` equals Posted `a234503a-…` | R3 | ✓ + ระบุเหตุผล | `<TBD>` | MCP (unverified) |
| ส่งตั้งหนี้เพื่ออนุมัติ | `ac_ap` | `updateCurrentRecord` | `ap_status` = Pending approval `35be3f29-…` | `ap_status` equals Draft `e10952c6-…` | R1 | ✓ | `<TBD>` | MCP (unverified) |
| สร้างใบสำคัญจ่ายจากคำขอ | `ac_pay_req` | `triggerWorkflow` → WF-AC-14 | สร้าง AC_PAY + AC_PAY_LINE | `req_status` equals Approved | R1 | ✓ | `<TBD>` | MCP (unverified) |
| ปิดงวด | `ac_period` | `updateCurrentRecord` (เขียน `biz_close_flag`) → `runWorkflowAfterSubmit` → WF-AC-09 | ตรวจรายการค้างแล้วปิดงวด | `period_status` equals Open `f662571c-…` | R3 | ✓ | **`6a903eb89762533b5b71c4b2`** | ✅ **ปิดครบทุกมิติแล้ว 31 ส.ค. 2569** — workflow logic ผ่านครบ + **Scope แก้เป็น All Records แล้ว** (`isAllView: 1` ยืนยันผ่าน API หลังแก้) ⇒ ผู้ใช้กดปุ่มได้จริงแล้ว |
| ปิดปีและยกยอด | `ac_period` | `updateCurrentRecord` (เขียน `biz_close_year_flag`) → `runWorkflowAfterSubmit` → WF-AC-11 | ตรวจงวดค้าง แล้วปิดปี+ยกยอด | `period_no` equals 13 **AND** `period_status` equals Soft-closed `b2986cb5-…` | R3 | ✓ | **`6a90f50e1378964f9984df83`** | ✅ **ปิดครบทุกมิติแล้ว 31 ส.ค. 2569** — workflow logic ผ่านครบทั้ง 2 เส้นทาง + **Scope แก้เป็น All Records แล้ว** (`isAllView: 1` ยืนยันผ่าน API หลังแก้) ⇒ ผู้ใช้กดปุ่มได้จริงแล้ว |
| เปิดงวดใหม่ | `ac_period` | `updateCurrentRecord` | `period_status` = Open + บังคับกรอก `reopen_reason` | `period_status` equals Soft-closed `b2986cb5-…` | R3 | ✓ + ระบุเหตุผล | `<TBD>` | MCP (unverified) |
| แปลงเป็นใบกำกับภาษี | `ac_bl` `<ยังไม่มีตาราง>` | `triggerWorkflow` → WF-AC-18 | สร้าง AC_INV จากใบแจ้งหนี้ | สถานะ = Recognised | R1 | ✓ | `<TBD>` | MCP (unverified) |
| ยื่นแบบภาษี | `ac_tax_filing` | `updateCurrentRecord` | `filing_status` = Filed `746ab42c-…` + `filing_date` | `filing_status` equals Approved `f8c0a410-…` | R3 | ✓ | `<TBD>` | MCP (unverified) |

> 🔴 **สร้างปุ่มก่อน `create_view`** แล้วอ้าง `actionId` ที่คืนมาใน view config · **MCP ไม่มี update tool** — แต่ **CLI มี**: `hap worksheet create-custom-action --btn-id <id>` แก้ปุ่มหลังสร้างได้ [S] ยังไม่เคยยิง ⇒ ลอง CLI ก่อน ถ้าไม่ผ่านค่อยเข้า Browser · ⚠️ **ยกเว้นการตั้ง Scope → "All Records" ที่ไม่มี API ทั้งสองทาง — Browser เท่านั้น** (กับดักข้อ 20)
> ปุ่มชนิด `triggerWorkflow` จะ auto-gen workflow ที่ **ไม่โผล่ใน `get_workflow_list`** — บันทึก ID จาก URL ลง §1.5

### §1.7 Views / Custom Pages / Charts — ยังไม่มี (ทุกตารางมีแต่ view `全部` ที่ระบบสร้างให้)

| ชนิด | ชื่อ | บน worksheet | ใช้ทำอะไร | ID | Surface |
|---|---|---|---|---|---|
| View (Grid) | ใบสำคัญของฉัน (ร่าง) | `ac_voucher` | filter `status1` = Draft AND ผู้สร้าง = ผู้ใช้ปัจจุบัน | `<TBD>` | MCP (`create_view`, unverified) |
| View (Grid) | รออนุมัติ | `ac_voucher` | filter `status1` = Pending approval | `<TBD>` | MCP (unverified) |
| View (Grid) | เจ้าหนี้คงค้าง | `ac_ap` | filter `ap_status` in (Recognised, Partially paid) · เรียงตาม `due_date` | `<TBD>` | MCP (unverified) 🔴 ต้องมี `ap_status` ก่อน |
| View (Calendar) | กำหนดชำระ | `ac_ap` | ตาม `due_date` | `<TBD>` | MCP (unverified) |
| View (Grid) | ภาษีซื้อรอใบกำกับ | `ac_vat_doc` | filter `claim_status` = Awaiting tax invoice | `<TBD>` | MCP (unverified) 🔴 ต้องมี `claim_status` ก่อน |
| Custom Page | แดชบอร์ดผู้บริหาร | — | งบทดลอง · กระแสเงินสด · อายุหนี้ · ภาษีค้างยื่น | `<TBD>` | Browser |
| Custom Page | แดชบอร์ดภาษี | — | ภาษีซื้อ–ขายรายเดือน · สถานะการยื่น | `<TBD>` | Browser |

### §1.8 System fields (มีทุก worksheet — ห้ามสร้างซ้ำ)

`rowid` `_owner` `_createdBy` `_createdAt` `_updatedAt` `_updatedBy` · workflow: `_processName` `_nodeAssignees` `_initiatedBy` `_initiatedAt` `_nodeStartedAt` `_approvalCompletedAt` `_dueAt` `_remainingTime` `_processStatus` (options `pass` / `refuse` / `abort` / `other`)

---
