#!/usr/bin/env bash
# preflight.sh <agent> <task> <app> <objects,csv>
# exit 0 = ได้สิทธิ์ · exit 1 = ชน/ล้มเหลว → agent ต้องหยุดและรายงานผู้ใช้
set -uo pipefail
. "$(dirname "$0")/claimlib.sh"
AGENT="$1"; TASK="$2"; APP="$3"; OBJS="$4"; ROOT="$(repo_root)"
LOG="$ROOT/shared/claims/$AGENT.log"; mkdir -p "$(dirname "$LOG")"; touch "$LOG"

for attempt in 1 2 3; do
  sync_repo; rc=$?; [ $rc -eq 0 ] || { echo "PREFLIGHT FAIL: $(sync_reason $rc)"; exit 1; }

  # TTL: ปลด CLAIM ที่ค้างเกิน TTL_HOURS (B2)
  while IFS='|' read -r ag iso app task objs; do
    [ -z "${ag:-}" ] && continue
    # เขียนลง log ของตัวเอง ไม่แตะไฟล์ของ agent อื่น (กันชนซ้ำรอย B1)
    echo "EXPIRED $(now_iso) $task by=$AGENT was=$ag" >> "$LOG"
    echo "PREFLIGHT WARN: ปลด CLAIM ค้างของ $ag ($task ตั้งแต่ $iso เกิน ${TTL_HOURS}h)"
  done < <(expired_claims)

  # ตรวจชน
  CONFLICT=""
  while IFS='|' read -r ag iso app task objs; do
    [ -z "${ag:-}" ] && continue
    [ "$ag" = "$AGENT" ] && continue
    [ "$app" != "$APP" ] && continue
    if objects_overlap "$objs" "$OBJS"; then CONFLICT="$ag ถือ $task ($objs) ตั้งแต่ $iso"; break; fi
  done < <(active_claims)
  [ -n "$CONFLICT" ] && { echo "PREFLIGHT BLOCK: $CONFLICT"; echo "→ หยุดและรายงานผู้ใช้ ห้ามยิงคำสั่งใด ๆ ใส่แอป"; exit 1; }

  # แจ้ง handoff ค้าง
  HF="$ROOT/handoff/$(echo "$TASK"|tr '/' '-').md"
  [ -f "$HF" ] && { echo "PREFLIGHT NOTE: มี handoff ค้าง — อ่านก่อนทำอย่างอื่น"; sed -n '/ยิงไปแล้ว/,/^## /p' "$HF"|head -20; }

  # จอง แล้วให้ remote ตัดสิน
  echo "CLAIM $(now_iso) $APP $TASK $OBJS" >> "$LOG"
  git add "$ROOT/shared/claims" >/dev/null
  if ! git commit -qm "claim($AGENT): $TASK"; then
    echo "PREFLIGHT FAIL: commit ใบจองไม่สำเร็จ — ยังไม่ได้ถือสิทธิ์ ห้ามแตะแอป"; exit 1
  fi
  if push_or_retry && claim_landed "$AGENT" "$TASK"; then
    echo "PREFLIGHT OK: $AGENT ถือ $TASK"
    # เตือนขนาดไฟล์ที่ agent ต้องเปิด — คำเตือนล้วน ห้ามกระทบ exit code ของการจอง
    # (เพิ่ม 31 ส.ค. 2569: guardrail ที่ไม่มีใครเรียก = ไม่มีใครวัด ซึ่งคือต้นเหตุที่
    #  02-BuildSpec/05-Roadmap โตทะลุเพดานโดยไม่มีใครเห็น)
    if [ -f "$ROOT/tools/sizecheck.sh" ]; then
      ( cd "$ROOT" && SIZECHECK_QUIET=1 . tools/sizecheck.sh && run_sizecheck "  " ) || true
    fi
    exit 0
  fi
  echo "PREFLIGHT RETRY $attempt: มีคนpushก่อน — ตรวจใหม่"
  git reset -q --hard HEAD~1
done
echo "PREFLIGHT FAIL: retry ครบ 3 ครั้งยังไม่ได้สิทธิ์ → หยุดและรายงานผู้ใช้"; exit 1
