# EverLeaf Roblox

New Roblox game project for EverLeaf, built with Luau and Rojo.

## Development

The canonical source lives in this repository and is mirrored on the EverLeaf VM at:

```text
/opt/roblox/game
```

Build a Roblox place file on the VM:

```bash
./build.sh
```

The generated place is written to:

```text
build/game.rbxlx
```

## Project layout

```text
src/
  client/   LocalScripts and client systems
  server/   ServerScripts and authoritative game systems
  shared/   Shared modules and configuration
```

Roblox Studio remains the visual editor and playtest environment; Rojo keeps Studio synchronized with the source tree.
