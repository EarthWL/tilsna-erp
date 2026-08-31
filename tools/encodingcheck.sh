#!/usr/bin/env bash
# encodingcheck.sh — จับไฟล์ .md ที่มีอักขระเสีย (U+FFFD) หรือไม่ใช่ UTF-8
# ที่มา: 31 ส.ค. 2569 — การเขียนไฟล์รอบหนึ่งทำให้คำว่า "จนกว่า" กลายเป็น "จน��ว่า"
# ผลคือ str.replace ของสคริปต์รอบถัดไปหา target ไม่เจอ แล้ว "แก้ไม่ติดแบบเงียบ ๆ"
# จนไกด์ขัดกันเองและ handoff มีข้อความเท็จส่งออกไปแล้ว
run_encodingcheck() {
  local pfx="${1:-}"
  python3 - "$pfx" <<'PY'
import sys,glob
pfx=sys.argv[1] if len(sys.argv)>1 else ""
bad=0
for p in sorted(set(glob.glob('projects/*/*.md')+glob.glob('shared/*.md')+glob.glob('handoff/*.md')+glob.glob('*.md'))):
    raw=open(p,'rb').read()
    try:
        s=raw.decode('utf-8')
    except UnicodeDecodeError as e:
        print(f"{pfx}🔴 {p} — ไม่ใช่ UTF-8 ที่ถูกต้อง ({e})"); bad+=1; continue
    n=s.count('�')
    if n:
        i=s.index('�')
        print(f"{pfx}🔴 {p} — มีอักขระเสีย {n} ตัว รอบ ๆ: …{s[max(0,i-30):i+30]}…"); bad+=1
if bad:
    print(f"{pfx}── {bad} ไฟล์มีปัญหา encoding — แก้ก่อน เพราะสคริปต์ค้นหา/แทนที่จะหา target ไม่เจอแบบเงียบ ๆ")
PY
  return 0
}
if [ "${BASH_SOURCE[0]}" = "$0" ]; then cd "$(git rev-parse --show-toplevel)" && run_encodingcheck ""; fi
