# ตัวสร้างหนังสือรับรองการหักภาษี ณ ที่จ่าย (PDF)

รันใน cloud sandbox ของ agent เท่านั้น (ต้องมี playwright + chromium + `hap` CLI)

1. `mkdir fonts && cd fonts` แล้วดึงฟอนต์ Sarabun (ไทย) — reportlab/Chromium ต้องมีฟอนต์ฝังในหน้า
   - `curl -o Sarabun-Regular.ttf "https://fonts.gstatic.com/s/sarabun/v17/DtVjJx26TKEr37c9WBI.ttf"`
   - `curl -o Sarabun-Bold.ttf "https://fonts.gstatic.com/s/sarabun/v17/DtVmJx26TKEr37c9YK5sulw.ttf"`
   - (URL ที่ถูกต้อง ณ เวลานั้นอ่านได้จาก `https://fonts.googleapis.com/css2?family=Sarabun:wght@400;700`)
2. `data.json` = ข้อมูลที่อ่านจากระบบแล้ว (AC_WHT_CERT + AC_PARTNER + ประเภทเงินได้) — **อย่ากรอกมือ ให้ดึงจาก MCP ทุกครั้ง**
3. `python3 render.py` → ได้ PDF ใน `out/`
4. แนบขึ้นระบบ: `hap upload` เพื่อเอา signed URL แล้วเขียนด้วย **MCP `update_record`**
   ⚠️ `hap worksheet record update` เขียนฟิลด์แนบไฟล์ไม่ผ่าน (`附件保存失败，参数错误`) — ดู MIGRATION.md D-46
