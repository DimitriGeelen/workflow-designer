import sys, os, json, shutil, tempfile
ROOT="/opt/832-Workflow-designer"
sys.path.insert(0, os.path.join(ROOT,"tests"))
import test_t962_findings_on_map as t
from playwright.sync_api import sync_playwright
EV=os.path.join(ROOT,".context/reviews/evidence/T-962")
AG=os.environ["FW_SIDECAR_AGENT_ID"]
tmp=tempfile.mkdtemp(); dr=os.path.join(tmp,"d"); os.makedirs(dr); shutil.copy2(t.SRC, os.path.join(dr,"designer.html"))
proc,port=t.start_server(dr)
INSPECT="""(nid) => { const g=document.querySelector(`g[data-id="${nid}"]`);
 return { finding: [...g.querySelectorAll('[data-finding-badge]')].map(e=>e.getAttribute('data-finding-badge')),
          authority: [...g.querySelectorAll('[data-authority-marker]')].map(e=>e.getAttribute('data-authority-marker')+':'+e.textContent),
          laneHeadersMarked: document.querySelectorAll('#g-pool > .lane-header[data-finding]').length,
          rows: [...document.querySelectorAll('.finding-row')].map(r=>r.getAttribute('data-rule')),
          authDeclared: mapDeclaresAuthority(), showAuthority: labelPrefs.showAuthority,
          lane: n_lane(nid) }; }""".replace("n_lane(nid)","(state.nodes.find(x=>x.id===nid)||{}).lane")
out={}
try:
  with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page(viewport={"width":1600,"height":1000}, device_scale_factor=3)
    def load():
      pg.goto("http://127.0.0.1:%d/designer.html"%port)
      pg.wait_for_function("() => typeof _apiAvailable!=='undefined' && _apiAvailable===true", timeout=15000)
    # Scenario A: the AC's own steps — drag a step below every lane band, Check
    load()
    nid=pg.evaluate("""async () => { const n=state.nodes.find(x=>x.type==='task')||state.nodes[0];
      let bottom=POOL_Y+POOL_HEADER; for (const l of getLanes()) bottom+=l.height;
      n.y=bottom+120; const nl=laneAtY(n.y+NODE_DEFAULTS[n.type].h/2); if (nl) n.lane=nl;
      renderAll(); await runCheck(); return n.id; }""")
    out["A_drag_below_lanes"]=pg.evaluate(INSPECT,nid)
    pg.screenshot(path=os.path.join(EV,"AC1-%s-dragged.png"%AG))
    # Scenario B: node with dangling lane -> E-XML-NODE-UNASSIGNED, the only node-anchored no-lane rule
    load()
    nid=pg.evaluate("""async () => { const n=state.nodes.find(x=>x.type==='task')||state.nodes[0];
      n.lane='lane-that-does-not-exist'; if (n.aef) delete n.aef.authority; renderAll(); await runCheck(); return n.id; }""")
    out["B_unassigned_no_own_authority"]=pg.evaluate(INSPECT,nid)
    g=pg.locator('g[data-id="%s"]'%nid)
    bb=g.bounding_box()
    pg.screenshot(path=os.path.join(EV,"AC1-%s-unassigned.png"%AG), clip={"x":max(bb["x"]-30,0),"y":max(bb["y"]-25,0),"width":bb["width"]+140,"height":bb["height"]+50})
    b.close()
finally:
  proc.terminate()
print(json.dumps(out,indent=1))
