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
| **แก้** view / custom action หลังสร้าง | **hap CLI** — `hap worksheet view update <ws> <view> --name …` · `create-custom-action --btn-id …` | **[V] 28 ส.ค. — view update ยิงจริงสำเร็จ 5 ครั้ง** (MCP ไม่มี `update_*` ยังถูกต้อง แต่ **ไม่ต้องไป Browser แล้ว**) · แก้ปุ่มยัง [S] |
| trigger นอก 4 ชนิด (Personnel / External User / PBP / Subprocess / Custom Action) | Browser | [S] |
| node นอก 17 ชนิด (Loop / Terminate / Send API Request / JSON Parsing / Print / AI / SMS …) | Browser | [S] |
| bind ฟิลด์กับ shared optionset · print template · external portal · field default/validation | Browser | [V] จากโปรเจกต์ WFH |
| **Business Rule (Interaction/Validation/Lock)** | **hap CLI** `worksheet save-rule` | **[V] 6 ก.ย. — ดู §15** · ข้อจำกัด "อ้าง relation field ไม่ได้" ของ §4 ข้ามได้ด้วย Lookup field (§15.3) · 🔴 พิสูจน์ผลต้องเปิดฟอร์มจริง (§15.5) |
| **Dynamic Default (Query worksheet) · Unique Index** | Browser | **[V] 27 ส.ค. — ดูข้อจำกัดใน §4** |
| กด approve / reject / recall | Browser (To-do) หรือ org-auth API (gated) | [V] |
| หา `userId` / `departmentId` จาก**ชื่อคน** | UI หรือ org-auth API | **[V] — `find_member` ถูกถอดออกจาก connector แล้ว** |
| สร้าง**แอปใหม่** | UI หรือ org-auth API | [V] — connector ไม่มี `create_app` |
| แชท · ปฏิทิน · โพสต์ · อัปโหลดไฟล์ · ไล่จากข้อความไปหาเรคอร์ด | **hap-cli เท่านั้น** | [S] — **CLI ติดตั้งแล้วใช้ได้ ยืนยัน 30 ส.ค. (ดู §6)** ตัวคำสั่งกลุ่มนี้ยังไม่เคยยิง |
| **ดู workflow ทั้งแอป** (MCP `get_workflow_list` เห็นแค่ PBP) | `hap workflow list <appId>` — แต่ **ใช้เป็นหลักฐาน "ไม่มี" ไม่ได้** | 🔴 **[V] 28 ส.ค. — ผลไม่คงที่ 50/37/36 จาก 3 ครั้งติด** · ยืนยันการมีอยู่ต้อง `hap workflow get <id>` แล้วดู `deleted` |
| **หา `userId` / `departmentId` จากชื่อคน** | `hap contact search --keyword` · `hap department` | [S] — แทน `find_member` ที่ถูกถอดออก ไม่ต้องใช้ org-auth API แล้ว |
| **กด approve / reject / recall** | `hap approval todo` · `approve` · `reject` | [S] ⚠️ **ทำงานในนามบัญชีที่ล็อกอินอยู่** — ใช้กับแอปทดสอบ หรือเมื่อผู้อนุมัติยินยอมชัดเจนเท่านั้น (นโยบายเดียวกับ org-auth API) |

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
| 19 | 🔴🔴 **`FieldPatch.value{kind:"record", node:{...}}` เขียนลง Relation field แล้วได้ค่าขยะ ไม่ error ทั้งตอน `validate_process`/`publish_process` และตอนรันจริง** — ค่าที่บันทึกจริงกลายเป็น literal string ที่มี **node ID ภายในของ workflow** (เช่น `["6a8fa9a9fdab77a41c51cd9e"]`) ไม่ใช่ rowid ของ record จริงที่ node นั้นสร้าง/ดึงมา ⇒ อ่านกลับด้วย `get_record_details`/`get_record_list` relation field จะแสดง `已删除` ("ถูกลบ"/ไม่พบ) เพราะ node ID ไม่ตรงกับ rowid จริงในตาราง — พิสูจน์จริง (WF-HR-02, TILSNA): `add_record` ของ ledger ใช้ `{fieldId:<balance relation>, value:{kind:"record", node:{nodeAlias:"get_bal"}}}` เพื่อผูก relation กลับไปยังแถว balance ที่เพิ่งดึงมา ผลลัพธ์คือค่าขยะ ⇒ **ห้ามใช้ `kind:"record"` เพื่อเขียนค่าเข้า Relation field ที่ต้องการชี้ไปยัง "record ที่ node ต้นน้ำผลิต/ดึงมา"** ทางแก้ที่พิสูจน์แล้วว่าถูกต้อง (ยิงจริงแล้ว relation แสดงชื่อ record จริง ไม่ใช่ `已删除`): ใช้ `{kind:"field", node:{nodeAlias:<upstream node>}, fieldId:"rowid"}` แทน — อ้าง system field `rowid` ของ node ต้นน้ำตรง ๆ (ใช้ได้ทั้งกับ `get_single`/`add_record`/`trigger`) — หมายเหตุ: การ **copy ค่าจาก Relation field ที่มีอยู่แล้ว** (เช่น คัดลอก `trigger.employee` ไปยัง `add_record.employee`) ยังคงใช้ `kind:"field"` อ้าง fieldId ของ relation field ต้นทางตามปกติได้ปกติ (ทดสอบแล้วใช้งานถูกต้อง) — บั๊กนี้เกิดเฉพาะกรณีใช้ `kind:"record"` เพื่ออ้างอิง "ทั้ง record" ของ node อื่นเท่านั้น · 🆕 **31 ส.ค. — พบซ้ำข้ามโมดูล** ที่ WF-AC-02 (`add_record` ของ GL เขียน relation `voucher` เป็น `[{"sid":"[\"6a8ea7b8730d20c5b7604a55\"]","name":"已删除"}]` — sid คือ **nodeId** ไม่ใช่ rowid) ⇒ ไม่ใช่บั๊กเฉพาะ workflow ตัวเดียว **ต้องออดิตทุก node ที่เขียน Relation field ทั้งแอป** · **วิธีออดิต:** ไล่ `hap workflow node get <pid> <nodeId>` ทุก node ชนิด add_record(?)/update_record แล้วดู `fields[]` ที่ปลายทางเป็น Relation — **ถูกต้อง 2 แบบเท่านั้น** คือ (ก) `fieldValueId: "rowid"` (ชี้ record ที่ node ต้นน้ำผลิต/ดึงมา) และ (ข) `fieldValueId` = **fieldId ของ Relation field บน record ต้นทาง** (คัดลอก relation → relation) · **ผิดคือ** `kind:"record"` / `fieldValueId` ที่เป็น nodeId · **ยืนยันด้วยข้อมูลจริงเสมอ** — อ่าน record ที่ workflow สร้างแล้วดูว่า relation คืน `{"sid":"<uuid>","name":"<ชื่อจริง>"}` ไม่ใช่ `已删除` | **[V] 27 ส.ค. (HR) · 31 ส.ค. (บัญชี)** |
| 20 | 🔴 **`compute` ชนิด `computeType:"dateDiff"` ตัดพารามิเตอร์ `precision` ทิ้งเงียบ ๆ เมื่อ `outputUnit` เป็นหน่วยที่มีเศษ (`h`/`d`)** — ไม่ error ทั้ง `validate_process`/`publish_process` · อ่านกลับด้วย `get_workflow_structure` พบว่า config ที่บันทึกจริงไม่มี `precision` เลย ⇒ ผลถูก**ตัดทศนิยม** (ไม่ใช่ปัด) · ยืนยัน: 18:00–20:30 ผ่าน `dateDiff(outputUnit:"h", precision:2)` ได้ `"2.00"` แทน `"2.50"` · **ทางแก้ที่ยิงจริงแล้วได้ `"2.50"` ตรงเป๊ะ:** `dateDiff(outputUnit:"m")` แล้วต่อ compute ตัวที่สอง `computeType:"number"` (`expression:"$<alias>-number_fx_id$ / 60"`, `precision:2`) — **numeric compute เคารพ `precision` ปกติ ต่างจาก `dateDiff`** | **[V] 27 ส.ค.** |
| 21 | 🔴 **ปุ่มที่สร้างผ่าน `create_custom_actions` มี Scope เริ่มต้น "Unassigned View" เสมอ — ไม่โผล่บนหน้าจอเลย** แม้ tool คืน `success:true`+`actionId` ปกติ · พบซ้ำ 2 โมดูล (บัญชี `ac_voucher` 26 ส.ค. · HR `hr_ot_request` 27 ส.ค.) ⇒ เป็นพฤติกรรมของทุกปุ่มที่สร้างผ่าน MCP ไม่ใช่บั๊กเฉพาะโมดูล · **ทางแก้:** เปิด record ใดก็ได้ → เมนู "…" → **Edit Custom Action** → Form Settings → Custom Action → คลิกลิงก์ **Scope** ท้ายแถวปุ่ม → เลือก **All Records** (หรือ Specified View) → บันทึกทันทีที่คลิก ไม่มีปุ่ม Save · ⇒ **ตั้ง Scope ใน Browser เป็นขั้นตอนที่สองเสมอ ก่อนนับว่า DoD "เห็นปุ่มโผล่จริง" ผ่าน** · 🆕 **ตรวจได้จาก CLI ไม่ต้องเปิด Browser:** `hap worksheet custom-actions <ws_id>` คืนฟิลด์ **`isAllView`** ตรง ๆ — `1` = All Records (ผู้ใช้เห็นปุ่ม ✅) · `0` + `displayViews: []` = **Unassigned View (ไม่โผล่ที่ไหนเลย ❌)** (ยิงจริงทั้งสองโมดูล: บัญชี `ac_voucher` 3 ปุ่ม = `1`, `ac_period` 2 ปุ่ม = `0` · HR ทุกปุ่ม = `1`) · **การ *ตั้ง* ค่ายังต้อง Browser เหมือนเดิม** (ยังไม่ทดสอบว่า `create-custom-action --btn-id` เขียน `isAllView` ได้ไหม) | **[V] 26–31 ส.ค.** |
| 22 | 🔴 **`workflow structure` ไม่คืนเงื่อนไขของ node ที่ไม่ใช่ branch** — `filters` ของ search (typeId 7) และ get_multiple (typeId 13) หายไปทั้งก้อน คืนแค่ `appId`/`executeType` ⇒ **ห้ามใช้ `workflow structure` สแกนหาเงื่อนไขทั้ง workflow** จะได้ภาพที่ไม่ครบและดูเหมือนสะอาด · วิธีที่ถูก: ไล่ `hap workflow node get <pid> <nodeId>` **ทีละ node** แล้วเก็บทุก object ที่มีคีย์ `conditionId` (มันซ้อนอยู่คนละคีย์กัน — branch=`conditions` · search/get_multiple=`filters[].conditions`) · ต้นทุนจริง ~1 คำขอต่อ node (12 process HR = ~200 คำขอ ใช้เวลาไม่กี่นาที) | **[V] 30 ส.ค.** |
| 23 | 🔴🔴 **`hap workflow node save-get-more --condition` เก็บแค่ OR group แรก ทิ้งที่เหลือเงียบ ๆ** — ส่ง `[[A],[B]]` แล้ว rc=0 ตอบ `GetMoreRecord node saved.` แต่อ่านกลับเหลือกลุ่มเดียว · ยังมีผลข้างเคียงอีก 2 อย่างที่ไม่ได้ขอ: `relation` ถูกรีเซ็ต `true`→`false` และ `filters[0].spliceType` `1`→`2` ⇒ **ต้องอ่านกลับเทียบทุกคีย์หลัง save เสมอ ไม่ใช่ดูแค่เงื่อนไข** | **[V] 30 ส.ค.** |
| 24 | ⚠️ **`hap workflow node save --type 13` ต้องส่ง config ที่เขียนได้ครบทั้งก้อน** (`actionId` `appId` `appType` `name` `desc` `fields` `sorts` `numberFieldValue` `execute` `relation` `random` `conditions` `filters`) — ส่งแค่คีย์เดียว (เช่น `{"filters": …}`) ได้ **500 Internal Server Error** · ต่างจาก branch (`--type 2`) ที่ส่งแค่ `{"operateCondition": …}` ได้ · เมื่อส่งครบ **OR group หลายกลุ่มลงได้จริง** (ต่างจาก `save-get-more`) | **[V] 30 ส.ค.** |
| 25 | ⚠️ **`hap workflow trigger <pid>` กับ workflow ชนิด schedule/timer คืน instance object มาปกติแต่ไม่ได้รันตัว flow จริง** — ยืนยันด้วย control case (ตั้งฟิลด์ให้ผ่านเงื่อนไขแน่นอนแล้ว trigger ก็ยังไม่มีอะไรเปลี่ยน) ⇒ **ห้ามใช้ผลจาก `workflow trigger` สรุปว่า schedule workflow ทำงานหรือไม่ทำงาน** ต้องรอรอบจริง หรือดู **Workflow History** บนเบราว์เซอร์ | **[V] 30 ส.ค.** |
| 26 | ✅ **`sub_process` ซ้อนใน `sub_process` สร้าง publish และ *รันจริง* ได้** — พิสูจน์ด้วย probe: outer loop 2 แถว × inner loop 2 แถว ได้ผลลัพธ์ **4 record ครบ cross product** · **ลำดับ publish ต้องจากในสุดออกนอกสุด** (inner-inner → inner → main) ไม่งั้น `NodeAppIsNull` ตามข้อ 9 · ภายใน sub_process ชั้นในสุด `sub_trigger` หมายถึง **record ของลูปชั้นในสุด** (ชั้นนอกถูกบัง) · เขียน `config.process.nodes` ซ้อนกันได้ตรง ๆ ในคำสั่ง `batch_create_process_nodes` เดียว | **[V] 31 ส.ค.** |
| 27 | 🔴🔴 **`delete_process` ที่ main flow *ไม่* cascade ลบ inner process ของ `sub_process`** — ยืนยันด้วย probe ที่มี sub_process ซ้อน 2 ชั้น: ลบ main แล้วอ่าน `workflow get` ของ inner ทั้ง 2 ตัวยังได้ `deleted:false, enabled:true` ⇒ **ต้องเก็บ processId ของทุก inner ไว้ตั้งแต่ตอนสร้าง (`createdNodes[].processId` + `get_workflow_structure` ของ inner) แล้วไล่ `delete_process` เองทุกตัว** · แก้ความเข้าใจเดิมในข้อ "จุดบอดของ connector" ที่เขียนว่า `delete_process_node` ไม่ cascade *เหมือน* `delete_process` — ที่จริง `delete_process` ก็ไม่ cascade เข้า sub_process เหมือนกัน | **[V] 31 ส.ค.** |
| 28 | 🔴🔴 **เขียนค่าลงฟิลด์ตัวเลือก (SingleSelect/Dropdown/MultipleSelect) ด้วย `{kind:"literal"}` ต้องใส่ *option key* ไม่ใช่ข้อความที่แสดง** — ใส่ข้อความ (เช่น `"Probation"`) แล้ว `validate_process`/`publish_process` ผ่าน · รันจริงก็ไม่ error · แต่ **ฟิลด์ว่างเปล่า** · พิสูจน์: WF-HR-17 ยิงครั้งแรกด้วย `"Probation"` → `emp_status` ว่าง · เปลี่ยนเป็น key `d477a6b5-…` ยิงใหม่ → ได้ `Probation` · เป็นอาการเดียวกับข้อ 17/19 (เขียนเงียบ ๆ ไม่มี error) และตรงกับกฎใน §3 ที่ว่า *ตัวเลือก → key ของ option ไม่ใช่ข้อความ* — แต่กฎนั้นเขียนไว้ใต้หัวข้อ filter คนจึงพลาดตอนเขียนค่า · **วิธีกวาดทั้งแอป:** ไล่ทุก `fields[]` ที่ปลายทาง `type` เป็น 9/10/11 และมี `fieldValue` แต่ไม่มี `fieldValueId` แล้วเช็คว่า `fieldValue` เป็น GUID · **กวาดฝั่ง HR แล้ว 23 จุด ผ่านหมด** | **[V] 31 ส.ค.** |
| 29 | ✅ **`add_record`/`update_record` ของ workflow ข้ามการตรวจ `required` เหมือนที่ข้าม `isUnique`** — สร้าง `hr_employee` ได้ทั้งที่ `emp_user` (Collaborator) ตั้ง required ไว้ ⇒ **`required` เป็นด่านของฟอร์มเท่านั้น ไม่ใช่ข้อจำกัดของ workflow** · มีประโยชน์: workflow สร้าง record ตั้งต้นแล้วให้คนมาเติมฟิลด์ที่ resolve เองไม่ได้ (เช่น userId) ทีหลังได้ · มีโทษ: **ข้อมูลไม่ครบเข้าระบบได้เงียบ ๆ** ⇒ ถ้าฟิลด์ไหนสำคัญจริงต้องมีการแจ้งเตือนตามหลัง ไม่ใช่พึ่ง `required` | **[V] 31 ส.ค.** |
| 30 | ✅ **พารามิเตอร์ของ sub_process (`process_variable`) เขียนลง Relation field ได้** — ส่ง rowid เป็น `type:"text"` เข้า `inputFields` แล้วใน sub_process ใช้ `{kind:"field", node:{nodeAlias:"process_variable"}, fieldId:"<param>"}` เขียนลงฟิลด์ Relation ตรง ๆ · อ่านกลับได้ `{"sid":"<rowid จริง>","name":"<ชื่อ record>"}` ไม่ใช่ `已删除` · ใช้ใน template ได้ด้วย (`$process_variable-<param>$`) · พิสูจน์กับ WF-HR-18 (ส่ง rowid ของรอบประเมินเข้าไปในลูปต่อพนักงาน) | **[V] 31 ส.ค.** |

| 31 | 🔴 **ห้ามใส่ `filter` ใน trigger ของ `worksheet_event`** — ใส่แล้ว workflow **ไม่ยิงเลยและไม่มี error ใด ๆ** · พิสูจน์ด้วย workflow ควบคุมที่ไม่มี filter ซึ่งยิงได้ปกติ ⇒ **เอาเงื่อนไขไปไว้ใน branch แรกแทนเสมอ** | [V] |
| 32 | 🔴 **`sub_process` โหมด `use_existing` ที่อ้าง process ซึ่ง publish ไปแล้ว สร้าง node ไม่ได้** — ต้องอ้างตัวที่ยังไม่ publish หรือใช้โหมดสร้างใหม่ | [V] |
| 33 | 🔴🔴 **relation-to-record มี 2 รูปแบบที่ถูก ไม่ใช่รูปแบบเดียว** — (ก) `fieldValueId:"rowid"` + `nodeId` (ข) **`nodeId` + `fieldValueId` ว่าง** ← สิ่งที่ **หน้าจอเขียนออกมาเองเมื่อเลือก node object** จึงเป็น canonical และจะเกิดกับทุก node ที่คนแก้ผ่าน UI ⇒ **สคริปต์ออดิตที่ใช้เกณฑ์ `fieldValueId=="rowid"` อย่างเดียวจะฟ้องรูปแบบ (ข) ว่าผิดทั้งที่ถูก** | [V] |
| 34 | 🔑 **วิธีสแกนบั๊ก Relation ด้วยตาที่เร็วที่สุด: เปิด node ในหน้าจอแล้วดูช่อง relation — ถ้ามัน "ว่าง" ทั้งที่ JSON มี `fieldValue` แปลว่าค่าที่เก็บเป็น literal ดิบ** (UI แปลงเป็น node object ไม่ได้จึงไม่แสดง) · เป็นอาการของรูปร่างที่เขียน nodeId ลงไปเป็นสตริง แล้วอ่านกลับได้ `已删除` | [V] |
| 35 | 🔴 **ปุ่ม custom action ชนิด `updateCurrentRecord` ไม่ auto-apply ค่าที่ตั้งไว้** — ต้องมี workflow รับช่วงต่อ | [S] |

| 36 | 🔑 **`code` node: ค่าที่ input ได้รับ ไม่เหมือนที่เก็บในฟิลด์** — **Checkbox มาเป็นสตริง `"1.0"` / `"0.0"`** (ไม่ใช่ `"1"`/`"0"`) และ **Dropdown มาเป็น *ข้อความที่แสดง* ไม่ใช่ option key** ⇒ `=== '1'` และการแมตช์ด้วย option key **พังเงียบทั้งคู่** · **เทียบ Checkbox ด้วยตัวเลข (`parseFloat(v) === 1`) และแมตช์ Dropdown ด้วยข้อความ (หรือรับทั้งสองแบบ)** | [V] 1 ก.ย. 69 |
| 37 | 🔑 **วิธีดีบัก `code` node ที่เร็วที่สุด: เพิ่ม output `trace` ที่ต่อสตริงค่าดิบของทุก input แล้วเขียนลงฟิลด์ Text ชั่วคราว** ยิงหนึ่งรอบแล้วอ่านค่าจริง — เห็นภายในนาทีเดียว แทนการเดาจาก schema · **ลบ node/ฟิลด์ที่ใช้ trace ออกทุกครั้งหลังใช้เสร็จ** อย่าปล่อยให้เขียนทับฟิลด์ธุรกิจ | [V] 1 ก.ย. 69 |
| 38 | ⚠️ **`rollup` ที่ filter แล้วไม่เจอแถวเลย คืนค่า *ว่าง* ไม่ใช่ 0** ⇒ ฟิลด์ปลายทางถูกปล่อยว่าง แล้วไปชนกับบทเรียน "เงื่อนไข `=`/`ne` กับค่าว่าง" ปลายน้ำ · `compute` ที่ตั้ง `nullZero` ช่วยเฉพาะการคำนวณ **ไม่ได้ช่วยค่าที่เขียนลงฟิลด์** | [V] 1 ก.ย. 69 |
| 39 | 🔑 **`code` node สร้างผ่าน MCP ได้ และคุ้มมากเมื่อตรรกะมีหลายมิติคูณกัน** — สูตรที่ต้องใช้ branch ~10 node รวมเหลือ node เดียว · แก้ทีหลังง่ายกว่ามากเพราะ MCP แก้ node ไม่ได้ ต้องลบ–สร้างใหม่ (ลบ 1 node ดีกว่าลบ 10) · แลกกับตรรกะไม่ปรากฏบนผังใน UI | [V] 1 ก.ย. 69 |

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
- 🔴 **[V] 1 ก.ย. 2569 — `defaultValue` ของฟิลด์ "ตั้งได้ แต่ไม่ถูกใช้ตอนสร้าง record ผ่าน API"** · ตั้ง default `0` บนฟิลด์ธงแล้วสร้าง record ด้วย `create_record` โดยไม่ส่งฟิลด์นั้น ⇒ **ได้ค่าว่าง ไม่ใช่ 0** (ทดสอบจริงแล้วลบ record ทิ้ง) ⇒ **default ช่วยเฉพาะ record ที่คนกรอกผ่านฟอร์ม** · ทุก record ที่ workflow/API สร้างจะมาพร้อมฟิลด์ธงว่างเสมอ
  ⇒ **กฎที่ใช้ได้จริง 2 ข้อ: (1) workflow ที่สร้าง record ต้องเขียนค่าธงลงไปเองทุกครั้ง (2) ทุกเงื่อนไข branch ที่อ่านธงต้องทนค่าว่าง** (กระจาย AND ลง OR group ที่มี `is empty`) — อย่าไปหวังพึ่ง default
- 🔴 **[V] 1 ก.ย. 2569 — `update_worksheet.editFields` ที่ส่งมาแค่ `config` ล้างทั้ง `name` และ `alias` ของฟิลด์นั้นเป็นสตริงว่าง** · เดิมไกด์เขียนไว้แค่ "ส่งแค่ `name` จะล้าง `alias`" ซึ่ง**แคบเกินไป** — ของจริงคือ **ฟิลด์ใดที่ไม่ส่งไปด้วยจะถูกล้าง** ⇒ **ส่ง `name` + `alias` + `config` ครบทุกครั้ง แล้วอ่านกลับมายืนยันทันที** (เจอเพราะผลลัพธ์เรียก field ด้วย ID แทน alias)
- 🔴 **[V] 1 ก.ย. 2569 — รูปแบบเลข AutoNumber: ลากสลับลำดับกฎในหน้าจอ "ดูเหมือนสำเร็จ" แต่ไม่ถูกบันทึก** · ลากแล้วหน้าจอแสดงลำดับใหม่ · กด Save ขึ้น "Saved" · แต่พอ panel re-render กลับเป็นลำดับเดิม และ **record ที่สร้างหลังจากนั้นยังได้รูปแบบเดิม** (พิสูจน์ด้วยการสร้าง record จริงแล้วอ่านค่า ไม่ใช่ดูหน้าจอ)
  ⇒ **แก้ผ่าน API แทน: `update_worksheet.editFields[].config.rules`** ซึ่งเป็น **อาร์เรย์ที่มีลำดับ** และเขียนทับทั้งชุด — `{"type":"text","value":"GL-"}` แล้ว `{"type":"sequence","length":6,"repeat":"never"}` ได้ `GL-000033` · ตัวนับ**เดินต่อจากเดิม ไม่รีเซ็ต**
  ⚠️ **บทเรียนวิธีตรวจ:** ทั้ง toast "Saved" และ panel ที่ re-render **เชื่อไม่ได้ทั้งคู่** — ตัวชี้ขาดเดียวคือสร้าง record จริงหนึ่งแถวแล้วอ่านค่าที่ได้ แล้วลบทิ้ง
- ⚠️ **[V] 1 ก.ย. 2569 — `hap worksheet fields` (และ `get_worksheet_structure`) ไม่คืน `advancedSetting` ของฟิลด์** ⇒ **มองไม่เห็น** รูปแบบเลข AutoNumber (`advancedSetting.increase`) และค่า default (`advancedSetting.defsource`) · ต้องใช้ **`hap worksheet fields <wsid> --raw`** ถึงจะเห็น ⇒ อย่าสรุปว่า "ฟิลด์ไม่ได้ตั้ง default/รูปแบบ" จากผลของ `fields` เฉย ๆ
- **เลี่ยง Formula field** — dialog แก้สูตรไม่เสถียร ใช้ Number + node คำนวณแทน
- **API ผูก shared optionset ไม่ได้** → ทุก SingleSelect ใช้ inline options ⇒ ตัวเลือกชื่อเดียวกันคนละตาราง **key คนละค่า**
- 🔴 **เงื่อนไข `ne` กับฟิลด์ที่ค่ายังว่างอยู่ไม่ผ่าน — พิสูจน์แล้วใน branch (ใน `filters` ของ get_multiple ไม่เป็นแบบนั้น · context อื่นยังไม่รู้)** (แม้ logically ว่าง≠1 ควรจริง) — ฟิลด์ธง (flag) ทุกตัวต้องตั้ง **default 0** และ backfill record เดิมก่อนใช้เงื่อนไข `not equal to 1` ในสาย gate/anti-duplicate — ยืนยันจริงหลายโปรเจกต์ (WFH, บัญชี, HR) · ⚠️ **แก้ 31 ส.ค. 2569:** ข้อนี้เคยเขียนเหมารวมทุกที่ **ซึ่งผิด** — ใน `filters` ของ **get_multiple (typeId 13)** เงื่อนไข `≠` ผ่านค่าว่างตามปกติ (พิสูจน์ด้วย probe workflow) — **ส่วน trigger filter / search(7) ยังไม่เคยทดสอบ** ⇒ อ่านหัวข้อ `เงื่อนไขและ operator…` ท้ายไฟล์ก่อนตัดสินใจแก้จุดใด

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

## 6. hap-cli — ช่องทางที่สาม (✅ ติดตั้งแล้ว ใช้งานได้จริง)

> ✅ **[V] 30 ส.ค. 2569 (agent-ac) — availability gate ผ่านครบ 3 ข้อ ไม่ต้องติดตั้งอะไรเพิ่ม**
> ```
> hap --version        → hap 0.8.21
> hap auth whoami      → Wanadtapong.l · org VBix · host https://www.nocoly.com
> hap app list-managed → *  deca7391-1761-424b-9af3-c8d043004ad3  ERP - TILSNA  69
> ```
> เครื่องหมาย `*` แปลว่าแอปนี้ถูก select อยู่แล้ว ⇒ **Surface C เปิดใช้ได้ทันที** ข้อความเดิมที่ว่า "ยังไม่ได้ติดตั้ง" ทำให้ agent หลายรอบเลี่ยงไปใช้ Browser ทั้งที่ไม่จำเป็น
> ⚠️ ถ้ารันแล้วพัง **ให้แยกสาเหตุก่อนสรุปว่า "ไม่มี CLI"**: ยังไม่ล็อกอิน · org ปิดสวิตช์ "CLI access" (แอดมินต้องเปิด) · encoding (Windows ต้อง `$env:PYTHONUTF8="1"` ไม่งั้นชื่อไทยทำคำสั่งพังแบบดูเหมือน CLI เสีย) · `--token` รับ session cookie `md_pss_id` **ไม่ใช่ PAT**

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
| M-07 | ~~`create_custom_actions` / `create_chart` / `create_view` เรียกแล้วได้ object จริงไหม~~ ✅ **ปิดครบทั้งชุดแล้ว: view · chart · custom-page · ปุ่ม custom action สร้างได้จริงและใช้งานได้จริงทั้งหมด** (ผ่าน `hap` CLI) | **[V] 6 ก.ย. — view/chart/page ดู §8 · ปุ่มดู §12** |
| M-08 | `get_single`/`get_multiple` filter รูปแบบอื่น (`belongs`/`subordinate_contains`) ที่ยังไม่ได้พิสูจน์ตรง ๆ ใช้ได้จริงหรือไม่ (ปัจจุบันพิสูจน์แล้วเฉพาะ `contains` สำหรับ reverse-relation และ `in` สำหรับ relation-to-relation ที่ field ชนิดเดียวกัน — ดู §2 ข้อ 16) | กระทบทุก workflow ที่ต้อง cross-reference relation |
| M-09 🆕 | Dynamic Default มีวิธีอ้างอิง Relation field ของฟอร์มปัจจุบันแบบอื่นที่ไม่ใช่ "Query worksheet" หรือไม่ (เช่น formula/expression mode ถ้ามี) | ถ้ามี = ไม่ต้องย้าย DV ทุกเคสไป workflow |

**จุดที่เอกสาร hap-skills ขัดกันเอง** — SingleSelect เป็น type **9** (view-plugin + apiv3-data) หรือ **11** (api-website) · header เป็น `HAP-Appkey` หรือ `AppKey` · V3 มี `belongsto` หรือไม่มี · base URL: **บน Nocoly คือ `/api/v3/app/...`** ไม่ใช่ `/v3/app/...` **[V]**

---

## 8. View / Chart / Custom page — ยืนยันจริง 6 ก.ย. 2569 (แอป ERP TILSNA, โมดูล HR)

`[V]` **สร้าง view / chart / custom page ผ่าน `hap` CLI ได้จริง** — ปิดคำถาม M-07 ที่เคยเขียนว่า "มีหลักฐานค้าน (REST 405)" · หลักฐาน: สร้าง 15 view (table / kanban / hierarchy / gallery / calendar / gantt), 10 chart (column / pie / funnel / ranking / number) และ custom page `แดชบอร์ด HR` ที่วาง 10 chart แล้วอ่านกลับได้ครบด้วย `worksheet view list|info`, `worksheet chart get`, `custom-page info` (`version` เพิ่มจาก 0 → 1)

### 8.1 กับดัก: อ้างของที่ไม่มีจริง แล้วระบบ "รับ" เงียบ ๆ

`[V]` 🔴🔴 **filter ของ view รับ `controlId` ที่ไม่มีอยู่บน worksheet โดยไม่ error** — view ถูกสร้างสำเร็จ คืน `viewId` ปกติ แต่เงื่อนไขผูกกับ field ที่ไม่มี ⇒ กรองผิด/ว่าง · เจอจริง: ใส่ `6a8fcd7f353e1b0e4a507d47` แทน `...d44` (`hr_att_status`) · **ต้องอ่านกลับด้วย `worksheet view info` แล้วเทียบ `controlId` กับรายการ field จริงเสมอ**

`[V]` 🔴🔴 **filter ของ view รับ option key ที่ไม่มีใน option set ของ field นั้นโดยไม่ error** — view สร้างสำเร็จ แต่ตอนใช้งาน**คืน 0 แถวเงียบ ๆ** · เจอจริง 3 view (`รออนุมัติ`, `มาสาย / ขาดงาน`, `OT ที่อนุมัติแล้ว`) ที่ใช้ key ซึ่งไม่มีในฟิลด์สถานะเลย · **กฎ: ต้อง dump option key จาก `hap worksheet fields <ws> --raw` ณ เวลาที่สร้าง ห้ามใช้ key จาก map ที่ cache ไว้** (แผนที่ที่ cache ไว้เมื่อ 1 ก.ย. ยังถูก แต่ key ที่ใช้จริงตอนสร้าง view กลับผิด — แปลว่าจุดพลาดคือ "ไม่ได้อ่านตอนสร้าง")

`[V]` 🔴 **`filter.viewId` ของ chart รับ viewId ที่ไม่มีจริงโดยไม่ error** — เจอจริง: chart `จำนวนพนักงานตามระดับตำแหน่ง` ชี้ `6a8efa5e9762533b5b7185c4` ขณะที่ view "ทั้งหมด" จริงคือ `...c5` (`view info` ตอบ `Service exception` เมื่อถามด้วย id ปลอม = วิธีตรวจ) · แก้ด้วย `chart get` → แก้ค่า → `chart update` (ต้องส่ง config ทั้งก้อนกลับ)

### 8.2 กับดัก: หลาย condition ใน `groupFilters` เป็น AND ไม่ใช่ OR

`[V]` 🔴🔴 **สอง condition ใน `groupFilters` ถูก AND เข้าด้วยกัน** — เขียน "สถานะ = Late" + "สถานะ = Absent" เป็นสอง condition ⇒ view คืน **0 แถว** (เป็นไปไม่ได้ที่ค่าเดียวจะเท่ากับสองค่า) ทั้งที่มีข้อมูลตรงเงื่อนไข 4 แถว · **วิธีที่ถูก: ใช้ condition เดียว `filterType: 2` แล้วใส่ key หลายค่าใน `values` (และ `value` เป็น JSON string ของ list เดียวกัน)** · หลังแก้: 0 → 4 แถวทั้งสอง view

### 8.3 กับดัก: `chart list` บน worksheet ที่ยังไม่มี chart จะ**สร้าง** chart ให้ 2 อัน

`[V]` 🔴🔴 **`hap worksheet chart list <ws>` เป็นคำสั่งอ่าน แต่มี side effect** — ถ้า worksheet นั้นยังไม่มี chart เลย ระบบจะ seed chart เริ่มต้นให้ 2 อันชื่อ `Add new<ชื่อ worksheet>` (reportType 10) และ `Add new (daily)<ชื่อ worksheet>` (reportType 1) · พิสูจน์: เรียก list บน `hr_welfare_scheme` แล้วได้ chart id `6a9cec4c…` ซึ่ง timestamp ในตัว id = **9 วินาทีก่อนหน้า** (เวลาที่เรียกคำสั่งพอดี) · เจอซ้ำบน 5 worksheet · **ผลข้างเคียง: "ตรวจสอบ" ด้วยการ list ทำให้เกิดขยะที่ต้องลบทิ้ง — ใช้ `chart get <reportId>` ตรวจแทนเมื่อรู้ id แล้ว** · ลบขยะได้ด้วย `hap worksheet chart delete <reportId> -y`

### 8.4 การ verify view ทำไม่ได้ด้วย `record list --view-id` ทุกชนิด

`[V]` **`hap worksheet record list <ws> --view-id <v>` คืน 0 แถวสำหรับ view บางชนิด แม้ข้อมูลมีจริง** — ไม่ใช่ view พัง แต่เป็นข้อจำกัดของ API path นี้:

| viewType | ชนิด | `record list --view-id` | หมายเหตุ |
|---|---|---|---|
| 0 (ไม่มี group) | ตาราง | ✅ ได้จำนวนจริง | ใช้ verify ได้ |
| 0 + `advancedSetting.groupsetting` | ตารางแบบจัดกลุ่ม | ❌ คืน 0 | **พิสูจน์แล้ว: ลบ `groupsetting` ออก → 0 → 14 แถวทันที** |
| 1 | Kanban | ❌ คืน 0 | ต้องตรวจด้วยตาบน UI |
| 2 | ผังลำดับชั้น | ⚠️ คืนเฉพาะ node ระดับบน (10 คน → 2) | ปกติ |
| 3 | Gallery / การ์ด | ✅ ได้จำนวนจริง | |
| 4 | ปฏิทิน | ✅ ได้จำนวนจริง | |
| 5 | Gantt | ❌ คืน 0 | ต้องตรวจด้วยตาบน UI |

**กฎ:** อย่าสรุปว่า view เสียเพราะ `record list --view-id` คืน 0 — ต้องดูชนิด view ก่อน · และอย่าสรุปว่า view "ผ่าน" เพราะสร้างสำเร็จ — ต้องนับแถวจริงสำหรับชนิดที่นับได้

### 8.5 สูตรที่ใช้ได้จริง

```bash
# view: สร้างแล้วอ่านกลับทันที
hap worksheet view create <ws> --name "..." --view-type 1 --view-control <controlId>
hap --json worksheet view info <ws> <viewId>      # ตรวจ controlId / option key / viewControl

# view: แก้เฉพาะบางแอตทริบิวต์ (ที่เหลือคงเดิม)
hap worksheet view update <ws> <viewId> --view-json '{"filters": [...]}' --edit-attrs filters
hap worksheet view update <ws> <viewId> --view-json '{"advancedSetting": {...}}'     --edit-attrs advancedSetting --edit-ad-keys groupsetting

# chart: ต้องมี filter scope เสมอ (CLI backfill ให้ถ้าไม่ใส่) — normType 1=sum 2=max 3=min 4=avg 5=count
hap worksheet chart create <ws> --name "..." --report-type 1 -j '{"xaxes":{...},"yaxisList":[{...}],"filter":{"filterRangeId":"ctime","rangeType":0,"today":false}}'
hap --json worksheet chart get <reportId>          # ตรวจว่า controlName ถูก backfill = id ถูกจริง

# custom page: สร้าง section → สร้าง page → save layout (grid 48 คอลัมน์)
hap app add-section <appId> -n "HR-07 Dashboard" --parent-id <sectionId>
hap custom-page create <appId> "แดชบอร์ด HR" --section-id <newSectionId>
hap custom-page save <pageId> --version 0 --components '[{"type":1,"value":"<reportId>", ...}]'
```

`[V]` **`chart get` เป็นเครื่องมือ verify ที่ดีเพราะ server backfill `controlName` ให้** — ถ้า `controlId` ที่ส่งไปไม่มีจริง `controlName` จะว่าง ⇒ ใช้แยก "id ถูก" กับ "id มั่ว" ได้โดยไม่ต้องเทียบเอง

`[V]` **`custom-page save` ต้องส่ง `--version` ให้ตรงกับ version ปัจจุบันของ page** (page ที่เพิ่งสร้าง = 0) และ **save ทับทั้งหน้า** — ถ้าจะเพิ่ม component ต้องอ่าน `custom-page info` มาต่อท้ายก่อน

---

## 9. รูปแบบวันที่ (`advancedSetting.showformat`) — ยืนยันจริง 6 ก.ย. 2569

### 9.1 ค่ารหัสของ `showformat` — เปิดหน้าจอดูแล้วทั้ง 3 แบบ

`[V]` ฟิลด์ Date (type 15) / DateTime (type 16) เก็บรูปแบบแสดงผลไว้ที่ `advancedSetting.showformat` ซึ่งรับได้ทั้ง **รหัสตัวเลข** และ **แพตเทิร์นตรง ๆ**:

| `showformat` | แสดงผลจริงบนหน้าจอ | หมายเหตุ |
|---|---|---|
| `"1"` | **`2001年12月2日`** | 🔴 **ค่าเริ่มต้นของแพลตฟอร์ม = รูปแบบจีน** — ฟิลด์ที่ไม่เคยตั้งค่าจะเป็นแบบนี้เสมอ |
| `"0"` | `2026-08-28` | ISO — ไม่ใช่จีน แต่ก็ไม่ใช่รูปแบบไทย |
| `"DD/MM/YYYY"` | `28/08/2026` | ✅ มาตรฐานของโปรเจกต์นี้ |
| `"DD/MM/YYYY HH:mm"` | `28/08/2026 07:52` | ✅ มาตรฐานสำหรับ DateTime |
| `"yyyy-MM-dd HH:mm"` | 🔴 **`2026-08-Fr 07:52`** | **พัง** — ดู §9.2 |

หลักฐาน: `ทะเบียนพนักงาน.วันเกิด` แสดง `2001年12月2日` · `บันทึกลงเวลา.วันที่ทำงาน` แสดง `2026-08-28` · หลังแก้ทั้งสองตารางแสดง `28/08/2026` และ `28/08/2026 07:52` (ดูด้วยตาบนหน้าจอทั้งก่อนและหลัง)

### 9.2 🔴🔴 ตัวพิมพ์เล็ก-ใหญ่ผิด = วันที่ผิดแบบเงียบ ๆ (ไม่ใช่แค่ "หน้าตาไม่สวย")

`[V]` แพตเทิร์นตีความแบบ **moment.js** ⇒ `dd` = **ชื่อวันในสัปดาห์แบบย่อ** ไม่ใช่เลขวันที่ · เจอจริง 4 ฟิลด์ที่ตั้งไว้เป็น `yyyy-MM-dd HH:mm` (`hr_ot_from`, `hr_ot_to`, `hr_check_in`, `hr_check_out`) แสดงผลออกมาเป็น **`2026-08-Fr 07:52`** — **เลขวันที่หายไปทั้งคอลัมน์** และไม่มี error ใด ๆ

> **กฎ: ใช้ `DD/MM/YYYY` และ `DD/MM/YYYY HH:mm` เท่านั้น** (ตัวใหญ่ทั้ง D และ Y) · ห้ามใช้ `dd`/`yyyy` เด็ดขาด · ฝั่งบัญชีเคยบันทึกกฎนี้ไว้แล้ว (`tilsna-accounting/04-CLAUDE-memory.md` ข้อ 14) แต่ฟิลด์ที่สร้างทีหลังยังพลาดซ้ำ ⇒ **ต้องสแกนซ้ำทุกครั้งที่สร้างตารางใหม่**

### 9.3 วิธีแก้ที่ปลอดภัย + สิ่งที่ต้องส่งกลับไปด้วยเสมอ

`update_worksheet.editFields` **รีเซ็ตทุก attribute ที่ไม่ได้ส่งไป** ⇒ ส่งกลับให้ครบทุกครั้ง:

```jsonc
{"id": "<controlId>", "name": "<ชื่อฟิลด์เดิม>", "alias": "<alias เดิม>",
 "type": "Date",            // หรือ "DateTime"
 "required": <ค่าเดิม>,
 "subType": "3",            // 3 = ปี-เดือน-วัน · 1 = ปี-เดือน-วัน-ชม.-นาที
 "config": {"format": "DD/MM/YYYY"}}
```

ยิงจริง 47 ครั้งบน 19 worksheet ของ HR: `showtype` · `sorttype` · `attribute` (ธง title) · `enumDefault` และฟิลด์อื่นทั้งตาราง **ไม่ถูกแตะเลย** (เทียบ snapshot ก่อน–หลังแบบ field-by-field บน 16 worksheet ที่มี baseline)

`[V]` 🔴 **กับดักของตัวเอง: ชื่อฟิลด์ที่พิมพ์เป็น `\uXXXX` พลาดตัวเดียวก็เปลี่ยนชื่อฟิลด์เงียบ ๆ** — รอบนี้ `เวลาที่คำนวณ` กลายเป็น `เวลาที่คำนวด` เพราะพิมพ์ `\u0e14` (ด) แทน `\u0e13` (ณ) · **ไม่มี error** เพราะทั้งคู่เป็นชื่อที่ถูกต้องตามไวยากรณ์ · จับได้เพราะ verify เทียบ `controlName` ก่อน–หลัง · **กฎ: generate escape ด้วยเครื่อง (`''.join('\\u%04x'%ord(c) for c in s)`) อย่าพิมพ์เอง และ verify ต้องเทียบชื่อฟิลด์ทุกตัวเสมอ ไม่ใช่เทียบแค่ค่าที่ตั้งใจแก้**

### 9.4 สูตรสแกนหาฟิลด์ที่ยังไม่ถูกต้อง

```bash
hap --json worksheet fields <ws_id> --raw | python3 -c "
import json,sys
for c in json.load(sys.stdin):
    if c['type'] in (15,16):
        want='DD/MM/YYYY' if c['type']==15 else 'DD/MM/YYYY HH:mm'
        f=(c.get('advancedSetting') or {}).get('showformat')
        if f!=want: print(c['controlName'], c['controlId'], repr(f))
"
```

### 9.5 สิ่งที่ตรวจแล้ว **ไม่พบ** ภาษาจีนเลย (HR 37 worksheet)

ชื่อ worksheet · `entityName` (Record Name ที่ใช้บนปุ่ม "+ …") · ชื่อฟิลด์ · ค่าตัวเลือก (option value) · ชื่อ view ทุกอัน — สแกนด้วย regex ช่วง CJK ทั้ง `worksheet info` / `fields --raw` / `view list` ครบทั้ง 37 ตาราง: **0 จุด**

> ⚠️ `advancedSetting.sorttype = "zh"` มีอยู่บนฟิลด์แทบทุกตัวของแอปนี้ — เป็น **ลำดับการเรียงแบบจีน** ไม่ใช่รูปแบบแสดงผล และไม่มีผลกับฟิลด์วันที่/ตัวเลข · **ยังไม่ได้ทดสอบว่ามีผลกับการเรียงข้อความไทยหรือไม่** ⇒ ยังไม่แตะ

---

## 10. `NodeAppIsNull` ของ `sub_process` + วิธีอ่าน dynamic value ในเงื่อนไข — 6 ก.ย. 2569

### 10.1 `[V]` `NodeAppIsNull` บน sub_process = **inner flow ยังไม่ถูก publish** ไม่ใช่ config ผิด

`validate_process` ของ flow แม่ตอบ:

```
{"code":"NodeAppIsNull","message":"节点关联对象不存在或不可用",
 "nodeAlias":"loop_emp","nodeType":"sub_process"}
```

ทั้งที่ `validate_process` ของ **inner flow เอง** ตอบ `valid: true, issueCount: 0` · ข้อความ hint ที่ระบบให้มา ("โปรดตรวจในหน้าจอออกแบบ") **ชี้ผิดทาง**

**สาเหตุจริง:** flow แม่ตรวจว่า inner flow `enabled` หรือยัง · อ่านยืนยันได้จาก `hap workflow node get <main> <subprocess nodeId>` → ดู `processList[]` แล้วเทียบ `enabled` ของ inner ตัวที่ `subProcessId` ชี้ไป (ของ WF-HR-18 ที่ใช้งานได้อยู่แล้ว = `true` · ของตัวที่เพิ่งสร้าง = `false`)

**ลำดับที่ถูกต้อง:** `publish_process(inner)` → **แล้วค่อย** `validate_process(main)` → `publish_process(main)` · หลัง publish inner แล้ว main เปลี่ยนจาก 1 error เป็น `valid: true` ทันทีโดยไม่ต้องแก้อะไรเลย

> ⚠️ ต่างจาก `sub_process` แบบ **`mode: use_existing`** ซึ่งฝั่งบัญชีบันทึกไว้ว่า **ห้าม publish inner** (`tilsna-accounting/04-CLAUDE-memory.md` กับดักข้อ 24) — กฎ "publish inner ก่อน" ใช้กับ **`mode: create`** เท่านั้น

### 10.2 `[V]` 🔴 dynamic value ในเงื่อนไขอยู่คนละที่กับ literal — อ่านผิดแล้วจะสรุปว่า "เงื่อนไขไม่มีค่า"

ใน `conditionValues[]`:

| ชนิดค่า | เก็บไว้ที่ | `value` |
|---|---|---|
| ค่าคงที่ (literal) | `value.value` (option ใช้ `{key, value}`) | มีค่า |
| **ค่าอ้างอิงจาก node อื่น (dynamic)** | **`nodeId` + `controlId` + `controlName`** | **`null`** |

⇒ สคริปต์ที่ dump แค่ `value` จะเห็น `[None]` แล้วสรุปผิดว่า "เงื่อนไขนี้ไม่มีค่าเปรียบเทียบ"

**เกิดขึ้นจริงกับเอกสารชุดนี้:** การออดิต WF-HR-05 เมื่อ 31 ส.ค. บันทึกว่า *"filter ฟิลด์วันที่ `วันที่ทำงาน` โดย `conditionValues` **ว่าง** (`[None]`)"* — ตรวจซ้ำ 6 ก.ย. พบว่า **ไม่ว่าง**: เป็น `วันที่ทำงาน ≤ Result ของ node คำนวณวันที่เมื่อวาน` (`nodeId=6a91018d… controlId=date_fx_id`) ⇒ เงื่อนไขถูกต้องอยู่แล้ว

**สูตร dump ที่ถูกต้อง:**

```python
for v in cond.get('conditionValues') or []:
    if v.get('nodeId'):
        print('DYN', v['nodeId'], v.get('controlId'), v.get('controlName'))
    else:
        val = v.get('value')
        print('LIT', val.get('value') if isinstance(val, dict) else val)
```

### 10.3 แพทเทิร์น gate ที่กัน D-19 ได้โดยไม่ต้องพึ่ง `≠` กับธงที่อาจว่าง

แทนที่จะ gate ด้วย `ธง ≠ 1` (ซึ่งเป็นเท็จเมื่อธงว่าง = D-19) ให้ gate ด้วย **การนับของจริง**:

`get_multiple` ของที่จะสร้าง (filter ผูกกับ record ต้นทาง) → `rollup count` → `branch` เงื่อนไข `count < 1`

- ผลนับเป็นตัวเลขเสมอ **ไม่มีสถานะว่าง** ⇒ ไม่ติด D-19
- เป็น invariant จริง ("ยังไม่มีของในงวดนี้") ไม่ใช่ธงที่อาจไม่ตรงกับความจริง
- ยังตั้งธงไว้ได้เพื่อให้คนอ่านออก แต่ธงไม่ใช่ตัวตัดสิน

พิสูจน์แล้วกับ WF-HR-07: ยิงซ้ำรอบที่ 2 ไม่เกิดสลิปเพิ่ม (1 → 1)

---

## 11. ไอคอนของ worksheet — เปลี่ยนผ่าน CLI ได้ · 6 ก.ย. 2569

### 11.1 `[V]` คำสั่งที่ใช้ได้จริง

```bash
hap worksheet update <worksheet_id> --icon <ชื่อไอคอน> -a <app_id>
```

ยิงจริง **37 ครั้งบน worksheet ของ HR ทั้งหมด สำเร็จ 37/37** อ่านกลับด้วย `hap app info` ตรงทุกตัว · ส่ง `--icon` เดี่ยว ๆ ได้ **ไม่ต้องส่ง `--name` มาด้วย** และตรวจแล้วว่า **ชื่อตาราง · `entityName` · `alias` · จำนวนฟิลด์ · จำนวน record ไม่ถูกแตะเลย**

> `--icon-color` มีเฉพาะตอน `worksheet create` — **`update` เปลี่ยนสีไอคอนไม่ได้**

### 11.2 `[V]` 🔴 รับชื่อไอคอนที่ไม่มีจริงไปเงียบ ๆ

`hap worksheet update --icon zz_not_a_real_icon_xyz` ตอบ **`true`** และเก็บ URL นั้นลง `iconUrl` จริง ⇒ ไอคอนบนไซด์บาร์กลายเป็นช่องว่าง **ไม่มี error ที่ไหนเลย** (ตระกูลเดียวกับ §8.1 — ระบบรับ id ที่ไม่มีจริงไปเงียบ ๆ)

**ตรวจก่อนใช้เสมอ** — ไฟล์ต้องมีอยู่จริง:

```bash
curl -s -o /dev/null -w '%{http_code}\n' \
  "https://www.nocoly.com/file/mdpub/customIcon/<ชื่อ>.svg"   # 200 = ใช้ได้ · 400 = ไม่มี
```

🔴 **ตัวอย่างใน `hap worksheet update --help` เองก็ผิด** — ยกตัวอย่าง `shopping_cart` ซึ่งเช็คแล้วได้ **400** (ชื่อจริงคือ `sys_13_3_shopping_cart_loaded`)

### 11.3 `[V]` ชื่อไอคอนเดาไม่ได้ — และวิธีดึงรายชื่อทั้งชุด (997 ชื่อ)

คำอังกฤษธรรมดา (`calendar` `user` `money` `file` `chart` `clock`) **400 ทั้งหมด** · ชื่อจริงมี 3 ทรง:

| ทรง | ตัวอย่าง |
|---|---|
| `sys_<กลุ่ม>_<ลำดับ>_<คำ>` | `sys_4_1_calendar` · `sys_1_10_people` |
| `sys_<คำ>_<หมวด>` | `sys_wallet_finance` · `sys_interview_people` · `sys_gear1_office` |
| ชื่อลอย | `table` · `8_4_folder` |

> ตัวแปรของไอคอนเดียวกันใช้ได้หลายชื่อ: `4_1_calendar` · `sys_4_1_calendar` · `sys_4_1_calendar_line` ล้วน 200

✅ **มีคำสั่ง CLI อยู่แล้ว — `hap icon`** (ค้นพบทีหลัง · ตอนแรกเอกสารนี้เขียนผิดว่า "ไม่มี")

```bash
hap icon search <คำ>        # ค้นด้วยคำอังกฤษหรือจีน เช่น calendar / people / folder
hap icon list -n 50 -p 2    # ไล่ดูทั้งแคตตาล็อกทีละหน้า
```

ผลลัพธ์เป็นตาราง `Icon | Keywords` โดย keyword เป็นภาษาจีน (`sys_4_1_calendar` → `日历 日程 时间`) ⇒ **ค้นด้วยคำอังกฤษได้ผลบางส่วน ค้นด้วยคำจีนแม่นกว่า**

> ⚠️ **แคตตาล็อกใน CLI มี 426 ชื่อ = subset ของ 997 ชื่อที่ icon picker บนหน้าจอมี** (agent-ac นับไว้ใน `MIGRATION.md` D-52) ⇒ ถ้าหาไม่เจอใน CLI **ยังมีสิทธิ์มีอยู่จริง** ให้ไปดึงจาก DOM ตามด้านล่าง

หากอยากได้ชุดเต็มพร้อมกันทีเดียว (997 ชื่อ) ยังดึงจาก DOM ของ icon picker ได้: เปิด **Edit Name and Icon** → แท็บ **Default** → รันใน console ของหน้านั้น

```js
[...document.querySelectorAll('.contentCon li > span')].map(s => s.className.trim())
// className ของ span = ชื่อไฟล์ .svg ตรงตัว
```

endpoint ที่ picker ใช้คือ `POST /wwwapi/AppManagement/GetIcon` body `{"projectId":"<org id>","iconType":true,"keyword":"","isLine":false}` — ยิง body ว่างจะได้ `Service exception` · `/file/mdpub/customIcon/icon.json` = 404

**วิธีที่ใช้ได้จริง — ดึงจาก DOM ของ icon picker** (เปิดจากไซด์บาร์ → เมนู `...` ของ worksheet → **Edit Name and Icon** → แท็บ **Default**) แล้วรันใน console ของหน้านั้น:

```js
[...document.querySelectorAll('.contentCon li > span')].map(s => s.className.trim())
// → 997 ชื่อ · className ของ span = ชื่อไฟล์ .svg ตรงตัว
```

หมวดใน picker: Basic · Office · Finance · Object · Character · Symbol · Natural · Clothing · Diet · Activity · Transportation · Location

**ชุดที่ใช้ได้ดีกับงานธุรกิจ (ตรวจแล้ว 200 ทุกตัว):**

| งาน | ชื่อไอคอน |
|---|---|
| ปฏิทิน / เวลา / นาฬิกาปลุก | `sys_4_1_calendar` · `sys_4_2_clock` · `sys_4_3_alarm_clock` |
| คน / กลุ่มคน / ค้นหาคน / สัมภาษณ์ | `sys_1_10_people` · `sys_6_1_user_group` · `sys_search_people` · `sys_interview_people` |
| เงิน / กระเป๋าเงิน / บิล / เช็ค / เปอร์เซ็นต์ | `sys_3_1_coins` · `sys_wallet_finance` · `sys_bill_finance` · `sys_cheque_office` · `sys_percentage_finance` |
| เอกสาร / ใบรับรอง / ลายเซ็น / รายการ | `sys_1_6_document` · `sys_certificate_object` · `sys_signature_symbol` · `sys_bullet-list_office` |
| กราฟ / สถิติ / โครงสร้าง / ไทม์ไลน์ | `sys_2_1_bar_chart` · `sys_2_3_statistics` · `sys_hierarchy_symbol` · `sys_timeline_symbol` |
| อนุมัติ / ตั้งค่า / ความปลอดภัย / กระเป๋าเอกสาร | `sys_1_7_approval` · `sys_gear1_office` · `sys_10_3_security_checked` · `sys_8_3_briefcase` |
| สวัสดิการ / ของขวัญ / ดาว / หนังสือ | `sys_14_1_gift` · `sys_10_5_star` · `sys_12_2_book` |

### 11.4 สคริปต์ที่ใช้จริง (ตรวจก่อน แล้วค่อยยิง)

```bash
# ไฟล์ icons.tsv: <worksheet_id>\t<ชื่อตาราง>\t<ชื่อไอคอน>
while IFS=$'\t' read -r id name ic; do
  code=$(curl -s -o /dev/null -w '%{http_code}' \
    "https://www.nocoly.com/file/mdpub/customIcon/$ic.svg")
  [ "$code" = 200 ] || echo "❌ $ic ($name)"
done < icons.tsv        # ต้องไม่มี ❌ ก่อนจึงยิงจริง

while IFS=$'\t' read -r id name ic; do
  hap worksheet update "$id" --icon "$ic" -a "$APP"
done < icons.tsv

# verify: อ่าน iconUrl กลับมาเทียบกับ icons.tsv ทีละตัว (อย่าเชื่อ "true")
hap --json app info -a "$APP"
```

### 11.5 ไอคอนของ **กลุ่ม** กับของ **section จริง** — คนละเรื่องกัน

🔴🔴 **แก้ข้อผิดพลาดของหัวข้อนี้เอง (6 ก.ย. 2569 รอบค่ำ)** — เดิมเขียนว่า "CLI เปลี่ยนไอคอนกลุ่มไม่ได้" **ผิด** · agent-ac ชี้จุดที่เข้าใจผิดใน `MIGRATION.md` D-52 และ **ทดสอบซ้ำเองแล้วว่าจริง**

**ต้นเหตุที่เข้าใจผิด: "กลุ่ม" กับ "section" ไม่ใช่ของชนิดเดียวกัน**

| สิ่งที่เห็นบนไซด์บาร์ | จริง ๆ คืออะไร | เปลี่ยนไอคอนยังไง |
|---|---|---|
| `HR-00 Configuration` · `AC-01 ข้อมูลหลัก` ("กลุ่ม") | **item ชนิด 2 ที่อยู่ใน section** — id ทรงเดียวกับ worksheet | ✅ **`hap worksheet update <groupId> --icon <ชื่อ> -a <appId>`** — ใช้คำสั่งเดียวกับ worksheet เลย |
| `บัญชี (AC)` · `ทรัพยากรบุคคลฯ (HR)` (**section จริง** มีแค่ 2 อันในแอปนี้) | section ของแอป | ต้องยิง `HomeApp/UpdateAppSection` (ดูด้านล่าง) |

`[V]` **`hap app edit-section` เปลี่ยนได้แค่ชื่อ** (`-n/--name` เท่านั้น ไม่มี `--icon`) และรับเฉพาะ **section จริง** — ส่ง id ของ "กลุ่ม" เข้าไปจะได้ `Error: The app does not exist` · **ข้อความนี้ชี้ผิดทาง**: ไม่ใช่ว่าแอปไม่มี แต่เป็นเพราะ id ที่ส่งไปไม่ใช่ section · **เจอ error นี้เมื่อไร ให้สงสัยว่าส่ง id ผิดชนิดก่อนเสมอ**

`[V]` **ตั้งไอคอนได้ตอนสร้างเท่านั้น** ผ่าน `--sections-json`:

```bash
hap app add-section <appId> --parent-id <parentSectionId> \
  --sections-json '[{"name":"HR-07 Dashboard","icon":"sys_folder-chart-bar_office"}]'
```

`[V]` **สำหรับ section จริง 2 อัน (และเป็นทางที่ใช้ได้กับกลุ่มด้วย แม้จะยากกว่าจำเป็น)** — ยิง endpoint ภายในของหน้าเว็บ รันใน console ของแท็บที่ล็อกอินอยู่ (ใช้คุกกี้ session ไม่ต้องมี API key):

```js
await fetch('/wwwapi/HomeApp/UpdateAppSection', {
  method: 'POST', headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    appId: '<appId>',
    appSectionId: '<sectionId>',
    appSectionName: '<ชื่อเดิม — ต้องส่งกลับไปด้วย ไม่งั้นชื่อเพี้ยน>',
    icon: 'sys_folder-user_office'
  })
})
// สำเร็จ = {"data":{"code":1,"data":true},"state":1}
```

🔴 **กับดักของ endpoint นี้ — ต้องอ่านผลลัพธ์ ไม่ใช่แค่ HTTP 200:**

| body ที่ส่ง | ผลลัพธ์ | เกิดอะไรจริง |
|---|---|---|
| `appSectionId` + `appSectionName` + **`icon`** | `data: true` | ✅ เปลี่ยนจริง |
| `appSectionId` + `appSectionName` + **`iconUrl`** | `data: true` | ✅ เปลี่ยนจริง (ใช้ URL เต็มก็ได้) |
| ส่ง **`icon` และ `iconUrl` พร้อมกัน** | **`data: false`** | 🔴 **ไม่ทำอะไรเลย** — ต้องเลือกส่งอย่างใดอย่างหนึ่ง |
| ใช้ชื่อคีย์ `name` แทน `appSectionName` | `Service exception` | ❌ |
| ใช้ชื่อคีย์ `sectionId` แทน `appSectionId` | `Service exception` | ❌ |

⇒ `state: 1` **ไม่พอ** ต้องเช็ค `data.data === true` และอ่าน `iconUrl` กลับจาก `hap app info` เสมอ

**ยิงจริงแล้ว 8/8 กลุ่มของ HR ด้วยวิธีนี้** (6 ก.ย. 2569) · ตรวจหลังยิง: ชื่อกลุ่มครบถูกต้องทั้ง 8 และ **จำนวน worksheet ในแต่ละกลุ่มไม่เปลี่ยน** (10 · 7 · 2 · 3 · 7 · 6 · 2 · 0)

> ⚠️ **แต่ถ้าเป็น "กลุ่ม" ให้ใช้ `hap worksheet update --icon` แทน** — สั้นกว่า ไม่ต้องเปิดเบราว์เซอร์ และไม่ต้องส่งชื่อเดิมกลับไป · เก็บ `UpdateAppSection` ไว้ใช้กับ section จริงเท่านั้น
> 🧪 **ทดสอบยืนยันเอง 6 ก.ย.**: `hap worksheet update 6a9cece1db26b712423ce585 --icon sys_folder-info_office -a <app>` → อ่านกลับได้ `sys_folder-info_office` แล้วคืนค่าเดิมสำเร็จ (id นั้นคือกลุ่ม `HR-07 Dashboard`)

> 💡 **แพทเทิร์นที่อ่านง่าย:** ให้ **กลุ่มใช้ไอคอนตระกูล `sys_folder-*_office`** (โฟลเดอร์) และให้ **worksheet ใช้ไอคอนรูปธรรม** ⇒ สายตาแยก "กล่อง" กับ "ของในกล่อง" ได้ทันที

---

## 12. ปุ่ม Custom Action — ยืนยันจริง 6 ก.ย. 2569 (ปิด M-07 ครบทั้งชุด)

`[V]` **`hap worksheet create-custom-action` สร้างปุ่มได้จริง และปุ่มโผล่บนหน้าจอจริง** — ยิงจริง 4 ปุ่ม บน 4 worksheet ของ HR · **ปิดคำถาม M-07 ตัวสุดท้าย** (`create_custom_actions` เป็นชิ้นเดียวที่ยังค้างหลังปิด view/chart ไปแล้วใน §8)

### 12.1 แพทเทิร์นปุ่มที่ทำงานได้จริง — ปุ่มคือ "ตัวจุด workflow"

ปุ่มทุกปุ่ม **สร้าง workflow ผูกติดมาให้อัตโนมัติ 1 ตัว** และคำสั่งคืน `processId` + `triggerNodeId` มาให้ต่อทันที:

```bash
hap worksheet create-custom-action <ws_id> -a <app_id> --action-spec '{
  "name":"สร้างสลิปทั้งงวด", "desc":"...", "type":"triggerWorkflow", "isAllView":1
}'
# → {"actionId":"...", "processId":"...", "triggerNodeId":"..."}
```

จากนั้นใส่ node เข้า workflow ของปุ่มด้วย `batch_create_process_nodes` (trigger alias = **`trigger`** · `target` = `{kind:'record', node:{nodeAlias:'trigger'}}`) แล้ว `publish_process`

`[V]` 🟢 **ปุ่มยิง workflow ต่อกันเป็นทอด ๆ ได้** — พิสูจน์แล้ว: กดปุ่มเดียว → workflow ของปุ่มเปลี่ยน `biz_period_status` เป็น Calculating → **WF-HR-07 (worksheet_event) รับช่วงต่อทันที** สร้างสลิปให้พนักงานที่เข้าเงื่อนไข · `_createdBy` ของสลิป = **`user-workflow`** · นี่คือวิธีทำให้ workflow ที่ trigger ด้วย record-event **กดสาธิตได้ด้วยปุ่มเดียว**

### 12.2 🔴 `--action-spec` ทิ้ง `enableWhen` และ `confirm` เงียบ ๆ

ส่ง `enableWhen` + `confirm` + `confirmMsg` ไปครบ · คำสั่งตอบสำเร็จพร้อม `actionId` · แต่ **อ่านกลับแล้วได้ `showType: 0` และ `filters: []`** = ปุ่มโผล่ตลอดเวลา ไม่มีเงื่อนไข ไม่มีกล่องยืนยัน

**ทางแก้: ยิงซ้ำด้วย `--config` (wire form) พร้อม `--btn-id` ของปุ่มเดิม**

```bash
hap worksheet create-custom-action <ws_id> -a <app_id> --btn-id <actionId> --config '{
  "name":"...", "desc":"...",
  "clickType":2, "workflowType":1, "isAllView":1, "showType":2,
  "enableConfirm":true, "confirmMsg":"...", "sureName":"...", "cancelName":"ยกเลิก",
  "filters":[ <wire filter array> ],
  "advancedSetting":{"detailviews":"[]","listviews":"[]"}
}'
```

🔴 **ต้องมี `--btn-id` เสมอ** — ไม่ใส่ = ได้ปุ่มใหม่ + workflow ใหม่อีกชุด ของเดิมกลายเป็นขยะ

`[V]` **`clickType` ที่ส่งไปถูกเซิร์ฟเวอร์เขียนทับ** — ส่ง `2` (ยืนยันสองชั้น) แต่อ่านกลับได้ `1` เสมอสำหรับปุ่มชนิด `triggerWorkflow` · **กล่องยืนยันมาจาก `enableConfirm: true` ไม่ใช่จาก `clickType`** — ยืนยันด้วยตาว่ากล่อง confirm พร้อมข้อความไทยที่ตั้งไว้ขึ้นจริง

### 12.3 คีย์ 3 ตัวที่ตัดสินว่าปุ่ม "โผล่หรือไม่โผล่"

| คีย์ | ต้องเป็น | ถ้าผิด |
|---|---|---|
| `isAllView` | **1** | ปุ่มผูกกับ view ที่ไม่ได้กำหนด = ไม่โผล่ (ตรงกับที่บัญชีบันทึกไว้ในกับดักข้อ 20) |
| `showType` | **2** = โผล่เมื่อเข้าเงื่อนไข · `1` = โผล่ตลอด · **`0` = ค่าที่ `--action-spec` ทิ้งไว้** | `0` + `filters` ว่าง ⇒ ไม่มีการกรองเลย |
| `filters` | wire filter array (โครงเดียวกับ view — group ครอบ condition) | ว่าง = ปุ่มโผล่ทุกสถานะ รวมสถานะที่ไม่ควรกดได้ |

> เงื่อนไข "โผล่เมื่อสถานะเป็นค่าใดค่าหนึ่งในหลายค่า" ใช้ **condition เดียว `filterType: 2` แล้วใส่ key หลายตัวใน `values`** — กฎเดียวกับ §8.2 ห้ามแตกเป็นหลาย condition (จะถูก AND แล้วปุ่มไม่โผล่เลย)

### 12.4 เช็กลิสต์หลังสร้างปุ่ม

1. `hap worksheet custom-actions <ws_id>` → ตรวจ `showType` · `isAllView` · `enableConfirm` · `filters` ว่าตรงที่ตั้งใจ
2. `hap workflow structure <processId>` → ตรวจว่า node เขียนฟิลด์ถูกตัว
3. `hap workflow get <processId>` → ต้องได้ `enabled=True` `publishStatus=2`
4. **เปิดหน้าจอกดจริง 1 ครั้ง** แล้วอ่าน `_updatedBy` ของ record — ต้องเป็น `user-workflow`

---

## 13. 🔴🔴 Role — `worksheetPermissions` **ตั้งผ่าน API ไม่ติดเลย** (6 ก.ย. 2569)

### 13.1 สิ่งที่พบ

**สร้าง role ผ่าน API ได้จริง แต่ permission matrix ที่ส่งไปถูกทิ้งทั้งก้อน** — role ที่ได้จะมีสิทธิ์ **`read 20 / edit 20 / delete 20` เท่ากันหมดทุก worksheet ในแอป** ไม่ว่าจะส่งอะไรไป

ลองครบ **3 ทาง ผลเหมือนกันทั้ง 3**:

| ทาง | ผลตอบกลับ | ผลจริง |
|---|---|---|
| `hap app role create --worksheet-permissions-json '<37 worksheet>'` | สำเร็จ คืน role object | ❌ ได้ `(20,20,20)` × **87 worksheet ทั้งแอป** |
| `hap app role set-permissions <app> <role> --permission-way 0 -P '<...>'` | `Permissions updated.` | ❌ ไม่เปลี่ยนอะไรเลย |
| MCP `create_role` + `worksheetPermissions[]` | `success: true` | ❌ เหมือนกัน |

อ่านกลับยืนยัน **2 ทางอิสระ** — `hap app role permissions` และ MCP `get_role_details` — ตรงกันว่าเป็น `(20,20,20)` ทั้ง 87 รายการ · `permissionScope` / `permissionWay` ที่อ่านกลับได้เป็น `null`

### 13.2 🔴 ทำไมเรื่องนี้อันตราย

`(20,20,20)` = **"ของตัวเอง: ดู/แก้/ลบได้"** บน **ทุก worksheet ของทั้งแอป** ⇒

- role ที่ตั้งใจให้ **อ่านอย่างเดียว** (ผู้ตรวจสอบภายใน · ผู้บริหาร) **ลบระเบียนของตัวเองได้**
- role ที่ตั้งใจให้เห็นเฉพาะโมดูลตัวเอง **เห็นและแก้ข้ามโมดูลได้** (HR เห็นตารางบัญชี และกลับกัน)
- ข้อกำหนดแยกอำนาจ (SoD) และ "ห้ามลบเอกสารที่อนุมัติแล้ว" **ไม่มีผลบังคับจริงเลย**

**และมันเงียบสนิท** — ไม่มี error ไม่มี warning · ถ้าไม่อ่านกลับมาเทียบทีละ worksheet จะไม่มีทางรู้

> ✅ **ตรวจแล้วบนแอปนี้ (6 ก.ย. 2569): role ของโมดูลบัญชีทั้ง 8 ตัวก็เป็นแบบเดียวกัน** — `AC-R5 Internal Auditor` ที่ควรอ่านอย่างเดียว อ่านกลับได้ `(20,20,20)` × 87 · **และมีสมาชิกผูกอยู่จริงแล้ว** ⇒ แจ้งฝั่งบัญชีแล้ว

### 13.3 กฎที่ต้องใช้ตั้งแต่นี้ไป

1. **ห้ามถือว่า role ที่สร้างผ่าน API มีสิทธิ์ตามที่ส่งไป** — ต้องอ่านกลับด้วย `hap app role permissions <roleId> -a <appId>` แล้ว**เทียบทีละ worksheet** ก่อนพูดว่าเสร็จ
2. **ถ้าตั้ง matrix ไม่ติด อย่าปล่อย role ทิ้งไว้** — role ที่ชื่อบอกว่า "พนักงาน" แต่สิทธิ์จริงคือแก้/ลบได้ทั้งแอป **อันตรายกว่าไม่มี role เลย** เพราะคนจะผูกสมาชิกเข้าไปด้วยความเข้าใจผิด · รอบนี้เลือก **ลบทิ้งทั้ง 8 ตัวที่เพิ่งสร้าง** แล้วบันทึกว่าเป็นงานที่ต้องทำผ่านหน้าจอ
3. **การตั้ง permission matrix = งาน Browser** จนกว่าจะพิสูจน์ได้ว่ามี API ทางอื่น — เข้า Setting drawer ของแต่ละ worksheet ในหน้า role แล้วกด radio scope เอง (ตรงกับที่บัญชีเคยบันทึกไว้ว่า checkbox "View/Edit All" ≠ `recordDataScope 100`)

### 13.4 สคริปต์ตรวจ role ทั้งแอป

```bash
hap --json app role list -a "$APP" | python3 -c "
import json,sys,subprocess,collections
d=json.load(sys.stdin)
rs=d.get('roles') or d.get('data') or d
for r in rs:
    p=json.loads(subprocess.run(['hap','--json','app','role','permissions',r['id'],'-a','$APP'],
                 capture_output=True,text=True).stdout)
    sh=(p.get('data') or p).get('sheets') or []
    c=collections.Counter((s['recordDataScope']['read'],s['recordDataScope']['edit'],s['recordDataScope']['delete']) for s in sh)
    print(f\"{r['name'][:38]:40s} {len(sh):3d} sheets  {dict(c)}\")
"
# ทุก role ที่ออกมาเป็น {(20,20,20): <จำนวน worksheet ทั้งแอป>} คือ role ที่ยังไม่ได้ตั้งสิทธิ์จริง
```

---

---

## 14. Rollup (type 37) — สร้างผ่าน CLI ได้ · `enumDefault` คือฟังก์ชันรวม · 6 ก.ย. 2569

**สรุปหัวเรื่อง:** BuildSpec เดิมเขียนว่า Rollup ต้องสร้างใน Browser เท่านั้น — **ไม่จริง** `hap worksheet add-fields` สร้างได้และคำนวณจริง ยืนยันด้วยเคสหลายบรรทัด (1,200 + 300 = 1,500) [V]

### 14.1 payload ที่ใช้ได้จริง

```bash
hap worksheet add-fields <parent_ws> --controls '[{
  "type": 37,
  "controlName": "จำนวนเงินที่ขอเบิก",
  "dataSource": "$<relation_controlId_บน_parent>$",
  "sourceControlId": "<controlId ของฟิลด์ตัวเลขบน child>",
  "enumDefault": 5,
  "dot": 2,
  "advancedSetting": {"summaryresult": "1"}
}]'
```

- `dataSource` ต้องครอบด้วย `$…$` และเป็น **relation control บนตารางแม่** (ไม่ใช่ worksheetId ของตารางลูก)
- `sourceControlId` = ฟิลด์บนตารางลูกที่จะเอามารวม
- ❗ `add-fields` **ไม่รับ `-a/--app`** (ต่างจากคำสั่ง worksheet อื่น) — ใส่แล้ว error `No such option: -a`

### 14.2 🔴 `enumDefault` = ฟังก์ชันรวม — ยิงจริงครบทุกค่า

ทดสอบด้วยใบเบิกที่มี 2 บรรทัด (1,200 และ 300) แล้วอ่านค่าที่คำนวณกลับมา:

| `enumDefault` | ผลที่ได้ | ความหมาย |
|---|---|---|
| 0 | `2.0000` | COUNT (นับจำนวนบรรทัด) |
| 1 | `750.0000` | **AVG** (ค่าเฉลี่ย) |
| 2 | `1200.0000` | MAX |
| 3 | `300.0000` | MIN |
| 4 | `` (ว่าง) | ❌ ไม่คำนวณ — ค่าที่ใช้ไม่ได้ |
| **5** | **`1500.0000`** | ✅ **SUM (ผลรวม) — ค่าที่ต้องใช้** |
| 6 | `2.0000` | COUNT (นับค่าที่ไม่ว่าง) |

🔴 **กับดักตัวจริง:** สัญชาตญาณจะเดาว่า `enumDefault: 1` = SUM (เพราะ 1 = ตัวแรก) — **ผิด** มันคือ AVG และแพลตฟอร์มก็ยอมรับเงียบ ๆ ไม่มี error ให้เห็น
🔴 **การทดสอบด้วยใบที่มีบรรทัดเดียวจับ bug นี้ไม่ได้** — 2,400 บรรทัดเดียว SUM ก็ 2,400 AVG ก็ 2,400 ต้องทดสอบด้วยเคส ≥2 บรรทัดที่ค่าไม่เท่ากันเสมอ

`advancedSetting.summaryresult` **ไม่ใช่** ฟังก์ชันรวม — ลองค่า 0/1/2/3/4/5 แล้วผลลัพธ์เท่ากันหมด (มีผลกับการแสดงทศนิยมเท่านั้น: `"1"` คืน 4 ตำแหน่ง ค่าอื่นคืนตาม `dot`)

### 14.3 🔴 Rollup คำนวณแบบ lazy — ต้อง "แตะ" record ลูกถึงจะอัปเดต

ลำดับเหตุการณ์ที่ยืนยันแล้ว:

1. สร้าง record ลูกใหม่พร้อม relation → **rollup บนแม่ยังว่าง** (`''`)
2. แก้ field ธรรมดาบน record ลูก (เช่น จำนวนเงิน) → **ยังว่าง**
3. เขียนค่า **relation field** บน record ลูกซ้ำ (`update` field `<child_relation_id>` = `[parent_rowid]`) → **คำนวณทันที** ✅
4. แก้ record แม่เอง → **ไม่ทำให้ rollup คำนวณใหม่**

⇒ หลังเปลี่ยน `enumDefault` ของ rollup ที่มีข้อมูลอยู่แล้ว **ต้องวนเขียน relation field ของทุก record ลูกซ้ำ** ไม่งั้นจะยังเห็นค่าที่คำนวณด้วยฟังก์ชันเดิม (คิดว่าแก้ไม่ติด)

### 14.4 🔴 relation ที่สร้างตอน `create_worksheet` ไม่ใช่ตัวเดียวกับที่ rollup ใช้ได้

`hr_claim_line` มี relation `ใบเบิก` (`…a353`) ที่สร้างพร้อม worksheet — ตั้ง `bidirectional: "1"` แล้วแต่ **คู่ตรงข้ามบนตารางแม่ไม่ถูกสร้างจริง** (`sourceControlId` ชี้ไป controlId ที่ไม่มีอยู่) จึงเอามาเป็น `dataSource` ของ rollup ไม่ได้

ต้องสร้างคู่ relation ใหม่ด้วย MCP `addFields` + `sourceField` บนตารางแม่ → ได้คู่ `…a373` (แม่) ⇄ `…a374` (ลูก) แล้วจึงชี้ rollup ไปที่ `$…a373$`

ผลข้างเคียง: record ลูกจะมี relation **สองตัว** ที่ชี้แม่คนเดียวกัน และ **ตัวเก่าไม่ป้อน rollup** → อาการคือ "ผูกบรรทัดครบแล้วแต่ rollup ยังเป็น 0/ว่าง" วิธีแก้คือลบ relation ตัวเก่าทิ้งด้วย `update-fields` (อ่าน controls สดมาทั้งชุด → ตัดตัวที่ไม่ใช้ → เขียนกลับ) แล้วผูกใหม่ผ่านตัวที่ถูกต้อง

### 14.5 `hap app-editor` ใช้กับแอปนี้ไม่ได้ (สำหรับ field ops)

`app-editor plan/apply` คืน `worksheet '<id>' not found in app <app_id>` ทุก op เพราะ `app-editor inspect` คืน `"worksheets": []` — แอปนี้เก็บ worksheet ไว้ใต้ group (item type 2) ซึ่ง inspect ไม่ไล่ลงไป ⇒ **field.update / field.delete ต้องทำเองด้วย `worksheet update-fields`** (อ่าน `worksheet fields --raw` → แก้ → เขียนกลับทั้งชุด)

ยืนยันแล้วว่า `update-fields` แบบอ่าน-แก้-เขียนกลับ **ไม่ทำ relation/ข้อมูลหาย**: หลังเขียนกลับ rollup ยังคำนวณค่าเดิมถูกต้องทั้ง 3 record

---

---

## 15. Business Rules — สร้างผ่าน CLI ได้ · และวิธีข้ามข้อจำกัด "อ้าง relation field ไม่ได้" · 6 ก.ย. 2569

**สรุปหัวเรื่อง:** §1 เดิมบอกว่า Business Rule ต้องทำใน Browser — **ไม่จริงอีกต่อไป** `hap worksheet save-rule` สร้างได้ครบ และ **ตั้ง Dynamic Value ได้โดยไม่ต้องเจอ UI quirk Down+Enter ของ §4** [V]

### 15.1 คำสั่งและ payload

```bash
hap worksheet save-rule <ws_id> \
  --name "BR-19.2 จำนวนเงินเกินวงเงินสูงสุดต่อครั้ง" \
  --type 1 --check-type 1 --hint-type 0 \
  --filters '<FilterCondition[]>' --rule-items '<RuleItem[]>'
```

- `--type` · `0` = interaction · `1` = validation · `2` = lock
- `--rule-id` ใส่เมื่อจะแก้ของเดิม · ไม่ใส่ = สร้างใหม่ · คืน `ruleId` กลับมาเป็น string
- ❗ `worksheet rules` / `worksheet save-rule` **ไม่รับ `-a/--app`** เหมือน `add-fields`
- `--filters` ใช้โครงเดียวกับ view filter: อาร์เรย์ 1 ตัวที่ `isGroup: true` แล้วเงื่อนไขจริงอยู่ใน `groupFilters` (`spliceType 1` = AND ระหว่างกัน)

### 15.2 `ruleItems[].type` — เท่าที่ยืนยันแล้ว

| `type` | ความหมาย | ต้องมี |
|---|---|---|
| 1 | แสดงฟิลด์ | `controls[]` |
| 2 | ซ่อนฟิลด์ | `controls[]` |
| 6 | ข้อความ error (ใช้กับ rule ชนิด validation) | `controls[]` + `message` |
| 7 | ทุกฟิลด์อ่านอย่างเดียว | `controls: []` |

ค่าอื่น (เช่น "บังคับกรอก") **ยังไม่ยืนยัน — อย่าเดา** ถ้าต้องการผลแบบ "บังคับแนบไฟล์" ให้เขียนเป็น **validation** แทน (เงื่อนไข "ต้องแนบ = จริง **และ** ไฟล์ว่าง" → `type 6` ข้อความบล็อก) ซึ่งได้ผลเทียบเท่าและใช้เฉพาะ type ที่รู้แน่

### 15.3 🟢 ทางแก้ข้อจำกัด §4 "Business Rule อ้าง Relation field ของฟอร์มปัจจุบันไม่ได้"

ข้อจำกัดใน §4 เป็นข้อจำกัดของ **field picker ในหน้าจอ** ไม่ใช่ของ engine — ทางออกที่พิสูจน์แล้ว:

1. สร้าง **Lookup (type 30)** บนตารางลูก ดึงค่าที่ต้องเทียบข้ามมาเป็น "ฟิลด์ท้องถิ่น" ก่อน
2. เขียน rule เทียบสองฟิลด์ท้องถิ่นตามปกติ

```bash
hap worksheet add-fields <ws> --controls '[{
  "type": 30, "controlName": "(ระบบ) วงเงินสูงสุดต่อครั้ง",
  "dataSource": "$<relation_controlId บนตารางนี้>$",
  "sourceControlId": "<controlId ของฟิลด์บนตารางปลายทาง>",
  "sourceControlType": 6, "enumDefault": 0, "dot": 2,
  "advancedSetting": {"sorttype": "en", "datamask": "0"}
}]'
```

ยืนยันด้วยของจริง: `hr_claim` ดึง `max_per_claim` (Number) และ `require_receipt` (Checkbox) จาก `hr_welfare_scheme` มาได้ค่า `1500.00` / `1` ⇒ กฎ BR-19.2 และ BR-19.3 ทำงานได้ทั้งที่ต้นทางอยู่คนละตาราง

⚠️ **Lookup คำนวณแบบ lazy เหมือน Rollup (§14.3)** — record ที่มีอยู่ก่อนสร้างฟิลด์จะยังว่างจนกว่าจะเขียน relation field ของ record นั้นซ้ำ

### 15.4 Dynamic Value ผ่าน CLI

เทียบฟิลด์กับฟิลด์ ใส่ `dynamicSource` ในเงื่อนไข (ไม่ต้องตั้ง `isDynamicsource`):

```json
{"controlId": "<ฟิลด์ซ้ายมือ>", "dataType": 6, "spliceType": 1, "filterType": 13,
 "dynamicSource": [{"rcid": "", "cid": "<ฟิลด์ที่เอามาเทียบ>", "staticValue": "", "isAsync": false, "type": 0}]}
```

`filterType 13` = `>` · ยืนยันว่าเทียบตัวเลขถูกจริงจากหน้าจอ

⚠️ **`dataType` ที่ส่งไปถูกเซิร์ฟเวอร์เขียนทับ** — ส่ง `6` ให้ฟิลด์ Rollup อ่านกลับมาได้ `2` (text) แต่ **การเปรียบเทียบยังเป็นตัวเลขถูกต้อง** ⇒ อย่าตกใจตอนอ่านกลับ และอย่าพยายาม "แก้" ให้เป็น 6

### 15.5 🔴🔴 `checkType: 1` **ไม่บล็อกการเขียนผ่าน API/CLI**

`--check-type 1` แปลว่า "ตรวจทั้งหน้าบ้านและหลังบ้าน" แต่ **หลังบ้าน = endpoint ของการ submit ฟอร์ม ไม่ใช่ open API**

ยิงจริง: ทำให้ `จำนวนเงินที่ขอเบิก` (1,700) เกิน `วงเงินสูงสุดต่อครั้ง` (1,500) แล้วสั่ง `hap worksheet record update` บน record นั้น → **`resultCode: 1` สำเร็จ ไม่มี error** แต่พอเปิด record เดียวกันในหน้าจอแล้วแก้ฟิลด์ใด ๆ → **ขึ้นแถบแดงบล็อกทันที**

⇒ **ห้ามใช้ API/CLI เป็นเครื่องพิสูจน์ว่า Business Rule ทำงาน** — ผลลัพธ์จะดู "ผ่าน" เสมอไม่ว่ากฎจะถูกหรือผิด · ต้องเปิดฟอร์มจริงในหน้าจอ (ตรงกับกฎเดิมใน §4 ที่ให้ทดสอบด้วย Role Debugging)
⇒ ในทางกลับกัน **workflow และ seed script เขียนข้อมูลที่ละเมิดกฎฟอร์มได้เสมอ** เหมือนที่ workflow ข้าม `required` (§2 ข้อ 29) — ถ้าต้องการกันจริงที่ระดับข้อมูล ต้องมี gate ใน workflow ด้วย ไม่ใช่พึ่ง Business Rule อย่างเดียว

### 15.6 relation field ต้องตั้ง `showControls` ไม่งั้นตารางฝังในฟอร์มว่าง

relation ที่ `showtype: "5"` (แสดงเป็นตารางในฟอร์ม) ถ้า `showControls` เป็น `[]` หน้าฟอร์มจะขึ้น **"No visible fields"** ทั้งที่นับจำนวนแถวได้ถูก (`Total 2 view(s)`) — ตั้งด้วย `update-fields` โดยใส่ controlId ของคอลัมน์ที่ต้องการจากตารางลูก

---

## ที่มา

- ยิงจริงบนแอป `API-Lab` (24 + 26 ส.ค. 2569) — รายละเอียดใน `nocoly-api-lab/03-RTM-Status.md` §E
- โปรเจกต์ `nocoly-wfh-dgr` (ส.ค. 2569) — กับดักฝั่ง Browser
- โปรเจกต์ `tilsna-hr` — WF-HR-01 ยิงจริง 27 ส.ค. 2569 (get_single relation lookup, cascade delete, node-ref staleness) · WF-HR-02/WF-HR-03 ยิงจริง 27 ส.ค. 2569 (compute/get_single live re-evaluation, `kind:"record"` relation-write garbage) · P3-7/P3-8 ยิงจริง 27 ส.ค. 2569 (Business Rules + Dynamic Default relation-field limitation, Unique Index tooltip risk, Role Debugging workflow, ghost-object-after-reject, Dynamic Value/Escape UI quirks)
- `github.com/mingdaocom/hap-skills` commit `9d4ea6b` — 8 สกิล ~1.2 MB
- สกิล `nocoly-hybrid-builder-v2` v2.4.2 — `references/workflow-authoring-mcp.md`
## เงื่อนไขและ operator ในเงื่อนไข workflow (`operateCondition` / `filters`) — ยืนยันจากการยิงจริง 30 ส.ค. 2569

`[V]` **`conditionId` เป็น enum ที่ความหมายขึ้นกับชนิดฟิลด์ และ schema กลางของ skill ตีความผิดสำหรับฟิลด์ตัวเลข/ตัวเลือก/สมาชิก** — schema `operate-condition.schema.json` เขียนว่า `"7"=is empty · "8"=is not empty · "9"=> · "10"=>=` แต่การอ่านโครงจริงของ WF-HR-01…06 เทียบกับชื่อ branch และผลการยิงจริง ให้ผลตรงข้าม/ต่างออกไป:

| conditionId | ความหมายจริงที่ยืนยันแล้ว | หลักฐาน |
|---|---|---|
| `7` | **ไม่ว่าง (is not empty)** | branch `เป็นวันหยุด` (ฟิลด์ชื่อวันหยุด type 2) · `มีผู้อนุมัติ` (type 26) |
| `8` | **ว่าง (is empty)** | branch `ไม่มีเวลาเข้า` (type 16) · `ไม่พบข้อมูลสิทธิ` (rowid) · `ไม่พบผู้บังคับบัญชา` (type 26) |
| `9` | **เท่ากับ (=)** | branch `Approved…` (option type 11 = key ของ Approved) · `เคยตัด` (number type 6 = "1") |
| `10` | **ไม่เท่ากับ (≠)** | branch `…ยังไม่ตัดสิทธิ` (number = "1") — ยิงจริงแล้วเป็นจริงเมื่อค่า `0` |
| `33` | **เท่ากับ record ที่อ้างจาก node อื่น** (relation type 29) | filter ของ search node `ค้นหาสิทธิและยอดคงเหลือการลา` |

⇒ **ห้ามเดา `conditionId` จาก schema** — อ่านของจริงด้วย `hap --json workflow node get <pid> <nodeId>` แล้วลอกรูปมาเสมอ

`[V]` 🔴🔴 **`≠` ประเมินเป็น FALSE เมื่อฟิลด์เป็นค่าว่าง ใน `operateCondition` ของ branch — แต่ไม่เป็นแบบนั้นใน `filters` ของ get_multiple** · **branch:** พิสูจน์ด้วย A/B controlled test บน WF-HR-02 (record เหมือนกันทุกฟิลด์ ต่างแค่ flag `""` vs `"0"`) — ตัวที่ `"0"` ทำงานครบสาย ตัวที่ `""` ตกไป catch-all **เงียบสนิท ไม่มี error ไม่มีร่องรอยบน record** · **`filters` ของ get_multiple (typeId 13): ตรงข้ามกัน — ค่าว่างผ่านตามปกติ** พิสูจน์ 31 ส.ค. ด้วย probe workflow ที่คุมตัวแปรครบ (ฟิลด์ Number ชนิดเดียวกัน · `conditionId 10` ตัวเดียวกัน · `ignoreEmpty 0` เท่ากัน) ได้ 2 แถว = แถวที่ค่า `"0"` **และแถวที่ค่าว่าง** พร้อม control ยืนยันว่า filter ไม่ได้ถูกเมิน ⇒ ⚠️ **พิสูจน์แล้ว 2 context เท่านั้น (branch = พัง · get_multiple filter = ไม่พัง) · ที่เหลือยังไม่รู้** — `filter` ของ trigger `worksheet_event` · `get_single`/search (typeId 7) · filter ของ rollup/sub_process **ยังไม่เคยทดสอบ อย่าเหมาไปทั้งสองทาง** ⇒ 🔴 **ห้ามเหมาว่าอาการที่ context หนึ่งเกิดที่อีก context ด้วย** — เราเคยเหมาแบบนั้นแล้วไปแก้จุดที่ไม่ได้พัง 3 จุดสองโมดูล · ทางแก้ที่ถูกสำหรับ **branch**: ใช้ `flag eq "1"` → เส้น no-op แล้วให้ catch-all เป็นเส้นทำงาน หรือเพิ่ม OR group `is empty` (`conditionId 8`)

### ตารางสถานะ `conditionId` — สินทรัพย์ร่วมสองโมดูล (อัปเดต 31 ส.ค. 2569)

สำรวจของจริงแล้วทั้งสองโมดูล: **HR 12 process** + **บัญชี 7 process / 66 เงื่อนไข** ⇒ ระบบนี้ใช้ `conditionId` ต่างกันอย่างน้อย **11 ตัว** และเรารู้ความหมายแน่ ๆ แค่ **5 ตัว**

| conditionId | ความหมาย | สถานะ | พบที่ไหน / ทำไมต้องรู้ |
|---|---|---|---|
| `7` | ไม่ว่าง (is not empty) | ✅ `[V]` | HR เท่านั้น — **บัญชีไม่ใช้เลย** |
| `8` | ว่าง (is empty) | ✅ `[V]` **ข้ามโมดูล + ข้าม context** | HR branch (ยิงจริง) · บัญชี branch (`ZZTEST-REV-001` 31 ส.ค.) · **`filters` ของ get_multiple typeId 13 (probe 31 ส.ค. — กลุ่ม `="77"` OR `8` ได้ 1 แถว ขณะที่ `="77"` เดี่ยวได้ 0)** ⇒ ใช้ได้ทั้ง branch และ filter ของ 13 · search(7) ยังไม่ทดสอบ |
| `9` | เท่ากับ (=) | ✅ `[V]` | บัญชีใช้ 18 จุด (มากที่สุด) |
| `10` | ไม่เท่ากับ (≠) **สำหรับฟิลด์ Number** | ✅ `[V]` | **ตัวที่ก่อ D-19 เมื่ออยู่ใน branch** · ใน `filters` ของ get_multiple ทำงานถูกต้อง (ค่าว่างผ่าน) · context อื่นยังไม่ทดสอบ · บัญชีใช้ 8 จุด · HR 5 จุด |
| `33` | เท่ากับ record ที่อ้างจาก node อื่น (relation) | ✅ `[V]` | บัญชี 7 จุด |
| **`12`** | ❓ **ไม่รู้** | 🔴 ยังไม่พิสูจน์ | บัญชี **15 จุด — ใช้เยอะเป็นอันดับ 2 ของทั้งระบบ** · 14 จุดใช้กับ `Result` (มีค่าเสมอ ปลอดภัย) แต่ **1 จุดใช้กับฟิลด์ตัวเลข `คงค้าง` ใน get_multiple** ⇒ ถ้า `12` เป็น `>` เจ้าหนี้ที่ยอดว่างจะหลุดการแจ้งเตือนเงียบ ๆ แบบเดียวกับ D-19 |
| **`41`** | ❓ **ไม่รู้** | 🔴 ยังไม่พิสูจน์ | บัญชี 4 จุด **ทั้ง 4 เป็นฟิลด์วันที่** (`วันครบกำหนดชำระ` · `Modified Time` · `วันที่ความรับผิดทางภาษีเกิดขึ้น`) ⇒ ตรงกับกลุ่มเสี่ยง "เงื่อนไขวันที่แบบก่อนวันที่ X กับวันที่ว่าง" |
| **`1`** | **น่าจะเป็น "อยู่ในชุดค่าที่กำหนด (is one of)" สำหรับฟิลด์ตัวเลือก (type 11)** | 🔶 `[V]` บางส่วน **6 ก.ย. 2569** — MCP `op:"in"` + `right` เป็น array ของ option key แปลงออกมาเป็น `1` พร้อม `conditionValues` ครบทุกค่า · ใช้จริงใน WF-HR-18 และ WF-HR-07 แล้วได้ผลถูกต้องทั้งคู่ · 🔴 **ยังไม่ได้ทดสอบแบบแยกแยะ** — ตอนทดสอบ พนักงานทั้ง 10 คนอยู่ในชุด {Probation, Active, On leave} หมด จึงพิสูจน์ได้แค่ว่า "ไม่ตัดของที่ควรผ่าน" **ยังไม่พิสูจน์ว่าตัดค่าที่อยู่นอกชุดออกจริง** | บัญชี 6 จุด (`Record ID`, `เดือนภาษี`) |
| **`29`** | ❓ ไม่รู้ | 🟡 | บัญชี 4 จุด (relation, `isCheckDay`) — ใช้คัดบัญชีตอนปิดปี |
| **`2`** | **operator ตระกูลปฏิเสธ สำหรับฟิลด์ Text** (น่าจะเป็น `≠`) | 🔶 `[V]` บางส่วน **31 ส.ค.** | probe: `flag <2> "1"` บนฟิลด์ Text ได้ 2 แถว (ตัดทิ้งได้ว่าเป็น `=`/`contains`/`starts_with` ซึ่งจะได้ 6) · ⚠️ **แยก `≠` ออกจาก `not contains` / `not starts_with` ไม่ได้ เพราะค่าทดสอบเป็นอักขระเดียวล้วน** — ต้องมีแถวค่า `"12"` ถึงจะแยกได้ · หลักฐานประกอบ: MCP `batch_create_process_nodes` แปลง `op:"ne"` บนฟิลด์ Text ออกมาเป็น `2` · 🔴 **สิ่งที่พิสูจน์แน่แล้วคือ: `conditionId` ของ operator เดียวกันต่างกันตามชนิดฟิลด์** — `≠` = `10` บน Number แต่ = `2` บน Text ⇒ **ตารางนี้ต้องระบุชนิดฟิลด์กำกับเสมอ** |
| **`42`** | **`≤` (น้อยกว่าหรือเท่ากับ) สำหรับฟิลด์วันที่ (type 15)** | ✅ `[V]` **6 ก.ย. 2569** — MCP `op:"lte"` บนฟิลด์ Date แปลงออกมาเป็น `42` และ **ทดสอบแบบแยกแยะได้จริง**: WF-HR-07 filter `วันเริ่มงาน ≤ 2019-01-31` บนพนักงาน 10 คน → คืน **1 คน** (EMP-0001 เริ่มงาน 2019-01-07) ตัดอีก 9 คนที่เริ่มงานหลังจากนั้นออกถูกต้อง · ⚠️ **ยังไม่ได้ทดสอบกรณีวันที่เท่ากันพอดี** จึงยังแยก `≤` กับ `<` ไม่ได้ 100% | 🆕 **HR ก็ใช้** — WF-HR-05 filter ฟิลด์วันที่ `วันที่ทำงาน` โดย `conditionValues` **ว่าง** (`[None]`) ⇒ น่าจะเป็น operator วันที่แบบไม่ต้องมีค่า (เช่น "วันนี้"/"ก่อนวันนี้") · อยู่ตระกูลเดียวกับ `41` ที่บัญชีใช้ 4 จุดบนฟิลด์วันที่ |
| **`31` `40`** | ❓ ไม่รู้ | 🟡 | บัญชีอย่างละ 1 จุด |

🔴 **กฎคัดกรองที่ใช้หา D-19 ตัวถัดไป:** *operator ไหนที่ "คำตอบที่ถูกต้องเมื่อฟิลด์ว่าง คือ TRUE" ตัวนั้นอันตราย* — `≠`, `>`, `<`, `ก่อนวันที่ X` เข้าข่ายทั้งหมด ส่วน `=`/`ว่าง`/`ไม่ว่าง` ไม่เข้าข่าย
⇒ **การไล่ทีละบั๊กจะไม่มีวันจบ** ตารางนี้เป็นที่รวม — ใครพิสูจน์ตัวไหนได้ให้เติมพร้อมหลักฐานการยิงจริง

`[V]` ❌ **"Ignore null value" (`ignoreEmpty` / `ignoreValueEmpty`) ไม่ใช่ทางแก้ของ D-19** — ทุกเงื่อนไขบน Browser UI มีเช็คบ็อกซ์นี้ และดูเหมือนจะแปลว่า "ค่าว่างให้ถือว่าผ่าน" **แต่ไม่ใช่** · ทดสอบบน WF-HR-02 (ถอด OR group ที่สองออกให้เหลือกลุ่มเดียว): ติ๊ก `ignoreEmpty=1` กับฟิลด์ว่าง → **ยังตกเหมือนเดิม** · ติ๊กทั้ง `ignoreEmpty` + `ignoreValueEmpty` → **ยังตกเหมือนเดิม** · control ที่ค่า `"0"` ผ่านปกติ (พิสูจน์ว่าชุดทดสอบไม่พัง) · regression หลังคืน OR group ผ่านปกติ ⇒ **การเพิ่ม OR group `is empty` (`conditionId 8`) ยังเป็นวิธีเดียวที่พิสูจน์แล้ว** · ความหมายจริงของช่องนี้ยังไม่ทราบ (เดาว่าเกี่ยวกับ**ค่าเปรียบเทียบฝั่งขวา** ว่าง ไม่ใช่ฟิลด์ฝั่งซ้าย — ยังไม่ทดสอบ)

✅ **ช่องว่างนี้ปิดแล้ว 31 ส.ค. 2569** — `conditionId 8` ใน `filters` ของ **get_multiple (typeId 13)** ใช้ได้จริง และที่สำคัญกว่านั้น **จุดเหล่านั้นไม่เคยพังตั้งแต่แรก** (WF-HR-05 ของ HR · WF-AC-09/12 ของบัญชี) เพราะ `≠` ใน `filters` ผ่านค่าว่างอยู่แล้ว · ⚠️ **ยังไม่ได้ทดสอบกับ node ชนิด search (typeId 7)** — คนละชนิดกับ 13 อย่าเหมา

### 🔬 วิธีพิสูจน์ operator ที่ไม่รู้ความหมาย โดยไม่แตะระบบจริง (probe workflow)

ใช้กับ `12` `41` `1` `29` `31` `40` `42` ที่ยังค้าง · ต้นทุนจริงที่วัดได้ **~25 นาที ต่อชุด 5 รอบทดสอบ**

1. `hap worksheet create <app> "ZZ-…" --alias zz_… --fields '[…]'` — ตารางชั่วคราวของตัวเอง ไม่มีใครใช้ ⇒ publish workflow บนตารางนี้ไม่กระทบใคร
2. seed ข้อมูลตายตัวที่ครอบทุกกรณี: ค่าปกติ · **ค่าว่าง** · ค่าที่ต้องไม่แมตช์ · 🔴 **ค่าทดสอบต้องแยกแยะ operator ที่หน้าตาเหมือนกันได้** — ถ้าใช้อักขระเดียวล้วน (`"1"` `"0"` `""`) จะแยก `≠` ออกจาก `not contains` / `not starts_with` ไม่ได้เลย **ต้องมีแถวค่า `"12"` ด้วยเสมอ**
3. `create_process` (trigger `worksheet_event` / `add` บนตารางนั้น) → `get_multiple(filters=ที่จะทดสอบ)` → `rollup(count)` → `update_record` เขียนจำนวนกลับ record ที่จุด flow
4. เปลี่ยน `filters` ด้วย `hap workflow node save --type 13` (ส่ง config ครบก้อนตามข้อ 24) → **`publish` ทุกครั้ง** → สร้าง record ใหม่ 1 ใบ = 1 รอบทดสอบ · **จำนวนที่ได้คือคำตอบ** · ⚠️ record ที่ใช้จุด flow ต้องตั้งค่าให้**ไม่เข้าเงื่อนไขใดเลย** ไม่งั้นมันจะนับตัวเอง
5. 🔴 **ต้องมี control ≥ 2 ตัวเสมอ** — เงื่อนไขที่รู้คำตอบแน่ (พิสูจน์ว่า filter ไม่ถูกเมิน) และเงื่อนไขที่ต้องได้ **0** (พิสูจน์ว่ากลุ่มที่สนใจคือตัวที่ให้ผล)
6. อ่านกลับ **ทุกคีย์** หลัง `node save` ตามข้อ 23 ไม่ใช่แค่ `filters`
7. `delete_process` + `hap worksheet delete <ws> -a <app> -y` แล้วยืนยันว่าหายจริง

`[V]` **`workflow structure` ไม่คืน `filters`/`operateCondition` ของ node ชนิด search (typeId 7)** — คืนแค่ `appId`/`executeType` ⇒ ต้องใช้ `hap workflow node get <pid> <nodeId>` ถึงจะเห็นเงื่อนไขค้นหาจริง

## กับดักของ `hap worksheet record` — ยืนยัน 30 ส.ค. 2569

`[V]` 🔴 **`record update <ws_id> <ROW_ID>` ต้องใช้ `rowId` แบบ UUID ไม่ใช่ `_id` แบบ 24-hex** — ถ้าใส่ `_id` จะได้ `{"resultCode": 4}` **โดยไม่มีข้อความ error ใด ๆ** และ record ไม่ถูกแก้ · `record list` คืนทั้งสองคีย์ (`_id` = 24-hex, `rowId` = UUID) จึงหยิบผิดได้ง่ายมาก · `record create` คืน `rowid` (UUID) มาให้ใช้ต่อได้เลย · **กฎ: เจอ `resultCode: 4` ให้สงสัยรูปแบบ id ก่อนสงสัย permission/business rule**

`[V]` 🔴🔴 **`hap worksheet record list` คืนแค่ 20 แถวเป็นค่าเริ่มต้น (`--page-size` default = 20)** — ไม่มีอะไรบอกว่าถูกตัด ⇒ **ห้ามใช้ผลจากคำสั่งนี้นับจำนวนแถว** และห้ามสรุปว่า "ตารางมีแค่เท่านี้" · ต้องใส่ `-n <มาก ๆ>` และ**วนหน้าจนกว่าจะได้น้อยกว่า page size** · เจอจริง: seed 24 แถวแล้วนับได้ 20 · `hr_holiday` ที่เคยรายงานว่า "20 แถว" จริง ๆ มี 21 · อยู่ตระกูลเดียวกับ `get_workflow_list`/`hap workflow list` ที่ผลว่างหรือสั้นไม่ใช่หลักฐาน

`[V]` **`record create/update --no-workflow` ถูกปฏิเสธ ไม่ใช่ถูกเพิกเฉย** — CLI ตอบเป็น `ValueError` พร้อมบอกให้ปิด workflow ก่อน (`hap workflow publish <id> --disable`) แล้วค่อยแก้ · ต่างจาก MCP `triggerWorkflow:false` ที่รับพารามิเตอร์ไปเงียบ ๆ
