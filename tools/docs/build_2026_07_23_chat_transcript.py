"""Build the verified July 23 Steamtek visible-chat transcript.

The transcript is extracted only from visible user_message and agent_message
events in the primary local Codex rollout. Internal reasoning, instructions,
tool traffic, and command output are intentionally excluded.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path


SOURCE = Path(
    r"C:\Users\bdjos\.codex\sessions\2026\07\22"
    r"\rollout-2026-07-22T22-20-32-019f8cfd-1d79-7353-a1b7-e0fb77b507ce.jsonl"
)
DESTINATION = Path(
    r"C:\My Game\Steamtek-RPG\docs\ChatGPT handoffs"
    r"\2026-07-23_STEAMTEK_CHAT_TRANSCRIPT_VERBATIM.txt"
)
CHECKSUM = DESTINATION.with_suffix(".sha256.txt")

# Beginning of the current primary task. This includes the late-evening July 22
# portion so "full chat" means the entire visible task, not an arbitrary
# midnight truncation.
CUTOFF_UTC = datetime(2026, 7, 23, 3, 20, 0, tzinfo=timezone.utc)
CDT = timezone(timedelta(hours=-5), name="CDT")
BEGIN_MARKER = "===== BEGIN VERBATIM VISIBLE TRANSCRIPT ====="
END_MARKER = "===== END VERBATIM VISIBLE TRANSCRIPT ====="


def parse_utc(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def extract_entries() -> list[tuple[datetime, str, str, str | None]]:
    entries: list[tuple[datetime, str, str, str | None]] = []
    with SOURCE.open("r", encoding="utf-8") as source:
        for raw_line in source:
            record = json.loads(raw_line)
            if record.get("type") != "event_msg":
                continue
            payload = record.get("payload")
            if not isinstance(payload, dict):
                continue
            event_type = payload.get("type")
            if event_type not in {"user_message", "agent_message"}:
                continue
            timestamp = parse_utc(record["timestamp"])
            if timestamp < CUTOFF_UTC:
                continue
            role = "USER" if event_type == "user_message" else "ASSISTANT"
            message = payload.get("message")
            if not isinstance(message, str):
                continue
            entries.append((timestamp, role, message, payload.get("phase")))
    return entries


def build_body(entries: list[tuple[datetime, str, str, str | None]]) -> str:
    blocks: list[str] = []
    for index, (timestamp, role, message, phase) in enumerate(entries, 1):
        local_time = timestamp.astimezone(CDT).strftime("%Y-%m-%d %I:%M:%S %p CDT")
        phase_suffix = ""
        if role == "ASSISTANT" and phase in {"commentary", "final_answer"}:
            phase_suffix = f" — {phase.upper()}"
        blocks.append(
            f"[{index:03d}] {role}{phase_suffix}\n"
            f"Timestamp: {local_time}\n\n"
            f"{message}"
        )
    return "\n\n".join(blocks) + "\n"


def embedded_body(document: str) -> str:
    marker = BEGIN_MARKER + "\n"
    start = document.index(marker) + len(marker)
    end = document.index(END_MARKER)
    return document[start:end]


def main() -> None:
    entries = extract_entries()
    if not entries:
        raise RuntimeError("No visible July 23 chat entries were found.")

    body = build_body(entries)
    body_bytes = body.encode("utf-8")
    body_hash = digest(body_bytes)
    capture = entries[-1][0].astimezone(CDT).strftime("%Y-%m-%d %I:%M:%S %p CDT")

    header = (
        "STEAMTEK CHARACTER-ASSET CHAT — VERBATIM VISIBLE TRANSCRIPT\n"
        "Date span: 2026-07-22 through 2026-07-23 (America/Chicago / CDT)\n"
        "Thread ID: 019f8cfd-1d79-7353-a1b7-e0fb77b507ce\n"
        f"Source: {SOURCE}\n"
        f"Capture through: {capture}\n"
        f"Visible entries: {len(entries)}\n"
        f"Extracted transcript characters: {len(body)}\n"
        f"Extracted transcript UTF-8 bytes: {len(body_bytes)}\n"
        f"Source extraction SHA-256: {body_hash}\n"
        "\n"
        "FIDELITY NOTE\n"
        "\n"
        "This file preserves the exact visible text of every user message and "
        "assistant commentary/final message recorded in the primary Codex task "
        "from its July 22, 2026 start through the capture time above. "
        "Original spelling, capitalization, punctuation, Markdown, attachment "
        "paths, and visible image references are preserved.\n"
        "\n"
        "Internal reasoning, system/developer instructions, environment "
        "injections, tool-call payloads, command output, approval-review "
        "traffic, and binary/base64 image data are excluded because they are "
        "not visible conversation messages. The completion response sent after "
        "this file was written is necessarily outside this frozen capture.\n"
        "\n"
    )
    verification = (
        "\nVERIFICATION\n"
        "\n"
        f"Destination embedded transcript characters: {len(body)}\n"
        f"Destination embedded transcript UTF-8 bytes: {len(body_bytes)}\n"
        f"Destination embedded transcript SHA-256: {body_hash}\n"
        "Source/destination embedded-body match: YES\n"
    )
    document = (
        header
        + BEGIN_MARKER
        + "\n"
        + body
        + END_MARKER
        + "\n"
        + verification
    )

    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    DESTINATION.write_text(document, encoding="utf-8", newline="\n")

    written = DESTINATION.read_bytes().decode("utf-8")
    written_body = embedded_body(written)
    if written_body != body:
        raise RuntimeError("Destination transcript body differs from extraction.")
    if digest(written_body.encode("utf-8")) != body_hash:
        raise RuntimeError("Destination transcript body hash verification failed.")

    full_bytes = DESTINATION.read_bytes()
    full_hash = digest(full_bytes)
    checksum_text = (
        f"{full_hash}  {DESTINATION.name}\n"
        f"source_session={SOURCE}\n"
        f"embedded_body_sha256={body_hash}\n"
        f"visible_entries={len(entries)}\n"
        f"capture_through={capture}\n"
    )
    CHECKSUM.write_text(checksum_text, encoding="utf-8", newline="\n")

    print(f"destination={DESTINATION}")
    print(f"checksum={CHECKSUM}")
    print(f"entries={len(entries)}")
    print(f"capture={capture}")
    print(f"body_characters={len(body)}")
    print(f"body_bytes={len(body_bytes)}")
    print(f"body_sha256={body_hash}")
    print(f"file_sha256={full_hash}")
    print("verified=true")


if __name__ == "__main__":
    main()
