#!/usr/bin/env bash
# ไลบรารีร่วมของ preflight/postflight — อ่านสถานะการจองจาก shared/claims/*.log
TTL_HOURS="${TTL_HOURS:-8}"
REMOTE="${CLAIM_REMOTE:-origin}"   # ตั้ง CLAIM_REMOTE ได้ถ้า remote ที่ใช้ตัดสินการชิงสิทธิ์ไม่ได้ชื่อ origin

repo_root() { git rev-parse --show-toplevel; }
now_iso()   { date -u +%FT%TZ; }
to_epoch()  { date -u -d "$1" +%s 2>/dev/null || echo 0; }

# พิมพ์ CLAIM ที่ยัง active: agent|iso|app|task|objects
active_claims() {
  local root; root="$(repo_root)"
  local dir="$root/shared/claims"
  [ -d "$dir" ] || return 0
  awk '
    FNR==1 { split(FILENAME,p,"/"); agent=p[length(p)]; sub(/\.log$/,"",agent) }
    $1=="CLAIM" { c[$4]=agent"|"$2"|"$3"|"$4"|"$5; next }
    $1=="RELEASE" || $1=="HANDOFF" || $1=="EXPIRED" { closed[$3]=1 }
    END { for (t in c) if (!(t in closed)) print c[t] }
  ' "$dir"/*.log 2>/dev/null
}

# CLAIM ที่หมดอายุ: agent|iso|app|task|objects
expired_claims() {
  local cutoff; cutoff=$(( $(date -u +%s) - TTL_HOURS*3600 ))
  active_claims | while IFS='|' read -r ag iso app task objs; do
    [ "$(to_epoch "$iso")" -lt "$cutoff" ] && echo "$ag|$iso|$app|$task|$objs"
  done
}

# ทับกันไหม (รองรับ prefix wildcard ท้ายด้วย *)
objects_overlap() {
  local a b x y
  IFS=, read -ra A <<< "$1"; IFS=, read -ra B <<< "$2"
  for a in "${A[@]}"; do for b in "${B[@]}"; do
    x="${a%\*}"; y="${b%\*}"
    x="$(echo "$x"|xargs)"; y="$(echo "$y"|xargs)"
    [ -z "$x" ] || [ -z "$y" ] && continue
    case "$x" in "$y"*) return 0;; esac
    case "$y" in "$x"*) return 0;; esac
  done; done
  return 1
}

cur_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null; }
has_remote()  { git remote get-url "$REMOTE" >/dev/null 2>&1; }

# ตรวจ lock ค้าง — สภาพแวดล้อมที่ลบไฟล์ไม่ได้ (เช่น mount บางชนิด) ทำให้ git เขียนไม่ได้ทั้ง repo
check_locks() {
  local root; root="$(git rev-parse --git-dir 2>/dev/null)" || return 0
  local L; L=$(find "$root" \( -name '*.lock' -o -name 'tmp_obj_*' \) 2>/dev/null | head -5)
  [ -z "$L" ] && return 0
  echo "  🔴 พบ lock/temp ค้างใน .git — git จะเขียนไม่ได้เลย:" >&2
  echo "$L" | sed 's/^/     /' >&2
  echo "     ล้างด้วย: find .git \( -name '*.lock' -o -name 'tmp_obj_*' \) -delete" >&2
  echo "     (ถ้าลบไม่ได้ แปลว่าสภาพแวดล้อมนี้ไม่มีสิทธิ์ลบไฟล์ — ต้องแก้ที่สิทธิ์ก่อน)" >&2
  return 1
}

# exit code: 0 ok · 2 lock ค้าง · 3 ไม่มี remote · 4 commit WIP ล้ม · 1 pull ล้ม
sync_repo() {   # มี WIP ค้างก็ไม่ล้ม — commit ก่อนแล้วค่อย rebase
  check_locks || return 2
  git add -A >/dev/null 2>&1
  if ! git diff --cached --quiet; then
    git commit -qm "wip: autosave ก่อน preflight" || { echo "  🔴 commit WIP ล้มเหลว" >&2; return 4; }
  fi
  has_remote || { echo "  (ไม่มี remote '$REMOTE' — การจองใช้ไม่ได้ ดู tools/check-repo.sh)" >&2; return 3; }
  git pull -q --rebase "$REMOTE" "$(cur_branch)" 2>/dev/null || return 1
}

push_or_retry() { git push -q "$REMOTE" "$(cur_branch)" 2>/dev/null; }

# ยืนยันว่าใบจอง "ลงจริง" ไม่ใช่แค่เขียนลงไฟล์ — ตรวจสามชั้น
claim_landed() {   # <agent> <task>
  local ag="$1" tk="$2" f="shared/claims/$1.log"
  git show "HEAD:$f" 2>/dev/null | grep -q "CLAIM .* $tk " || {
    echo "  🔴 CLAIM ไม่ได้อยู่ใน commit (ยังเป็น working tree เท่านั้น)" >&2; return 1; }
  git diff --quiet -- "$f" || { echo "  🔴 $f ยังมีของค้างที่ยังไม่ commit" >&2; return 1; }
  local L R; L=$(git rev-parse HEAD); R=$(git ls-remote "$REMOTE" "$(cur_branch)" 2>/dev/null | cut -f1)
  [ -n "$R" ] && [ "$L" = "$R" ] || {
    echo "  🔴 remote ยังไม่มี commit นี้ (local=$L remote=${R:-ไม่ทราบ}) — อีกฝ่ายมองไม่เห็นใบจอง" >&2; return 1; }
  return 0
}

sync_reason() {   # แปลง exit code ของ sync_repo เป็นสาเหตุที่อ่านรู้เรื่อง
  case "$1" in
    2) echo "มี lock ค้างใน .git — git เขียนไม่ได้" ;;
    3) echo "ไม่มี remote '$REMOTE' ให้ตัดสินการชิงสิทธิ์" ;;
    4) echo "commit งานค้าง (WIP) ไม่สำเร็จ" ;;
    *) echo "pull/rebase ไม่สำเร็จ (เน็ต · สิทธิ์ · หรือ branch ไม่ตรงกับ remote)" ;;
  esac
}
