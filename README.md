# EverLeaf Roblox

Original Roblox RPG project for EverLeaf, built with Luau and Rojo.

## Development

Canonical source repository: `EverLeaf-Online/roblox`.

The EverLeaf ARM64 build host keeps its working tree at:

```text
/opt/roblox/game
```

Install the pinned Rokit tools:

```bash
rokit install
```

Run the complete pre-push validation:

```bash
./check.sh
```

The validation gate runs StyLua formatting checks, Selene linting, Lune headless tests, and a Rojo place build.

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
- [Toolchain](docs/TOOLCHAIN.md)
- [Deployment](docs/DEPLOYMENT.md)
