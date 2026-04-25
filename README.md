# menace-ci-dependencies

Stripped reference assemblies for building [Jiangyu.Loader](https://github.com/antistrategie/jiangyu) in CI.

Stripping is done via [DeepStrip](https://git.sr.ht/~malicean/DeepStrip) — a .NET tool that
removes method bodies, non-public types/members, and runtime attributes while preserving
every public API signature the compiler needs.

MelonLoader assemblies (`MelonLoader.dll`, `0Harmony.dll`, `Il2CppInterop.Runtime.dll`)
are **not** included here; they are downloaded from
[MelonLoader releases](https://github.com/LavaGang/MelonLoader/releases) during CI.

## Updating

Run `./update.sh` (or `./update.ps1` on Windows) from a machine that has MENACE
installed. The script uses DeepStrip to regenerate every reference assembly from the
live game install.

By default the game is expected at the Steam Linux default path. Set `MENACE_DIR` to
override:

```sh
MENACE_DIR="/mnt/games/Menace" ./update.sh
```
