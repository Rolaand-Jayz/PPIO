#!/usr/bin/env python3
"""Optional, text-only Pulse Alpha delegation through the official OpenCode CLI."""
import argparse
import json
import shutil
import subprocess
import sys
import tempfile

MODEL = "opencode/pulse-alpha-free"
MAX_TASK_CHARS = 2000
MAX_TIMEOUT_SECONDS = 300
MAX_OUTPUT_CHARS = 8000
MAX_STDERR_CHARS = 2000


def parse_events(stdout):
    text = []
    errors = []
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "text":
            part = event.get("part", {})
            if part.get("type") == "text":
                text.append(part.get("text", ""))
        elif event.get("type") == "error":
            error = event.get("error", {})
            errors.append(error.get("message") or json.dumps(error))
    return "".join(text), errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("task", help="bounded text-only task; no files are attached. Review hosted-data terms before including confidential material.")
    parser.add_argument("--timeout", type=int, default=90, help="maximum runtime, 1-300 seconds")
    args = parser.parse_args()
    task = args.task.strip()
    if not task or len(task) > MAX_TASK_CHARS:
        parser.error(f"task must contain 1-{MAX_TASK_CHARS} characters")
    if not 1 <= args.timeout <= MAX_TIMEOUT_SECONDS:
        parser.error(f"timeout must be between 1 and {MAX_TIMEOUT_SECONDS} seconds")
    if not shutil.which("opencode"):
        result = {"ok": False, "model": MODEL, "error": "official opencode executable not found"}
        print(json.dumps(result))
        return 127

    command = ["opencode", "run", "--model", MODEL, "--format", "json", "--agent", "plan", task]
    try:
        with tempfile.TemporaryDirectory(prefix="omp-pulse-task-") as workdir:
            completed = subprocess.run(command, cwd=workdir, capture_output=True, text=True, timeout=args.timeout, check=False)
    except subprocess.TimeoutExpired as exc:
        result = {
            "ok": False,
            "model": MODEL,
            "error": f"OpenCode task timed out after {args.timeout}s",
            "stdout": exc.stdout.decode(errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or ""),
            "stderr": exc.stderr.decode(errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or ""),
        }
        print(json.dumps(result, ensure_ascii=False))
        return 124
    except OSError as exc:
        result = {"ok": False, "model": MODEL, "error": str(exc)}
        print(json.dumps(result, ensure_ascii=False))
        return 1

    output, errors = parse_events(completed.stdout)
    result = {
        "ok": completed.returncode == 0 and not errors,
        "model": MODEL,
        "output": output or completed.stdout.strip(),
    }
    if errors:
        result["error"] = "; ".join(errors)
    if completed.returncode:
        result["exit_code"] = completed.returncode
    if completed.stderr.strip():
        result["stderr"] = completed.stderr.strip()[:MAX_STDERR_CHARS]
    if len(result["output"]) > MAX_OUTPUT_CHARS:
        result["output"] = result["output"][:MAX_OUTPUT_CHARS]
        result["output_truncated"] = True
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["ok"] else (completed.returncode or 1)


if __name__ == "__main__":
    raise SystemExit(main())
