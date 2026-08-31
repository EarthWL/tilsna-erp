#!/usr/bin/env bash
# refcheck.sh — จับ "การอ้างอิง §หัวข้อ ที่ชี้ไปไฟล์อื่นแต่ไม่บอกว่าไฟล์ไหน"
#
# 🔴 ทำไมต้องมี (บทเรียน 31 ส.ค. 2569):
#   ตอนแยกไฟล์เอกสาร เราตรวจว่า "ไม่มีเนื้อหาหาย" ด้วยการนับตัวระบุ (ID/FR/WF/alias)
#   และเทียบชุดบรรทัด — ได้ผล "หาย 0" ซึ่งถูกต้องตามที่มันวัด
#   แต่ตัวอักษรเหมือนเดิมทุกตัว **สิ่งที่เปลี่ยนคือผู้ถูกอ้างถึง ไม่ใช่ตัวอักษร**
#   => "§1.7" ที่เคยหมายถึงหัวข้อในไฟล์เดียวกัน กลายเป็นการอ้างลอยทันทีที่ §1 ย้ายออก
#   วิธีตรวจแบบนับตัวระบุ **บอดต่อความเสียหายชนิดนี้โดยโครงสร้าง** — เจอมาแล้ว 24 จุด
#
# กฎที่บังคับ: การอ้าง §n ต้อง **อย่างใดอย่างหนึ่ง**
#   (ก) หัวข้อ §n นั้นมีอยู่จริงในไฟล์เดียวกัน  หรือ
#   (ข) บรรทัดนั้นระบุชื่อไฟล์ปลายทาง (มี `.md` อยู่ในบรรทัด)
#
# ใช้: bash tools/refcheck.sh            → รายงานจุดที่ผิดกฎ
#      bash tools/refcheck.sh --quiet    → พิมพ์เฉพาะจำนวน
# exit 0 เสมอ (เป็นคำเตือน ไม่บล็อก)
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0
python3 - "$@" <<'PY'
import io,re,sys,glob
quiet = "--quiet" in sys.argv
ref  = re.compile(r"§(\d+(?:\.\d+)*)")
head = re.compile(r"^#{1,6}\s*(?:§\s*)?(\d+(?:\.\d+)*)\s*[.)\s]")  # รับทั้ง "## §1.2 ..." และ "## 12. ..." (หลายไฟล์ใช้เลขล้วน)
bad_total=0
for f in sorted(glob.glob("projects/*/*.md")+glob.glob("shared/*.md")+glob.glob("*.md")):
    lines=io.open(f,encoding="utf-8").read().split("\n")
    own=set()
    for l in lines:
        m=head.match(l.strip())
        if m:
            own.add(m.group(1))
            own.add(m.group(1).split(".")[0])      # มี §1.6 ถือว่ามี §1 ด้วย
    bad=[]
    for n,l in enumerate(lines):
        if head.match(l.strip()): continue          # ตัวหัวข้อเอง
        if ".md" in l: continue                     # (ข) ระบุชื่อไฟล์แล้ว
        for m in ref.finditer(l):
            num=m.group(1)
            if num in own or num.split(".")[0] in own: continue   # (ก) มีในไฟล์เดียวกัน
            bad.append((n+1,m.group(0),re.sub(r"\s+"," ",l.strip())[:88]))
    if bad:
        bad_total+=len(bad)
        if not quiet:
            print("── %s" % f)
            for n,g,c in bad: print("   L%-5d %-7s %s" % (n,g,c))
if bad_total:
    print("\n🔴 พบการอ้าง § ที่ชี้ข้ามไฟล์โดยไม่ระบุชื่อไฟล์ %d จุด" % bad_total)
    print("   แก้เป็น: `<ชื่อไฟล์>.md` §n  — ห้ามปล่อยให้ agent ต้องเดาว่าหัวข้อนั้นอยู่ไฟล์ไหน")
else:
    print("✅ refcheck: การอ้าง § ทุกจุดชี้ได้ถูก (มีในไฟล์เดียวกัน หรือระบุชื่อไฟล์)")
PY
exit 0
