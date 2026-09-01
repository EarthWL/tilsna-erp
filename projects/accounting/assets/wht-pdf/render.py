# -*- coding: utf-8 -*-
import json, base64, pathlib, asyncio, html
BASE = pathlib.Path(__file__).parent
OUT  = BASE / "out"; OUT.mkdir(exist_ok=True)

def b64(p): return base64.b64encode((BASE/"fonts"/p).read_bytes()).decode()
REG, BOLD = b64("Sarabun-Regular.ttf"), b64("Sarabun-Bold.ttf")

TH_MONTH = ["","มกราคม","กุมภาพันธ์","มีนาคม","เมษายน","พฤษภาคม","มิถุนายน",
            "กรกฎาคม","สิงหาคม","กันยายน","ตุลาคม","พฤศจิกายน","ธันวาคม"]

def thai_date(iso):
    y, m, d = (int(x) for x in iso.split("-"))
    return f"{d} {TH_MONTH[m]} {y+543}"

# ---- บาทเป็นตัวอักษร ----
_N = ["ศูนย์","หนึ่ง","สอง","สาม","สี่","ห้า","หก","เจ็ด","แปด","เก้า"]
_U = ["","สิบ","ร้อย","พัน","หมื่น","แสน","ล้าน"]
def _int_text(s):
    s = s.lstrip("0")
    if not s: return ""
    if len(s) > 7:
        return _int_text(s[:-6]) + "ล้าน" + _int_text(s[-6:])
    out, n = "", len(s)
    for i, ch in enumerate(s):
        d, pos = int(ch), n - i - 1
        if d == 0: continue
        if pos == 0 and d == 1 and n > 1: out += "เอ็ด"
        elif pos == 1 and d == 1:         out += "สิบ"
        elif pos == 1 and d == 2:         out += "ยี่สิบ"
        else:                             out += _N[d] + _U[pos]
    return out

def baht_text(amount):
    baht, satang = divmod(int(round(amount * 100)), 100)
    if baht == 0 and satang == 0: return "ศูนย์บาทถ้วน"
    t = (_int_text(str(baht)) + "บาท") if baht else ""
    t += (_int_text(str(satang)) + "สตางค์") if satang else "ถ้วน"
    return t

def money(v): return f"{v:,.2f}"
def boxes(tid):
    tid = (tid or "").ljust(13)[:13]
    return "".join(f'<span class="tb">{html.escape(c) if c.strip() else "&nbsp;"}</span>' for c in tid)
def tick(on): return "☑" if on else "☐"

# ประเภทเงินได้ → บรรทัดในแบบ 50 ทวิ (ท.ป.4/2528 = ข้อ 5)
ROW5 = {"WHT-SERVICE", "WHT-RENT", "WHT-TRANSPORT", "WHT-ADS", "WHT-PRIZE", "WHT-PROF"}

CSS = """
@page { size: A4; margin: 10mm 12mm; }
@font-face { font-family:'Sarabun'; font-weight:400; src:url(data:font/ttf;base64,__REG__) format('truetype'); }
@font-face { font-family:'Sarabun'; font-weight:700; src:url(data:font/ttf;base64,__BOLD__) format('truetype'); }
* { box-sizing:border-box; }
body { font-family:'Sarabun',sans-serif; font-size:13px; color:#000; margin:0; line-height:1.45; }
.hdr { display:flex; justify-content:space-between; align-items:flex-start; }
.hdr .l { font-size:12px; }
.hdr .r { font-size:12px; text-align:right; border:1px solid #000; padding:3px 8px; }
h1 { text-align:center; font-size:16px; margin:2px 0 0; font-weight:700; }
.sub { text-align:center; font-size:12px; margin:0 0 6px; }
.party { border:1px solid #000; padding:5px 7px; margin-bottom:5px; }
.party .cap { font-weight:700; font-size:12px; }
.tb { display:inline-block; width:13px; height:16px; line-height:16px; border:1px solid #666;
      margin-right:1px; text-align:center; font-size:11px; vertical-align:middle; }
.muted { color:#8a8a8a; font-style:italic; }
.row { margin:1px 0; }
.forms { border:1px solid #000; padding:4px 7px; margin-bottom:5px; font-size:12px; }
table { width:100%; border-collapse:collapse; font-size:12px; }
th,td { border:1px solid #000; padding:2px 5px; vertical-align:top; }
th { text-align:center; font-weight:700; background:#f2f2f2; }
td.n { text-align:right; white-space:nowrap; width:100px; }
td.d { text-align:center; white-space:nowrap; width:92px; }
.hl { font-weight:700; }
.tot td { font-weight:700; }
.txt { border:1px solid #000; border-top:0; padding:3px 6px; font-size:12px; }
.cond { border:1px solid #000; border-top:0; padding:4px 6px; font-size:12px; }
.sign { margin-top:10px; display:flex; justify-content:space-between; align-items:flex-end; }
.sign .box { text-align:center; font-size:12px; }
.line { border-bottom:1px dotted #000; width:190px; height:22px; }
.stamp { width:105px; height:70px; border:1px dashed #999; color:#999; font-size:10px;
         display:flex; align-items:center; justify-content:center; text-align:center; }
.foot { margin-top:8px; font-size:10px; color:#666; border-top:1px solid #ccc; padding-top:3px;
        display:flex; justify-content:space-between; }
""".replace("__REG__", REG).replace("__BOLD__", BOLD)

def page(c, payer):
    p = c["payee"]
    r5 = c["income_code"] in ROW5
    rows = [
        ("1.", "เงินเดือน ค่าจ้าง เบี้ยเลี้ยง โบนัส ฯลฯ ตามมาตรา 40 (1)", False),
        ("2.", "ค่าธรรมเนียม ค่านายหน้า ฯลฯ ตามมาตรา 40 (2)", False),
        ("3.", "ค่าแห่งลิขสิทธิ์ ฯลฯ ตามมาตรา 40 (3)", False),
        ("4.", "ดอกเบี้ย เงินปันผล ฯลฯ ตามมาตรา 40 (4)", False),
        ("5.", "การจ่ายเงินได้ที่ต้องหักภาษี ณ ที่จ่าย ตามคำสั่งกรมสรรพากรที่ ท.ป.4/2528 "
               "เช่น รางวัล ส่วนลด ค่าจ้างทำของ ค่าโฆษณา ค่าเช่า ค่าขนส่ง ค่าบริการ ฯลฯ", r5),
        ("6.", "อื่น ๆ (ระบุ)", not r5),
    ]
    tr = []
    for no, label, hit in rows:
        detail = f'<div class="hl">— {html.escape(c["income_th"])}</div>' if hit else ""
        tr.append(
            f'<tr><td>{no} {html.escape(label)}{detail}</td>'
            f'<td class="d">{thai_date(c["pay_date"]) if hit else ""}</td>'
            f'<td class="n">{money(c["base"]) if hit else ""}</td>'
            f'<td class="n">{money(c["wht"]) if hit else ""}</td></tr>')

    forms = ["ภ.ง.ด.1ก", "ภ.ง.ด.1ก พิเศษ", "ภ.ง.ด.2", "ภ.ง.ด.3", "ภ.ง.ด.2ก", "ภ.ง.ด.3ก", "ภ.ง.ด.53"]
    fhtml = "&nbsp;&nbsp;".join(f'{tick(f == c["form"])} {f}' for f in forms)

    payer_tax = boxes(payer["tax_id"]) if payer["tax_id"] else \
                f'<span class="muted">รอเลขประจำตัวผู้เสียภาษีของกิจการ</span>'
    b = c["borne_by"]
    return f"""<!doctype html><html lang="th"><head><meta charset="utf-8">
<style>{CSS}</style></head><body>
<div class="hdr">
  <div class="l">ฉบับที่ 1 (สำหรับผู้ถูกหักภาษี ณ ที่จ่าย ใช้แนบพร้อมกับแบบแสดงรายการภาษี)</div>
  <div class="r">เล่มที่ ..............<br>เลขที่ <b>{html.escape(c["wht_no"])}</b></div>
</div>
<h1>หนังสือรับรองการหักภาษี ณ ที่จ่าย</h1>
<div class="sub">ตามมาตรา 50 ทวิ แห่งประมวลรัษฎากร</div>

<div class="party">
  <div class="cap">ผู้มีหน้าที่หักภาษี ณ ที่จ่าย</div>
  <div class="row">ชื่อ <span class="muted">{html.escape(payer["name"])}</span></div>
  <div class="row">เลขประจำตัวผู้เสียภาษีอากร {payer_tax}</div>
  <div class="row">ที่อยู่ <span class="muted">{html.escape(payer["address"])}</span></div>
</div>

<div class="party">
  <div class="cap">ผู้ถูกหักภาษี ณ ที่จ่าย</div>
  <div class="row">ชื่อ <b>{html.escape(p["name"])}</b> &nbsp; ({html.escape(p["code"])})</div>
  <div class="row">เลขประจำตัวผู้เสียภาษีอากร {boxes(p["tax_id"])}
     &nbsp;&nbsp; {tick(p["branch_type"] == "สำนักงานใหญ่")} สำนักงานใหญ่
     &nbsp; {tick(p["branch_type"] == "สาขา")} สาขาที่ {html.escape(p["branch"] or "..........")}</div>
  <div class="row">ที่อยู่ {html.escape(p["address"])} {html.escape(p["postcode"])}</div>
</div>

<div class="forms">ลำดับที่ .......... ในแบบ &nbsp; {fhtml}</div>

<table>
  <tr><th style="width:auto">ประเภทเงินได้พึงประเมินที่จ่าย</th>
      <th style="width:92px">วัน เดือน<br>ปีภาษีที่จ่าย</th>
      <th style="width:100px">จำนวนเงินที่จ่าย</th>
      <th style="width:100px">ภาษีที่หักและนำส่งไว้</th></tr>
  {"".join(tr)}
  <tr class="tot"><td style="text-align:right">รวมเงินที่จ่ายและภาษีที่หักนำส่ง</td>
      <td class="d"></td><td class="n">{money(c["base"])}</td><td class="n">{money(c["wht"])}</td></tr>
</table>
<div class="txt">รวมเงินภาษีที่หักนำส่ง (ตัวอักษร) &nbsp; <b>({baht_text(c["wht"])})</b></div>
<div class="cond">
  เงินที่จ่ายเข้า &nbsp; ☐ กบข. ........ บาท &nbsp; ☐ กสจ. ........ บาท &nbsp;
  ☐ กองทุนสงเคราะห์ครูโรงเรียนเอกชน ........ บาท &nbsp; ☐ กองทุนประกันสังคม ........ บาท<br>
  ผู้จ่ายเงิน &nbsp;
  {tick(b == "ผู้ถูกหักภาษี")} (1) หัก ณ ที่จ่าย &nbsp;
  {tick(b == "ผู้จ่ายออกให้ตลอดไป")} (2) ออกให้ตลอดไป &nbsp;
  {tick(b == "ผู้จ่ายออกให้ครั้งเดียว")} (3) ออกให้ครั้งเดียว &nbsp;
  ☐ (4) อื่น ๆ
</div>

<div style="margin-top:8px;font-size:12px">
  ขอรับรองว่าข้อความและตัวเลขดังกล่าวข้างต้นถูกต้องตรงกับความจริงทุกประการ
</div>
<div class="sign">
  <div class="stamp">ประทับตรานิติบุคคล<br>(ถ้ามี)</div>
  <div class="box">
    <div class="line"></div>
    ลงชื่อ ผู้จ่ายเงิน<br>
    ออกให้ ณ วันที่ {thai_date(c["pay_date"])}
  </div>
</div>
<div class="foot">
  <span>เอกสารอ้างอิงในระบบ: {html.escape(c["wht_no"])} · เอกสารต้นทาง {html.escape(c["source_id"])} · อัตราหัก {c["rate"]:.0f}%</span>
  <span>TILSNA ERP · สร้างอัตโนมัติ</span>
</div>
</body></html>"""

async def main():
    from playwright.async_api import async_playwright
    d = json.loads((BASE / "data.json").read_text(encoding="utf-8"))
    async with async_playwright() as pw:
        br = await pw.chromium.launch()
        pg = await br.new_page()
        for c in d["certs"]:
            await pg.set_content(page(c, d["payer"]), wait_until="load")
            name = c["wht_no"].replace("/", "-") + ".pdf"
            await pg.pdf(path=str(OUT / name), format="A4", print_background=True)
            print("ok", name)
        await br.close()

asyncio.run(main())
