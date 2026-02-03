param(
  [string]$Abi = "x86_64",
  [string]$Api = "28"
)

$ErrorActionPreference = "Stop"

function Resolve-NdkPath {
  if ($env:ANDROID_NDK) { return $env:ANDROID_NDK }
  if ($env:ANDROID_NDK_HOME) { return $env:ANDROID_NDK_HOME }
  if ($env:ANDROID_HOME) {
    $ndkRoot = Join-Path $env:ANDROID_HOME "ndk"
    if (Test-Path $ndkRoot) {
      $ndks = Get-ChildItem -Path $ndkRoot -Directory | Sort-Object Name -Descending
      if ($ndks.Count -gt 0) { return $ndks[0].FullName }
    }
  }
  $localSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
  if (Test-Path $localSdk) {
    $env:ANDROID_HOME = $localSdk
    $ndkRoot = Join-Path $localSdk "ndk"
    if (Test-Path $ndkRoot) {
      $ndks = Get-ChildItem -Path $ndkRoot -Directory | Sort-Object Name -Descending
      if ($ndks.Count -gt 0) { return $ndks[0].FullName }
    }
  }
  throw "ANDROID_NDK (or ANDROID_NDK_HOME/ANDROID_HOME) is not set."
}

$root = Split-Path -Parent $PSScriptRoot
$thirdParty = Join-Path $root "third_party"
$llamaDir = Join-Path $thirdParty "llama.cpp"

if (-not (Test-Path $llamaDir)) {
  New-Item -ItemType Directory -Path $thirdParty | Out-Null
  git clone https://github.com/ggerganov/llama.cpp $llamaDir
}

$ndk = Resolve-NdkPath
$toolchain = Join-Path $ndk "build\cmake\android.toolchain.cmake"

if (-not (Test-Path $toolchain)) {
  throw "NDK toolchain not found at $toolchain"
}

$buildDir = Join-Path $llamaDir "build-android-$Abi"
if (Test-Path $buildDir) {
  Remove-Item -Recurse -Force $buildDir
}

$sdkRoot = $env:ANDROID_HOME
if (-not $sdkRoot) { $sdkRoot = $env:ANDROID_SDK_ROOT }
if (-not $sdkRoot) { $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk" }

$env:ANDROID_NDK = $ndk
$env:ANDROID_SDK_ROOT = $sdkRoot

$ninja = Get-ChildItem -Path (Join-Path $sdkRoot "cmake") -Recurse -Filter "ninja.exe" -ErrorAction SilentlyContinue |
  Sort-Object FullName -Descending |
  Select-Object -First 1
if (-not $ninja) { throw "ninja.exe not found under $sdkRoot\\cmake" }

$cmakeArgs = @(
  "-G", "Ninja",
  "-S", $llamaDir,
  "-B", $buildDir,
  "-DCMAKE_TOOLCHAIN_FILE=$toolchain",
  "-DANDROID_ABI=$Abi",
  "-DANDROID_PLATFORM=android-$Api",
  "-DBUILD_SHARED_LIBS=ON",
  "-DCMAKE_MAKE_PROGRAM=$($ninja.FullName)"
)

& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed." }

& cmake --build $buildDir -j
if ($LASTEXITCODE -ne 0) { throw "CMake build failed." }

$outDir = Join-Path $root "android\app\src\main\jniLibs\$Abi"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$lib = Get-ChildItem -Path $buildDir -Filter "libllama.so" -Recurse | Select-Object -First 1
if (-not $lib) { throw "libllama.so not found in $buildDir" }
Copy-Item $lib.FullName -Destination (Join-Path $outDir "libllama.so") -Force

Write-Host "Copied libllama.so to $outDir"
