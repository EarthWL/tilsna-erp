import json, subprocess, pathlib, datetime, sys
BASE = pathlib.Path(".")
APP = "deca7391-1761-424b-9af3-c8d043004ad3"
WS  = "6a8677f1055f2288c5b77d1d"
FLD_PDF = "6a975297866e70ecc2e32e75"
FLD_PRINTED = "6a8677f1055f2288c5b77d33"
NOW = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

certs = json.loads(BASE.joinpath("data.json").read_text(encoding="utf-8"))["certs"]
log = []
for c in certs:
    f = BASE / "out" / (c["wht_no"].replace("/", "-") + ".pdf")
    up = subprocess.run(["hap","--json","upload","--app-id",APP,"--worksheet-id",WS,str(f)],
                        capture_output=True, text=True)
    if up.returncode != 0:
        print("UPLOAD FAIL", c["wht_no"], up.stderr[:200]); sys.exit(1)
    url = json.loads(up.stdout)[0]["url"]
    payload = json.dumps([
        {"id": FLD_PDF, "value": [{"name": f.name, "url": url}]},
        {"id": FLD_PRINTED, "value": NOW},
    ], ensure_ascii=False)
    r = subprocess.run(["hap","--json","worksheet","record","update", WS, c["rowid"],
                        "--fields-json", payload],
                       capture_output=True, text=True)
    ok = r.returncode == 0
    print(("OK  " if ok else "FAIL"), c["wht_no"], (r.stdout or r.stderr).strip()[:120])
    log.append((c["wht_no"], ok))
print("---", sum(1 for _,o in log if o), "/", len(log), "updated")
