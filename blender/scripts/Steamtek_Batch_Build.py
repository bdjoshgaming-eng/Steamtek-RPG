"""Run multiple deterministic Steamtek Blender builders in one Blender process."""

from __future__ import annotations

import argparse
import json
import runpy
import sys
import time
import traceback
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent


def blender_args() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--stop-on-error", action="store_true")
    args = parser.parse_args(blender_args())
    manifest = args.manifest.resolve()
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    builders = payload.get("builders")
    if not isinstance(builders, list):
        raise ValueError("Manifest must contain a 'builders' list.")

    results: list[dict] = []
    enabled = [item for item in builders if item.get("enabled", True)]
    if not enabled:
        raise ValueError("Manifest contains no enabled builders.")
    for position, item in enumerate(enabled, start=1):
        script_name = Path(item["script"]).name
        script_path = SCRIPT_DIR / script_name
        if not script_path.is_file():
            raise FileNotFoundError(f"Builder not found: {script_path}")
        started = time.perf_counter()
        print(f"BATCH [{position}/{len(enabled)}] {script_name}")
        try:
            namespace = runpy.run_path(str(script_path), run_name=f"steamtek_batch_{script_path.stem}")
            builder_main = namespace.get("main")
            if not callable(builder_main):
                raise RuntimeError(f"{script_name} has no callable main()")
            builder_main()
            results.append({
                "script": script_name,
                "status": "PASS",
                "seconds": round(time.perf_counter() - started, 3),
            })
        except Exception as exc:
            results.append({
                "script": script_name,
                "status": "FAIL",
                "seconds": round(time.perf_counter() - started, 3),
                "error": str(exc),
                "traceback": traceback.format_exc(),
            })
            print(f"BATCH FAILED: {script_name}: {exc}")
            if args.stop_on_error:
                break

    report_path = manifest.with_name(manifest.stem + "_blender_report.json")
    report_path.write_text(json.dumps({"schema": 1, "results": results}, indent=2) + "\n")
    failures = sum(item["status"] == "FAIL" for item in results)
    print(f"Batch report: {report_path}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
