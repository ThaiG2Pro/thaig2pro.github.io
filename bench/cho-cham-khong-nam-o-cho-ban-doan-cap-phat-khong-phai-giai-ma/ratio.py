#!/usr/bin/env python3
"""Per-pair ratios from run.sh output. Prints the post's finding first (oldest vs newest
at depth 60 on each commit), then fix1/before and after/before per benchmark."""
import re, sys, statistics as st
hdr = "".join(open(sys.argv[1]).readlines()[:2])
commits = dict(re.findall(r"(before|fix1|after)=(\w+)", hdr))
data = {k: {} for k in commits}          # side -> bench name -> pair -> ns
alloc = {k: {} for k in commits}         # side -> bench name -> B/op
cur = None
for line in open(sys.argv[1]):
    m = re.match(r"## pair (\d+)\s+commit (\w+)", line)
    if m:
        cur = (int(m[1]), next(k for k, v in commits.items() if v == m[2])); continue
    if line.startswith("## copy"): cur = None
    m = re.match(r"Benchmark(\S+?)-\d+\s+\d+\s+([\d.]+) ns/op\s+(\d+) B/op", line)
    if m and cur:
        data[cur[1]].setdefault(m[1], {})[cur[0]] = float(m[2]); alloc[cur[1]][m[1]] = int(m[3])
    elif m:
        print(f"{m[1]:40s} {float(m[2]):8.1f} ns/op  {m[3]} B/op")
def q(r): r = sorted(r); return f"{st.median(r):.2f} [{r[len(r)//4]:.2f}, {r[(3*len(r))//4]:.2f}]"
print("\n# finding: at depth 60, does the reader that needs the LAST version pay more than the one needing the FIRST?")
for side in ("before", "fix1", "after"):
    nw, od = data[side].get("GetChainDepth/depth=60/newest"), data[side].get("GetChainDepth/depth=60/oldest")
    if nw and od:
        ps = set(nw) & set(od)
        print(f"{side:7s} oldest/newest {q(od[p]/nw[p] for p in ps)}   newest median {st.median(nw.values()):6.0f} ns  "
              f"oldest median {st.median(od.values()):6.0f} ns  B/op {alloc[side]['GetChainDepth/depth=60/newest']}")
print("\n# per benchmark: side/before, median [Q1, Q3] of per-pair ratio")
for name in data["before"]:
    row = f"{name:36s} before {st.median(data['before'][name].values()):6.0f} ns"
    for side in ("fix1", "after"):
        if name in data[side]:
            ps = set(data["before"][name]) & set(data[side][name])
            row += f"   {side} {st.median(data[side][name].values()):6.0f} ns  ratio {q(data[side][name][p]/data['before'][name][p] for p in ps)}"
    print(row)
