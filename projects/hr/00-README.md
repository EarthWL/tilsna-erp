# โมดูลทรัพยากรบุคคล (HR) — TILSNA ERP บน Nocoly
> ชุดเอกสารสำหรับให้ build agent (`nocoly-hybrid-builder-v2`) สร้างระบบได้โดยไม่หลง
> สร้างเมื่อ 26 สิงหาคม 2569 · แอป **ERP - TILSNA** `deca7391-1761-424b-9af3-c8d043004ad3` · connector `ERP_-_TILSNA`

## สถานะปัจจุบัน
🔴 **ยังไม่มี object ของ HR บนเซิร์ฟเวอร์แม้แต่ชิ้นเดียว** — เอกสารเสร็จแล้ว รอเริ่มสร้าง
แอปนี้มีโมดูลบัญชี 34 worksheet · 35 optionset · 8 custom role ทำงานอยู่แล้ว ⇒ **ห้ามสร้างซ้ำ ห้ามแก้โครงสร้างของบัญชี**

## ใช้ไฟล์ไหนตอนไหน

| ไฟล์ | ใครอ่าน | เมื่อไร |
|---|---|---|
| `01-BRD.md` | ผู้บริหาร · ผู้ตรวจรับ | ตกลงขอบเขต · ตรวจรับตามเกณฑ์ §12 |
| `02-BuildSpec-FRS.md` | **build agent** | 🔴 **เปิดทุกครั้งก่อนแตะ object ใด ๆ** — ID Registry · field ทุกตัว · workflow ทุก node · Test recipe |
| `03-RTM-Status.md` | PM · QA | สอบทานว่าความต้องการข้อไหนทำแล้ว/ยัง · ดู Gap ที่ยังบล็อกอยู่ |
| `04-CLAUDE-memory.md` | **build agent** | 🔴 **โหลดทุก session ก่อนเริ่มงาน** — ข้อกำหนด · กับดักเฉพาะแอปนี้ · pointer ไปไฟล์อื่น (~13k tokens) |
| `15-Investigations-D13-D17.md` · `16-D19-Empty-Flag-Branch.md` | build agent | เปิดเมื่อเจออาการเดิมซ้ำ — บันทึกการสอบสวนเต็มของ D-13/D-15/D-17/D-19 |
| `17-ID-Registry-HR.md` | **build agent** | 🔴 **เปิดเมื่อจะแตะ object จริง** — ws / view / workflow ID · ตารางบัญชีที่ HR เขียนถึง · option key ที่ใช้บ่อย (แยกออกจาก memory 30 ส.ค. 2569) |
| `05-Roadmap-Tracker.md` | PM · build agent | 🔴 **living doc** — อัปเดตทุกครั้งที่เริ่ม/ปิดงาน |
| `06-Demo-Plan-Checklist.md` | ผู้สาธิต · QA | เตรียมเดโมและตรวจความครบถ้วนก่อนส่งมอบ |

## เริ่มงานอย่างไร (build agent)
1. โหลด `04-CLAUDE-memory.md` ให้จบ · ความรู้แพลตฟอร์ม (ไม่ผูกกับแอปนี้) อยู่ที่ `shared/00-HAP-Working-Guide.md` · ID ระดับ object อยู่ที่ `17-ID-Registry-HR.md`
2. เปิด `02-BuildSpec-FRS.md` §0 (DO/DON'T) และ §1 (ID Registry)
3. **ข้าม Phase 1 Interview ของ `nocoly-hybrid-builder-v2`** — สรุป checklist จาก spec ให้ผู้ใช้ยืนยัน แล้วเริ่ม Phase 3
4. ทำตามลำดับใน `05-Roadmap-Tracker.md` เริ่มที่ **P0** (ปลด blocker ก่อน)
5. หลัง `create_*` ทุกครั้ง อ่าน ID กลับแล้วเติมแทน `<TBD>` ใน BuildSpec **ทันที**

## 🔴 Blocker ที่ต้องปลดก่อนเริ่ม
- **G-06** มีบัญชีผู้ใช้ในองค์กรเพียง 2 บัญชี ⇒ ทดสอบอนุมัติ 2 ระดับและสิทธิ์ 8 บทบาทไม่ได้
- **G-02** `ac_posting_rule.event_code` ไม่มีค่าสำหรับเงินเดือน ⇒ WF-HR-10 ทำงานไม่ได้
- **G-05** ยังไม่ยืนยันอัตราประกันสังคมและขั้นบันไดภาษีที่บังคับใช้จริง

## ขอบเขตโดยย่อ
41 worksheet · 24 optionset ใหม่ · 8 บทบาท · 20 workflow · 15 custom action · 27 FR · 20 เกณฑ์การยอมรับ
ครอบคลุม Core HR · การลา · ลงเวลา/OT · เงินเดือนและภาษี · สวัสดิการและการเบิก · สรรหา ประเมิน อบรม
เชื่อมกับโมดูลบัญชี 2 จุด: ใบสำคัญเงินเดือน (WF-HR-10) และใบขออนุมัติเบิกจ่าย (WF-HR-12)
