#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# ── Game location ────────────────────────────────────────────────────────────
if (-not (Test-Path env:MENACE_DIR)) {
  $MenaceDir = "$env:ProgramFiles\Steam\steamapps\common\Menace"
} else {
  $MenaceDir = $env:MENACE_DIR
}
$Il2CppDir = "$MenaceDir\MelonLoader\Il2CppAssemblies"

if (-not (Test-Path $Il2CppDir)) {
  Write-Error "Il2CppAssemblies not found at $Il2CppDir"
  Write-Error "Set `$env:MENACE_DIR to your game install path."
  exit 1
}

# ── Assemblies Jiangyu.Loader references ─────────────────────────────────────
# Keep this list synchronised with src/Jiangyu.Loader/Jiangyu.Loader.csproj
# <Reference> entries under $(GameAssembliesDir).
$Assemblies = @(
  "Assembly-CSharp.dll",
  "Il2Cppmscorlib.dll",
  "Il2CppSirenix.Serialization.dll",
  "UnityEngine.CoreModule.dll",
  "UnityEngine.AnimationModule.dll",
  "UnityEngine.AudioModule.dll",
  "UnityEngine.UIModule.dll",
  "UnityEngine.UI.dll",
  "UnityEngine.AssetBundleModule.dll",
  "UnityEngine.PhysicsModule.dll",
  "UnityEngine.UIElementsModule.dll",
  "UnityEngine.JSONSerializeModule.dll"
)

# ── Build DeepStrip ──────────────────────────────────────────────────────────
$DeepStripDir = "$ScriptDir\DeepStrip"
$DeepStripProj = "$DeepStripDir\DeepStrip\DeepStrip.csproj"

if (-not (Test-Path $DeepStripProj)) {
  Write-Host "Cloning DeepStrip..."
  git clone https://git.sr.ht/~malicean/DeepStrip $DeepStripDir
}

Write-Host "Building DeepStrip..."
dotnet build $DeepStripProj -c Release --nologo -v q

$DeepStripDll = "$DeepStripDir\DeepStrip\bin\Release\net8.0\DeepStrip.dll"
if (-not (Test-Path $DeepStripDll)) {
  Write-Error "DeepStrip build output not found at $DeepStripDll"
  exit 1
}

# ── Strip each assembly ──────────────────────────────────────────────────────
Write-Host "Stripping assemblies from $Il2CppDir..."
Write-Host

$Count = 0
foreach ($dll in $Assemblies) {
  $Src = "$Il2CppDir\$dll"
  if (-not (Test-Path $Src)) {
    Write-Warning "$dll not found at $Src — skipping"
    continue
  }

  Write-Host "  $dll"
  dotnet $DeepStripDll `
    $Src `
    "$ScriptDir\$dll" `
    -i $Il2CppDir `
    --verbose
  $Count++
}

Write-Host
Write-Host "Done. Stripped $Count assemblies into $ScriptDir"
