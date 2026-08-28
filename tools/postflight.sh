#!/usr/bin/env bash
# postflight.sh <agent> <task> --release|--handoff
set -uo pipefail
. "$(dirname "$0")/claimlib.sh"
AGENT="$1"; TASK="$2"; MODE="$3"; ROOT="$(repo_root)"
LOG="$ROOT/shared/claims/$AGENT.log"
HF="$ROOT/handoff/$(echo "$TASK"|tr '/' '-').md"

if [ "$MODE" = "--handoff" ]; then
  [ -f "$HF" ] || { echo "POSTFLIGHT BLOCK: ต้องมี $HF ก่อน HANDOFF"; exit 1; }
  BODY=$(sed -n '/## ยิงไปแล้ว/,/^## /p' "$HF" | sed '1d;$d' | tr -d '[:space:]')
  [ -z "$BODY" ] && { echo "POSTFLIGHT BLOCK: หัวข้อ 'ยิงไปแล้วบนเซิร์ฟเวอร์' ว่าง — ถ้าไม่ได้แตะอะไรให้เขียน 'ไม่มี'"; exit 1; }
  LINE="HANDOFF $(now_iso) $TASK $HF"
else
  LINE="RELEASE $(now_iso) $TASK"
  [ -f "$HF" ] && { mkdir -p "$ROOT/handoff/.done"; git mv -f "$HF" "$ROOT/handoff/.done/" >/dev/null 2>&1; }
fi

for attempt in 1 2 3; do
  sync_repo || exit 1
  echo "$LINE" >> "$LOG"; git add -A >/dev/null
  if ! git commit -qm "close($AGENT): $TASK"; then
    echo "POSTFLIGHT FAIL: commit ไม่สำเร็จ — ใบจองยังไม่ถูกปิด"; exit 1
  fi
  if push_or_retry && [ "$(git rev-parse HEAD)" = "$(git ls-remote "$REMOTE" "$(cur_branch)" 2>/dev/null | cut -f1)" ]; then
    echo "POSTFLIGHT OK: ${MODE#--} $TASK"; exit 0
  fi
  git reset -q --hard HEAD~1
done
echo "POSTFLIGHT FAIL"; exit 1
