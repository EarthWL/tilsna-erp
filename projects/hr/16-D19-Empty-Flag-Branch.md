# D-19 — เงื่อนไข `<flag> ne "1"` ไม่ผ่านเมื่อฟิลด์ว่าง (ไม่ใช่ 0)

**สถานะ:** 🔴 ยืนยันแล้วด้วย A/B controlled test · 30 ส.ค. 2569 · agent-hr · claim `HR/D19-A`
**ผลกระทบ:** WF-HR-02 **ไม่ตัดสิทธิลา** เมื่อใบลาที่ `deducted_flag` ว่างถูกอนุมัติ — เงียบสนิท ไม่มี error ไม่มีร่องรอยบน record
**ที่มา:** ต่อยอดจาก D-17 (`15-Investigations-D13-D17.md`) ซึ่งพบอาการเดียวกันบน `submitted_flag` ของ WF-HR-01

---

## 1. หลักฐาน — A/B controlled test (E vs F)

สร้างใบลา 2 ใบที่ **เหมือนกันทุกฟิลด์** ยกเว้น `deducted_flag` แล้วเปลี่ยนสถานะ Draft → Approved เท่ากัน

| record | leave_year | `deducted_flag` ก่อน | ผลหลัง Approved | ยอดสิทธิ TEST-EMP1-ANNUAL-2026 |
|---|---|---|---|---|
| `TEST-LR-D19-E` | 2026 | `"0"` | `deducted_flag` = `"1"` | used 0.0 → **1.0** · remaining 10.0 → **9.0** ✅ |
| `TEST-LR-D19-F` | 2026 | `""` (ว่าง) | `deducted_flag` = `""` **ไม่เปลี่ยน** | **ไม่ขยับ** ❌ |

⇒ ตัวแปรเดียวที่ต่างคือ ว่าง vs 0 · workflow ตัวเดียวกัน · record เหมือนกัน ⇒ **`"" ne "1"` ประเมินเป็น FALSE**

เงื่อนไขที่ตกคือ branch `Approved และยังไม่ตัดสิทธิ` (`6a8fa9a9fdab77a41c51cdac`) ใน WF-HR-02 (`6a8fa97cfdab77a41c51cb3f`)
เมื่อ FALSE จะไหลไป branch `อื่นๆ (ไม่ทำอะไร)` (`6a8fa9a9fdab77a41c51cdaf`, catch-all) — ซึ่งเป็น no-op ⇒ **เงียบ**

_ล้าง test data และคืนยอดสิทธิกลับ used=0 / remaining=10 เรียบร้อยแล้ว (ลบ 6 ใบลา + 1 ledger)_

## 2. ทำไมฟิลด์ถึงว่างตั้งแต่แรก

ต่อจาก D-17: `defaultValue` ที่ตั้งผ่าน `editFields` **ไม่ persist** — `hap worksheet fields --raw` แสดง `default: ""` บนฟิลด์ flag ทุกตัว
และ MCP `get_worksheet_structure` **ไม่คืนค่า `defaultValue` เลย** จึงมองไม่เห็นว่าค่าเริ่มต้นหาย

## 3. workflow / branch ที่ใช้ `ne` กับ flag (เสี่ยงแบบเดียวกัน)

| workflow | processId | branch | ฟิลด์ที่ทดสอบ | conditionId |
|---|---|---|---|---|
| WF-HR-01 อนุมัติใบลา | `6a8f36bc0e97bf440dda64eb` | `รอหัวหน้างานอนุมัติ (ยังไม่ส่ง)` | `ส่งอนุมัติแล้ว` `…849b9b` | `10` |
| WF-HR-02 ตัดสิทธิลา | `6a8fa97cfdab77a41c51cb3f` | `Approved และยังไม่ตัดสิทธิ` | `ตัดสิทธิแล้ว` `…849b9c` | `10` |
| WF-HR-03 คืนสิทธิลา | `6a8fab800e97bf440dddb744` | `Cancelled + เคยตัด + ยังไม่คืน` | `คืนสิทธิแล้ว` `…849b9d` | `10` |
| WF-HR-04 อนุมัติ OT | `6a8fd8d35f8564a68c3c1909` | `รอหัวหน้างานอนุมัติ (ยังไม่ส่ง)` | `สถานะส่งคำขอแล้ว` `…f13075` | `10` |

หมายเหตุ WF-HR-03 มีเงื่อนไข `เคยตัด eq "1"` (`conditionId 9`) ร่วมด้วย — ตัวนั้นไม่ได้รับผลจากค่าว่าง (ว่าง ≠ "1" อยู่แล้ว จึง FALSE ตามเจตนา)

## 4. ทางเลือกในการแก้ (ยังไม่ลงมือ — ต้องขออนุมัติเพราะแตะ workflow ที่ publish แล้ว)

| # | วิธี | ข้อดี | ข้อเสีย |
|---|---|---|---|
| 1 | **สลับขั้ว branch**: เงื่อนไข `flag eq "1"` → เส้น no-op · ให้ catch-all เป็นเส้นทำงาน | ทนค่าว่างถาวร ไม่พึ่ง data hygiene | ต้องแก้ + republish ทุกตัว · ลำดับ `flowIds` ต้องถูก (เงื่อนไขก่อน default) |
| 2 | เพิ่ม OR group: `flag ne "1"` **หรือ** `flag is empty` (`conditionId 8`) | แก้น้อย ตรรกะเดิมยังอ่านออก | operateCondition เป็น 2-D array — ต้องเขียนกลุ่ม OR ให้ถูก |
| 3 | patch ข้อมูล: ตั้ง flag = 0 ทุก record ที่ว่าง | ไม่แตะ workflow เลย | **แก้ปลายเหตุ** — record ใหม่ที่สร้างผ่านฟอร์มจะว่างอีก ตราบใดที่ `defaultValue` ยัง persist ไม่ได้ |

**ข้อเสนอ:** ทำ **2 + 3** — ①patch record ที่ค้างอยู่ตอนนี้ (กันเคสจริงที่รออนุมัติ) ②แก้เงื่อนไขให้ทน empty ③ค่อยหาทางทำให้ `defaultValue` persist เป็นงานแยก

🔴 **เคสจริงที่ค้างอยู่ตอนนี้:** `TEST-LR-D15-REVERIFY` (`6a90fd5f1378964f9984e14f`) — status `Pending supervisor`, `deducted_flag` = `""`, มี To-do ค้างที่ Wanadtapong.l · **ถ้ากด Approve ตอนนี้ ยอดสิทธิจะไม่ถูกตัด**

## 5. เครื่องมือแก้ที่ใช้ได้จริง

`hap workflow node save <processId> <nodeId> --type 2 -c '{"operateCondition": …}'` **แก้ node เดิมในที่ได้** ไม่ต้องลบ-สร้างใหม่แบบฝั่ง MCP (`delete_process_node` + `batch_create_process_nodes`) — จากนั้น `hap workflow publish <processId>` เพื่อ release ใหม่
สำรอง `hap --json workflow structure <id>` + `hap --json workflow node get <id> <nodeId>` ลงไฟล์ก่อนแก้เสมอ

## 6. ข้อสังเกตค้าง (ยังไม่สรุป) — เส้นทาง "ไม่พบข้อมูลสิทธิ"

`TEST-LR-D19-D` (`deducted_flag="0"` แต่ `leave_year=""`) → branch ทำงาน (`deducted_flag` เป็น `"1"`) แต่ **ไม่มี ledger และไม่มี balance ใหม่ชื่อ `AUTO-…` ถูกสร้าง**
node `ค้นหาสิทธิและยอดคงเหลือการลา` (`6a8fa9a9fdab77a41c51cd9e`) กรองด้วย พนักงาน AND ประเภทการลา AND **ปีสิทธิ** — `leave_year` ว่างจึงหาไม่เจอ
สมมติฐาน `[?]` — search node (typeId 7) อาจ **หยุด flow เมื่อหาไม่พบ** ทำให้ gateway `พบข้อมูลสิทธิหรือไม่` และเส้น `สร้างสิทธิและยอดคงเหลือการลาใหม่` **ไม่เคยถูกเรียก**
ยังพิสูจน์ไม่ได้จาก CLI/MCP — ต้องเปิด **Workflow History** บนเบราว์เซอร์ (บทเรียน D-17: ห้ามสรุปว่า workflow ไม่ยิงโดยไม่เปิด History)
