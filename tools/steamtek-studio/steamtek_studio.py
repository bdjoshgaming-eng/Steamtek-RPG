import csv, json, os, re, shutil, sqlite3, subprocess, sys
from collections import Counter, deque
from datetime import datetime
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from PIL import Image, ImageTk

APP = "Steamtek Studio v1.4.0"
HERE = Path(__file__).resolve().parent
# When installed at <Godot project>/tools/steamtek-studio, keep shared project
# data at <Godot project>/.steamtek-studio so the whole project is portable.
DETECTED_PROJECT = HERE.parents[1] if len(HERE.parents) > 1 and (HERE.parents[1] / "project.godot").exists() else None
DATA_DIR = (DETECTED_PROJECT / ".steamtek-studio") if DETECTED_PROJECT else HERE
DATA_DIR.mkdir(parents=True, exist_ok=True)
DB = DATA_DIR / "studio.db"
STATUSES = ["Planned", "Concept", "Source", "QC", "Production", "Approved", "In Game"]
CATEGORIES = ["Prop", "Architecture", "Ground", "Effect", "Character", "Machine", "Furniture", "Other"]

class Studio:
    def __init__(self, root):
        self.root=root; root.title(APP); root.geometry("1180x760"); root.minsize(960,620)
        self.conn=sqlite3.connect(DB); self.conn.row_factory=sqlite3.Row; self.setup_db()
        self.project_root=tk.StringVar(value=self.setting("project_root", str(DETECTED_PROJECT or ""))); self.crop_img=None; self.crop_tk=None; self.crop_start=None; self.crop_rect=None
        self.style(); self.shell()
        # Keep the database synchronized with the portable project on every
        # launch. Existing editorial data is never overwritten by this scan.
        self.scan_project_assets(silent=True)
        self.show_dashboard()

    def setup_db(self):
        c=self.conn.cursor()
        c.executescript("""
        CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY,value TEXT);
        CREATE TABLE IF NOT EXISTS kits(id INTEGER PRIMARY KEY,name TEXT UNIQUE,description TEXT DEFAULT '');
        CREATE TABLE IF NOT EXISTS assets(id TEXT PRIMARY KEY,name TEXT NOT NULL,category TEXT,status TEXT,kit_id INTEGER,source_path TEXT DEFAULT '',production_path TEXT DEFAULT '',scene_path TEXT DEFAULT '',collision_required INTEGER DEFAULT 1,transparency_ok INTEGER DEFAULT 0,art_ok INTEGER DEFAULT 0,ysort_ok INTEGER DEFAULT 0,in_game_tested INTEGER DEFAULT 0,notes TEXT DEFAULT '',updated_at TEXT);
        """)
        if not c.execute("SELECT 1 FROM kits").fetchone():
            c.execute("INSERT INTO kits(name,description) VALUES (?,?)",("Surface Kit 001 — Props","Lantern Ward starter props"))
            kid=c.lastrowid
            rows=[("P001","Street Lamp","In Game"),("P002","Industrial Crate","Source"),("P003","Industrial Barrel","Source"),("P004","Steam Vent","Source"),("P005","Straight Pipe","Source"),("P006","Pipe Valve","Source")]
            for aid,n,s in rows:c.execute("INSERT INTO assets(id,name,category,status,kit_id,updated_at) VALUES (?,?,?,?,?,?)",(aid,n,"Prop",s,kid,self.now()))
        self.conn.commit()

    def style(self):
        s=ttk.Style(); s.theme_use("clam")
        self.bg="#12171d"; self.panel="#1b232c"; self.fg="#e8edf2"; self.accent="#d68a42"; self.muted="#8fa1b3"
        self.root.configure(bg=self.bg)
        # Define every state explicitly. Windows otherwise supplies light native
        # backgrounds while retaining our white foreground, making text vanish.
        s.configure(".",background=self.panel,foreground=self.fg,fieldbackground="#26313c",font=("Segoe UI",11))
        s.configure("TFrame",background=self.bg); s.configure("Panel.TFrame",background=self.panel)
        s.configure("TLabel",background=self.bg,foreground=self.fg); s.configure("Panel.TLabel",background=self.panel,foreground=self.fg)
        s.configure("TEntry",fieldbackground="#26313c",foreground="#ffffff",insertcolor="#ffffff",bordercolor="#738292",padding=5)
        s.configure("TCombobox",fieldbackground="#26313c",background="#26313c",foreground="#ffffff",arrowcolor="#ffffff",padding=4)
        s.map("TCombobox",
              fieldbackground=[("readonly","#26313c"),("disabled","#1c242c")],
              foreground=[("readonly","#ffffff"),("disabled","#9aa8b5")],
              selectbackground=[("readonly","#35536d")],
              selectforeground=[("readonly","#ffffff")])
        s.configure("TCheckbutton",background=self.bg,foreground="#ffffff",font=("Segoe UI",11))
        s.map("TCheckbutton",background=[("active",self.bg)],foreground=[("disabled","#9aa8b5"),("active","#ffffff")])
        s.configure("Panel.TCheckbutton",background=self.panel,foreground="#ffffff",font=("Segoe UI",11))
        s.map("Panel.TCheckbutton",background=[("active",self.panel)],foreground=[("active","#ffffff")])
        s.configure("Title.TLabel",font=("Segoe UI Semibold",22),background=self.bg,foreground=self.fg)
        s.configure("TButton",background="#202a34",foreground="#ffffff",bordercolor="#8795a3",padding=7)
        s.map("TButton",
              background=[("pressed","#36536b"),("active","#2d4152"),("disabled","#1a222a")],
              foreground=[("pressed","#ffffff"),("active","#ffffff"),("disabled","#8694a1")],
              bordercolor=[("active",self.accent),("pressed",self.accent)])
        s.configure("Nav.TButton",background=self.panel,foreground="#ffffff",padding=(14,12),anchor="w",font=("Segoe UI",11))
        s.map("Nav.TButton",
              background=[("pressed","#36536b"),("active","#2d4152")],
              foreground=[("pressed","#ffffff"),("active","#ffffff")],
              bordercolor=[("active",self.accent),("pressed",self.accent)])
        s.configure("Accent.TButton",background=self.accent,foreground="#111111",padding=8,font=("Segoe UI Semibold",10))
        s.map("Accent.TButton",
              background=[("pressed","#c77a31"),("active","#efa85d"),("disabled","#725235")],
              foreground=[("pressed","#111111"),("active","#111111"),("disabled","#d4c2b1")]);
        s.configure("Treeview",rowheight=34,background="#202a34",fieldbackground="#202a34",foreground="#f4f7fa",bordercolor="#6f7f8f",font=("Segoe UI",11))
        s.map("Treeview",background=[("selected","#496f8d")],foreground=[("selected","#ffffff")])
        s.configure("Treeview.Heading",background="#172029",foreground="#ffffff",font=("Segoe UI Semibold",11),padding=6)
        s.map("Treeview.Heading",background=[("active","#263746")],foreground=[("active","#ffffff")])
        self.root.option_add("*TCombobox*Listbox.background", "#26313c")
        self.root.option_add("*TCombobox*Listbox.foreground", "#ffffff")
        self.root.option_add("*TCombobox*Listbox.selectBackground", "#496f8d")
        self.root.option_add("*TCombobox*Listbox.selectForeground", "#ffffff")

    def shell(self):
        self.nav=ttk.Frame(self.root,style="Panel.TFrame",width=190); self.nav.pack(side="left",fill="y"); self.nav.pack_propagate(False)
        ttk.Label(self.nav,text="STEAMTEK\nSTUDIO",style="Panel.TLabel",font=("Segoe UI Semibold",18),foreground=self.accent).pack(padx=18,pady=(24,30),anchor="w")
        for text,fn in [("Dashboard",self.show_dashboard),("Assets",self.show_assets),("Kits",self.show_kits),("Asset Cutter",self.show_cutter),("Modular Intake",self.launch_modular_intake),("Settings",self.show_settings)]: ttk.Button(self.nav,text=text,style="Nav.TButton",command=fn).pack(fill="x",padx=10,pady=3)
        self.body=ttk.Frame(self.root); self.body.pack(side="left",fill="both",expand=True,padx=24,pady=20)

    def launch_modular_intake(self):
        intake = HERE.parent / "modular-intake" / "Steamtek_Modular_Intake.py"
        if not intake.exists():
            return messagebox.showerror(APP, f"Modular Intake was not found:\n{intake}")
        subprocess.Popen([sys.executable, str(intake)], cwd=str(intake.parent))

    def clear(self):
        for w in self.body.winfo_children():w.destroy()

    def title(self,text,sub=""):
        ttk.Label(self.body,text=text,style="Title.TLabel").pack(anchor="w")
        if sub: ttk.Label(self.body,text=sub,foreground=self.muted).pack(anchor="w",pady=(2,18))

    def show_dashboard(self):
        self.clear(); self.title("Dashboard","Steamtek art production at a glance")
        counts={r["status"]:r["n"] for r in self.conn.execute("SELECT status,COUNT(*) n FROM assets GROUP BY status")}; total=sum(counts.values())
        row=ttk.Frame(self.body); row.pack(fill="x")
        for label,val in [("Total Assets",total),("Awaiting QC",counts.get("QC",0)),("Production Ready",counts.get("Approved",0)),("In Godot",counts.get("In Game",0))]:
            f=ttk.Frame(row,style="Panel.TFrame",padding=18); f.pack(side="left",fill="x",expand=True,padx=(0,12)); ttk.Label(f,text=label,style="Panel.TLabel",foreground=self.muted).pack(anchor="w"); ttk.Label(f,text=str(val),style="Panel.TLabel",font=("Segoe UI Semibold",26),foreground=self.accent).pack(anchor="w")
        ttk.Label(self.body,text="Kit Progress",font=("Segoe UI Semibold",15)).pack(anchor="w",pady=(28,10))
        for k in self.conn.execute("SELECT * FROM kits ORDER BY name"):
            t=self.conn.execute("SELECT COUNT(*) FROM assets WHERE kit_id=?",(k["id"],)).fetchone()[0]; done=self.conn.execute("SELECT COUNT(*) FROM assets WHERE kit_id=? AND status IN ('Approved','In Game')",(k["id"],)).fetchone()[0]
            f=ttk.Frame(self.body,style="Panel.TFrame",padding=14); f.pack(fill="x",pady=4); ttk.Label(f,text=k["name"],style="Panel.TLabel").pack(side="left"); ttk.Label(f,text=f"{done}/{t}",style="Panel.TLabel",foreground=self.accent).pack(side="right"); p=ttk.Progressbar(f,value=(done/t*100 if t else 0)); p.pack(side="right",fill="x",expand=True,padx=20)

    def show_assets(self):
        self.clear(); self.title("Assets","Search, review, and promote production assets")
        bar=ttk.Frame(self.body); bar.pack(fill="x",pady=(0,12)); self.search=tk.StringVar(); e=ttk.Entry(bar,textvariable=self.search); e.pack(side="left",fill="x",expand=True); e.bind("<KeyRelease>",lambda _:self.load_assets()); ttk.Button(bar,text="New Asset",style="Accent.TButton",command=lambda:self.asset_dialog()).pack(side="right",padx=(12,0)); ttk.Button(bar,text="Export",command=self.export_data).pack(side="right",padx=6); ttk.Button(bar,text="Scan Project",style="Accent.TButton",command=self.scan_project_assets).pack(side="right",padx=6); ttk.Button(bar,text="Find Missing",command=self.scan_missing_assets).pack(side="right",padx=6); ttk.Button(bar,text="Delete Record",command=self.delete_selected_asset).pack(side="right",padx=6)
        cols=("id","name","category","status","kit","files"); self.tree=ttk.Treeview(self.body,columns=cols,show="headings")
        for c,w in zip(cols,(80,250,120,120,250,90)): self.tree.heading(c,text=c.title()); self.tree.column(c,width=w,anchor="w")
        self.tree.pack(fill="both",expand=True); self.tree.bind("<Double-1>",lambda _:self.edit_selected()); self.load_assets()

    def load_assets(self):
        self.tree.delete(*self.tree.get_children()); q=f"%{self.search.get()}%"
        for r in self.conn.execute("SELECT a.*,k.name kit FROM assets a LEFT JOIN kits k ON k.id=a.kit_id WHERE a.id LIKE ? OR a.name LIKE ? ORDER BY a.id",(q,q)):
            ok=sum(bool(r[x]) for x in ("source_path","production_path","scene_path")); self.tree.insert("", "end", values=(r["id"],r["name"],r["category"],r["status"],r["kit"] or "",f"{ok}/3"))

    def edit_selected(self):
        s=self.tree.selection()
        if s:self.asset_dialog(self.tree.item(s[0],"values")[0])

    def delete_selected_asset(self):
        selected=self.tree.selection()
        if not selected:return messagebox.showinfo(APP,"Select an asset record first.")
        ids=[self.tree.item(item,"values")[0] for item in selected]
        if not messagebox.askyesno(APP,"Delete these database records?\n\n"+", ".join(ids)+"\n\nFiles on disk will not be deleted."):return
        self.conn.executemany("DELETE FROM assets WHERE id=?",[(aid,) for aid in ids]); self.conn.commit(); self.load_assets()

    def resolve_asset_path(self,value):
        if not value:return None
        if value.startswith("res://") and self.project_root.get():return Path(self.project_root.get())/value[6:]
        return Path(value)

    def project_relative(self,path):
        """Return a portable res:// path whenever the file is in the project."""
        root=Path(self.project_root.get()).resolve()
        try:return "res://"+path.resolve().relative_to(root).as_posix()
        except (ValueError,OSError):return str(path)

    def asset_id_from_name(self,name):
        # Strict Modular v1/v2 IDs and legacy IDs remain valid.
        m=re.match(r"^(SMV[12]_[A-Z]{1,3}\d{3}|FX\d{3}|[A-Z]\d{3})(?:_|\b)",name,re.I)
        return m.group(1).upper() if m else None

    def friendly_asset_name(self,filename,asset_id):
        stem=Path(filename).stem
        stem=re.sub(r"^"+re.escape(asset_id)+r"[_ -]*","",stem,flags=re.I)
        stem=re.sub(r"(?:_Source|_Master|_alpha(?:_raw)?|_chroma|_256x128|_Special.*|_Atlas.*|_Preview)$","",stem,flags=re.I)
        stem=stem.replace("_"," ").replace("-"," ")
        stem=re.sub(r"(?<=[a-z0-9])(?=[A-Z])"," ",stem)
        return " ".join(stem.split()).title() or asset_id

    def category_for_asset(self,asset_id,path):
        p=path.as_posix().lower()
        if asset_id.startswith("FX"):return "Effect"
        if asset_id.startswith("P"):return "Prop"
        if asset_id.startswith(("G","SMV1_G","SMV2_G")) or "/ground/" in p:return "Ground"
        if asset_id.startswith(("B","SMV1_","SMV2_")):return "Architecture"
        if "/characters/" in p:return "Character"
        return "Other"

    def preferred_file(self,paths,kind):
        if not paths:return ""
        def score(p):
            n=p.name.lower(); s=0
            if kind=="production" and "/production/" in p.as_posix().lower():s+=100
            if kind=="source" and "/source/" in p.as_posix().lower():s+=100
            if any(x in n for x in ("preview","atlas","special","qc")):s-=30
            if kind=="production" and any(x in n for x in ("source","chroma","raw")):s-=60
            if kind=="source" and "chroma" in n:s+=10
            return (s,-len(str(p)))
        return self.project_relative(max(paths,key=score))

    def scan_project_assets(self,silent=False):
        root=Path(self.project_root.get()).expanduser()
        if not root.exists() or not (root/"project.godot").exists():
            if not silent:messagebox.showerror(APP,"Choose a valid Godot project root in Settings first.")
            return
        found={}
        def bucket(aid):return found.setdefault(aid,{"source":[],"production":[],"scene":[],"sample":None})
        assets_root=root/"assets"
        if assets_root.exists():
            for p in assets_root.rglob("*.png"):
                aid=self.asset_id_from_name(p.name)
                if not aid:continue
                b=bucket(aid); b["sample"]=b["sample"] or p
                parts={x.lower() for x in p.parts}
                if "production" in parts:b["production"].append(p)
                elif "source" in parts:b["source"].append(p)
                else:b["production"].append(p)
        scenes_root=root/"scenes"
        if scenes_root.exists():
            for p in scenes_root.rglob("*.tscn"):
                aid=self.asset_id_from_name(p.name)
                if not aid:continue
                b=bucket(aid); b["scene"].append(p); b["sample"]=b["sample"] or p
        self.conn.execute("INSERT OR IGNORE INTO kits(name,description) VALUES (?,?)",("Modular v1 - Apartment Exterior","Strict snapping apartment exterior modules"))
        self.conn.execute("INSERT OR IGNORE INTO kits(name,description) VALUES (?,?)",("Modular v2 - Apartment Exterior","Production modular apartment, ground, roof, fire-escape, and prop assets"))
        modular_v1_kit=self.conn.execute("SELECT id FROM kits WHERE name=?",("Modular v1 - Apartment Exterior",)).fetchone()[0]
        modular_v2_kit=self.conn.execute("SELECT id FROM kits WHERE name=?",("Modular v2 - Apartment Exterior",)).fetchone()[0]
        def kit_for_asset(aid):
            if aid.startswith("SMV1_"):return modular_v1_kit
            if aid.startswith("SMV2_"):return modular_v2_kit
            return None
        added=updated=0
        for aid,b in sorted(found.items()):
            source=self.preferred_file(b["source"],"source")
            production=self.preferred_file(b["production"],"production")
            scene=self.preferred_file(b["scene"],"scene")
            current=self.conn.execute("SELECT * FROM assets WHERE id=?",(aid,)).fetchone()
            if current:
                changes={}
                for col,value in (("source_path",source),("production_path",production),("scene_path",scene)):
                    if value and current[col]!=value:changes[col]=value
                expected_kit=kit_for_asset(aid)
                if expected_kit and current["kit_id"]!=expected_kit:changes["kit_id"]=expected_kit
                if changes:
                    changes["updated_at"]=self.now(); sql=", ".join(f"{k}=?" for k in changes)
                    self.conn.execute(f"UPDATE assets SET {sql} WHERE id=?",tuple(changes.values())+(aid,)); updated+=1
            else:
                sample=b["sample"]
                name=self.friendly_asset_name(sample.name,aid)
                category=self.category_for_asset(aid,sample)
                status="Production" if production else "Source" if source else "Planned"
                kid=kit_for_asset(aid)
                self.conn.execute("INSERT INTO assets(id,name,category,status,kit_id,source_path,production_path,scene_path,updated_at) VALUES (?,?,?,?,?,?,?,?,?)",(aid,name,category,status,kid,source,production,scene,self.now())); added+=1
        self.conn.commit()
        if hasattr(self,"tree"):self.load_assets()
        if not silent:messagebox.showinfo(APP,f"Project scan complete.\n\nAdded: {added}\nUpdated paths: {updated}\nAssets found: {len(found)}")

    def scan_missing_assets(self):
        stale=[]; partial=[]
        for r in self.conn.execute("SELECT id,name,source_path,production_path,scene_path FROM assets ORDER BY id"):
            values=[r[k] for k in ("source_path","production_path","scene_path") if r[k]]
            if not values:continue
            exists=[self.resolve_asset_path(v).exists() for v in values]
            if not any(exists):stale.append((r["id"],r["name"]))
            elif not all(exists):partial.append((r["id"],r["name"]))
        if not stale and not partial:return messagebox.showinfo(APP,"No missing asset files were found.")
        text=""
        if stale:text+="Records with no referenced files remaining:\n"+"\n".join(f"• {a} — {n}" for a,n in stale)
        if partial:text+=("\n\n" if text else "")+"Records with some missing files (kept):\n"+"\n".join(f"• {a} — {n}" for a,n in partial)
        if stale and messagebox.askyesno(APP,text+"\n\nDelete the fully missing records?\nFiles on disk will not be changed."):
            self.conn.executemany("DELETE FROM assets WHERE id=?",[(a,) for a,_ in stale]); self.conn.commit(); self.load_assets()
        elif not stale:messagebox.showinfo(APP,text)

    def asset_dialog(self,aid=None):
        r=self.conn.execute("SELECT * FROM assets WHERE id=?",(aid,)).fetchone() if aid else None; d=tk.Toplevel(self.root); d.title("Edit Asset" if r else "New Asset"); d.geometry("680x720"); d.configure(bg=self.bg); frm=ttk.Frame(d,padding=20); frm.pack(fill="both",expand=True)
        fields={}
        def add(label,value=""):
            ttk.Label(frm,text=label).pack(anchor="w",pady=(8,2)); v=tk.StringVar(value=value or ""); ttk.Entry(frm,textvariable=v).pack(fill="x"); fields[label]=v
        def add_path(label,value="",kind="image"):
            ttk.Label(frm,text=label).pack(anchor="w",pady=(8,2))
            v=tk.StringVar(value=value or ""); path_row=ttk.Frame(frm); path_row.pack(fill="x")
            ttk.Entry(path_row,textvariable=v).pack(side="left",fill="x",expand=True)
            def browse():
                current=Path(v.get()).expanduser() if v.get().strip() else None
                start=str(current.parent if current and current.parent.exists() else Path(self.project_root.get()) if self.project_root.get() and Path(self.project_root.get()).exists() else Path.home())
                types=[("PNG Images","*.png"),("All Images","*.png *.jpg *.jpeg *.webp"),("All Files","*.*")] if kind=="image" else [("Godot Scenes","*.tscn"),("All Files","*.*")]
                chosen=filedialog.askopenfilename(parent=d,title=f"Select {label}",initialdir=start,filetypes=types)
                if chosen:v.set(chosen)
            ttk.Button(path_row,text="📁 Browse",command=browse,width=12).pack(side="left",padx=(8,0))
            fields[label]=v
        add("Asset ID",r["id"] if r else ""); add("Name",r["name"] if r else "")
        ttk.Label(frm,text="Category").pack(anchor="w",pady=(8,2)); cat=tk.StringVar(value=r["category"] if r else "Prop"); ttk.Combobox(frm,textvariable=cat,values=CATEGORIES,state="readonly").pack(fill="x")
        ttk.Label(frm,text="Status").pack(anchor="w",pady=(8,2)); status=tk.StringVar(value=r["status"] if r else "Planned"); ttk.Combobox(frm,textvariable=status,values=STATUSES,state="readonly").pack(fill="x")
        kits=list(self.conn.execute("SELECT id,name FROM kits ORDER BY name")); ttk.Label(frm,text="Kit").pack(anchor="w",pady=(8,2)); kit=tk.StringVar(value=next((x["name"] for x in kits if r and x["id"]==r["kit_id"]),"")); ttk.Combobox(frm,textvariable=kit,values=[x["name"] for x in kits],state="readonly").pack(fill="x")
        add_path("Source Path",r["source_path"] if r else "","image")
        add_path("Production Path",r["production_path"] if r else "","image")
        add_path("Godot Scene Path",r["scene_path"] if r else "","scene")
        checks={}; cf=ttk.Frame(frm); cf.pack(fill="x",pady=12)
        for label,key in [("Transparency OK","transparency_ok"),("Art Direction OK","art_ok"),("Y-Sort Verified","ysort_ok"),("In-Game Tested","in_game_tested")]: v=tk.BooleanVar(value=bool(r[key]) if r else False); ttk.Checkbutton(cf,text=label,variable=v).pack(anchor="w"); checks[key]=v
        saved = {"done": False}
        def save():
            new_id=fields["Asset ID"].get().strip().upper(); name=fields["Name"].get().strip()
            if not new_id or not name:return messagebox.showerror(APP,"Asset ID and name are required.",parent=d)
            kid=next((x["id"] for x in kits if x["name"]==kit.get()),None); vals=(new_id,name,cat.get(),status.get(),kid,fields["Source Path"].get(),fields["Production Path"].get(),fields["Godot Scene Path"].get(),*[int(checks[x].get()) for x in ("transparency_ok","art_ok","ysort_ok","in_game_tested")],self.now())
            try:
                if r:self.conn.execute("UPDATE assets SET id=?,name=?,category=?,status=?,kit_id=?,source_path=?,production_path=?,scene_path=?,transparency_ok=?,art_ok=?,ysort_ok=?,in_game_tested=?,updated_at=? WHERE id=?",vals+(r["id"],))
                else:self.conn.execute("INSERT INTO assets(id,name,category,status,kit_id,source_path,production_path,scene_path,transparency_ok,art_ok,ysort_ok,in_game_tested,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",vals)
                self.conn.commit(); saved["done"]=True; d.destroy(); self.show_assets()
            except sqlite3.IntegrityError:messagebox.showerror(APP,"That asset ID already exists.",parent=d)
        def close_editor():
            answer=messagebox.askyesnocancel(APP,"Save changes to this asset before closing?",parent=d)
            if answer is None:return
            if answer:save()
            else:d.destroy()
        actions=ttk.Frame(frm); actions.pack(fill="x",pady=12)
        ttk.Button(actions,text="Cancel",command=d.destroy).pack(side="left")
        ttk.Button(actions,text="Save and Close",style="Accent.TButton",command=save).pack(side="right",fill="x",expand=True,padx=(10,0))
        d.protocol("WM_DELETE_WINDOW",close_editor)

    def show_kits(self):
        self.clear(); self.title("Kits","Track complete, playable environment sets")
        top=ttk.Frame(self.body); top.pack(fill="x"); n=tk.StringVar(); ttk.Entry(top,textvariable=n).pack(side="left",fill="x",expand=True); ttk.Button(top,text="Add Kit",style="Accent.TButton",command=lambda:self.add_kit(n.get())).pack(side="left",padx=8)
        self.kit_tree=ttk.Treeview(self.body,columns=("name","assets","approved","progress"),show="headings"); [self.kit_tree.heading(x,text=x.title()) for x in ("name","assets","approved","progress")]; self.kit_tree.pack(fill="both",expand=True,pady=14)
        for k in self.conn.execute("SELECT * FROM kits"):
            t=self.conn.execute("SELECT COUNT(*) FROM assets WHERE kit_id=?",(k["id"],)).fetchone()[0]; a=self.conn.execute("SELECT COUNT(*) FROM assets WHERE kit_id=? AND status IN ('Approved','In Game')",(k["id"],)).fetchone()[0]; self.kit_tree.insert("","end",values=(k["name"],t,a,f"{int(a/t*100) if t else 0}%"))

    def add_kit(self,n):
        if n.strip():
            try:self.conn.execute("INSERT INTO kits(name) VALUES (?)",(n.strip(),)); self.conn.commit(); self.show_kits()
            except sqlite3.IntegrityError:messagebox.showerror(APP,"Kit already exists.")

    def show_cutter(self):
        self.clear(); self.title("Asset Cutter","Queue multiple crops, then batch-export them into the project")
        self.crop_regions=[]; self.crop_selected=None
        bar=ttk.Frame(self.body); bar.pack(fill="x",pady=(0,10))
        ttk.Button(bar,text="Open Source Sheet",command=self.open_sheet).pack(side="left")
        ttk.Button(bar,text="Export All",style="Accent.TButton",command=self.export_all_crops).pack(side="left",padx=8)
        ttk.Button(bar,text="Clean Existing PNG",command=self.clean_existing_png).pack(side="left",padx=(0,8))
        ttk.Button(bar,text="Clear Queue",command=self.clear_crop_queue).pack(side="left")
        self.sheet_label=ttk.Label(bar,text="No sheet loaded",foreground=self.muted); self.sheet_label.pack(side="left",padx=14)
        split=ttk.Panedwindow(self.body,orient="horizontal"); split.pack(fill="both",expand=True)
        left=ttk.Frame(split); right=ttk.Frame(split,style="Panel.TFrame",padding=12); split.add(left,weight=4); split.add(right,weight=2)
        self.canvas=tk.Canvas(left,bg="#0b0e12",highlightthickness=0,cursor="cross"); self.canvas.pack(fill="both",expand=True)
        self.canvas.bind("<ButtonPress-1>",self.crop_down); self.canvas.bind("<B1-Motion>",self.crop_move); self.canvas.bind("<ButtonRelease-1>",self.crop_up)
        ttk.Label(right,text="New Crop",style="Panel.TLabel",font=("Segoe UI Semibold",14)).pack(anchor="w")
        self.cut_id=tk.StringVar(); self.cut_name=tk.StringVar(); self.cut_category=tk.StringVar(value="Prop"); self.cut_padding=tk.IntVar(value=16); self.cut_trim=tk.BooleanVar(value=True); self.cut_remove_checker=tk.BooleanVar(value=True); self.cut_tolerance=tk.IntVar(value=24)
        for label,var in [("Asset ID",self.cut_id),("Asset Name",self.cut_name)]: ttk.Label(right,text=label,style="Panel.TLabel").pack(anchor="w",pady=(10,2)); ttk.Entry(right,textvariable=var).pack(fill="x")
        ttk.Label(right,text="Category",style="Panel.TLabel").pack(anchor="w",pady=(10,2)); ttk.Combobox(right,textvariable=self.cut_category,values=CATEGORIES,state="readonly").pack(fill="x")
        kit_names=[r["name"] for r in self.conn.execute("SELECT name FROM kits ORDER BY name")]; self.cut_kit=tk.StringVar(value=kit_names[0] if kit_names else "")
        ttk.Label(right,text="Kit",style="Panel.TLabel").pack(anchor="w",pady=(10,2)); ttk.Combobox(right,textvariable=self.cut_kit,values=kit_names,state="readonly").pack(fill="x")
        opts=ttk.Frame(right,style="Panel.TFrame"); opts.pack(fill="x",pady=10); ttk.Checkbutton(opts,text="Remove baked checkerboard",variable=self.cut_remove_checker,style="Panel.TCheckbutton").pack(anchor="w"); ttk.Checkbutton(opts,text="Trim transparent edges",variable=self.cut_trim,style="Panel.TCheckbutton").pack(anchor="w")
        tr=ttk.Frame(right,style="Panel.TFrame"); tr.pack(fill="x"); ttk.Label(tr,text="Removal tolerance",style="Panel.TLabel").pack(side="left"); ttk.Spinbox(tr,from_=4,to=80,textvariable=self.cut_tolerance,width=7).pack(side="right")
        pr=ttk.Frame(right,style="Panel.TFrame"); pr.pack(fill="x"); ttk.Label(pr,text="Padding",style="Panel.TLabel").pack(side="left"); ttk.Spinbox(pr,from_=0,to=128,textvariable=self.cut_padding,width=7).pack(side="right")
        ttk.Button(right,text="Add Selection to Queue",style="Accent.TButton",command=self.queue_crop).pack(fill="x",pady=10)
        ttk.Label(right,text="Queued Assets",style="Panel.TLabel",font=("Segoe UI Semibold",13)).pack(anchor="w",pady=(8,4))
        self.crop_tree=ttk.Treeview(right,columns=("id","name"),show="headings",height=9); self.crop_tree.heading("id",text="ID"); self.crop_tree.heading("name",text="Name"); self.crop_tree.column("id",width=70); self.crop_tree.column("name",width=180); self.crop_tree.pack(fill="both",expand=True)
        self.crop_tree.bind("<Double-1>",lambda _:self.remove_queued_crop())
        ttk.Button(right,text="Remove Selected",command=self.remove_queued_crop).pack(fill="x",pady=(8,0))

    def open_sheet(self):
        p=filedialog.askopenfilename(filetypes=[("Images","*.png *.jpg *.jpeg")]);
        if not p:return
        self.crop_path=Path(p); self.crop_img=Image.open(p).convert("RGBA"); self.crop_regions=[]; self.crop_selected=None; self.sheet_label.configure(text=self.crop_path.name); self.render_sheet(); self.refresh_crop_queue()

    def render_sheet(self):
        self.canvas.update(); mw=max(100,self.canvas.winfo_width()-10); mh=max(100,self.canvas.winfo_height()-10); scale=min(mw/self.crop_img.width,mh/self.crop_img.height,1); self.display_scale=scale; im=self.crop_img.resize((int(self.crop_img.width*scale),int(self.crop_img.height*scale)),Image.Resampling.LANCZOS); self.crop_tk=ImageTk.PhotoImage(im); self.canvas.delete("all"); self.canvas.create_image(5,5,image=self.crop_tk,anchor="nw")
        for r in getattr(self,"crop_regions",[]):
            x1,y1,x2,y2=r["box"]; coords=tuple(5+v*scale for v in (x1,y1,x2,y2)); self.canvas.create_rectangle(*coords,outline="#55d6a9",width=3); self.canvas.create_text(coords[0]+5,coords[1]+5,text=r["id"],fill="#ffffff",anchor="nw",font=("Segoe UI Semibold",10))
        self.crop_rect=None

    def crop_down(self,e):
        if not self.crop_img:return
        self.crop_start=(e.x,e.y)
        if self.crop_rect:self.canvas.delete(self.crop_rect)
        self.crop_rect=self.canvas.create_rectangle(e.x,e.y,e.x,e.y,outline=self.accent,width=3)
    def crop_move(self,e):
        if self.crop_start:self.canvas.coords(self.crop_rect,*self.crop_start,e.x,e.y)

    def crop_up(self,e):
        if not self.crop_start:return
        x1,y1,x2,y2=self.canvas.coords(self.crop_rect); self.crop_start=None
        if abs(x2-x1)<8 or abs(y2-y1)<8:self.canvas.delete(self.crop_rect); self.crop_rect=None; self.crop_selected=None; return
        self.crop_selected=tuple(int((v-5)/self.display_scale) for v in (x1,y1,x2,y2))

    def queue_crop(self):
        if not self.crop_img or not self.crop_selected:return messagebox.showinfo(APP,"Open a sheet and drag a rectangle around an asset first.")
        aid=self.cut_id.get().strip().upper(); name=self.cut_name.get().strip()
        if not aid or not name:return messagebox.showerror(APP,"Asset ID and name are required.")
        if any(r["id"]==aid for r in self.crop_regions):return messagebox.showerror(APP,"That ID is already in the crop queue.")
        self.crop_regions.append({"id":aid,"name":name,"category":self.cut_category.get(),"kit":self.cut_kit.get(),"box":self.crop_selected,"padding":self.cut_padding.get(),"trim":self.cut_trim.get(),"remove_checker":self.cut_remove_checker.get(),"tolerance":self.cut_tolerance.get()})
        self.canvas.itemconfigure(self.crop_rect,outline="#55d6a9"); self.crop_rect=None; self.crop_selected=None; self.cut_id.set(""); self.cut_name.set(""); self.refresh_crop_queue()

    def refresh_crop_queue(self):
        if not hasattr(self,"crop_tree"):return
        self.crop_tree.delete(*self.crop_tree.get_children())
        for i,r in enumerate(self.crop_regions):self.crop_tree.insert("","end",iid=str(i),values=(r["id"],r["name"]))

    def remove_queued_crop(self):
        s=self.crop_tree.selection()
        if not s:return
        self.crop_regions.pop(int(s[0])); self.render_sheet(); self.refresh_crop_queue()

    def clear_crop_queue(self):
        self.crop_regions=[]; self.crop_selected=None
        if self.crop_img:self.render_sheet()
        self.refresh_crop_queue()

    def remove_baked_checkerboard(self, image, tolerance=24):
        """Remove a two-color checkerboard connected to the crop border.

        Border-connected removal avoids deleting light gray/white details that
        are enclosed inside the prop. The two dominant border colors are
        detected automatically, so the tool works with white/light-gray and
        other checkerboard palettes.
        """
        im=image.convert("RGBA"); w,h=im.size
        if w<2 or h<2:return im
        px=im.load(); border=[]
        for x in range(w):border.extend((px[x,0][:3],px[x,h-1][:3]))
        for y in range(1,h-1):border.extend((px[0,y][:3],px[w-1,y][:3]))
        # Quantization groups compression/antialias variations around each key.
        quant=[tuple((c//8)*8 for c in rgb) for rgb in border]
        keys=[rgb for rgb,_ in Counter(quant).most_common(2)]
        if not keys:return im
        tol2=int(tolerance)**2
        def matches(rgb):return any(sum((rgb[i]-key[i])**2 for i in range(3))<=tol2 for key in keys)
        # A checkerboard is split into many squares. Border-only flood fill can
        # remove one square while leaving neighboring squares intact because
        # their antialiased seam is not considered connected. Remove both
        # detected key colors globally instead. The low-chroma/lightness guard
        # protects saturated markings and most metal/wood detail.
        for y in range(h):
            for x in range(w):
                r,g,b,a=px[x,y]; chroma=max(r,g,b)-min(r,g,b); light=(r+g+b)/3
                if light>=185 and chroma<=18 and matches((r,g,b)):
                    px[x,y]=(r,g,b,0)
        return im

    def clean_existing_png(self):
        source=filedialog.askopenfilename(title="Select PNG with baked checkerboard",filetypes=[("PNG Images","*.png")])
        if not source:return
        src=Path(source); im=Image.open(src).convert("RGBA"); before=sum(a==0 for a in im.getchannel("A").getdata())
        cleaned=self.remove_baked_checkerboard(im,int(self.cut_tolerance.get()))
        after=sum(a==0 for a in cleaned.getchannel("A").getdata()); removed=max(0,after-before)
        if self.cut_trim.get():
            bbox=cleaned.getchannel("A").getbbox(); cleaned=cleaned.crop(bbox) if bbox else cleaned
        pad=max(0,int(self.cut_padding.get())); result=Image.new("RGBA",(cleaned.width+pad*2,cleaned.height+pad*2),(0,0,0,0)); result.paste(cleaned,(pad,pad),cleaned)
        target=filedialog.asksaveasfilename(title="Save cleaned production PNG",initialdir=str(src.parent),initialfile=src.name,defaultextension=".png",filetypes=[("PNG Images","*.png")])
        if not target:return
        result.save(target)
        if removed==0:messagebox.showwarning(APP,"Saved the PNG, but no checkerboard pixels were detected. Try a higher removal tolerance.")
        else:messagebox.showinfo(APP,f"Cleaned PNG saved.\n\nRemoved {removed:,} opaque background pixels.\n\n{target}")

    def export_all_crops(self):
        if not self.crop_img or not self.crop_regions:return messagebox.showinfo(APP,"Add at least one crop to the queue first.")
        # Export controls are authoritative. This lets the user adjust cleanup
        # after crops have already been queued without deleting/re-queuing them.
        remove_checker_now=bool(self.cut_remove_checker.get()); tolerance_now=int(self.cut_tolerance.get()); trim_now=bool(self.cut_trim.get()); padding_now=max(0,int(self.cut_padding.get()))
        default=Path(self.project_root.get())/"assets"/"surface"/"props" if self.project_root.get() else Path.home()
        out=filedialog.askdirectory(title="Choose asset category output folder",initialdir=str(default if default.exists() else Path.home()))
        if not out:return
        exported=[]
        for r in self.crop_regions:
            x1,y1,x2,y2=r["box"]; box=(max(0,min(x1,x2)),max(0,min(y1,y2)),min(self.crop_img.width,max(x1,x2)),min(self.crop_img.height,max(y1,y2)))
            words=["".join(ch for ch in word.lower() if ch.isalnum()) for word in r["name"].replace("_"," ").split()]
            words=[w for w in words if w]; slug="_".join(words); compact="".join(w.title() for w in words)
            selected=Path(out)
            # Accept either the category folder (props/) or the asset's existing
            # folder (props/industrial_crate/) without duplicating the slug.
            base=selected if selected.name.lower()==slug else selected/slug
            (base/"source").mkdir(parents=True,exist_ok=True); (base/"production").mkdir(exist_ok=True)
            crop=self.crop_img.crop(box); source=base/"source"/f'{r["id"]}_{compact}_Source.png'; crop.save(source)
            prod=self.remove_baked_checkerboard(crop,tolerance_now) if remove_checker_now else crop
            if trim_now:
                bbox=crop.getchannel("A").getbbox(); prod=crop.crop(bbox) if bbox else crop
            # Recalculate trim from the cleaned production image, not source.
            if trim_now:
                bbox=prod.getchannel("A").getbbox(); prod=prod.crop(bbox) if bbox else prod
            pad=padding_now; padded=Image.new("RGBA",(prod.width+pad*2,prod.height+pad*2),(0,0,0,0)); padded.paste(prod,(pad,pad),prod); production=base/"production"/f'{r["id"]}_{compact}.png'; padded.save(production)
            kit=self.conn.execute("SELECT id FROM kits WHERE name=?",(r["kit"],)).fetchone(); kid=kit[0] if kit else None
            exists=self.conn.execute("SELECT 1 FROM assets WHERE id=?",(r["id"],)).fetchone()
            if exists:self.conn.execute("UPDATE assets SET name=?,category=?,status='Production',kit_id=?,source_path=?,production_path=?,updated_at=? WHERE id=?",(r["name"],r["category"],kid,str(source),str(production),self.now(),r["id"]))
            else:self.conn.execute("INSERT INTO assets(id,name,category,status,kit_id,source_path,production_path,updated_at) VALUES (?,?,?,'Production',?,?,?,?)",(r["id"],r["name"],r["category"],kid,str(source),str(production),self.now()))
            exported.append(r["id"])
        self.conn.commit(); messagebox.showinfo(APP,f"Exported {len(exported)} assets:\n"+", ".join(exported))

    def simple_prompt(self,label):
        d=tk.Toplevel(self.root); d.title(APP); d.configure(bg=self.bg); v=tk.StringVar(); ttk.Label(d,text=label).pack(padx=20,pady=(18,5)); e=ttk.Entry(d,textvariable=v,width=40); e.pack(padx=20); e.focus(); done=tk.BooleanVar(); ttk.Button(d,text="OK",command=lambda:done.set(True)).pack(pady=14); d.grab_set(); d.wait_variable(done); val=v.get().strip(); d.destroy(); return val

    def show_settings(self):
        self.clear(); self.title("Settings","Connect Steamtek Studio to your Godot project")
        ttk.Label(self.body,text="Godot Project Root").pack(anchor="w"); row=ttk.Frame(self.body); row.pack(fill="x",pady=6); ttk.Entry(row,textvariable=self.project_root).pack(side="left",fill="x",expand=True); ttk.Button(row,text="Browse",command=lambda:self.project_root.set(filedialog.askdirectory())).pack(side="left",padx=8)
        ttk.Label(self.body,text="Steamtek Art Standard",font=("Segoe UI Semibold",15)).pack(anchor="w",pady=(28,8)); ttk.Label(self.body,wraplength=760,justify="left",text="Hand-painted HD isometric 2D. Modern neo-industrial and neo-punk: concrete, gunmetal, black steel, functional copper pressure systems, rain, steam, and restrained cyan, magenta, acid-green, and amber accents. No Victorian architecture, decorative gears, fantasy steampunk, or 1800s London styling.").pack(anchor="w")
        def save():
            self.set_setting("project_root",self.project_root.get())
            self.scan_project_assets(silent=True)
            messagebox.showinfo(APP,"Settings saved and project assets refreshed.")
        ttk.Button(self.body,text="Save Settings",style="Accent.TButton",command=save).pack(anchor="w",pady=24)

    def export_data(self):
        folder=filedialog.askdirectory(title="Export asset library");
        if not folder:return
        rows=[dict(r) for r in self.conn.execute("SELECT a.*,k.name kit FROM assets a LEFT JOIN kits k ON k.id=a.kit_id ORDER BY a.id")]
        Path(folder,"steamtek_assets.json").write_text(json.dumps(rows,indent=2),encoding="utf-8")
        with open(Path(folder,"steamtek_assets.csv"),"w",newline="",encoding="utf-8-sig") as f:
            w=csv.DictWriter(f,fieldnames=rows[0].keys() if rows else ["id"]); w.writeheader(); w.writerows(rows)
        messagebox.showinfo(APP,"Export complete.")

    def setting(self,k,d=""):
        r=self.conn.execute("SELECT value FROM settings WHERE key=?",(k,)).fetchone(); return r[0] if r else d
    def set_setting(self,k,v):self.conn.execute("INSERT INTO settings(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",(k,v)); self.conn.commit()
    def now(self):return datetime.now().isoformat(timespec="seconds")

if __name__=="__main__":
    root=tk.Tk(); Studio(root); root.mainloop()
