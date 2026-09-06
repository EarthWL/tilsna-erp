# ID Registry — โมดูล HR (TILSNA ERP)

_แยกออกจาก `04-CLAUDE-memory.md` เมื่อ 30 ส.ค. 2569 (MIGRATION §C ขั้น ⑤) — **เนื้อหาเหมือนเดิมทุกตัวอักษร ไม่ได้ตัดอะไรทิ้ง**_

> ทำไมแยก: ส่วนนี้กิน 22% ของ memory ทั้งไฟล์ แต่ agent ต้องการมันเฉพาะตอนจะแตะ object จริง ไม่ใช่ทุก session ⇒ memory เก็บแค่ ID ระดับระบบ (App/Org/connector) ที่ต้องรู้ทุกครั้ง แล้วชี้มาที่ไฟล์นี้
> ต้นทางของความจริงเรื่อง **field** ยังเป็น `02-BuildSpec-FRS.md` §1 และ `02b-BuildSpec-Addendum-P3-1.md` เสมอ — ไฟล์นี้เป็น **ดัชนีรวม ws/view/workflow ID** ให้หาเร็ว ไม่ต้อง grep BuildSpec 276 KB

| รายการ | ค่า |
|---|---|
| App ID | `deca7391-1761-424b-9af3-c8d043004ad3` (**ERP - TILSNA**) |
| **MCP connector** | **`ERP_-_TILSNA`** |

---

### 🆕 ID ตารางใบลา (P3-1 — สร้าง 26 ส.ค. 2569 · รายละเอียดฟิลด์ครบใน `02b-BuildSpec-Addendum-P3-1.md`)

| ตาราง | ws ID | view "ทั้งหมด" |
|---|---|---|
| `hr_leave_request` (ใบลา) | `6a8f2dbaae2a0e3743a0beaa` | `6a8f2dbaae2a0e3743a0beae` |
| `hr_leave_balance` (สิทธิและยอดคงเหลือการลา) | `6a8f2dba353e1b0e4a507757` | `6a8f2dba353e1b0e4a50775b` |
| `hr_leave_ledger` (รายการเคลื่อนไหวสิทธิลา) | `6a8f2dba9762533b5b718675` | `6a8f2dba9762533b5b718679` |

**🆕 view ทั้ง 4 มุมมองของ `hr_leave_request` (P3-7 — สร้าง+ยืนยันแล้ว 27 ส.ค. 2569):**

| view | id |
|---|---|
| ใบลาของฉัน | `6a8fb8451378964f9984a0b5` |
| รออนุมัติ (หัวหน้างาน) | `6a8fb845ae2a0e3743a0c34f` |
| รออนุมัติ (HR) | `6a8fb8458b6633ef76f12f64` |
| ปฏิทินการลาของทีม | `6a8fb845353e1b0e4a507c38` |

⚠️ **ทั้ง 3 ตารางยังไม่มี:** unique index จริง (IX-08.1 — **ตัดสินใจไม่เปิดใช้ 27 ส.ค. 2569 ดูเหตุผลใน Known Issues** / IX-09.1) · DV-08.1 (**ทำผ่าน UI ไม่ได้ ต้องย้ายไป WF-HR-01 — ดู Known Issues**) · การผูก Dropdown (`leave_unit`/`leave_status`/`ledger_type`) เข้า shared optionset · ✅ seed `hr_leave_balance` ครบทั้ง 6 ประเภท×2 พนักงาน 27 ส.ค. 2569 (P3-4) · `hr_leave_request`/`hr_leave_ledger` ยังไม่ seed record ทดสอบเพิ่ม — ✅ **BR-08.1/8.4/8.5 สร้าง+ยืนยันผ่าน Role Debugging แล้ว 27 ส.ค. 2569** (✅ `addRecordButtonName` ตั้งเป็นไทยครบแล้วทั้ง 3 ตาราง 26 ส.ค. 2569)

### 🆕 ID ตารางลงเวลา/OT (P4-1/P4-2 — สร้าง 27 ส.ค. 2569 · field ตามสเปกเต็มใน `02-BuildSpec-FRS.md` FR-HR-10/FR-HR-11B)

| ตาราง | ws ID | view "ทั้งหมด" | Data Name ไทย |
|---|---|---|---|
| `hr_ot_request` (ใบขออนุมัติล่วงเวลา) | `6a8fcca48b6633ef76f13033` | `6a8fcca48b6633ef76f13037` | ✅ "ใบขออนุมัติล่วงเวลา" |
| `hr_attendance` (บันทึกลงเวลา) | `6a8fcd67353e1b0e4a507d32` | `6a8fcd67353e1b0e4a507d36` | ✅ "บันทึกลงเวลา" |

- **ลำดับสร้าง:** `hr_ot_request` ก่อน (ไม่มี dependency ขาเข้านอกจาก `hr_employee`) แล้วค่อย `hr_attendance` (ต้องอ้าง `hr_ot_request` สำหรับ field `ot_request`)
- **Relation ที่ผูกสำเร็จ:** `hr_ot_request.employee`→`hr_employee` (`6a8efa5e9762533b5b7185c1`) · `hr_attendance.employee`→`hr_employee` · `hr_attendance.shift`→`hr_shift` (`6a8eebf79762533b5b7184c5`) · `hr_attendance.leave_request`→`hr_leave_request` (`6a8f2dbaae2a0e3743a0beaa`) · `hr_attendance.ot_request`→`hr_ot_request` — ทั้งหมด `bidirectional:true` สร้าง reverse field อัตโนมัติ
- **Dropdown ที่สร้างเป็น inline options (label อังกฤษให้ตรงกับ optionset กลาง แต่ key/GUID คนละชุด — ยังไม่ bind จริง):** `hr_attendance.att_status` (Present/Late/Absent/On leave/Holiday/Weekly holiday/Half day ตรงกับ `OS_HR_ATT_STATUS`) · `hr_attendance.att_source` (Device import/Manual entry/Self check-in/System generated ตรงกับ `OS_HR_ATT_SOURCE`) · `hr_ot_request.day_type` (Working day/Holiday within hours/Holiday outside hours ตรงกับ `OS_HR_OT_DAY_TYPE` — **แก้จากภาษาไทยผิดพลาดครั้งแรกด้วย `editFields` แล้ว** ดู Known Issues) · `hr_ot_request.ot_status` (Draft/Pending supervisor/Pending HR/Approved/Rejected/Cancelled ตรงกับ `OS_HR_REQUEST_STATUS`)
- ⚠️ **ยังไม่มี:** unique index IX-10.1 (`employee`+`work_date` บน `hr_attendance`) / IX-11.1 (`employee`+`ot_date`+`ot_from` บน `hr_ot_request`) — Browser-only · Business Rules BR-10.1/10.2/11.1/11.2/11.3 · `hr_ot_request.pay_period` relation (รอ P5-1) · seed record ทดสอบ

### 🆕 ID ตารางเงินเดือน (P5-1 — สร้าง 27 ส.ค. 2569 · field ตามสเปกเต็มใน `02-BuildSpec-FRS.md` FR-HR-12 12A/12B/12C)

| ตาราง | ws ID | view "全部" | Data Name ไทย |
|---|---|---|---|
| `hr_pay_component` (องค์ประกอบค่าจ้าง) | `6a8ff2868b6633ef76f13871` | `6a8ff2868b6633ef76f13875` | ✅ "องค์ประกอบค่าจ้าง" |
| `hr_pay_period` (งวดจ่ายเงินเดือน) | `6a8ff2878b6633ef76f1387b` | `6a8ff2878b6633ef76f1387f` | ✅ "งวดจ่ายเงินเดือน" |
| `hr_salary_structure` (โครงสร้างเงินเดือน) | `6a8ff287353e1b0e4a508550` | `6a8ff287353e1b0e4a508554` | ✅ "โครงสร้างเงินเดือน" |

- **ลำดับสร้าง:** `hr_pay_component` ก่อน (ไม่มี dependency ขาเข้านอกจาก `ac_coa`) → `hr_pay_period` (อ้าง `ac_period`/`ac_voucher` ของบัญชี) → `hr_salary_structure` (อ้าง `hr_employee` และ `hr_pay_component`)
- **Relation ที่ผูกสำเร็จ (ทั้งหมด `bidirectional:true` สร้าง reverse field อัตโนมัติ):** `hr_pay_component.biz_coa_account`→`ac_coa` (`6a85516e1049edca1eecd9b7`, reverse `6a8ff3049762533b5b7193a3`) · `hr_pay_period.biz_ac_period_ref`→`ac_period` (`6a8434d5055f2288c5b6d4b8`, reverse `6a8ff311ae2a0e3743a0ccb1`) · `hr_pay_period.biz_voucher_ref`→`ac_voucher` (`6a85fb2e9b6999a714d2a53d`, reverse `6a8ff311ae2a0e3743a0ccbb`) · `hr_salary_structure.biz_employee`→`hr_employee` (`6a8efa5e9762533b5b7185c1`, reverse `6a8ff3149762533b5b7193c9`) · `hr_salary_structure.biz_pay_component`→`hr_pay_component` (`6a8ff2868b6633ef76f13871`, reverse `6a8ff3149762533b5b7193cb` — auto-created on `hr_pay_component`)
- **Field ID หลักที่ workflow (WF-HR-07/08/09/10) จะต้องอ้าง:** `hr_pay_period.biz_period_status` `6a8ff311ae2a0e3743a0ccb2` (inline options: Open=`f10e686c-9381-4a5a-9406-bead7012bf51` · Calculating=`d4c51a3a-2c41-4959-bd97-cac24ae9db48` · Pending approval=`4b772a20-1b19-4f49-b635-f4b809e97b1b` · Approved=`3c7aa8cd-6a7c-446a-9d9e-b123dbc1cbd9` · Posted=`a40f98e5-d1a8-408c-a0a5-03c4eeafe5e8` · Closed=`c227fad9-0a9f-4869-90e6-b1b2a15db991` · Cancelled=`30fb7cad-9653-4ce3-a230-6a8b57bd9725`) · `biz_generated_flag` `6a8ff311ae2a0e3743a0ccbe` · `biz_pp_submitted_flag` `6a8ff311ae2a0e3743a0ccbf` · `biz_post_flag` `6a8ff311ae2a0e3743a0ccc0` · `hr_pay_component.biz_component_type` `6a8ff3049762533b5b71939e` (Earning=`3d7c0516-9963-401f-94d5-af77b411ddb0` · Deduction=`b2f76390-5726-49d6-b9c1-2df381b605e8` · Employer contribution=`c0fa8294-f4f1-43dc-8033-71560716d14a` · Informational=`a50efeb5-a2e7-41f9-9184-7b121f6918ba`)
- **Dropdown ที่สร้างเป็น inline options (label อังกฤษให้ตรงกับ optionset กลาง แต่ key/GUID คนละชุด — ยังไม่ bind จริง):** `hr_pay_component.biz_component_type`↔`OS_HR_COMPONENT_TYPE` · `hr_pay_component.biz_calc_method`↔`OS_HR_COMPONENT_CALC` · `hr_pay_period.biz_period_status`↔`OS_HR_PAY_PERIOD_STATUS`
- ⚠️ **ยังไม่มี:** unique index IX-12.1 (`biz_period_year`+`biz_period_month` บน `hr_pay_period`) / IX-12.2 (`biz_employee`+`biz_pay_component`+`biz_effective_from` บน `hr_salary_structure`) — Browser-only · Business Rules BR-12.1/12.2/12.3 · `hr_leave_type.pay_component`→`hr_pay_component` relation ที่ค้างจาก FR-HR-07 (ตารางปลายทางมีแล้ว แต่ยังไม่เพิ่มฟิลด์บน `hr_leave_type`) · `hr_ot_request.pay_period`→`hr_pay_period` relation ที่ค้างจาก P4-2 (ตอนนี้ทำได้แล้ว — ตารางปลายทางพร้อมแล้ว) · seed record P5-6 (โครงสร้างเงินเดือน 4 พนักงานทดสอบ) ยังไม่ได้ทำ
- ✅ **28 ส.ค. 2569 (P5-4) — ปิดครบ 6/6 (ต่อเนื่อง 13):** seed `hr_pay_component` 6 รายการเสร็จผ่าน `batch_create_records`(`triggerWorkflow:false`) — verify ด้วย `get_record_list`/`get_record_details` ผ่านครบ: `SALARY`(rowId `4f6e08db-9316-4d22-88ac-a3656c29a182`)/`OT`(`485f15df-1467-4af6-b072-43c027237e7a`)/`SSO_ER`(`68d66b6b-cfcb-404b-a7c6-35d324c7ca7d`)/`SSO_EE`(`b8e92933-ba55-488b-b6fa-bd2e0c0044f7`)/`WHT`(`ad802ca3-fcb4-4aba-909c-a6f2ae786835`)/`ABSENCE_DEDUCT`(`63ed6dd9-9d2b-435f-a823-28935b0dff8a`) · ผูก `biz_coa_account`(fieldId `6a8ff3049762533b5b7193a2`)→`ac_coa` ครบ **6/6**: `SALARY`/`OT`/`ABSENCE_DEDUCT`→`530101 เงินเดือน`(rowId `43ee2889-b2e5-4620-85b7-53f6db1c8e5b`, 26-27 ส.ค.) · `SSO_ER`→`530102`(rowId `233626b4-d272-4cb5-8f77-9d8d2ddef804`) · `SSO_EE`→`210402`(rowId `c6386fe7-1b3c-44db-ab80-9dfd3308a6a5`) · `WHT`→`210304`(rowId `777ea001-5300-4f5c-857a-71a45db2076b`) — บัญชี 3 รายการหลังนี้ฝ่ายบัญชีสร้างให้ 28 ส.ค. 2569 ตามที่ HR ส่งเรื่องไป (ดู Known Issues)

### 🆕 ID ตารางสลิปเงินเดือน (P5-2 — สร้าง 27 ส.ค. 2569 · field ตามสเปกเต็มใน `02-BuildSpec-FRS.md` FR-HR-12 12D/12E)

| ตาราง | ws ID | view "全部" | Data Name ไทย |
|---|---|---|---|
| `hr_payslip` (สลิปเงินเดือน) | `6a904c85353e1b0e4a50ba05` | `6a904c85353e1b0e4a50ba09` | ✅ "สลิปเงินเดือน" (add-record button ตั้งแล้ว) |
| `hr_payslip_line` (รายการในสลิปเงินเดือน) | `6a904c858b6633ef76f16a0b` | `6a904c858b6633ef76f16a0f` | ✅ "รายการในสลิปเงินเดือน" (add-record button ตั้งแล้ว) |

- **Relation ที่ผูกสำเร็จ (ทั้งหมด `bidirectional:true`):** `hr_payslip.biz_employee`→`hr_employee` (`6a8efa5e9762533b5b7185c1`, reverse `6a904d67353e1b0e4a50ba11`) · `hr_payslip.biz_pay_period`→`hr_pay_period` (`6a8ff2878b6633ef76f1387b`, reverse `6a904d67353e1b0e4a50ba13`) · `hr_payslip.biz_cost_center`→`ac_cost_center` (`6a85452b9b6999a714d26720`, reverse `6a904d67353e1b0e4a50ba15`) · `hr_payslip.biz_bank_account`→`hr_bank_account` (`6a8efd1fae2a0e3743a0bd9d`, reverse `6a904d67353e1b0e4a50ba26`) · `hr_payslip_line.biz_payslip`→`hr_payslip` (`6a904c85353e1b0e4a50ba05`, reverse `6a904d6d9762533b5b71c4e2` auto-created on `hr_payslip`) · `hr_payslip_line.biz_pay_component`→`hr_pay_component` (`6a8ff2868b6633ef76f13871`, reverse `6a904d6d9762533b5b71c4e4`)
- **Field ID หลักที่ workflow (WF-HR-07/08) จะต้องอ้าง:** `hr_payslip.biz_payslip_no` `6a904d67353e1b0e4a50ba0f` (AutoNumber, title, rule "PS-"+yyyyMM+sequence4) · `biz_recalc_flag` `6a904d67353e1b0e4a50ba28` (🔴 Trigger Field ของ WF-HR-08 ที่ยังไม่ได้สร้าง) · `biz_calculated_flag` `6a904d67353e1b0e4a50ba29` · `biz_payslip_status` `6a904d67353e1b0e4a50ba27` (inline: Draft=`73dcdbaf-283c-4182-9072-3f59b4336f79` · Calculated=`740b4fba-e506-4e23-853f-10b17b3d7210` · Approved=`325b8942-70b4-4ffa-9e78-ce8d65937156` · Paid=`f1ed2aa6-f2d8-4e8b-804e-118625af0d72` · Cancelled=`a846cbb5-75a1-4515-bc96-908d5ce7d8cf`) · totals `biz_total_earning`/`biz_total_deduction`/`biz_net_pay` = `6a904d67353e1b0e4a50ba1d`/`...1e`/`...1f`
- **⚠️ เปลี่ยนจากสเปกเดิม:** ยอดเงินทั้งหมด (`base_salary`/totals/`sso_ee`/`sso_er`/`wht_amount`/`ytd_*`/`hr_payslip_line.rate`/`amount`) สร้างเป็น **`Currency` (code THB)** แทน `Number` ตามที่ระบุใน BuildSpec ฉบับก่อนหน้า (ปรับ BuildSpec ให้ตรงของจริงแล้ว) · `payslip_no` ใช้ **`AutoNumber`** แทน `Text` (รองรับ isTitle + auto-generate ได้ในตัว)
- flag/total ทุกตัวตั้ง `defaultValue:[{source:"static",value:"0"}]` เชิงรุกตามแบบแผนที่เจอบั๊กซ้ำมาก่อน (D-9/D-13 pattern)
- ⚠️ **ยังไม่มี:** unique index IX-12.3 (`biz_employee`+`biz_pay_period` บน `hr_payslip`) — Browser-only · Business Rules BR-12.4 (`pay_period.period_status` in Posted/Closed → read-only)/BR-12.5 (R1 เห็นเฉพาะ Published/Paid) · ผูก `biz_payslip_status` เข้า `OS_HR_PAYSLIP_STATUS` `f77b582b-187e-4df0-8578-69b2078d9045` จริง (label "Published" ของ optionset เดิมกับ "Paid" ที่สร้างใหม่ไม่ตรงกัน ต้องเทียบก่อนผูก) · Dynamic default snapshot ของ `biz_cost_center` · WF-HR-07 (สร้างสลิปทั้งงวด)/WF-HR-08 (คำนวณสลิป) ยังไม่ได้สร้าง

### 🆕 ID ตารางภาษี/หนังสือรับรอง (P5-3 — สร้าง 27 ส.ค. 2569 · field ตามสเปกเต็มใน `02-BuildSpec-FRS.md` FR-HR-12 12I/12J · กลุ่มเงินเดือนครบ 7/7 ตารางแล้ว)

| ตาราง | ws ID | view "全部" | Data Name ไทย |
|---|---|---|---|
| `hr_pnd1_filing` (การยื่นภาษีเงินได้หัก ณ ที่จ่าย) | `6a904e72ae2a0e3743a0fd06` | `6a904e72ae2a0e3743a0fd0a` | ✅ "การยื่นภาษีเงินได้หัก ณ ที่จ่าย" |
| `hr_wht_cert` (หนังสือรับรองการหักภาษี ณ ที่จ่าย) | `6a904e73353e1b0e4a50ba83` | `6a904e73353e1b0e4a50ba87` | ✅ "หนังสือรับรองการหักภาษี ณ ที่จ่าย" |

- **Relation ที่ผูกสำเร็จ (ทั้งหมด `bidirectional:true`):** `hr_pnd1_filing.biz_pay_periods`→`hr_pay_period` (`6a8ff2878b6633ef76f1387b`, multi, reverse `6a904e96353e1b0e4a50ba93`) · `hr_wht_cert.biz_employee`→`hr_employee` (`6a8efa5e9762533b5b7185c1`, reverse `6a904ea1353e1b0e4a50bac0`) · `hr_wht_cert.biz_pnd1_filing`→`hr_pnd1_filing` (`6a904e72ae2a0e3743a0fd06`, reverse `6a904ea1353e1b0e4a50bac3` auto-created on `hr_pnd1_filing`)
- **Field ID หลักที่ WF-HR-10/WF-HR-20 (ยังไม่สร้าง) จะต้องอ้าง:** `hr_pnd1_filing.biz_filing_status` `6a904e96353e1b0e4a50ba97` (inline: Draft=`9cfae3d7-8705-413f-b406-a0d538aaf406` · Approved=`e1aa329d-b0b2-4576-b23c-29f0740e0d7d` · Filed=`b214da57-0f11-4165-acba-139be95bf93a` · Paid=`a16148b3-68f1-4032-892a-bfb1a688bf91` · Amended=`260f4c54-e005-4c62-8118-2a5be8b92483`) · `biz_issue_cert_flag` `6a904e96353e1b0e4a50ba9b` (🔴 Trigger Field ของ WF-HR-20) · `hr_wht_cert.biz_cert_status` `6a904ea1353e1b0e4a50bac8` (inline: Issued=`48242102-ee8a-44a4-bec5-482b16b8729e` · Printed=`27a8ee8a-f6e2-4bfa-aa2a-da709d93ada6` · Included in filing=`e608e791-438d-40fa-acb3-fb339ef41eee` · Cancelled=`8b45923b-7541-4417-9cec-295d4c37e962`)
- **⚠️ เปลี่ยนจากสเปกเดิม:** `total_income`/`total_wht` ทั้ง 2 ตารางสร้างเป็น **`Currency` (THB)** แทน `Number` (ปรับ BuildSpec ให้ตรงของจริงแล้ว — สอดคล้องกับแนวทางเดียวกับ `hr_payslip` ใน P5-2)
- `biz_payee_legal_form` ของ `hr_wht_cert` สร้างเป็น inline options มีแค่ค่า "Individual" (`08216df9-8694-4a85-a961-a61c7f1646f6`) ตรงกับที่สเปกระบุว่าใช้เฉพาะค่านี้ — key ต่างจาก `OS_LEGAL_FORM` ของโมดูลบัญชี (`1aeb1a04-1957-4905-92d9-c506d8bbdccc`) ยังไม่ผูกจริง
- ⚠️ **ยังไม่มี:** unique index IX-12.5 (`biz_form_type`+`biz_tax_year`+`biz_tax_month` บน `hr_pnd1_filing`) / IX-12.6 (`biz_employee`+`biz_tax_year` บน `hr_wht_cert`) — Browser-only · ผูก dropdown 4 ฟิลด์เข้า shared optionset จริง (`form_type`/`filing_status`/`payee_legal_form`/`cert_status`) · WF-HR-10 (ผ่านรายการเข้าบัญชี, ⛔ บล็อกด้วย G-02)/WF-HR-20 (ออกหนังสือรับรองประจำปี) ยังไม่ได้สร้าง

### 🆕 ID Workflow WF-HR-02 / WF-HR-03 (P3-6 — สร้าง+publish+ทดสอบยิงจริงสำเร็จ 27 ส.ค. 2569)

| Workflow | processId | publish version | node สำคัญ |
|---|---|---|---|
| **WF-HR-02** ตัดสิทธิลาเมื่ออนุมัติ | `6a8fa97cfdab77a41c51cb3f` | v3 (v1/v2 มีบั๊ก ledger balance_after ผิด/relation ขยะ — แก้แล้วใน v3) | `gate`(branch)→`upd_deducted`→`get_emp`→`calc_neg_days`→`get_bal`→`br_bal_found`(branch: `bal_missing`→`add_bal`+`calc_used_m`+`calc_remaining_m`+`add_ledger_m`+`upd_bal_m`+`notify_m` / `bal_found`→`calc_used_f`+`calc_remaining_f`+`add_ledger_f`+`upd_bal_f`+`notify_f`) |
| **WF-HR-03** คืนสิทธิลาเมื่อยกเลิกใบลา | `6a8fab800e97bf440dddb744` | v1 (ถูกต้องตั้งแต่รอบแรก เพราะเรียนรู้บั๊กจาก WF-HR-02 มาก่อน) | `gate`(branch)→`upd_returned`→`get_emp`→`get_bal`(ifEmpty:stop)→`calc_used_r`→`calc_remaining_r`→`add_ledger_r`→`upd_bal_r`→`notify_emp_r`→`notify_approver_r` |

**หลักการสำคัญที่ทั้งคู่ใช้ (เขียนไว้ใน Known Issues ด้วย):** (1) `add_record` ของ ledger ต้องรันก่อน `update_record` ของ balance เสมอ (ไม่งั้น compute node ที่อ้างซ้ำจะคำนวณผิดจากค่าที่ update ไปแล้ว) (2) เขียนค่าลง Relation field ที่ชี้ไปยัง record ของ node ต้นน้ำ ใช้ `{kind:"field", node:{nodeAlias:<node>}, fieldId:"rowid"}` ไม่ใช่ `{kind:"record", node:{...}}`

> 🔴🆕 **D-8 ลองทำแล้ว 27 ส.ค. 2569 (รอบเย็น) แต่ชนบั๊กใหม่ `sub_process`→`NodeAppIsNull` — revert กลับสถานะเดิมแล้ว (publish v4/v2)** — `hr_attendance` มีตารางแล้ว แต่การเพิ่ม node sync สถานะ "On leave" กลับเข้า WF-HR-02/WF-HR-03 ต้องใช้ node ชนิด `sub_process` (`sequential_each`) เพื่อวน update ทีละ attendance record ที่ทับช่วงวันลา — สร้างสำเร็จแต่ publish ไม่ได้ ดูรายละเอียดเต็มใน Known Issues ด้านล่าง (หัวข้อ "sub_process → NodeAppIsNull") — **ยังบล็อกอยู่จริง ไม่ใช่พร้อมทำ**

### 🆕 ID Workflow WF-HR-04 (P4-3 — สร้าง+publish+ทดสอบขั้นหัวหน้างานสำเร็จ 27 ส.ค. 2569 ต่อเนื่อง — ไม่ต้องใช้ `sub_process`)

| Process | processId | publish version | node สำคัญ |
|---|---|---|---|
| **Main** WF-HR-04 | `6a8fd8d35f8564a68c3c1909` | v2 (v1 มีบั๊ก `dateDiff` precision — แก้แล้วใน v2) | `gate`(branch: `leg_supervisor`/`leg_hr`/`leg_default` ตาม `hr_ot_status`)→[leg_supervisor] `get_emp`(reverse-relation+`op:eq` หา `hr_employee`)→`chk_supervisor`(branch missing/ok)→[sup_missing]`rej_no_supervisor`+notify / [sup_ok]`calc_ot_minutes`(compute dateDiff→นาที)→`calc_ot_hours`(compute number หาร 60, precision:2)→`get_holiday`→`chk_holiday`(branch is_workday/is_holiday)→[is_holiday]`get_rate_holiday`→`upd_daytype_holiday`→`appr_block_1a`(approval_block, `mode:"use_existing"` ชี้ processId เดียวกับ 1b) / [is_workday]`get_rate_workday`→`upd_daytype_workday`→`appr_block_1b`(approval_block, `mode:"create"` — ตัวที่สร้าง inner flow จริง) · [leg_hr] `appr_block_2`(approval_block, `mode:"use_existing"` ชี้ inner HR flow) |
| **Inner** supervisor-approval (ใช้ร่วม 2 เส้นทาง day-type) | `6a8fd9325f8564a68c3c1cec` | v1 | `approve_l1`(approvers=`approval_start.hr_approver_user`)→`res_branch_1`(branch r_pass/r_reject)→[r_pass]`upd_pendinghr`(ot_status→Pending HR, approval_step=2) / [r_reject]`upd_rejected_l1`+`notify_rejected_l1` |
| **Inner** HR-approval | `6a8fd9325f8564a68c3c1ced` | v1 (สร้างแล้ว **ยังไม่ทดสอบ** — รอ `hr_approval_rule` seed) | `get_rule`(get_single `hr_approval_rule` filter `hr_doc_kind`=OT key `402a261b-ba3f-4e76-941a-0791d5ceea84` AND `hr_approval_level`="2" AND `hr_rule_is_active` checked, ifEmpty:stop)→`approve_l2`(approvers=`get_rule.hr_approver_role`)→`res_branch_2`(branch)→[pass]`upd_approved`(ot_status→Approved, approval_step=3) / [reject]`upd_rejected2`+`notify_final_rejected` |

**🆕 เทคนิคใหม่ — แชร์ inner approval_block ข้าม 2 branch path ที่ไม่มีทาง merge กัน (บันทึกไว้ใน Known Issues ด้วย):** แพลตฟอร์มนี้ไม่มี node ชนิด join/merge — ทุก node มี `prevNode` ได้แค่ 1 เดียว ⇒ เมื่อ 2 เส้นทาง (holiday/workday) ต้องไปจบที่ approval_block เดียวกัน ให้สร้าง approval_block ตัวแรกด้วย `config.process.mode:"create"` (เก็บ inner `processId` ที่ตอบกลับมาใน `createdNodes`) แล้วสร้าง approval_block ตัวที่สองด้วย `mode:"use_existing"` อ้าง processId เดียวกัน — ได้ผลลัพธ์เหมือน merge จริงในแง่ logic (ทั้ง 2 เส้นทางส่งเข้า approval flow เดียวกัน) โดยไม่ต้องสร้าง inner flow ซ้ำ

**🆕 ID ปุ่ม + view P4-5 (สร้าง+verify ผ่านจริง 27 ส.ค. 2569 ต่อเนื่อง 2):**

| รายการ | บน worksheet | ID | หมายเหตุ |
|---|---|---|---|
| ปุ่ม "ส่งขอล่วงเวลา" | `hr_ot_request` | `6a8fde0aae2a0e3743a0c62f` | `updateCurrentRecord`, `enableWhen: hr_ot_status=Draft`, `runWorkflowAfterSubmit:true` — Scope ตั้งเป็น "All Records" แล้วผ่าน Browser |
| view "OT รออนุมัติ" | `hr_ot_request` | `6a8fde0b353e1b0e4a50803e` | filter `hr_ot_status` in (Pending supervisor, Pending HR) |
| view "บันทึกลงเวลาที่ผิดปกติ" | `hr_attendance` | `6a8fde0c1378964f9984a42c` | filter `hr_att_status` in (Late, Absent) |

**🆕 ทดสอบยิงจริง 3 เคส (เก็บไว้เป็นหลักฐาน ไม่ลบ):** `OT-TEST-HOLIDAY-01` (rowid `079c9d4d-439b-4536-9670-4d753d2af47f`, 4h ณ Holiday outside hours → `applied_multiplier`=3.0) · `OT-TEST-WORKDAY-01` (rowid `6384d1bc-dfb0-40b5-af86-e5b399725ec0`, 2.5h ณ Working day → ×1.5) · `OT-TEST-FRACTIONAL-01` (rowid `ecfa8e8f-b65e-4e60-ab5b-1dded2d3761a`, 2.5h → ยืนยัน `hr_ot_hours`="2.50" ถูกต้องหลังแก้บั๊ก precision) — ทั้ง 3 มี `_updatedBy`=`user-workflow` และ To-do จริงถึง Wanadtapong.l (`get_approval_list_by_row`) ✅ **AC-19 ส่วนแรกผ่าน** (`applied_multiplier` ดึงจากตาราง `hr_ot_rate` จริง ไม่ hardcode — ยืนยันจาก 2 ค่าต่างกันตาม day_type)

### 🆕 ID Workflow WF-HR-05 / WF-HR-06 (P4-4 / P4-6 — สร้าง+publish 28 ส.ค. 2569 · **เพิ่มเข้า Registry ย้อนหลัง 30 ส.ค. 2569**)

> 🔴 **ทำไมเพิ่มย้อนหลัง:** ฝั่งบัญชีส่งเรื่องมาใน `handoff/AC-DOC-SLIM.md` §4 ว่าเขาเจอ `WF-AC-10` publish แล้วแต่ตกหล่นจาก Registry (agent รอบหน้าเสี่ยงสร้างซ้ำทั้งตัว) และแนะนำให้ HR ไล่เช็คบ้าง — **ตรวจแล้วเป็นจริง: WF-HR-05 และ WF-HR-06 ไม่เคยถูกบันทึกลง Registry เลยตั้งแต่สร้าง** ทั้งที่ `enabled=true` ใช้งานอยู่

| Process | processId | publish version | โครงสร้าง |
|---|---|---|---|
| **Main** WF-HR-05 สรุปเวลาทำงานรายวัน | `6a910184730d20c5b7710fa8` | **v3** (v1 สร้าง 28 ส.ค. · **v3 = แก้ D-19 เมื่อ 30 ส.ค.**) | 9 node · trigger = schedule (`frequency:0`) · `คำนวณวันที่เมื่อวาน`(compute actionId 101) → `หาบันทึกลงเวลาที่ยังไม่สรุป`(**get_multiple actionId 400** บน `hr_attendance`) → `สรุปสถานะทีละรายการ`(sub_process) |
| **Inner** WF-HR-05 สรุปต่อ 1 เรคอร์ด | `6a910197730d20c5b7711028` | v1 | 22 node · branch `เป็นวันหยุด`(cond 7) / `ไม่มีเวลาเข้า`(cond 8) / `มีใบลาอนุมัติ`(cond 7) |
| **Main** WF-HR-06 เตือนคำขอค้างอนุมัติเกิน SLA | `6a910222730d20c5b77115e5` | v1 | 9 node · trigger = schedule (`frequency:0`) · → `แจ้งเตือนทีละใบ`(sub_process) |
| **Inner** WF-HR-06 แจ้งเตือนต่อ 1 ใบ | `6a9102345f8564a68c449ee7` | v1 | 9 node · branch `มีผู้อนุมัติ`(cond 7 บนฟิลด์ type 26) |

🔴 **node ที่ต้องระวัง — `หาบันทึกลงเวลาที่ยังไม่สรุป` (`6a91018d730d20c5b7710fdc`)** filter = `สรุปแล้ว`(`6a8fcd7f353e1b0e4a507d4f`) **`≠ "1"` OR `is empty`** · OR group ที่สองเพิ่มเมื่อ 30 ส.ค. เพื่อแก้ D-19 — **ถ้าแก้ node นี้ต้องส่ง config ครบทั้งก้อนผ่าน `hap workflow node save --type 13` ห้ามใช้ `save-get-more --condition` เพราะมันทิ้ง OR group ที่สองเงียบ ๆ** (`shared/00-HAP-Working-Guide.md` §2 ข้อ 23/24)

⚠️ **ทั้ง WF-HR-05 และ WF-HR-06 ยังไม่เคย live-fire test** — เป็น schedule และ `hap workflow trigger` ไม่รัน flow จริง (`shared/00-HAP-Working-Guide.md` §2 ข้อ 25) ต้องดู Workflow History บนเบราว์เซอร์ · fixture ที่เตรียมไว้: `hr_attendance` → `TEST-ATT-D19-01` (rowid `0a91bd5e-9b1b-4221-a113-739212564ca7`)

⚠️ **WF-HR-06 v1 จำกัดขอบเขตเหลือแค่ `hr_leave_request`** — ตัด `hr_ot_request` ออกเพราะ D-18 (`hr_ot_request` ไม่มีฟิลด์ `submitted_at`)

**สรุป workflow ที่มีอยู่จริงในแอปตอนนี้ = WF-HR-01…06 เท่านั้น** (main 6 + inner 6 = 12 process) · **WF-HR-07…13 ยังไม่มีอยู่จริง** ID ในเอกสารส่วนอื่นเป็น target/`<TBD>`

### 🔴 ตารางของบัญชีที่ HR ต้องเขียนถึง (ID ดึงจริงแล้ว — ใช้ได้เลย ห้ามแก้โครงสร้าง)

| ตาราง | ws ID | HR ใช้ทำอะไร |
|---|---|---|
| **ใบสำคัญ** `ac_voucher` | `6a85fb2e9b6999a714d2a53d` | WF-HR-10 สร้างใบสำคัญเงินเดือน · 🔴 required 6 ฟิลด์ (`description` `voucher_date` `journal` `voucher_type` `period` `currency`) |
| **รายการในใบสำคัญ** `ac_voucher_line` | `6a85fb3933560633b8cd9f40` | บรรทัดเดบิต/เครดิต · relation กลับ = `6a85fb399b6999a714d2a557` |
| **ใบขออนุมัติเบิกจ่าย** `ac_pay_req` | `6a8677b19b6999a714d2aa83` | WF-HR-12 ส่งใบเบิกสวัสดิการเข้าไปจ่าย |
| **หน่วยงาน/ศูนย์ต้นทุน** `ac_cost_center` | `6a85452b9b6999a714d26720` | ปลายทาง relation "หน่วยงาน" · ✅ มีฟิลด์ `hrms_unit_id` `6a85452b055f2288c5b741bc` เตรียมไว้แล้ว |
| **ผังบัญชี** `ac_coa` | `6a85516e1049edca1eecd9b7` | ปลายทางของ `hr_pay_component.coa_account` (79 record) |
| **กฎการผ่านรายการ** `ac_posting_rule` | `6a85518c33560633b8cd6a15` | 🔴 คู่บัญชีเงินเดือน — **ห้าม hard-code รหัสบัญชีใน workflow** |
| **งวดบัญชี** `ac_period` | `6a8434d5055f2288c5b6d4b8` | ผูกงวดจ่ายเงินเดือน · 🔴 **ห้ามลบสร้างใหม่** |

**Option key ที่ใช้บ่อย (จำไว้ ไม่ต้องเปิดหา)**
- `ac_voucher.source_module` `6a86021833560633b8cd9fb1` → **Payroll = `914f5226-dc4c-4572-bd4d-18bb278414b5`** 🔴 WF-HR-10 ต้องเขียนค่านี้
- `ac_voucher.voucher_status` `6a86016b1049edca1eed028a` → Draft = `3536165d-460c-4942-8bec-6f381209d8da`
- `ac_period.period_status` `6a851f70055f2288c5b73edf` → Open = `f662571c-3de0-4e4c-9828-9172e337d223`
- `ac_pay_req.biz_preq_status` `6a8ec5be353e1b0e4a506d75` → Draft = `08092993-906a-4956-b0ff-6f91f766fe61`

---

---

### 🆕 ID ตารางเฟส 6–7 · สวัสดิการ / สรรหา / ประเมินผล (P6-1 · P7-1 · P7-5 — สร้าง 31 ส.ค. 2569)

> **วิธีสร้างที่ใช้รอบนี้ (ต่างจากรอบก่อน):** `hap worksheet create <app> "<ชื่อไทย>" --alias <alias> --section-id <sec>` สร้างเปลือกตาราง แล้ว **MCP `update_worksheet` ส่ง `removeFields` (คอลัมน์เริ่มต้น 3 ตัว) + `addFields` (ฟิลด์จริงพร้อม alias) ในคำสั่งเดียว**
> ✅ ได้ alias ครบทุกฟิลด์ (ต่างจาก `hap worksheet create --fields` / `add-fields --controls` ที่ alias หายทั้งคู่)
> 🆕 **`hap worksheet create` ให้ค่าเริ่มต้นเป็นภาษาอังกฤษ (`entityName: "Record"` · view `"All"`) ไม่ใช่ภาษาจีน `记录`/`全部` แบบ workaround `create_app_items`** — แต่ยังต้องแก้เป็นไทยอยู่ดี · แก้แล้วทั้ง 8 ตาราง
> 🔴 **`defaultValue` ยังไม่ persist เหมือนเดิม** — อ่านกลับ `--raw` ได้ `default: ""` ทุกตัว ⇒ ฟิลด์ธงของ 8 ตารางนี้ก็เกิดมาพร้อมค่าว่าง ต้องตั้งผ่านหน้าจอตาม **P2-4**
> **Section:** HR-05 Talent `6a8ee66ce56d2e6eb7bd6cb9` · HR-06 Welfare and Claims `6a8ee66ce56d2e6eb7bd6cba`
> **ยังไม่ได้ทำ:** unique index IX-18.1 / IX-22.1 / IX-22.2 (Browser) · ผูก Dropdown เข้า shared optionset (ตอนนี้เป็น inline options ที่ลอกค่าจาก optionset จริงมาครบทุกตัว — key คนละค่ากับ optionset กลาง)

#### `hr_welfare_scheme` — สวัสดิการ · `6a95c0db8b6633ef76f1fcf9`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อสวัสดิการ | `scheme_name` | `6a95c10c353e1b0e4a515a95` | Text |
| รหัสสวัสดิการ | `scheme_code` | `6a95c10c353e1b0e4a515a96` | Text |
| ระดับพนักงาน | `job_level` | `6a95c10c353e1b0e4a515a97` | Relation |
| วงเงินสิทธิ | `entitlement_amount` | `6a95c10c353e1b0e4a515a99` | Number |
| รอบสิทธิ | `entitlement_cycle` | `6a95c10c353e1b0e4a515a9a` | Dropdown |
| วงเงินสูงสุดต่อครั้ง | `max_per_claim` | `6a95c10c353e1b0e4a515a9b` | Number |
| ต้องแนบใบเสร็จ | `require_receipt` | `6a95c10c353e1b0e4a515a9c` | Checkbox |
| ครอบคลุมผู้ติดตาม | `covers_dependent` | `6a95c10c353e1b0e4a515a9d` | Checkbox |
| ผังบัญชีที่ผูก | `coa_account` | `6a95c10c353e1b0e4a515a9e` | Relation |
| มีผลตั้งแต่วันที่ | `effective_from` | `6a95c10c353e1b0e4a515aa0` | Date |
| เปิดใช้งาน | `is_active` | `6a95c10c353e1b0e4a515aa1` | Checkbox |
| วงเงินสวัสดิการคงเหลือ | `_(reverse-relation ระบบสร้าง)_` | `6a95c129353e1b0e4a515ac5` | Relation |

#### `hr_welfare_balance` — วงเงินสวัสดิการคงเหลือ · `6a95c0de9762533b5b7250a1`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อรายการวงเงิน | `wb_name` | `6a95c129353e1b0e4a515ac1` | Text |
| พนักงาน | `wb_employee` | `6a95c129353e1b0e4a515ac2` | Relation |
| สวัสดิการ | `wb_welfare_scheme` | `6a95c129353e1b0e4a515ac4` | Relation |
| ปีสิทธิประโยชน์ | `benefit_year` | `6a95c129353e1b0e4a515ac6` | Number |
| วงเงินสิทธิ | `entitled_amount` | `6a95c129353e1b0e4a515ac7` | Number |
| วงเงินที่ใช้ไป | `used_amount` | `6a95c129353e1b0e4a515ac8` | Number |
| วงเงินคงเหลือ | `remaining_amount` | `6a95c129353e1b0e4a515ac9` | Number |
| หมายเหตุ | `wb_note` | `6a95c129353e1b0e4a515aca` | Text |

#### `hr_job_requisition` — ใบขออัตรากำลัง · `6a95c1349762533b5b7250b5`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| เลขที่ใบขออัตรากำลัง | `req_no` | `6a95c175ae2a0e3743a1888b` | Text |
| ตำแหน่งงาน | `req_position` | `6a95c175ae2a0e3743a1888c` | Relation |
| หน่วยงาน / ศูนย์ต้นทุน | `req_cost_center` | `6a95c175ae2a0e3743a1888e` | Relation |
| ระดับพนักงาน | `req_job_level` | `6a95c175ae2a0e3743a18890` | Relation |
| จำนวนอัตราที่ขอ | `headcount` | `6a95c175ae2a0e3743a18892` | Number |
| งบประมาณที่ตั้งไว้ | `budget_amount` | `6a95c175ae2a0e3743a18893` | Number |
| เหตุผลความจำเป็น | `req_reason` | `6a95c175ae2a0e3743a18894` | Text |
| วันที่ต้องการเริ่มงาน | `target_start_date` | `6a95c175ae2a0e3743a18895` | Date |
| สถานะใบขอ | `req_status` | `6a95c175ae2a0e3743a18896` | Dropdown |
| ผู้อนุมัติที่ระบบกำหนด | `req_approver_user` | `6a95c175ae2a0e3743a18897` | Collaborator |
| วันที่อนุมัติ | `req_approved_at` | `6a95c175ae2a0e3743a18898` | DateTime |
| (ระบบ) ส่งอนุมัติแล้ว | `req_submitted_flag` | `6a95c175ae2a0e3743a18899` | Number |
| จำนวนที่บรรจุแล้ว | `filled_count` | `6a95c175ae2a0e3743a1889a` | Number |
| ผู้สมัคร | `_(reverse-relation ระบบสร้าง)_` | `6a95c1988b6633ef76f1fd0b` | Relation |

#### `hr_candidate` — ผู้สมัคร · `6a95c137ae2a0e3743a1887f`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อผู้สมัคร | `candidate_name` | `6a95c1988b6633ef76f1fd09` | Text |
| ใบขออัตรากำลัง | `cand_job_requisition` | `6a95c1988b6633ef76f1fd0a` | Relation |
| ตำแหน่งที่สมัคร | `applied_position` | `6a95c1988b6633ef76f1fd0c` | Relation |
| ขั้นตอนการคัดเลือก | `cand_stage` | `6a95c1988b6633ef76f1fd0e` | Dropdown |
| อีเมล | `cand_email` | `6a95c1988b6633ef76f1fd0f` | Email |
| โทรศัพท์มือถือ | `cand_mobile` | `6a95c1988b6633ef76f1fd10` | PhoneNumber |
| เลขประจำตัวประชาชน (PDPA) | `candidate_national_id` | `6a95c1988b6633ef76f1fd11` | Text |
| วันเกิด | `cand_birth_date` | `6a95c1988b6633ef76f1fd12` | Date |
| ประสบการณ์ (ปี) | `experience_years` | `6a95c1988b6633ef76f1fd13` | Number |
| เงินเดือนที่คาดหวัง | `expected_salary` | `6a95c1988b6633ef76f1fd14` | Number |
| การศึกษา | `cand_education` | `6a95c1988b6633ef76f1fd15` | Text |
| ช่องทางที่มา | `source_channel` | `6a95c1988b6633ef76f1fd16` | SingleSelect |
| เวลาที่เปลี่ยนขั้นตอน | `stage_changed_at` | `6a95c1988b6633ef76f1fd17` | DateTime |
| เอกสารสมัคร | `cand_resume` | `6a95c1988b6633ef76f1fd18` | Attachment |
| พนักงานที่จ้างแล้ว | `hired_employee` | `6a95c1988b6633ef76f1fd19` | Relation |
| (ระบบ) จ้างแล้ว | `hire_flag` | `6a95c1988b6633ef76f1fd1b` | Number |
| วันที่ให้ความยินยอม PDPA | `pdpa_consent_date` | `6a95c1988b6633ef76f1fd1c` | Date |
| เก็บข้อมูลถึงวันที่ | `data_retention_until` | `6a95c1988b6633ef76f1fd1d` | Date |
| การสัมภาษณ์ | `_(reverse-relation ระบบสร้าง)_` | `6a95c1ac8b6633ef76f1fd4e` | Relation |

#### `hr_interview` — การสัมภาษณ์ · `6a95c1399762533b5b7250c1`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อรายการสัมภาษณ์ | `interview_name` | `6a95c1ac8b6633ef76f1fd4c` | Text |
| ผู้สมัคร | `itv_candidate` | `6a95c1ac8b6633ef76f1fd4d` | Relation |
| รอบที่สัมภาษณ์ | `interview_round` | `6a95c1ac8b6633ef76f1fd4f` | Number |
| วันเวลาสัมภาษณ์ | `interview_at` | `6a95c1ac8b6633ef76f1fd50` | DateTime |
| กรรมการสัมภาษณ์ | `interviewers` | `6a95c1ac8b6633ef76f1fd51` | Collaborator |
| สถานที่ | `itv_location` | `6a95c1ac8b6633ef76f1fd52` | Text |
| คะแนน | `itv_score` | `6a95c1ac8b6633ef76f1fd53` | Number |
| ผลการสัมภาษณ์ | `itv_result` | `6a95c1ac8b6633ef76f1fd54` | SingleSelect |
| ความเห็นกรรมการ | `itv_comments` | `6a95c1ac8b6633ef76f1fd55` | Text |
| (ระบบ) แจ้งนัดแล้ว | `notified_flag` | `6a95c1ac8b6633ef76f1fd56` | Number |

#### `hr_appraisal_cycle` — รอบประเมินผล · `6a95c13b1378964f99857909`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อรอบประเมิน | `cycle_name` | `6a95c1c1353e1b0e4a515af0` | Text |
| ปีที่ประเมิน | `cycle_year` | `6a95c1c1353e1b0e4a515af1` | Number |
| ครั้งที่ | `cycle_no` | `6a95c1c1353e1b0e4a515af2` | Number |
| รอบประเมินตั้งแต่วันที่ | `period_from` | `6a95c1c1353e1b0e4a515af3` | Date |
| รอบประเมินถึงวันที่ | `period_to` | `6a95c1c1353e1b0e4a515af4` | Date |
| กำหนดส่งประเมินตนเอง | `self_due_date` | `6a95c1c1353e1b0e4a515af5` | Date |
| กำหนดหัวหน้าประเมิน | `supervisor_due_date` | `6a95c1c1353e1b0e4a515af6` | Date |
| กำหนด HR สรุป | `hr_due_date` | `6a95c1c1353e1b0e4a515af7` | Date |
| (ระบบ) เปิดรอบแล้ว | `cycle_open_flag` | `6a95c1c1353e1b0e4a515af8` | Number |
| จำนวนแบบประเมินที่สร้างแล้ว | `generated_count` | `6a95c1c1353e1b0e4a515af9` | Number |
| แบบประเมินผล | `_(reverse-relation ระบบสร้าง)_` | `6a95c1e0353e1b0e4a515b17` | Relation |

#### `hr_appraisal` — แบบประเมินผล · `6a95c13d1378964f99857913`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อแบบประเมิน | `appraisal_name` | `6a95c1e0353e1b0e4a515b15` | Text |
| รอบประเมิน | `apr_cycle` | `6a95c1e0353e1b0e4a515b16` | Relation |
| พนักงาน | `apr_employee` | `6a95c1e0353e1b0e4a515b18` | Relation |
| หัวหน้าผู้ประเมิน | `apr_supervisor_user` | `6a95c1e0353e1b0e4a515b1a` | Collaborator |
| สถานะการประเมิน | `appraisal_status` | `6a95c1e0353e1b0e4a515b1b` | Dropdown |
| คะแนนประเมินตนเอง | `self_score` | `6a95c1e0353e1b0e4a515b1c` | Number |
| คะแนนจากหัวหน้า | `supervisor_score` | `6a95c1e0353e1b0e4a515b1d` | Number |
| คะแนนสุดท้าย | `final_score` | `6a95c1e0353e1b0e4a515b1e` | Number |
| เกรด | `apr_grade` | `6a95c1e0353e1b0e4a515b1f` | SingleSelect |
| ความเห็นของพนักงาน | `self_comment` | `6a95c1e0353e1b0e4a515b20` | Text |
| ความเห็นของหัวหน้า | `supervisor_comment` | `6a95c1e0353e1b0e4a515b21` | Text |
| ความเห็นของ HR | `hr_comment` | `6a95c1e0353e1b0e4a515b22` | Text |
| วันที่ส่งแบบประเมิน | `apr_submitted_at` | `6a95c1e0353e1b0e4a515b23` | DateTime |
| วันที่ประเมินเสร็จ | `apr_completed_at` | `6a95c1e0353e1b0e4a515b24` | DateTime |
| (ระบบ) ขั้นการประเมิน | `apr_step_flag` | `6a95c1e0353e1b0e4a515b25` | Number |
| รายการประเมิน | `_(reverse-relation ระบบสร้าง)_` | `6a95c1f38b6633ef76f1fd75` | Relation |

#### `hr_appraisal_item` — รายการประเมิน · `6a95c140353e1b0e4a515ae6`

| ฟิลด์ | alias | fieldId | type |
|---|---|---|---|
| ชื่อรายการประเมิน | `item_name` | `6a95c1f38b6633ef76f1fd73` | Text |
| แบบประเมิน | `item_appraisal` | `6a95c1f38b6633ef76f1fd74` | Relation |
| หมวดรายการ | `item_category` | `6a95c1f38b6633ef76f1fd76` | SingleSelect |
| น้ำหนัก (%) | `weight_pct` | `6a95c1f38b6633ef76f1fd77` | Number |
| เป้าหมาย | `target_value` | `6a95c1f38b6633ef76f1fd78` | Text |
| ผลงานจริง | `actual_value` | `6a95c1f38b6633ef76f1fd79` | Text |
| คะแนนตนเอง | `self_rating` | `6a95c1f38b6633ef76f1fd7a` | Number |
| คะแนนหัวหน้า | `supervisor_rating` | `6a95c1f38b6633ef76f1fd7b` | Number |
| ความเห็นต่อรายการ | `item_comment` | `6a95c1f38b6633ef76f1fd7c` | Text |

---

### 🆕 ID Workflow WF-HR-13A / WF-HR-13B + ฟิลด์ที่เพิ่งเติม (P8-4 — สร้าง+publish 31 ส.ค. 2569 · **ยังไม่ live-fire**)

| workflow | processId | trigger | offset | executeTime |
|---|---|---|---|---|
| **WF-HR-13A** เตือนสัญญาจ้างใกล้ครบกำหนด | `6a95c6b8730d20c5b79226ac` | `date_field` บน `hr_employment_contract.biz_contract_to` `6a8efd39353e1b0e4a507653` | **−30 วัน** | `10:00:00` (= **09:00 เวลาไทย** เพราะ tenant ใช้ UTC+8) |
| **WF-HR-13B** เตือนครบกำหนดทดลองงาน | `6a95c701e6605c4b130752aa` | `date_field` บน `hr_employee.probation_end_date` `6a8efa78353e1b0e4a5075e3` | **−14 วัน** | `10:00:00` |

**node ของ 13A:** `gate` `6a95c6d2730d20c5b7922792` (branch 2 OR group) · `get_emp` `6a95c6d2730d20c5b7922793` (get_single) · `notify` `6a95c6d2730d20c5b7922794` · `mark_done` `6a95c6d2730d20c5b7922795`
**node ของ 13B:** `gate` `6a95c718730d20c5b7922934` · `notify` `6a95c718730d20c5b7922935` · `mark_done` `6a95c718730d20c5b7922936`

🔴 **ลำดับ node ต่างจากสเปทเจตนา:** แจ้งเตือน **ก่อน** ตั้งธง — ถ้าแจ้งเตือนล้ม (เช่น `supervisor_user` ว่าง) แล้วตั้งธงไปก่อน การแจ้งเตือนจะหายถาวร · เรียงแบบนี้กรณีแย่สุดคือแจ้งซ้ำ
✅ **gate กันค่าว่างตามบทเรียน D-19 ตั้งแต่แรก** — 2 OR group: `สถานะ = ...` AND `ธง ≠ "1"` (`cid 9`+`cid 10`) OR `สถานะ = ...` AND `ธง is empty` (`cid 9`+`cid 8`) — อ่านกลับด้วย `hap workflow structure` ยืนยันแล้วทั้งสองตัว
⚠️ **ผู้รับ = `supervisor_user` เท่านั้น** (`hr_employee.supervisor_user` `6a8efa78353e1b0e4a5075d7`) · ฝั่ง HR ตามสเปกยังไม่ได้ใส่ เพราะยังไม่มี role/บัญชี HR ที่ resolve ได้ (**P0-2**)
🔴 **get_single ของ 13A ใช้ pattern reverse-relation ตามข้อ 16** — กรอง `hr_employee.<reverse ของ biz_employee>` `6a8efd39353e1b0e4a507650` เทียบ `trigger.rowid` · MCP แปลง `op:"contains"` บนฟิลด์ Relation ออกมาเป็น **`conditionId 33`**

#### ฟิลด์ที่เติมเพิ่มให้ `hr_leave_type` (ปลดบล็อก WF-HR-14)

| ฟิลด์ | alias | fieldId | type | หมายเหตุ |
|---|---|---|---|---|
| นโยบายการยกยอด | `hr_carry_policy` | `6a95c73b353e1b0e4a515b62` | Dropdown | inline 3 ค่าลอกจาก `OS_HR_CARRY_POLICY` `52b15a75-76fc-457b-a72d-e6b7f2136243` · FRS เคยระบุว่า 🔴 ยังไม่ได้สร้าง · **seed 6/6 แล้วตาม `carry_cap_days` — รอ HR ยืนยัน** |

---

### 🆕 ID Workflow WF-HR-16 / WF-HR-17 / WF-HR-18 (P7-3 · P7-4 · P7-6 — สร้าง+publish+**ยิงจริงผ่านครบ** 31 ส.ค. 2569)

| workflow | processId | trigger | inner processId |
|---|---|---|---|
| **WF-HR-17** สร้างทะเบียนพนักงานจากผู้สมัครที่ถูกจ้าง | `6a95fc61730d20c5b7935ff6` | `worksheet_event` update บน `hr_candidate` · `triggerFields=[cand_stage]` | — |
| **WF-HR-18** เปิดรอบประเมิน สร้างแบบประเมินทุกคน | `6a96016ee6605c4b1308f052` | `worksheet_event` update บน `hr_appraisal_cycle` · `triggerFields=[cycle_open_flag]` | `6a960190e6605c4b1308f16a` |
| **WF-HR-16** เลื่อนขั้นตอนผู้สมัคร + แจ้งนัดสัมภาษณ์ | `6a960289730d20c5b79386a9` | `worksheet_event` update บน `hr_candidate` · `triggerFields=[cand_stage]` | `6a9602a9e6605c4b1308f927` |

> 🔴 **WF-HR-16 และ WF-HR-17 ผูก trigger กับฟิลด์เดียวกัน (`cand_stage`)** — ทั้งคู่ยิงพร้อมกันทุกครั้งที่ขั้นตอนเปลี่ยน แล้วแยกกันด้วย branch ของตัวเอง (17 รับเฉพาะ `Hired` · 16 รับเฉพาะ `Interview 1/2`) · ทดสอบแล้วไม่ชนกัน แต่ **ถ้าจะเพิ่ม workflow ที่ผูก `cand_stage` อีกต้องระวังลำดับ**

**node ของ WF-HR-17:** `gate` `6a95fc96730d20c5b7936178` · `mark_flag` `6a95fc96730d20c5b7936179` · `gen_code` `6a95fc96730d20c5b793617a` (code/JS) · `make_emp` `6a95fd07730d20c5b793655d` · `link_back` `6a95fd07730d20c5b793655e` · `notify_hr` `6a95fc96730d20c5b793617d`
**node ของ WF-HR-18:** `gate` `6a960190e6605c4b1308f15c` · `find_emp` `6a960190e6605c4b1308f15d` · `loop_emp` `6a960190e6605c4b1308f15e` · `count_apr` `6a960190e6605c4b1308f15f` · `write_count` `6a960190e6605c4b1308f160`
**node ของ WF-HR-16:** `stamp` `6a9602a9e6605c4b1308f91a` · `gate` `6a9602a9e6605c4b1308f91b` · `find_itv` `6a9602a9e6605c4b1308f91c` · `loop_itv` `6a9602a9e6605c4b1308f91d`

#### 🔴 ค่าที่ยังไม่ใช่ของจริง — ต้องให้คนตัดสิน

| จุด | ค่าที่ workflow เขียนตอนนี้ | ทำไม |
|---|---|---|
| `hr_employee.emp_code` (WF-HR-17) | **`NEW-<yyyymmddHHMMSS>`** สร้างจาก code node | **ยังไม่มีกฎการออกเลขที่พนักงาน** — ไม่มีตารางกฎเลขที่ของ HR และ FRS ไม่ได้ระบุรูปแบบ · เลือกค่าที่ **เห็นชัดว่าเป็นของชั่วคราว** แทนการเดารูปแบบเลขพนักงานจริง · การแจ้งเตือน node สุดท้ายบอก HR ให้แก้เป็นเลขจริงเป็นข้อแรก |
| `hr_employee.emp_user` | **ว่าง** | workflow หา userId จากชื่อไม่ได้ (`find_member` ถูกถอด) · ฟิลด์ตั้ง `required` ไว้แต่ **workflow เขียนผ่านได้** (`00-HAP-Working-Guide.md` §2 ข้อ 29) ⇒ record เกิดขึ้นจริงแต่พนักงานยังยื่นใบลาไม่ได้จนกว่า HR จะผูกบัญชี |

#### หลักฐานการยิงจริง

| workflow | หลักฐาน |
|---|---|
| **WF-HR-17** | เปลี่ยน `cand_stage` → `Hired` → เกิด `hr_employee` 1 แถว · `_createdBy`/`_updatedBy` = **`user-workflow`** · `first_name_th`/`last_name_th` แยกจากชื่อเต็มถูกต้อง · `emp_status` = `Probation` · `hired_employee` บนผู้สมัครชี้กลับด้วย **sid = rowid จริง** ไม่ใช่ `已删除` · **ยิงซ้ำ (Offered→Hired) ไม่เกิดพนักงานคนที่สอง** ✅ AC-17 |
| **WF-HR-18** | ตั้ง `cycle_open_flag` = 1 → เกิด `hr_appraisal` **2 แถว = จำนวนพนักงานที่เข้าเงื่อนไข** · `_createdBy` = `user-workflow` · `apr_cycle`/`apr_employee` sid ถูกต้องทั้งคู่ · `appraisal_status` = `Self assessment` · `generated_count` = 2 · **ยิงซ้ำไม่เพิ่มแถว** ✅ |
| **WF-HR-16** | เปลี่ยน `cand_stage` → `Interview 1` → นัดสัมภาษณ์ 2 นัดที่ `notified_flag` **ว่าง** ถูกตั้งเป็น `1` ทั้งคู่ · `stage_changed_at` ถูกประทับเวลา · เพิ่มนัดที่ 3 (ยังไม่แจ้ง) แล้วเปลี่ยนเป็น `Interview 2` → นัดที่ 3 ถูกแจ้งและตั้งธง ส่วน 1–2 คงเป็น 1 ✅ |

> ✅ **ทั้ง 3 ตัวใส่ gate กันค่าว่างตามบทเรียน D-19 ตั้งแต่แรก** — และ WF-HR-16 ได้ทดสอบเส้นทางค่าว่างจริง เพราะ `notified_flag` ของนัดที่สร้างใหม่**ว่าง** (ไม่ใช่ 0) ตามที่ `defaultValue` ไม่ persist

---

### 🆕 ID View / Chart / Custom page ชุด Demo (HR/DEMO-VIEWS — สร้าง+ตรวจสอบ 6 ก.ย. 2569)

> วิธีตรวจซ้ำ: `hap --json worksheet view info <ws_id> <view_id>` และ `hap --json worksheet chart get <report_id>`
> 🔴 **ห้ามใช้ `hap worksheet chart list` เพื่อตรวจ** — บน worksheet ที่ยังไม่มี chart คำสั่งนี้ **สร้าง** chart ขยะให้ 2 อัน (ดู `00-HAP-Working-Guide.md` §8.3)

#### View (15 รายการ — ของใหม่รอบนี้ทั้งหมด)

| worksheet | view | viewId | viewType | นับแถวจริง |
|---|---|---|---|---|
| `hr_candidate` | กระดานสรรหา (Kanban) | `6a9cea7ef363582dd3792c51` | 1 kanban (`cand_stage`) | — (API นับไม่ได้) |
| `hr_employee` | ผังองค์กร (Org Chart) | `6a9cea9df363582dd3792c53` | 2 hierarchy (`supervisor`) | 2 node ระดับบน |
| `hr_employee` | ทำเนียบพนักงาน (การ์ด) | `6a9cea9df363582dd3792c55` | 3 gallery | 10 |
| `hr_employee` | พนักงานทดลองงาน | `6a9cea9d4a22ad87b7279fa8` | 0 table | 1 |
| `hr_leave_request` | ปฏิทินการลา | `6a9ceaa7f363582dd3792c57` | 4 calendar | 14 |
| `hr_leave_request` | กระดานสถานะใบลา | `6a9ceaa74a73a3142151a125` | 1 kanban (`leave_status`) | — |
| `hr_leave_request` | รออนุมัติ | `6a9ceaa74a73a3142151a127` | 0 table | 4 |
| `hr_employment_contract` | ไทม์ไลน์สัญญาจ้าง (Gantt) | `6a9ceab14720c515252ab4a7` | 5 gantt | — |
| `hr_employment_contract` | สัญญาที่มีกำหนดสิ้นสุด | `6a9ceab14720c515252ab4a9` | 0 table | 2 |
| `hr_attendance` | ปฏิทินลงเวลา | `6a9ceab94720c515252ab4ab` | 4 calendar | 41 |
| `hr_attendance` | มาสาย / ขาดงาน | `6a9ceae1f363582dd3792c5b` | 0 table | 4 |
| `hr_ot_request` | กระดานสถานะใบขอ OT | `6a9ceaea4720c515252ab4ad` | 1 kanban (`hr_ot_status`) | — |
| `hr_ot_request` | OT ที่อนุมัติแล้ว | `6a9ceaea4a73a3142151a129` | 0 table | 2 |
| `hr_appraisal` | กระดานความคืบหน้าการประเมิน | `6a9ceaf54720c515252ab4af` | 1 kanban (`appraisal_status`) | — |
| `hr_appraisal` | ประเมินเสร็จแล้ว (เรียงคะแนน) | `6a9ceaf54720c515252ab4b1` | 0 table | 4 |
| `hr_payslip` | สลิปงวด ส.ค. 2569 | `6a9ceafaf363582dd3792c5d` | 0 table | 8 |
| `hr_leave_balance` | สิทธิคงเหลือรายคน | `6a9ceb014720c515252ab4b3` | 0 table | 36 |
| `hr_welfare_balance` | วงเงินสวัสดิการคงเหลือ | `6a9ceb074a73a3142151a12b` | 0 table | 14 |

#### Chart (10 รายการ)

| worksheet | chart | reportId | reportType | ค่าที่วัด |
|---|---|---|---|---|
| `hr_employee` | จำนวนพนักงานทั้งหมด (KPI) | `6a9ceca140cf7aec60e9eddf` | 10 number | COUNT record |
| `hr_employee` | จำนวนพนักงานตามระดับตำแหน่ง | `6a9ceb0e40cf7aec60e9eddb` | 1 column | COUNT × `job_level` |
| `hr_payslip` | ยอดจ่ายสุทธิรวมทั้งงวด | `6a9ceb57720a3fbb2b182cab` | 10 number | SUM `biz_net_pay` |
| `hr_leave_request` | สัดส่วนใบลาตามสถานะ | `6a9ceb44720a3fbb2b182ca6` | 3 pie | COUNT × `leave_status` |
| `hr_leave_request` | วันลาสะสมตามประเภทการลา | `6a9ceb4a720a3fbb2b182ca8` | 1 column | SUM วัน × ประเภทการลา |
| `hr_attendance` | สถิติการมาทำงานรายวัน | `6a9ceb50720a3fbb2b182ca9` | 1 column | COUNT × `hr_att_status` |
| `hr_ot_request` | ชั่วโมง OT รวมตามพนักงาน | `6a9cec9ee29effb3d6a57a6b` | 16 ranking | SUM `hr_ot_hours` × พนักงาน |
| `hr_candidate` | ผู้สมัครตามขั้นตอนการคัดเลือก | `6a9ceb3e40cf7aec60e9eddd` | 6 funnel | COUNT × `cand_stage` |
| `hr_appraisal` | คะแนนประเมินเฉลี่ยตามรอบ | `6a9ceca240cf7aec60e9ede0` | 1 column | AVG `final_score` × รอบ |
| `hr_welfare_balance` | วงเงินสวัสดิการ ใช้ไป vs คงเหลือ | `6a9cec9fe29effb3d6a57a6c` | 1 column | SUM `used_amount` / `remaining_amount` × สวัสดิการ |

#### Section / Custom page

| object | id | หมายเหตุ |
|---|---|---|
| section `HR-07 Dashboard` | `6a9cece1db26b712423ce585` | child section ใต้ `ทรัพยากรบุคคลฯ (HR)` = `6a8ee668e56d2e6eb7bd6cb3` |
| custom page `แดชบอร์ด HR` | `6a9cece5db26b712423ce586` | version 1 · 10 component (chart ทั้งหมดข้างบน) · layout grid 48 คอลัมน์ 2 ชิ้น/แถว |

#### ⚠️ แก้จุดผิดที่พบระหว่างตรวจสอบ (ทั้งหมดแก้แล้ว)

| จุดผิด | อาการ | แก้อย่างไร |
|---|---|---|
| view 3 ตัวใช้ option key ที่ไม่มีจริง | คืน 0 แถวเงียบ ๆ | `view update --edit-attrs filters` ด้วย key จาก `worksheet fields --raw` |
| view 2 ตัวเขียนเงื่อนไข "Late" + "Absent" เป็นสอง condition | ถูก AND ⇒ 0 แถว | รวมเป็น condition เดียว `filterType 2` หลายค่าใน `values` → 4 แถว |
| chart `จำนวนพนักงานตามระดับตำแหน่ง` ชี้ `filter.viewId` = `…7185c4` ซึ่งไม่มีจริง | scope ผิด | `chart update` เป็น `…7185c5` (view "ทั้งหมด" จริง) |
| chart ขยะ `Add new…` 10 อัน จากการเรียก `chart list` | รกหน้าจอ | `chart delete -y` ทั้งหมด |

---

### 🆕 ID Workflow WF-HR-07 (P5-8 — สร้าง+publish+**ยิงจริงผ่านแบบแยกแยะได้** 6 ก.ย. 2569)

| object | id | หมายเหตุ |
|---|---|---|
| **Main** WF-HR-07 สร้างสลิปทั้งงวด | `6a9cfbd42fe3e8d6b3b6a47f` | v1 · trigger = `worksheet_event` update บน `hr_pay_period` · triggerFields = `[biz_period_status]` |
| **Inner** WF-HR-07 inner — สร้างสลิปรายคน | `6a9cfc1e8475f61d4c71f668` | 🔴 **ต้อง publish ก่อน main เสมอ** ไม่งั้น main จะได้ `NodeAppIsNull` (`../../shared/00-HAP-Working-Guide.md` §10.1) |

#### node ตามลำดับ

| alias | nodeId | ชนิด | ทำอะไร |
|---|---|---|---|
| `trigger` | `6a9cfbd42fe3e8d6b3b6a47c` | trigger | งวดจ่ายเปลี่ยน `biz_period_status` |
| `find_slips` | `6a9cfbdf8475f61d4c71f503` | get_multiple | หาสลิปที่ผูกกับงวดนี้อยู่แล้ว (`biz_pay_period` = trigger › rowid) |
| `cnt_slips` | `6a9cfbdf8475f61d4c71f504` | rollup count | นับผลจาก `find_slips` |
| `gate` | `6a9cfbdf8475f61d4c71f505` | branch firstMatch | path `do_gen`: `biz_period_status` = **Calculating** **และ** `cnt_slips` **< 1** · path `skip_gen`: fallback ไม่ทำอะไร |
| `mark` | `6a9cfbf88475f61d4c71f593` | update_record | ตั้ง `biz_generated_flag` = 1 บนงวด |
| `find_emp` | `6a9cfbf88475f61d4c71f594` | get_multiple | `emp_status` **in** (Probation·Active·On leave) **และ** `hire_date` **≤** trigger › `biz_period_to` |
| `loop_emp` | `6a9cfc1e8475f61d4c71f666` | sub_process `sequential_each` | วนสร้างสลิปทีละคน · ส่งพารามิเตอร์ `period_rowid` เข้า inner |
| `cnt_emp` | `6a9cfc2f8475f61d4c71f8f9` | rollup count | นับพนักงานที่เข้าเงื่อนไข |
| `upd_head` | `6a9cfc2f8475f61d4c71f8fa` | update_record | เขียน `biz_headcount` กลับที่งวด |
| `notify` | `6a9cfc2f8475f61d4c71f8fb` | send_internal_notice | แจ้งผู้สั่งงาน (ชื่องวด · จำนวนราย · ช่วงวันที่) |

#### หลักฐานการยิงจริง (6 ก.ย. 2569)

สร้างงวดทดสอบ **`ZZTEST-WF07 มกราคม 2562`** ช่วง 2019-01-01 → 2019-01-31 แล้วเปลี่ยนสถานะเป็น Calculating:

| ตรวจ | ผลที่ได้ |
|---|---|
| จำนวนสลิปที่เกิด | **1 ใบ = EMP-0001 เท่านั้น** จากพนักงาน 10 คน ✅ **เป็นการทดสอบที่แยกแยะได้จริง** — อีก 9 คนเริ่มงานหลัง 2019-01-31 จึงถูกตัดออกถูกต้อง |
| `_createdBy` / `_updatedBy` ของสลิป | **`user-workflow`** ✅ |
| ค่าที่เขียน | `biz_payslip_status` = Draft · `biz_recalc_flag` = 1 · `biz_pay_period` sid ชี้งวดถูกต้อง · `biz_employee` sid ชี้ EMP-0001 |
| งวดหลังรัน | `biz_generated_flag` = 1 · `biz_headcount` = 1 ✅ |
| **ยิงซ้ำ** (Open → Calculating อีกครั้ง) | **สลิปยังเป็น 1 ใบ ไม่เพิ่ม** ✅ |
| เก็บกวาด | ลบสลิปทดสอบและงวดทดสอบแล้ว (soft delete) — กลับสู่ 1 งวด / 8 สลิป เท่าเดิม |

#### 🔴 จุดที่ **เบี่ยงจากสเปก** ใน `22-Workflow-Catalog-HR.md` (จงใจ พร้อมเหตุผล)

| สเปกเดิม | ที่ทำจริง | ทำไม |
|---|---|---|
| gate ด้วย `biz_generated_flag` **not equal to** 1 | gate ด้วย **จำนวนสลิปที่มีอยู่จริง < 1** | `≠` เป็นเท็จเมื่อธงว่าง = **D-19** และงวดที่ผู้ใช้เพิ่งสร้างจะมีธงว่างเสมอ · การนับไม่มีสถานะว่าง (`../../shared/00-HAP-Working-Guide.md` §10.3) · ยังตั้งธง = 1 ไว้ให้คนอ่านออก แต่ธงไม่ใช่ตัวตัดสิน |
| เงื่อนไข `termination_date` **is empty OR** ≥ `biz_period_from` | **ตัดออก** | OR ซ้อนใน AND ถูกแบนราบเงียบ ๆ (กับดักบัญชีข้อ 29) · พนักงานที่พ้นสภาพมี `emp_status` = Resigned/Terminated/Retired ซึ่ง filter `emp_status` ตัดออกอยู่แล้ว |

#### ⚠️ ที่ยังไม่ได้พิสูจน์

- **`biz_cost_center`** — workflow เขียนค่าจาก `sub_trigger › cost_center` แต่ **EMP-0001 ไม่มี cost_center** ⇒ ผลออกมาว่างเพราะต้นทางว่าง **ไม่ใช่เพราะ workflow ผิด** · ยังไม่มีหลักฐานว่า copy relation→relation ทำงาน — ต้องทดสอบกับพนักงานที่มี cost_center
- **`biz_recalc_flag` = 1 ตั้งใจให้ไปยิง WF-HR-08 ต่อ** ซึ่ง **ยังไม่ได้สร้าง** ⇒ ตอนนี้ธงถูกตั้งไว้เฉย ๆ ไม่มีอะไรมารับช่วง สลิปจึงยังเป็น Draft ยอด 0 ทุกใบ

---

### 🆕 ไอคอนของ worksheet ฝั่ง HR (HR/WS-ICONS — ตั้งครบ 37/37 เมื่อ 6 ก.ย. 2569)

> ก่อนหน้านี้ **32 ตารางใช้ `table` เหมือนกันหมด** + 5 ตารางใช้ `8_4_folder` ⇒ ไซด์บาร์แยกไม่ออกตอนนำเสนอ
> ตั้งผ่าน `hap worksheet update <ws_id> --icon <ชื่อ> -a <app_id>` · **ตรวจชื่อไอคอนด้วย HTTP 200 ก่อนยิงทุกตัว** และอ่าน `iconUrl` กลับมาเทียบทีละตาราง (วิธี + กับดักอยู่ใน `../../shared/00-HAP-Working-Guide.md` §11)
> ✅ ยืนยันแล้วว่า **ชื่อตาราง · `entityName` · `alias` · จำนวนฟิลด์ · จำนวน record ไม่เปลี่ยน** และ **ไอคอนไม่ซ้ำกันเลยทั้ง 37 ตัว**

| กลุ่ม | worksheet | worksheet_id | ไอคอน |
|---|---|---|---|
| HR-00 | การตั้งค่าโมดูลบุคคล | `6a8eebbd353e1b0e4a507477` | `sys_gear1_office` |
| HR-00 | วันหยุดประจำปี | `6a8eebf7353e1b0e4a5074b5` | `sys_4_1_calendar` |
| HR-00 | กะการทำงาน | `6a8eebf79762533b5b7184c5` | `sys_4_2_clock` |
| HR-00 | ประเภทการลา | `6a8eebf89762533b5b7184cf` | `sys_15_8_beach` |
| HR-00 | อัตราค่าล่วงเวลา | `6a8eebf88b6633ef76f129d6` | `sys_4_3_alarm_clock` |
| HR-00 | อัตราประกันสังคม | `6a8eebf8353e1b0e4a5074c1` | `sys_10_3_security_checked` |
| HR-00 | ขั้นบันไดภาษีเงินได้บุคคลธรรมดา | `6a8eebf8ae2a0e3743a0bcec` | `sys_percentage_finance` |
| HR-00 | ค่าลดหย่อนภาษี | `6a8eebf8353e1b0e4a5074cb` | `sys_coupon_finance` |
| HR-00 | กฎการอนุมัติของโมดูลบุคคล | `6a8eebf81378964f998499f8` | `sys_1_7_approval` |
| HR-00 | นโยบายสิทธิการลา | `6a8eebf88b6633ef76f129e1` | `sys_12_2_book` |
| HR-01 | ตำแหน่งงาน | `6a8ef9901378964f99849a6d` | `sys_8_3_briefcase` |
| HR-01 | ระดับพนักงาน | `6a8ef9909762533b5b71859a` | `sys_hierarchy_symbol` |
| HR-01 | ทะเบียนพนักงาน | `6a8efa5e9762533b5b7185c1` | `sys_1_10_people` |
| HR-01 | สัญญาจ้าง | `6a8efd1e9762533b5b718618` | `sys_signature_symbol` |
| HR-01 | เหตุการณ์การจ้าง | `6a8efd1e8b6633ef76f12ad4` | `sys_timeline_symbol` |
| HR-01 | ผู้ติดตามและผู้ใช้สิทธิลดหย่อน | `6a8efd1eae2a0e3743a0bd93` | `sys_6_1_user_group` |
| HR-01 | บัญชีธนาคารพนักงาน | `6a8efd1fae2a0e3743a0bd9d` | `sys_bank-statement_finance` |
| HR-02 | บันทึกลงเวลา | `6a8fcd67353e1b0e4a507d32` | `sys_todo_office` |
| HR-02 | ใบขออนุมัติล่วงเวลา | `6a8fcca48b6633ef76f13033` | `sys_money-time_symbol` |
| HR-03 | สิทธิและยอดคงเหลือการลา | `6a8f2dba353e1b0e4a507757` | `sys_balance_activity` |
| HR-03 | ใบลา | `6a8f2dbaae2a0e3743a0beaa` | `sys_stay-home_people` |
| HR-03 | รายการเคลื่อนไหวสิทธิลา | `6a8f2dba9762533b5b718675` | `sys_transactions_symbol` |
| HR-04 | องค์ประกอบค่าจ้าง | `6a8ff2868b6633ef76f13871` | `sys_1_4_calculator` |
| HR-04 | งวดจ่ายเงินเดือน | `6a8ff2878b6633ef76f1387b` | `sys_bill_finance` |
| HR-04 | โครงสร้างเงินเดือน | `6a8ff287353e1b0e4a508550` | `sys_chart-bar_finance` |
| HR-04 | สลิปเงินเดือน | `6a904c85353e1b0e4a50ba05` | `sys_cheque_office` |
| HR-04 | รายการในสลิปเงินเดือน | `6a904c858b6633ef76f16a0b` | `sys_bullet-list_office` |
| HR-04 | การยื่นภาษีเงินได้หัก ณ ที่จ่าย (เงินเดือน) | `6a904e72ae2a0e3743a0fd06` | `sys_1_6_document` |
| HR-04 | หนังสือรับรองการหักภาษี ณ ที่จ่าย | `6a904e73353e1b0e4a50ba83` | `sys_certificate_object` |
| HR-05 | ใบขออัตรากำลัง | `6a95c1349762533b5b7250b5` | `sys_1_5_create_new` |
| HR-05 | ผู้สมัคร | `6a95c137ae2a0e3743a1887f` | `sys_search_people` |
| HR-05 | การสัมภาษณ์ | `6a95c1399762533b5b7250c1` | `sys_interview_people` |
| HR-05 | รอบประเมินผล | `6a95c13b1378964f99857909` | `sys_2_3_statistics` |
| HR-05 | แบบประเมินผล | `6a95c13d1378964f99857913` | `sys_form_symbol` |
| HR-05 | รายการประเมิน | `6a95c140353e1b0e4a515ae6` | `sys_10_5_star` |
| HR-06 | สวัสดิการ | `6a95c0db8b6633ef76f1fcf9` | `sys_14_1_gift` |
| HR-06 | วงเงินสวัสดิการคงเหลือ | `6a95c0de9762533b5b7250a1` | `sys_wallet_finance` |

**คืนค่าเดิมถ้าต้องการ:** ทุกตารางเดิมเป็น `table` ยกเว้น 5 ตารางที่เป็น `8_4_folder` (`สัญญาจ้าง` · `เหตุการณ์การจ้าง` · `ผู้ติดตามและผู้ใช้สิทธิลดหย่อน` · `บัญชีธนาคารพนักงาน` · `การตั้งค่าโมดูลบุคคล`)

#### ไอคอนของกลุ่ม (section) ฝั่ง HR — ตั้งครบ 8/8 เมื่อ 6 ก.ย. 2569

> 🔴 **CLI ทำไม่ได้** — `hap app edit-section` มีแค่ `--name` และใช้กับ child section ไม่ได้เลย (ตอบ `Error: The app does not exist` ซึ่งชี้ผิดทาง)
> ทางที่ใช้จริง: `POST /wwwapi/HomeApp/UpdateAppSection` `{appId, appSectionId, appSectionName, icon}` จาก console ของแท็บที่ล็อกอินอยู่ · **ต้องส่งชื่อเดิมกลับไปด้วย** และ **ห้ามส่ง `icon` กับ `iconUrl` พร้อมกัน** (จะได้ `data:false` = ไม่ทำอะไร) · รายละเอียดใน `../../shared/00-HAP-Working-Guide.md` §11.5

| กลุ่ม | sectionId | ไอคอน |
|---|---|---|
| HR-00 Configuration | `6a8ee66ce56d2e6eb7bd6cb4` | `sys_folder-settings_office` |
| HR-01 Master Data | `6a8ee66ce56d2e6eb7bd6cb5` | `sys_folder-user_office` |
| HR-02 Time and Attendance | `6a8ee66ce56d2e6eb7bd6cb6` | `sys_folder-check_office` |
| HR-03 Leave | `6a8ee66ce56d2e6eb7bd6cb7` | `sys_folder-bookmark_office` |
| HR-04 Payroll | `6a8ee66ce56d2e6eb7bd6cb8` | `sys_folder-money_office` |
| HR-05 Talent (Recruitment, Performance, Training) | `6a8ee66ce56d2e6eb7bd6cb9` | `sys_folder-starred_office` |
| HR-06 Welfare and Claims | `6a8ee66ce56d2e6eb7bd6cba` | `sys_folder-shared_office` |
| HR-07 Dashboard | `6a9cece1db26b712423ce585` | `sys_folder-chart-bar_office` |

**หลักการที่ใช้:** กลุ่ม = ไอคอนตระกูล `sys_folder-*_office` (โฟลเดอร์) · worksheet = ไอคอนรูปธรรม ⇒ แยก "กล่อง" กับ "ของในกล่อง" ได้ด้วยสายตา
**ค่าเดิมก่อนแก้:** `HR-00` = `sys_11_2_maintenance_line` · อีก 7 กลุ่ม = `table`
✅ ตรวจหลังยิง: ชื่อกลุ่มครบถูกต้องทั้ง 8 · จำนวน worksheet ในแต่ละกลุ่มไม่เปลี่ยน (10 · 7 · 2 · 3 · 7 · 6 · 2 · 0) · เปิดหน้าจอดูด้วยตาแล้ว

---

### 🆕 ปุ่ม Custom Action ฝั่ง HR (HR/ACTION-BUTTONS — สร้าง 4 ปุ่มใหม่ 6 ก.ย. 2569)

> เดิมมีปุ่มแค่ **3 ปุ่มใน 2 ตาราง** จาก 37 ตาราง · ตอนนี้ **7 ปุ่มใน 5 ตาราง**
> ปุ่มทุกปุ่มมี **workflow ผูกติดมา 1 ตัว** — วิธีสร้าง + กับดักอยู่ใน `../../shared/00-HAP-Working-Guide.md` §12

| worksheet | ปุ่ม | btnId | processId ของปุ่ม | ทำอะไร | โผล่เมื่อ |
|---|---|---|---|---|---|
| `hr_pay_period` | **สร้างสลิปทั้งงวด** | `6a9d0e754a22ad87b727a2a7` | `6a9d0e75d91d10186d8bc22b` | ตั้ง `biz_period_status` = Calculating ⇒ **WF-HR-07 รับช่วงสร้างสลิปให้ทุกคน** | สถานะ = Open |
| `hr_job_requisition` | **ส่งขออนุมัติอัตรากำลัง** | `6a9d0f8df363582dd3792f32` | `6a9d0f8d2fe3e8d6b3b711a8` | `req_status` → Pending supervisor · `req_submitted_flag` = 1 | สถานะ = Draft |
| `hr_appraisal` | **ส่งแบบประเมินให้หัวหน้า** | `6a9d0f904a22ad87b727a2a9` | `6a9d0f902fe3e8d6b3b711cc` | `appraisal_status` → Supervisor review · ประทับ `apr_submitted_at` | สถานะ = Self assessment |
| `hr_candidate` | **ปฏิเสธผู้สมัคร** | `6a9d0f934a73a3142151a3f3` | `6a9d0f932fe3e8d6b3b711f8` | `cand_stage` → Rejected | ขั้นตอน ∈ Applied · Screening · Interview 1 · Interview 2 · Offered |

**ปุ่มเดิมที่มีอยู่ก่อนแล้ว:** `hr_leave_request` → ส่งคำขอ `6a8fb8391378964f9984a0b3` · ยกเลิกใบลา `6a8fb839353e1b0e4a507c36` · `hr_ot_request` → ส่งขอล่วงเวลา `6a8fde0aae2a0e3743a0c62f`

#### หลักฐานการยิงจริง (กดบนหน้าจอจริง)

| ปุ่ม | ผลที่ได้ |
|---|---|
| **สร้างสลิปทั้งงวด** | สร้างงวดทดสอบ `ZZTEST-BTN มกราคม 2562` (2019-01-01→31) สถานะ Open → **ปุ่มโผล่** → กด → กล่องยืนยันภาษาไทยขึ้นถูกต้อง → กดยืนยัน → สถานะเปลี่ยนเป็น **Calculating** → **WF-HR-07 ยิงต่อเอง** → เกิดสลิป **1 ใบ = EMP-0001 เท่านั้น** (กรอง `hire_date ≤ วันสิ้นงวด` ถูกต้องจากพนักงาน 10 คน) · `biz_generated_flag`=1 · `biz_headcount`=1 · `_createdBy`/`_updatedBy` ของสลิป = **`user-workflow`** ✅ **พิสูจน์ปุ่ม → workflow → workflow ต่อกันเป็นทอด** · ลบข้อมูลทดสอบครบแล้ว |
| **ส่งแบบประเมินให้หัวหน้า** | กดบนแบบประเมินของ TEST-EMP1 → สถานะ **Self assessment → Supervisor review** · `apr_submitted_at` ถูกประทับ `2026-09-06 15:02:31` · `_updatedBy` = **`user-workflow`** ✅ · **คืนค่าเดิมแล้ว** (Self assessment · ล้างวันที่ส่ง) |
| **ส่งขออนุมัติอัตรากำลัง** · **ปฏิเสธผู้สมัคร** | ⬜ **ยังไม่ได้กดจริง** — ตรวจแล้วว่า config ปุ่มถูก (`showType 2` · `isAllView 1` · `enableConfirm` · filter ตรง) และ workflow `enabled=True publishStatus=2` พร้อม node เขียนฟิลด์ถูกตัว แต่ **ยังไม่มีหลักฐานการกดจริง** |

✅ ตรวจหลังทดสอบ: งวดจ่าย 1 · สลิป 8 · ผู้สมัคร 6 · แบบประเมิน 10 — **กลับสู่ baseline ครบทุกตาราง**

---

### 🆕 P6-2 / P6-3 โมดูลเบิกสวัสดิการ (HR/P6-CLAIM — 6 ก.ย. 2569)

**กลุ่ม:** HR-06 สวัสดิการ (`6a8ee66ce56d2e6eb7bd6cba`)

#### `hr_claim` — ใบเบิกสวัสดิการ · `6a9d19c34720c515252ab8b1` · ไอคอน `sys_bill_finance`

| # | ฟิลด์ | controlId | type | หมายเหตุ |
|---|---|---|---|---|
| 1 | เลขที่ใบเบิก | `6a9d19c5f363582dd3793038` | 2 Text | ฟิลด์ชื่อ record |
| 2 | พนักงาน | `6a9d19c5f363582dd3793039` | 29 Relation | → `hr_employee` |
| 3 | สวัสดิการ | `6a9d19c5f363582dd379303b` | 29 Relation | → `hr_welfare_scheme` |
| 4 | ผู้ใช้สิทธิ (ตนเอง/ผู้ติดตาม) | `6a9d19c5f363582dd379303d` | 29 Relation | → `hr_dependent` |
| 5 | วันที่เกิดค่าใช้จ่าย | `6a9d19c5f363582dd379303f` | 15 Date | `showformat: DD/MM/YYYY` ตั้งตั้งแต่ตอนสร้าง |
| 6 | วงเงินคงเหลือขณะยื่น | `6a9d19c5f363582dd3793040` | 6 Number | snapshot |
| 7 | สถานะใบเบิก | `6a9d19c5f363582dd3793041` | 11 Dropdown | 6 ค่า (ดูตารางล่าง) |
| 8 | ผู้อนุมัติที่ระบบกำหนด | `6a9d19c5f363582dd3793042` | 26 Collaborator | |
| 9 | (ระบบ) ขั้นการอนุมัติ | `6a9d19c5f363582dd3793043` | 6 Number | |
| 10 | วันที่อนุมัติ | `6a9d19c5f363582dd3793044` | 16 DateTime | `DD/MM/YYYY HH:mm` |
| 11 | เหตุผลที่ไม่อนุมัติ | `6a9d19c5f363582dd3793045` | 2 Text | |
| 12 | หลักฐานประกอบ | `6a9d19c5f363582dd3793046` | 14 Attachment | |
| 13 | (ระบบ) ส่งอนุมัติแล้ว | `6a9d19c5f363582dd3793047` | 6 Number | flag 0/1 |
| 14 | (ระบบ) ตัดวงเงินแล้ว | `6a9d19c5f363582dd3793048` | 6 Number | flag 0/1 |
| 15 | (ระบบ) ส่งเข้าบัญชีแล้ว | `6a9d19c5f363582dd3793049` | 6 Number | flag 0/1 |
| 16 | รายการค่าใช้จ่าย | `6a9d1a084a22ad87b727a373` | 29 Relation | ⇄ `…a374` บน `hr_claim_line` · `showtype 5` (แสดงเป็นตารางในฟอร์ม) |
| 17 | **จำนวนเงินที่ขอเบิก** | `6a9d1a154a22ad87b727a37a` | **37 Rollup** | **SUM** (`enumDefault: 5`) ของ `…a357` ผ่าน `$…a373$` |

**option key ของ `สถานะใบเบิก` (`…3041`)**

| ค่า | key |
|---|---|
| Draft | `eb035798-c4f3-43e5-b6bb-f620a6acf490` |
| Pending supervisor | `c73164e8-0755-43c6-a584-d574ca5efeec` |
| Pending HR | `dd87c434-8db0-463e-94e9-d3b72bd741c3` |
| Approved | `aa4bdb96-20c3-4230-839c-1945161791c5` |
| Rejected | `2a165bf9-a0ea-4ceb-a1dc-d0cb26257b91` |
| Cancelled | `d5352133-8c72-41a2-b481-4758f6df2451` |

#### `hr_claim_line` — รายการในใบเบิก · `6a9d19e24a22ad87b727a348` · ไอคอน `sys_bullet-list_office`

| # | ฟิลด์ | controlId | type |
|---|---|---|---|
| 1 | รายการค่าใช้จ่าย | `6a9d19e44a22ad87b727a352` | 2 Text (ชื่อ record) |
| 2 | ลำดับที่ | `6a9d19e44a22ad87b727a355` | 6 Number |
| 3 | ประเภทค่าใช้จ่าย | `6a9d19e44a22ad87b727a356` | 9 SingleSelect (6 ค่า) |
| 4 | จำนวนเงิน | `6a9d19e44a22ad87b727a357` | 6 Number ← **แหล่งของ Rollup** |
| 5 | เลขที่ใบเสร็จ | `6a9d19e44a22ad87b727a358` | 2 Text |
| 6 | ชื่อผู้ให้บริการ/ร้านค้า | `6a9d19e44a22ad87b727a359` | 2 Text |
| 7 | ใบเสร็จแนบ | `6a9d19e44a22ad87b727a35a` | 14 Attachment |
| 8 | ใบเบิกสวัสดิการ | `6a9d1a084a22ad87b727a374` | 29 Relation → `hr_claim` · **required** |

**option key ของ `ประเภทค่าใช้จ่าย` (`…a356`)**

| ค่า | key |
|---|---|
| ค่ารักษาพยาบาล | `46ee916c-9bc6-44fc-9640-828ba04f95ba` |
| ค่าทันตกรรม | `d6b92cc2-8ad2-4554-9179-aaf8f3172fa7` |
| ค่าตัดแว่นสายตา | `1af026a0-4c3b-4418-8df1-3922a2cec3e0` |
| ค่าตรวจสุขภาพ | `de84fbde-b92b-488a-ae28-4792e9612f1e` |
| ค่าเล่าเรียนบุตร | `8bbb57f4-4287-4f9d-bcc0-e20ad02844fc` |
| อื่น ๆ | `beecd4e1-aca8-43c4-9c3a-a9b30277233b` |

> ⚠️ relation `ใบเบิก` (`…a353`) ที่สร้างพร้อม worksheet **ถูกลบทิ้งแล้ว** เพราะคู่ตรงข้ามไม่ถูกสร้างจริงและ rollup ใช้ไม่ได้ — เหตุผลเต็มอยู่ใน `../../shared/00-HAP-Working-Guide.md` §14.4

#### View ของ `hr_claim`

| viewId | viewType | ชื่อ | ตรวจแล้ว |
|---|---|---|---|
| `6a9d19c34720c515252ab8b5` | 0 sheet | All | — |
| `6a9d1cc6f363582dd3793179` | 1 board | บอร์ดสถานะใบเบิก | จัดกลุ่มด้วย `…3041` |
| `6a9d1cc74a73a3142151a53c` | 0 sheet | รอดำเนินการอนุมัติ | ✅ คืน 1 แถว = CLM-2569-0002 |
| `6a9d1cc8f363582dd379317b` | 0 sheet | อนุมัติแล้ว | ✅ คืน 1 แถว = CLM-2569-0003 |
| `6a9d1cca4a22ad87b727a3f3` | 4 calendar | ปฏิทินวันที่เกิดค่าใช้จ่าย | begindate = `…303f` |

#### ข้อมูล demo + หลักฐาน Rollup ทำงานจริง

| เลขที่ | rowid | พนักงาน | สวัสดิการ | สถานะ | บรรทัด | **Rollup ที่อ่านกลับมา** |
|---|---|---|---|---|---|---|
| CLM-2569-0001 | `bfcf68d3-953e-45be-9062-2dfb70f2202a` | EMP-0005 | ค่าทันตกรรม | Draft | 1,200 + 300 | **1500.0000** ✅ |
| CLM-2569-0002 | `af44d1e8-5788-4286-b7d1-7dedc8fa80ad` | EMP-0003 | ค่ารักษาพยาบาล (ผู้ป่วยนอก) | Pending supervisor | 2,400 | **2400.0000** ✅ |
| CLM-2569-0003 | `a1f32eb2-bd8f-47ee-8de6-2fd7d3b788ec` | EMP-0008 | ค่าตัดแว่นสายตา | Approved | 2,800 | **2800.0000** ✅ |

**CLM-2569-0001 คือเคสตัดสิน** — มี 2 บรรทัดค่าไม่เท่ากัน ⇒ แยก SUM (1,500) ออกจาก AVG (750) ได้ ตอนแรกอ่านได้ 750 จึงรู้ว่า `enumDefault: 1` = AVG ไม่ใช่ SUM

---

### 🆕 P6-4 Business Rules + Lookup ของใบเบิก (HR/P6-RULES — 6 ก.ย. 2569)

#### ฟิลด์ Lookup ที่เพิ่มบน `hr_claim` (ทางแก้ข้อจำกัด "Business Rule อ้าง relation field ไม่ได้")

| ฟิลด์ | controlId | type | ดึงจาก | ค่าที่อ่านได้จริง |
|---|---|---|---|---|
| (ระบบ) วงเงินสูงสุดต่อครั้ง | `6a9d206e4a73a3142151a543` | 30 Lookup | `hr_welfare_scheme.max_per_claim` `6a95c10c353e1b0e4a515a9b` ผ่าน `$…303b$` | 1500.00 / 3000.00 / 3000.00 ✅ |
| (ระบบ) ต้องแนบใบเสร็จ | `6a9d206e4a73a3142151a544` | 30 Lookup | `hr_welfare_scheme.require_receipt` `6a95c10c353e1b0e4a515a9c` ผ่าน `$…303b$` | 1 ทั้ง 3 ใบ ✅ |

⇒ `hr_claim` ตอนนี้มี **19 ฟิลด์**

#### Business Rules ของ `hr_claim` — สร้างครบ 4 กฎผ่าน `hap worksheet save-rule`

| # | ruleId | type | เงื่อนไข | ผล |
|---|---|---|---|---|
| BR-19.1 | `6a9d20fd4a22ad87b727a403` | 1 validate (`checkType 1`) | `วงเงินคงเหลือขณะยื่น` ไม่ว่าง **และ** Rollup > `วงเงินคงเหลือขณะยื่น` (dynamicSource) | บล็อก "จำนวนเงินที่ขอเบิกเกินวงเงินคงเหลือของสวัสดิการนี้" |
| BR-19.2 | `6a9d20c04720c515252ab959` | 1 validate (`checkType 1`) | Lookup วงเงินสูงสุดต่อครั้ง ไม่ว่าง **และ** Rollup > Lookup (dynamicSource) | บล็อก "จำนวนเงินที่ขอเบิกเกินวงเงินสูงสุดต่อครั้งของสวัสดิการนี้" |
| BR-19.3 | `6a9d20fe4720c515252ab95f` | 1 validate (`checkType 1`) | Lookup ต้องแนบใบเสร็จ = 1 **และ** `หลักฐานประกอบ` ว่าง | บล็อก "สวัสดิการนี้กำหนดให้ต้องแนบหลักฐานประกอบ" |
| BR-19.4 | `6a9d20ff4720c515252ab961` | 0 interact | `สถานะใบเบิก` ≠ Draft | `ruleItems type 7` = ทุกฟิลด์อ่านอย่างเดียว |

#### หลักฐานการทดสอบ (เปิดฟอร์มจริงในหน้าจอ — API พิสูจน์ไม่ได้ ดู `../../shared/00-HAP-Working-Guide.md` §15.5)

| กฎ | วิธีทดสอบ | ผล |
|---|---|---|
| BR-19.2 · BR-19.3 | แก้บรรทัดของ CLM-2569-0001 จาก 1,200 → 1,400 ⇒ Rollup 1,700 > วงเงินสูงสุดต่อครั้ง 1,500 · เปิด record แล้วแก้ฟิลด์ | ✅ ขึ้นแถบแดง **2 อัน** พร้อมกัน — "จำนวนเงินที่ขอเบิกเกินวงเงินสูงสุดต่อครั้งของสวัสดิการนี้" ที่ Rollup และ "สวัสดิการนี้กำหนดให้ต้องแนบหลักฐานประกอบ" ที่ช่องแนบไฟล์ · **บันทึกไม่ผ่าน** |
| BR-19.1 | รอบเดียวกัน — Rollup 1,700 กับ `วงเงินคงเหลือขณะยื่น` 3,500 | ✅ **ไม่ขึ้น error** (ถูกต้อง — ยังไม่เกินวงเงินคงเหลือ) ⇒ เป็นการทดสอบที่แยกแยะได้จริง ไม่ใช่ทุกกฎยิงพร้อมกันหมด |
| BR-19.4 | เปิด CLM-2569-0003 (สถานะ Approved) | ✅ ฟอร์ม render เป็นข้อความล้วน **ไม่มีกรอบ input สักช่อง** ต่างจาก CLM-2569-0001 (Draft) ที่แก้ได้ปกติ |
| — (กับดัก) | สั่ง `hap worksheet record update` บน record ที่ละเมิด BR-19.2 | 🔴 **`resultCode: 1` สำเร็จ ไม่มี error** ⇒ `checkType: 1` ไม่บล็อก API |

✅ คืนค่าหลังทดสอบครบ: บรรทัดกลับเป็น 1,200 · Rollup กลับเป็น 1,500.0000 · `เหตุผลที่ไม่อนุมัติ` ล้างเป็นค่าว่าง

#### แก้เพิ่ม: `showControls` ของ relation `รายการค่าใช้จ่าย`

`6a9d1a084a22ad87b727a373` เดิมเป็น `[]` ⇒ ตารางฝังในฟอร์มขึ้น **"No visible fields"** ทั้งที่นับได้ 2 แถว · ตั้งเป็น `ลำดับที่` · `รายการค่าใช้จ่าย` · `ประเภทค่าใช้จ่าย` · `จำนวนเงิน` · `เลขที่ใบเสร็จ` แล้ว — ✅ ยืนยันด้วยตาว่าตารางแสดง 2 บรรทัดพร้อมคอลัมน์ครบ

---

### 🆕 WF-HR-11 อนุมัติใบเบิก + ตัดวงเงิน (HR/P6-5-WF11 — 6 ก.ย. 2569)

**processId `6a9d2996d91d10186d8c6edf`** · publish v4 · trigger `worksheet_event` update บน `hr_claim` · `triggerFields = [สถานะใบเบิก 6a9d19c5f363582dd3793041]`

| ลำดับ | alias | nodeId | ชนิด | ทำอะไร |
|---|---|---|---|---|
| 1 | `gate` | `6a9d29af2fe3e8d6b3b7c7ff` | branch | container |
| 1a | `do_deduct` | `6a9d29af2fe3e8d6b3b7c809` | branch path | `[[สถานะ=Approved, ธง≠1],[สถานะ=Approved, ธงว่าง]]` — เขียนแบบกระจายเอง |
| 1b | `skip` | `6a9d29af2fe3e8d6b3b7c80d` | branch path | fallback ไม่ทำอะไร |
| 2 | `upd_flag` | `6a9d29af2fe3e8d6b3b7c800` | update_record | ตั้ง `(ระบบ) ตัดวงเงินแล้ว` = 1 **ก่อนคำนวณ** (กันตัดซ้ำ) |
| 3 | `get_bal` | `6a9d29af2fe3e8d6b3b7c801` | get_single | `hr_welfare_balance` · `wb_employee` = trigger.พนักงาน **และ** `wb_welfare_scheme` = trigger.สวัสดิการ (`conditionId 33` ทั้งคู่) · เรียง `benefit_year` มาก→น้อย · `ifEmpty: stop` |
| 4 | `get_emp` | `6a9d29af2fe3e8d6b3b7c802` | get_single | `hr_employee` ที่ reverse-relation `6a95c129353e1b0e4a515ac3` ชี้มาที่ `get_bal.rowid` |
| 5 | `sum_lines` | `6a9d2a772fe3e8d6b3b7cd1e` | rollup (sum) | รวม `จำนวนเงิน` ของ `hr_claim_line` ที่ `…a374` = trigger.rowid — **แทนการอ่านฟิลด์ Rollup ซึ่งอ่านไม่ได้** |
| 6 | `calc_used` | `6a9d29af2fe3e8d6b3b7c803` | compute | `get_bal.วงเงินที่ใช้ไป + sum_lines.number_fx_id` |
| 7 | `calc_remaining` | `6a9d29af2fe3e8d6b3b7c804` | compute | `get_bal.วงเงินสิทธิ − calc_used` |
| 8 | `upd_claim` | `6a9d29af2fe3e8d6b3b7c806` | update_record | ใบเบิก: `วงเงินคงเหลือขณะยื่น` = calc_remaining · `วันที่อนุมัติ` = `nowTime` |
| 9 | `notify_emp` | `6a9d29af2fe3e8d6b3b7c807` | send_internal_notice | ถึง `get_emp.emp_user` |
| 10 | `upd_bal2` | `6a9d2c318475f61d4c7326ad` | update_record | **ขั้นสุดท้าย** เขียน `วงเงินที่ใช้ไป`/`วงเงินคงเหลือ` กลับแถววงเงิน |

🔴 **ลำดับ 8–10 สลับไม่ได้** — ถ้า `upd_bal2` มาก่อน `upd_claim` ค่า compute จะถูกประเมินใหม่จากวงเงินที่เพิ่งเขียนไป แล้วใบเบิกจะได้ **−2,600** แทน **200** (ยิงจริงเจอมาแล้ว) ดู `../../shared/00-HAP-Working-Guide.md` §16.3

#### หลักฐานการยิงจริง (3 การทดสอบที่แยกแยะได้)

| การทดสอบ | ก่อน | หลัง | ผล |
|---|---|---|---|
| **ตัดวงเงินจริง** — CLM-2569-0003 (EMP-0008 / ค่าตัดแว่น 2,800) Draft→Approved | วงเงิน `EMP-0008-WF-GLASS-2026` ใช้ไป 0 / คงเหลือ 3,000 · ธง 0 · snapshot ตั้งไว้ 9,999 | **ใช้ไป 2,800 · คงเหลือ 200** `_updatedBy` = **`user-workflow`** · ธง 1 · snapshot **200** · `วันที่อนุมัติ` 2026-09-06 17:03:24 | ✅ |
| **ยิงซ้ำไม่ตัดซ้ำ** — ใบเดิม Approved→Pending HR→Approved (ธงเป็น 1 แล้ว) | ใช้ไป 2,800 / คงเหลือ 200 | **คง 2,800 / 200 ไม่ขยับ** | ✅ |
| **เลือกแถววงเงินถูกใบ** — CLM-2569-0002 (EMP-0003 / ค่ารักษาพยาบาล 2,400) →Approved | `EMP-0003-WF-MED-2026` ใช้ไป 6,200 / คงเหลือ 13,800 | **ใช้ไป 8,600 · คงเหลือ 11,400** · แถว `EMP-0005-WF-DENTAL-2026` **ยังคง 0 / 5,000 ไม่ถูกแตะ** | ✅ |

⬜ **ยังไม่ทดสอบ:** เส้น `ifEmpty: stop` (ใบเบิกที่ไม่มีแถววงเงินรองรับ) · การแจ้งเตือนถึงพนักงานยังไม่ได้ยืนยันว่าถึงผู้รับจริง

#### แถววงเงินที่เพิ่มใหม่ (เติมช่องว่างของชุด demo)

| wb_name | rowid | วงเงินสิทธิ |
|---|---|---|
| EMP-0005-WF-DENTAL-2026 | `a14557b9-cef9-4dd4-9995-ac9b148f98bb` | 5,000 |
| EMP-0008-WF-GLASS-2026 | `bba60ad5-3450-4219-a87b-b105eaa765ac` | 3,000 |

**สถานะข้อมูล demo หลังทดสอบ:** CLM-2569-0001 = Pending supervisor (ยังไม่ตัดวงเงิน) · CLM-2569-0002 · CLM-2569-0003 = Approved **ตัดวงเงินจริงโดย workflow แล้วทั้งคู่**
