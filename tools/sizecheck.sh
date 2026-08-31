#!/usr/bin/env bash
# sizecheck.sh — เตือนขนาดไฟล์ที่ agent ต้องเปิดอ่าน
#   ใช้ได้ 2 แบบ: รันตรง (`bash tools/sizecheck.sh`) หรือ source แล้วเรียก `run_sizecheck`
#   ไม่เคยคืน exit code ที่ไม่ใช่ 0 — เป็นคำเตือนล้วน ห้ามบล็อกงานใคร
#
# ── การคาลิเบรต (อย่าเดา ให้แก้พร้อมหลักฐาน) ──────────────────────────────
# เพดาน Read ของ agent = 25,000 tokens
# อัตราส่วนที่ "วัดจริง" บน repo นี้ = 7.46 bytes/token (ข้อความไทยปนโค้ด)
#   จุดข้อมูล: 217,234 b ↔ ~29,108 tokens · 134,546 b ↔ ~18,028 tokens (28–30 ส.ค. 2569)
# ⇒ เพดานจริง ≈ 25,000 × 7.46 = 186,500 bytes
#
# 🔴 บทเรียน 31 ส.ค. 2569 (จาก /scrutinize): เคยเขียนทับค่านี้เป็น 7 / 175,000
#    โดยไม่ได้วัดใหม่ ทำให้ข้อความ "เกินเพดาน อ่านไม่จบ" กลายเป็นเท็จสำหรับไฟล์
#    ขนาด 175,000–186,500 (ซึ่งอ่านจบ) — คำเตือนที่ผิดคือสิ่งที่ทำให้ guardrail ถูกเมิน
#    **ถ้าจะเปลี่ยนตัวเลขพวกนี้ ต้องแนบจุดข้อมูลที่วัดได้จริงมาด้วยเสมอ**
BYTES_PER_TOKEN=${BYTES_PER_TOKEN:-746}          # ×100 เพื่อคำนวณด้วยจำนวนเต็ม
OVERMAX=${OVERMAX:-186500}                        # = เพดานจริง อ่านไม่จบแน่นอน
WARNMAX=${WARNMAX:-${MEMMAX:-150000}}             # ~80% ของเพดาน · MEMMAX เดิมยังใช้ได้

_tok() { echo $(( $1 * 100 / BYTES_PER_TOKEN )); }
_n()   { printf "%'d" "$1"; }

run_sizecheck() {
  local prefix="${1:-  }" m sz n=0
  for m in projects/*/02-BuildSpec-FRS.md \
           projects/*/03-RTM-Status.md \
           projects/*/04-CLAUDE-memory.md \
           projects/*/05-Roadmap-Tracker.md \
           shared/00-HAP-Working-Guide.md; do
    [ -f "$m" ] || continue
    sz=$(wc -c <"$m")
    if [ "$sz" -gt "$OVERMAX" ]; then
      echo "${prefix}🔴 $m = $(_n "$sz") bytes (~$(_tok "$sz") tokens) — เกินเพดาน Read 25,000 tokens **อ่านไม่จบใน 1 call**"
      n=$((n+1))
    elif [ "$sz" -gt "$WARNMAX" ]; then
      echo "${prefix}⚠️  $m = $(_n "$sz") bytes (~$(_tok "$sz") tokens) — ใกล้ชนเพดาน (เกินเกณฑ์เตือน $(_n "$WARNMAX"))"
      n=$((n+1))
    else
      [ -n "${SIZECHECK_QUIET:-}" ] || echo "${prefix}✅ $m = $(_n "$sz") bytes (~$(_tok "$sz") tokens) อยู่ในเกณฑ์"
    fi
  done
  [ "$n" -gt 0 ] && echo "${prefix}── รวม $n ไฟล์ที่เกินเกณฑ์ (ไม่บล็อกการทำงาน — แยกไฟล์ตาม MIGRATION.md §C)"
  return 0
}

# รันตรงเมื่อไม่ได้ถูก source
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0
  run_sizecheck "  "
fi
