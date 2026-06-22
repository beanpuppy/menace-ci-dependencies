#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Game location ────────────────────────────────────────────────────────────
MENACE_DIR="${MENACE_DIR:-$HOME/.local/share/Steam/steamapps/common/Menace}"
IL2CPP_DIR="$MENACE_DIR/MelonLoader/Il2CppAssemblies"

if [ ! -d "$IL2CPP_DIR" ]; then
  echo "ERROR: Il2CppAssemblies not found at $IL2CPP_DIR" >&2
  echo "Set MENACE_DIR to your game install path." >&2
  exit 1
fi

# ── Assemblies Jiangyu.Loader references ─────────────────────────────────────
# Keep this list synchronised with the <Reference> entries under
# $(GameAssembliesDir) across the projects CI builds against the game:
# src/Jiangyu.Loader/Jiangyu.Loader.csproj and
# src/Jiangyu.Sdk.Menace/Jiangyu.Sdk.Menace.csproj (the loader merges it in).
ASSEMBLIES=(
  Assembly-CSharp.dll
  Assembly-CSharp-firstpass.dll
  Il2Cppmscorlib.dll
  Il2CppSirenix.Serialization.dll
  UnityEngine.CoreModule.dll
  UnityEngine.InputLegacyModule.dll
  UnityEngine.AnimationModule.dll
  UnityEngine.AudioModule.dll
  UnityEngine.UIModule.dll
  UnityEngine.UI.dll
  UnityEngine.AssetBundleModule.dll
  UnityEngine.PhysicsModule.dll
  UnityEngine.UIElementsModule.dll
  UnityEngine.TextRenderingModule.dll
  UnityEngine.JSONSerializeModule.dll
)

# ── Build DeepStrip ──────────────────────────────────────────────────────────
DEEPSTRIP_DIR="$SCRIPT_DIR/DeepStrip"
DEEPSTRIP_PROJ="$DEEPSTRIP_DIR/DeepStrip/DeepStrip.csproj"

if [ ! -f "$DEEPSTRIP_PROJ" ]; then
  echo "Cloning DeepStrip..."
  git clone https://git.sr.ht/~malicean/DeepStrip "$DEEPSTRIP_DIR"
fi

echo "Building DeepStrip..."
dotnet build "$DEEPSTRIP_PROJ" -c Release --nologo -v q

DEEPSTRIP_DLL="$DEEPSTRIP_DIR/DeepStrip/bin/Release/net8.0/DeepStrip.dll"
if [ ! -f "$DEEPSTRIP_DLL" ]; then
  echo "ERROR: DeepStrip build output not found at $DEEPSTRIP_DLL" >&2
  exit 1
fi

# ── Strip each assembly ──────────────────────────────────────────────────────
echo "Stripping assemblies from $IL2CPP_DIR..."
echo

COUNT=0
for dll in "${ASSEMBLIES[@]}"; do
  SRC="$IL2CPP_DIR/$dll"
  if [ ! -f "$SRC" ]; then
    echo "WARNING: $dll not found at $SRC — skipping" >&2
    continue
  fi

  echo "  $dll"
  dotnet "$DEEPSTRIP_DLL" \
    "$SRC" \
    "$SCRIPT_DIR/$dll" \
    -i "$IL2CPP_DIR" \
    --verbose
  COUNT=$((COUNT + 1))
done

echo
echo "Done. Stripped $COUNT assemblies into $SCRIPT_DIR"
