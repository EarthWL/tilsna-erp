# Build Spec / FRS สำหรับ Agent — โมดูลบัญชี TILSNA ERP (Nocoly)

> คู่กับ `01-BRD.md` — BRD บอก "ทำอะไร" · ไฟล์นี้บอก "ทำกับ object ไหน ด้วย ID อะไร เสร็จแล้ววัดยังไง"
> **Brownfield** — ID ทุกตัวในเอกสารนี้ **ดึงสดจากเซิร์ฟเวอร์เมื่อ 26 ส.ค. 2569** ผ่าน MCP connector `ERP_-_TILSNA`
> `<TBD-…>` = ยังไม่มี object จริง ต้องเติม ID ทันทีหลังสร้าง
> อัปเดต: 26 ส.ค. 2569 · เพิ่มเติม 27 ส.ค. 2569 (Phase 8: AC_BANK_RECON / AC_BANK_RECON_LINE / AC_CLOSE / AC_CLOSING_ENTRY / AC_OPENING สร้างสำเร็จผ่าน MCP)

---

## §0. กฎปฏิบัติของ Agent (DO / DON'T) — อ่านก่อนทำทุกครั้ง

**DO**

1. เปิด **§1 ID Registry** ก่อนพิมพ์ ID ใด ๆ — ห้ามพิมพ์จากความจำหรือจากเอกสาร SDS ต้นฉบับ (SDS ไม่มี ID)
2. ยืนยันว่ากำลังต่อกับแอปที่ถูกต้องด้วย `get_app_info` ก่อน write แรกของทุก session (`appId` ต้องเป็น `deca7391-1761-424b-9af3-c8d043004ad3`)
3. **Verify ก่อน claim** — ทุกคำว่า "มี/ไม่มี/เสร็จ/ผ่าน" ต้องมีผลจาก MCP หรือหน้าจอรองรับ
4. ทำ workflow ทีละ node สั้น ๆ แล้วบันทึก · `validate_process` ทุกครั้งหลัง `batch_create_process_nodes`
5. seed ข้อมูลด้วย `batch_create_records` + `triggerWorkflow:false` เสมอ กัน workflow ยิงรัวระหว่างนำเข้า
6. เขียน DateTime ผ่าน API แบบระบุโซนเสมอ: `"2026-08-26 09:00:00+07:00"`
7. `update_worksheet` ต้องส่ง `name` + `alias` **คู่กันเสมอ** (ส่งแต่ name จะล้าง alias ทิ้ง)
8. หลัง `create_*` ทุกครั้ง อ่าน ID กลับด้วย `get_worksheet_structure` แล้วเติมแทน `<TBD-…>` ใน §1 **ทันที**
9. Approval: ตารางหลักต้องมีฟิลด์ **Collaborator** เก็บผู้อนุมัติ + node **Update Record เขียนค่าลงก่อน** Initiate Approval · กรอก Data Update tab · ตั้ง empty-approver policy
10. ทดสอบตามชนิด trigger (§5.3) — worksheet trigger ยิงด้วย `create_record`/`update_record` **ไม่ใช่** `trigger_workflow`

**DON'T**

| ห้าม | เพราะ | ทำแทน |
|---|---|---|
| เขียนค่าลง alias `status` ของ AC_VOUCHER | **alias จริงคือ `status1`** | ใช้ `status1` หรือ field id `6a86016b1049edca1eed028a` |
| สร้าง worksheet / field / optionset ซ้ำ | ของมีแล้ว 34 ตาราง + 30 optionset | เช็ก §1.2 และ §1.3 ก่อนทุกครั้ง |
| สรุปจาก `get_workflow_list` ว่างว่า "ไม่มี workflow" | tool คืนเฉพาะ PBP — ยืนยันแล้วเป็นจุดบอด | **`hap workflow list <appId>`** (เห็น draft/disabled/orphan ด้วย) — ⚠️ **แต่ผลไม่คงที่ 50/37/36 จาก 3 ครั้งติด (หลักฐาน agent-hr 28 ส.ค.) ⇒ ใช้เป็นหลักฐาน "ไม่มี" ไม่ได้** · ยืนยันการมีอยู่จริงของตัวใดตัวหนึ่ง = **`hap workflow get <id>` แล้วดูฟิลด์ `deleted`** (`workflow structure` คืนค่าแม้ถูกลบแล้ว ใช้ไม่ได้) · Browser เป็นทางสุดท้าย |
| สรุปว่า "workflow ทำงานแล้ว" จาก operator `user-api` | นั่นคือเขียนมือ | ต้องเห็น `_createdBy`/`_updatedBy` = **`user-workflow`** ผ่าน `get_record_details(includeSystemFields:true)` — ⚠️ **ห้ามใช้ operator ใน `get_record_logs`** ให้ผลลบลวง (คืน `user-api` แม้ workflow เป็นคนเขียนจริง ยืนยัน 28 ส.ค. 2569) |
| ใช้ Trigger Condition อ้างฟิลด์ SingleSelect | field-cache bug → Publish error "1 nodes with abnormal" | ใช้ **Trigger Field** แล้วทำเงื่อนไขใน Branch node แรก |
| แปลง Number → Formula ตรง ๆ | แพลตฟอร์มไม่รองรับ | ลบแล้วสร้างใหม่ (field ID เปลี่ยน — อัปเดต §1) |
| ใช้ Formula field เพิ่ม | dialog ไม่เสถียร สูตรหาย | Number field + node `Function calculation` ให้ workflow เขียน |
| ใช้ค่า before-update ในเงื่อนไข | เข้าถึงไม่ได้ทั้งใน Trigger Condition และ Branch | ใช้ฟิลด์ธง (`posted_flag` เป็นตัวอย่างที่มีอยู่แล้ว) |
| พึ่ง `isUnique` กันซ้ำ | API bypass ได้ | **Unique index** (Index Acceleration) — ดู §2 Form rules |
| แก้ node ของ workflow ที่สร้างแล้ว | `nodeId` ถูกเมิน แก้ไม่ติด | `delete_process_node` แล้วสร้างใหม่ |
| ปิดงาน ✅ ทั้งที่ approval ยัง pending | ยังไม่พิสูจน์ | รอผู้อนุมัติกดใน To-do จริง |
| เดาว่า AC_TAX_FILING / AC_VAT_DOC มีฟิลด์สถานะ | **ยังไม่มี** — optionset สร้างไว้แต่ไม่มีฟิลด์ผูก | ดู §1.3 ตาราง "optionset กำพร้า" |
| ใส่ `filter` ใน trigger ของ `worksheet_event` | 🔴 **ยิงจริง 26 ส.ค.: workflow ไม่ทำงานเลยและไม่มี error** | ใส่ `triggerFields` อย่างเดียว แล้วเอาเงื่อนไขไปไว้ใน **branch node แรก** (branch เทียบ option key ได้ถูกต้อง — พิสูจน์แล้ว) |
| ใช้ `ne 1` กับฟิลด์ธงที่ยังว่าง | 🔴 **ค่าว่างไม่ผ่านเงื่อนไข `ne`** — flow เงียบ | ตั้ง **default = 0** ให้ทุกฟิลด์ธง แล้ว backfill record เดิม (ทำแล้วกับ `submitted_flag`, `posted_flag`) |
| คัดลอกค่าฟิลด์ **OrgRole** ด้วย `update_record` | 🔴 **เขียนค่าว่างเงียบ ๆ** — approval abort ทันที (ยิงจริงทั้งลง Collaborator และลง Role) | อย่าคัดลอก — ให้ `get_single` หากฎ **ภายในสายอนุมัติ** แล้ว `approve.approvers` อ้าง `{kind:"field", node:<get_single>, fieldId:<approver_role_1>}` ตรง ๆ |
| อ้าง `nodeAlias:"approval_start"` ในสายอนุมัติ | 🔴 `找不到节点别名 approval_start` — tenant นี้ start node **ไม่มี alias** | `get_workflow_structure(<inner processId>)` แล้วอ้างด้วย **`nodeId`** ของ start node |
| วาง branch `approval_result` ไว้นอก approval_block | 🔴 `approval_result 只能接在 approve 节点后` | วาง branch + node ผลอนุมัติ **ไว้ในสายอนุมัติ** ต่อจาก approve node |
| สรุปว่า workflow ไม่ทำงานเพราะ log ขึ้น `user-api` | log ของ `get_record_logs` แสดง operator ตามผู้จุดชนวน | ดู **`_updatedBy` จาก `get_record_details(includeSystemFields:true)`** — ต้องเป็น `user-workflow` |

**Special operator ใน log:** `user-workflow` = workflow ยิงเอง (หลักฐานว่า workflow ทำงาน) · `user-api` = เขียนผ่าน MCP/API · `user-self` = ผู้ใช้กดเอง (รวมการกดปุ่ม Custom Action)

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
> ✅ **แก้ 30 ส.ค. 2569 — `create_custom_actions` พิสูจน์แล้ว ไม่ใช่ unverified อีกต่อไป** (ยิงจริงสำเร็จครั้งแรก 27 ส.ค. ที่งาน 2.2 — ปุ่ม "ส่งอนุมัติ" `6a8f380b1378964f99849bfe` + "ยกเลิกใบสำคัญ" `6a8f380bae2a0e3743a0bedb`) · ⚠️ **แต่ปุ่มจะลง Scope = "Unassigned View" เสมอ และไม่โผล่ที่ไหนเลยจนกว่าจะเข้า Browser ตั้ง Scope → "All Records"** (กับดักข้อ 20 — ยืนยันซ้ำแล้วทั้งกับปุ่ม "กลับรายการ" 27 ส.ค.) การตั้ง Scope **ไม่มี API ทั้ง MCP และ CLI ⇒ Browser เท่านั้น**
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

> ต้นฉบับ SDS §4.1 ระบุ inventory 49 ตาราง (ตัวเลข "44" ใน SDS §1.2 นับไม่ตรงกับตาราง — บันทึกไว้ใน `03-RTM-Status.md` §E)
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

**Permission matrix (แปลงจาก BRD §5 / SDS §3.2)**

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
> ⚠️ **WF-AC-02 ใช้ node Loop** ซึ่ง MCP สร้างไม่ได้ → ดูทางเลี่ยงใน §3 WF-AC-02

### §1.6 Custom Actions (ปุ่มบน record) — สร้างแล้ว 5 ปุ่ม (แก้ 30 ส.ค. 2569)

> ⚠️ **หัวข้อเดิมเขียนว่า "ยังไม่มีสักปุ่ม" ซึ่งขัดกับตารางของตัวเอง** — ตอนนี้มีปุ่มจริงบนเซิร์ฟเวอร์แล้วอย่างน้อย 5 ปุ่ม: บน `ac_voucher` 3 ปุ่ม (ส่งอนุมัติ `6a8f380b1378964f99849bfe` · ยกเลิกใบสำคัญ `6a8f380bae2a0e3743a0bedb` · กลับรายการ — งาน 2.2 ครบ 3/3) และบน `ac_period` 2 ปุ่ม (ปิดงวด `6a903eb89762533b5b71c4b2` · ปิดปีและยกยอด `6a90f50e1378964f9984df83`) · แถวที่ยังเป็น `<TBD>` ด้านล่างคือปุ่มที่**ยังไม่ได้สร้าง** ไม่ใช่ว่าไม่มีปุ่มเลย

| ปุ่ม | Worksheet · scope | ชนิด | ทำอะไร | เปิดใช้เมื่อ (`enableWhen`) | Role ที่เห็น | ยืนยัน | ID | Surface |
|---|---|---|---|---|---|---|---|---|
| ส่งอนุมัติ | `ac_voucher` · Record details ทุก view | `updateCurrentRecord` | `status1` = Pending approval `982090bd-…` → WF-AC-01 รับช่วง | `status1` equals Draft `3536165d-…` | R1 | ✓ | `<TBD>` | MCP (unverified) |
| ยกเลิกใบสำคัญ | `ac_voucher` | `updateCurrentRecord` | `status1` = Cancelled `e0474c62-…` | `status1` in (Draft, Pending approval) | R1, R2 | ✓ + ระบุเหตุผล | `<TBD>` | MCP (unverified) |
| กลับรายการ | `ac_voucher` | `triggerWorkflow` → WF-AC-10 | สร้างใบสำคัญกลับรายการ | `status1` equals Posted `a234503a-…` | R3 | ✓ + ระบุเหตุผล | `<TBD>` | MCP (unverified) |
| ส่งตั้งหนี้เพื่ออนุมัติ | `ac_ap` | `updateCurrentRecord` | `ap_status` = Pending approval `35be3f29-…` | `ap_status` equals Draft `e10952c6-…` | R1 | ✓ | `<TBD>` | MCP (unverified) |
| สร้างใบสำคัญจ่ายจากคำขอ | `ac_pay_req` | `triggerWorkflow` → WF-AC-14 | สร้าง AC_PAY + AC_PAY_LINE | `req_status` equals Approved | R1 | ✓ | `<TBD>` | MCP (unverified) |
| ปิดงวด | `ac_period` | `updateCurrentRecord` (เขียน `biz_close_flag`) → `runWorkflowAfterSubmit` → WF-AC-09 | ตรวจรายการค้างแล้วปิดงวด | `period_status` equals Open `f662571c-…` | R3 | ✓ | **`6a903eb89762533b5b71c4b2`** | MCP ✓ (workflow logic ทดสอบผ่านครบผ่าน `update_record` ตรง — **Scope ยังไม่ verify ผ่าน Browser**, คาดว่าเป็น "Unassigned View" ตามแพทเทิร์นกับดักข้อ 20) |
| ปิดปีและยกยอด | `ac_period` | `updateCurrentRecord` (เขียน `biz_close_year_flag`) → `runWorkflowAfterSubmit` → WF-AC-11 | ตรวจงวดค้าง แล้วปิดปี+ยกยอด | `period_no` equals 13 **AND** `period_status` equals Soft-closed `b2986cb5-…` | R3 | ✓ | **`6a90f50e1378964f9984df83`** | MCP ✓ (workflow logic ทดสอบผ่านครบทั้ง 2 เส้นทาง — **Scope ยังไม่ verify ผ่าน Browser**, คาดว่าเป็น "Unassigned View" ตามแพทเทิร์นกับดักข้อ 20 — สร้างปุ่มหลังสร้าง/ทดสอบ workflow เสร็จแล้ว) |
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

## §2. สเปกรายโมดูล (FR-01 … FR-19)

> อ่านคู่กับ §1 เสมอ · ตารางฟิลด์ทุกตารางในส่วนนี้ **คัดลอกตรงจากเซิร์ฟเวอร์** — แถวที่ขึ้นต้นด้วย 🆕 คือฟิลด์ที่ **ยังไม่มี** และต้องสร้าง

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

> 🔑 `approver_role_1/2/3` เป็นชนิด **OrgRole** — เก็บ "บทบาท" ไม่ใช่ "ตัวบุคคล" ⇒ workflow ต้องแปลงบทบาทเป็นผู้อนุมัติจริงก่อนเข้า Approve node (ดู §3 WF-AC-01 ขั้นที่ 4)
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
**Gap:** ยังไม่ได้ตรวจจำนวน record ของทั้ง 6 ตาราง (§1.2 คอลัมน์ record = `—`) · ไวยากรณ์ `AC_POSTING_RULE.condition` ยังไม่ตกลง 🔴

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
> ⚠️ `balance_diff` เป็น Formula field ซึ่ง playbook เตือนว่า dialog ไม่เสถียร — **ของเดิมใช้ได้อยู่ ห้ามแตะ** ถ้าต้องแก้ให้บันทึกลง §1 ทันทีเพราะ field id จะเปลี่ยน

| ฟิลด์ที่สร้างแล้ว 26 ส.ค. 2569 | Field ID | type | เหตุผล |
|---|---|---|---|
| `approver_user` `biz_vch_approver_user` | `6a8ea405ae2a0e3743a084ee` | Collaborator subType 0 | ⚠️ **สร้างไว้แต่ยังไม่ได้ใช้** — ดูกับดัก OrgRole ใน §0 · เก็บไว้เผื่อเปลี่ยนไปเก็บผู้อนุมัติเป็นตัวบุคคล |
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

**Custom Actions ที่ผูก:** ส่งอนุมัติ · ยกเลิกใบสำคัญ · กลับรายการ (ดู §1.6)
**Workflow ที่ผูก:** WF-AC-01 (อนุมัติ) · WF-AC-02 (ผ่านรายการ) · WF-AC-10 (กลับรายการ) — ดู §3

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
- ⚠️ WF-AC-02 ต้องวนสร้าง GL รายบรรทัด แต่ **node Loop สร้างผ่าน MCP ไม่ได้** — ดูทางเลี่ยงใน §3

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
| `ap_status` `biz_ap_status` | `6a8ead08ae2a0e3743a0b1c3` | Dropdown | ✅ **ผูกกับ `OS_AP_STATUS` `9f29af16-…` แล้ว** — key ตาม §1.3 |
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

**สถานะ: ✅ ตารางและฟิลด์พร้อมใช้งาน (0 record) · อยู่ใน section `AC-07 Close and Reconciliation` `6a853b2f0f7255ac5594e0e1` · สร้างด้วยวิธีแก้บั๊ก `create_worksheet` (ดู §1.2c) · ✅ WF-AC-08 สร้าง publish และทดสอบผ่านครบแล้ว 27 ส.ค. 2569 (รอบเย็น)**

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
**หมายเหตุ:** alias `worksheet22`/`worksheet23` เป็นค่า auto-generated จากบั๊ก `create_worksheet` (ไม่ใช่ `ac_bank_recon` ตามธรรมเนียมเดิม) — ดู §1.2c ก่อนอ้างอิงตารางนี้ใน filter/formula ของ workflow ใหม่

---

### FR-15 ปิดงวด ปิดปี และยอดยกมา ✅ **สร้างตารางและฟิลด์ครบแล้ว 27 ส.ค. 2569**

**สถานะ: ✅ ตารางและฟิลด์พร้อมใช้งาน · สร้างด้วยวิธีแก้บั๊ก `create_worksheet` (ดู §1.2c) · ✅ WF-AC-09 (ปิดงวด) และ ✅ WF-AC-11 (ปิดปีและยกยอด) สร้าง publish และทดสอบผ่านครบแล้ว (ดู §3) · ฟิลด์ `biz_close_flag` (WF-AC-09) และ `biz_close_year_flag` (WF-AC-11) บน `AC_PERIOD` สร้างแล้วทั้งคู่**

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
**หมายเหตุ:** alias `worksheet24`/`worksheet25`/`worksheet26` เป็นค่า auto-generated จากบั๊ก `create_worksheet` — ดู §1.2c

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

**กฎกำกับ AI (จาก SDS §9.1):** AI เสนอค่าเท่านั้น **ห้ามผ่านรายการเอง** · ทุกค่าที่ AI เติมต้องมีผู้ใช้ยืนยันและบันทึกว่าใครยืนยัน · ค่าความเชื่อมั่นต้องเก็บไว้ตรวจสอบย้อนหลัง

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
2. ตั้ง permission ตาม matrix ใน §1.4 ให้ครบทั้ง 8 role
3. เพิ่มบัญชีทดสอบอย่างน้อย 1 บัญชีต่อ role — โดยเฉพาะ **AC-R1 (ผู้จัดทำ) และ AC-R2 (ผู้อนุมัติ) ต้องเป็นคนละบัญชี** ไม่อย่างนั้นพิสูจน์ TC-05 (SoD) ไม่ได้
4. ซ่อนฟิลด์อ่อนไหวจาก AC-R6 ตาม NFR-02
5. ตั้ง AC_GL เป็น read-only ทุก role รวม AC-R8

**วิธี verify**

| ต้องตรวจ | เรียก / ทำ | ผลที่คาด |
|---|---|---|
| permission ตรง matrix | `get_role_details(<roleId>)` | worksheetPermissions ตรงตาราง §1.4 |
| SoD ทำงานจริง | **Role Debugging** → สลับเป็น AC-R1 → เปิดใบสำคัญที่ตนสร้าง | ไม่มีปุ่มอนุมัติ |
| AC_GL แก้ไม่ได้ | Role Debugging ทุก role → เปิด AC_GL | ไม่มีปุ่มแก้ไข/ลบ (TC-06) |
| ฟิลด์อ่อนไหวถูกซ่อน | Role Debugging → AC-R6 → เปิด AC_PARTNER | ไม่เห็น `tax_id`, `account_no` |
| ผู้ตรวจสอบภายในอ่านอย่างเดียว | Role Debugging → AC-R5 → เปิดทุกตาราง | เห็นทุกอย่าง ไม่มีปุ่มแก้ (TC-14) |

> ⚠️ multi-role ให้สิทธิ์แบบ **กว้างสุด** — ห้ามใส่บัญชีทดสอบไว้หลาย role พร้อมกันตอนพิสูจน์ SoD

---

## §3. Workflow Catalog — 22 workflow, node-by-node

> **WF-AC-01, WF-AC-02 สร้างและ publish แล้ว** — ที่เหลือทุก ID เป็น `<TBD>` · เติมทันทีหลัง `create_process`
> **ก่อนสร้างตัวใหม่:** เปิดหน้า **Automated Workflow** ยืนยันด้วยตาว่าสถานะตรงกับ §1.5 แล้วบันทึกผลลง §1.5
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
- **Pitfall:** AI เสนอค่าได้เท่านั้น ห้ามผ่านรายการเอง (SDS §9.1) · ต้องบันทึกว่าใครยืนยันและเมื่อไร

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

## §4. Non-functional (NFR) — ทำอย่างไรบน Nocoly

| รหัส | สถานะ | ทำอย่างไรบน Nocoly / Gap | วิธี verify |
|---|---|---|---|
| NFR-01 ความปลอดภัย/สิทธิ์ | ⚠️ | role ครบ 8 ตัวมี ID แล้ว · permission ยังไม่ยืนยัน · ไม่มีสมาชิก | `get_role_details` + Role Debugging |
| NFR-02 PDPA | ⬜ | ซ่อนฟิลด์ `tax_id`, `AC_PARTNER_BANK.account_no` ที่ระดับ role (ตั้งใน UI) | Role Debugging เป็น AC-R6 |
| NFR-03 audit trail | ✅ | `get_record_logs` ให้เวลาและค่าก่อน–หลังครบ · ⚠️ **ฟิลด์ operator สะท้อนผู้จุดชนวน ไม่ใช่ตัวการที่เขียนจริง** — ถ้าต้องพิสูจน์ว่า workflow เป็นคนเขียน ใช้ `_updatedBy` จาก `get_record_details(includeSystemFields:true)` แทน · **Application Logs** ใน org console ให้ "ใครดู/พิมพ์/ดาวน์โหลด" — ไม่ต้องสร้างตาราง log เอง | `get_record_logs(ac_voucher, <rowid>)` (TC-15) — ดูค่าก่อน-หลัง ไม่ใช่ operator |
| NFR-04 ความถูกต้องของตัวเลข | 🔶 | ฟิลด์จำนวนเงินเป็น Number precision 2 · `total_debit`/`total_credit` เป็น Rollup ✅ · **แต่ยอดบน AC_AP/AC_PAY ยังไม่มีฟิลด์** 🔴 | `get_worksheet_structure` ตรวจ precision |
| NFR-05 ความต่อเนื่องของลำดับ | ⚠️ | `AC_GL.movement_seq` เป็น AutoNumber ✅ · การตรวจเลขขาดหายอยู่ใน WF-AC-12 ข้อ 5 ⬜ | เทียบ max(`movement_seq`) กับจำนวนแถว |
| NFR-06 SLA | ⬜ | WF-AC-12 แจ้งเตือนเมื่อค้างเกิน 1 วันทำการ | Workflow History |
| NFR-07 เวลา/เขตเวลา | 🔶 | เขียน DateTime ผ่าน API ต้องระบุ `+07:00` เสมอ (เซิร์ฟเวอร์ตีความเป็น UTC+8 ถ้าไม่ระบุ → เร็วไป 1 ชม.) · เวลาที่เป็นหลักฐานให้ workflow เขียนด้วย System › Current time เท่านั้น | เขียนแล้วอ่านกลับ เทียบกับเวลาจริง |
| NFR-08 การเก็บรักษา | 🔶 | ไฟล์แนบเก็บบนแพลตฟอร์ม (`attachments` มีบน AC_VOUCHER, AC_PARTNER, AC_DOC_SETTING) · **ต้องมีนโยบายห้ามลบ record 5 ปี** — ตั้งด้วย permission delete = 0 | ตรวจ role ที่มีสิทธิ์ delete |
| NFR-09 สองภาษา | 🔶 | `account_name_th/_en`, `cc_name_th/_en`, `name_th/_en` ✅ มีครบ · งบการเงินสองภาษายังไม่ได้ทำ ⬜ | เปิดรายงาน |
| NFR-10 ทุก logic บน Nocoly | ✅ | ไม่มีสคริปต์ภายนอกในแผนนี้ — ทุกกฎเป็น Business Rule / workflow / rollup / index | ทบทวน spec |
| NFR-11 ตั้งค่าได้เอง | ✅ | อัตราภาษี กฎอนุมัติ กฎออกเลขที่ กฎผ่านรายการ อยู่ในตารางข้อมูลทั้งหมด | AC-R4 แก้ค่าแล้ว workflow เปลี่ยนพฤติกรรมตาม |
| NFR-12 SoD | 🔶 | AC-R8 ต้องไม่มีสิทธิ์อนุมัติ · WF-AC-01 node 8 เปลี่ยนผู้อนุมัติเมื่อเป็นผู้จัดทำเอง | TC-05 + Role Debugging |
| NFR-13 สำรอง/กู้คืน | ⬜ | ใช้ **Backup & Restore** ก่อนแก้โครงสร้างทุกครั้ง · **App Lock** หลังขึ้นระบบจริง | ตรวจในหน้า org console |

---

## §5. Verification Cookbook

### §5.1 ตรวจโครงสร้างและข้อมูล

| ต้องตรวจ | เรียก | ผลที่คาด |
|---|---|---|
| ต่อกับแอปถูกตัว | `get_app_info` | `appId` = `deca7391-1761-424b-9af3-c8d043004ad3` |
| โครงสร้างแอป | `get_app_info` | worksheet + section + ID |
| field / option จริง | `get_worksheet_structure(<ws>, responseFormat="md")` | ตารางฟิลด์ (⚠️ ไม่คืน display name และ alias ระดับ worksheet) |
| นับ record | `get_record_list(<ws>, pageSize:1, includeTotalCount:true)` | `data.total` |
| นับแบบมีมิติ | `get_record_pivot_data(<ws>, viewId, rows, includeSummary)` | ⚠️ **ต้องมี viewId หรือ rows** ไม่งั้น error |
| optionset ที่มีอยู่ | `get_optionset_list` | 30 ชุด — `worksheetIds` ว่าง = ยังไม่มีฟิลด์ผูก |
| role | `get_role_list` | ✅ tenant นี้คืน custom role ครบ 8 ตัว |
| รายละเอียดสิทธิ์ | `get_role_details(<roleId>)` | worksheetPermissions |

### §5.2 ตรวจว่า workflow ทำงานจริง

| ต้องตรวจ | เรียก | ผลที่คาด |
|---|---|---|
| workflow ยิงจริง | `get_record_details(<ws>, <rowId>, includeSystemFields:true)` | `_updatedBy` = **`user-workflow`** — ⚠️ **ห้ามใช้ operator จาก `get_record_logs`** ให้ผลลบลวง (คืน `user-api` แม้ workflow เขียนจริง) |
| การกดปุ่มทำงาน | `get_record_details(includeSystemFields:true)` เทียบ 2 จังหวะ (ก่อน/หลัง publish node ถัดไป) | `_updatedBy` เปลี่ยนจาก `user-self` (ตอนกดปุ่ม) เป็น `user-workflow` (ตอน node ถัดไปเขียน) — ⚠️ ห้ามอ่านลำดับนี้จาก `get_record_logs` operator เพราะสะท้อนผู้จุดชนวนไม่ใช่ตัวการจริง |
| approval ถูกส่ง | `get_approval_list_by_row(<ws>, <rowId>)` | มี instance + ผู้รับผิดชอบ |
| ผลการอนุมัติ | `get_approval_detail(<processId>)` | สถานะเปลี่ยน + Data Update เขียนค่าแล้ว |
| มี workflow อยู่จริงไหม | **`hap workflow get <id>` → ดูฟิลด์ `deleted`** (ตัวเดียวที่เชื่อได้) · สำรวจทั้งแอปใช้ `hap workflow list <appId>` · Browser เป็นทางสุดท้าย | ❌ **ห้ามใช้ `get_workflow_list`** — คืนเฉพาะ PBP · ⚠️ **และห้ามใช้ `workflow list` หรือ `workflow structure` เป็นหลักฐานว่า "ไม่มี"** — list ให้ผลไม่คงที่, structure คืนค่าแม้ลบแล้ว (หลักฐาน agent-hr 28 ส.ค.) |

### §5.3 วิธียิงตามชนิด trigger (ห้ามสลับ)

| ชนิด | วิธียิง | หลักฐานผ่าน |
|---|---|---|
| `worksheet_event` | `create_record` / `update_record` พร้อม `triggerWorkflow:true` | log `user-workflow` |
| `schedule` | รอรอบ หรือกด **"Execute now"** ใน Browser | Workflow History + log |
| `webhook` | ยิง HTTP จริงไปที่ URL ของ workflow | log `user-workflow` (⚠️ `create_record` ผ่าน MCP **ไม่** กระตุ้น webhook trigger) |
| Custom Action | กดปุ่มบนหน้าจอด้วยบัญชีของ role นั้น | log `user-self` + `user-workflow` |
| Approve step | ผู้อนุมัติกดใน **To-do** (คนจริง) | `get_approval_detail` เปลี่ยนสถานะ |
| Business Rule / form rule | **Role Debugging** → สลับ role → เปิดฟอร์ม | ฟิลด์ถูกซ่อน/ล็อก หรือ save ถูกบล็อก (**ไม่ใช่** ตรวจด้วย `get_record_logs`) |

### §5.4 กรณีทดสอบ 28 ข้อ ↔ ที่มา

| TC | เรื่อง | บังคับด้วย | ตรวจที่ |
|---|---|---|---|
| TC-01 | เดบิต ≠ เครดิต ส่งอนุมัติไม่ได้ | BR-06.1 + WF-AC-01 node 3 | FR-06 |
| TC-02 | บันทึกในงวดที่ปิดไม่ได้ | WF-AC-01 node 4 + BR-02.1 | FR-02 |
| TC-03 | บัญชีระดับสรุปไม่อยู่ใน picker | BR-03.1 + relation filter | FR-03 |
| TC-04 | เกิน 1 ล้าน อนุมัติ 3 ระดับ | WF-AC-01 node 6–14 | FR-06 |
| TC-05 | ผู้จัดทำอนุมัติเองไม่ได้ | WF-AC-01 node 8 | FR-06 / NFR-12 |
| TC-06 | แก้ AC_GL ไม่ได้ | BR-06.6 + role permission | FR-06 / FR-19 |
| TC-07 | กลับรายการที่มี VAT + WHT | WF-AC-10 node 6 | FR-06 |
| TC-08 | รับรู้หนี้สินจากการตรวจรับ | WF-AC-03 | FR-07 |
| TC-09 | ใบแจ้งหนี้ซ้ำ | IX-07.1 + WF-AC-13 | FR-07 / FR-18 |
| TC-10 | ค่าเสื่อมรายเดือน | WF-AC-07 | FR-13 |
| TC-11 | ปิดงวดขณะมีใบค้าง | WF-AC-09 node `checkPending`→`clearFlag1`→`notifyPending` (nodes 7-9) — ✅ ทดสอบผ่าน 27 ส.ค. 2569 | FR-15 |
| TC-12 | งบทดลอง / งบแสดงฐานะการเงิน | RPT-AC-01 / 04 | FR-16 |
| TC-13 | ใบรับรองหัก ณ ที่จ่าย | WF-AC-06 + print template | FR-09 |
| TC-14 | ผู้ตรวจสอบภายในอ่านอย่างเดียว | role AC-R5 | FR-19 |
| TC-15 | ประวัติการแก้ไข (เวลา + ค่าก่อน-หลัง) | `get_record_logs` — ดูเวลา/ค่าก่อน-หลัง เท่านั้น ไม่ใช่ operator | NFR-03 |
| TC-16 | หลายอัตรา VAT ในเอกสารเดียว | `AC_VAT_RATE.is_taxable_base` + WF-AC-03 | FR-05 / FR-07 |
| TC-17 | ราคารวมภาษี = ราคาแยกภาษี | `AC_AP.price_basis` 🆕 + WF-AC-03 | FR-07 |
| TC-18 | ผู้จ่ายออกภาษีแทน (gross-up) | `wht_borne_by` 🆕 + WF-AC-06 | FR-07 / FR-09 |
| TC-19 | ภาษีซื้อรอเรียกคืน | WF-AC-15 node 8 | FR-10 |
| TC-20 | ใช้เครดิตซ้ำไม่ได้ | IX-10.1 + WF-AC-15 node 3 | FR-10 |
| TC-21 | tax point ตกในงวดที่ยื่นแล้ว | WF-AC-15 node 7 | FR-10 |
| TC-22 | ยื่นปกติ + ยื่นเพิ่มเติม | WF-AC-16 node 3 + IX-11.1 | FR-11 |
| TC-23 | จ่าย 3 คู่ค้า 7 เอกสาร | WF-AC-14 + AC_PAY_LINE | FR-08 |
| TC-24 | จ่ายเกินยอดคงเหลือ | BR-08.1 | FR-08 |
| TC-25 | แปลงใบแจ้งหนี้บางส่วน | BR-12.1 + WF-AC-18 | FR-12 |
| TC-26 | ใบลดหนี้กับใบกำกับที่ยื่นแล้ว | WF-AC-19 | FR-12 |
| TC-27 | สแกนแล้วความเชื่อมั่นต่ำ | AI-03 Business Rule | FR-18 |
| TC-28 | ตัดจำหน่ายสินทรัพย์ | WF-AC-21 | FR-13 |

### §5.5 Record ทดสอบที่มีอยู่แล้ว

| Worksheet | rowId | หมายเหตุ |
|---|---|---|
| `ac_voucher` | `74750822-0ff2-4eaa-b273-e0a38066716d` | สร้าง 24 ส.ค. 2569 ผ่าน API · มี 2 บรรทัด ("จ่ายเงินสด", "ค่าธรรมเนียมวิชาชีพ - ผู้สอบบัญชี") · log มีแต่ `user-api` |
| `ac_coa` | 79 record | ⚠️ ยังไม่ยืนยันว่าเป็นผังจริงหรือชุดตัวอย่าง |
| `ac_partner` | 30 record | ⚠️ ยังไม่ยืนยันว่าเป็นข้อมูลจริงหรือชุดทดสอบ |
| `ac_period` | 13 record | น่าจะครบ 12 งวด + งวด 13 — **ต้องยืนยันปีบัญชี (A-01)** |
| `ac_vat_rate` | 5 record | |
| `ac_ap` | 0 record | ว่างจริง |
| `ac_bank_recon` / `ac_bank_recon_line` / `ac_close` / `ac_closing_entry` / `ac_opening` | 0 record ทั้งหมด | สร้างตาราง 27 ส.ค. 2569 — ยังไม่มี record ทดสอบ |

> **กติกาข้อมูลทดสอบ:** ก่อน demo หรือส่งมอบ ต้องล้าง record ทดสอบทั้งหมดและบันทึกไว้ว่าเหลืออะไรไว้ด้วยเหตุผลอะไร

---

## §6. Data Model — ผังความสัมพันธ์

```
                          ┌──────────────┐
                          │  AC_PERIOD   │◄─────────────┬──────────────┐
                          └──────┬───────┘              │              │
                                 │                      │              │
  AC_JOURNAL ◄── AC_DOC_TYPE ──► AC_DOC_NUMBER_RULE     │              │
                     │  ▲                               │              │
                     │  └── AC_APPROVAL_RULE            │              │
                     ▼                                  │              │
              ┌─────────────┐   period                  │              │
              │ AC_VOUCHER  │──────────────────────────►┘              │
              └──────┬──────┘                                          │
                     │ 1:N  (AC_VOUCHER_LINE)      reversal_of (self)  │
                     ▼                                                 │
            ┌──────────────────┐   account   ┌──────────┐              │
            │ AC_VOUCHER_LINE  │────────────►│  AC_COA  │◄── parent (self)
            └──────────────────┘             └────┬─────┘              │
                     │ (ผ่านรายการโดย WF-AC-02)   │                    │
                     ▼                            │                    │
              ┌─────────────┐  account            │                    │
              │   AC_GL     │─────────────────────┘                    │
              └─────────────┘  period ────────────────────────────────►┘
                     ▲
        voucher      │
  ┌──────────────────┴───────────────┬─────────────────┐
  │                                  │                 │
┌────────┐  1:N   ┌─────────────┐  ┌──────┐  1:N  ┌──────────────┐
│ AC_AP  │───────►│ AC_AP_LINE  │  │AC_PAY│──────►│ AC_PAY_LINE  │
└───┬────┘        └──────┬──────┘  └──┬───┘       └──────┬───────┘
    │ partner            │ item       │ pay_req          │ ap
    ▼                    ▼            ▼                  ▼
┌────────────┐    ┌──────────┐  ┌────────────┐    (กลับไป AC_AP)
│ AC_PARTNER │    │ AC_ITEM  │  │ AC_PAY_REQ │──► documents (N:N → AC_AP)
└─────┬──────┘    └────┬─────┘  └────────────┘
      │ 1:N            │ vat_rate / wht_type        ┌───────────────┐
      ▼                ▼                            │ AC_PAY_SETTLE │
┌──────────────────┐  ┌──────────────┐              └───────┬───────┘
│ AC_PARTNER_BANK  │  │ AC_VAT_RATE  │                      │ payment_channel
└──────────────────┘  └──────────────┘                      ▼
                      ┌────────────────────┐        ┌────────────────────┐
                      │ AC_WHT_INCOME_TYPE │◄───────│ AC_PAYMENT_CHANNEL │
                      └─────────┬──────────┘        └────────────────────┘
                                │ 1:N
                                ▼
                        ┌──────────────┐        ┌──────────────┐
                        │ AC_WHT_RATE  │        │    AC_WHT    │──┐
                        └──────────────┘        └──────────────┘  │ filing
                                                                  ▼
                        ┌──────────────┐  filing  ┌────────────────┐
                        │  AC_VAT_DOC  │─────────►│ AC_TAX_FILING  │──► original_filing (self)
                        └──────┬───────┘          └────────────────┘
                               │ claim_period → AC_PERIOD
                               │ partner → AC_PARTNER · vat_rate → AC_VAT_RATE

  มิติที่ใช้ร่วมทุกตารางธุรกรรม:  AC_COST_CENTER (self-hierarchy) · AC_FUND · AC_PROJECT_DIM
  สกุลเงิน:                      AC_CURRENCY ◄── AC_FX_RATE · AC_BANK · AC_VOUCHER · AC_AP · AC_PAY

  ✅ สร้างแล้ว 27 ส.ค. 2569:  AC_BANK_RECON ─► AC_BANK_RECON_LINE (→ AC_GL)
               AC_CLOSE (→ AC_PERIOD) · AC_CLOSING_ENTRY (→ AC_COA, AC_VOUCHER) · AC_OPENING (→ AC_COA, AC_VOUCHER)
               (ยังไม่มี record ทดสอบ · ยังไม่มี workflow ผูก — ดู FR-14/FR-15, §1.5)

  ⬜ ยังไม่มี:  AC_AR ─► AC_AR_LINE · AC_BL ─► AC_INV ─► AC_RE · AC_CN / AC_DN
               AC_ASSET_BOOK ─► AC_DEPR_SCHEDULE ─► AC_DEPR · AC_ASSET_DISPOSAL
               AC_GFMIS_MAP
```

---

*แก้ object เมื่อไร อัปเดต §1 และ §3 ทันที มิฉะนั้น registry จะกลายเป็นแหล่ง hallucinate เสียเอง*
