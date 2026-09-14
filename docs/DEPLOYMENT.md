# EverLeaf Roblox — Deployment Architecture

## Environments

The source tree is canonical. Builds must pass `./check.sh` before any publish action.

- **development:** local/Studio/Rojo iteration;
- **staging:** private Roblox place for integrated multiplayer/content testing;
- **production:** public/live place after explicit release approval.

`GameConfig.Places` intentionally contains placeholder `0` IDs until the real Roblox universe/place structure is created. Instance teleports fail closed while the instance place is unconfigured.

## Publishing rules

- VM headless builds may produce `.rbxlx` artifacts but do not auto-publish.
- Never publish a dirty/unvalidated working tree.
- Staging must receive a validated commit before production.
- Production releases should be tagged/versioned and retain a rollback target.
- `ReleaseService.CanPublishAutomatically()` intentionally returns false until a deliberate publishing workflow is approved.

## Version surfaces

`shared/BuildInfo.luau` owns architecture/protocol/content version numbers. Persistent data schema version remains separate under `GameConfig.DataStore.SchemaVersion`.
