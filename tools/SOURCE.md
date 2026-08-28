# tools/ มาจากไหน

สคริปต์ในโฟลเดอร์นี้ **ไม่ได้เขียนที่นี่** — เป็นสำเนาจากสกิล `nocoly-build-docs` commit ไว้เพื่อให้ทุก clone รันได้เหมือนกัน

## ติดตั้ง / อัปเดต

```bash
SKILLDIR=$(dirname "$(find /mnt/skills -name preflight.sh -path '*nocoly-build-docs*' | head -1)")
cp "$SKILLDIR"/*.sh tools/ && chmod +x tools/*.sh
./tools/check-repo.sh          # ต้องได้ "พร้อมใช้"
git add tools && git commit -m "chore: refresh tools from nocoly-build-docs"
```

บันทึกทุกครั้งที่ก็อปมา เพื่อให้รู้ว่าสำเนานี้เก่าแค่ไหน

| วันที่ | สกิลเวอร์ชัน | ผู้ทำ |
|---|---|---|
| _(ยังไม่ติดตั้ง)_ | | |

## สองสคริปต์ที่สับสนกันบ่อย

| | ตรวจอะไร | ใช้ตอนไหน |
|---|---|---|
| `run-tests.sh` | **สคริปต์เอง**ทำงานถูกไหม — สร้าง repo ชั่วคราวของตัวเองมาทดสอบ | หลังก็อปสคริปต์มาใหม่ |
| `check-repo.sh` | **repo นี้**พร้อมใช้ไหม — remote, branch, โฟลเดอร์, git identity | ทุกครั้งก่อนเริ่มงาน |

⚠️ `run-tests.sh` ผ่าน 11/11 ได้แม้ repo นี้ยังไม่มี remote และจองงานไม่ได้เลย — **อย่าใช้แทน `check-repo.sh`**
