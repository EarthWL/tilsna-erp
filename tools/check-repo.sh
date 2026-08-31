#!/usr/bin/env bash
# check-repo.sh — ตรวจว่า "เรโปนี้" พร้อมใช้กลไกจองงานจริงไหม
# ต่างจาก run-tests.sh ที่สร้างเรโปชั่วคราวของตัวเองมาทดสอบ (ผ่านได้แม้เรโปจริงยังใช้ไม่ได้)
set -uo pipefail
ok=0; bad=0
say(){ if [ "$1" = y ]; then echo "  ✅ $2"; ok=$((ok+1)); else echo "  ❌ $2"; bad=$((bad+1)); fi; }

git rev-parse --show-toplevel >/dev/null 2>&1 \
  && say y "อยู่ใน git repo: $(git rev-parse --show-toplevel)" \
  || { say n "ไม่ได้อยู่ใน git repo — รัน 'git init' ก่อน"; echo; echo "สรุป: ใช้ไม่ได้"; exit 1; }

B="$(git rev-parse --abbrev-ref HEAD)"; say y "branch ปัจจุบัน: $B"

if git remote get-url origin >/dev/null 2>&1; then
  say y "มี remote origin: $(git remote get-url origin)"
  if git ls-remote --exit-code origin >/dev/null 2>&1; then
    say y "ติดต่อ remote ได้ (auth ผ่าน)"
    git ls-remote --exit-code --heads origin "$B" >/dev/null 2>&1 \
      && say y "branch '$B' มีอยู่บน remote" \
      || say n "branch '$B' ยังไม่มีบน remote — push ครั้งแรกก่อน: git push -u origin $B"
  else
    say n "ติดต่อ remote ไม่ได้ (เน็ต/สิทธิ์/credential)"
  fi
else
  say n "ไม่มี remote 'origin' — การชิงสิทธิ์ตัดสินที่ remote จึงใช้ไม่ได้เลย"
fi

[ -d shared/claims ] && say y "มีโฟลเดอร์ shared/claims" || { mkdir -p shared/claims && say y "สร้าง shared/claims ให้แล้ว"; }
[ -d handoff ] && say y "มีโฟลเดอร์ handoff" || { mkdir -p handoff && say y "สร้าง handoff ให้แล้ว"; }
for f in preflight.sh postflight.sh claimlib.sh; do
  [ -x "tools/$f" ] && say y "tools/$f รันได้" || say n "tools/$f ไม่มีหรือไม่มีสิทธิ์รัน (chmod +x)"
done
[ -f ENV.md ] && say y "มี ENV.md" || echo "  ⚠️  ยังไม่มี ENV.md (ไม่บล็อก แต่ควรสร้างจาก assets/AgentProtocol-template.md)"
# ── เตือนขนาดไฟล์ที่ agent ต้องเปิดอ่าน ────────────────────────────────────
# เพดาน Read ของ agent = 25,000 tokens · วัดจริงบน repo นี้ ~7 bytes/token (ข้อความไทย)
# => ~175,000 bytes คือขีดที่อ่านไม่จบใน 1 call
#   WARN ที่ 150,000 (~86% ของเพดาน) เพื่อให้มีเวลาจัดการก่อนชน
#   OVER ที่ 175,000 = อ่านไม่จบแล้วจริง ๆ ต้องแยกไฟล์
#
# 🔴 บทเรียน 31 ส.ค. 2569: เดิมเช็คแค่ `04-CLAUDE-memory.md` ไฟล์เดียว ทำให้
#    `02-BuildSpec-FRS.md` (276 KB) และ `05-Roadmap-Tracker.md` (160 KB) โตทะลุเพดาน
#    โดยไม่มีใครเห็น — และตัวเลข "memory เล็กลง" ก็ดูดีขึ้นได้ด้วยการย้ายของออกไปไฟล์
#    ที่ไม่ถูกวัด ⇒ เกณฑ์ต้องครอบทุกไฟล์ที่ agent ต้องเปิด ไม่ใช่ไฟล์เดียว
WARNMAX=${WARNMAX:-${MEMMAX:-150000}}
OVERMAX=${OVERMAX:-175000}
tot_warn=0
check_size() {
  m="$1"; [ -f "$m" ] || return 0
  sz=$(wc -c <"$m")
  if [ "$sz" -gt "$OVERMAX" ]; then
    echo "  🔴 $m = $(printf "%'d" "$sz") bytes (~$((sz/7)) tokens) — **เกินเพดาน Read 25,000 tokens อ่านไม่จบใน 1 call**"
    echo "      ต้องแยกไฟล์ (ดู MIGRATION.md §C) — ไม่บล็อก แต่ agent จะอ่านไฟล์นี้ไม่ครบทุก session"
    tot_warn=$((tot_warn+1))
  elif [ "$sz" -gt "$WARNMAX" ]; then
    echo "  ⚠️  $m = $(printf "%'d" "$sz") bytes (~$((sz/7)) tokens) เกินเกณฑ์เตือน $(printf "%'d" "$WARNMAX")"
    echo "      ใกล้ชนเพดานแล้ว ถึงเวลาจัดการตาม MIGRATION.md §C"
    tot_warn=$((tot_warn+1))
  else
    say y "$m = $(printf "%'d" "$sz") bytes (~$((sz/7)) tokens) อยู่ในเกณฑ์"
  fi
}
# ไฟล์ที่ agent ต้องเปิดอ่าน — ครอบทั้งสองโมดูล + คู่มือกลาง
for m in projects/*/02-BuildSpec-FRS.md \
         projects/*/03-RTM-Status.md \
         projects/*/04-CLAUDE-memory.md \
         projects/*/05-Roadmap-Tracker.md \
         shared/00-HAP-Working-Guide.md; do
  check_size "$m"
done
[ "$tot_warn" -gt 0 ] && echo "  ── รวม $tot_warn ไฟล์ที่เกินเกณฑ์ (ไม่บล็อกการทำงาน)"

N="$(git config user.name)"; [ -n "$N" ] && say y "git identity = $N (ใช้เป็น agent-id)" || say n "ยังไม่ตั้ง git config user.name — ใช้เป็น agent-id ไม่ได้"

echo
if [ "$bad" -eq 0 ]; then echo "สรุป: พร้อมใช้ ($ok ผ่าน) — claim_protocol: on"
else echo "สรุป: ยังใช้ไม่ได้ ($bad ข้อไม่ผ่าน) — ถือว่า claim_protocol: off จนกว่าจะแก้ครบ"; exit 1; fi
