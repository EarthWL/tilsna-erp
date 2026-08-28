# ENV — ข้อเท็จจริงระดับ repo · TILSNA ERP

```yaml
docs_vcs: git
workspace_mode: cowork
commit_by: human           # ⚠️ ยังไม่ทดสอบว่า agent รัน git ได้จริงในสภาพแวดล้อมนี้ — ทดสอบ 1 ครั้งแล้วเปลี่ยนเป็น agent
cli_available: unknown     # ⚠️ ดูหมายเหตุด้านล่าง
project_publisher: []      # ระบุผู้อัปเข้า Claude Project (หลัก, สำรอง) ถ้ายังใช้ Project คู่ขนาน

apps:
  deca7391-1761-424b-9af3-c8d043004ad3: ERP - TILSNA      # 69 worksheets — accounting + hr ใช้ร่วมกัน
  23ce02b5-ef67-4f9e-b4f2-fc8d8818734c: API-Lab           # งานทดลอง — ไม่ควรอยู่ repo นี้ ดู MIGRATION.md
  f21b5c19-fab9-49b4-a035-d92d1f71376c: ERP               # 35 worksheets — ⚠️ ไม่มีเอกสารกำกับ ต้องตัดสินว่าคืออะไร
```

## หมายเหตุ `cli_available`

ยืนยันเมื่อ **28 ส.ค. 2569** ว่า `hap` CLI ใช้งานได้จริงกับแอปนี้ — `hap workflow list` คืน 50 workflow, `hap worksheet rules` คืนกฎจริง, `record get --include-system-fields` คืน `_createdBy` — **แต่ทดสอบบนเครื่อง Windows ของผู้ดูแล ไม่ใช่เครื่องที่ build agent รัน**

ค่านี้เป็นของ **เครื่อง** ไม่ใช่ของ repo ⇒ ตั้งเป็น `unknown` ไว้ก่อน · agent ต้องรันเองครั้งเดียวตอน Phase 0 แล้วแก้บรรทัดนี้:

```bash
hap --version && hap auth whoami && hap app list-managed   # ต้องเห็น deca7391… ในรายการ
# Windows: ตั้ง $env:PYTHONUTF8="1" ก่อน ไม่งั้นชื่อไทยทำให้พังด้วย charmap error
```

## กติกาที่ผูกกับค่าข้างบน

| ค่า | ผล |
|---|---|
| `cli_available` ไม่ใช่ `yes` | **ห้ามเขียน Surface = CLI ลง Build Spec** ให้ใช้ Browser |
| accounting + hr ใช้ `deca7391` ร่วมกัน | **ต้องจองงานก่อนแตะแอปเสมอ** — สองสายงานชนกันได้จริง (มี `hr_pay_component.biz_coa_account` วิ่งข้ามโมดูล) |
| `f21b5c19` ยังไม่มีเอกสาร | อย่าแตะจนกว่าจะรู้ว่าคืออะไร |
