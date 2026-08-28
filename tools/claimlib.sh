#!/usr/bin/env bash
# ไลบรารีร่วมของ preflight/postflight — อ่านสถานะการจองจาก shared/claims/*.log
TTL_HOURS="${TTL_HOURS:-8}"

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
has_remote()  { git remote get-url origin >/dev/null 2>&1; }

sync_repo() {   # มี WIP ค้างก็ไม่ล้ม — commit ก่อนแล้วค่อย rebase
  git add -A >/dev/null 2>&1
  git diff --cached --quiet || git commit -qm "wip: autosave ก่อน preflight"
  has_remote || { echo "  (ไม่มี remote 'origin' — การจองใช้ไม่ได้ ดู tools/check-repo.sh)" >&2; return 1; }
  git pull -q --rebase origin "$(cur_branch)" 2>/dev/null || return 1
}

push_or_retry() { git push -q origin "$(cur_branch)" 2>/dev/null; }
