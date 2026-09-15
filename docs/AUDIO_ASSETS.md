# EverLeaf Audio Asset Ledger

Runtime audio must come from EverLeaf-owned uploads or assets explicitly distributed for Creator Store use. Keep the source asset ID, creator, role, and replacement status here so soundtrack licensing never becomes guesswork.

## Current Phase 1 region audio

| Region | Role | Asset | Creator | Roblox asset ID | Status |
| --- | --- | --- | --- | ---: | --- |
| Lumenreach | Background music | Morning Breeze Main | APMOfficial | 1848017039 | Creator Store / temporary production track |
| Lumenreach | Forest ambience | Forest Ambience 1 (SFX) | ProSoundEffects | 9112781510 | Creator Store / production ambience |
| Brasshaven | Background music | Grey Shores main | APMOfficial | 9040092810 | Creator Store / temporary production track |
| Brasshaven | Foundry ambience | Construction Presence 1 (SFX) | ProSoundEffects | 9112761348 | Creator Store / temporary production ambience |

## Runtime behavior

- `RegionAudioController` listens to the authoritative profile snapshot and crossfades when `World.RegionId` changes.
- `Settings.MusicVolume` controls regional BGM.
- `Settings.SfxVolume` controls environmental ambience.
- Region audio is client-side presentation only and does not affect gameplay authority.
- Current music can be replaced later with original EverLeaf compositions by changing `RegionAudioProfiles`; no world-service rewrite is required.

## Release policy

Do not paste unverified audio IDs into source. New audio must be EverLeaf-owned or clearly distributed for Creator Store use, and every new runtime ID must be recorded in this ledger.
