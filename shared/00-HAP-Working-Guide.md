# HAP / Nocoly — ไกด์ทำงานสำหรับ Cowork

_เวอร์ชัน 1.2 · อัปเดต 27 ส.ค. 2569 (เพิ่มหัวข้อใหม่ §4 — Business Rules/Dynamic Default/Unique Index/Role Debugging/ghost objects จาก TILSNA HR P3-7/P3-8) · ใช้ร่วมกันทุกโปรเจกต์ Nocoly (`nocoly-api-lab`, `nocoly-wfh-dgr`, `tilsna-*`)_

> ไฟล์นี้เป็น **ไกด์ปฏิบัติงาน** ไม่ใช่สเปกของระบบใดระบบหนึ่ง — เปิดอ่านก่อนลงมือกับ Nocoly/HAP
> สเปกรายโปรเจกต์อยู่ที่ `<project>/02-BuildSpec-FRS.md` · ความจำรายโปรเจกต์อยู่ที่ `<project>/04-CLAUDE-memory.md`

## ป้ายความน่าเชื่อถือ (ใช้ทั้งไฟล์)

| ป้าย | ความหมาย |
|---|---|
| **[V]** | ยิงจริงแล้วบนระบบจริง มีวันที่และหลักฐานกำกับ |
| **[S]** | มาจากเอกสาร (`mingdaocom/hap-skills` หรือ help.nocoly.com) น่าเชื่อถือ แต่ยังไม่ได้ยิงเอง |
| **[?]** | ยังไม่รู้ / เอกสารขัดกันเอง — ต้องทดสอบก่อนเชื่อ |

🔴 **กฎเหล็กข้อแรก: "เห็น tool ใน connector" ไม่นับเป็นการพิสูจน์** — เคยพลาดมาแล้ว (26 ส.ค.) ต้องยิงจริงจึงเขียนว่า "ทำได้"

---

## 1. เลือกช่องทาง (surface) — ตารางตัดสินใจ

| งาน | ทำที่ไหน | สถานะ |
|---|---|---|
| worksheet / field / optionset / role / record / seed data | **MCP** | [V] |
| **สร้าง workflow + node + validate + publish** | **MCP** | **[V] 26 ส.ค.** |
| **เปิดใช้งาน workflow** | ไม่มีขั้นตอนนี้ — `publish_process` = ทำงานทันที | **[V] 26 ส.ค.** |
| View / Custom Action / Chart / Chatbot / custom page | MCP (ลองก่อน) → Browser ถ้าพัง | **[?] ยังไม่เคยเรียก** |
| **แก้** view / custom action หลังสร้าง | Browser | [V] — MCP มีแต่ `create_*` ไม่มี `update_*` |
| trigger นอก 4 ชนิด (Personnel / External User / PBP / Subprocess / Custom Action) | Browser | [S] |
| node นอก 17 ชนิด (Loop / Terminate / Send API Request / JSON Parsing / Print / AI / SMS …) | Browser | [S] |
| bind ฟิลด์กับ shared optionset · print template · external portal · field default/validation | Browser | [V] จากโปรเจกต์ WFH |
| **Business Rule (Interaction/Style/Validation/Lock) · Dynamic Default (Query worksheet) · Unique Index** | Browser | **[V] 27 ส.ค. — ดูข้อจำกัดใหม่ใน §4** |
| กด approve / reject / recall | Browser (To-do) หรือ org-auth API (gated) | [V] |
| หา `userId` / `departmentId` จาก**ชื่อคน** | UI หรือ org-auth API | **[V] — `find_member` ถูกถอดออกจาก connector แล้ว** |
| สร้าง**แอปใหม่** | UI หรือ org-auth API | [V] — connector ไม่มี `create_app` |
| แชท · ปฏิทิน · โพสต์ · อัปโหลดไฟล์ · ไล่จากข้อความไปหาเรคอร์ด | **hap-cli เท่านั้น** | [S] — ต้องติดตั้งก่อน (ดู §6) |

**กฎการแบ่ง:** ถ้า workflow ตัวหนึ่งต้องใช้ trigger/node ที่ MCP สร้างไม่ได้ → **ทำทั้งตัวใน Browser** ห้ามแบ่งกราฟเดียวข้าม surface

---

## 2. สร้าง workflow ผ่าน MCP — ลำดับมาตรฐาน

```
create_process(name, description, trigger, publish:false)
    → { processId, triggerAlias }        ← อ่าน triggerAlias จากตรงนี้ ห้าม hardcode
batch_create_process_nodes(workflow_id, nodes[])
validate_process(workflow_id)            ← เรียกหลังทุก batch (ฟรี และ node แก้ไม่ได้)
publish_process(workflow_id)             ← รับแค่ workflow_id · publish = ใช้งานได้ทันที
create_record(worksheet_id, fields, triggerWorkflow:true)
get_record_details(..., includeSystemFields:true)
    → _updatedBy.accountId == "user-workflow"   ← หลักฐานเดียวที่นับ
```

**[V] เวลาที่ใช้จริง:** เรคอร์ดสร้าง 14:01:50 → workflow เขียนทับ 14:01:55 = 5 วินาที

### สิ่งที่สร้างได้

- **Trigger 4 ชนิด:** `worksheet_event` (`add`/`update`/`delete`/`add_or_update` + `triggerFields[]` + `filter`) · `schedule` · `date_field` · `webhook`
- **Node 17 ชนิด:** `get_single` `get_multiple` `add_record` `update_record` `delete_record` `branch` `rollup` `compute` `delay` `send_internal_notice` `cc` `send_email` `code` `approval_block` `approve` `fill_in` `sub_process`

### กับดักที่ต้องรู้ก่อนเขียน node แรก

| # | กฎ | สถานะ |
|---|---|---|
| 1 | **แก้ node ที่สร้างแล้วไม่ได้** — alias ซ้ำ → `NODE_ALIAS_EXISTS` · ส่ง `nodeId` ก็ถูกเมิน ต้อง `delete_process_node` แล้วสร้างใหม่ | **[V]** |
| 2 | **ลบ branch node = cascade ลบทุก node ใต้ paths ของมันทั้งหมด** (ยืนยันจริง 27 ส.ค. — ลบ branch 1 ตัว หายไป 24 node ที่ผูกอยู่ใต้ทั้งสอง path) ⇒ ก่อนแก้ node กลาง flow ให้ประเมินก่อนว่าจะเสีย subtree เท่าไร | **[V] 27 ส.ค.** |
| 3 | **`prevNode` ของ node ถัดไป auto-relink เองเมื่อสร้าง node ใหม่ด้วย alias เดิม** แต่ **เนื้อหา filter/condition ของ node อื่นที่อ้าง field ของ node ที่ถูกลบ (เก็บ nodeId ไว้ตรง ๆ) ไม่ auto-relink** — ต้อง `delete_process_node`+สร้างใหม่ทุก node ที่ filter อ้างถึง node ที่เปลี่ยน nodeId ด้วย ไม่ใช่แค่ node ที่ต่อ sequence โดยตรง · เจอเป็น `StartNodeControlsIsNull` ตอน `validate_process` (**ตอบ M-04 แล้ว**) | **[V] 27 ส.ค.** |
| 4 | **`get_workflow_structure` ป้อนกลับไม่ได้** — `template` อ่านกลับมาเป็น `literal` แล้ว placeholder จะตายเงียบ ๆ ⇒ ประกอบ node spec จากแผน + `get_worksheet_structure` เสมอ | **[V]** |
| 5 | `fieldId` ต้องเป็น **ID จริง 24 hex** ห้ามใช้ alias — ทุกที่ที่มี `fieldId` รวมถึงใน `$...$` | [S] |
| 6 | `update_record` **ไม่มี output field** — อ้าง `$update_node-fieldId$` ปลายน้ำ = `StartNodeControlsIsNull` | [S] |
| 7 | `get_multiple` เช็กว่าง **ห้ามดู `rowid`** → ต่อ `rollup(count)` แล้ว branch ที่ `number_fx_id > 0` (`get_single` ดู `rowid not_empty` ได้) | [S] |
| 8 | `approval_block` / `sub_process` เป็น **scope ปิด** — ใช้ alias คงที่ `approval_start` / `sub_trigger` · `prevNode` ข้ามขอบเขตไม่ได้ · ⚠️ บาง tenant **start node ไม่มี alias** เลย (`approval_start` ใช้ไม่ได้ "找不到节点别名") ต้อง `get_workflow_structure(<inner processId>)` แล้วอ้างด้วย `nodeId` แทน — เจอจริงในแอป TILSNA | **[V]** |
| 9 | **publish subflow (approval_block internals) ก่อน main flow เสมอ** ไม่งั้น `NodeAppIsNull` | **[V] 26–27 ส.ค.** |
| 10 | `approve.allowReject` default = `false` → ต้องตั้ง `true` เอง | [S] |
| 11 | branch: `paths` ≥ 2 · path ที่ `filter: null`/`items:[]` ต้องอยู่**ท้ายสุด** · path alias ห้ามเป็น `prevNode` ของ node นอกพาธ และห้ามเป็น `target.node` · **node แรกในแต่ละ path ต้องส่งทั้ง `prevNode` และ `parentNode` เป็น `{nodeAlias:<path alias>}` เหมือนกัน** (ขาดตัวใดตัวหนึ่ง → `分支后的节点必须接到 paths[].alias`) | **[V] 26 ส.ค.** |
| 12 | `branch.paths[].result` = **`pass` \| `overrule`** (ไม่ใช่ `approve`/`reject`) · branch ผลอนุมัติ (`branchType:"approval_result"`) ต้องอยู่ **ในสายอนุมัติ ต่อจาก `approve` node** วางนอก block จะได้ error `approval_result 只能接在 approve 节点后` | **[V]** |
| 13 | `compute` dateOffset: `offsetExpression` ต้องมีเครื่องหมาย+หน่วย case-sensitive (`+30d`) · output = `date_fx_id` ส่วนตัวอื่น = `number_fx_id` | [S] |
| 14 | `batch_create_process_nodes` เป็น **atomic** — พังหนึ่ง node ล้มทั้ง batch · แต่ **approval_block ทั้งก้อนพร้อม inner `process.nodes` สร้างในคำเดียวได้จริง** (ไม่ต้อง 2 จังหวะแบบที่เอกสารเก่าเตือนไว้ — ยิงจริงสำเร็จ 2 ครั้งในแอป TILSNA) | **[V] 26 ส.ค. — ตอบ M-03 บางส่วน** |
| 15 | **workflow ที่ publish แล้วยิงทันทีกับทุกคน** — ก่อน publish `worksheet_event` บนตารางที่คนอื่นใช้ ต้องใส่ `filter` ให้ match เฉพาะเรคอร์ดทดสอบ แล้วลบทิ้งเมื่อเสร็จ | **[V]** |
| 16 | 🔴🔴 **`get_single`/`get_multiple` filter ด้วย `fieldId:"rowid"` + `op:"in"` เทียบกับค่าจาก Relation field ของ node อื่น (เช่น `trigger.employee`) ล้มเหลวเงียบ ๆ เสมอ** — ไม่ error แต่ผลว่างทุกครั้ง ไม่ว่า `right` จะเป็น bare ValueRef หรือ array-wrapped ValueRef (ทดสอบทั้งสองแบบแล้วผลเหมือนกัน) ⇒ **ห้ามใช้ `rowid in <relation field ของ node อื่น>` เพื่อ "ดึง record ที่ relation ชี้มา"** ทางแก้ที่พิสูจน์แล้วว่าใช้ได้จริง: กรอง **reverse-relation field บนตารางปลายทาง** (auto-created field ที่ระบบสร้างคู่กับ relation field ต้นทาง หาได้จาก `sourceField` ใน `get_worksheet_structure`) ด้วย `op:"contains"` เทียบกับ `<source node>.rowid`(array-wrap `right:[{...}]`) — เช่น หา `hr_employee` ที่ `hr_leave_request.employee` ชี้มา ให้กรอง `hr_employee.<reverse-relation field id>` `contains` `trigger.rowid` แทนกรอง `hr_employee.rowid` `in` `trigger.employee` | **[V] 27 ส.ค. — พิสูจน์กับ WF-HR-01** |
| 17 | ⚠️ `FieldPatch.value{kind:"field",...}` ที่**ลืมใส่ `node`** ไม่ error ตอน `validate_process`/`publish_process` — เขียนค่าว่างเงียบ ๆ ตอนรันจริง (คนละสาเหตุกับกับดัก OrgRole ที่มีอยู่แล้ว แต่ผลเหมือนกัน) ⇒ ก่อน publish ให้ `get_workflow_structure` อ่านสอบทุก `value.kind=="field"` ว่ามี `node` ครบ | **[V] 27 ส.ค.** |
| 18 | 🔴🔴 **`compute`/`get_single` node ไม่ใช่ snapshot แบบ freeze ณ จุดที่มันรัน — downstream node ที่อ้างผลลัพธ์ (`{kind:"field",node:{nodeAlias:<compute/get_single>},fieldId:...}`) จะถูกคำนวณ/ดึงใหม่จากค่า**ปัจจุบัน**ของฟิลด์ต้นทางในฐานข้อมูล ณ เวลาที่ node ปลายทางรัน ไม่ใช่ค่า ณ ตอนที่ node ต้นทางรันครั้งแรก** — พิสูจน์จริง (WF-HR-02, TILSNA): compute `calc_remaining` (= `get_bal.total_days − calc_used.number_fx_id`) ถูกทั้ง `update_record` (เขียนยอดคงเหลือกลับตาราง balance) และ `add_record` (เขียน `balance_after` ลง ledger) อ้างอิงร่วมกัน — เมื่อวาง `add_record` (ledger) **หลัง** `update_record` (balance) ผลคือ `add_record` อ่านค่า `get_bal.used_days` ที่ **ถูก update ไปแล้ว** ทำให้คำนวณซ้ำเป็นเลขผิด (ยอดจริง=9.0 แต่ ledger บันทึก 8.0 เพราะหัก used_days ซ้ำสองรอบ) ⇒ **ห้ามวาง node ที่ต้องใช้ผลลัพธ์ compute/get_single เดิมซ้ำ ไว้หลัง node ที่เขียนทับฟิลด์ต้นทางของมัน** ทางแก้ที่พิสูจน์แล้วว่าถูกต้อง: **เรียงให้ node ที่ "อ่าน" ผลลัพธ์ (เช่น สร้างบัญชีแยกประเภท/ledger) รันก่อน node ที่ "เขียน" ทับฟิลด์ต้นทาง (เช่น update ยอดคงเหลือ) เสมอ** — กระทบทุก pattern ที่มี compute/get_single node ถูกอ้างอิงมากกว่า 1 จุดในเส้นทางเดียวกัน | **[V] 27 ส.ค. — พิสูจน์กับ WF-HR-02 (TILSNA)** |
| 19 | 🔴🔴 **`FieldPatch.value{kind:"record", node:{...}}` เขียนลง Relation field แล้วได้ค่าขยะ ไม่ error ทั้งตอน `validate_process`/`publish_process` และตอนรันจริง** — ค่าที่บันทึกจริงกลายเป็น literal string ที่มี **node ID ภายในของ workflow** (เช่น `["6a8fa9a9fdab77a41c51cd9e"]`) ไม่ใช่ rowid ของ record จริงที่ node นั้นสร้าง/ดึงมา ⇒ อ่านกลับด้วย `get_record_details`/`get_record_list` relation field จะแสดง `已删除` ("ถูกลบ"/ไม่พบ) เพราะ node ID ไม่ตรงกับ rowid จริงในตาราง — พิสูจน์จริง (WF-HR-02, TILSNA): `add_record` ของ ledger ใช้ `{fieldId:<balance relation>, value:{kind:"record", node:{nodeAlias:"get_bal"}}}` เพื่อผูก relation กลับไปยังแถว balance ที่เพิ่งดึงมา ผลลัพธ์คือค่าขยะ ⇒ **ห้ามใช้ `kind:"record"` เพื่อเขียนค่าเข้า Relation field ที่ต้องการชี้ไปยัง "record ที่ node ต้นน้ำผลิต/ดึงมา"** ทางแก้ที่พิสูจน์แล้วว่าถูกต้อง (ยิงจริงแล้ว relation แสดงชื่อ record จริง ไม่ใช่ `已删除`): ใช้ `{kind:"field", node:{nodeAlias:<upstream node>}, fieldId:"rowid"}` แทน — อ้าง system field `rowid` ของ node ต้นน้ำตรง ๆ (ใช้ได้ทั้งกับ `get_single`/`add_record`/`trigger`) — หมายเหตุ: การ **copy ค่าจาก Relation field ที่มีอยู่แล้ว** (เช่น คัดลอก `trigger.employee` ไปยัง `add_record.employee`) ยังคงใช้ `kind:"field"` อ้าง fieldId ของ relation field ต้นทางตามปกติได้ปกติ (ทดสอบแล้วใช้งานถูกต้อง) — บั๊กนี้เกิดเฉพาะกรณีใช้ `kind:"record"` เพื่ออ้างอิง "ทั้ง record" ของ node อื่นเท่านั้น | **[V] 27 ส.ค. — พิสูจน์กับ WF-HR-02 (TILSNA)** |

### ค่าอ้างอิงและ placeholder

| ต้องการ | เขียนแบบนี้ |
|---|---|
| ค่าจาก node ต้นน้ำ | `{kind:"field", node:{nodeAlias:"..."}, fieldId:"<24hex>"}` |
| เวลาปัจจุบัน | `{kind:"systemField", fieldId:"nowTime"}` — **ไม่มี `node`** |
| ผู้เริ่ม (เขียนลงฟิลด์) | `{kind:"systemField", fieldId:"triggeraid"}` |
| ผู้เริ่ม (เลือกเป็นคน) | `PersonRef {kind:"triggerUser"}` — คนละอย่างกับข้างบน |
| ข้อความมีตัวแปร | `{kind:"template", value:"...$trigger-<fieldId>$..."}` |
| system field ใน template | `$system-nowTime$` — **ใช้ prefix `system` ตายตัว** ห้ามใช้ node alias |

`systemField` ที่ schema รับ: `nowTime` · `triggertime` · `triggeraid` · `sourceId` · `instanceId` · `timestamp` · `timestampSeconds` — ยิงจริงแค่ `nowTime` **[V]** ที่เหลือ **[S]**

output field คงที่: `rollup` และ `compute(number/dateDiff)` → `number_fx_id` · `compute(dateOffset)` → `date_fx_id` · `code` → ชื่อที่ประกาศใน `outputs[].name`

---

## 3. 🔴 สี่ภาษา filter ที่ใช้แทนกันไม่ได้

ก๊อปจากที่หนึ่งไปวางอีกที่หนึ่ง **พังทุกครั้ง** และบางกรณีพังเงียบ ๆ

| ใช้กับ | รูปร่าง | ตัวดำเนินการ |
|---|---|---|
| **Builder DSL** — `get_record_list`, pivot, REST `rows/list` | `{type:"group", logic:"AND", children:[{type:"condition", field, operator, value}]}` | `eq ne gt` **`ge`** **`le`** `in` **`notin`** `contains` `notcontains` `concurrent` `startswith` `endswith` `between` **`isempty`** `isnotempty` `belongsto` |
| **Workflow AST** — `create_process`, `batch_create_process_nodes` | `{logic:"and", items:[{left:{kind:"field",node,fieldId}, op, right}]}` | `eq ne gt` **`gte`** **`lte`** `in` **`not_in`** **`empty`** `not_empty` `contains` `starts_with` `belongs` `checked` |
| **FilterCondition (wire)** — filter ของ view, `enableWhen` ของปุ่ม, chart | array แบน `[{controlId, dataType, spliceType, filterType, values}]` — AND/OR อยู่ที่ `spliceType` รายตัว | เป็น**ตัวเลข**: `2`=เท่ากับ `7`=ว่าง `11`=ระหว่าง |
| **OperateCondition** — เงื่อนไข node ฝั่ง CLI | array 2 ชั้น (นอก=OR ใน=AND) | คีย์สะกด **`filedId`** (พิมพ์ผิดมาแต่เดิม) · อ่านมาเป็น `conditions` เขียนกลับใช้ `operateCondition` |

**จำสั้น ๆ:** ฝั่ง**ข้อมูล** = `ge`/`le`/`notin`/`isempty` · ฝั่ง **workflow** = `gte`/`lte`/`not_in`/`empty` (ตรงข้ามกันพอดี) · ฝั่ง **config ของ view/ปุ่ม** = ตัวเลข

**ค่าที่ใส่ ตามชนิดฟิลด์** (ทุกภาษา): ตัวเลือก → **key ของ option** ไม่ใช่ข้อความ · Relation → **rowid array** (ค่าที่คืนมาเป็น `[{sid, name}]` เอา `sid`) · Collaborator → accountId array · Department → department ID array · **ตัวเลขใน filter เป็น string** (`["1000000"]`)

**⚠️ ข้อยกเว้นสำคัญของ Workflow AST (ดู §2 ข้อ 16):** แม้ค่าอ้างอิงจาก Relation field จะเป็น sid array ตามหลักข้างบน แต่การกรองด้วย `rowid`+`in` เทียบกับค่าที่มาจาก Relation field ของ node อื่น **ยังใช้ไม่ได้จริง** (ยิงว่างเงียบ) — ใช้ pattern reverse-relation+`contains` แทนเสมอเมื่อจะ "ดึง record ที่ relation field ของอีกตารางชี้มา"

---

## 4. กับดักที่ไม่ขึ้นกับ surface

รวมจากโปรเจกต์ WFH + API-Lab + TILSNA ทั้งหมด **[V]**

**โครงสร้างข้อมูล**
- alias **`status` เป็นคำสงวน** — `create_worksheet` ปฏิเสธ ใช้ `probe_status` / `order_status` แทน
- `update_worksheet` ส่งแค่ `name` จะ **ล้าง `alias` ทิ้ง** — ส่ง `name`+`alias` คู่กันเสมอ
- API สร้างฟิลด์ได้อย่างน้อย **17 ชนิด** (ไม่ใช่ 8–9 ตาม tool description) รวม Checkbox / Formula / AutoNumber / SubTable / Location / Department / Attachment / Rating / Time
- `isUnique` และ `defaultValue` **ตั้งได้แต่อ่านกลับไม่ได้** และ API **ข้ามการตรวจ `isUnique`** — ผู้ใช้บน UI ถูกกัน แต่ API เขียนซ้ำได้
- Date subType รับ **1–6 เท่านั้น** (ไม่มี 0)
- **เลี่ยง Formula field** — dialog แก้สูตรไม่เสถียร ใช้ Number + node คำนวณแทน
- **API ผูก shared optionset ไม่ได้** → ทุก SingleSelect ใช้ inline options ⇒ ตัวเลือกชื่อเดียวกันคนละตาราง **key คนละค่า**
- 🔴 **เงื่อนไข `ne` กับฟิลด์ที่ค่ายังว่างอยู่ไม่ผ่าน** (แม้ logically ว่าง≠1 ควรจริง) — ฟิลด์ธง (flag) ทุกตัวต้องตั้ง **default 0** และ backfill record เดิมก่อนใช้เงื่อนไข `not equal to 1` ในสาย gate/anti-duplicate — ยืนยันจริงหลายโปรเจกต์ (WFH, บัญชี, HR)

**ข้อมูลและเวลา**
- record ที่สร้างผ่าน API **ไม่มีเจ้าของ** — `_owner` = `user-undefined` · `_createdBy` = `user-api` ⇒ กระทบ role scope แบบ "เฉพาะของฉัน"
- **display timezone ของ tenant = UTC+8** เร็วกว่าไทย 1 ชม. → เขียน DateTime ระบุ `+07:00` เสมอ
- seed ข้อมูลใช้ `triggerWorkflow: false` · ตั้ง `true` เฉพาะตอนตั้งใจจะยิง workflow

**จุดบอดของ connector**
- `get_workflow_list` คืนเฉพาะ **PBP** — **[V]** คืน `[]` ขณะที่ workflow ที่ publish แล้วกำลังทำงานอยู่ ⇒ ผลว่างไม่ใช่หลักฐานว่าไม่มี
- `get_role_list` คืนเฉพาะ **org role** ไม่คืน application custom role (แต่บาง tenant คืนครบ — ตรวจก่อนสรุปทุกครั้ง)
- `get_record_pivot_data` ต้องมี `viewId` (`430028`) แต่ **dimension ไม่จำเป็น**
- **`find_member` / `find_department` / `get_regions` ถูกถอดออกแล้ว** (มี 24 ส.ค. หาย 26 ส.ค.)
- 🔴 **[V] 28 ส.ค. 2569 — `get_record_logs` แบ่ง operator เป็น 2 ชนิด ห้ามใช้ตัดสินว่า workflow ทำงานหรือไม่** · รายการที่เขียน **ฟิลด์กรอบอนุมัติ** (`wfstatus`/`wfcuaids`/`wfname`) → operator `user-workflow` ✅ แต่รายการที่เขียน **ฟิลด์ธุรกิจจาก node ของเราเอง** (`update_record` ใน workflow) → operator **`user-api`** ❌ ⇒ **ยิ่งเป็น node ที่เราเขียน ยิ่งถูกรายงานเป็น `user-api`** คนที่ตรวจว่า "node ฉันทำงานไหม" โดยหา `user-workflow` ใน log จะได้ผลลบลวงเสมอ · **ใช้ `get_record_details(includeSystemFields:true)` → `_updatedBy`/`_createdBy` แทน** (คืน `user-workflow` ถูกต้อง และมี `_processName`/`_processStatus` ให้ด้วยเมื่อเข้าสายอนุมัติ) · `get_record_logs` ยังดีสำหรับดู "ฟิลด์ไหนเปลี่ยนจากอะไรเป็นอะไรเมื่อไร" เท่านั้น
  - *พิสูจน์ซ้ำ:* ยิง workflow ที่มี `update_record` node ให้สำเร็จ 1 ครั้ง แล้วเรียก `get_record_logs` กับ `get_record_details(includeSystemFields:true)` บน rowid เดียวกัน เทียบ operator ของรายการที่เขียนฟิลด์ธุรกิจ กับ `_updatedBy`
- 🔴 **[V] 28 ส.ค. 2569 — `delete_process` เป็น soft-delete ไม่ใช่ลบถาวร** · หลังลบ `workflow get` คืน `deleted:true, enabled:false` และหายจาก `workflow list` แต่ object ยังดึงด้วย id ได้ ⇒ ใช้งานไม่ได้แล้วจริง แต่อย่าเขียนว่า "ลบถาวร"
- 🔴 **[V] 28 ส.ค. 2569 — `delete_process_node` ที่ลบ node ชนิด `sub_process` ทิ้ง inner process ไว้เป็น orphan เสมอ** (ไม่ cascade เหมือน `delete_process`) ⇒ **ต้องลบ inner processId ด้วยมือทุกครั้ง** · เจอค้างจริง 9 ตัวจากการ revert งานเดียว (ลองแก้ 3 รอบ)
- 🔴 **[V] 28 ส.ค. 2569 — คีย์ที่อ้าง inner process ต่างกันตามเครื่องมือ** · MCP `get_workflow_structure` → `config.process.processId` · hap CLI `workflow structure` → `flowNodeMap.<nodeId>.subProcessId` · ส่วน **approval sub-flow ผูกผ่าน `triggerId` (`appType:9`) ไม่ใช่ทั้งสองตัว** ⇒ สคริปต์หา orphan ต้อง **grep แบบ full-text ทั้ง output** อย่าเจาะจงคีย์ (จับผิดคีย์รอบแรกได้ผลลวงว่า "ทุก inner เป็น orphan") · และ workflow ที่ชื่อคล้ายกันและ `enabled` พร้อมกันอาจไม่ใช่ตัวซ้ำ — เช็ค `appType`/`triggerId` ก่อนสรุป

**จุดบอดของ hap CLI**
- 🔴 **[V] 28 ส.ค. 2569 — `hap workflow list <app>` ให้ผลไม่คงที่และไม่ครบ** · เรียก 3 ครั้งติดกันได้ 50 / 37 / 36 รายการ · inner ของ workflow ที่ใช้งานอยู่จริงไม่ปรากฏในการเรียกครั้งแรกเลย ⇒ **ผลจาก list ไม่ใช่หลักฐานว่า "ไม่มี"**
- 🔴 **[V] 28 ส.ค. 2569 — `hap workflow structure <id>` คืนโครงสร้างเต็มแม้ process ถูกลบไปแล้ว** ไม่มีอะไรบอกความต่างจากตัวที่ยังใช้งานอยู่เลย ⇒ **ใช้ยืนยันการมีอยู่ไม่ได้** · ตัวเดียวที่เชื่อถือได้คือ **`hap workflow get <id>` แล้วดูฟิลด์ `deleted`** (เกือบสรุปผิดว่า `delete_process` ไม่ทำงาน เพราะเช็คด้วย `structure`)

**ฝั่ง Browser (จากโปรเจกต์ WFH)**
- **Field cache bug** → ใช้ **Trigger Field** แทน Trigger Condition ไม่งั้น publish แล้ว error `1 nodes with abnormal at action selection` · **[?]** ยังไม่รู้ว่ากระทบสาย MCP ไหม
- **ค่า before-update เข้าถึงไม่ได้** → ใช้ฟิลด์ธง เงื่อนไข `not equal to 1` (ไม่ใช่ `equals 0` เพราะค่าอาจว่าง)
- **สาขา Branch ที่ไม่ใส่ filter ไม่ใช่ else — มันผ่านเสมอ**
- Approve node เลือกผู้อนุมัติได้เฉพาะฟิลด์ Collaborator บนตารางของ approval เอง · **[?]** สาย MCP อาจไม่มีข้อจำกัดนี้ (`approve.approvers` รับ `PersonRef` 7 แบบ)
- **`Read-only` ไม่กันการกรอกตอน *สร้าง* เรคอร์ด** (โดยเฉพาะมือถือ) → ฟิลด์ที่ workflow เขียน ต้องติ๊ก `Hide when adding a record`
- Scheduled trigger ใช้ **UTC+8** — ตั้ง 09:05 = 08:05 เวลาไทย

**🆕 Business Rules / Dynamic Default / Unique Index / Role Debugging (จาก TILSNA HR, 27 ส.ค. 2569 — ใช้ได้ทุกโปรเจกต์ Nocoly)**
- 🔴 **Relation-type field ของฟอร์มปัจจุบันใช้เป็นค่าเปรียบเทียบ (Dynamic Value) ไม่ได้เลย ทั้งใน Business Rules (ทุกแท็บ) และ Dynamic Default → "Query worksheet" → Query conditions** — field picker "Select fields from current form" แสดงเฉพาะ Text/Date/Number ของฟอร์มปัจจุบัน ค้นหาด้วยชื่อฟิลด์ตรง ๆ ก็ไม่เจอ ไม่ใช่แค่ scroll ไม่ถึง (ทดสอบยืนยันจริง — เดิมรู้แค่ว่า Business Rules ทำไม่ได้ รอบนี้ยืนยันเพิ่มว่า Dynamic Default ก็ทำไม่ได้เหมือนกัน) ⇒ **ทุก cross-table lookup ที่ต้องอ้างอิง Relation field ของฟอร์มปัจจุบัน (เช่น หา "หัวหน้าของพนักงานที่เลือกในฟอร์มนี้") ต้องย้ายไปทำที่ระดับ workflow เสมอ** (query worksheet node + update_record node — ดู §2 ข้อ 16 สำหรับวิธี query ข้าม relation ที่ถูกต้อง)
- 🔴 **Unique Index บนฟิลด์ที่ไม่ required จำกัดทั้งตารางให้มี record ที่ฟิลด์นั้นว่างได้แค่ 1 แถว** — ยืนยันจาก tooltip จริงของระบบที่หน้า Search Acceleration → Create Index: *"Once a unique index is established, the value of the field cannot be duplicated. If the field is not required, the entire worksheet can only have one empty record to ensure the uniqueness of the data."* ⇒ **ห้ามเปิด Unique Index บนฟิลด์ที่ไม่ required และไม่ auto-generate ค่าตอนสร้าง record** (เช่น เลขที่เอกสารที่ยังปล่อยว่างตอน Draft แล้วรอ workflow ใส่เลขทีหลัง) จนกว่าจะมีกลไก auto-generate ค่าให้ครบทุก record ก่อน ไม่งั้นจะสร้าง record ที่ 2 (ที่ฟิลด์นั้นยังว่าง) ไม่ได้ทันที
- ⚠️ **เลือก "Dynamic Value" ในช่องค่า (value-type dropdown) ของ Business Rules ต้องทำผ่านคีย์บอร์ด** — คลิกเปิด dropdown แล้วกด **Down แล้ว Enter/Return** เท่านั้น การคลิกเมาส์เลือกตรง ๆ จะเงียบและ dropdown เด้งกลับเป็น "Fixed Value" โดยไม่มี error ใด ๆ
- ⚠️ **ปุ่ม Escape ขณะแผงสร้าง/แก้ business rule (หรือแผง config อื่นที่คล้ายกัน) เปิดอยู่ จะปิดทั้งแผงและทิ้งข้อมูลที่ยังไม่ได้ Save ทันที** — ต้องใช้ปุ่ม **Cancel ของแผงเอง** หรือคลิกนอกแผงแทน ห้ามใช้ Escape เพื่อ "ปิดแบบไม่บันทึก"
- 🔴 **Agent tool call ที่ถูก reject/cancel โดยผู้ใช้ อาจยังทิ้ง side-effect ไว้บนเซิร์ฟเวอร์จริง (ghost object)** — พบจริง 2 ครั้งในเซสชันเดียวกัน (view ซ้ำ 8 อันจาก 2 ชุด × 4) ที่ยังค้างอยู่แม้ tool call ที่สร้างมันถูก reject ไปแล้วในเซสชันก่อนหน้า ⇒ **หลัง reject/cancel การเรียก tool ที่สร้าง object ใด ๆ ห้ามสันนิษฐานว่า "ไม่มีอะไรเกิดขึ้น"** ต้องเช็ค list ของจริง (เช่น `get_app_info`, view list) ก่อนเริ่มงานต่อ โดยเฉพาะถ้าเซสชันก่อนหน้าถูก compact/ตัดตอน
- ✅ **ทดสอบว่า Business Rule/field visibility ทำงานจริงหรือไม่ ให้ใช้ Role Debugging เสมอ ไม่ใช่ `get_record_logs`** — เปิดที่หน้า User/Role admin ของแอป (`/app/<appId>/role`) → toggle "Debug Role" เป็นเปิด → เลือก role ที่ต้องการ impersonate (เช่น Member) ที่ dropdown "Select Role" ในแถบนำทางบนสุดของแอป → เปิด record จริงดูว่าฟอร์ม render ตามกฎที่ตั้งไว้หรือไม่ (read-only/hide-show/ปุ่มที่ enableWhen) → **อย่าลืมสลับกลับเป็น Administrator แล้วปิด Debug Role toggle เมื่อทดสอบเสร็จ** · หมายเหตุ UI: ถ้า dropdown "Select Role" render ตกขอบขวาจอ ให้ resize browser window ให้กว้างขึ้น (เช่น 1800px) ก่อน

---

## 5. เช็กลิสต์

**ก่อนเริ่มทุก session**
1. `get_app_info` ยืนยัน connector ชี้แอปที่ถูก
2. **Gate 0** — เช็กว่า tool ที่จะใช้มีจริง (connector เปลี่ยนได้: 2 วันเคยพลิกมาแล้ว ทั้งเพิ่มและถอด)
3. เปิด BuildSpec §1 ก่อนพิมพ์ ID ใด ๆ — ห้ามพิมพ์จากความจำ
4. 🆕 ถ้าเซสชันก่อนหน้าถูก compact/ตัดตอน หรือมี Agent tool call ที่ถูก reject ค้างอยู่ — เช็ค list ของจริง (view/worksheet/record) ก่อนเริ่มงานต่อ เผื่อมี ghost object หลงเหลือ (ดู §4)

**ก่อนปิดงานเป็น ✅**
1. อ่าน ID จริงกลับมาแทน `<TBD>` ทุกตัว
2. workflow: `_updatedBy` ต้องเป็น `user-workflow` (`user-api` = เขียนมือ ไม่นับ)
3. approval ที่ยัง pending → **ห้ามปิด ✅**
4. เจอผลที่ขัดกับเอกสาร → ลง RTM §E ทันที · **เจอผลที่ขัดกับสกิล → patch สกิลด้วย**
5. 🆕 กฎฟอร์ม (Business Rule/visibility/ปุ่ม) → ทดสอบด้วย **Role Debugging** เสมอ ไม่ใช่ `get_record_logs` (ดู §4)

**ก่อนทำ destructive op**
- ระบุให้ชัดว่ากำลังอยู่ที่ connector/แอปไหน
- `delete_worksheet` / `delete_role` / `delete_record` / `batch_delete_records` / `update_worksheet.removeFields` → **ถามผู้ใช้ก่อน**
- `permanent: true` ต้องมีคำสั่งชัดเจนเท่านั้น
- ⚠️ connector **ไม่มี tool ลบ view / custom action / chart** — สร้างแล้วลบได้แค่ใน UI
- ⚠️ `delete_process_node` บน branch/block node **cascade ลบ subtree ทั้งหมด** — ประเมินผลกระทบก่อนเสมอ (ดู §2 ข้อ 2)

---

## 6. hap-cli — ช่องทางที่สาม (ยังไม่ได้ติดตั้ง)

`pip install hap-cli` แล้ว `hap auth login` — ให้ความสามารถที่ **MCP ไม่มีเลย**

| กลุ่ม | คำสั่ง |
|---|---|
| สื่อสาร | `contact` `department` `chat` `group` `post` `calendar` |
| แอปและข้อมูล | `app` `worksheet` `workflow` `approval` `custom-page` |
| เครื่องมือ | `region` `icon` `upload` |
| ระบบ | `auth` `config` `repl` |

**สี่เทคนิคที่ต้องรู้** [S]

1. **`--json` ต้องอยู่ระหว่าง `hap` กับ subcommand** — `hap --json worksheet record list WS_ID` ✅ · `hap chat list --json` ❌ (`--profile` ก็เหมือนกัน)
2. **ไล่จากข้อความแจ้งเตือนไปหาเรคอร์ด** — `hap --json chat messages --category app` คืน `appId` + `worksheetId` + `rowId` ครบชุด · **ห้ามใช้ `appId` ระดับห้องแชท** (เป็นแอปของศูนย์ข้อความ มักถูกลบแล้ว)
3. **SubTable ไม่อยู่ในเรคอร์ดแม่** — ตารางลูก = `dataSource` ของฟิลด์ SubTable · ฟิลด์โยงกลับ = `sourceField` · แก้ค่าทีละช่องให้ update ที่แถวลูกตรง ๆ
4. **`record create/update/delete` ไม่รับ `--app-id`** — ต้อง `hap app select <appID>` ก่อน · ดูฟิลด์ใช้ `hap worksheet fields WS_ID` (ไม่ใช่ `get`/`structure`)

**หลายสภาพแวดล้อม** (สำคัญกับคุณ เพราะต่อ 5 connector): `hap auth accounts` (ตัวที่ใช้อยู่มี `*`) · `hap auth use <ชื่อ>` · `hap --profile <ชื่อ> <คำสั่ง>` — และกฎคือ **ถ้าผู้ใช้ไม่ระบุ + op เป็น destructive → หยุดถาม ห้ามเดา ห้ามเลือก production เป็นค่าเริ่มต้น**

**ถ้าจะแก้แอปผ่าน CLI** — ต้องเป็น admin (`hap app list-managed` เช็กก่อน ไม่อยู่ในลิสต์ **ห้ามลองยิง**) · `update-fields` **ลบคอลัมน์ที่ไม่ได้ส่งไปด้วย** ห้ามใช้เพื่อเพิ่มฟิลด์ ใช้ `add-fields` · `view update` ใส่ชื่อ attr แต่ไม่ให้ค่า = ล้างค่าทิ้ง

---

## 7. ยังไม่รู้ / ต้องทดสอบ

| # | คำถาม | ทำไมสำคัญ |
|---|---|---|
| M-01 | `approve.approvers` รับ `PersonRef` แบบ `role`/`orgRole`/`department` ได้ไหม | ถ้าได้ = ตัดฟิลด์ `approver_user` + Update Record นำหน้าทิ้งได้ทุก approval flow |
| M-02 | trigger `filter` ผ่าน `create_process` ติด field-cache bug ไหม | เลิกใช้ workaround Trigger Field ได้ |
| M-03 | ~~`approval_block` สร้าง 2 จังหวะ + publish inner ก่อน main ได้จริงไหม~~ **ตอบแล้ว: สร้างพร้อม inner nodes ในคำเดียวได้จริง (ไม่ต้อง 2 จังหวะ) · publish inner ก่อน main ยังจำเป็น** | **[V] 26 ส.ค.** |
| M-04 | ~~`delete_process_node` แล้วสร้างใหม่ ระบบเชื่อม `prevNode` ให้ไหม~~ **ตอบแล้ว: `prevNode` ของ node ถัดไป auto-relink เอง แต่ filter/condition ที่อ้าง nodeId เดิมของ node อื่นไม่ auto-relink ต้องรื้อสร้างใหม่ทั้ง downstream chain** | **[V] 27 ส.ค.** |
| M-05 | `create_view` + `create_role.recordPermissionInViews` ทำ field-filtered visibility ครบวงจรไหม | ปิดช่องว่างที่เคยต้องพึ่ง Browser |
| M-06 | ปุ่ม `triggerWorkflow` ที่ auto-gen workflow มี trigger alias ใช้ได้ไหม | เคสเดียวที่ `triggerAlias` อาจใช้ไม่ได้ |
| M-07 | `create_custom_actions` / `create_chart` / `create_view` เรียกแล้วได้ object จริงไหม | **มีหลักฐานค้าน** — REST route ชื่อเดียวกันตอบ 405 body ว่าง |
| M-08 | `get_single`/`get_multiple` filter รูปแบบอื่น (`belongs`/`subordinate_contains`) ที่ยังไม่ได้พิสูจน์ตรง ๆ ใช้ได้จริงหรือไม่ (ปัจจุบันพิสูจน์แล้วเฉพาะ `contains` สำหรับ reverse-relation และ `in` สำหรับ relation-to-relation ที่ field ชนิดเดียวกัน — ดู §2 ข้อ 16) | กระทบทุก workflow ที่ต้อง cross-reference relation |
| M-09 🆕 | Dynamic Default มีวิธีอ้างอิง Relation field ของฟอร์มปัจจุบันแบบอื่นที่ไม่ใช่ "Query worksheet" หรือไม่ (เช่น formula/expression mode ถ้ามี) | ถ้ามี = ไม่ต้องย้าย DV ทุกเคสไป workflow |

**จุดที่เอกสาร hap-skills ขัดกันเอง** — SingleSelect เป็น type **9** (view-plugin + apiv3-data) หรือ **11** (api-website) · header เป็น `HAP-Appkey` หรือ `AppKey` · V3 มี `belongsto` หรือไม่มี · base URL: **บน Nocoly คือ `/api/v3/app/...`** ไม่ใช่ `/v3/app/...` **[V]**

---

## ที่มา

- ยิงจริงบนแอป `API-Lab` (24 + 26 ส.ค. 2569) — รายละเอียดใน `nocoly-api-lab/03-RTM-Status.md` §E
- โปรเจกต์ `nocoly-wfh-dgr` (ส.ค. 2569) — กับดักฝั่ง Browser
- โปรเจกต์ `tilsna-hr` — WF-HR-01 ยิงจริง 27 ส.ค. 2569 (get_single relation lookup, cascade delete, node-ref staleness) · WF-HR-02/WF-HR-03 ยิงจริง 27 ส.ค. 2569 (compute/get_single live re-evaluation, `kind:"record"` relation-write garbage) · P3-7/P3-8 ยิงจริง 27 ส.ค. 2569 (Business Rules + Dynamic Default relation-field limitation, Unique Index tooltip risk, Role Debugging workflow, ghost-object-after-reject, Dynamic Value/Escape UI quirks)
- `github.com/mingdaocom/hap-skills` commit `9d4ea6b` — 8 สกิล ~1.2 MB
- สกิล `nocoly-hybrid-builder-v2` v2.4.2 — `references/workflow-authoring-mcp.md`
