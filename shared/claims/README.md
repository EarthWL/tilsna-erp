# ใบจองงาน — หนึ่งไฟล์ต่อหนึ่ง agent

`<agent-id>.log` · **ต่อท้ายอย่างเดียว ห้ามแก้บรรทัดเก่า ห้ามแตะไฟล์ของ agent อื่น**

เหตุผล: log ไฟล์เดียวร่วมกันจะชน merge conflict ทุกครั้งที่สอง agent จองพร้อมกัน — ซึ่งคือสถานการณ์ที่กลไกนี้มีไว้แก้พอดี (ทดสอบยืนยันแล้ว)

```
CLAIM   2026-08-29T09:00Z deca7391 HR/P5-6 hr_salary_structure,hr_payslip*
RELEASE 2026-08-29T16:40Z HR/P5-6
HANDOFF 2026-08-29T11:05Z AC/P8.6 handoff/AC-P8.6.md
EXPIRED 2026-08-29T12:00Z HR/ZOMBIE by=agent-ac was=agent-hr
```

สถานะปัจจุบัน = CLAIM ที่ยังไม่มี RELEASE/HANDOFF/EXPIRED · TTL 8 ชั่วโมง · agent อ่าน 30 บรรทัดท้ายพอ · เกิน 500 บรรทัดให้ตัดครึ่งบนไป `.archive/`
