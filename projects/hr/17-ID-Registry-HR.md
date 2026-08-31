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
