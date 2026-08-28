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
N="$(git config user.name)"; [ -n "$N" ] && say y "git identity = $N (ใช้เป็น agent-id)" || say n "ยังไม่ตั้ง git config user.name — ใช้เป็น agent-id ไม่ได้"

echo
if [ "$bad" -eq 0 ]; then echo "สรุป: พร้อมใช้ ($ok ผ่าน) — claim_protocol: on"
else echo "สรุป: ยังใช้ไม่ได้ ($bad ข้อไม่ผ่าน) — ถือว่า claim_protocol: off จนกว่าจะแก้ครบ"; exit 1; fi
