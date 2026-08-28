# รายงานการแปลค่าตัวเลือก (Option Value) เป็นภาษาไทยทั้งระบบ — โมดูลบัญชี TILSNA ERP

> วันที่ทำงาน: 26 ส.ค. 2569 · ทำต่อจากงาน 1.16 (ชั้นการแสดงผล — ชื่อตาราง/view เป็นไทย)
> ขอบเขต: งาน **1.17 แปลค่าตัวเลือก (option value) เป็นภาษาไทยทั้งระบบ** ใน `05-Roadmap-Tracker.md`
> อ้างอิงกฎเหล็ก: **option key (GUID) ต้องไม่เปลี่ยนสักตัว** เพราะ workflow / filter / record ทุกจุดอ้างด้วย key ไม่ใช่ label — และ **record ต้องไม่มีข้อมูลหาย**

---

## 1. สรุปผล

| รายการ | จำนวน | สถานะ |
|---|---|---|
| Shared optionset (ผูกหลายตาราง/ตารางเดียวผ่าน `dataSource`) | 35 ชุด (123 options) | ✅ แปลครบ 100% |
| ฟิลด์ inline option (SingleSelect/MultipleSelect ไม่ผูก optionset) ที่ผูก Lookup ภายนอก | 1 ฟิลด์ (สถานะงวดบัญชี) | ✅ แก้ผ่านหน้าจอ — field ID + option key เดิมทั้งหมด |
| ฟิลด์ inline option ที่ลบ–สร้างใหม่ได้ปลอดภัย (0 หรือมี record) | 8 ฟิลด์ | ✅ แปลครบ — สำรอง/คืนค่า record ทุกแถวสำเร็จ 100% |
| ฟิลด์รหัสระบบ/โมดูล (ไม่ใช่ศัพท์บัญชี) | 4 ฟิลด์ | ⬜ จงใจไม่แตะ (ดู §4) |
| **รวม record ที่ต้องสำรอง–คืนค่า** | **71 แถว** (13+30+5+12+2+4+5=71) | ✅ ตรวจกลับทุกแถว ตรงกับค่าเดิม 100% ไม่มีข้อมูลหาย |
| option key ที่เปลี่ยน | **0** | ✅ |

---

## 2. Shared optionset — แปลครบ 35 ชุด (123 options)

แปลผ่าน `update_optionset` โดยส่ง options array เต็มทุกครั้ง (คง key/index/color เดิม เปลี่ยนเฉพาะ `value`):

OS_DOC_STATUS · OS_AP_STATUS · OS_AR_STATUS · OS_PERIOD_STATUS · OS_TAX_PERIOD_STATUS · OS_ACCOUNT_TYPE · OS_ACCOUNT_GROUP · OS_NORMAL_BALANCE · OS_SOURCE_MODULE · OS_PRICE_BASIS · OS_VAT_SIDE · OS_VAT_DOC_STATUS · OS_WHT_BORNE_BY · OS_WHT_TIMING · OS_FORM_TYPE (P.P.30→ภ.พ.30 ฯลฯ ตามที่กรมสรรพากรใช้จริง) · OS_FILING_TYPE · OS_FILING_STATUS · OS_ASSET_STATUS · OS_DEPR_METHOD · OS_LEGAL_FORM · OS_BRANCH_TYPE · OS_PARTNER_TYPE · OS_ITEM_TYPE · OS_FX_RATE_TYPE · OS_DATE_PATTERN · OS_RESET_CYCLE · OS_COMPUTE_POSITION · OS_COMPLETION_MODE · OS_PAYMENT_METHOD · OS_DISPOSAL_METHOD · OS_PAYREQ_STATUS · OS_PAY_STATUS · OS_SETTLE_STATUS · OS_WHT_STATUS · "สถานะ" (ผูกกับ `voucher_status` บนใบสำคัญ)

**ยืนยันผลด้วย `get_optionset_list` แบบเต็มชุดหลังแก้เสร็จทั้งหมด** — ทุกชุดเป็นไทย 100%, ไม่มีชุดใดตกหล่น.

---

## 3. ฟิลด์ inline option (ไม่ผูก optionset ส่วนกลาง)

### 3.1 กับดักที่พบใหม่: `editFields` บนฟิลด์ SingleSelect/MultipleSelect ไม่ได้ "แก้" ตัวเลือก แต่ "เพิ่ม" ซ้อนทับ

ทดสอบกับฟิลด์ `ระบบต้นทาง` (0 record ตอนทดสอบ) โดยส่ง `editFields[].options` พร้อม `key` เดิม — ผลคือ **ตัวเลือกไทยถูกเพิ่มเข้าไปใหม่ 8 ตัว ซ้อนทับของเดิม 8 ตัว รวมเป็น 16 ตัว** และ `key` ที่ส่งไปถูกเพิกเฉยเงียบ ๆ (ระบบสร้าง key ใหม่ให้เอง) สาเหตุ: schema ของ `editFields.options` รองรับแค่ `{value, index, color}` ไม่มีช่อง `key`/`isDelete` จริง ๆ

**วิธีแก้ที่ใช้ได้จริง:** ลบฟิลด์เดิมแล้วสร้างใหม่ในคำสั่ง `update_worksheet` เดียวกัน (`removeFields` + `addFields`) — ปลอดภัยเมื่อไม่มี field อื่นอ้างอิงฟิลด์นี้ผ่าน Lookup/`sourceField` (ตรวจก่อนทุกครั้งจาก ID registry)

### 3.2 ฟิลด์ที่ลบ–สร้างใหม่ + คืนค่า record (8 ฟิลด์)

| ตาราง | ฟิลด์ (alias) | field ID เดิม | **field ID ใหม่** | record ที่คืนค่า | ผล |
|---|---|---|---|---|---|
| ใบสำคัญ (AC_VOUCHER) | `source_module` (ระบบต้นทาง) | `6a86021833560633b8cd9fb1` | `6a8ee2729762533b5b718321` | 0 | ✅ ไม่ต้องคืนค่า |
| งวดบัญชี (AC_PERIOD) | `tax_period_status` (สถานะงวดภาษี) | `6a851f70055f2288c5b73ee0` | `6a8ee2c68b6633ef76f1288e` | 13 | ✅ ทุกแถว = "เปิด" |
| คู่ค้า (AC_PARTNER) | `partner_type` (ประเภทคู่ค้า) | `6a85e4269b6999a714d2a3f0` | `6a8ee32a1378964f99849859` | 30 (รวม 3 ฟิลด์) | ✅ ตรง 100% |
| คู่ค้า (AC_PARTNER) | `branch_type` (สำนักงานใหญ่/สาขา) | `6a85e486055f2288c5b77673` | `6a8ee32a1378964f9984985a` | ↑ | ✅ |
| คู่ค้า (AC_PARTNER) | `partner_residence` (ถิ่นที่อยู่) | `6a8545701049edca1eecd86d` | `6a8ee32a1378964f9984985b` | ↑ | ✅ |
| สมุดรายวัน (AC_JOURNAL) | `journal_type` (ประเภทสมุดรายวัน) | `6a8434da33560633b8cd2f09` | `6a8ee5389762533b5b718449` | 5 | ✅ ตรง 100% |
| กฎการออกเลขที่เอกสาร (AC_NUMBERING_RULE) | `year_era` (ปีที่ใช้ พ.ศ./ค.ศ.) | `6a8434ea1049edca1eec9f6d` | `6a8ee53b1378964f99849987` | 12 | ✅ ทุกแถว = "พ.ศ." |
| การตั้งค่าเอกสาร (AC_DOC_SETTING) | `side` (ฝั่งเอกสาร ซื้อ/ขาย) | `6a8434f69b6999a714d22e81` | `6a8ee53eae2a0e3743a0bc6c` | 2 | ✅ ตรง 100% |
| แหล่งเงิน (AC_FUND_SOURCE) | `fund_type` (ประเภทแหล่งเงิน) | `6a8545309b6999a714d2672e` | `6a8ee5439762533b5b71844f` | 4 | ✅ ตรง 100% |
| อัตราภาษีมูลค่าเพิ่ม (AC_VAT_RATE) | `vat_treatment` (ประเภทการเสียภาษีมูลค่าเพิ่ม) | `6a8545468b36df988c17244d` | `6a8ee548ae2a0e3743a0bc72` | 5 | ✅ ตรง 100% |

> 🔴 **field ID ทั้ง 8 ตัวข้างต้นเปลี่ยนแล้ว** — ห้ามใช้ ID เดิมในเอกสาร/workflow ใด ๆ ต่อจากนี้ ดู §5 สำหรับตารางรวม

**ขั้นตอนที่ใช้กับทุกฟิลด์ (ป้องกันข้อมูลหาย):**
1. `get_worksheet_structure` ยืนยันฟิลด์และ options ปัจจุบัน
2. ตรวจ ID registry (`grep sourceField`) ว่าไม่มีฟิลด์อื่นอ้างอิงผ่าน Lookup
3. `get_record_list` ดึงค่าเดิมทุกแถว (เก็บคู่ `rowId` + ค่าเดิม)
4. `update_worksheet` ลบฟิลด์เดิม + สร้างใหม่ (Thai-only options) ในคำสั่งเดียว
5. `get_worksheet_structure` อ่าน field ID ใหม่
6. `batch_update_records` (แยกกลุ่มตามค่าที่ไม่ซ้ำ, `triggerWorkflow:false`) คืนค่าทุกแถว
7. `get_record_list` อ่านกลับยืนยันค่าตรงกับสำรองเดิม 100%

### 3.3 กรณีพิเศษ: ฟิลด์ที่มี Lookup ภายนอกผูกอยู่ (ห้ามลบ–สร้างใหม่)

**`AC_PERIOD.period_status`** (สถานะงวดบัญชี, field id `6a851f70055f2288c5b73edf`) มีฟิลด์ Lookup `(ระบบ) สถานะงวดบัญชี` บน AC_VOUCHER (id `6a8b2f728b36df988c17f00f`) ผูกอยู่ผ่าน `sourceField` — ถ้าลบ–สร้างใหม่ Lookup จะขาดทันทีและ WF-AC-01 (ตรวจงวดปิด) จะพัง

**วิธีแก้:** แก้ผ่านหน้าจอ (แก้ไขฟอร์ม → คลิกฟิลด์ → double-click ข้อความตัวเลือกแต่ละอันแล้วพิมพ์ทับ → บันทึก) ซึ่งไม่ลบ/สร้าง option ใหม่ จึงคง **field ID และ option key เดิมทั้ง 3 ตัว** ได้ครบ

| ตัวเลือกเดิม | แปลเป็น | option key (ไม่เปลี่ยน) |
|---|---|---|
| Open | เปิด | `f662571c-3de0-4e4c-9828-9172e337d223` |
| Soft-closed | ปิดชั่วคราว | `b2986cb5-59db-4fdc-87ed-d57a38201c6a` |
| Permanently locked | ปิดถาวร | `38392e32-7c09-4339-a9b4-81a9f53eba0a` |

ยืนยันด้วย API ว่า field ID และทั้ง 3 key ไม่เปลี่ยน, record เดิมแสดงค่าไทยทันทีโดยไม่ต้องคืนค่าใด ๆ (เพราะ record อ้างด้วย key อยู่แล้ว), และ Lookup บนใบสำคัญดึงค่าไทยมาแสดงถูกต้องอัตโนมัติ

---

## 4. ฟิลด์ที่จงใจไม่แตะ — รหัสระบบ/โมดูล ไม่ใช่ศัพท์บัญชี

| ตาราง | ฟิลด์ | ค่าปัจจุบัน | เหตุผลที่ไม่แปล |
|---|---|---|---|
| ใบสำคัญ (AC_VOUCHER) | `source_doc_type` | `AC_AP` / `AC_AR` / `AC_PAY` / `AC_DEPR` / `AC_CLOSE` / `Manual` | ส่วนใหญ่เป็นรหัสตาราง/โมดูลภายใน — แปลแค่ `Manual` จะทำให้ชุดนี้ไม่สอดคล้องกัน |
| ทะเบียนภาษีซื้อ–ขาย (AC_VAT_DOC) | `source_doc_type` | `AC_AP` / `AC_INV` / `AC_CN` / `AC_DN` | รหัสตารางล้วน |
| หนังสือรับรองหักภาษี (AC_WHT) | `source_type` | `AP` / `PAY` | รหัสย่อโมดูลภายใน |
| กฎการบันทึกบัญชี (AC_POSTING_RULE) | `event_code` | `AP_RECOGNITION`, `AR_COLLECTION`, `DEPRECIATION` ฯลฯ | รหัส event ที่ workflow อ้างอิงตรง ๆ ไม่ใช่คำที่ผู้ใช้เห็นบ่อย |

หากต้องการแปลกลุ่มนี้ในอนาคต แนะนำให้ทำเป็นงานแยก และพิจารณาว่าจะคง suffix รหัสไว้คู่กับคำไทยหรือไม่ (เช่น "ตั้งหนี้ (AC_AP)") เพื่อไม่ให้เสียการอ้างอิงกับเอกสารเก่า

---

## 5. ตาราง field ID ใหม่ทั้งหมดจากงานนี้ (เพิ่มเข้า ID Registry)

| ตาราง | field alias | field ID ใหม่ |
|---|---|---|
| AC_VOUCHER | `source_module` | `6a8ee2729762533b5b718321` |
| AC_PERIOD | `tax_period_status` | `6a8ee2c68b6633ef76f1288e` |
| AC_PARTNER | `partner_type` | `6a8ee32a1378964f99849859` |
| AC_PARTNER | `branch_type` | `6a8ee32a1378964f9984985a` |
| AC_PARTNER | `partner_residence` | `6a8ee32a1378964f9984985b` |
| AC_JOURNAL | `journal_type` | `6a8ee5389762533b5b718449` |
| AC_NUMBERING_RULE | `year_era` | `6a8ee53b1378964f99849987` |
| AC_DOC_SETTING | `side` | `6a8ee53eae2a0e3743a0bc6c` |
| AC_FUND_SOURCE | `fund_type` | `6a8ee5439762533b5b71844f` |
| AC_VAT_RATE | `vat_treatment` | `6a8ee548ae2a0e3743a0bc72` |

`AC_PERIOD.period_status` **ไม่เปลี่ยน** (`6a851f70055f2288c5b73edf`).

---

## 6. บทเรียนใหม่ (เพิ่มเข้า Known Issues / กับดัก `update_worksheet`)

1. 🔴 **`update_worksheet.editFields` บนฟิลด์ SingleSelect/MultipleSelect/Dropdown-inline ไม่แก้ตัวเลือก — เพิ่มซ้อนทับเสมอ** แม้ส่ง `key` เดิมไปก็ถูกเพิกเฉย (schema ไม่มีช่อง key ในการ edit) ⇒ ต้อง `removeFields`+`addFields` เท่านั้น
2. 🔴 **`batch_update_records`/`update_record` ต้องใช้ `rowId` (UUID) ไม่ใช่ `_id`** (Mongo-style ID จาก `get_record_list`) — ใช้ `_id` จะได้ error `10007` (batch) หรือ `430002` (details) เงียบว่า "ไม่พบข้อมูล"
3. ✅ ฟิลด์ที่มี field อื่นผูก Lookup/`sourceField` ห้ามลบ–สร้างใหม่เด็ดขาด — ทางเดียวที่ปลอดภัยคือแก้ label ตัวเลือกผ่านหน้าจอ (double-click ที่ข้อความ → พิมพ์ทับ) ซึ่งคง field ID และทุก option key ไว้ครบ

---

## 7. งานที่เหลือ (ไม่อยู่ในขอบเขตงาน 1.17 นี้)

- งาน 1.11 (ฟิลด์ 8 ตัวยังเป็นชื่ออังกฤษ — คนละเรื่องกับค่าตัวเลือก), 1.12, 1.13, 1.18, 1.19, 1.20 ยังคงค้างตามเดิมใน Roadmap
- พิจารณาว่าจะแปล `source_doc_type`/`source_type`/`event_code` (§4) เป็นงานแยกหรือไม่
