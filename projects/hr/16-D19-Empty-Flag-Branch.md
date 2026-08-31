# D-19 — เงื่อนไข `<flag> ne "1"` ไม่ผ่านเมื่อฟิลด์ว่าง (ไม่ใช่ 0)

**สถานะ:** 🔶 **แก้ครบ 5 workflow แล้ว 30 ส.ค. 2569 · ยืนยันด้วยการยิงจริง 3/5 · WF-HR-04 และ WF-HR-05 ยังรอพิสูจน์** (claim `HR/D19-B` + `HR/D19-C`) — พบและพิสูจน์ด้วย A/B controlled test เมื่อ 30 ส.ค. 2569 (claim `HR/D19-A`)
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
| **WF-HR-05 สรุปเวลาทำงานรายวัน** 🆕 | `6a910184730d20c5b7710fa8` | **ไม่ใช่ branch — เป็น filter ของ node `หาบันทึกลงเวลาที่ยังไม่สรุป`** (`6a91018d730d20c5b7710fdc`, get_multiple/actionId 400 บน `hr_attendance`) | `สรุปแล้ว` `6a8fcd7f353e1b0e4a507d4f` | `10` |

> 🔴 **แถว WF-HR-05 ถูกเพิ่มทีหลังจาก `/scrutinize` (30 ส.ค. 2569) — ก่อนหน้านั้นเอกสารฉบับนี้เขียนผิดว่า "WF-HR-05 ไม่กระทบ"**
> สาเหตุ: สแกนด้วย `hap workflow structure` ซึ่ง **ไม่คืน `filters` ของ node ชนิด search/get_multiple** (ข้อจำกัดที่บันทึกไว้ในไกด์เองแล้ว แต่กลับใช้วิธีนี้สรุป) ⇒ เห็นแต่ branch แล้วสรุปว่าสะอาด
> ที่แย่กว่านั้นคือ **เอกสารเดิมเขียนถูกอยู่แล้ว** ว่า "WF-HR-03/05/13 เสี่ยงเหมือนกัน" แล้วถูกเขียนทับด้วยข้อสรุปที่ผิด
> **วิธีสแกนที่ถูก (ใช้ตั้งแต่นี้ไป):** ไล่ `hap workflow node get <pid> <nodeId>` ทีละ node แล้วเก็บทุก object ที่มี `conditionId` — รันครบ 12 process HR แล้วได้จุดที่ใช้ `≠` ทั้งหมด **5 จุด** ตามตารางข้างบน (WF-HR-05 inner · WF-HR-06 · inner ทั้งหมด สะอาด) · ดูไกด์ §2 ข้อ 22

หมายเหตุ WF-HR-03 มีเงื่อนไข `เคยตัด eq "1"` (`conditionId 9`) ร่วมด้วย — ตัวนั้นไม่ได้รับผลจากค่าว่าง (ว่าง ≠ "1" อยู่แล้ว จึง FALSE ตามเจตนา)

## 4. ทางเลือกในการแก้ (ผู้ใช้เลือกข้อ 2+3 เมื่อ 30 ส.ค. 2569 — ดำเนินการแล้ว ดู §7)

| # | วิธี | ข้อดี | ข้อเสีย |
|---|---|---|---|
| 1 | **สลับขั้ว branch**: เงื่อนไข `flag eq "1"` → เส้น no-op · ให้ catch-all เป็นเส้นทำงาน | ทนค่าว่างถาวร ไม่พึ่ง data hygiene | ต้องแก้ + republish ทุกตัว · ลำดับ `flowIds` ต้องถูก (เงื่อนไขก่อน default) |
| 2 | เพิ่ม OR group: `flag ne "1"` **หรือ** `flag is empty` (`conditionId 8`) | แก้น้อย ตรรกะเดิมยังอ่านออก | operateCondition เป็น 2-D array — ต้องเขียนกลุ่ม OR ให้ถูก |
| 3 | patch ข้อมูล: ตั้ง flag = 0 ทุก record ที่ว่าง | ไม่แตะ workflow เลย | **แก้ปลายเหตุ** — record ใหม่ที่สร้างผ่านฟอร์มจะว่างอีก ตราบใดที่ `defaultValue` ยัง persist ไม่ได้ |

**ข้อเสนอ:** ทำ **2 + 3** — ①patch record ที่ค้างอยู่ตอนนี้ (กันเคสจริงที่รออนุมัติ) ②แก้เงื่อนไขให้ทน empty ③ค่อยหาทางทำให้ `defaultValue` persist เป็นงานแยก

✅ **เคสจริงที่เคยค้าง แก้แล้ว:** `TEST-LR-D15-REVERIFY` (`6a90fd5f1378964f9984e14f`) — `deducted_flag`/`returned_flag` ถูก patch เป็น `0` แล้ว และเงื่อนไข branch ก็ทนค่าว่างแล้ว ⇒ กด Approve ได้ตามปกติ ยอดสิทธิจะถูกตัดจริง

## 5. เครื่องมือแก้ที่ใช้ได้จริง

`hap workflow node save <processId> <nodeId> --type 2 -c '{"operateCondition": …}'` **แก้ node เดิมในที่ได้** ไม่ต้องลบ-สร้างใหม่แบบฝั่ง MCP (`delete_process_node` + `batch_create_process_nodes`) — จากนั้น `hap workflow publish <processId>` เพื่อ release ใหม่
สำรอง `hap --json workflow structure <id>` + `hap --json workflow node get <id> <nodeId>` ลงไฟล์ก่อนแก้เสมอ

## 6. ข้อสังเกตค้าง (ยังไม่สรุป) — เส้นทาง "ไม่พบข้อมูลสิทธิ"

`TEST-LR-D19-D` (`deducted_flag="0"` แต่ `leave_year=""`) → branch ทำงาน (`deducted_flag` เป็น `"1"`) แต่ **ไม่มี ledger และไม่มี balance ใหม่ชื่อ `AUTO-…` ถูกสร้าง**
node `ค้นหาสิทธิและยอดคงเหลือการลา` (`6a8fa9a9fdab77a41c51cd9e`) กรองด้วย พนักงาน AND ประเภทการลา AND **ปีสิทธิ** — `leave_year` ว่างจึงหาไม่เจอ
สมมติฐาน `[?]` — search node (typeId 7) อาจ **หยุด flow เมื่อหาไม่พบ** ทำให้ gateway `พบข้อมูลสิทธิหรือไม่` และเส้น `สร้างสิทธิและยอดคงเหลือการลาใหม่` **ไม่เคยถูกเรียก**
ยังพิสูจน์ไม่ได้จาก CLI/MCP — ต้องเปิด **Workflow History** บนเบราว์เซอร์ (บทเรียน D-17: ห้ามสรุปว่า workflow ไม่ยิงโดยไม่เปิด History)
## 7. สิ่งที่ทำจริง (30 ส.ค. 2569 · claim `HR/D19-B` · ผู้ใช้อนุมัติ "patch data ก่อน + แก้เงื่อนไข")

### ① patch ข้อมูลที่ค้าง — ตั้งธงว่างเป็น `0` (ไม่เหลือธงว่างในระบบแล้ว)

| record | ที่แก้ |
|---|---|
| `TEST-LR-D15-REVERIFY` | `deducted_flag` `""`→`0` · `returned_flag` `""`→`0` |
| `TEST-LR-DOCOK` | `submitted_flag`/`deducted_flag`/`returned_flag` `""`→`0` |
| `TEST-LR-BR083` | เหมือนกัน |
| `TEST-OT-SYSCHK-01` | `hr_paid_flag` `""`→`0` |

### ② เพิ่ม OR group `is empty` เข้าเงื่อนไข branch แล้ว republish ทั้ง 4 workflow

`operateCondition` เป็น array 2 ชั้น (**ชั้นนอก = OR · ชั้นใน = AND**) — วิธีแก้คือ **คัดลอกกลุ่ม AND เดิมทั้งกลุ่ม** แล้วในสำเนาเปลี่ยนเฉพาะเงื่อนไขธงจาก `conditionId "10"` (≠) เป็น `"8"` (ว่าง) พร้อมล้าง `conditionValues` เป็น `[]` — เงื่อนไขอื่นในกลุ่มคงเดิมทุกตัว

```bash
hap workflow node save <processId> <branchNodeId> --type 2 \
  -c '{"operateCondition": [<กลุ่มเดิม>, <สำเนาที่เปลี่ยนธงเป็น conditionId 8>]}'
hap workflow publish <processId>
```

| workflow | processId | branch nodeId | ผลอ่านกลับ | publish |
|---|---|---|---|---|
| WF-HR-01 | `6a8f36bc0e97bf440dda64eb` | `6a8f36c6730d20c5b7646a9f` | `สถานะ:9,ส่งอนุมัติแล้ว:10` \| `สถานะ:9,ส่งอนุมัติแล้ว:8` | ✅ v6 |
| WF-HR-02 | `6a8fa97cfdab77a41c51cb3f` | `6a8fa9a9fdab77a41c51cdac` | `สถานะ:9,ตัดสิทธิแล้ว:10` \| `สถานะ:9,ตัดสิทธิแล้ว:8` | ✅ v5 |
| WF-HR-03 | `6a8fab800e97bf440dddb744` | `6a8faba80e97bf440dddb902` | `สถานะ:9,ตัดสิทธิแล้ว:9,คืนสิทธิแล้ว:10` \| `…,คืนสิทธิแล้ว:8` | ✅ v3 |
| WF-HR-04 | `6a8fd8d35f8564a68c3c1909` | `6a8fd9325f8564a68c3c1cdb` | `สถานะ OT:9,ส่งคำขอแล้ว:10` \| `สถานะ OT:9,ส่งคำขอแล้ว:8` | ✅ v3 |

ทั้ง 4 ตัวยืนยันหลัง publish: `enabled=true, deleted=false` · สำรอง `workflow structure` + `node get` ก่อนแก้ครบทั้ง 4 คู่

### ③ ยืนยันผลด้วยการยิงจริง — เคสเดียวกับที่เคยพัง

| test | ก่อนแก้ | หลังแก้ |
|---|---|---|
| **WF-HR-02** — ใบลา `deducted_flag=""` → Approved | ❌ เงียบ ไม่ตัดสิทธิ (record F) | ✅ `deducted_flag`→`"1"` · used 0→1 · remaining 10→9 (record G) |
| **WF-HR-03** — ใบลาที่ `returned_flag=""` → Cancelled | (ไม่เคยทดสอบ) | ✅ `returned_flag`→`"1"` · used 1→0 · remaining 9→10 (record G) |
| **WF-HR-01** — ใบลา `submitted_flag=""` → Pending supervisor | ❌ เงียบ (D-17) | ✅ `submitted_flag`→`"1"` · `approval_step`→`1` · `submitted_at` ถูกเขียน (record H) |
| **WF-HR-04** | — | ⚠️ แก้ + publish + อ่านกลับตรงแล้ว แต่ **ยังไม่ live-fire test** (โครงเหมือน WF-HR-01 ทุกประการ) |

ล้าง test record G/H + ledger 2 แถวเรียบร้อย · ยอดสิทธิ TEST-EMP1-ANNUAL-2026 กลับมา used=0 / remaining=10 ตามเดิม

### ยังเปิดอยู่หลังการแก้นี้

1. **`defaultValue` ยัง persist ไม่ได้** — record ใหม่ยังเกิดมาพร้อมธงว่าง เพียงแต่ตอนนี้ workflow ทนได้แล้ว (งานแยก)
2. **ยังไม่เคยทดสอบ path ผู้ใช้จริงผ่านฟอร์ม** — record ทดสอบทุกใบสร้างผ่าน API
3. **§6 ข้อสังเกตค้าง** — เส้น "ไม่พบข้อมูลสิทธิ" ยังไม่ได้พิสูจน์ ต้องเปิด Workflow History
## 8. รอบแก้ที่ 2 — WF-HR-05 (30 ส.ค. 2569 · claim `HR/D19-C` · หลัง `/scrutinize`)

**ผลกระทบถ้าไม่แก้:** `hr_summarised_flag` ของ `hr_attendance` ทุก record ใหม่จะเป็น `""` (เพราะ `defaultValue` ยัง persist ไม่ได้) ⇒ filter `สรุปแล้ว ≠ "1"` เป็น FALSE ⇒ **node เลือกได้ 0 แถวทุกครั้ง สรุปเวลาทำงานรายวันไม่เกิดขึ้นเลย โดยไม่มี error** · ตอนพบ `hr_attendance` มี 0 แถวจึงยังไม่เสียหายจริง แต่ workflow publish+enabled รออยู่แล้ว

**สิ่งที่ทำ:** เพิ่ม OR group `สรุปแล้ว is empty` (`conditionId 8`) เข้า `filters[0].conditions` ของ node `6a91018d730d20c5b7710fdc` แล้ว `publish` → v3 (`enabled=true`)

**กับดักที่เจอระหว่างแก้ (บันทึกลงไกด์ §2 ข้อ 23/24 แล้ว):**

1. `hap workflow node save --type 13 -c '{"filters": …}'` (ส่งคีย์เดียวแบบที่ใช้กับ branch ได้) → **500 Internal Server Error** ต้องส่ง config ที่เขียนได้ครบทั้งก้อน
2. `hap workflow node save-get-more --condition '[[A],[B]]'` → rc=0 ตอบ `saved.` แต่ **เก็บแค่ OR group แรก ทิ้ง B เงียบ ๆ** และรีเซ็ต `relation` `true`→`false` กับ `spliceType` `1`→`2` โดยไม่ได้ขอ — ตรวจเจอตอนอ่านกลับเทียบทีละคีย์ แล้ว **คืนค่าทั้งสองกลับเป็นของเดิมแล้ว** (ยืนยัน `relation=True`, `spliceType=1`)

**สถานะการพิสูจน์ — ตรงไปตรงมา:**

| | หลักฐาน |
|---|---|
| เงื่อนไขใหม่อยู่ในระบบจริง | ✅ อ่านกลับได้ 2 OR group (`สรุปแล้ว:10` \| `สรุปแล้ว:8`) · config อื่นเทียบกับต้นฉบับตรงทุกคีย์ (ต่างแค่ `conditionValues[].nodeId/controlId` `null`→`""` ซึ่งเป็นการ normalize ของเซิร์ฟเวอร์) · publish v3 `enabled=true` |
| `conditionId 8` จับค่าว่างได้จริง | ✅ พิสูจน์แล้วบน **branch** (record F/G ของ WF-HR-02, record G ของ WF-HR-03) |
| `conditionId 8` จับค่าว่างได้จริง **ใน filter ของ get_multiple** | ⬜ **ยังไม่ได้พิสูจน์** — ยิงเองไม่ได้ |
| WF-HR-05 ทำงานครบสาย | ⬜ **ยังไม่ได้พิสูจน์** |

**ทำไมพิสูจน์ไม่ได้จาก CLI:** WF-HR-05 เป็น schedule/timer · `hap workflow trigger` คืน instance object มาปกติแต่ **ไม่ได้รัน flow จริง** — ยืนยันด้วย **control case**: ตั้ง `hr_summarised_flag = 0` (ค่าที่ผ่านเงื่อนไขเดิมแน่นอน) แล้ว trigger ก็ยังไม่มีอะไรเปลี่ยนเหมือนกัน ⇒ เครื่องมือทดสอบเป็นตัวที่ล้ม ไม่ใช่ตัวแก้ (บันทึกลงไกด์ §2 ข้อ 25)

**สิ่งที่ต้องทำต่อเพื่อปิดจริง:** เปิด **Workflow History** ของ WF-HR-05 บนเบราว์เซอร์หลังรอบ schedule ถัดไป แล้วดูว่า node `หาบันทึกลงเวลาที่ยังไม่สรุป` เลือกได้กี่แถว
**fixture ที่เตรียมไว้ให้แล้ว:** `hr_attendance` record `TEST-ATT-D19-01` (rowId `0a91bd5e-9b1b-4221-a113-739212564ca7`) — พนักงาน TEST-EMP1 · `วันที่ทำงาน` = 2026-08-30 · เวลาเข้า 09:00 ออก 18:00 · **`hr_summarised_flag` = ว่าง** (ตั้งใจ) ⇒ ถ้าแก้ได้ผล record นี้ต้องถูกสรุปและ flag กลายเป็น `1`

## 9. สำรองก่อนแก้

`projects/hr/_backup/D19-node-conditions-before.json` — เก็บเงื่อนไขต้นฉบับของ node ทั้ง 5 ตัวก่อนแก้ พร้อมคำสั่งกู้คืนใน `_meta`
_(รอบแรกสำรองไว้ใน sandbox ของ agent เท่านั้นซึ่งหายเมื่อ session จบ — `/scrutinize` จับได้ว่า commit อ้างว่า "สำรองแล้ว" เกินจริง จึงย้ายเข้า repo ในรอบนี้)_

## 10. ทดสอบสมมติฐาน "Ignore null value" — ❌ **หักล้างแล้ว** (31 ส.ค. 2569 · claim `HR/IGNORE-EMPTY`)

**ที่มา:** `handoff/AC-D19-APPLY.md` — agent-ac แก้ WF-AC-01/02 ผ่าน Browser UI แล้วพบว่า **ทุกเงื่อนไขมีเช็คบ็อกซ์ "Ignore null value"** อยู่ข้าง operator ซึ่งตรงกับฟิลด์ `ignoreEmpty` / `ignoreValueEmpty` ใน JSON (เป็น `0` ทุกจุดทั้งสองโมดูล ไม่มีใครเคยติ๊ก)

สมมติฐานของเขา: ถ้ามันแปลว่า *"ค่าว่างให้ถือว่าผ่าน"* จะได้วิธีแก้ที่สั้นกว่า OR group **และใช้กับ `filters` ของ get_multiple ได้** (จุดที่ทั้งสองฝั่งยังพิสูจน์ไม่ได้ — WF-HR-05 ของ HR · WF-AC-09/12 ของบัญชี) เพราะเป็น property ของ condition ไม่ใช่โครงสร้าง group

### วิธีทดสอบ

ใช้ชุดทดสอบเดิมของ D-19 (WF-HR-02 branch `Approved และยังไม่ตัดสิทธิ`) — **ถอด OR group ที่สองออกชั่วคราว** ให้เหลือกลุ่มเดียว `สถานะ eq Approved AND ตัดสิทธิแล้ว ≠ "1"` แล้วติ๊กช่องที่ต้องการทดสอบ · publish · สร้างใบลา Draft → Approved

| # | `deducted_flag` | ช่องที่ติ๊ก | ผล |
|---|---|---|---|
| `TEST-LR-IE1` | `""` (ว่าง) | `ignoreEmpty=1` | ❌ **ไม่ตัดสิทธิ** |
| `TEST-LR-IE2` | `"0"` | `ignoreEmpty=1` | ✅ ตัดสิทธิ (used 0→1) — **control** |
| `TEST-LR-IE3` | `""` (ว่าง) | `ignoreEmpty=1` **และ** `ignoreValueEmpty=1` | ❌ **ไม่ตัดสิทธิ** |
| `TEST-LR-IE4` | `""` (ว่าง) | คืน OR group แล้ว (ไม่ติ๊ก) | ✅ ตัดสิทธิ (used 0→1) — **regression** |

🔴 **`TEST-LR-IE2` คือหัวใจของการทดสอบนี้** — พิสูจน์ว่ากลุ่มเงื่อนไขกลุ่มเดียวยังทำงาน workflow ยังยิง และชุดทดสอบยังใช้ได้ ⇒ ผลลบของ IE1/IE3 **ไม่ใช่เพราะเครื่องมือทดสอบพัง** (บทเรียนจากรอบ WF-HR-05 ที่ `workflow trigger` ไม่รัน flow แล้วเกือบสรุปผิด)

### ข้อสรุป

> ❌ **`ignoreEmpty` และ `ignoreValueEmpty` ไม่ได้ทำให้เงื่อนไข `≠` ผ่านเมื่อฟิลด์เป็นค่าว่าง** — ไม่ว่าจะติ๊กตัวเดียวหรือทั้งคู่

⇒ **"Ignore null value" ไม่ใช่ทางลัดของ D-19** · การเพิ่ม OR group `is empty` (`conditionId 8`) ยังเป็นวิธีเดียวที่พิสูจน์แล้ว
⇒ **จุด `filters` ของ get_multiple ยังไม่มีทางแก้ที่พิสูจน์แล้ว** — WF-HR-05 ของเรา และ WF-AC-09/12 ของบัญชี ยังค้างเหมือนเดิม

**ความหมายจริงของช่องนี้ยังไม่ทราบ** — น่าจะเกี่ยวกับกรณีที่ **ค่าเปรียบเทียบ** (ฝั่งขวา ที่ดึงมาจาก node อื่น) เป็นค่าว่าง ไม่ใช่ฟิลด์ที่ถูกทดสอบ (ฝั่งซ้าย) · ยังไม่ได้ทดสอบสมมติฐานนี้

### สภาพหลังทดสอบ

WF-HR-02 คืนค่าเป็น **2 OR group เหมือนเดิมทุกตัวอักษร** (เทียบ JSON แบบ sort_keys แล้วตรง) · publish → v8 · `enabled=true` `deleted=false`
ล้าง test record IE1–IE4 + ledger 2 แถว · คืนยอดสิทธิ `TEST-EMP1-ANNUAL-2026` = used 0 / remaining 10 · ใบลาในระบบเหลือ 4 ใบเท่าเดิม
