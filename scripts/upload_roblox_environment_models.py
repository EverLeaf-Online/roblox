#!/usr/bin/env python3
import argparse
import json
import mimetypes
import os
import time
import uuid
import urllib.error
import urllib.request
from pathlib import Path

CREATE_URL = "https://apis.roblox.com/assets/v1/assets"
OP_URL = "https://apis.roblox.com/assets/v1/operations/{}"


def load_env_file(path: Path):
    if not path.exists():
        return
    for raw in path.read_text().splitlines():
        raw = raw.strip()
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def multipart(payload, file_path: Path):
    boundary = "----EverLeaf" + uuid.uuid4().hex
    ctype = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    if file_path.suffix.lower() == ".glb":
        ctype = "model/gltf-binary"
    chunks = [
        f"--{boundary}\r\n".encode(),
        b'Content-Disposition: form-data; name="request"\r\n\r\n',
        json.dumps(payload).encode(),
        b"\r\n",
        f"--{boundary}\r\n".encode(),
        f'Content-Disposition: form-data; name="fileContent"; filename="{file_path.name}"\r\n'.encode(),
        f"Content-Type: {ctype}\r\n\r\n".encode(),
        file_path.read_bytes(),
        b"\r\n",
        f"--{boundary}--\r\n".encode(),
    ]
    return boundary, b"".join(chunks)


def request_json(url, *, method="GET", headers=None, data=None, timeout=120):
    req = urllib.request.Request(url, method=method, headers=headers or {}, data=data)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        raise RuntimeError(f"Roblox API HTTP {exc.code}: {body[:1200]}") from exc


def upload_model(api_key, creator_user_id, file_path: Path, display_name: str, description: str):
    payload = {
        "assetType": "Model",
        "displayName": display_name[:50],
        "description": description,
        "creationContext": {"creator": {"userId": str(creator_user_id)}},
    }
    boundary, body = multipart(payload, file_path)
    result = request_json(
        CREATE_URL,
        method="POST",
        headers={"x-api-key": api_key, "Content-Type": f"multipart/form-data; boundary={boundary}"},
        data=body,
        timeout=180,
    )
    op_path = result.get("path") or result.get("operationPath")
    if not op_path:
        raise RuntimeError(f"Create Asset response did not contain operation path: {result}")
    op_id = op_path.rsplit("/", 1)[-1]

    deadline = time.time() + 300
    while time.time() < deadline:
        op = request_json(OP_URL.format(op_id), headers={"x-api-key": api_key}, timeout=30)
        if op.get("done"):
            if op.get("error"):
                raise RuntimeError(f"Asset operation failed: {op['error']}")
            response = op.get("response", {})
            asset_id = response.get("assetId")
            if not asset_id:
                raise RuntimeError(f"Completed operation missing assetId: {op}")
            moderation = response.get("moderationResult", {}).get("moderationState", "unknown")
            return int(asset_id), moderation
        time.sleep(2)
    raise TimeoutError(f"Timed out waiting for Roblox asset operation {op_id}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("--display-name", required=True)
    parser.add_argument("--description", default="EverLeaf environment model sourced from Poly Haven (CC0).")
    parser.add_argument("--creator-user-id", required=True)
    parser.add_argument("--env-file", default="/etc/everleaf-roblox.env")
    args = parser.parse_args()

    load_env_file(Path(args.env_file))
    api_key = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("ROBLOX_OPEN_CLOUD_API_KEY is missing")

    file_path = Path(args.file).resolve()
    if not file_path.exists():
        raise SystemExit(f"Missing model: {file_path}")
    if file_path.stat().st_size > 20 * 1024 * 1024:
        raise SystemExit("Model exceeds the 20 MiB Open Cloud asset limit")

    asset_id, moderation = upload_model(
        api_key,
        args.creator_user_id,
        file_path,
        args.display_name,
        args.description,
    )
    print(json.dumps({"assetId": asset_id, "moderation": moderation}, indent=2))


if __name__ == "__main__":
    main()
