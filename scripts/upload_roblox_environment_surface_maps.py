#!/usr/bin/env python3
"""Upload extracted EverLeaf environment SurfaceAppearance maps to Roblox."""
from __future__ import annotations

import argparse
import json
import mimetypes
import os
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_MANIFEST = ROOT / "assets/polyhaven/surface_maps/manifest.json"
OUTPUT_JSON = ROOT / "assets/roblox/environment_surface_asset_ids.json"
CREATE_URL = "https://apis.roblox.com/assets/v1/assets"
OP_URL = "https://apis.roblox.com/assets/v1/operations/{}"


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw in path.read_text().splitlines():
        raw = raw.strip()
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def request_json(url: str, *, method="GET", headers=None, data=None, timeout=90):
    request = urllib.request.Request(url, method=method, headers=headers or {}, data=data)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        raise RuntimeError(f"Roblox API HTTP {exc.code}: {body[:1200]}") from exc


def multipart(payload: dict, file_path: Path) -> tuple[str, bytes]:
    boundary = "----EverLeaf" + uuid.uuid4().hex
    content_type = mimetypes.guess_type(file_path.name)[0] or "image/png"
    body = b"".join([
        f"--{boundary}\r\n".encode(),
        b'Content-Disposition: form-data; name="request"\r\n\r\n',
        json.dumps(payload).encode(), b"\r\n",
        f"--{boundary}\r\n".encode(),
        f'Content-Disposition: form-data; name="fileContent"; filename="{file_path.name}"\r\n'.encode(),
        f"Content-Type: {content_type}\r\n\r\n".encode(),
        file_path.read_bytes(), b"\r\n",
        f"--{boundary}--\r\n".encode(),
    ])
    return boundary, body


def upload(api_key: str, creator_user_id: int, path: Path, display_name: str) -> int:
    payload = {
        "assetType": "Image",
        "displayName": display_name[:50],
        "description": "EverLeaf environment surface texture sourced from Poly Haven (CC0).",
        "creationContext": {"creator": {"userId": str(creator_user_id)}},
    }
    boundary, body = multipart(payload, path)
    result = request_json(
        CREATE_URL,
        method="POST",
        headers={"x-api-key": api_key, "Content-Type": f"multipart/form-data; boundary={boundary}"},
        data=body,
        timeout=120,
    )
    operation_path = result.get("path") or result.get("operationPath")
    if not operation_path:
        raise RuntimeError(f"Create Asset response missing operation path: {result}")
    operation_id = operation_path.rsplit("/", 1)[-1]
    deadline = time.time() + 240
    while time.time() < deadline:
        operation = request_json(OP_URL.format(operation_id), headers={"x-api-key": api_key}, timeout=30)
        if operation.get("done"):
            if operation.get("error"):
                raise RuntimeError(f"Asset operation failed: {operation['error']}")
            response = operation.get("response", {})
            asset_id = response.get("assetId")
            if not asset_id:
                raise RuntimeError(f"Completed operation missing assetId: {operation}")
            return int(asset_id)
        time.sleep(1.5)
    raise TimeoutError(f"Timed out waiting for Roblox asset operation {operation_id}")



def write_outputs(current: dict) -> None:
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", default="/etc/everleaf-roblox.env")
    parser.add_argument("--creator-user-id", required=True, type=int)
    args = parser.parse_args()
    load_env_file(Path(args.env_file))
    api_key = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("ROBLOX_OPEN_CLOUD_API_KEY is missing")
    manifest = json.loads(SOURCE_MANIFEST.read_text())["assets"]
    current = json.loads(OUTPUT_JSON.read_text()) if OUTPUT_JSON.exists() else {}
    for key, info in sorted(manifest.items()):
        current.setdefault(key, {})
        for map_name in ("Color", "Normal", "Roughness"):
            existing = int(current[key].get(map_name, 0) or 0)
            if existing > 0:
                print(f"SKIP {key} {map_name}: {existing}")
                continue
            path = ROOT / info["maps"][map_name]
            display = f"EverLeaf {key.replace('_', ' ').title()} {map_name}"
            print(f"UPLOAD {display}")
            asset_id = upload(api_key, args.creator_user_id, path, display)
            current[key][map_name] = asset_id
            write_outputs(current)
            print(f"OK {display}: {asset_id}")
    write_outputs(current)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
