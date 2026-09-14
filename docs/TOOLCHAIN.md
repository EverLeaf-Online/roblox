# Roblox development toolchain

The project uses a reproducible headless workflow on the EverLeaf ARM64 VM and the same source tree can be used from Windows with Roblox Studio.

## Pinned release-backed tools

`rokit.toml` pins:

- Rojo 7.7.0 — filesystem/Studio sync and place builds.
- StyLua 2.5.2 — Luau formatting.
- Lune 0.10.5 — standalone Luau runtime for future tests/tooling.

## ARM64-native source builds

The current upstream Wally and Selene release artifacts do not expose a native Linux ARM64 download, so this VM builds these exact versions from source with Rust rather than using x86 emulation:

- Wally 0.3.2 — package manager.
- Selene 0.31.0 — Luau/Roblox linter.

## Commands

Install the Rokit-managed tools:

```bash
rokit install
```

Run the full pre-push validation:

```bash
./check.sh
```

Build only:

```bash
./build.sh
```

`./check.sh` runs StyLua in check mode, Selene, and a Rojo place build in that order.
