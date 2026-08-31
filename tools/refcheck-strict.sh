#!/usr/bin/env bash
# refcheck-strict.sh — ส่วนขยายของ `refcheck.sh` ที่ตรวจ **เลขหัวข้อย่อยเต็ม** ไม่ใช่แค่เลขหลัก
#
# 🔴 ทำไมต้องมี (บทเรียน 31 ส.ค. 2569 — จาก /scrutinize หลังแยก `02-BuildSpec-FRS.md`):
#   `refcheck.sh` ผ่านเมื่อ "ไฟล์ปลายทางมีหัวข้อเลขหลักตรงกัน" (มันเก็บทั้ง "1.2" และ "1")
#   ⇒ `ไฟล์.md` §4.1 **ผ่าน** ถ้าไฟล์นั้นมีแค่ §4 — ทั้งที่ §4.1 ไม่มีอยู่จริง
#   ตอนแยกไฟล์ ผมเติมชื่อไฟล์หน้า § 81 จุดโดยใช้กฎ "เลขหลัก 1→13 · 2→14 · 3→15"
#   แล้วยืนยันความถูกต้องด้วย refcheck — **ซึ่งเป็นการวนกลับ (circular)**:
#   กฎที่ใช้เติม กับ กฎที่ใช้ตรวจ เป็นกฎเดียวกัน (เลขหลัก) ⇒ ผ่านโดยโครงสร้าง ไม่ใช่เพราะถูก
#   ตัวตรวจนี้เข้มกว่าหนึ่งขั้น จึงจับได้ 10 จุดที่ refcheck มองไม่เห็น (3 จุดเป็นของที่ผมเพิ่งเติมผิดเอง)
#
# กฎ: `x.md` §a.b.c ผ่านเมื่อไฟล์ x มีหัวข้อ **a.b.c ตรงตัว** (ไม่ใช่แค่ a)
#     · § ที่ตรงกับหัวข้อในไฟล์ตัวเอง = ผ่าน · § ที่ไม่มีไฟล์กำกับ = ปล่อยให้ refcheck.sh ว่า
#     · ไฟล์นอก repo = ข้าม
#
# ใช้: bash tools/refcheck-strict.sh   · exit 0 เสมอ (เตือน ไม่บล็อก) — คู่กับ refcheck.sh ไม่ใช่แทน
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0
python3 - <<'PY'
import io,re,glob,os
head=re.compile(r"^#{1,6}\s*(?:§\s*)?(\d+(?:\.\d+)*)\s*[.)\s]")
tok =re.compile(r"`([^`]*\.md)`|§(\d+(?:\.\d+)*[a-z]?)")
ALL=sorted(set(glob.glob("projects/*/*.md")+glob.glob("shared/*.md")+glob.glob("*.md")))
def H(p):
    s=set()
    for l in io.open(p,encoding="utf-8"):
        m=head.match(l.strip())
        if m: s.add(m.group(1))
    return s
IDX={f:H(f) for f in ALL}; BY={}
for f in ALL: BY.setdefault(os.path.basename(f),[]).append(f)
def res(r,src):
    c=BY.get(os.path.basename(r))
    if not c: return None
    if len(c)==1: return c[0]
    s=[x for x in c if os.path.dirname(x)==os.path.dirname(src)]
    if s: return s[0]
    for x in c:
        if r.replace("\\","/") in x: return x
    return c[0]
bad=[]; ok=0; ext=0
for f in ALL:
    own=H(f)
    for i,l in enumerate(io.open(f,encoding="utf-8"),1):
        if head.match(l.strip()): continue
        ctx=None
        for m in tok.finditer(l):
            if m.group(1): ctx=m.group(1); continue
            num=m.group(2).rstrip("abc")
            if num in own: ok+=1; continue
            if ctx is None: continue          # refcheck.sh ดูแลเคสนี้
            t=res(ctx,f)
            if t is None: ext+=1; continue
            if num in IDX[t]: ok+=1
            else: bad.append((f,i,m.group(2),os.path.basename(t),re.sub(r"\s+"," ",l.strip())[:66]))
if bad:
    print("\n\U0001F534 ระบุไฟล์แล้ว แต่ไฟล์นั้นไม่มีหัวข้อ**ย่อย**เลขนั้น (%d จุด)"%len(bad))
    cur=None
    for b in bad:
        if b[0]!=cur: cur=b[0]; print("── %s"%cur)
        print("   L%-5d §%-8s -> %s | %s"%b[1:])
print("\nสรุป (strict): ชี้ถูกถึงเลขย่อย %d · ชี้ผิดเลขย่อย %d · ไฟล์นอก repo %d (ข้าม)"%(ok,len(bad),ext))
print("✅ refcheck-strict: เลขหัวข้อย่อยทุกจุดมีอยู่จริง" if not bad
      else "   แก้เป็นไฟล์ที่ถือหัวข้อนั้นจริง — อย่าปล่อยให้ผ่านเพราะเลขหลักบังเอิญตรง")
PY
exit 0
