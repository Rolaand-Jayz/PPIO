#!/usr/bin/env python3
"""Small local-only ComfyUI HTTP client; submits workflow JSON and retrieves outputs."""
import argparse
import json
import os
from pathlib import Path
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = os.environ.get("COMFY_URL", "http://127.0.0.1:8188").rstrip("/")


def request(path, data=None, timeout=10):
    body = None if data is None else json.dumps(data).encode()
    req = urllib.request.Request(BASE + path, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read()

def upload(args):
    image = Path(args.image)
    boundary = "----ComfyUI" + uuid.uuid4().hex
    parts = [
        (b'--' + boundary.encode() + b'\r\nContent-Disposition: form-data; name="image"; filename="' + image.name.encode() + b'"\r\nContent-Type: application/octet-stream\r\n\r\n' + image.read_bytes() + b'\r\n'),
        (b'--' + boundary.encode() + b'\r\nContent-Disposition: form-data; name="type"\r\n\r\ninput\r\n'),
        (b'--' + boundary.encode() + b'\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\nfalse\r\n'),
        (b'--' + boundary.encode() + b'--\r\n')
    ]
    req = urllib.request.Request(BASE + "/upload/image", data=b"".join(parts), headers={"Content-Type": "multipart/form-data; boundary=" + boundary})
    with urllib.request.urlopen(req, timeout=args.timeout) as response:
        result = json.loads(response.read())
    print(json.dumps(result))


def apply_overrides(workflow, overrides):
    for override in overrides:
        path, separator, raw_value = override.partition("=")
        node_id, dot, field = path.partition(".")
        if not separator or not dot or not node_id or not field:
            raise ValueError("input override must be NODE.FIELD=VALUE: " + override)
        node = workflow.get(node_id)
        if not isinstance(node, dict) or field not in node.get("inputs", {}):
            raise ValueError("workflow input not found: " + path)
        try:
            value = json.loads(raw_value)
        except json.JSONDecodeError:
            value = raw_value
        node["inputs"][field] = value



def submit(args):
    workflow = json.loads(Path(args.workflow).read_text())
    apply_overrides(workflow, args.inputs)
    result = json.loads(request("/prompt", {"prompt": workflow, "client_id": str(uuid.uuid4())}, args.timeout))
    prompt_id = result.get("prompt_id")
    if not prompt_id:
        raise RuntimeError("ComfyUI did not return prompt_id: " + json.dumps(result))
    print(prompt_id)


def wait(args):
    deadline = time.monotonic() + args.timeout
    while time.monotonic() < deadline:
        try:
            history = json.loads(request("/history/" + urllib.parse.quote(args.prompt_id), timeout=5))
        except (urllib.error.URLError, TimeoutError):
            time.sleep(2)
            continue
        record = history.get(args.prompt_id)
        if record and record.get("outputs"):
            output_dir = Path(args.output)
            output_dir.mkdir(parents=True, exist_ok=True)
            files = []
            for node in record["outputs"].values():
                for kind in ("images", "gifs", "3d"):
                    for item in node.get(kind, []):
                        query = urllib.parse.urlencode({"filename": item["filename"], "subfolder": item.get("subfolder", ""), "type": item.get("type", "output")})
                        payload = request("/view?" + query, timeout=30)
                        subfolder = Path(item.get("subfolder", ""))
                        target = (output_dir / subfolder / Path(item["filename"]).name).resolve()
                        target.relative_to(output_dir.resolve())
                        target.parent.mkdir(parents=True, exist_ok=True)
                        target.write_bytes(payload)
                        if not payload:
                            raise RuntimeError("empty ComfyUI output: " + str(target))
                        if target.suffix.lower() == ".glb" and payload[:4] != b"glTF":
                            raise RuntimeError("invalid GLB header: " + str(target))
                        files.append(str(target))
            if not files:
                raise RuntimeError("workflow completed without image, gif, or 3D outputs")
            print("\n".join(files))
            return
        time.sleep(2)
    raise TimeoutError("ComfyUI job timed out: " + args.prompt_id)


def cancel(args):
    request("/interrupt", {}, args.timeout)
    print("interrupt requested")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(required=True)
    p = sub.add_parser("submit", help="submit an API-format workflow with optional input overrides")
    p.add_argument("workflow")
    p.add_argument("--set", dest="inputs", action="append", default=[], metavar="NODE.FIELD=VALUE")
    p.add_argument("--timeout", type=float, default=15)
    p.set_defaults(run=submit)
    p = sub.add_parser("upload", help="upload an image to ComfyUI's local input folder")
    p.add_argument("image")
    p.add_argument("--timeout", type=float, default=30)
    p.set_defaults(run=upload)
    p = sub.add_parser("wait", help="poll job and download image, gif, or 3D outputs")
    p.add_argument("prompt_id")
    p.add_argument("--output", default="artifacts/comfy")
    p.add_argument("--timeout", type=float, default=900)
    p.set_defaults(run=wait)
    p = sub.add_parser("cancel", help="interrupt the currently executing ComfyUI job")
    p.add_argument("--timeout", type=float, default=10)
    p.set_defaults(run=cancel)
    args = parser.parse_args()
    try:
        args.run(args)
    except (OSError, ValueError, RuntimeError, TimeoutError, urllib.error.URLError) as exc:
        print(f"comfy: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
