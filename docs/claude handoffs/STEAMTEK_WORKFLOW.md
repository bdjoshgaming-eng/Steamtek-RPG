# Steamtek Dev Workflow

Paste this at the start of a session (or keep it in the repo and reference it).
It has two lanes. Tell me which lane a request is in, or just phrase it so the
lane is obvious.

---

## Lane A — FIXES (batch these)

Use for: wrong values, label typos, tweaks, small visual nudges, "that's not
quite right" corrections.

**Rule: collect, don't fire one at a time.** As I test, I keep a running list
and send them together.

Format:
```
FIXES against <file>:
1. <what's wrong> -> <what it should be>
2. ...
3. ...
```

Example:
```
FIXES against main.gd:
1. Scavenging awards Combat XP -> should be Crafting XP
2. Mastered diamond glow too subtle -> make it stronger
3. Ability tooltip overlaps the triangle -> nudge it up
```

Why it saves usage: one file read, one edit pass, one ASCII check, one export
for the whole batch instead of per-item.

---

## Lane B — FEATURES (stage these)

Use for: new systems, new professions/keystones, new mechanics, anything that
doesn't exist yet.

Three steps. **I stop and wait for your OK between each** unless you say
"go straight through."

1. **CONCEPT** (prose only, no code)
   - I describe the design: what it does, how it fits existing systems, edge
     cases, what data/state it touches.
   - Cheap to change here. Redirect me now, before any code exists.

2. **VISUAL** (only if it has UI)
   - Layout/mockup description or a quick diagram of the flow.
   - Skip this step for pure-logic features (XP rules, combat math, etc.).

3. **IMPLEMENTATION** (code + file export)
   - I write it once, against the locked concept.

Why it saves usage: we settle direction in cheap prose instead of burning
full implementation passes on a version you didn't want.

---

## Standing rules (always apply)

- **Don't re-upload a file mid-session** unless you edited it on your end.
  Within one conversation I already have it after the first read — re-uploading
  makes me re-read the whole thing.
- **All `.gd` files: ASCII only, tabs, complete drop-in files.** I verify ASCII
  every export. (Em-dashes/smart quotes cause silent parse failures.)
- **New session = fresh upload of any file we'll touch.** Context doesn't carry
  between conversations.
- **Ambiguous fix?** I'll ask ONE batched question with options rather than
  guessing, then proceed.

---

## Quick tags (optional shorthand)

- `FIX:` — single urgent fix, don't wait to batch
- `FIXES:` — batched list (Lane A)
- `FEATURE:` — start Lane B at Concept
- `FEATURE (go through):` — Lane B, all three steps in one pass, no stops
- `Q:` — just a question, no code expected
