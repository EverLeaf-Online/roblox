#!/usr/bin/env python3
import argparse
import json
import mimetypes
import os
import sys
import time
import uuid
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_MANIFEST = ROOT / "assets/polyhaven/manifest.json"
OUTPUT_JSON = ROOT / "assets/roblox/pbr_asset_ids.json"
OUTPUT_LUAU = ROOT / "src/server/Content/GeneratedPBRAssetIds.luau"
CREATE_URL = "https://apis.roblox.com/assets/v1/assets"
OP_URL = "https://apis.roblox.com/assets/v1/operations/{}"

MATERIAL_KEY_MAP = {
    "forest_ground": "ForestGround",
    "mossy_rock": "MossyRock",
    "moss_wood": "MossWood",
    "wood_chip_path": "WoodChipPath",
    "wood_stone_pathway": "WoodStonePathway",
}
MAP_KEY_MAP = {"color": "Color", "normal": "Normal", "roughness": "Roughness"}


def load_env_file(path: Path):
    if not path.exists():
        return
    for raw in path.read_text().splitlines():
        raw = raw.strip()
        if not raw or raw.startswith("#") or "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def creator_context():
    uid = os.environ.get("ROBLOX_CREATOR_USER_ID", "").strip()
    gid = os.environ.get("ROBLOX_CREATOR_GROUP_ID", "").strip()
    if bool(uid) == bool(gid):
        raise SystemExit("Set exactly one of ROBLOX_CREATOR_USER_ID or ROBLOX_CREATOR_GROUP_ID")
    if uid:
        return {"userId": uid}
    return {"groupId": gid}


def multipart(fields, file_field, file_path: Path, content_type: str):
    boundary = "----EverLeaf" + uuid.uuid4().hex
    chunks = []
    for name, value in fields.items():
        chunks.extend([
            f"--{boundary}\r\n".encode(),
            f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode(),
            value.encode(), b"\r\n",
        ])
    chunks.extend([
        f"--{boundary}\r\n".encode(),
        f'Content-Disposition: form-data; name="{file_field}"; filename="{file_path.name}"\r\n'.encode(),
        f"Content-Type: {content_type}\r\n\r\n".encode(),
        file_path.read_bytes(), b"\r\n",
        f"--{boundary}--\r\n".encode(),
    ])
    return boundary, b"".join(chunks)


def request_json(url, *, method="GET", headers=None, data=None, timeout=60):
    req = urllib.request.Request(url, method=method, headers=headers or {}, data=data)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, json.load(resp)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        raise RuntimeError(f"Roblox API HTTP {exc.code}: {body[:1000]}") from exc


def upload_image(api_key, creator, path: Path, display_name: str):
    payload = {
        "assetType": "Image",
        "displayName": display_name[:50],
        "description": "EverLeaf PBR environment texture sourced from Poly Haven (CC0).",
        "creationContext": {"creator": creator},
    }
    ctype = mimetypes.guess_type(path.name)[0] or "image/jpeg"
    boundary, body = multipart({"request": json.dumps(payload)}, "fileContent", path, ctype)
    _, result = request_json(
        CREATE_URL,
        method="POST",
        headers={"x-api-key": api_key, "Content-Type": f"multipart/form-data; boundary={boundary}"},
        data=body,
        timeout=90,
    )
    op_path = result.get("path") or result.get("operationPath")
    if not op_path:
        raise RuntimeError(f"Create Asset response did not contain operation path: {result}")
    op_id = op_path.rsplit("/", 1)[-1]
    return op_id


def poll_operation(api_key, op_id, timeout=180):
    deadline = time.time() + timeout
    while time.time() < deadline:
        _, op = request_json(OP_URL.format(op_id), headers={"x-api-key": api_key}, timeout=30)
        if op.get("done"):
            if op.get("error"):
                raise RuntimeError(f"Asset operation failed: {op['error']}")
            response = op.get("response", {})
            asset_id = response.get("assetId")
            if asset_id:
                return int(asset_id), response
            raise RuntimeError(f"Completed operation missing assetId: {op}")
        time.sleep(2)
    raise TimeoutError(f"Timed out waiting for Roblox asset operation {op_id}")


def load_source_entries():
    data = json.loads(SOURCE_MANIFEST.read_text())
    entries = []
    # manifest shape is intentionally handled flexibly.
    materials = data.get("materials", data)
    if isinstance(materials, dict):
        iterable = materials.items()
    else:
        iterable = [(m.get("key") or m.get("name"), m) for m in materials]
    for src_key, info in iterable:
        if src_key not in MATERIAL_KEY_MAP:
            continue
        files = info.get("files", info.get("maps", {}))
        for map_key in ("color", "normal", "roughness"):
            value = files.get(map_key) or files.get(MAP_KEY_MAP[map_key])
            if isinstance(value, dict):
                value = value.get("path") or value.get("file")
            if not value:
                candidate = ROOT / "assets/polyhaven" / src_key / f"{src_key}_{map_key}_1k.jpg"
            else:
                candidate = ROOT / value if not str(value).startswith("/") else Path(value)
            if candidate.exists():
                entries.append((src_key, map_key, candidate))
    return entries


def write_outputs(ids):
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(json.dumps(ids, indent=2, sort_keys=True) + "\n")
    lines = ["-- Generated by scripts/upload_roblox_pbr_assets.py. Do not hand-edit.", "return table.freeze({"]
    for mat in sorted(ids):
        maps = ids[mat]
        lines.append(f"    {mat} = table.freeze({{")
        for key in ("Color", "Normal", "Roughness"):
            lines.append(f"        {key} = {int(maps.get(key, 0))},")
        lines.append("    }),")
    lines.append("})")
    OUTPUT_LUAU.write_text("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", default="/etc/everleaf-roblox.env")
    parser.add_argument("--test", action="store_true", help="Upload only the first texture")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--ui-icons", action="store_true", help="Upload original EverLeaf UI icon PNGs")
    args = parser.parse_args()
    load_env_file(Path(args.env_file))
    api_key = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("ROBLOX_OPEN_CLOUD_API_KEY is missing")
    creator = creator_context()
    if args.ui_icons:
        icon_dir = ROOT / "assets/ui/icons"
        out_json = ROOT / "assets/roblox/ui_icon_asset_ids.json"
        out_luau = ROOT / "src/client/UI/EverLeafIcons.luau"
        current = {}
        if out_json.exists():
            try:
                current = json.loads(out_json.read_text())
            except Exception:
                current = {}
        for path in sorted(icon_dir.glob("*.png")):
            name = path.stem
            if int(current.get(name, 0) or 0) > 0:
                print(f"SKIP {name}: asset {current[name]}")
                continue
            display = f"EverLeaf UI {name.replace('_', ' ').title()}"
            print(f"UPLOAD {display}: {path.relative_to(ROOT)}")
            op_id = upload_image(api_key, creator, path, display)
            asset_id, response = poll_operation(api_key, op_id)
            state = response.get("moderationResult", {}).get("moderationState", "unknown")
            print(f"OK {display}: asset {asset_id} moderation={state}")
            current[name] = asset_id
            out_json.parent.mkdir(parents=True, exist_ok=True)
            out_json.write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")
        lines = ["-- Generated from original EverLeaf UI artwork.", "return table.freeze({"]
        for name, asset_id in sorted(current.items()):
            key_name = "".join(part[:1].upper() + part[1:] for part in name.split("_"))
            lines.append(f'    {key_name} = "rbxassetid://{int(asset_id)}",')
        lines.append("})")
        out_luau.write_text("\n".join(lines) + "\n")
        return
    entries = load_source_entries()
    if not entries:
        raise SystemExit("No Poly Haven source textures found")
    if args.test:
        entries = entries[:1]
    current = {}
    if OUTPUT_JSON.exists():
        try:
            current = json.loads(OUTPUT_JSON.read_text())
        except Exception:
            current = {}
    for src_key, map_key, path in entries:
        mat = MATERIAL_KEY_MAP[src_key]
        roblox_map = MAP_KEY_MAP[map_key]
        display = f"EverLeaf {mat} {roblox_map}"
        if args.dry_run:
            print(f"DRY RUN {display}: {path.relative_to(ROOT)}")
            continue
        existing = int(current.get(mat, {}).get(roblox_map, 0) or 0)
        if existing > 0:
            print(f"SKIP {display}: asset {existing}")
            continue
        print(f"UPLOAD {display}: {path.relative_to(ROOT)}")
        op_id = upload_image(api_key, creator, path, display)
        asset_id, response = poll_operation(api_key, op_id)
        state = response.get("moderationResult", {}).get("moderationState", "unknown")
        print(f"OK {display}: asset {asset_id} moderation={state}")
        current.setdefault(mat, {})[roblox_map] = asset_id
        write_outputs(current)
    if not args.dry_run:
        write_outputs(current)


if __name__ == "__main__":
    main()
