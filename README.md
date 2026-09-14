# EverLeaf Roblox

Original Roblox RPG project for EverLeaf, built with Luau and Rojo.

## Development

Canonical source repository: `EverLeaf-Online/roblox`.

The EverLeaf ARM64 build host keeps its working tree at:

```text
/opt/roblox/game
```

Install the pinned Rokit tools and Wally packages:

```bash
rokit install
wally install
```

On Windows, the one-time setup can be run with:

```powershell
.\setup.ps1
```

The production UI stack uses React Lua + ReactRoblox from `wally.toml`.

Run the complete pre-push validation:

```bash
./check.sh
```

The validation gate installs Wally dependencies, runs StyLua formatting checks, Selene linting, service-cycle validation, Lune headless tests, and a Rojo place build.

Build only:

```bash
./build.sh
```

Generated place:

```text
build/game.rbxlx
```

## Project layout

```text
src/
  client/      client controllers and replicated presentation state
  server/      authoritative game systems and server-only content
  shared/      shared configuration and pure gameplay math

tests/         headless Luau tests run with Lune
docs/          canonical design, roadmap, and toolchain notes
```

Roblox Studio remains the visual editor/playtest environment. Rojo keeps Studio synchronized with the canonical source tree while the VM handles repeatable headless validation and builds.

## Project tracking

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Master checklist](docs/MASTER_CHECKLIST.md)
- [Canonical game design](docs/GAME_DESIGN.md)
- [3D art pipeline](docs/ART_PIPELINE_3D.md)
- [Toolchain](docs/TOOLCHAIN.md)
- [Deployment](docs/DEPLOYMENT.md)
