#!/usr/bin/env bash
# ชุดทดสอบ: จำลอง agent สองตัวชนกันจริงผ่าน git remote
set -uo pipefail
W=/tmp/proto; rm -rf $W; mkdir -p $W; cd $W
PASS=0; FAIL=0
ok(){ if eval "$2"; then echo "  ✅ $1"; PASS=$((PASS+1)); else echo "  ❌ $1"; FAIL=$((FAIL+1)); fi; }

git init -q --bare origin.git
git clone -q origin.git seed && cd seed
git config user.email s@x; git config user.name seed
mkdir -p shared/claims handoff tools; cp /home/claude/work/proto/tools/*.sh tools/; chmod +x tools/*
echo "# repo" > README.md; git add -A; git commit -qm init; git push -q origin HEAD:master; cd ..

for a in hr ac; do
  git clone -q origin.git $a; (cd $a; git config user.email $a@x; git config user.name agent-$a; git checkout -q -B master origin/master)
done

echo "=== T1: จองปกติ ไม่ชน ==="
(cd hr && ./tools/preflight.sh agent-hr HR/P5-6 deca7391 "hr_payslip*,hr_salary_structure") | sed 's/^/  /'
ok "hr ได้สิทธิ์" '[ "$(cd hr && git log --oneline|grep -c "claim(agent-hr)")" = 1 ]'

echo "=== T2: คนละ object → ผ่านทั้งคู่ ==="
(cd ac && ./tools/preflight.sh agent-ac AC/P8.6 deca7391 "ac_voucher*,ac_gl") | sed 's/^/  /'
ok "ac ได้สิทธิ์ด้วย" 'grep -q "CLAIM.*AC/P8.6" /tmp/proto/ac/shared/claims/agent-ac.log'

echo "=== T3: RACE จริง — ทั้งคู่ pull ก่อน แล้วแย่ง object เดียวกัน ==="
(cd hr && git pull -q --rebase origin master); (cd ac && git pull -q --rebase origin master)
(cd hr && ./tools/preflight.sh agent-hr HR/P9 deca7391 "shared_tbl_x") >/tmp/t3a.txt 2>&1
(cd ac && ./tools/preflight.sh agent-ac AC/P9 deca7391 "shared_tbl_x") >/tmp/t3b.txt 2>&1
echo "  --- hr:"; sed 's/^/    /' /tmp/t3a.txt; echo "  --- ac:"; sed 's/^/    /' /tmp/t3b.txt
ok "hr ได้ (push ก่อน)" 'grep -q "PREFLIGHT OK" /tmp/t3a.txt'
ok "ac ถูกบล็อก ไม่ใช่ conflict" 'grep -q "PREFLIGHT BLOCK" /tmp/t3b.txt'
ok "ac ไม่มีไฟล์ค้างสถานะ conflict" '[ -z "$(cd ac && git status --short)" ]'

echo "=== T4: ปล่อยแล้วจองต่อได้ ==="
(cd hr && ./tools/postflight.sh agent-hr HR/P9 --release) | sed 's/^/  /'
(cd ac && ./tools/preflight.sh agent-ac AC/P9 deca7391 "shared_tbl_x") | sed 's/^/  /'
ok "ac จองต่อได้หลัง RELEASE" 'grep -q "CLAIM.*AC/P9" /tmp/proto/ac/shared/claims/agent-ac.log'

echo "=== T5: HANDOFF ต้องมีไฟล์ + หัวข้อไม่ว่าง ==="
(cd ac && ./tools/postflight.sh agent-ac AC/P9 --handoff) >/tmp/t5.txt 2>&1; sed 's/^/  /' /tmp/t5.txt
ok "บล็อกเมื่อไม่มีไฟล์ handoff" 'grep -q "POSTFLIGHT BLOCK" /tmp/t5.txt'
(cd ac && mkdir -p handoff && printf '# HANDOFF\n## ยิงไปแล้ว\n\n## ทำถึงไหน\nx\n' > handoff/AC-P9.md)
(cd ac && ./tools/postflight.sh agent-ac AC/P9 --handoff) >/tmp/t5b.txt 2>&1; sed 's/^/  /' /tmp/t5b.txt
ok "บล็อกเมื่อหัวข้อ 'ยิงไปแล้ว' ว่าง" 'grep -q "ว่าง" /tmp/t5b.txt'
(cd ac && printf '# HANDOFF\n## ยิงไปแล้ว\n- สร้าง field biz_x ยังไม่ verify\n\n## ทำถึงไหน\nx\n' > handoff/AC-P9.md)
(cd ac && ./tools/postflight.sh agent-ac AC/P9 --handoff) >/tmp/t5c.txt 2>&1; sed 's/^/  /' /tmp/t5c.txt
ok "ผ่านเมื่อกรอกครบ" 'grep -q "POSTFLIGHT OK" /tmp/t5c.txt'

echo "=== T6: TTL ปลด CLAIM ที่ agent ตายทิ้งไว้ ==="
(cd hr && git pull -q --rebase origin master
 echo "CLAIM 2020-01-01T00:00Z deca7391 HR/ZOMBIE dead_tbl" >> shared/claims/agent-hr.log
 git commit -qam zombie; git push -q origin master)
(cd ac && ./tools/preflight.sh agent-ac AC/TAKEOVER deca7391 "dead_tbl") >/tmp/t6.txt 2>&1; sed 's/^/  /' /tmp/t6.txt
ok "ปลด CLAIM ค้างแล้วให้สิทธิ์" 'grep -q "PREFLIGHT WARN" /tmp/t6.txt && grep -q "PREFLIGHT OK" /tmp/t6.txt'

echo "=== T7: มี WIP ค้างแล้ว preflight ไม่ล้ม (M4) ==="
(cd hr && git pull -q --rebase origin master; echo "งานค้าง" >> README.md)
(cd hr && ./tools/preflight.sh agent-hr HR/P10 deca7391 "hr_new_tbl") >/tmp/t7.txt 2>&1; sed 's/^/  /' /tmp/t7.txt
ok "commit WIP ให้แล้วไปต่อได้" 'grep -q "PREFLIGHT OK" /tmp/t7.txt'

echo; echo "ผล: PASS=$PASS FAIL=$FAIL"
