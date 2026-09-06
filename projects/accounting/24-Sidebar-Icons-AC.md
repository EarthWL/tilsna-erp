# 24 — ไอคอนไซด์บาร์โมดูลบัญชี (worksheet + กลุ่ม)

**งาน** `AC/ICONS` · **agent-ac** · 6 ก.ย. 2569
ตั้งไอคอนให้ **47 worksheet + 9 กลุ่ม = 56 รายการ** ในโมดูลบัญชี · เดิมใช้ `table` และ `8_4_folder` เหมือนกันหมด แยกไม่ออกตอนนำเสนอ

---

## 1. คำสั่งที่ใช้ — และเรื่องสำคัญที่เพิ่งรู้

```bash
hap worksheet update <id> --icon <ชื่อไอคอน> -a <app_id>
```

🔵 **คำสั่งเดียวกันนี้เปลี่ยนไอคอน "กลุ่ม" ได้ด้วย** — ยืนยัน 6 ก.ย. 2569
สาเหตุ: สิ่งที่เราเรียกว่า "กลุ่ม" (AC-00 … AC-08) **ไม่ใช่ section** แต่เป็น **item ชนิด 2 (subgroup) ที่อยู่ใน section** และมี id ทรงเดียวกับ worksheet
`HomeApp/GetApp` จึงคืนมันมาใน `workSheetInfo` ปนกับ worksheet จริง ⇒ `AppManagement/EditWorkSheetInfoForApp` (ที่ `worksheet update` เรียก) รับ id ของกลุ่มได้ตรง ๆ

ในแอปนี้มี **section จริงแค่ 2 อัน**: `บัญชี (AC)` `6a841cbc3970d3f694ee96f3` และ `ทรัพยากรบุคคลฯ (HR)` `6a8ee668e56d2e6eb7bd6cb3`
ถ้าจะแก้ไอคอนของ **section จริง** ต้องใช้ `HomeApp/UpdateAppSection` (ต้องส่ง `appSectionName` + `icon` + `iconColor` ครบก้อน และใช้คีย์ `appSectionId`) — `hap app edit-section` เปลี่ยนได้แค่ **ชื่อ** เท่านั้น

## 2. รายชื่อไอคอน — ดึงจาก CLI ได้แล้ว ไม่ต้องงัด DOM

hap-cli 0.8.29 มี `hap icon` แล้ว (ตอนที่ HR ทำยังไม่มี จึงต้องดึงจาก DOM ของ icon picker)

```bash
hap icon search <คำ> --limit 20     # คำค้นเป็นภาษาจีน เช่น 财务 账单 银行 审批
hap --json icon list -p <หน้า> -n 50   # 426 ไอคอน · 9 หน้า
```

⚠️ CLI คืน **426 ชื่อ** ขณะที่ icon picker บน UI มี **997** ⇒ CLI เป็น subset ไม่ใช่ทั้งหมด
🔴 ยังคงจริงตาม `shared/00-HAP-Working-Guide.md` §11.2 — **`--icon` รับชื่อที่ไม่มีจริงไปเงียบ ๆ แล้วตอบ `true`** ไอคอนกลายเป็นช่องว่างโดยไม่มี error
⇒ **ตรวจ HTTP 200 ก่อนยิงทุกตัวเสมอ:**

```bash
curl -s -o /dev/null -w '%{http_code}\n' "https://www.nocoly.com/file/mdpub/customIcon/<ชื่อ>.svg"
```

## 3. ขั้นตอนที่ทำจริง

1. อ่านไอคอนที่ HR ใช้อยู่ทั้ง 37 ตัว (`hap --json app info`) เพื่อ **ไม่ตั้งชนกัน**
2. ร่างแผน 56 รายการ → ตรวจ 3 ด่านก่อนยิง: **ไม่ซ้ำกันเอง · ไม่ชน HR · HTTP 200 ครบ**
3. ยิงทีละรายการ 56 ครั้ง — สำเร็จ **56/56**
4. อ่านกลับเทียบทีละรายการ + ตรวจว่าไม่มีอะไรอื่นถูกแตะ

## 4. 🔴 ชนกับ agent-hr ระหว่างทาง — และวิธีที่จับได้

ตอนอ่านค่าเริ่มต้น HR ยังไม่ได้ตั้งไอคอน**กลุ่ม** · ระหว่างที่ยิง agent-hr ตั้งไอคอนกลุ่มของตัวเองพร้อมกัน ทำให้ชน 3 ตัว:

| ไอคอน | AC ใช้ที่ | HR ใช้ที่ |
|---|---|---|
| `sys_folder-check_office` | AC-07 (กลุ่ม) | HR-02 (กลุ่ม) |
| `sys_folder-settings_office` | การตั้งค่าเอกสาร | HR-00 (กลุ่ม) |
| `sys_folder-money_office` | ทะเบียนภาษีซื้อ–ภาษีขาย | HR-04 (กลุ่ม) |

**จับได้เพราะนับไอคอนซ้ำจากผลอ่านกลับ ไม่ใช่จากแผนที่ร่างไว้** — ถ้าเช็คแค่ตอนวางแผนจะไม่เห็นเลย
แก้โดยเปลี่ยนฝั่ง AC 3 ตัว (HR ยิงทีหลัง ให้ของเขาอยู่): `sys_final-score_activity` · `sys_folder-vector_office` · `sys_1_9_address_book`

🔑 **บทเรียน:** งานที่แตะ "พื้นที่ร่วม" อย่างชุดไอคอนของแอป **ต้องตรวจซ้ำหลังยิงเสร็จ** เพราะ preflight จองได้แค่ object ที่ระบุชื่อ ไม่ได้จองทั้งแอป

## 5. ผลตรวจหลังทำ

```
ไอคอนตรงกับที่ตั้ง        : 56/56
ไอคอนซ้ำทั้งแอป           : ไม่มี — 102 รายการในไซด์บาร์ ใช้ไอคอนต่างกันครบ 102 แบบ
ชื่อตาราง / entityName / view : ไม่เปลี่ยนเลยทั้ง 47 ตาราง
จำนวนระเบียน              : GL 337 · ใบแจ้งหนี้ 32 · ใบสำคัญ 97 (คงเดิม)
```

## 6. ตารางไอคอนที่ตั้ง

### กลุ่ม (9)

| กลุ่ม | id | ไอคอน |
|---|---|---|
| AC-00 ตั้งค่าระบบ | `6a8538dee16cff5c409bc74d` | `sys_11_4_services` |
| AC-01 ข้อมูลหลัก | `6a8539557a3fe56d6dd35ba3` | `sys_cabinet_object` |
| AC-02 บัญชีแยกประเภท | `6a8539a3c011bf786fef6b56` | `sys_books_office` |
| AC-03 เจ้าหนี้และการจ่ายเงิน | `6a8539cac011bf786fef6b59` | `sys_money-transfer_finance` |
| AC-04 ภาษี | `6a8539e70f7255ac5594e0d9` | `sys_percentage2_finance` |
| AC-05 ลูกหนี้และรายได้ | `6a853a35e16cff5c409bc753` | `sys_chart-growth_finance` |
| AC-06 สินทรัพย์ถาวร | `6a853ab60f7255ac5594e0dc` | `sys_18_1_apartment_house` |
| AC-07 ปิดบัญชีและกระทบยอด | `6a853b2f0f7255ac5594e0e1` | `sys_final-score_activity` |
| AC-08 เชื่อมต่อระบบและรับข้อมูล | `6a853b790f7255ac5594e0e3` | `sys_api_symbol` |

### Worksheet (47)

| กลุ่ม | worksheet | id | ไอคอน |
|---|---|---|---|
| AC-00 | กฎการผ่านรายการ | `6a85518c33560633b8cd6a15` | `sys_decision-process_symbol` |
| AC-00 | งวดบัญชี | `6a8434d5055f2288c5b6d4b8` | `sys_roadmap_symbol` |
| AC-00 | สมุดรายวัน | `6a8434da33560633b8cd2efd` | `sys_notes_object` |
| AC-00 | ประเภทเอกสาร | `6a8434dd9b6999a714d22e3d` | `sys_cards_symbol` |
| AC-00 | กฎการออกเลขที่เอกสาร | `6a8434ea8b36df988c16ed84` | `sys_hash-mark_finance` |
| AC-00 | กฎการอนุมัติตามวงเงิน | `6a8434f18b36df988c16ed8e` | `sys_16_1_checked` |
| AC-00 | การตั้งค่าเอกสาร | `6a8434f69b6999a714d22e75` | `sys_folder-vector_office` |
| AC-00 | พารามิเตอร์ระบบบัญชี | `6a917a2d9762533b5b720392` | `sys_11_1_tool_storage_box` |
| AC-01 | สกุลเงิน | `6a8545261049edca1eecd818` | `sys_currency-dollar_finance` |
| AC-01 | หน่วยงาน / ศูนย์ต้นทุน | `6a85452b9b6999a714d26720` | `sys_filter-organization_symbol` |
| AC-01 | แหล่งเงิน | `6a85453033560633b8cd68dc` | `sys_money-bag_finance` |
| AC-01 | โครงการ (มิติบัญชี) | `6a854534055f2288c5b741ce` | `sys_folder-dev_office` |
| AC-01 | ประเภทเงินได้ (หัก ณ ที่จ่าย) | `6a85454133560633b8cd68e6` | `sys_paragraph_finance` |
| AC-01 | อัตราภาษีมูลค่าเพิ่ม | `6a8545469b6999a714d2673c` | `sys_math_office` |
| AC-01 | อัตราภาษีหัก ณ ที่จ่าย | `6a8545688b36df988c172471` | `sys_rate-down_finance` |
| AC-01 | คู่ค้า (ผู้ขาย / ลูกค้า) | `6a85457033560633b8cd6920` | `sys_handshake_office` |
| AC-01 | บัญชีธนาคารคู่ค้า | `6a85458033560633b8cd692a` | `sys_contactless-card_finance` |
| AC-01 | บัญชีธนาคารของกิจการ | `6a854584055f2288c5b74202` | `sys_atm_symbol` |
| AC-01 | อัตราแลกเปลี่ยน | `6a8545911049edca1eecd8a5` | `sys_currency-exchange_finance` |
| AC-01 | ประเภทสินทรัพย์ | `6a8545948b36df988c17247c` | `sys_18_5_warehouse` |
| AC-01 | ช่องทางการจ่ายเงิน | `6a8545a19b6999a714d2675f` | `sys_credit-card_finance` |
| AC-01 | สินค้าและบริการ | `6a8545a89b6999a714d26769` | `sys_13_2_shopping_bag` |
| AC-01 | ผังบัญชี | `6a85516e1049edca1eecd9b7` | `sys_nodes_symbol` |
| AC-02 | ใบสำคัญ | `6a85fb2e9b6999a714d2a53d` | `sys_cheque2_finance` |
| AC-02 | รายการในใบสำคัญ | `6a85fb3933560633b8cd9f40` | `sys_ayout_symbol` |
| AC-02 | บัญชีแยกประเภททั่วไป | `6a85fb4133560633b8cd9f4a` | `sys_1_worksheet` |
| AC-03 | ใบสำคัญตั้งหนี้ | `6a8673d61049edca1eed0638` | `sys_loan_finance` |
| AC-03 | รายการค่าใช้จ่าย | `6a8673e78b36df988c176b77` | `sys_3_3_paper_money` |
| AC-03 | ใบขออนุมัติเบิกจ่าย | `6a8677b19b6999a714d2aa83` | `sys_letter_office` |
| AC-03 | ใบสำคัญจ่าย | `6a8677c38b36df988c176cd3` | `sys_money_finance` |
| AC-03 | รายการเอกสารที่จ่าย | `6a8677d7055f2288c5b77d12` | `sys_desk-drawer_object` |
| AC-03 | บันทึกการจ่ายชำระ | `6a8677de8b36df988c176d02` | `sys_credit-card-in_finance` |
| AC-03 | หนังสือรับรองการหักภาษี ณ ที่จ่าย | `6a8677f1055f2288c5b77d1d` | `sys_badge2_office` |
| AC-04 | การยื่นแบบภาษี | `6a8677c79b6999a714d2aa93` | `sys_send_office` |
| AC-04 | ทะเบียนภาษีซื้อ–ภาษีขาย | `6a8677f9055f2288c5b77d58` | `sys_1_9_address_book` |
| AC-05 | ใบแจ้งหนี้ลูกหนี้ | `6a996762f9501c7d9b814dc1` | `sys_1_2_order` |
| AC-05 | รายการรายได้ | `6a9967cff9501c7d9b814de3` | `sys_rate-up_finance` |
| AC-05 | ใบกำกับภาษี / ใบส่งของ | `6a996830f27dae0c03afe8e9` | `sys_delivery-fast_traffic` |
| AC-05 | ใบเสร็จรับเงิน | `6a99685df9501c7d9b814e0d` | `sys_coins_finance` |
| AC-05 | ใบลดหนี้ | `6a99688af27dae0c03afe8f6` | `sys_reply_office` |
| AC-05 | ใบเพิ่มหนี้ | `6a9968baee1c5c4507b37ca0` | `sys_folder-add_office` |
| AC-05 | ใบวางบิล | `6a9968def9501c7d9b814e3f` | `sys_attach_email_office` |
| AC-07 | การกระทบยอดธนาคาร | `6a8fd69d1378964f9984a2ad` | `sys_refresh_symbol` |
| AC-07 | รายการกระทบยอดธนาคาร | `6a8fd69e8b6633ef76f1313f` | `sys_ayout-grid_symbol` |
| AC-07 | รายการตรวจสอบปิดงวด | `6a8fd69e353e1b0e4a507e16` | `sys_measurement_activity` |
| AC-07 | การปิดบัญชีสิ้นปี | `6a8fd69f9762533b5b718bce` | `sys_10_2_lock` |
| AC-07 | ยอดยกมาต้นปี | `6a8fd69f353e1b0e4a507e20` | `sys_shape-arrow_symbol` |

## 7. ค้างอยู่

- **สีไอคอน** เปลี่ยนไม่ได้หลังสร้าง — `--icon-color` มีเฉพาะตอน `worksheet create` (ตาม `shared/00-HAP-Working-Guide.md` §11.1) ⇒ ทั้งแอปยังเป็นสีเดียวกันหมด
- **ไอคอนของ section จริง** (`บัญชี (AC)` ตอนนี้เป็น `custom_style`) ยังไม่ได้แตะ — ต้องใช้ `HomeApp/UpdateAppSection` และกระทบทั้งโมดูล ⇒ รอตกลงกับ agent-hr ก่อน
