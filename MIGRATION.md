# MIGRATION — ย้ายเอกสาร TILSNA เข้า repo

_28 ส.ค. 2569 · รอบนี้ทำเฉพาะ **โครงสร้าง** ไม่แตะเนื้อหาสักไฟล์_

## ทำอะไรไปแล้ว

| จาก | ไป |
|---|---|
| `tilsna-accounting_*.md` (13 ไฟล์) | `projects/accounting/` ตัด prefix ออก |
| `tilsna-hr_*.md` (10 ไฟล์) | `projects/hr/` ตัด prefix ออก |
| `nocoly-shared_00-HAP-Working-Guide.md` | `shared/00-HAP-Working-Guide.md` |

**เนื้อหาทุกไฟล์เหมือนเดิมทุกตัวอักษร** — การตัด prefix ทำให้ลิงก์ภายในเอกสาร (ซึ่งอ้างด้วยชื่อสั้น เช่น `` `04-CLAUDE-memory.md` ``) ชี้ถูกต้องขึ้น ไม่ใช่พัง

## ทำไมไม่แก้เนื้อหาในรอบนี้

ฝั่ง accounting ยังทำงานอยู่ ⇒ การเขียนทับไฟล์ที่ agent กำลังแก้จะชนกันแน่นอน · และการบีบเอกสารเป็น operation ที่กู้ไม่ได้ **จนกว่าจะมี commit แรก** ⇒ ลำดับที่ปลอดภัยคือ **push ขึ้น repo ก่อน แล้วค่อยแก้เนื้อหา** เพราะตอนนั้นทุกอย่างย้อนได้

---

## งานเนื้อหาที่ค้าง (ทำหลังฝั่ง accounting หยุด)

### A. ข้อมูลผิดที่ต้องแก้ — เร่งด่วนสุด

| ที่ | ปัญหา | แก้เป็น |
|---|---|---|
| `accounting/02-BuildSpec-FRS.md` บรรทัด 32, 953, 1077 | สั่งพิสูจน์ workflow ด้วย `get_record_logs` → operator `user-workflow` — **ให้ผลลบลวง** (ยืนยัน 28 ส.ค.: log คืน `user-api` แม้ `_createdBy` เป็น `user-workflow`) | `get_record_details(includeSystemFields:true)` → `_createdBy`/`_updatedBy` |
| ไฟล์เดียวกัน บรรทัด 46 | **เขียนถูกอยู่แล้ว** — ทีมค้นพบก่อนแล้วแต่ไม่ได้ตามไปแก้จุดอื่น | ใช้เป็นต้นแบบ |
| `hr/*` | ตรวจแบบเดียวกัน ยังไม่ได้ไล่ | — |

### B. ยกความรู้ขึ้นชั้นบน

`accounting/04-CLAUDE-memory.md` มีกับดักถึงข้อ 34 · **ข้อ 26–32 ยกขึ้นสกิลแล้ว** (`anti-drift-playbook.md` §9.1/§9.3/§9.4) ที่เหลือต้องไล่ว่าข้อไหนเป็นความรู้แพลตฟอร์ม (→ `shared/00-HAP-Working-Guide.md`) ข้อไหนเฉพาะแอป (อยู่เดิม)

เกณฑ์: ประโยคนั้นมีชื่อตาราง/ฟิลด์ของแอปนี้อยู่ไหม — ถ้าไม่มี = อยู่ผิดที่

### C. บีบเอกสาร (ทำหลัง B เท่านั้น — บีบก่อนยกขึ้น = ความรู้หายถาวร)

วัดเมื่อ 28 ส.ค.:

| | hr | accounting |
|---|---|---|
| `04-CLAUDE-memory.md` | **11,391 คำ** | 5,796 คำ |
| บรรทัด `_อัปเดตล่าสุด:_` เดียว | **1,397 คำ ซ้อน 12 ชั้น** = 12% | 600 คำ ซ้อน 3 ชั้น |
| section "สถานะงานล่าสุด" (สำเนาของ Roadmap) | 2,061 คำ = 18% | 127 คำ |
| Known Issues | 5,132 คำ = 45% | 631 คำ |

ลำดับ: ① ยกความรู้แพลตฟอร์มขึ้น → ② ลบ section สถานะ ใส่ pointer ไป `05-Roadmap-Tracker.md` → ③ แยกการสอบสวนยาว >500 คำ เป็นไฟล์เลข (แบบที่ accounting `07-`–`12-` ทำอยู่แล้ว) → ④ บีบ prose ที่เหลือ → ⑤ ตัด ID ที่ซ้ำกับ BuildSpec §1

เป้าหมาย ~6,000 คำต่อไฟล์ · `_อัปเดตล่าสุด:_` เหลือ 1 รายการ ประวัติอยู่ใน commit

### D. เรื่องที่ต้องตัดสินใจ ไม่ใช่แค่แก้ไฟล์

| # | เรื่อง | หลักฐาน |
|---|---|---|
| D-1 | **API-Lab อยู่ผิด repo** — เป็นงานทดลองคนละแอป ควรแยกออกไป (ยังไม่ได้ย้ายมาใน repo นี้) และเอกสารของมันสั่งพิสูจน์ด้วย `get_record_logs` 9 จุด ผู้ดูแลระบุว่า **outdate** ⇒ ปั๊ม `DEPRECATED` ที่หัวไฟล์แทนการลบ ก่อนที่ agent จะไปดูดวิธีเก่ากลับมาใช้ |
| D-2 | **แอป `f21b5c19` "ERP" 35 worksheets ไม่มีเอกสารกำกับเลย** — ของเก่าที่ควรเก็บกวาด หรือของจริงอีกสายที่ไม่มีเอกสาร |
| D-3 | **`ac_gl` ว่าง 0 แถว ทั้งที่ WF-AC-02 เปิดอยู่** และมี workflow ชื่อซ้ำที่ Enabled พร้อมกัน 4 ตัวในกลุ่มใบสำคัญ — agent กำลังตรวจ |
| D-4 | **`_owner = user-undefined` บนแถวที่ workflow สร้าง** ⇒ role ที่ตั้ง scope "เฉพาะของตัวเอง" มองไม่เห็น — ยังไม่ได้ตรวจว่า 8 role ของ accounting มีตัวไหนตั้งแบบนั้นไหม (`hap app role list` → `role permissions`) |
| D-5 | **ยังไม่เคยสำรองแอป** — `hap app backup deca7391…` แล้วยืนยันด้วย `backup-logs` · คอนฟิกบนเซิร์ฟเวอร์คือสิ่งเดียวในระบบที่สร้างใหม่ไม่ได้ |

---

## ก่อนให้ agent เริ่มทำงานจาก repo นี้

```bash
git init && git branch -M main
git remote add origin <private repo>
git config user.name "agent-ac"        # หรือ agent-hr — หนึ่ง clone ต่อหนึ่งสายงาน
git config user.email "agent-ac@tilsna.local"

SKILLDIR=$(dirname "$(find /mnt/skills -name preflight.sh -path '*nocoly-build-docs*' | head -1)")
cp "$SKILLDIR"/*.sh tools/ && chmod +x tools/*.sh
./tools/check-repo.sh                  # ต้องได้ "พร้อมใช้"

git add -A && git commit -m "chore: migrate TILSNA docs into repo (structure only)"
git push -u origin main
```

**commit แรกต้องเป็นสภาพเดิมทุกตัวอักษร** — นั่นคือสิ่งที่ทำให้งานข้อ C (ซึ่งกู้ไม่ได้ในโลกที่ไม่มี git) กลายเป็นงานที่ปลอดภัย
