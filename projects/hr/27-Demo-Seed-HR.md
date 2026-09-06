# ชุดข้อมูลเสมือนจริง — โมดูล HR (1 ก.ย. 2569)

> สร้างเพื่อใช้ **นำเสนอให้เห็นภาพระบบ** ไม่ใช่ข้อมูลจริงขององค์กร
> **ทุกชื่อ เลขบัตรประชาชน อีเมล เบอร์โทร และตัวเลขเงินเดือนเป็นข้อมูลสมมติทั้งหมด**
> `rowId` ของทุกแถวถูกบันทึกไว้ในไฟล์นี้ ⇒ ลบออกได้ครบโดยไม่กระทบข้อมูลอื่น

## บริษัทสมมติ

**บริษัท ทิลสนา จำกัด** — พนักงาน 8 คน (ยังไม่รวม `TEST-EMP1`/`TEST-EMP2` ที่เป็น fixture เดิมของการทดสอบ workflow)

| รหัส | ชื่อ | ตำแหน่ง | ระดับ | เงินเดือน | หัวหน้า | สถานะ |
|---|---|---|---|---:|---|---|
| EMP-0001 | ธนกฤต วงศ์อนันต์ | กรรมการผู้จัดการ | L6 | 120,000 | — | Active |
| EMP-0002 | ศิริพร ตั้งจิตต์ | ผู้จัดการฝ่ายบุคคล | L4 | 55,000 | EMP-0001 | Active |
| EMP-0003 | ณัฐพงษ์ ศรีสมบูรณ์ | ผู้จัดการฝ่ายบัญชี | L4 | 58,000 | EMP-0001 | Active |
| EMP-0004 | กมลชนก พูนสวัสดิ์ | เจ้าหน้าที่บุคคล | L2 | 26,000 | EMP-0002 | Active |
| EMP-0005 | วรเทพ อินทรสุวรรณ | เจ้าหน้าที่บัญชี | L2 | 28,000 | EMP-0003 | Active |
| EMP-0006 | ปิยะนุช แก้วประเสริฐ | หัวหน้าทีมขาย | L3 | 38,000 | EMP-0001 | Active |
| EMP-0007 | อธิวัฒน์ บุญมาก | พนักงานขาย | L1 | 20,000 | EMP-0006 | Active |
| EMP-0008 | จันทร์เพ็ญ สายทอง | พนักงานปฏิบัติการ | L1 | 17,000 | EMP-0006 | **Probation** |

## สิ่งที่สร้าง

| ตาราง | จำนวน | หมายเหตุ |
|---|---:|---|
| `hr_employee` | 8 | พนักงาน 8 คน · มีสายบังคับบัญชาครบ |
| `hr_employment_contract` | 8 | สัญญาจ้าง 8 ใบ · 2 ใบเป็นสัญญามีกำหนด (EMP-0007 หมด 5 ต.ค. 2026 ⇒ **ใช้สาธิต WF-HR-13A ได้**) |
| `hr_salary_structure` | 8 | โครงสร้างเงินเดือน 8 แถว |
| `hr_leave_balance` | 24 | สิทธิลาปี 2026 · 8 คน × 3 ประเภท (พักร้อน/ป่วย/กิจ) · มียอดยกมาจากปีก่อน |
| `hr_leave_ledger` | 33 | รายการเคลื่อนไหว 30 แถวที่ seed + **3 แถวที่ WF-HR-02 เขียนเองตอนอนุมัติใบลา** |
| `hr_leave_request` | 10 | ใบลา 10 ใบ ครบทุกสถานะ: Approved 3 · Pending supervisor 2 · Pending HR 1 · Draft 2 · Rejected 1 · Cancelled 1 |
| `hr_attendance` | 40 | บันทึกลงเวลา 1 สัปดาห์ (24–28 ส.ค. 2026) × 8 คน = 40 แถว · มีมาสาย 3 · ขาดงาน 1 · ครึ่งวัน 1 |
| `hr_ot_request` | 5 | ใบขอ OT 5 ใบ · อนุมัติแล้ว 2 (จ่ายแล้ว) · รออนุมัติ 2 · ไม่อนุมัติ 1 |
| `hr_job_requisition` | 2 | ใบขออัตรากำลัง 2 ใบ · อนุมัติแล้ว 1 · รอ HR 1 |
| `hr_candidate` | 6 | ผู้สมัคร 6 คน กระจายทุกขั้นตอน: Hired · Interview 2 · Interview 1 · Screening · Applied · Rejected |
| `hr_interview` | 6 | นัดสัมภาษณ์ 6 นัด · มีผลแล้ว 4 · รอพิจารณา 2 |
| `hr_appraisal_cycle` | 1 | รอบประเมินครึ่งปีแรก 2569 · เปิดรอบแล้ว |
| `hr_appraisal` | 10 | **10 ใบที่ WF-HR-18 สร้างเองทั้งหมด** · เติมคะแนน/ความเห็นให้ 8 ใบ กระจาย 4 สถานะ |
| `hr_appraisal_item` | 12 | รายการประเมินย่อย 12 แถว (3 คน × 4 หัวข้อ KPI/สมรรถนะ/พฤติกรรม) |
| `hr_pay_period` | 1 | งวดเงินเดือน ส.ค. 2569 · สถานะ Approved |
| `hr_payslip` | 8 | สลิป 8 ใบ · รวมรายรับ 363,800.00 · รายหัก 20,583.33 · **สุทธิ 343,216.67** |
| `hr_payslip_line` | 23 | บรรทัดในสลิป 23 แถว (เงินเดือน · OT · หักขาดงาน · ประกันสังคม · ภาษี) |
| `hr_welfare_scheme` | 5 | สวัสดิการ 5 รายการ · 1 รายการจำกัดเฉพาะระดับ L4 ขึ้นไป |
| `hr_welfare_balance` | 14 | วงเงินสวัสดิการรายคน 14 แถว · มีทั้งใช้เต็ม ใช้บางส่วน และยังไม่ใช้ |

**รวม 224 แถว**

## 🟢 ส่วนที่ระบบคำนวณเอง ไม่ได้ยัดข้อมูล

| สิ่งที่เกิดขึ้น | ทำอย่างไร | ผลที่ตรวจได้ |
|---|---|---|
| ตัดสิทธิลาเมื่ออนุมัติ | สร้างใบลาเป็น Draft แล้วเปลี่ยนสถานะเป็น Approved จริง | **WF-HR-02** หักยอดและเขียน ledger เอง — `EMP-0004` พักร้อน 7 → ใช้ 3 → เหลือ **4** · `EMP-0005` ป่วย 30 → เหลือ **29** · `EMP-0007` กิจ 3 → เหลือ **2** |
| สร้างแบบประเมินทั้งองค์กร | ตั้ง `cycle_open_flag` = 1 | **WF-HR-18** สร้าง `hr_appraisal` **10 ใบ** เท่าจำนวนพนักงาน แล้วเขียน `generated_count` = 10 กลับเอง |

## ⚠️ ข้อควรระวังตอนนำเสนอ

1. **ตัวเลขภาษีหัก ณ ที่จ่ายในสลิปเป็นตัวอย่าง ไม่ได้คำนวณจริง** — เครื่องคำนวณเงินเดือน (WF-HR-07/WF-HR-09) ยังไม่ได้สร้าง · เขียนกำกับไว้ในช่องหมายเหตุของสลิปทุกใบแล้ว · ประกันสังคมใช้กฎจริง (เพดานฐาน 15,000 × 5% = 750)
2. **`TEST-EMP1` / `TEST-EMP2` ยังอยู่ในทะเบียนพนักงาน** — เป็น fixture ที่การทดสอบ workflow ใช้อยู่ (ผูกบัญชีผู้ใช้จริงไว้) · ถ้าไม่อยากให้ขึ้นบนจอตอนนำเสนอ ให้ทำ view กรองออก **อย่าลบ**
3. **`emp_user` ของพนักงานสมมติทั้ง 8 คนว่าง** — ยังไม่มีบัญชีผู้ใช้จริงให้ผูก (ติด P0-2) ⇒ สาธิตการกดอนุมัติในหน้าจอผู้ใช้จริงยังทำไม่ได้ แสดงได้แค่ข้อมูลและสถานะ
4. **เลขบัตรประชาชนทั้งหมดเป็นเลขสมมติ** (ขึ้นต้น 11008/11009) ไม่ใช่เลขจริงของใคร

## วิธีลบทั้งชุด

`rowId` ทุกแถวอยู่ในไฟล์ `manifest.json` ที่แนบมาคู่กัน (หรือรายการท้ายเอกสารนี้) · ลบด้วย `delete_record` ตามลำดับย้อนกลับ:

```
hr_payslip_line → hr_payslip → hr_pay_period
hr_appraisal_item → hr_appraisal → hr_appraisal_cycle
hr_interview → hr_candidate → hr_job_requisition
hr_welfare_balance → hr_welfare_scheme
hr_attendance → hr_ot_request
hr_leave_ledger → hr_leave_request → hr_leave_balance
hr_salary_structure → hr_employment_contract → hr_employee
```

> 🔴 ลบจากปลายทางก่อนเสมอ — ตารางแม่มี relation ผูกอยู่

## รายการ rowId ทั้งหมด
```json
{
 "hr_employee": [
  {
   "rowId": "1e544d5f-f205-44cb-a3bb-1120c64e31bb",
   "note": "EMP-0001 ธนกฤต วงศ์อนันต์"
  },
  {
   "rowId": "f83b4962-2dcc-40a6-ae44-926c5c97ebfc",
   "note": "EMP-0002 ศิริพร ตั้งจิตต์"
  },
  {
   "rowId": "1602a32a-96b6-4fe3-a489-d7e9ef4f63c3",
   "note": "EMP-0003 ณัฐพงษ์ ศรีสมบูรณ์"
  },
  {
   "rowId": "9e44ffde-870c-4f79-a266-5f3eb41c81a9",
   "note": "EMP-0004 กมลชนก พูนสวัสดิ์"
  },
  {
   "rowId": "55282532-2be8-4526-93fc-7de7539936de",
   "note": "EMP-0005 วรเทพ อินทรสุวรรณ"
  },
  {
   "rowId": "40ba7b9b-cb47-405f-8189-a6a673aaf7c2",
   "note": "EMP-0006 ปิยะนุช แก้วประเสริฐ"
  },
  {
   "rowId": "eea6cc12-89c1-491e-9edc-ea3408cd9bd2",
   "note": "EMP-0007 อธิวัฒน์ บุญมาก"
  },
  {
   "rowId": "c8e387eb-dba9-431a-bd9f-3de07991ff93",
   "note": "EMP-0008 จันทร์เพ็ญ สายทอง"
  }
 ],
 "hr_employment_contract": [
  {
   "rowId": "f6d88f85-31ae-4050-a7b5-04b15f038a9a",
   "note": "CT-2569-001 · EMP-0001"
  },
  {
   "rowId": "c4b2acc7-ce41-4d93-80b7-30a2342e34dd",
   "note": "CT-2569-002 · EMP-0002"
  },
  {
   "rowId": "743d6d0d-da04-4534-9453-bdc559f194c8",
   "note": "CT-2569-003 · EMP-0003"
  },
  {
   "rowId": "a538ab48-1c1f-471b-af99-c59cf0ba9613",
   "note": "CT-2569-004 · EMP-0004"
  },
  {
   "rowId": "e03d4c49-d38e-4434-9ce3-838100185af2",
   "note": "CT-2569-005 · EMP-0005"
  },
  {
   "rowId": "5bb81912-22e8-4d68-865f-51a67eed9d4d",
   "note": "CT-2569-006 · EMP-0006"
  },
  {
   "rowId": "228915d0-1590-4338-8a5f-971be1d8a85b",
   "note": "CT-2569-007 · EMP-0007"
  },
  {
   "rowId": "250823dd-317d-4785-be42-1dbf7b3702b7",
   "note": "CT-2569-008 · EMP-0008"
  }
 ],
 "hr_salary_structure": [
  {
   "rowId": "8c7b170b-70bb-4d24-9fb5-d0386f38befe",
   "note": "โครงสร้างเงินเดือน EMP-0001"
  },
  {
   "rowId": "1b8f29a0-b8bf-467c-adc9-9fb0c947831e",
   "note": "โครงสร้างเงินเดือน EMP-0002"
  },
  {
   "rowId": "438103f8-75bc-4f00-a0b5-45052e6d5dd5",
   "note": "โครงสร้างเงินเดือน EMP-0003"
  },
  {
   "rowId": "c5b61942-c35f-4f35-8fb3-53c5f20d20b8",
   "note": "โครงสร้างเงินเดือน EMP-0004"
  },
  {
   "rowId": "d8da42c4-07ca-4ccf-9d8f-235c7d0f0c3e",
   "note": "โครงสร้างเงินเดือน EMP-0005"
  },
  {
   "rowId": "2bbc2fad-b817-41a3-a9cf-282031b3dd41",
   "note": "โครงสร้างเงินเดือน EMP-0006"
  },
  {
   "rowId": "0cd947be-540b-4b9b-9d56-cd500cb9ff65",
   "note": "โครงสร้างเงินเดือน EMP-0007"
  },
  {
   "rowId": "7754fbb3-3665-40d2-957c-2d3e6dd10731",
   "note": "โครงสร้างเงินเดือน EMP-0008"
  }
 ],
 "hr_leave_balance": [
  {
   "rowId": "8c0781be-eff0-44c8-892e-6047abaf7c87",
   "note": "EMP-0001 ลาพักร้อน 2026"
  },
  {
   "rowId": "8dfb055f-44ef-4840-b04d-f12320f84c9d",
   "note": "EMP-0001 ลาป่วย 2026"
  },
  {
   "rowId": "cb1795cc-c4c8-4108-b8c2-b118f4ba9a5e",
   "note": "EMP-0001 ลากิจ 2026"
  },
  {
   "rowId": "9cbd34b2-beeb-40e9-89f7-e9ff630cc500",
   "note": "EMP-0002 ลาพักร้อน 2026"
  },
  {
   "rowId": "482c9cfd-a862-4d10-84c1-20d43eabba94",
   "note": "EMP-0002 ลาป่วย 2026"
  },
  {
   "rowId": "23bc1526-05b6-4a5d-8691-5a17ad872542",
   "note": "EMP-0002 ลากิจ 2026"
  },
  {
   "rowId": "74532b8f-17a0-4a8d-b076-4a03706af551",
   "note": "EMP-0003 ลาพักร้อน 2026"
  },
  {
   "rowId": "addc036b-73b9-45be-b46e-f592e1e17de5",
   "note": "EMP-0003 ลาป่วย 2026"
  },
  {
   "rowId": "c97bd299-afa0-4bd7-a669-9a25e65b3bb4",
   "note": "EMP-0003 ลากิจ 2026"
  },
  {
   "rowId": "cda30df2-ae03-4b07-8187-2531280d9e00",
   "note": "EMP-0004 ลาพักร้อน 2026"
  },
  {
   "rowId": "ca8b5cc4-3dba-49ba-be4a-2abcd501c2cf",
   "note": "EMP-0004 ลาป่วย 2026"
  },
  {
   "rowId": "641ed2ce-27c5-445f-8c85-32b4d7581709",
   "note": "EMP-0004 ลากิจ 2026"
  },
  {
   "rowId": "8770bafb-d272-46f2-aba4-21d27eef7095",
   "note": "EMP-0005 ลาพักร้อน 2026"
  },
  {
   "rowId": "bdee250f-942f-45a5-a76d-ff800997cd81",
   "note": "EMP-0005 ลาป่วย 2026"
  },
  {
   "rowId": "ed97cf5d-69f1-4259-9481-93857d6a348f",
   "note": "EMP-0005 ลากิจ 2026"
  },
  {
   "rowId": "ffda2e41-eab0-4da2-b849-ccb83a0bdb43",
   "note": "EMP-0006 ลาพักร้อน 2026"
  },
  {
   "rowId": "78ddeac1-a2ce-4e8a-807b-8a76227ffea9",
   "note": "EMP-0006 ลาป่วย 2026"
  },
  {
   "rowId": "4e9b7e92-2c9b-4224-96d9-ab2e90d44b6b",
   "note": "EMP-0006 ลากิจ 2026"
  },
  {
   "rowId": "8c5cdc34-af19-49a6-88f6-231bdf944b5f",
   "note": "EMP-0007 ลาพักร้อน 2026"
  },
  {
   "rowId": "6c2e0b5d-7cb6-4373-b7ab-9521a0357df7",
   "note": "EMP-0007 ลาป่วย 2026"
  },
  {
   "rowId": "04552d8a-a9e5-46a6-8d90-d154f6dc197c",
   "note": "EMP-0007 ลากิจ 2026"
  },
  {
   "rowId": "3346dcb9-4dda-4e8b-9569-99395ec7d018",
   "note": "EMP-0008 ลาพักร้อน 2026"
  },
  {
   "rowId": "9636f64b-c7e2-49a2-bcc1-fd2e13badfad",
   "note": "EMP-0008 ลาป่วย 2026"
  },
  {
   "rowId": "3479921a-70b0-4618-892f-870c38716032",
   "note": "EMP-0008 ลากิจ 2026"
  }
 ],
 "hr_leave_ledger": [
  {
   "rowId": "3da763b2-720a-4e02-8e48-fc6fb93e572a",
   "note": "grant EMP-0001 ANNUAL"
  },
  {
   "rowId": "af2010c2-efaf-4be1-8afe-cc6ecae81b07",
   "note": "carry EMP-0001 ANNUAL"
  },
  {
   "rowId": "6a0b356b-ef04-4a4d-ba67-c2b02f49daf3",
   "note": "grant EMP-0001 SICK"
  },
  {
   "rowId": "f169fd51-92b4-42d0-ad8b-c1a57afba8b2",
   "note": "grant EMP-0001 PERSONAL"
  },
  {
   "rowId": "8e969db9-4101-4aef-9dff-f22668243172",
   "note": "grant EMP-0002 ANNUAL"
  },
  {
   "rowId": "422d51d9-1542-4f95-8a14-543a233c5427",
   "note": "carry EMP-0002 ANNUAL"
  },
  {
   "rowId": "0ff99f0b-0986-44eb-beb2-bb76630eb168",
   "note": "grant EMP-0002 SICK"
  },
  {
   "rowId": "5c8d1169-bf69-4e16-9bed-86d225250de4",
   "note": "grant EMP-0002 PERSONAL"
  },
  {
   "rowId": "f1fa15c1-14ed-4464-94f4-803f16c59c80",
   "note": "grant EMP-0003 ANNUAL"
  },
  {
   "rowId": "4046012d-e6ca-45da-aebc-4fc8bea75530",
   "note": "carry EMP-0003 ANNUAL"
  },
  {
   "rowId": "1c8caf11-4aa4-411d-a157-c1a7ea3ef98b",
   "note": "grant EMP-0003 SICK"
  },
  {
   "rowId": "f4c89e71-f643-478c-a756-b50ba4ca4c2e",
   "note": "grant EMP-0003 PERSONAL"
  },
  {
   "rowId": "ba973cd5-1086-42ac-a1fe-c826a377ec06",
   "note": "grant EMP-0004 ANNUAL"
  },
  {
   "rowId": "4fc530a0-4c2d-4189-8e8c-f966e8368096",
   "note": "carry EMP-0004 ANNUAL"
  },
  {
   "rowId": "7c9902f1-343f-42e3-8c1c-ce7891cff261",
   "note": "grant EMP-0004 SICK"
  },
  {
   "rowId": "075fd8e4-8da8-4d1f-9758-425b0869db7c",
   "note": "grant EMP-0004 PERSONAL"
  },
  {
   "rowId": "90d685c1-7a9f-4d93-bc04-b5c5064b4bc6",
   "note": "grant EMP-0005 ANNUAL"
  },
  {
   "rowId": "dfd6c937-7aa6-4c9b-b553-e1983f1e948b",
   "note": "carry EMP-0005 ANNUAL"
  },
  {
   "rowId": "aafc9da6-1d32-4e7e-8e71-c804ea5d3d0e",
   "note": "grant EMP-0005 SICK"
  },
  {
   "rowId": "fd0df08e-999e-4fec-9f13-5f49bcedb849",
   "note": "grant EMP-0005 PERSONAL"
  },
  {
   "rowId": "4463aa3d-3230-42c2-acc1-6271ff07f5f5",
   "note": "grant EMP-0006 ANNUAL"
  },
  {
   "rowId": "1488a92d-4499-486e-8cd9-6c832a8f593b",
   "note": "carry EMP-0006 ANNUAL"
  },
  {
   "rowId": "58f37771-c5c9-4cbc-940a-887998e460d4",
   "note": "grant EMP-0006 SICK"
  },
  {
   "rowId": "85443577-5991-4ebe-afb7-c0297270ae65",
   "note": "grant EMP-0006 PERSONAL"
  },
  {
   "rowId": "f33d1fd9-a641-4652-ba20-70f3732dd6ef",
   "note": "grant EMP-0007 ANNUAL"
  },
  {
   "rowId": "54ac9ff5-a2fe-42bd-a366-223ac0b0c266",
   "note": "grant EMP-0007 SICK"
  },
  {
   "rowId": "4fccf1d9-9798-42f8-a25a-aa1229c2225f",
   "note": "grant EMP-0007 PERSONAL"
  },
  {
   "rowId": "496765ce-28c9-4fb9-8d98-1feebd14453d",
   "note": "grant EMP-0008 ANNUAL"
  },
  {
   "rowId": "c8bc2004-1033-4c7f-989f-30dc311e5fab",
   "note": "grant EMP-0008 SICK"
  },
  {
   "rowId": "89147f66-8324-42ca-873c-445cf106b137",
   "note": "grant EMP-0008 PERSONAL"
  },
  {
   "rowId": "878f181d-09c0-4c45-9369-4c4fbafbad4e",
   "note": "LV-2569-0003 (WF-HR-02 สร้างเอง)"
  },
  {
   "rowId": "8402bc1e-2f50-4fb2-ae89-0797871b3a04",
   "note": "LV-2569-0002 (WF-HR-02 สร้างเอง)"
  },
  {
   "rowId": "2bcc5db1-8d44-40aa-97fd-cdf18b1237f1",
   "note": "LV-2569-0001 (WF-HR-02 สร้างเอง)"
  }
 ],
 "hr_leave_request": [
  {
   "rowId": "27d37236-1b2e-45b6-b3b4-d7f980cdba59",
   "note": "LV-2569-0001 EMP-0004 ANNUAL Draft"
  },
  {
   "rowId": "da53de11-4cbe-477d-b9cb-b00547fac7b2",
   "note": "LV-2569-0002 EMP-0005 SICK Draft"
  },
  {
   "rowId": "bf016716-2d35-4661-9b1f-d7a2316b4c85",
   "note": "LV-2569-0003 EMP-0007 PERSONAL Draft"
  },
  {
   "rowId": "f020f609-1b74-4e55-8df8-4514ae14e0d2",
   "note": "LV-2569-0004 EMP-0006 ANNUAL Pending supervisor"
  },
  {
   "rowId": "8e7949b8-d6e7-47b3-af76-46487bcd15ac",
   "note": "LV-2569-0005 EMP-0008 SICK Pending supervisor"
  },
  {
   "rowId": "7d6bc2da-1cfb-4fdd-a946-be77c82b6d90",
   "note": "LV-2569-0006 EMP-0003 ANNUAL Pending HR"
  },
  {
   "rowId": "a3d28850-1c1d-48b2-9f15-6a3b03d38760",
   "note": "LV-2569-0007 EMP-0002 PERSONAL Draft"
  },
  {
   "rowId": "9af59f7e-8523-4e98-8808-7fe278675824",
   "note": "LV-2569-0008 EMP-0005 ANNUAL Draft"
  },
  {
   "rowId": "ddac8f37-4a40-49b0-b725-9c89f77cc7d7",
   "note": "LV-2569-0009 EMP-0007 ANNUAL Rejected"
  },
  {
   "rowId": "00a57478-4ccb-46f5-8cf1-17cc17dc9ab5",
   "note": "LV-2569-0010 EMP-0004 PERSONAL Cancelled"
  }
 ],
 "hr_attendance": [
  {
   "rowId": "8d8a65b3-0d82-4670-b524-1060cb937585",
   "note": "ATT 2026-08-24 EMP-0001"
  },
  {
   "rowId": "45e9573c-d263-4c07-a2bc-31acbb63eebc",
   "note": "ATT 2026-08-24 EMP-0002"
  },
  {
   "rowId": "3ae8399c-6b20-4e78-b66b-f5eea66f8431",
   "note": "ATT 2026-08-24 EMP-0003"
  },
  {
   "rowId": "a4b111e7-7fc1-4ecb-922f-67922a4f96f5",
   "note": "ATT 2026-08-24 EMP-0004"
  },
  {
   "rowId": "9e8d6ff3-462e-4d77-b32a-4a86a9715536",
   "note": "ATT 2026-08-24 EMP-0005"
  },
  {
   "rowId": "aa078ec0-0924-43f4-bd37-9a7f2e3f34cd",
   "note": "ATT 2026-08-24 EMP-0006"
  },
  {
   "rowId": "21ae088d-dadb-4098-a68d-93dca2f005fa",
   "note": "ATT 2026-08-24 EMP-0007"
  },
  {
   "rowId": "80a35d61-07f4-47e2-843e-6cff9213bac2",
   "note": "ATT 2026-08-24 EMP-0008"
  },
  {
   "rowId": "814e3dc3-05b1-4ac8-a704-639ca27ff53b",
   "note": "ATT 2026-08-25 EMP-0001"
  },
  {
   "rowId": "4807eb92-98d1-421a-9f51-fe068afaf467",
   "note": "ATT 2026-08-25 EMP-0002"
  },
  {
   "rowId": "8678bfb4-8d1d-4586-91bf-226aeb7f63fa",
   "note": "ATT 2026-08-25 EMP-0003"
  },
  {
   "rowId": "b7d3cb1c-bd80-46c1-9b2a-fe9a35a1aed4",
   "note": "ATT 2026-08-25 EMP-0004"
  },
  {
   "rowId": "185f60a7-8cb8-41be-9ee0-4b4686f8ba1f",
   "note": "ATT 2026-08-25 EMP-0005"
  },
  {
   "rowId": "79852e01-353c-410d-8b2a-727f35aaf66a",
   "note": "ATT 2026-08-25 EMP-0006"
  },
  {
   "rowId": "b443a376-0fa5-4994-818c-ee9bb17f700b",
   "note": "ATT 2026-08-25 EMP-0007"
  },
  {
   "rowId": "17f01d45-2af5-4e04-8fc2-ad3f4b7c31cd",
   "note": "ATT 2026-08-25 EMP-0008"
  },
  {
   "rowId": "60855d42-8188-48fd-a408-3889ae9ff3b1",
   "note": "ATT 2026-08-26 EMP-0001"
  },
  {
   "rowId": "11a27464-31f7-4be6-8266-67238069053c",
   "note": "ATT 2026-08-26 EMP-0002"
  },
  {
   "rowId": "7e8789e5-74a4-44f2-98a0-b7fcdeeaa28e",
   "note": "ATT 2026-08-26 EMP-0003"
  },
  {
   "rowId": "8fa50af8-c9c9-45c5-8cef-0e19dd3e9664",
   "note": "ATT 2026-08-26 EMP-0004"
  },
  {
   "rowId": "7df9c2c6-e798-482e-ace3-32d177821051",
   "note": "ATT 2026-08-26 EMP-0005"
  },
  {
   "rowId": "05c1ec3a-0284-48d7-b03a-992516b4cfa5",
   "note": "ATT 2026-08-26 EMP-0006"
  },
  {
   "rowId": "d748d7b5-9681-4146-99aa-7574c039db2d",
   "note": "ATT 2026-08-26 EMP-0007"
  },
  {
   "rowId": "1580d391-b217-43a0-95cf-05f44e4355cd",
   "note": "ATT 2026-08-26 EMP-0008"
  },
  {
   "rowId": "b19e5634-ce26-41e0-b4ef-fdabaf739726",
   "note": "ATT 2026-08-27 EMP-0001"
  },
  {
   "rowId": "ceb96b7c-c4fc-4d18-944f-e7ec96ed005d",
   "note": "ATT 2026-08-27 EMP-0002"
  },
  {
   "rowId": "370a40c0-ecf9-4cb0-8fd2-d10920a18d08",
   "note": "ATT 2026-08-27 EMP-0003"
  },
  {
   "rowId": "2c75a5ec-16ff-49f0-bb11-6c1e2fa76885",
   "note": "ATT 2026-08-27 EMP-0004"
  },
  {
   "rowId": "ce2cb062-e60c-4a56-b4d1-c3fca7541d88",
   "note": "ATT 2026-08-27 EMP-0005"
  },
  {
   "rowId": "6325670f-ec84-4feb-8938-a089848ff9bd",
   "note": "ATT 2026-08-27 EMP-0006"
  },
  {
   "rowId": "1b95dbe8-a399-4476-b6d7-68b04b5fb515",
   "note": "ATT 2026-08-27 EMP-0007"
  },
  {
   "rowId": "3900d22f-2ee2-4b1a-baf9-ad21b97df3f7",
   "note": "ATT 2026-08-27 EMP-0008"
  },
  {
   "rowId": "1b2f289a-a46e-496a-965a-b552170deabd",
   "note": "ATT 2026-08-28 EMP-0001"
  },
  {
   "rowId": "364cf581-52c1-4d58-af1d-e8508fe163ec",
   "note": "ATT 2026-08-28 EMP-0002"
  },
  {
   "rowId": "e10070e2-172a-4251-b2d0-2d6985c43043",
   "note": "ATT 2026-08-28 EMP-0003"
  },
  {
   "rowId": "1f518bc4-0ac7-48e2-ba4b-97a32dfae060",
   "note": "ATT 2026-08-28 EMP-0004"
  },
  {
   "rowId": "844c03c7-96c2-4503-9586-aff42a9ba701",
   "note": "ATT 2026-08-28 EMP-0005"
  },
  {
   "rowId": "44888846-e8cf-45f1-8f76-39e9b633f25b",
   "note": "ATT 2026-08-28 EMP-0006"
  },
  {
   "rowId": "f050cc5d-d0ef-4bba-9c15-554b1321b954",
   "note": "ATT 2026-08-28 EMP-0007"
  },
  {
   "rowId": "401f2a73-92b6-442a-ab63-8a7ef5e0c153",
   "note": "ATT 2026-08-28 EMP-0008"
  }
 ],
 "hr_ot_request": [
  {
   "rowId": "80af12ea-e4d4-48d6-a92e-f471aecf55c8",
   "note": "OT-2569-0001 EMP-0005 Approved"
  },
  {
   "rowId": "8f0f7e17-97fa-4415-a06c-7d0e97e10645",
   "note": "OT-2569-0002 EMP-0008 Approved"
  },
  {
   "rowId": "017c4863-ca7b-431e-b32c-d8e71dac17b3",
   "note": "OT-2569-0003 EMP-0007 Pending supervisor"
  },
  {
   "rowId": "b64e7fbf-5e12-4ba6-b910-b5e129cfc0b9",
   "note": "OT-2569-0004 EMP-0004 Pending HR"
  },
  {
   "rowId": "e42eb70c-26e7-45cb-b1a6-8ff0edc6965f",
   "note": "OT-2569-0005 EMP-0007 Rejected"
  }
 ],
 "hr_job_requisition": [
  {
   "rowId": "b286d5e7-dfd3-4500-80a8-c874f303efa1",
   "note": "JR-2569-001 Approved"
  },
  {
   "rowId": "10479d18-31ae-4025-aad7-9e960170c25e",
   "note": "JR-2569-002 Pending HR"
  }
 ],
 "hr_candidate": [
  {
   "rowId": "b57bf408-34b7-4ee1-b601-3a59fbd89d06",
   "note": "ก้องภพ ธนบดี Hired"
  },
  {
   "rowId": "c34e03d8-8426-4074-8f6c-13a3418e0454",
   "note": "รวิสรา นิลจันทร์ Interview 2"
  },
  {
   "rowId": "cb18656c-d5f2-47f6-b610-d70dd35656ed",
   "note": "ธีรภัทร ชัยมงคล Interview 1"
  },
  {
   "rowId": "dab6e80e-36e4-4415-b5a1-ae2abe9602ac",
   "note": "อารียา พงศ์ไพบูลย์ Screening"
  },
  {
   "rowId": "0d6d9e33-3144-4506-95e4-59de56d28223",
   "note": "นพดล เรืองศรี Applied"
  },
  {
   "rowId": "f13d68fd-3935-4857-a9ce-4f69d021bf20",
   "note": "สุชานาถ วิริยะกุล Rejected"
  }
 ],
 "hr_interview": [
  {
   "rowId": "01fb9e11-8fab-45a9-977c-d4df812a6538",
   "note": "สัมภาษณ์รอบ 1 · ก้องภพ"
  },
  {
   "rowId": "0f6e8f2c-a281-4d8e-a145-f5cf6e27167f",
   "note": "สัมภาษณ์รอบ 2 · ก้องภพ"
  },
  {
   "rowId": "9b3b914e-7dcf-47df-aac9-f0aca5beb1c0",
   "note": "สัมภาษณ์รอบ 1 · รวิสรา"
  },
  {
   "rowId": "65d3be2f-d21f-4a02-9ac0-f79a451e4730",
   "note": "สัมภาษณ์รอบ 2 · รวิสรา"
  },
  {
   "rowId": "4ed80c85-881e-4de1-93d0-f0649dd6e4e3",
   "note": "สัมภาษณ์รอบ 1 · ธีรภัทร"
  },
  {
   "rowId": "14cb9e6b-7e0e-452f-bb31-f5b92c889b9a",
   "note": "สัมภาษณ์รอบ 1 · สุชานาถ"
  }
 ],
 "hr_appraisal_cycle": [
  {
   "rowId": "51a1e7f2-3f63-4c8c-bbff-6e09479a3850",
   "note": "รอบประเมิน ครึ่งปีแรก 2569"
  }
 ],
 "hr_appraisal_item": [
  {
   "rowId": "6febebba-c991-4e2b-b8dc-39a2692a1d82",
   "note": "item EMP-0002 KPI ยอดขายตามเป้าหมาย"
  },
  {
   "rowId": "376bff31-ca85-43cb-a4fc-f02205c61d57",
   "note": "item EMP-0002 KPI ความตรงเวลาของงานที่รับผิดชอบ"
  },
  {
   "rowId": "35032e6a-bdf2-4eee-b5ed-447ea926e33d",
   "note": "item EMP-0002 การทำงานเป็นทีม"
  },
  {
   "rowId": "b138cb11-0de5-4ada-a359-e0f54287d413",
   "note": "item EMP-0002 การตรงต่อเวลา"
  },
  {
   "rowId": "30c2bf2c-b24f-4d2f-8070-0d9da6728e21",
   "note": "item EMP-0003 KPI ยอดขายตามเป้าหมาย"
  },
  {
   "rowId": "59510451-488e-4e46-9957-b0fcbfbfbd8d",
   "note": "item EMP-0003 KPI ความตรงเวลาของงานที่รับผิดชอบ"
  },
  {
   "rowId": "c635bb87-5b83-4385-9454-cbd1da1bb401",
   "note": "item EMP-0003 การทำงานเป็นทีม"
  },
  {
   "rowId": "8a104c65-03f5-4b97-8b13-5a8c883e09b7",
   "note": "item EMP-0003 การตรงต่อเวลา"
  },
  {
   "rowId": "20e89666-efa5-42c2-8816-fa5e8635ba56",
   "note": "item EMP-0006 KPI ยอดขายตามเป้าหมาย"
  },
  {
   "rowId": "893c7f41-1eb0-4c3e-a276-46df3106ad3e",
   "note": "item EMP-0006 KPI ความตรงเวลาของงานที่รับผิดชอบ"
  },
  {
   "rowId": "651d9ec2-91ad-4b73-8410-c61a81f0b481",
   "note": "item EMP-0006 การทำงานเป็นทีม"
  },
  {
   "rowId": "0eb81f7f-4087-4e43-9187-baf82127c3c1",
   "note": "item EMP-0006 การตรงต่อเวลา"
  }
 ],
 "hr_pay_period": [
  {
   "rowId": "b4df452d-f8e3-4b7f-8de9-874bd7973702",
   "note": "งวดเงินเดือน ส.ค. 2569"
  }
 ],
 "hr_payslip": [
  {
   "rowId": "89b016b4-3566-4bbb-8e0d-26ea02a47446",
   "note": "สลิป ส.ค.2569 EMP-0001"
  },
  {
   "rowId": "46ca6d23-844d-4ed8-894b-e8c297e54bc8",
   "note": "สลิป ส.ค.2569 EMP-0002"
  },
  {
   "rowId": "0c6a0229-f1b7-4e18-9b19-dcc066483d3d",
   "note": "สลิป ส.ค.2569 EMP-0003"
  },
  {
   "rowId": "50829b68-6114-49a3-b4f3-c3f0be169d26",
   "note": "สลิป ส.ค.2569 EMP-0004"
  },
  {
   "rowId": "a55d7ae4-b553-42f9-8844-e1ab73cff294",
   "note": "สลิป ส.ค.2569 EMP-0005"
  },
  {
   "rowId": "0d957050-8d9e-498f-b92c-5041ec707871",
   "note": "สลิป ส.ค.2569 EMP-0006"
  },
  {
   "rowId": "967b97ec-05dd-452f-8397-2392f37410b7",
   "note": "สลิป ส.ค.2569 EMP-0007"
  },
  {
   "rowId": "a8e08eb7-9c0f-4838-a671-f522f464df98",
   "note": "สลิป ส.ค.2569 EMP-0008"
  }
 ],
 "hr_payslip_line": [
  {
   "rowId": "303aa53d-8072-4ee5-8677-8a39637c5641",
   "note": "line salary EMP-0001"
  },
  {
   "rowId": "90f6c1e5-f6c4-43ee-9070-e39b478634ac",
   "note": "line sso EMP-0001"
  },
  {
   "rowId": "10c5b94a-4bee-463a-9db6-a20de5a9c49f",
   "note": "line wht EMP-0001"
  },
  {
   "rowId": "09e83382-dcec-479d-b2d3-be536f31f7e4",
   "note": "line salary EMP-0002"
  },
  {
   "rowId": "68c894a4-ec5d-40a1-815e-2a20fa2df1af",
   "note": "line sso EMP-0002"
  },
  {
   "rowId": "809af336-f9b3-43e5-af41-2d226559b173",
   "note": "line wht EMP-0002"
  },
  {
   "rowId": "3d64fc88-f6f1-4858-bc6d-9fe0f70f8970",
   "note": "line salary EMP-0003"
  },
  {
   "rowId": "d6e0ab3d-7b73-49a2-b621-3a40e9f6685a",
   "note": "line sso EMP-0003"
  },
  {
   "rowId": "e08f5e8d-fa6f-4447-af11-abaf3dd65cf8",
   "note": "line wht EMP-0003"
  },
  {
   "rowId": "ff7758fa-2b8e-42c0-8135-538bce3c4030",
   "note": "line salary EMP-0004"
  },
  {
   "rowId": "88f8a57b-a360-4488-a8fd-2cd028e42917",
   "note": "line sso EMP-0004"
  },
  {
   "rowId": "3a247e59-9679-47c5-8d19-2baa2d93489b",
   "note": "line salary EMP-0005"
  },
  {
   "rowId": "0242de53-78c4-433d-98e7-1535931d1df9",
   "note": "line ot EMP-0005"
  },
  {
   "rowId": "b3ca944e-5cee-4c05-acb5-0bd05c5e9c74",
   "note": "line absent EMP-0005"
  },
  {
   "rowId": "4e9854a5-a818-43d3-9604-39fb09a057a7",
   "note": "line sso EMP-0005"
  },
  {
   "rowId": "caf97833-b5c3-4939-a2a7-483f2957bcef",
   "note": "line salary EMP-0006"
  },
  {
   "rowId": "96c519c8-6ec9-47a1-b71c-bc6866a4d6bc",
   "note": "line sso EMP-0006"
  },
  {
   "rowId": "03a0d803-e608-4833-a5cf-4d83d6182eee",
   "note": "line wht EMP-0006"
  },
  {
   "rowId": "7db059d8-1c6d-4653-8642-f159d1ce1e49",
   "note": "line salary EMP-0007"
  },
  {
   "rowId": "ec9f58b0-78e9-4680-aca5-63feed53905b",
   "note": "line sso EMP-0007"
  },
  {
   "rowId": "64ba8205-677d-4d1c-9e0d-24278c2ad5b2",
   "note": "line salary EMP-0008"
  },
  {
   "rowId": "4ab039de-c7a9-4217-8abd-6c89a44a2710",
   "note": "line ot EMP-0008"
  },
  {
   "rowId": "36aa7274-6bfe-4859-af40-c952f78231c5",
   "note": "line sso EMP-0008"
  }
 ],
 "hr_welfare_scheme": [
  {
   "rowId": "f543a697-5022-402d-8948-9fdcaf848faf",
   "note": "WF-MED ค่ารักษาพยาบาล (ผู้ป่วยนอก)"
  },
  {
   "rowId": "ce0a240a-3992-44d3-89d4-4f7cd1819337",
   "note": "WF-DENTAL ค่าทันตกรรม"
  },
  {
   "rowId": "c168e69e-9db7-4a78-8d03-7cb64557697d",
   "note": "WF-EDU ทุนการศึกษาบุตร"
  },
  {
   "rowId": "42e79ada-dad4-4502-b1ca-cdcec8d6c4f8",
   "note": "WF-GLASS ค่าตัดแว่นสายตา"
  },
  {
   "rowId": "d8a049ab-4ebe-40d7-ba47-296fc78a3671",
   "note": "WF-EXEC ตรวจสุขภาพประจำปี (ระดับบริหาร)"
  }
 ],
 "hr_welfare_balance": [
  {
   "rowId": "47edc727-c419-424e-ac07-423eb54e3c50",
   "note": "วงเงิน EMP-0001 WF-MED"
  },
  {
   "rowId": "6612e6ca-50d4-458c-b786-e8e399c5c48e",
   "note": "วงเงิน EMP-0001 WF-EXEC"
  },
  {
   "rowId": "3dd65c5a-9976-4119-9e4d-e2d19ee3a60f",
   "note": "วงเงิน EMP-0002 WF-MED"
  },
  {
   "rowId": "0b35150d-c6ea-42ed-b9e4-115e7836fce4",
   "note": "วงเงิน EMP-0002 WF-DENTAL"
  },
  {
   "rowId": "6df1b7dd-c7e6-45fb-9d5a-18f92e7543ae",
   "note": "วงเงิน EMP-0003 WF-MED"
  },
  {
   "rowId": "8dfef66f-e2b6-4102-8398-d64c9c18c8d5",
   "note": "วงเงิน EMP-0003 WF-EDU"
  },
  {
   "rowId": "f11fd5b7-3781-4bef-80df-2a1842cf2fcc",
   "note": "วงเงิน EMP-0003 WF-EXEC"
  },
  {
   "rowId": "7f3a86e3-179f-4f26-aee6-30fe9d3c0e48",
   "note": "วงเงิน EMP-0004 WF-MED"
  },
  {
   "rowId": "0fd62c1d-acb3-4a30-a3b0-55750b3f810a",
   "note": "วงเงิน EMP-0005 WF-MED"
  },
  {
   "rowId": "5d0abc01-b08c-4d74-97f3-9c56d96f7679",
   "note": "วงเงิน EMP-0005 WF-GLASS"
  },
  {
   "rowId": "c9e43a65-9dd2-4ab2-9af0-54abdc103671",
   "note": "วงเงิน EMP-0006 WF-MED"
  },
  {
   "rowId": "58d6a113-dd8e-4bbe-a5ac-15747c50cc1f",
   "note": "วงเงิน EMP-0006 WF-DENTAL"
  },
  {
   "rowId": "10a37ccb-58df-42dc-a947-4fb68e72e8af",
   "note": "วงเงิน EMP-0007 WF-MED"
  },
  {
   "rowId": "ce664345-0fdf-4148-8a9f-eeeb3d03b1c0",
   "note": "วงเงิน EMP-0008 WF-MED"
  }
 ],
 "hr_appraisal": [
  {
   "rowId": "5f03b725-72dd-4e08-8a96-5a3ded9e40b5",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — ธนกฤต วงศ์อนันต์ (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "3be87210-f11b-4bdf-aa6c-87361fc9f93c",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — ทดสอบ หัวหน้างาน (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "2dea4112-1a69-4d3c-9f4a-ab6992b21f18",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — ทดสอบ พนักงาน (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "d17b6d2d-548e-4c30-8ce8-2c6da1c56cac",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — ศิริพร ตั้งจิตต์ (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "0b2e34a8-cb70-4815-aa65-46d55e796c0a",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — ณัฐพงษ์ ศรีสมบูรณ์ (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "a22a4078-ef11-4b36-94e7-dee5207f3142",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — จันทร์เพ็ญ สายทอง (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "b50058f7-b1a1-442c-a5a5-e0b7bc77ff1d",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — วรเทพ อินทรสุวรรณ (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "136b4407-96b1-454a-9524-bad6be6db9c9",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — อธิวัฒน์ บุญมาก (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "423a115e-db0f-45fd-9dc3-d9d893be01b9",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — ปิยะนุช แก้วประเสริฐ (WF-HR-18 สร้างเอง)"
  },
  {
   "rowId": "c5fbb4d9-339a-4f8b-b581-eeaa8bb5ac53",
   "note": "รอบประเมินผลงาน ครึ่งปีแรก 2569 — กมลชนก พูนสวัสดิ์ (WF-HR-18 สร้างเอง)"
  }
 ]
}
```

---

## 🆕 รอบเติมชีทที่ยังว่าง (HR/SEED-EMPTY — 6 ก.ย. 2569)

สำรวจทั้งแอป 98 ตาราง พบว่าง 6 ตาราง (ทั้งหมดเป็นฝั่ง HR) — **เติมแล้ว 5 · เหลือ 1 ที่เติมไม่ได้**

| ตาราง | worksheetId | เดิม | ตอนนี้ |
|---|---|---|---|
| เหตุการณ์การจ้าง `hr_employment_event` | `6a8efd1e8b6633ef76f12ad4` | 0 | **20** |
| ผู้ติดตามและผู้ใช้สิทธิลดหย่อน `hr_dependent` | `6a8efd1eae2a0e3743a0bd93` | 0 | **9** |
| บัญชีธนาคารพนักงาน `hr_bank_account` | `6a8efd1fae2a0e3743a0bd9d` | 0 | **8** |
| การยื่น ภ.ง.ด.1 `hr_pnd1_filing` | `6a904e72ae2a0e3743a0fd06` | 0 | **1** |
| หนังสือรับรองหักภาษี `hr_wht_cert` | `6a904e73353e1b0e4a50ba83` | 0 | **4** |
| กฎการอนุมัติของโมดูลบุคคล `hr_approval_rule` | `6a8eebf81378964f998499f8` | 0 | **0 — เติมไม่ได้** |

### ทำไม `hr_approval_rule` ยังว่าง

ฟิลด์ `hr_approver_role` (`6a8eec6e8b6633ef76f12a56`) เป็น **type 44 Role** ⇒ ต้องมี role ของแอปอยู่ก่อน · ตอนนี้ยังไม่มี role เลย (9 role ที่เคยสร้างถูกลบทิ้งเพราะ `worksheetPermissions` ตั้งผ่าน API ไม่ติด — ดู `05-Roadmap-Tracker.md` P8-1) · **และ** ระดับการอนุมัติ/เกณฑ์วงเงินเป็นนโยบายที่ต้องให้คนกำหนด ⇒ รอ **P0-2 + P8-1** ก่อนจึงจะ seed ได้อย่างมีความหมาย

### 1. เหตุการณ์การจ้าง — 20 แถว `EVT-0001` … `EVT-0020`

- **Hired 8 แถว** — วันที่มีผล = `hire_date` จริงของแต่ละคน
- **Confirmed 8 แถว** — วันที่มีผล = `confirm_date` จริงของแต่ละคน
- **Promoted 3 แถว** — EMP-0002 (HR01→HR02 · L3→L4 · 1 ม.ค. 2566) · EMP-0003 (ACC01→ACC02 · L3→L4 · 1 เม.ย. 2566) · EMP-0006 (SALE01→SALE02 · L2→L3 · 1 ม.ค. 2567)
- **Salary adjusted 2 แถว** — EMP-0004 · EMP-0005 (1 ม.ค. 2569)

⚠️ วันที่และตำแหน่งเดิมของการเลื่อนขั้น **เป็นเรื่องแต่งให้สอดคล้องกับตำแหน่งปัจจุบัน** ไม่ใช่ประวัติจริง — `hire_date`/`confirm_date` เท่านั้นที่ยึดจากทะเบียนพนักงาน

### 2. ผู้ติดตาม — 9 แถว

คู่สมรส 3 · บุตร 4 · บิดา/มารดา 2 · ผูกกับพนักงานที่สถานะสมรส = Married เป็นหลัก (EMP-0001 · EMP-0003 · EMP-0006) และเพิ่มบิดา/มารดาให้ EMP-0002 · EMP-0005 เพื่อให้มีเคสลดหย่อนบุพการี · เลขบัตรประชาชนใช้ชุดสมมติต่อเนื่องจากของพนักงาน (`11008000001xx`) **ไม่ใช่เลขจริง**

🟢 **ผูกใช้งานจริงแล้ว 1 จุด** — `CLM-2569-0002` (EMP-0003 ค่ารักษาพยาบาล) ตั้ง `ผู้ใช้สิทธิ` = **ภูริช ศรีสมบูรณ์ (บุตร)** ⇒ ฟิลด์ relation นี้ไม่ว่างเปล่าตอนสาธิตอีกต่อไป

### 3. บัญชีธนาคาร — 8 แถว

คนละ 1 บัญชี · ทุกบัญชีเป็น **บัญชีหลัก + ออมทรัพย์ + ใช้งานอยู่** · กระจาย 6 ธนาคาร · **เลขบัญชีเป็นเลขสมมติทั้งหมด** (รูปแบบ `0xx-x-456xx-x`)

### 4–5. เอกสารภาษี — 🔴 อ่านก่อนใช้

**ภ.ง.ด.1 เดือน ส.ค. 2569** `a844ebd3-23d1-4bf7-b10d-53fb95caff48` — ประเภทแบบ `P.N.D.1` · ปีภาษี 2026 · เดือน 8 · ผูกงวด `b4df452d-f8e3-4b7f-8de9-874bd7973702` · พนักงาน 8 คน · **รวมรายได้ 363,800** · **รวมภาษีหัก 13,650** · สถานะ **Draft**

**หนังสือรับรองหักภาษี 4 ใบ** — ออกเฉพาะคนที่มีภาษีถูกหัก ใช้ยอด **สะสมทั้งปี (YTD)** จากสลิป

| เลขที่ | พนักงาน | รวมรายได้ | รวมภาษีหัก |
|---|---|---|---|
| WHT-2569-001 | EMP-0001 | 960,000 | 68,000 |
| WHT-2569-002 | EMP-0002 | 440,000 | 16,800 |
| WHT-2569-003 | EMP-0003 | 464,000 | 19,200 |
| WHT-2569-004 | EMP-0006 | 304,000 | 5,200 |

🔴🔴 **ตัวเลขภาษีทั้งหมดนี้เป็นการ "รวมยอดจากสลิป demo" เท่านั้น — ไม่ได้คำนวณจากขั้นบันไดภาษีจริง**
สลิปชุดนั้นเขียนกำกับไว้เองอยู่แล้วว่าเลขภาษีเป็นตัวอย่าง (WF-HR-09 ยังไม่ได้สร้าง) ⇒ **ห้ามใช้เอกสาร 5 ใบนี้อ้างอิงทางภาษีเด็ดขาด** · เมื่อ P5-9/P5-10 คำนวณภาษีจริงแล้ว **ต้องลบทั้ง 5 ใบทิ้งแล้วให้ WF-HR-20 (P8-6) สร้างใหม่**
🔴 ยังไม่ผูก `หนังสือรับรอง` เข้ากับ `ภ.ง.ด.1` (`biz_pnd1_filing` เว้นว่าง) เพราะการยื่นเป็น **รายเดือน** แต่หนังสือรับรองเป็น **รายปี** — คนละขอบเขต ต้องให้ WF-HR-20 ตัดสินตอนสร้างจริง

### ลำดับการลบถ้าต้องถอนชุดนี้ออก

`hr_wht_cert` (4) → `hr_pnd1_filing` (1) → `hr_bank_account` (8) → ล้าง `ผู้ใช้สิทธิ` ของ `CLM-2569-0002` → `hr_dependent` (9) → `hr_employment_event` (20)
