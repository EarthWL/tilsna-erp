# ENV — ข้อเท็จจริงระดับ repo · TILSNA ERP

```yaml
docs_vcs: git
workspace_mode: cowork
commit_by: human           # git identity ตั้งแล้ว (agent-ac, ยืนยัน 29 ส.ค. 2569) — แต่ push ยังทดสอบไม่ได้ (remote ต่อไม่ติด รอ credential) จึงยังไม่เปลี่ยนเป็น agent
cli_available: split-by-machine   # ⚠️ ไม่ใช่ yes/no เดียว — ดูหมายเหตุด้านล่าง มี 3 สภาพแวดล้อมที่แยกกัน
project_publisher: []      # ระบุผู้อัปเข้า Claude Project (หลัก, สำรอง) ถ้ายังใช้ Project คู่ขนาน

apps:
  deca7391-1761-424b-9af3-c8d043004ad3: ERP - TILSNA      # 69 worksheets — accounting + hr ใช้ร่วมกัน
  23ce02b5-ef67-4f9e-b4f2-fc8d8818734c: API-Lab           # งานทดลอง — ไม่ควรอยู่ repo นี้ ดู MIGRATION.md
  f21b5c19-fab9-49b4-a035-d92d1f71376c: ERP               # 35 worksheets — ⚠️ ไม่มีเอกสารกำกับ ต้องตัดสินว่าคืออะไร
```

## หมายเหตุ `cli_available` — แก้ไข 29 ส.ค. 2569: ไม่ใช่ค่าเดียว

เดิมเข้าใจว่า `cli_available` เป็นคุณสมบัติของ "เครื่องผู้ดูแล" เครื่องเดียว แต่ทดสอบแล้วพบว่ามี **3 สภาพแวดล้อมที่แยกกันจริง** และผลไม่เหมือนกัน:

| สภาพแวดล้อม | ผล | ยืนยันเมื่อ |
|---|---|---|
| เครื่อง Windows ของผู้ดูแลเอง (native shell, รันมือ) | ✅ ใช้ได้ — `hap workflow list` คืน 50 workflow, `hap worksheet rules` คืนกฎจริง, `record get --include-system-fields` คืน `_createdBy` | 28 ส.ค. 2569 |
| device bridge (Linux VM ที่ mount โฟลเดอร์นี้เข้ามาให้ agent ใช้ `device_bash`) | ❌ ไม่มี `hap` ติดตั้ง (`hap: command not found`) | 29 ส.ค. 2569 |
| cloud sandbox ของ agent เอง (`Bash` ตรง ไม่ผ่าน bridge) | ✅ ใช้ได้เต็ม — `hap 0.8.21`, authenticated เป็น Wanadtapong.l, **current app = deca7391 พอดี** | 29 ส.ค. 2569 (`hap --version && hap auth whoami` — ดู `hap app backup` ที่รันจริงแล้วด้านล่าง) |

**สรุปการใช้งาน:** งาน Surface C (CLI) ที่ agent ต้องทำเอง ให้รันผ่าน **cloud sandbox ของ agent** (แถวที่ 3) — ยืนยันแล้วว่าชี้ไปแอปที่ถูกต้องและไม่ต้องพึ่ง bridge เลย อย่าพยายามรัน `hap` ผ่าน `device_bash` เพราะไม่ได้ติดตั้งไว้ที่นั่น หากต้องการให้ผู้ดูแลรันเอง (เช่น งานที่ต้องยืนยันตัวตนเป็นคนจริง) ให้ใช้แถวที่ 1

หาก agent ตัวใดพบว่า cloud sandbox ของตัวเองใช้ `hap` ไม่ได้ (คนละ container กัน อาจไม่ auth ไว้) ให้รันตรวจสอบใหม่:

```bash
hap --version && hap auth whoami && hap app list-managed   # ต้องเห็น deca7391… ในรายการ
```

## กติกาที่ผูกกับค่าข้างบน

| ค่า | ผล |
|---|---|
| Surface C ในสภาพแวดล้อมที่ยังไม่ยืนยัน (`unknown`) | **ห้ามเขียน Surface = CLI ลง Build Spec** ให้ใช้ Browser จนกว่าจะทดสอบแล้วเห็นผลจริง |
| accounting + hr ใช้ `deca7391` ร่วมกัน | **ต้องจองงานก่อนแตะแอปเสมอ** — สองสายงานชนกันได้จริง (มี `hr_pay_component.biz_coa_account` วิ่งข้ามโมดูล) |
| `f21b5c19` ยังไม่มีเอกสาร | อย่าแตะจนกว่าจะรู้ว่าคืออะไร |
| `commit_by: human` แต่ git identity agent ตั้งแล้ว | agent รัน `git config`/`git add`/`git commit` local ได้ (ทดสอบแล้ว) — แต่ `git push` ยังไม่ผ่านเพราะ remote ต่อไม่ติด (credential) ห้าม push จนกว่าผู้ดูแลจะแจ้งว่าตั้ง credential เสร็จ |

## D-5 (จาก MIGRATION.md) — สำรองแอปแล้ว ✅

รัน `hap app backup deca7391-1761-424b-9af3-c8d043004ad3` จาก cloud sandbox ของ agent เมื่อ **29 ส.ค. 2569** — ยืนยันด้วย `hap app backup-logs deca7391-1761-424b-9af3-c8d043004ad3`:

```
backupFileName: Manual Backup_ERP - TILSNA_20260829_0206
rowTotal: 357 · appItemTotal: 69 · operator: Wanadtapong.l
```

นี่คือการสำรองครั้งแรกของแอปนี้เท่าที่มีบันทึกไว้ — ควรตั้งรอบสำรองประจำ (ไม่ใช่ manual ครั้งเดียว) เป็นงานถัดไป ถ้า `hap` มี schedule/cron option ให้ใช้ ไม่งั้นบันทึกไว้เป็น reminder ใน Roadmap Tracker
