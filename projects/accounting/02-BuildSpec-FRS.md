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

## §1. ID Registry (Master) → ย้ายไป `13-ID-Registry-AC.md`

🔴 **ย้ายออกจากไฟล์นี้เมื่อ 31 ส.ค. 2569 — เนื้อหาครบทุกตัวอักษรอยู่ที่ [`13-ID-Registry-AC.md`](13-ID-Registry-AC.md)**

เหตุผล: ไฟล์นี้เคยโต **316,054 bytes ≈ 42,366 tokens เกินเพดาน Read 25,000 tokens ไป 1.7 เท่า** — agent เปิดไม่จบใน 1 call ทั้งที่ §0 สั่งให้เปิดทุกครั้งก่อนแตะ object

⚠️ **การอ้างอิงข้ามไฟล์:** ที่อื่นในชุดเอกสารที่เคยเขียนสั้น ๆ ว่า "§1" ต้องเขียนเป็น `` `13-ID-Registry-AC.md` §1 `` จากนี้ไป (กฎใน `MIGRATION.md` — ตรวจด้วย `tools/refcheck.sh`)

## §2. สเปกรายโมดูล (FR-01 … FR-19) → ย้ายไป `14-FRS-Modules-AC.md`

🔴 **ย้ายออกจากไฟล์นี้เมื่อ 31 ส.ค. 2569 — เนื้อหาครบทุกตัวอักษรอยู่ที่ [`14-FRS-Modules-AC.md`](14-FRS-Modules-AC.md)**

เหตุผล: ไฟล์นี้เคยโต **316,054 bytes ≈ 42,366 tokens เกินเพดาน Read 25,000 tokens ไป 1.7 เท่า** — agent เปิดไม่จบใน 1 call ทั้งที่ §0 สั่งให้เปิดทุกครั้งก่อนแตะ object

⚠️ **การอ้างอิงข้ามไฟล์:** ที่อื่นในชุดเอกสารที่เคยเขียนสั้น ๆ ว่า "§2" ต้องเขียนเป็น `` `14-FRS-Modules-AC.md` §2 `` จากนี้ไป (กฎใน `MIGRATION.md` — ตรวจด้วย `tools/refcheck.sh`)

## §3. Workflow Catalog — 22 workflow, node-by-node → ย้ายไป `15-Workflow-Catalog-AC.md`

🔴 **ย้ายออกจากไฟล์นี้เมื่อ 31 ส.ค. 2569 — เนื้อหาครบทุกตัวอักษรอยู่ที่ [`15-Workflow-Catalog-AC.md`](15-Workflow-Catalog-AC.md)**

เหตุผล: ไฟล์นี้เคยโต **316,054 bytes ≈ 42,366 tokens เกินเพดาน Read 25,000 tokens ไป 1.7 เท่า** — agent เปิดไม่จบใน 1 call ทั้งที่ §0 สั่งให้เปิดทุกครั้งก่อนแตะ object

⚠️ **การอ้างอิงข้ามไฟล์:** ที่อื่นในชุดเอกสารที่เคยเขียนสั้น ๆ ว่า "§3" ต้องเขียนเป็น `` `15-Workflow-Catalog-AC.md` §3 `` จากนี้ไป (กฎใน `MIGRATION.md` — ตรวจด้วย `tools/refcheck.sh`)

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
