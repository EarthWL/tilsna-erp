#!/usr/bin/env bash
# refcheck.sh — ตรวจว่า "การอ้าง §หัวข้อ" ทุกจุด **ชี้ไปที่มีอยู่จริง**
#
# 🔴 ทำไมต้องมี (บทเรียน 31 ส.ค. 2569):
#   ตอนแยกไฟล์เอกสาร เราตรวจ "ไม่มีเนื้อหาหาย" ด้วยการนับตัวระบุ + เทียบชุดบรรทัด
#   ได้ผล "หาย 0" ซึ่งถูกต้องตามที่มันวัด — แต่ตัวอักษรเหมือนเดิมทุกตัว
#   **สิ่งที่เปลี่ยนคือผู้ถูกอ้างถึง ไม่ใช่ตัวอักษร** => "§1.7" กลายเป็นการอ้างลอย
#   วิธีนับตัวระบุบอดต่อความเสียหายชนิดนี้โดยโครงสร้าง (เจอ 44 จุด)
#
# 🔴 รุ่น 2 (31 ส.ค. 2569 รอบบ่าย — จาก /scrutinize รอบสอง):
#   รุ่นแรกใช้เกณฑ์ "บรรทัดมีคำว่า .md อยู่ที่ไหนก็ได้ = ผ่าน" ซึ่งเป็น **ตัวแทน**
#   ของสิ่งที่อยากรู้จริง ไม่ใช่ตัวมันเอง => ปล่อยผ่าน 61 จุดที่ § ไม่ได้ผูกกับไฟล์ใด
#   และ **ไม่เคยตรวจเลยว่าหัวข้อที่ถูกอ้างมีอยู่จริงไหม** (`ไฟล์.md` §9.9 ก็ผ่าน)
#
# กฎรุ่น 2 — อ่านบรรทัดจากซ้ายไปขวาเหมือนคนอ่าน:
#   1. `x.md` ที่พบล่าสุดในบรรทัด = "ไฟล์ที่กำลังพูดถึง" ของ § ถัดจากนั้นไปจนกว่าจะเจอไฟล์ใหม่
#   2. §n ผ่านเมื่อ (ก) มีหัวข้อ §n ในไฟล์ตัวเอง หรือ
#                  (ข) มีไฟล์กำกับ **และไฟล์นั้นมีหัวข้อ §n จริง**
#   3. ไฟล์ที่อ้างแต่ไม่มีใน repo (เช่นไฟล์สกิล) = ข้าม พร้อมนับแยกไว้ให้เห็น
#
# ใช้: bash tools/refcheck.sh [--quiet]   · exit 0 เสมอ (เตือน ไม่บล็อก)
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0
python3 - "$@" <<'PY'
import io,re,sys,glob,os
quiet="--quiet" in sys.argv
head=re.compile(r"^#{1,6}\s*(?:§\s*)?(\d+(?:\.\d+)*)\s*[.)\s]")   # รับทั้ง "## §1.2" และ "## 12."
tok =re.compile(r"`([^`]*\.md)`|§(\d+(?:\.\d+)*)")

def headings(path):
    s=set()
    for l in io.open(path,encoding="utf-8"):
        m=head.match(l.strip())
        if m: s.add(m.group(1)); s.add(m.group(1).split(".")[0])
    return s

# 🔴 ห้ามทำดัชนีด้วย basename อย่างเดียว: repo นี้มี 00-README/02-BuildSpec/03-RTM/04-memory/
#    05-Roadmap ชื่อซ้ำกันทั้งใน projects/hr และ projects/accounting
#    (รุ่นแรกใช้ basename แล้วเจอของ accounting ก่อน ทำให้ฟ้องผิด 9 จุดว่า "ไม่มีหัวข้อนี้")
ALL=sorted(set(glob.glob("projects/*/*.md")+glob.glob("shared/*.md")+glob.glob("*.md")+glob.glob("handoff/*.md")))
IDX={f:headings(f) for f in ALL}
BYNAME={}
for f in ALL: BYNAME.setdefault(os.path.basename(f),[]).append(f)

def resolve(ref, src):
    """หาไฟล์ปลายทางจากชื่อที่อ้าง — ไฟล์ในโฟลเดอร์เดียวกันมาก่อนเสมอ"""
    base=os.path.basename(ref)
    cands=BYNAME.get(base)
    if not cands: return None
    if len(cands)==1: return cands[0]
    d=os.path.dirname(src)
    same=[c for c in cands if os.path.dirname(c)==d]
    if same: return same[0]
    # อ้างแบบมี path นำหน้า เช่น projects/accounting/xx.md
    for c in cands:
        if ref.replace("\\","/") in c: return c
    return cands[0]

SCAN=sorted(set(glob.glob("projects/*/*.md")+glob.glob("shared/*.md")+glob.glob("*.md")))
noname=[]; badtgt=[]; ext=0; ok=0
for f in SCAN:
    own=headings(f)
    for n,l in enumerate(io.open(f,encoding="utf-8")):
        if head.match(l.strip()): continue
        ctx=None
        for m in tok.finditer(l):
            if m.group(1): ctx=os.path.basename(m.group(1)); continue
            num=m.group(2)
            if num in own or num.split(".")[0] in own: ok+=1; continue     # (ก)
            if ctx is None:
                noname.append((f,n+1,num,re.sub(r"\s+"," ",l.strip())[:84])); continue
            tgt=resolve(ctx,f)
            if tgt is None: ext+=1; continue                                 # ไฟล์นอก repo (เช่นไฟล์สกิล)
            if num in IDX[tgt] or num.split(".")[0] in IDX[tgt]: ok+=1      # (ข) ชี้ถูกจริง
            else: badtgt.append((f,n+1,num,tgt,re.sub(r"\s+"," ",l.strip())[:70]))

def show(title,rows,fmt):
    if not rows: return
    print("\n%s (%d จุด)" % (title,len(rows)))
    if quiet: return
    cur=None
    for r in rows:
        if r[0]!=cur: cur=r[0]; print("── %s" % cur)
        print(fmt % r[1:])

show("🔴 อ้าง § โดยไม่บอกว่าอยู่ไฟล์ไหน", noname, "   L%-5d §%-7s %s")
show("🔴 ระบุไฟล์แล้ว แต่ไฟล์นั้นไม่มีหัวข้อนี้", badtgt, "   L%-5d §%-7s -> %s | %s")
print("\nสรุป: ชี้ถูก %d · ไม่บอกไฟล์ %d · ชี้ผิดเป้า %d · อ้างไฟล์นอก repo %d (ข้าม)"
      % (ok,len(noname),len(badtgt),ext))
if not noname and not badtgt: print("✅ refcheck: การอ้าง § ทุกจุดชี้ไปที่มีอยู่จริง")
else: print("   แก้เป็น: `<ชื่อไฟล์>.md` §n — และหัวข้อนั้นต้องมีอยู่จริงในไฟล์นั้น")
PY
exit 0
